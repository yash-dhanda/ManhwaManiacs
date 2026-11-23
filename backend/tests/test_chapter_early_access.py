"""A chapter the source lists before it serves it (AsuraScans early access).

Asura publishes a chapter to paying members six hours ahead of everyone else and
lists it for both. Reported 2026-11-23: the update sweep announced
"Logging 10,000 Years into the Future" chapter 370 the moment it was listed, and
opening it answered "Chapter not found" -- the page list was empty, and an empty
page list was the only thing any layer above the connector could see.

The payload shapes below are the ones ``api.asurascans.com`` returned that day,
trimmed to the fields that matter.
"""

from __future__ import annotations

import json
from unittest.mock import patch

import pytest
from sqlalchemy import select

import services.browse_service as browse_service
from connectors.asurascans.connector import AsuraScansConnector
from connectors.asurascans.mappers import chapter_item_to_chapter, lock_instant
from connectors.base import ChapterLockedError
from core.errors import AppError
from database.models import (
    FollowedSeries,
    ReadingProfile,
    UpdateNotification,
    UpdateSettings,
    User,
)
from services.browse_service import BrowseService, _serialize_chapter
from services.bulk_fetch import item_error
from services.source_cache_service import SourceCacheService
from services.update_service import UpdateService

SLUG = "logging-10000-years-into-the-future"
UNLOCK_RAW = "2026-11-23T14:15:24.018266Z"
UNLOCK = "2026-11-23T14:15:24Z"

LOCKED_ITEM = {
    "id": 267453,
    "number": 370,
    "slug": "chapter-370",
    "page_count": 11,
    "is_premium": True,
    "early_access_until": UNLOCK_RAW,
    "published_at": "2026-11-23T08:15:24.018266Z",
}
# Every chapter released since the scheme began keeps its long-past instant.
OPENED_ITEM = {
    "id": 263384,
    "number": 369,
    "slug": "chapter-369",
    "page_count": 10,
    "is_premium": False,
    "early_access_until": "2026-11-20T01:04:36.465944Z",
    "published_at": "2026-11-19T19:04:36.465944Z",
}
LOCKED_PAGES = {
    "data": {
        "access_gate": "",
        "is_locked": True,
        "unlock_time": UNLOCK_RAW,
        "chapter": {**LOCKED_ITEM, "page_count": 0},
    }
}
OPEN_PAGES = {
    "data": {
        "access_gate": "",
        "is_locked": False,
        "unlock_time": None,
        "chapter": {
            **OPENED_ITEM,
            "pages": [{"url": "https://cdn.asurascans.com/a/1.webp"}],
        },
    }
}


# --- the connector ---------------------------------------------------------


def test_an_early_access_chapter_carries_when_it_opens():
    chapter = chapter_item_to_chapter(LOCKED_ITEM, series_id=SLUG)
    assert chapter.locked_until == UNLOCK
    assert _serialize_chapter(chapter, "asurascans")["locked_until"] == UNLOCK


def test_a_chapter_past_its_early_access_is_not_locked():
    chapter = chapter_item_to_chapter(OPENED_ITEM, series_id=SLUG)
    assert chapter.locked_until is None
    assert _serialize_chapter(chapter, "asurascans")["locked_until"] is None


@pytest.mark.parametrize("value", [None, "", "soon", 1763907324, "2026-13-45T99:00:00Z"])
def test_an_unreadable_instant_is_no_lock_at_all(value):
    assert lock_instant(value) is None
    item = {**LOCKED_ITEM, "early_access_until": value}
    assert chapter_item_to_chapter(item, series_id=SLUG).locked_until is None


def test_an_offset_instant_is_stored_as_utc():
    assert lock_instant("2026-11-23T19:45:24+05:30") == UNLOCK


def test_pages_of_a_locked_chapter_say_locked_and_are_not_cached():
    connector = AsuraScansConnector()
    chapter_id = chapter_item_to_chapter(LOCKED_ITEM, series_id=SLUG).id

    with patch.object(connector._http, "get_json", return_value=LOCKED_PAGES) as get:
        with pytest.raises(ChapterLockedError) as locked:
            connector.get_chapter_pages(chapter_id)
        assert locked.value.locked_until == UNLOCK
        # Still locked a minute later: asked again, never remembered.
        with pytest.raises(ChapterLockedError):
            connector.get_chapter_pages(chapter_id)
        assert get.call_count == 2

    # The unlock passes; the very next request gets the pages.
    opened = {"data": {**OPEN_PAGES["data"], "chapter": {**OPEN_PAGES["data"]["chapter"], "number": 370}}}
    with patch.object(connector._http, "get_json", return_value=opened):
        assert len(connector.get_chapter_pages(chapter_id)) == 1


def test_a_page_of_a_chapter_that_locked_again_is_simply_absent():
    connector = AsuraScansConnector()
    chapter_id = chapter_item_to_chapter(LOCKED_ITEM, series_id=SLUG).id
    with patch.object(connector._http, "get_json", return_value=LOCKED_PAGES):
        assert connector.find_page(f"{chapter_id}:1") is None


# --- what a client is told -------------------------------------------------


def _browse_with(connector: AsuraScansConnector, monkeypatch) -> BrowseService:
    service = BrowseService(mature_enabled=True)
    monkeypatch.setattr(service, "_get_connector", lambda source_id: connector)
    monkeypatch.setattr(service, "_require_visible_chapter", lambda *a, **k: None)
    return service


def test_opening_a_locked_chapter_is_chapter_locked_not_chapter_not_found(monkeypatch):
    connector = AsuraScansConnector()
    service = _browse_with(connector, monkeypatch)
    chapter_id = chapter_item_to_chapter(LOCKED_ITEM, series_id=SLUG).id

    with patch.object(connector._http, "get_json", return_value=LOCKED_PAGES):
        with pytest.raises(AppError) as raised:
            service.get_chapter_pages("asurascans", chapter_id)

    error = raised.value
    assert error.code == "chapter_locked"
    assert error.status_code == 423
    assert error.details == {
        "source_id": "asurascans",
        "chapter_id": chapter_id,
        "locked_until": UNLOCK,
    }
    # A build that predates the code can only show the sentence.
    assert error.message == (
        "Early access on AsuraScans. This chapter opens to everyone at "
        "14:15 UTC on 23 Nov."
    )


def test_a_lock_with_no_time_still_says_locked(monkeypatch):
    connector = AsuraScansConnector()
    service = _browse_with(connector, monkeypatch)
    chapter_id = chapter_item_to_chapter(LOCKED_ITEM, series_id=SLUG).id
    payload = {"data": {"is_locked": True, "unlock_time": None, "chapter": {"number": 370}}}

    with patch.object(connector._http, "get_json", return_value=payload):
        with pytest.raises(AppError) as raised:
            service.get_chapter_pages("asurascans", chapter_id)

    assert raised.value.code == "chapter_locked"
    assert raised.value.details["locked_until"] is None
    assert "locked on AsuraScans" in raised.value.message


def test_a_bulk_window_item_keeps_the_unlock_time(monkeypatch):
    connector = AsuraScansConnector()
    error = browse_service.chapter_locked_error(connector, "asurascans", "c", UNLOCK)
    assert item_error("asurascans", error) == {
        "code": "chapter_locked",
        "status": 423,
        "message": error.message,
        "locked_until": UNLOCK,
    }
    # Every other failure keeps exactly the three keys it always had.
    plain = AppError("Chapter not found.", code="chapter_not_found", status_code=404, details={"x": 1})
    assert set(item_error("asurascans", plain)) == {"code", "status", "message"}


# --- the chapter list cache and the update feed ----------------------------


def test_the_cached_chapter_list_keeps_the_lock(db_session):
    cache = SourceCacheService(db_session, BrowseService(mature_enabled=True))
    chapters = [
        _serialize_chapter(chapter_item_to_chapter(item, series_id=SLUG), "asurascans")
        for item in (OPENED_ITEM, LOCKED_ITEM)
    ]
    row = cache._upsert("asurascans", SLUG, {"title": "Logging"}, chapters)
    stored = json.loads(row.chapters)
    assert [c["locked_until"] for c in stored] == [None, UNLOCK]


def test_a_notification_for_a_locked_chapter_says_when_it_opens(db_session, monkeypatch):
    user = User(username="reader", password_hash="x", is_admin=False, is_active=True)
    db_session.add(user)
    db_session.commit()
    profile = ReadingProfile(user_id=user.id, name="P", sort_order=0)
    db_session.add(profile)
    db_session.add(UpdateSettings(id=1, enabled=True, notify_enabled=True))
    db_session.commit()
    follow = FollowedSeries(
        user_id=user.id,
        profile_id=profile.id,
        source_id="asurascans",
        series_key=SLUG,
        title="Logging 10,000 Years into the Future",
        notify=True,
        known_chapters=json.dumps([{"key": f"{SLUG}/chapter/368", "number": 368, "title": "Chapter 368"}]),
    )
    db_session.add(follow)
    db_session.commit()

    live = [
        {"id": f"{SLUG}/chapter/368", "number": 368.0, "title": "Chapter 368", "locked_until": None},
        {"id": f"{SLUG}/chapter/369", "number": 369.0, "title": "Chapter 369", "locked_until": None},
        {"id": f"{SLUG}/chapter/370", "number": 370.0, "title": "Chapter 370", "locked_until": UNLOCK},
        # A value no connector should write is "not locked", never a failed sweep.
        {"id": f"{SLUG}/chapter/371", "number": 371.0, "title": "Chapter 371", "locked_until": 12345},
    ]
    monkeypatch.setattr(
        browse_service.BrowseService, "get_chapters", lambda self, source_id, series_id: live
    )

    service = UpdateService(db_session, user_id=user.id, profile_id=profile.id)
    service.check_followed_by_id(follow.id)

    rows = db_session.execute(
        select(UpdateNotification).order_by(UpdateNotification.chapter_number)
    ).scalars().all()
    assert [(r.chapter_number, r.locked_until) for r in rows] == [
        (369.0, None),
        (370.0, UNLOCK),
        (371.0, None),
    ]
    by_number = {n["chapter_number"]: n for n in service.list_notifications()}
    assert by_number[370.0]["locked_until"] == UNLOCK
    assert by_number[369.0]["locked_until"] is None

    known = json.loads(db_session.get(FollowedSeries, follow.id).known_chapters)
    assert [c.get("locked_until") for c in known] == [None, None, UNLOCK, 12345]
