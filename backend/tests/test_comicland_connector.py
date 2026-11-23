from __future__ import annotations

import json
from pathlib import Path
from unittest.mock import patch

import pytest

from connectors.comicland.connector import ComicLandConnector


FIXTURES = Path(__file__).parent / "fixtures" / "comicland"


def _load(name: str) -> dict | list:
    return json.loads((FIXTURES / name).read_text(encoding="utf-8"))


@pytest.fixture
def comicland_connector() -> ComicLandConnector:
    return ComicLandConnector()


def test_connector_metadata(comicland_connector: ComicLandConnector):
    assert comicland_connector.source_type == "comicland"
    assert comicland_connector.display_name == "ComicLand"
    assert comicland_connector.is_mature is True
    assert comicland_connector.is_browsable is True
    assert "cdn.comicland.org" in comicland_connector.allowed_image_hosts
    modes = {mode.id for mode in comicland_connector.list_browse_modes()}
    assert modes == {"new", "popular", "ongoing", "official", "uncensored"}
    # first mode stays the one sort=None returns; ``latest`` is retired (alias)
    assert [m.id for m in comicland_connector.list_browse_modes()][:2] == ["new", "popular"]
    assert comicland_connector.LEGACY_SORT_ALIASES == {"latest": "new"}


def _fake_catalogue(total: int):
    """Stand-in for ``/comics``: id-ascending, offset/limit, no sort, no total."""
    calls: list[dict] = []

    def fake_get_json(path, *, params=None):
        assert path == "/comics"
        calls.append(dict(params))
        offset, limit = params["offset"], params["limit"]
        ids = range(offset + 1, min(offset + limit, total) + 1)
        return {
            "code": 0,
            "data": {
                "list": [
                    {"id": i, "slug": f"series-{i}", "title": f"Series {i}", "cover_url": None}
                    for i in ids
                ]
            },
        }

    return fake_get_json, calls


@pytest.mark.parametrize("sort", [None, "default", "latest", "new"])
def test_new_and_its_aliases_list_newest_added_first(
    comicland_connector: ComicLandConnector, sort
):
    fake, calls = _fake_catalogue(57)
    with patch.object(comicland_connector._http, "get_json", side_effect=fake):
        page1 = comicland_connector.get_series_list(1, sort=sort)
        page2 = comicland_connector.get_series_list(2, sort=sort)
        page3 = comicland_connector.get_series_list(3, sort=sort)
        page4 = comicland_connector.get_series_list(4, sort=sort)
    # tail window, newest first; each page continues the one before
    assert [i.id for i in page1.items] == [f"series-{n}" for n in range(57, 37, -1)]
    assert [i.id for i in page2.items][0] == "series-37"
    assert [i.id for i in page3.items] == [f"series-{n}" for n in range(17, 0, -1)]
    assert page1.has_more and page2.has_more and not page3.has_more
    assert page4.items == [] and not page4.has_more
    assert page1.total == 57
    # the size probe is cached: later pages only add their own window request
    windows = [c for c in calls if c["limit"] != 1]
    assert windows == [
        {"offset": 37, "limit": 20},
        {"offset": 17, "limit": 20},
        {"offset": 0, "limit": 17},
    ]


def test_catalogue_size_is_found_with_a_handful_of_one_item_requests(
    comicland_connector: ComicLandConnector,
):
    fake, calls = _fake_catalogue(2500)
    with patch.object(comicland_connector._http, "get_json", side_effect=fake):
        listing = comicland_connector.get_series_list(1, sort="new")
    assert listing.items[0].id == "series-2500"
    probes = [c for c in calls if c["limit"] == 1]
    assert len(probes) <= 16


def test_recommend_is_still_the_plain_catalogue_listing(comicland_connector: ComicLandConnector):
    payload = _load("comics_list.json")
    with patch.object(comicland_connector._http, "get_json", return_value=payload) as mock_get:
        listing = comicland_connector.get_series_list(1, sort="recommend")
    mock_get.assert_called_once_with("/comics", params={"offset": 0, "limit": 20})
    assert listing.items[0].id == "my-kingdom-silent-war"


def test_list_series_popular_slices(comicland_connector: ComicLandConnector):
    payload = _load("popular.json")

    with patch.object(comicland_connector._http, "get_json", return_value=payload) as mock_get:
        page1 = comicland_connector.get_series_list(1, sort="popular")
        page2 = comicland_connector.get_series_list(2, sort="popular")

    mock_get.assert_called_once_with("/comics/popular", params=None)
    assert len(page1.items) == 2
    assert page1.has_more is False
    assert page2.items == []


def test_search_series(comicland_connector: ComicLandConnector):
    payload = _load("search.json")

    with patch.object(comicland_connector._http, "get_json", return_value=payload) as mock_get:
        listing = comicland_connector.search_series("secret", 1)

    mock_get.assert_called_once_with(
        "/comic/search",
        params={"offset": 0, "limit": 20, "q": "secret"},
    )
    assert len(listing.items) == 2
    assert listing.has_more is True
    assert listing.total == 60


def test_get_series_and_chapters(comicland_connector: ComicLandConnector):
    detail = _load("comic_detail.json")

    with patch.object(comicland_connector._http, "get_json", return_value=detail):
        series = comicland_connector.get_series("my-kingdom-silent-war")
        chapters = comicland_connector.get_chapters("my-kingdom-silent-war")

    assert series is not None
    assert series.title == "My Kingdom (Silent War)"
    assert series.chapter_count == 3
    assert len(chapters) == 3
    assert chapters[0].id == "my-kingdom-silent-war/chapters/3"
    assert chapters[0].number == 3.0
    assert chapters[-1].id == "my-kingdom-silent-war/chapters/1"


def test_chapter_pages(comicland_connector: ComicLandConnector):
    pages_payload = _load("chapter_pages.json")
    chapter_id = "my-kingdom-silent-war/chapters/1"

    with patch.object(comicland_connector._http, "get_json", return_value=pages_payload) as mock_get:
        pages = comicland_connector.get_chapter_pages(chapter_id)

    mock_get.assert_called_once_with(
        "/chapter/pages_by_index",
        params={"slug": "my-kingdom-silent-war", "index": 1},
    )
    assert len(pages) == 3
    assert pages[0].number == 1
    assert pages[0].remote_url.endswith("/001.jpg")
    assert pages[0].id == f"{chapter_id}:1"
    found = comicland_connector.find_page(f"{chapter_id}:2")
    assert found is not None
    assert found.number == 2


def test_browse_by_genre(comicland_connector: ComicLandConnector):
    payload = _load("comics_list.json")

    with patch.object(comicland_connector._http, "get_json", return_value=payload) as mock_get:
        listing = comicland_connector.browse_by_genre("romance", 2)

    mock_get.assert_called_once_with(
        "/comics_by_genre",
        params={"offset": 20, "limit": 20, "name": "romance"},
    )
    assert len(listing.items) == 2
