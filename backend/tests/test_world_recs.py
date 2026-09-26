"""Worldwide recommendations: AniList picks, marked with what the reader's sources carry.

The owner asked for recommendations from "all the world", with titles none of
his sources carry still shown -- name, what it is, chapter count, rating. So
the properties pinned here are: candidates come from the catalog, not the
local cache; availability is read off the local cache and follows by title and
alternate titles; what he already reads is never recommended back; the 18+
gate holds; answers are cached; a catalog outage degrades instead of failing;
and the AI box drops any title the catalog cannot confirm.
"""

from __future__ import annotations

import json
from typing import Any

import httpx
import pytest

from database.models import SourceSeriesCache
from services import suggestion_service, world_recs
from services.followed_series_service import FollowedSeriesService
from services.llm import Completion
from services.suggestion_service import SuggestionService
from services.world_recs import WorldRecs, match_key
from tests._fakes import FakeBrowse


def _media(
    media_id: int,
    english: str,
    *,
    synonyms: list[str] | None = None,
    chapters: int | None = None,
    status: str = "RELEASING",
    score: int | None = 84,
    adult: bool = False,
    country: str = "KR",
) -> dict[str, Any]:
    return {
        "id": media_id,
        "title": {"romaji": english, "english": english, "native": None},
        "synonyms": synonyms or [],
        "format": "MANGA",
        "countryOfOrigin": country,
        "status": status,
        "chapters": chapters,
        "averageScore": score,
        "genres": ["Action", "Martial Arts"],
        "isAdult": adult,
        "coverImage": {"large": f"https://s4.anilist.co/cover/{media_id}.jpg"},
        "siteUrl": f"https://anilist.co/manga/{media_id}",
        "externalLinks": [
            {"site": "Webtoon", "url": "https://webtoons.example/x", "type": "STREAMING"},
            {"site": "Twitter", "url": "https://twitter.example/x", "type": "SOCIAL"},
        ],
    }


NANO = _media(1, "Nano Machine")
BLADE = _media(2, "Return of the Blossoming Blade", synonyms=["Return of the Mount Hua Sect"])
SOLO = _media(3, "Solo Leveling", chapters=201, status="FINISHED", score=84)
LEWD = _media(4, "An Adult Title", adult=True)


class Catalog:
    """A fake AniList + MangaUpdates, counting requests."""

    def __init__(self) -> None:
        self.calls = 0
        self.down = False
        self.search = {"nano machine": NANO, "solo leveling": SOLO}
        self.recs = {1: [(99, BLADE), (76, SOLO), (50, LEWD), (40, NANO)]}
        self.mu = {"return of the blossoming blade": {"series_id": 7, "latest_chapter": 181}}

    def handler(self, request: httpx.Request) -> httpx.Response:
        self.calls += 1
        if self.down:
            raise httpx.ConnectError("down", request=request)
        url = str(request.url)
        if url.startswith(world_recs.ANILIST_URL):
            body = json.loads(request.content)
            variables = body["variables"]
            if "s" in variables:
                media = self.search.get(match_key(variables["s"]))
                if media is None:
                    return httpx.Response(404, json={"errors": [{"message": "Not Found."}]})
                return httpx.Response(200, json={"data": {"Media": media}})
            nodes = [
                {"rating": r, "mediaRecommendation": m}
                for r, m in self.recs.get(variables["id"], [])
            ]
            return httpx.Response(
                200, json={"data": {"Media": {"recommendations": {"nodes": nodes}}}}
            )
        if url.endswith("/series/search"):
            title = json.loads(request.content)["search"]
            hit = self.mu.get(match_key(title))
            results = (
                [{"record": {"series_id": hit["series_id"], "title": title}}] if hit else []
            )
            return httpx.Response(200, json={"results": results})
        if "/series/" in url:
            series_id = int(url.rsplit("/", 1)[1])
            hit = next(v for v in self.mu.values() if v["series_id"] == series_id)
            return httpx.Response(
                200, json={"latest_chapter": hit["latest_chapter"], "bayesian_rating": 8.57}
            )
        return httpx.Response(404)


@pytest.fixture
def catalog(monkeypatch):
    fake = Catalog()
    monkeypatch.setattr(world_recs, "_transport", lambda: httpx.MockTransport(fake.handler))
    return fake


@pytest.fixture
def reader(make_user, make_profile, seed_follow, seed_progress):
    def _make(*, mature: bool = False):
        user = make_user("worldreader")
        profile = make_profile(user.id, "Main", mature_content_enabled=mature)
        seed_follow(
            user.id, profile.id, source_id="asurascans",
            series_key="nano-machine-6f7fe6eb", title="Nano Machine",
        )
        for n in (1, 2, 3):
            seed_progress(
                user.id, profile.id, source_id="asurascans",
                series_key="nano-machine-6f7fe6eb",
                chapter_key=f"nano-machine-6f7fe6eb:{n}",
            )
        return user.id, profile.id

    return _make


def _world(db_session, uid: int, pid: int) -> WorldRecs:
    library = FollowedSeriesService(db_session, FakeBrowse({}), user_id=uid, profile_id=pid)
    return WorldRecs(db_session, library)


def _cache(db_session, source_id: str, key: str, title: str) -> None:
    db_session.add(SourceSeriesCache(source_id=source_id, series_key=key, title=title, genres="[]"))
    db_session.commit()


def test_recommends_from_the_catalog_and_marks_what_his_sources_carry(
    db_session, catalog, reader
):
    uid, pid = reader()
    # Asura lists Blossoming Blade under another English name.
    _cache(db_session, "asurascans", "mount-hua-05c7df14", "Return of the Mount Hua Sect")

    out = _world(db_session, uid, pid).recommendations(seeds=3, per_seed=10)

    by_title = {i["title"]: i for i in out["for_you"]}
    assert set(by_title) == {"Return of the Blossoming Blade", "Solo Leveling"}
    blade, solo = by_title["Return of the Blossoming Blade"], by_title["Solo Leveling"]
    assert blade["available"] == [
        {"source_id": "asurascans", "source_name": blade["available"][0]["source_name"],
         "series_key": "mount-hua-05c7df14"}
    ]
    assert blade["chapters"] == 181  # AniList leaves ongoing series blank; MangaUpdates fills it
    assert (blade["format"], blade["status"], blade["rating"]) == ("Manhwa", "Ongoing", 8.4)
    assert blade["platforms"] == [{"site": "Webtoon", "url": "https://webtoons.example/x"}]
    # Not on any of his sources: still recommended, as information.
    assert solo["available"] == [] and solo["chapters"] == 201 and solo["status"] == "Completed"
    assert out["sections"][0]["because"] == {
        "title": "Nano Machine", "source_id": "asurascans", "series_key": "nano-machine-6f7fe6eb",
    }
    assert out["unavailable_reason"] is None


def test_what_he_already_reads_is_never_recommended_back(db_session, catalog, reader):
    uid, pid = reader()
    out = _world(db_session, uid, pid).recommendations()
    titles = {i["title"] for i in out["for_you"]}
    assert "Nano Machine" not in titles


def test_the_18_plus_gate_holds(db_session, catalog, reader):
    uid, pid = reader(mature=False)
    shut = _world(db_session, uid, pid).recommendations()
    assert "An Adult Title" not in {i["title"] for i in shut["for_you"]}


def test_an_open_gate_shows_adult_titles(db_session, catalog, reader):
    uid, pid = reader(mature=True)
    open_ = _world(db_session, uid, pid).recommendations()
    assert "An Adult Title" in {i["title"] for i in open_["for_you"]}


def test_answers_are_cached(db_session, catalog, reader):
    uid, pid = reader()
    _world(db_session, uid, pid).recommendations()
    first = catalog.calls
    _world(db_session, uid, pid).recommendations()
    assert first > 0 and catalog.calls == first


def test_a_catalog_outage_degrades_instead_of_failing(db_session, catalog, reader):
    uid, pid = reader()
    catalog.down = True
    out = _world(db_session, uid, pid).recommendations()
    assert out["for_you"] == [] and out["unavailable_reason"]


def test_no_reading_history_is_an_empty_answer(db_session, catalog, make_user, make_profile):
    user = make_user("newreader")
    profile = make_profile(user.id, "Main")
    out = _world(db_session, user.id, profile.id).recommendations()
    assert out == {"for_you": [], "sections": [], "unavailable_reason": None}
    assert catalog.calls == 0


def test_ai_titles_the_catalog_cannot_confirm_are_dropped(
    db_session, catalog, reader, monkeypatch, tmp_path
):
    uid, pid = reader()
    monkeypatch.setattr(suggestion_service, "BUDGET_PATH", tmp_path / "u.json")
    monkeypatch.setattr(suggestion_service, "ACCOUNT_BUDGET_PATH", tmp_path / "a.json")
    answer = Completion(
        content=json.dumps({"suggestions": [
            {"title": "Solo Leveling", "why": "Same power-climb as what you read."},
            {"title": "A Book Nobody Wrote", "why": "Invented."},
        ]}),
        prompt_tokens=1, completion_tokens=1, model="deepseek-flash",
    )
    monkeypatch.setattr(suggestion_service.deepseek_client, "complete_json", lambda *a, **k: answer)
    world = _world(db_session, uid, pid)
    service = SuggestionService(db_session, world._library, is_admin=True)

    out = service.world_suggest("something like solo leveling", world=world, limit=12)

    assert [i["title"] for i in out["items"]] == ["Solo Leveling"]
    assert out["items"][0]["why"] == "Same power-climb as what you read."
    assert out["dropped"] == 1


def test_route_answers(client, as_user, catalog, reader):
    uid, pid = reader()
    resp = client.get("/library/world/recommendations", headers=as_user(uid, pid))
    assert resp.status_code == 200, resp.text
    assert {"for_you", "sections", "unavailable_reason"} <= resp.json().keys()


def test_a_curly_apostrophe_is_straightened_before_asking_the_catalog(
    db_session, catalog, reader
):
    """Sources print "Swordmaster’s Youngest Son"; AniList's search only finds
    the straight-apostrophe spelling."""
    uid, pid = reader()
    sent: list[str] = []
    real = catalog.handler

    def spy(request: httpx.Request) -> httpx.Response:
        if str(request.url).startswith(world_recs.ANILIST_URL):
            sent.append(json.loads(request.content)["variables"].get("s") or "")
        return real(request)

    catalog.handler = spy
    _world(db_session, uid, pid).catalog.search(["Swordmaster’s Youngest Son"])
    assert sent == ["Swordmaster's Youngest Son"]


@pytest.mark.parametrize("mature, expected", [(False, []), (True, ["allporncomicsco"])])
def test_availability_never_names_a_mature_source_to_a_shut_gate(
    db_session, catalog, reader, mature, expected
):
    uid, pid = reader(mature=mature)
    _cache(db_session, "allporncomicsco", "solo", "Solo Leveling")
    out = _world(db_session, uid, pid).recommendations()
    solo = next(i for i in out["for_you"] if i["title"] == "Solo Leveling")
    assert [a["source_id"] for a in solo["available"]] == expected
