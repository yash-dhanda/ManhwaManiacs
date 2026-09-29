"""``GET /series/enrichment``: AniList credits for the feature page (backend/02 E).

The AniList transport is mocked as in ``test_world_recs.py``. Pinned: a
confident match answers the four fields; the answer (a miss included) is cached
for 30 days; an adult match is served only through an open gate; a hidden
series is 404; an AniList outage answers null and caches nothing.
"""

from __future__ import annotations

import json
from datetime import timedelta
from typing import Any

import httpx
import pytest
from sqlalchemy import select, update

from database.models import SourceSeriesCache, WorldCatalogCache
from routes.series import enrichment_key
from services import world_recs
from services.browse_service import get_browse_service
from services.world_recs import match_key
from tests._fakes import FakeBrowse

SRC = "mangadex"
MATURE_SRC = "nhentai"


def _media(media_id: int, title: str, *, adult: bool = False, score: int | None = 84,
           synonyms: list[str] | None = None) -> dict[str, Any]:
    return {
        "id": media_id,
        "title": {"romaji": title, "english": None, "native": None},
        "synonyms": synonyms or [],
        "format": "MANGA",
        "countryOfOrigin": "KR",
        "status": "RELEASING",
        "chapters": None,
        "averageScore": score,
        "genres": [],
        "isAdult": adult,
        "coverImage": {"large": None},
        "siteUrl": None,
        "externalLinks": [
            {"site": "Webtoon", "url": "https://webtoons.example/x", "type": "STREAMING"},
            {"site": "Twitter", "url": "https://twitter.example/x", "type": "SOCIAL"},
            {"site": "Instagram", "url": "https://ig.example/x", "type": "INFO"},
            {"site": "Official", "url": None, "type": "INFO"},
        ] + [{"site": f"Store {i}", "url": f"https://s{i}.example", "type": "INFO"}
             for i in range(8)],
    }


class AniList:
    def __init__(self) -> None:
        self.calls = 0
        self.status = 200
        self.media = {
            "solo leveling": _media(3, "Na Honjaman Level Up", synonyms=["Solo Leveling"]),
            "an adult title": _media(4, "An Adult Title", adult=True),
            "different book": _media(5, "Something Else Entirely"),
        }

    def handler(self, request: httpx.Request) -> httpx.Response:
        self.calls += 1
        if self.status != 200:
            return httpx.Response(self.status)
        search = json.loads(request.content)["variables"]["s"]
        media = self.media.get(match_key(search))
        if media is None:
            return httpx.Response(404, json={"errors": [{"message": "Not Found."}]})
        return httpx.Response(200, json={"data": {"Media": media}})


@pytest.fixture
def anilist(monkeypatch):
    fake = AniList()
    monkeypatch.setattr(world_recs, "_transport", lambda: httpx.MockTransport(fake.handler))
    return fake


@pytest.fixture
def browse(app):
    fake = FakeBrowse({(SRC, "live"): {"meta": {"title": "Solo Leveling"}}})
    app.dependency_overrides[get_browse_service] = lambda: fake
    return fake


@pytest.fixture
def people(make_user, make_profile, as_user):
    u1, u2 = make_user("one"), make_user("two")
    kid = make_profile(u1.id, "Kid")
    adult = make_profile(u1.id, "Adult", mature_content_enabled=True)
    other = make_profile(u2.id, "Other", mature_content_enabled=True)
    return {
        "kid": (u1.id, kid.id, as_user(u1.id, kid.id)),
        "adult": (u1.id, adult.id, as_user(u1.id, adult.id)),
        "other": (u2.id, other.id, as_user(u2.id, other.id)),
    }


def _cache(db, key, title, genres="[]", source_id=SRC, content_rating=None):
    db.add(SourceSeriesCache(source_id=source_id, series_key=key, title=title, genres=genres,
                             content_rating=content_rating))
    db.commit()


def _get(client, h, key, source_id=SRC):
    return client.get("/series/enrichment", params={"source": source_id, "series": key},
                      headers=h)


def _cached(db):
    db.expire_all()
    return {r.key: json.loads(r.payload) for r in db.execute(select(WorldCatalogCache)).scalars()
            if r.key.startswith("enrich:")}


def test_confident_match_answers_the_four_fields_and_is_cached(
    client, browse, anilist, people, db_session
):
    _cache(db_session, "sl", "Solo Leveling")
    h = people["kid"][2]
    resp = _get(client, h, "sl")
    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert body == {
        "anilist_id": 3, "format": "Manhwa", "score": 8.4,
        "official": [{"site": "Webtoon", "url": "https://webtoons.example/x"}]
        + [{"site": f"Store {i}", "url": f"https://s{i}.example"} for i in range(5)],
    }
    calls = anilist.calls
    assert _get(client, h, "sl").json() == body
    assert anilist.calls == calls
    key = enrichment_key(SRC, "sl")
    assert len(key) == 47 and _cached(db_session)[key]["is_adult"] is False


def test_title_from_follow_then_cache_then_live(
    client, browse, anilist, people, seed_follow, db_session
):
    uid, pid, h = people["kid"]
    seed_follow(uid, pid, source_id=SRC, series_key="f", title="Solo Leveling")
    assert _get(client, h, "f").json()["anilist_id"] == 3
    assert _get(client, h, "live").json()["anilist_id"] == 3
    assert f"get_series:{SRC}/live" in browse.calls


def test_unmatched_title_caches_null(client, browse, anilist, people, db_session):
    _cache(db_session, "x", "A Book Nobody Wrote")
    _cache(db_session, "y", "Different Book")  # AniList answers, but not this book
    h = people["kid"][2]
    assert _get(client, h, "x").json() is None
    assert _get(client, h, "y").json() is None
    cached = _cached(db_session)
    assert cached[enrichment_key(SRC, "x")] is None
    assert cached[enrichment_key(SRC, "y")] is None
    calls = anilist.calls
    assert _get(client, h, "x").json() is None and anilist.calls == calls


def test_stale_answer_is_asked_again(client, browse, anilist, people, db_session):
    from core.time_utils import utcnow

    _cache(db_session, "sl", "Solo Leveling")
    h = people["kid"][2]
    _get(client, h, "sl")
    db_session.execute(update(WorldCatalogCache).values(fetched_at=utcnow() - timedelta(days=31)))
    db_session.commit()
    calls = anilist.calls
    assert _get(client, h, "sl").json()["anilist_id"] == 3
    assert anilist.calls > calls


def test_adult_match_is_null_through_a_shut_gate(client, browse, anilist, people, db_session):
    _cache(db_session, "ad", "An Adult Title")
    assert _get(client, people["kid"][2], "ad").json() is None
    assert _get(client, people["adult"][2], "ad").json()["anilist_id"] == 4
    assert _get(client, people["kid"][2], "ad").json() is None
    assert "is_adult" not in _get(client, people["adult"][2], "ad").json()


def test_hidden_series_is_404_for_a_gated_profile(
    client, browse, anilist, people, seed_follow, db_session
):
    uid, pid, kid = people["kid"]
    browse.gate_open = False  # the kid's gate, as get_browse_service would carry it
    _cache(db_session, "rated", "Solo Leveling", genres='["hentai"]')
    seed_follow(uid, pid, source_id=SRC, series_key="flagged", title="Solo Leveling",
                mature_override=True)
    for key in ("rated", "flagged"):
        resp = _get(client, kid, key)
        assert resp.status_code == 404 and resp.json()["code"] == "series_not_found"
    browse.mature_sources.add(MATURE_SRC)
    assert _get(client, kid, "1", source_id=MATURE_SRC).status_code == 404
    assert anilist.calls == 0
    browse.gate_open = True
    assert _get(client, people["adult"][2], "rated").json()["anilist_id"] == 3


def test_anilist_outage_answers_null_and_caches_nothing(
    client, browse, anilist, people, db_session
):
    _cache(db_session, "sl", "Solo Leveling")
    anilist.status = 500
    resp = _get(client, people["kid"][2], "sl")
    assert resp.status_code == 200 and resp.json() is None
    assert _cached(db_session) == {}
    anilist.status = 200
    assert _get(client, people["kid"][2], "sl").json()["anilist_id"] == 3


def test_profile_isolation_follow_titles(client, browse, anilist, people, seed_follow):
    # A's follow title is never used for another account's lookup, and another
    # account's mature flag never hides the series from this one.
    uid, pid, _ = people["other"]
    seed_follow(uid, pid, source_id=SRC, series_key="iso", title="Solo Leveling",
                mature_override=True)
    assert _get(client, people["other"][2], "iso").json()["anilist_id"] == 3
    resp = _get(client, people["kid"][2], "iso")
    assert resp.status_code == 200  # the other account's flag does not apply here
    assert resp.json()["anilist_id"] == 3
