"""backend/02: manual progress, mark unread, repoint, collection rules and
previews, member order, library tags, tag filter and server-side sorts.

HTTP-level, through ``client`` + ``as_user`` so profile scoping, the 18+ gate
and profile ownership run for real. ``FakeBrowse`` stands in for connectors.
"""

from __future__ import annotations

import json
from datetime import timedelta

import pytest
from sqlalchemy import func, select

from core.time_utils import utcnow
from database.models import (
    ChapterProgress,
    Collection,
    CollectionSeries,
    CoverPalette,
    FollowedSeries,
    ProfileSeriesTag,
    ReadingSession,
    Tag,
)
from services.browse_service import get_browse_service
from tests._fakes import FakeBrowse

SRC = "mangadex"
OTHER = "comick"
MATURE_SRC = "nhentai"


def _chapters(prefix: str, numbers) -> list[dict]:
    return [
        {"id": f"{prefix}-{n:g}", "number": float(n), "title": f"Ch {n:g}",
         "release_date": "2026-01-01"}
        for n in numbers
    ]


FIXTURE = {
    (SRC, "old"): {"meta": {"title": "Old Home", "genres": ["action"]},
                   "chapters": _chapters("old", range(1, 11))},
    (OTHER, "new"): {"meta": {"title": "New Home", "genres": ["action"],
                              "cover_url": "http://x/new.jpg"},
                     "chapters": _chapters("new", range(1, 13))},
    (OTHER, "gap"): {"meta": {"title": "Gappy", "genres": ["action"]},
                     "chapters": _chapters("gap", [1, 2, 3, 4, 6, 7])},
    (OTHER, "adult"): {"meta": {"title": "Adult", "genres": ["hentai"]},
                       "chapters": _chapters("ad", [1, 2])},
}


@pytest.fixture
def world(make_user, make_profile):
    """Account 1 with profiles A (gate shut) and B; account 2 with profile C."""
    u1 = make_user("acct1")
    u2 = make_user("acct2")
    return {
        "u1": u1.id, "u2": u2.id,
        "a": make_profile(u1.id, "A").id,
        "b": make_profile(u1.id, "B").id,
        "c": make_profile(u2.id, "C").id,
    }


@pytest.fixture
def api(app, client):
    browse = FakeBrowse({k: json.loads(json.dumps(v)) for k, v in FIXTURE.items()})
    app.dependency_overrides[get_browse_service] = lambda: browse
    return client


@pytest.fixture
def ha(as_user, world):
    return as_user(world["u1"], world["a"])


@pytest.fixture
def hb(as_user, world):
    return as_user(world["u1"], world["b"])


@pytest.fixture
def hc(as_user, world):
    return as_user(world["u2"], world["c"])


def _push(**kw):
    item = {"source_id": SRC, "series_key": "s", "chapter_key": "c1",
            "chapter_number": 1, "last_page": 5, "page_count": 5,
            "is_completed": True, "time_spent_seconds": 30}
    item.update(kw)
    return item


def _sessions(db):
    db.expire_all()
    return db.execute(select(func.count()).select_from(ReadingSession)).scalar_one()


def _progress_keys(db, uid, pid, series_key=None):
    db.expire_all()
    stmt = select(ChapterProgress).where(
        ChapterProgress.user_id == uid, ChapterProgress.profile_id == pid
    )
    if series_key:
        stmt = stmt.where(ChapterProgress.series_key == series_key)
    return {r.chapter_key for r in db.execute(stmt).scalars()}


# ===========================================================================
# A. manual progress and mark unread
# ===========================================================================


def test_manual_batch_item_saves_without_a_session(api, ha, db_session):
    resp = api.post("/reader/progress/batch", json=[_push(manual=True)], headers=ha)
    assert resp.status_code == 200, resp.text
    assert resp.json()["items"][0]["is_completed"] is True
    assert _sessions(db_session) == 0

    resp = api.post("/reader/progress/batch", json=[_push(chapter_key="c2")], headers=ha)
    assert resp.status_code == 200
    assert _sessions(db_session) == 1


def test_manual_single_push_saves_without_a_session(api, ha, db_session):
    resp = api.post("/reader/progress", json=_push(manual=True), headers=ha)
    assert resp.status_code == 200, resp.text
    assert resp.json()["is_completed"] is True
    assert _sessions(db_session) == 0


def test_delete_progress_removes_named_chapters_for_caller_only(
    api, ha, hb, world, seed_progress, seed_session, db_session
):
    for key in ("c1", "c2", "c3"):
        seed_progress(world["u1"], world["a"], series_key="s", chapter_key=key)
        seed_progress(world["u1"], world["b"], series_key="s", chapter_key=key)
    seed_session(world["u1"], world["a"], series_key="s", chapter_key="c1")

    resp = api.request(
        "DELETE", "/reader/progress",
        json={"source_id": SRC, "series_key": "s", "chapter_keys": ["c1", "c2", "nope"]},
        headers=ha,
    )
    assert resp.status_code == 204, resp.text
    assert _progress_keys(db_session, world["u1"], world["a"]) == {"c3"}
    assert _progress_keys(db_session, world["u1"], world["b"]) == {"c1", "c2", "c3"}
    assert _sessions(db_session) == 1


def test_delete_progress_unknown_keys_204_and_cap_422(api, ha):
    resp = api.request(
        "DELETE", "/reader/progress",
        json={"source_id": SRC, "series_key": "zz", "chapter_keys": ["x"]}, headers=ha,
    )
    assert resp.status_code == 204
    resp = api.request(
        "DELETE", "/reader/progress",
        json={"source_id": SRC, "series_key": "zz",
              "chapter_keys": [f"k{i}" for i in range(201)]},
        headers=ha,
    )
    assert resp.status_code == 422
    resp = api.request(
        "DELETE", "/reader/progress",
        json={"source_id": SRC, "series_key": "zz",
              "chapter_keys": [f"k{i}" for i in range(200)]},
        headers=ha,
    )
    assert resp.status_code == 204


def test_delete_progress_other_account_untouched(api, hc, world, seed_progress, db_session):
    seed_progress(world["u1"], world["a"], series_key="s", chapter_key="c1")
    resp = api.request(
        "DELETE", "/reader/progress",
        json={"source_id": SRC, "series_key": "s", "chapter_keys": ["c1"]}, headers=hc,
    )
    assert resp.status_code == 204
    assert _progress_keys(db_session, world["u1"], world["a"]) == {"c1"}


def test_delete_progress_of_a_gated_series_still_deletes(
    api, ha, world, seed_follow, seed_progress, db_session
):
    seed_follow(world["u1"], world["a"], series_key="s", mature_override=True)
    seed_progress(world["u1"], world["a"], series_key="s", chapter_key="c1")
    resp = api.request(
        "DELETE", "/reader/progress",
        json={"source_id": SRC, "series_key": "s", "chapter_keys": ["c1"]}, headers=ha,
    )
    assert resp.status_code == 204
    assert _progress_keys(db_session, world["u1"], world["a"]) == set()
