from __future__ import annotations

import json
from pathlib import Path
from unittest.mock import patch

import pytest

from connectors.aurorascans.connector import AuroraScansConnector
from connectors.registry import create_connector, list_installed_connectors


FIXTURES = Path(__file__).parent / "fixtures" / "aurorascans"


def _load(name: str) -> dict | list:
    return json.loads((FIXTURES / name).read_text(encoding="utf-8"))


@pytest.fixture
def aurorascans_connector() -> AuroraScansConnector:
    return AuroraScansConnector()


def test_registry_lists_aurorascans():
    browsable = [item.source_type for item in list_installed_connectors(browsable_only=True)]
    assert "aurorascans" in browsable
    connector = create_connector("aurorascans")
    assert type(connector).__name__ == "AuroraScansConnector"


def test_list_series_uses_qimanga_api(aurorascans_connector: AuroraScansConnector):
    listing_payload = _load("series_list.json")

    with patch.object(aurorascans_connector._http, "get_json", return_value=listing_payload) as mock_get:
        listing = aurorascans_connector.get_series_list(1, sort="latest")

    mock_get.assert_called_once_with(
        "/series",
        params={"page": 1, "perPage": 20, "sort": "latest"},
    )
    assert listing.total == 818
    assert len(listing.items) == 2
    assert listing.items[0].id == "the-artist-who-paints-dungeon"
    assert listing.has_more is True


def test_search_series_uses_search_endpoint(aurorascans_connector: AuroraScansConnector):
    listing_payload = _load("series_list.json")

    with patch.object(aurorascans_connector._http, "get_json", return_value=listing_payload) as mock_get:
        listing = aurorascans_connector.search_series("dungeon", 1)

    mock_get.assert_called_once_with(
        "/series/search",
        params={"page": 1, "perPage": 20, "q": "dungeon"},
    )
    assert len(listing.items) == 2


def test_search_series_omits_sort_param(aurorascans_connector: AuroraScansConnector):
    """/series/search returns 400 if `sort` is present; /series (browse) requires it.

    Regression test for production incident: AuroraScans search sent
    `sort=latest` on every request, upstream returned 400 for all of them,
    and 10 consecutive failures tripped DEAD_AFTER_FAILURES, demoting a
    healthy source. Verified in-container that the identical request minus
    `sort` returns 200 with results.
    """
    listing_payload = _load("series_list.json")

    with patch.object(aurorascans_connector._http, "get_json", return_value=listing_payload) as mock_get:
        aurorascans_connector.search_series("solo", 1, sort="latest")

    _, kwargs = mock_get.call_args
    assert "sort" not in kwargs["params"], "search request must not carry `sort` — upstream returns 400"

    with patch.object(aurorascans_connector._http, "get_json", return_value=listing_payload) as mock_get:
        aurorascans_connector.get_series_list(1, sort="latest")

    _, kwargs = mock_get.call_args
    assert kwargs["params"]["sort"] == "latest", "browse listing should still send sort"


def test_get_series_and_chapters(aurorascans_connector: AuroraScansConnector):
    detail_payload = _load("series_detail.json")
    chapter_payload = _load("chapter_list.json")

    with patch.object(
        aurorascans_connector._http,
        "get_json",
        side_effect=[detail_payload, chapter_payload],
    ):
        series = aurorascans_connector.get_series("the-artist-who-paints-dungeon")
        chapters = aurorascans_connector.get_chapters("the-artist-who-paints-dungeon")

    assert series is not None
    assert series.title == "The Artist Who Paints Dungeon"
    assert series.chapter_count == 8
    assert len(chapters) == 1
    assert chapters[0].id == "the-artist-who-paints-dungeon/chapters/chapter-10"
    assert chapters[0].title == "Chapter 10"


def test_chapter_pages(aurorascans_connector: AuroraScansConnector):
    pages_payload = _load("chapter_pages.json")
    chapter_id = "the-artist-who-paints-dungeon/chapters/chapter-10"

    with patch.object(aurorascans_connector._http, "get_json", return_value=pages_payload):
        pages = aurorascans_connector.get_chapter_pages(chapter_id)

    assert len(pages) == 2
    assert pages[0].number == 1
    assert pages[0].remote_url.endswith("00.webp")
    assert pages[1].number == 2


# --- 2026-11-23 probe: chapter list, locks, failure behaviour ------------------

from connectors.base import ChapterLockedError  # noqa: E402
from connectors.http import swallowed  # noqa: E402
from connectors.http.client import ConnectorHttpError  # noqa: E402

SNAKE = "snake-immortal:-the-tale-of-a-snake's-cultivation-to-immortality"


def test_chapter_list_titles_numbers_and_paid_chapters_dropped(
    aurorascans_connector: AuroraScansConnector,
):
    """Real rows from the QiManga API (2026-11-23): chapter 114 is a coin
    chapter (dropped), 67's title is the bare numeral "67" (a worse label than
    "Chapter 67"), 0 and 0.5 are legitimate numbers, 13 has a real title."""
    pages = [_load("chapter_list_mixed_p1.json"), _load("chapter_list_mixed_p2.json")]
    with patch.object(aurorascans_connector._http, "get_json", side_effect=pages) as mock_get:
        chapters = aurorascans_connector.get_chapters(SNAKE)

    assert mock_get.call_count == 2
    assert [c.number for c in chapters] == [0.0, 0.5, 13.0, 67.0]
    by_number = {c.number: c for c in chapters}
    assert by_number[67.0].title == "Chapter 67"
    assert by_number[0.5].title == "Chapter 0.5"
    assert by_number[13.0].title not in {"13", "Chapter 13"}
    assert all(c.id.startswith(f"{SNAKE}/chapters/") for c in chapters)
    assert all(c.release_date and len(c.release_date) == 10 for c in chapters)


def test_chapter_list_failure_on_later_page_raises_instead_of_returning_short(
    aurorascans_connector: AuroraScansConnector,
):
    """A list missing its tail looked complete to the reader and was cached for
    three minutes. Page 2 failing must surface as an error."""
    with patch.object(
        aurorascans_connector._http,
        "get_json",
        side_effect=[_load("chapter_list_mixed_p1.json"), ConnectorHttpError("boom", status_code=500)],
    ):
        with pytest.raises(ConnectorHttpError):
            aurorascans_connector.get_chapters(SNAKE)
    assert aurorascans_connector._chapter_list_cache.get(SNAKE) is None


def test_chapter_list_first_page_failure_is_noted_and_not_cached(
    aurorascans_connector: AuroraScansConnector,
):
    err = ConnectorHttpError("blocked", status_code=403)
    with patch.object(aurorascans_connector._http, "get_json", side_effect=err):
        with swallowed.capture() as noted:
            assert aurorascans_connector.get_chapters("some-series") == []
    assert noted == [err]
    assert aurorascans_connector._chapter_list_cache.get("some-series") is None


def test_get_series_failure_is_noted(aurorascans_connector: AuroraScansConnector):
    err = ConnectorHttpError("blocked", status_code=403)
    with patch.object(aurorascans_connector._http, "get_json", side_effect=err):
        with swallowed.capture() as noted:
            assert aurorascans_connector.get_series("some-series") is None
    assert noted == [err]


def test_paid_chapter_pages_raise_locked_without_instant(
    aurorascans_connector: AuroraScansConnector,
):
    """Coin chapter payload: 200, ``images: []``, ``requiresPurchase: true``,
    ``becameFreeAt: null``. It used to come back as [] ("Chapter not found")."""
    payload = _load("chapter_pages_requires_purchase.json")
    with patch.object(aurorascans_connector._http, "get_json", return_value=payload):
        with pytest.raises(ChapterLockedError) as info:
            aurorascans_connector.get_chapter_pages(f"{SNAKE}/chapters/chapter-114")
    assert info.value.locked_until is None
    assert (
        aurorascans_connector.find_page(f"{SNAKE}/chapters/chapter-114:1") is None
    )


def test_chapter_pages_failure_propagates_but_404_is_empty(
    aurorascans_connector: AuroraScansConnector,
):
    chapter_id = "some-series/chapters/chapter-1"
    with patch.object(
        aurorascans_connector._http,
        "get_json",
        side_effect=ConnectorHttpError("boom", status_code=502),
    ):
        with pytest.raises(ConnectorHttpError):
            aurorascans_connector.get_chapter_pages(chapter_id)
    with patch.object(
        aurorascans_connector._http,
        "get_json",
        side_effect=ConnectorHttpError("nope", status_code=404),
    ):
        assert aurorascans_connector.get_chapter_pages(chapter_id) == []
    assert aurorascans_connector._page_cache.get(chapter_id) is None


def test_browse_modes_are_the_sorts_the_api_accepts(
    aurorascans_connector: AuroraScansConnector,
):
    """/series 400s on anything but latest/newest/popular/alphabetical
    (2026-11-23). "Top Rated" was a second button for ``popular``."""
    from connectors.aurorascans.mappers import resolve_sort

    ids = [mode.id for mode in aurorascans_connector.list_browse_modes()]
    assert {resolve_sort(i) for i in ids} <= {"latest", "newest", "popular", "alphabetical"}
    assert len({resolve_sort(i) for i in ids}) == len(ids)


def test_description_keeps_paragraph_breaks():
    from connectors.aurorascans.mappers import series_detail_to_series

    series = series_detail_to_series(
        {
            "slug": "x",
            "title": "X",
            "description": "<p>First &amp; best.</p><p>Second   paragraph.</p>",
            "stats": {"chapterCount": 1},
        }
    )
    assert series is not None
    assert series.description == "First & best.\n\nSecond paragraph."


def test_browse_modes_canonical_order_and_requests(aurorascans_connector: AuroraScansConnector):
    assert [m.id for m in aurorascans_connector.list_browse_modes()] == [
        "latest", "popular", "new", "alphabetical",
    ]
    listing_payload = _load("series_list.json")
    expected = {
        None: "latest", "default": "latest", "latest": "latest", "popular": "popular",
        "new": "newest", "newest": "newest", "alphabetical": "alphabetical",
        "top_rated": "popular",  # legacy id, no longer advertised
    }
    for sort, api_sort in expected.items():
        with patch.object(aurorascans_connector._http, "get_json", return_value=listing_payload) as mock_get:
            aurorascans_connector.get_series_list(1, sort=sort)
        assert mock_get.call_args.kwargs["params"]["sort"] == api_sort, sort
