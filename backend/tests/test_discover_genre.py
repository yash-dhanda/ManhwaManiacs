"""Discover's genre grid (``GET /discover/genre/{genre}/ai``), DeepSeek mocked.

Pinned: a page is one cached global answer; invented titles never become
cards; later pages never repeat earlier ones; the 18+ gate is applied when
serving, not baked into the shared cache; an AI failure falls back to the
catalogue's own genre listing instead of an error.
"""

from __future__ import annotations

import json

import httpx
import pytest

from services import suggestion_service
from services.llm import Completion, LLMError
from services.suggestion_service import SuggestionService
from tests.test_world_recs import (  # noqa: F401  (fixtures)
    BLADE,
    LEWD,
    SOLO,
    _media,
    _world,
    catalog,
    reader,
)

LISTED = [_media(10, "Omniscient Reader"), _media(11, "Lewd Listing", adult=True)]


@pytest.fixture
def deepseek(monkeypatch, tmp_path, catalog):
    """Answers page n with ``pages[n]``; records each prompt."""
    monkeypatch.setattr(suggestion_service, "BUDGET_PATH", tmp_path / "u.json")
    monkeypatch.setattr(suggestion_service, "ACCOUNT_BUDGET_PATH", tmp_path / "a.json")
    monkeypatch.setattr(suggestion_service, "GENRE_PAGES_PER_REQUEST", 1)
    monkeypatch.setattr(suggestion_service.deepseek_client, "is_configured", lambda: True)
    catalog.search.update({"return of the blossoming blade": BLADE, "an adult title": LEWD})
    real = catalog.handler

    def handler(request: httpx.Request) -> httpx.Response:
        if str(request.url).startswith("https://graphql.anilist.co"):
            variables = json.loads(request.content)["variables"]
            if "p" in variables:
                catalog.calls += 1
                catalog.genre_vars = variables
                media = [m for m in LISTED if variables.get("a") is None or not m["isAdult"]]
                return httpx.Response(200, json={"data": {"Page": {"media": media}}})
        return real(request)

    catalog.handler = handler
    fake = type("DeepSeek", (), {})()
    fake.pages = []
    fake.prompts = []
    fake.fail = False

    def complete_json(prompt, **kwargs):
        if fake.fail:
            raise LLMError("down")
        fake.prompts.append(prompt)
        titles = fake.pages[len(fake.prompts) - 1]
        return Completion(
            content=json.dumps({"titles": titles}),
            prompt_tokens=1, completion_tokens=1, model="deepseek-flash",
        )

    monkeypatch.setattr(suggestion_service.deepseek_client, "complete_json", complete_json)
    return fake


def _page(db_session, uid, pid, cursor=0, genre="Action"):
    world = _world(db_session, uid, pid)
    service = SuggestionService(db_session, world._library, is_admin=True)
    return service.genre_page(genre, cursor, world=world)


def test_invented_titles_are_dropped_and_pages_never_repeat(db_session, reader, deepseek):
    uid, pid = reader()
    deepseek.pages = [
        ["Solo Leveling", "A Book Nobody Wrote", "solo leveling"],
        ["Solo Leveling", "Return of the Blossoming Blade"],
    ]
    first = _page(db_session, uid, pid, 0)
    assert [i["title"] for i in first["items"]] == ["Solo Leveling"]
    assert first["dropped"] == 1 and first["source"] == "ai" and first["next_cursor"] == "1"

    second = _page(db_session, uid, pid, 1)
    assert [i["title"] for i in second["items"]] == ["Return of the Blossoming Blade"]
    assert "- Solo Leveling" in deepseek.prompts[1]


def test_a_page_is_cached_and_the_gate_is_applied_when_serving(
    db_session, reader, deepseek, make_profile
):
    uid, pid = reader(mature=False)
    adult_pid = make_profile(uid, "Late", mature_content_enabled=True).id
    deepseek.pages = [["Solo Leveling", "An Adult Title"]]

    shut = _page(db_session, uid, pid)
    opened = _page(db_session, uid, adult_pid)

    assert len(deepseek.prompts) == 1
    assert [i["title"] for i in shut["items"]] == ["Solo Leveling"]
    assert {i["title"] for i in opened["items"]} == {"Solo Leveling", "An Adult Title"}


def test_an_ai_failure_falls_back_to_the_catalogue_listing(
    db_session, reader, deepseek, catalog
):
    uid, pid = reader(mature=False)
    deepseek.fail = True
    out = _page(db_session, uid, pid, 2)
    assert out["source"] == "catalogue" and out["unavailable_reason"]
    assert [i["title"] for i in out["items"]] == ["Omniscient Reader"]
    assert catalog.genre_vars == {"p": 3, "v": ["Action"], "a": False}
    assert out["next_cursor"] == "3"


def test_route_needs_a_session_and_answers(client, as_user, reader, deepseek):
    assert client.get("/discover/genre/Action/ai").status_code == 401
    uid, pid = reader()
    deepseek.pages = [["Solo Leveling"]]
    resp = client.get("/discover/genre/Action/ai?cursor=0", headers=as_user(uid, pid))
    assert resp.status_code == 200, resp.text
    assert {"items", "next_cursor", "source", "dropped"} <= resp.json().keys()
