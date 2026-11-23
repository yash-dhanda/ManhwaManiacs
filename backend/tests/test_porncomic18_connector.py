from __future__ import annotations

from pathlib import Path
from unittest.mock import patch

import pytest

from connectors.porncomic18.connector import PornComic18Connector
from connectors.registry import create_connector


FIXTURES = Path(__file__).parent / "fixtures" / "porncomic18"


@pytest.fixture
def porncomic18_connector() -> PornComic18Connector:
    return PornComic18Connector()


def test_list_series_from_fixture(porncomic18_connector: PornComic18Connector):
    html = (FIXTURES / "listing.html").read_text(encoding="utf-8")

    with patch.object(porncomic18_connector, "_fetch_html", return_value=html):
        listing = porncomic18_connector.get_series_list(1)

    assert len(listing.items) == 20
    assert listing.items[0].id == "hypnotizing-maomao-manga"
    assert listing.has_more is True


def test_get_chapters_and_pages(porncomic18_connector: PornComic18Connector):
    series_html = (FIXTURES / "series.html").read_text(encoding="utf-8")
    chapter_html = (FIXTURES / "chapter.html").read_text(encoding="utf-8")

    def fake_fetch(path: str) -> str:
        if path == "/comic/secret-class":
            return series_html
        if path == "/comic/secret-class/chapter-242":
            return chapter_html
        raise AssertionError(path)

    with patch.object(porncomic18_connector, "_fetch_html", side_effect=fake_fetch):
        series = porncomic18_connector.get_series("secret-class")
        chapters = porncomic18_connector.get_chapters("secret-class")
        pages = porncomic18_connector.get_chapter_pages("secret-class/chapter-242")

    assert series is not None
    assert series.title == "Secret Class"
    assert len(chapters) == 243
    assert len(pages) == 35
    assert pages[0].remote_url.endswith("/01.jpg")
    assert porncomic18_connector.find_page(pages[0].id) == pages[0]


def test_english_chapter_link_is_parsed():
    from connectors.porncomic18.mappers import parse_chapters

    html = """
    <a title="Sample English" href="/comic/sample-doujin/english" class="chapter_num"># English</a>
    """
    chapters = parse_chapters(html, series_id="sample-doujin")
    assert len(chapters) == 1
    assert chapters[0].id == "sample-doujin/english"
    assert chapters[0].title == "English"


def test_browse_by_genre_uses_manga_list(porncomic18_connector: PornComic18Connector):
    listing_html = (FIXTURES / "listing.html").read_text(encoding="utf-8")

    with patch.object(porncomic18_connector, "_fetch_html", return_value=listing_html) as mock_fetch:
        listing = porncomic18_connector.browse_by_genre("yuri", 1)

    mock_fetch.assert_called_once_with("/manga-list/yuri")
    assert len(listing.items) == 20


def test_create_18porncomic_connector():
    connector = create_connector("18porncomic")
    assert connector.source_type == "18porncomic"
    assert connector.is_mature is True


# --- 2026-11-23 probe of 18porncomic.com ---------------------------------------

from connectors.base import ChapterLockedError  # noqa: E402,F401
from connectors.http import swallowed  # noqa: E402
from connectors.http.client import ConnectorHttpError  # noqa: E402
from connectors.porncomic18 import mappers  # noqa: E402


def _read(name: str) -> str:
    return (FIXTURES / name).read_text(encoding="utf-8")


def test_sort_uses_the_sites_order_by_parameter():
    """``?sort=views`` is ignored by the site (the page came back identical to
    the unsorted one); its own sort links use ``order_by=views|name``."""
    assert mappers.listing_path(1, sort="popular") == "/list-manga?order_by=views"
    assert mappers.listing_path(2, sort="name") == "/list-manga/2?order_by=name"
    assert mappers.listing_path(1) == "/list-manga"
    assert mappers.listing_path(3, sort="popular", query="maid") == (
        "/list-manga/3?search=maid&order_by=views"
    )
    assert mappers.genre_listing_path("yuri", 2, sort="popular") == "/manga-list/yuri/2?order_by=views"
    assert mappers.genre_listing_path("yuri", 1) == "/manga-list/yuri"


def test_browse_modes_are_distinct_sorts(porncomic18_connector: PornComic18Connector):
    modes = [mode.id for mode in porncomic18_connector.list_browse_modes()]
    assert modes == ["latest", "popular", "name"]


def test_popular_browse_requests_order_by_views(porncomic18_connector: PornComic18Connector):
    html = _read("listing.html")
    with patch.object(porncomic18_connector, "_fetch_html", return_value=html) as fetch:
        porncomic18_connector.get_series_list(1, sort="popular")
        porncomic18_connector.browse_by_genre("yuri", 1, sort="popular")
    assert [call.args[0] for call in fetch.call_args_list] == [
        "/list-manga?order_by=views",
        "/manga-list/yuri?order_by=views",
    ]


def test_last_page_reports_the_real_total():
    html = _read("listing.html")
    last = max(int(n) for n in mappers.PAGINATION_RE.findall(html))
    listing = mappers.parse_series_list(html, page=last)
    assert listing.has_more is False
    assert listing.total == (last - 1) * mappers.PAGE_SIZE + len(listing.items)


def test_chapters_are_oldest_first_with_iso_dates():
    chapters = mappers.parse_chapters(_read("series_ordering.html"), series_id="boarding-diary-uncensored")
    assert [c.id.split("/", 1)[1] for c in chapters] == ["2-a", "2-b", "chapter-108"]
    assert chapters[-1].release_date == "2024-09-24"  # printed "24-09-2024", day first
    assert all(c.release_date and len(c.release_date) == 10 for c in chapters)
    series = mappers.parse_series_detail(
        _read("series_ordering.html"), series_id="boarding-diary-uncensored"
    )
    assert series is not None
    assert series.latest_chapter == chapters[-1].title


def test_lettered_parts_do_not_share_a_number():
    chapters = mappers.parse_chapters(_read("series_ordering.html"), series_id="boarding-diary-uncensored")
    by_id = {c.id.split("/", 1)[1]: c.number for c in chapters}
    assert by_id["2-a"] == 2.0
    assert by_id["2-b"] == pytest.approx(2.1)
    assert by_id["chapter-108"] == 108.0


def test_decimal_chapters_keep_their_decimal():
    """``chapter-129-5`` is chapter 129.5; it used to be 129 -- the same number
    as chapter 129 itself, so progress on one counted as the other."""
    chapters = mappers.parse_chapters(_read("chapter_rows_decimals.html"), series_id="the-hole-is-open")
    numbers = {c.id.split("/", 1)[1]: c.number for c in chapters}
    assert numbers == {"chapter-1": 1.0, "chapter-129": 129.0, "chapter-129-5": 129.5}
    assert [c.number for c in chapters] == [1.0, 129.0, 129.5]


def test_translated_editions_use_the_sites_ordinal():
    """Kirtu series list a Hindi edition as "2.5 . ... Chapter 2 - Hindi"; it
    shared 2.0 with the English chapter 2."""
    chapters = mappers.parse_chapters(_read("chapter_rows_ordinals.html"), series_id="savita-bhabhi-kirtu")
    assert [c.number for c in chapters] == [2.0, 2.5, 150.0]
    assert len({c.number for c in chapters}) == len(chapters)


def test_placeholder_author_and_empty_description_are_none():
    series = mappers.parse_series_detail(_read("series_ordering.html"), series_id="boarding-diary-uncensored")
    assert series is not None
    assert series.author is None and series.artist is None
    assert series.description is None


def test_series_failure_is_noted_but_missing_is_not(porncomic18_connector: PornComic18Connector):
    blocked = ConnectorHttpError("blocked", status_code=403)
    with patch.object(porncomic18_connector, "_fetch_html", side_effect=blocked):
        with swallowed.capture() as noted:
            assert porncomic18_connector.get_series("x") is None
            assert porncomic18_connector.get_chapters("x") == []
    assert noted == [blocked, blocked]

    missing = ConnectorHttpError("Not Found", status_code=404)
    with patch.object(porncomic18_connector, "_fetch_html", side_effect=missing):
        with swallowed.capture() as noted:
            assert porncomic18_connector.get_series("gone") is None
    assert noted == []


def test_empty_chapter_list_from_failure_is_not_cached(porncomic18_connector: PornComic18Connector):
    series_html = (FIXTURES / "series.html").read_text(encoding="utf-8")
    with patch.object(
        porncomic18_connector,
        "_fetch_html",
        side_effect=[ConnectorHttpError("boom", status_code=502), series_html],
    ):
        assert porncomic18_connector.get_chapters("secret-class") == []
        assert len(porncomic18_connector.get_chapters("secret-class")) == 243


def test_chapter_pages_failure_propagates(porncomic18_connector: PornComic18Connector):
    with patch.object(
        porncomic18_connector,
        "_fetch_html",
        side_effect=ConnectorHttpError("boom", status_code=502),
    ):
        with pytest.raises(ConnectorHttpError):
            porncomic18_connector.get_chapter_pages("secret-class/chapter-1")
    with patch.object(
        porncomic18_connector,
        "_fetch_html",
        side_effect=ConnectorHttpError("nope", status_code=404),
    ):
        assert porncomic18_connector.get_chapter_pages("secret-class/chapter-1") == []


def test_every_mode_and_legacy_id_maps_to_its_request(porncomic18_connector: PornComic18Connector):
    html = _read("listing.html")
    expected = {
        None: "/list-manga",
        "default": "/list-manga",
        "latest": "/list-manga",
        "new": "/list-manga",  # never advertised; always resolved to the default
        "popular": "/list-manga?order_by=views",
        "name": "/list-manga?order_by=name",
    }
    for sort, path in expected.items():
        with patch.object(porncomic18_connector, "_fetch_html", return_value=html) as fetch:
            porncomic18_connector.get_series_list(1, sort=sort)
        assert fetch.call_args.args[0] == path, sort
