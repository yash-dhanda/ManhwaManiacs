"""Shared fakes for the backend/05 AI tests: a mock DeepSeek behind the real
client (so the ledgers are real), a fake AniList, and series seeding."""

from __future__ import annotations

import json
import time
from typing import Any

import httpx

from core.time_utils import utcnow
from database.models import ChapterOcr, ChapterProgress, SourceSeriesCache
from services import ai_desk, suggestion_service, world_recs
from tests import _home_stubs

SRC, MATURE, NOVEL = "hm_manga", "hm_mature", "hm_novel"


class Paid:
    """The mock DeepSeek. ``answer`` is the JSON object the model returns (or a
    callable ``(system, message) -> object``); every request is recorded."""

    def __init__(self) -> None:
        self.seen: list[dict[str, str]] = []
        self.answer: Any = {}
        self.status = 200
        self.delay = 0.0

    def handle(self, request: httpx.Request) -> httpx.Response:
        body = json.loads(request.content)
        msgs = body["messages"]
        system = next((m["content"] for m in msgs if m["role"] == "system"), "")
        user = next((m["content"] for m in msgs if m["role"] == "user"), "")
        self.seen.append({"system": system, "message": user})
        if self.delay:
            time.sleep(self.delay)
        if self.status != 200:
            return httpx.Response(self.status, json={})
        answer = self.answer(system, user) if callable(self.answer) else self.answer
        return httpx.Response(200, json={
            "choices": [{"message": {"content": json.dumps(answer)}, "finish_reason": "stop"}],
            "usage": {"prompt_tokens": 10, "completion_tokens": 10},
            "model": "deepseek-test",
        })


def install(monkeypatch, tmp_path, session_factory, *, key: bool = True) -> Paid:
    """Stubs, ledgers on tmp paths, the desk's background session, a mock AI."""
    _home_stubs.install(monkeypatch)
    monkeypatch.setattr(suggestion_service, "BUDGET_PATH", tmp_path / "s.json")
    monkeypatch.setattr(suggestion_service, "ACCOUNT_BUDGET_PATH", tmp_path / "a.json")
    monkeypatch.setattr(ai_desk, "DESK_BUDGET_PATH", tmp_path / "desk.json")
    monkeypatch.setattr(ai_desk, "open_session", session_factory)
    if key:
        monkeypatch.setenv("DEEPSEEK_API_KEY", "sk-test-not-a-real-key-0000000000")
    else:
        monkeypatch.delenv("DEEPSEEK_API_KEY", raising=False)
    ai_desk.reset_desk_state()

    from core.connector_directory import descriptor_for_source
    from core.errors import AppError
    from services.browse_service import BrowseService

    def ensure_visible(self, source_id):
        # The stub connectors have no ``is_browsable``: the registry-only gate
        # the real ``ensure_visible`` applies (unknown or mature-while-shut is 404).
        d = descriptor_for_source(source_id)
        if d is None or (d.mature and not self._gate_open()):
            raise AppError("Source not found.", code="source_not_found", status_code=404)

    monkeypatch.setattr(BrowseService, "ensure_visible", ensure_visible)
    paid = Paid()
    transport = httpx.MockTransport(paid.handle)
    monkeypatch.setattr(suggestion_service, "_upstream_transport", lambda: transport)
    from services import home_service, recap_service

    home_service.reset_home_cache()
    recap_service.reset_recap_limiter()
    return paid


def media(media_id: int, title: str, *, genres=("Action", "Fantasy"), adult=False, fmt="MANGA", country="KR"):
    return {
        "id": media_id,
        "title": {"romaji": title, "english": title, "native": None},
        "synonyms": [], "format": fmt, "countryOfOrigin": country, "status": "RELEASING",
        "chapters": 50, "averageScore": 80, "genres": list(genres), "isAdult": adult,
        "coverImage": {"large": f"https://s4.anilist.co/{media_id}.jpg"},
        "siteUrl": f"https://anilist.co/manga/{media_id}", "externalLinks": [],
    }


class FakeAniList:
    """AniList through ``world_recs._transport``: search by title, recs by id,
    trending by format. ``down`` raises a connection error."""

    def __init__(self) -> None:
        self.search: dict[str, dict] = {}
        self.recs: dict[int, list[tuple[int, dict]]] = {}
        self.trending: dict[str, list[dict]] = {}
        self.down = False
        self.calls = 0
        self.trending_vars: list[dict] = []

    def handler(self, request: httpx.Request) -> httpx.Response:
        self.calls += 1
        if self.down:
            raise httpx.ConnectError("down", request=request)
        url = str(request.url)
        if url.startswith(world_recs.ANILIST_URL):
            variables = json.loads(request.content)["variables"]
            if "s" in variables:
                found = self.search.get(world_recs.match_key(variables["s"]))
                if found is None:
                    return httpx.Response(404, json={"errors": [{"message": "Not Found."}]})
                return httpx.Response(200, json={"data": {"Media": found}})
            if "formats" in variables:
                self.trending_vars.append(variables)
                country = variables.get("country")
                fmt = "novel" if variables["formats"] == ["NOVEL"] else {
                    "KR": "manhwa", "JP": "manga", "CN": "manhua"}[country]
                items = self.trending.get(fmt, [])
                wanted = variables.get("genres")
                if wanted:
                    items = [m for m in items if set(wanted) & set(m["genres"])]
                if variables.get("adult") is False:
                    items = [m for m in items if not m["isAdult"]]
                return httpx.Response(200, json={"data": {"Page": {"media": items}}})
            nodes = [{"rating": r, "mediaRecommendation": m} for r, m in self.recs.get(variables["id"], [])]
            return httpx.Response(
                200, json={"data": {"Media": {"recommendations": {"nodes": nodes}}}}
            )
        return httpx.Response(200, json={"results": []})


def install_anilist(monkeypatch) -> FakeAniList:
    fake = FakeAniList()
    monkeypatch.setattr(world_recs, "_transport", lambda: httpx.MockTransport(fake.handler))
    return fake


def chapters_json(n: int) -> str:
    return json.dumps([{"key": f"c{i}", "number": i, "title": f"Ch {i}"} for i in range(1, n + 1)])


def seed_series(
    db, uid: int, pid: int, key: str = "s", *, source: str = SRC, read: range = range(131, 143),
    ocr: range = range(131, 146), title: str = "Regressor", genres=("Action", "Fantasy"),
    rating: str | None = None,
) -> None:
    """A series with completed chapters ``read``, OCR text for ``ocr`` (each
    carrying ``MARK<n>``) and a cache row listing every chapter."""
    top = max(list(read) + list(ocr) + [150])
    db.merge(SourceSeriesCache(
        source_id=source, series_key=key, title=title, genres=json.dumps(list(genres)),
        content_rating=rating,
        chapters=json.dumps([{"key": f"c{i}", "number": i} for i in range(1, top + 1)]),
    ))
    base = utcnow()
    for n in read:
        db.add(ChapterProgress(
            user_id=uid, profile_id=pid, source_id=source, series_key=key,
            chapter_key=f"c{n}", chapter_number=float(n), is_completed=True, last_read_at=base,
        ))
    for n in ocr:
        db.add(ChapterOcr(
            source_id=source, series_key=key, chapter_key=f"c{n}", word_count=30,
            full_text=f"MARK{n} the hero speaks in chapter {n}.",
        ))
    db.commit()


def sse_events(text: str) -> list[tuple[str, Any]]:
    """Parse an SSE body into ``(event, data)``; comment lines are skipped."""
    out = []
    for block in text.split("\n\n"):
        lines = [l for l in block.split("\n") if l and not l.startswith(":")]
        if not lines:
            continue
        name = next(l[7:] for l in lines if l.startswith("event: "))
        data = next(l[6:] for l in lines if l.startswith("data: "))
        out.append((name, json.loads(data)))
    return out
