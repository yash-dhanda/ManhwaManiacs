from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path
from unittest.mock import patch

import pytest

from connectors.asurascans.connector import AsuraScansConnector
from connectors.asurascans.mappers import chapter_locked_until, chapter_pages_to_pages
from connectors.registry import create_connector, list_installed_connectors
from services.browse_service import _serialize_page


FIXTURES = Path(__file__).parent / "fixtures" / "asurascans"


def _load(name: str) -> dict:
    return json.loads((FIXTURES / name).read_text(encoding="utf-8"))


@pytest.fixture
def asurascans_connector() -> AsuraScansConnector:
    return AsuraScansConnector()


def test_registry_lists_asurascans():
    browsable = [item.source_type for item in list_installed_connectors(browsable_only=True)]
    assert "asurascans" in browsable
    assert "mangadex" in browsable


def test_list_series_uses_asurascans_api(asurascans_connector: AsuraScansConnector):
    listing_payload = _load("series_list.json")

    with patch.object(asurascans_connector._http, "get_json", return_value=listing_payload):
        listing = asurascans_connector.get_series_list(1)

    assert listing.total == 333
    assert len(listing.items) == 20
    assert listing.items[0].id == "return-of-the-mount-hua-sect-30e93729"
    assert listing.items[0].title == "Return of the Mount Hua Sect"


def test_search_series_uses_search_param(asurascans_connector: AsuraScansConnector):
    listing_payload = _load("series_search.json")

    with patch.object(asurascans_connector._http, "get_json", return_value=listing_payload) as mock_get:
        listing = asurascans_connector.search_series("solo", 1)

    params = mock_get.call_args.kwargs["params"]
    assert params["search"] == "solo"
    assert params["offset"] == 0
    assert params["limit"] == 20
    assert listing.total >= 1
    assert any("solo" in item.title.casefold() for item in listing.items)


def test_list_series_page_2_uses_offset(asurascans_connector: AsuraScansConnector):
    listing_payload = _load("series_list.json")
    captured: list[dict] = []

    def fake_get_json(path: str, *, params=None):
        captured.append(dict(params or {}))
        return listing_payload

    with patch.object(asurascans_connector._http, "get_json", side_effect=fake_get_json):
        asurascans_connector.get_series_list(1)
        asurascans_connector.get_series_list(2, sort="popular")

    assert captured[0]["offset"] == 0
    assert captured[1]["offset"] == 20
    assert captured[1]["sort"] == "popular"

def test_browse_modes_canonical_order(asurascans_connector: AsuraScansConnector):
    assert [m.id for m in asurascans_connector.list_browse_modes()] == [
        "default", "popular", "latest", "new", "trending", "rating",
    ]


@pytest.mark.parametrize(
    ("sort", "expected"),
    [
        (None, None),
        ("default", None),
        ("popular", "popular"),
        ("latest", "latest"),
        ("new", "updated"),
        ("updated", "updated"),
        ("trending", "trending"),
        ("rating", "rating"),
    ],
)
def test_browse_sort_requests(asurascans_connector: AsuraScansConnector, sort, expected):
    payload = _load("series_list.json")
    with patch.object(asurascans_connector._http, "get_json", return_value=payload) as mock_get:
        asurascans_connector.get_series_list(2, sort=sort)
    params = mock_get.call_args.kwargs["params"]
    assert params.get("sort") == expected
    assert params["offset"] == 20


@pytest.mark.parametrize("fixture_name", ["chapter_pages.json", "chapter_pages_mount.json"])
def test_chapter_page_extraction_preserves_every_page(fixture_name: str):
    """Regression: extraction must emit exactly one page per source payload entry.

    Fails if even a single page is dropped, duplicated, or reordered between the
    AsuraScans API payload and the connector's normalized page list.
    """
    payload = _load(fixture_name)
    raw_pages = payload["data"]["chapter"]["pages"]
    chapter_id = "series-x:1"

    pages = chapter_pages_to_pages(chapter_id, payload)

    assert len(pages) == len(raw_pages)
    assert [page.number for page in pages] == list(range(1, len(raw_pages) + 1))
    assert [page.remote_url for page in pages] == [entry["url"] for entry in raw_pages]
    assert [page.id for page in pages] == [
        f"{chapter_id}:{index}" for index in range(1, len(raw_pages) + 1)
    ]


@pytest.mark.parametrize("fixture_name", ["chapter_pages.json", "chapter_pages_mount.json"])
def test_chapter_page_serialization_preserves_every_page(fixture_name: str):
    """Regression: API serialization must keep a 1:1 mapping with extracted pages."""
    payload = _load(fixture_name)
    raw_pages = payload["data"]["chapter"]["pages"]
    pages = chapter_pages_to_pages("series-x:1", payload)

    serialized = [_serialize_page(page, "asurascans") for page in pages]

    assert len(serialized) == len(raw_pages)
    assert [item["number"] for item in serialized] == list(range(1, len(raw_pages) + 1))
    assert all(item["image_url"].startswith("/sources/asurascans/pages/") for item in serialized)


def test_early_access_chapter_carries_its_unlock_time():
    # Real row from the fixture: chapter 169, is_locked + is_premium, unlocks 2026-06-30T23:04Z.
    locked = _load("chapter_list.json")["data"][0]
    assert locked["number"] == 169 and locked["is_locked"] is True

    unlock = datetime.fromisoformat(locked["unlock_time"].replace("Z", "+00:00"))
    assert chapter_locked_until(locked) == unlock.astimezone(timezone.utc).strftime(
        "%Y-%m-%dT%H:%M:%SZ"
    )


def test_the_list_spelling_asura_sends_now_is_read_too():
    # 2026-11-23: no ``is_locked`` on list rows any more, only these two.
    row = {"number": 370, "is_premium": True, "early_access_until": "2026-11-23T14:15:24.018266Z"}
    assert chapter_locked_until(row) == "2026-11-23T14:15:24Z"


def test_locked_without_a_readable_unlock_time_has_no_instant():
    # Still listed; the reader says "locked" without a countdown when its pages are asked for.
    assert chapter_locked_until({"is_locked": True}) is None
    assert chapter_locked_until({"is_locked": True, "unlock_time": "garbage"}) is None
    assert chapter_locked_until({"is_locked": True, "unlock_time": None}) is None


def test_unlocked_and_unflagged_chapters_are_not_locked():
    free = _load("chapter_list.json")["data"][1]
    assert free["is_locked"] is False
    assert chapter_locked_until(free) is None
    assert chapter_locked_until({"number": 1}) is None
    # is_premium alone (a paid chapter that is already open) is not a lock.
    assert chapter_locked_until(
        {"is_premium": True, "is_locked": False, "early_access_until": "2999-01-01T00:00:00Z"}
    ) is None


def test_get_chapters_lists_early_access_chapters_with_their_unlock_time(
    asurascans_connector: AsuraScansConnector,
):
    """They used to be left out until they opened. The clients count down to
    the instant now, so the chapter is listed and says when."""
    payload = _load("chapter_list.json")
    payload["data"][0]["unlock_time"] = "2999-01-01T00:00:00Z"
    total = len(payload["data"])

    with patch.object(asurascans_connector._http, "get_json", return_value=payload):
        chapters = asurascans_connector.get_chapters("return-of-the-mount-hua-sect")

    assert len(chapters) == total
    assert chapters[-1].number == 169  # ascending order: the newest is last
    assert chapters[-1].locked_until == "2999-01-01T00:00:00Z"
    assert all(chapter.locked_until is None for chapter in chapters[:-1])


@pytest.mark.integration
def test_asurascans_sequential_live_requests():
    connector = AsuraScansConnector()
    try:
        listing = connector.get_series_list(1)
        assert listing.items
        for series_id in [item.id for item in listing.items[:5]]:
            series = connector.get_series(series_id)
            chapters = connector.get_chapters(series_id)
            assert series is not None, series_id
            assert series.id == series_id
            assert chapters, series_id
    finally:
        connector._http.close()


def test_create_asurascans_connector():
    connector = create_connector("asurascans")
    assert connector.source_type == "asurascans"


def test_images_go_through_the_browser_fingerprint_client():
    """cdn.asurascans.com answers a plain client with a Cloudflare challenge."""
    from connectors.asurascans.connector import AsuraScansConnector

    class FakeImageClient:
        def __init__(self) -> None:
            self.urls: list[str] = []

        def get_bytes(self, url: str):
            self.urls.append(url)
            return "image/webp", b"RIFFxxxxWEBP"

    connector = AsuraScansConnector()
    fake = FakeImageClient()
    connector._image_local.client = fake
    url = "https://cdn.asurascans.com/asura-images/chapters/x/1/a.webp?v=1"
    assert connector.fetch_proxied_image(url) == ("image/webp", b"RIFFxxxxWEBP")
    assert fake.urls == [url]
