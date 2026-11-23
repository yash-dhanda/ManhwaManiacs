"""Offline tests for the Manga18fx connector.

Fixtures under ``tests/fixtures/manga18fx/`` were captured live 2026-10-13
FROM THE VPS (inside the production image, so through production's egress),
then trimmed of scripts, styles and ad slots. ``cloudflare_block.html`` is
Cloudflare's real "Attention Required!" block page, captured from the same
Cloudflare edge template on manga18.club (manga18fx would not serve one on
demand). No test touches the network: ``_http.get_text`` is patched.
"""

from __future__ import annotations

from contextlib import contextmanager
from pathlib import Path
from typing import Any, Iterator
from unittest.mock import patch
from urllib.parse import urlparse

import pytest

from connectors.http.client import ConnectorHttpError
from connectors.manga18fx.connector import (
    Manga18fxConnector,
    chapter_number,
    normalize_chapter_key,
    normalize_series_key,
    page_id_chapter_key,
    parse_chapter_pages,
    parse_chapters,
    parse_series_detail,
    parse_series_list,
)
from services.outbound_security import host_matches_allowlist

FIXTURES = Path(__file__).parent / "fixtures" / "manga18fx"
SERIES = "my-sweet-boss"
CHAPTER = "my-sweet-boss/chapter-18"


def _load(name: str) -> str:
    return (FIXTURES / name).read_text(encoding="utf-8")


@pytest.fixture()
def connector() -> Manga18fxConnector:
    return Manga18fxConnector()


@contextmanager
def _mock_site(connector: Manga18fxConnector, calls: list[tuple[str, dict]] | None = None) -> Iterator[None]:
    def fake_get_text(path: str, *, params: dict[str, Any] | None = None) -> str:
        if calls is not None:
            calls.append((path, params or {}))
        if path == "/":
            return _load("browse_page1.html")
        if path == "/page/2":
            return _load("browse_page2.html")
        if path == "/search":
            return _load("search_boss.html")
        if path == f"/manga/{SERIES}":
            return _load("series_detail.html")
        if path == f"/manga/{CHAPTER}":
            return _load("chapter_reader.html")
        if path.startswith("/manga/") and path.count("/") == 2:
            # An unknown slug 302s to the home page rather than 404ing.
            return _load("browse_page1.html")
        raise ConnectorHttpError(f"Client error '404 Not Found' for url '{path}'")

    with patch.object(connector._http, "get_text", side_effect=fake_get_text):
        yield


# --- identity -----------------------------------------------------------------


def test_keys_normalize_from_any_inbound_shape():
    assert normalize_series_key(SERIES) == SERIES
    assert normalize_series_key("/manga/my-sweet-boss/") == SERIES
    assert normalize_series_key("https://manga18fx.com/manga/my-sweet-boss") == SERIES
    assert normalize_chapter_key("https://manga18fx.com/manga/my-sweet-boss/chapter-18") == CHAPTER
    assert normalize_chapter_key(CHAPTER) == CHAPTER
    assert normalize_chapter_key(SERIES) == ""
    assert page_id_chapter_key(f"{CHAPTER}:3") == CHAPTER
    assert page_id_chapter_key("no-separator") is None


def test_chapter_number_prefers_the_label_and_falls_back_to_the_slug():
    assert chapter_number("Chapter 10.5", "chapter-10-5") == 10.5
    assert chapter_number("Side story", "chapter-10-5") == 10.5
    assert chapter_number("Epilogue", "chapter-12") == 12.0
    assert chapter_number("Epilogue", "epilogue") is None


# --- listings -----------------------------------------------------------------


def test_browse_reads_every_card_with_its_cover():
    listing = parse_series_list(_load("browse_page1.html"), page=1)
    assert len(listing.items) == 24
    first = listing.items[0]
    assert (first.id, first.title) == ("love-quest", "Love Quest")
    assert first.cover_url == "https://manga18fx.com/webtoon/love-questm.jpg"
    assert all(item.cover_url for item in listing.items)
    assert listing.has_more is True


def test_page_two_is_a_different_slice(connector: Manga18fxConnector):
    calls: list[tuple[str, dict]] = []
    with _mock_site(connector, calls):
        page1 = connector.get_series_list(1)
        page2 = connector.get_series_list(2)
    assert [path for path, _ in calls] == ["/", "/page/2"]
    assert page2.page == 2
    assert {s.id for s in page1.items}.isdisjoint({s.id for s in page2.items})


def test_search_sends_q_and_page_and_matches(connector: Manga18fxConnector):
    calls: list[tuple[str, dict]] = []
    with _mock_site(connector, calls):
        result = connector.search_series("  boss ", 1)
    assert calls == [("/search", {"q": "boss", "page": 1})]
    assert result.items[0].id == SERIES
    assert sum("boss" in s.title.casefold() for s in result.items) >= 15


def test_a_pager_without_an_enabled_next_arrow_is_the_last_page():
    html = _load("search_boss.html").replace('<li class="next"><a ', '<li class="next disabled"><span ')
    assert parse_series_list(html, page=2).has_more is False


# --- detail / chapters ----------------------------------------------------------


def test_detail_reads_every_field():
    series = parse_series_detail(_load("series_detail.html"), SERIES)
    assert series is not None
    assert series.title == "My Sweet Boss"
    assert series.cover_url == "https://manga18fx.com/webtoon/my-sweet-boss-5755.jpg"
    assert (series.author, series.artist, series.status) == ("Yamong", "Saeltto", "Ongoing")
    assert series.genres[:3] == ("Adult", "Comedy", "Drama")
    assert series.description and series.description.startswith("After more than ten years")


def test_chapters_are_ascending_and_complete():
    chapters = parse_chapters(_load("series_detail.html"), SERIES)
    assert len(chapters) == 38
    assert (chapters[0].id, chapters[0].number) == ("my-sweet-boss/chapter-0", 0.0)
    assert (chapters[-1].id, chapters[-1].title) == ("my-sweet-boss/chapter-37", "Chapter 37")
    numbers = [c.number for c in chapters]
    assert numbers == sorted(numbers)


def test_detail_and_chapters_share_one_fetch_and_cover_is_proxyable(connector: Manga18fxConnector):
    calls: list[tuple[str, dict]] = []
    with _mock_site(connector, calls):
        series = connector.get_series(SERIES)
        chapters = connector.get_chapters(f"/manga/{SERIES}")
    assert len(calls) == 1
    assert series is not None and series.chapter_count == len(chapters) == 38
    assert series.latest_chapter == "Chapter 37"
    host = urlparse(series.cover_url or "").hostname or ""
    assert host_matches_allowlist(host, connector.allowed_image_hosts)


def test_unknown_slug_redirected_home_is_none(connector: Manga18fxConnector):
    assert parse_series_detail(_load("browse_page1.html"), "x") is None
    with _mock_site(connector):
        assert connector.get_series("zz-no-such-series") is None
        assert connector.get_chapters("zz-no-such-series") == []


# --- reader -------------------------------------------------------------------


def test_reader_pages_are_in_order_on_an_allowlisted_host(connector: Manga18fxConnector):
    with _mock_site(connector):
        pages = connector.get_chapter_pages(CHAPTER)
        assert connector.find_page(pages[5].id) == pages[5]
        chapters = connector.get_chapters(SERIES)
    assert len(pages) == 24
    assert [p.number for p in pages] == list(range(1, 25))
    assert pages[0].remote_url == "https://img02.manga18fx.com/chapters/5755/18/1-049.jpg"
    for page in pages:
        assert host_matches_allowlist(urlparse(page.remote_url or "").hostname or "", connector.allowed_image_hosts)
    # A chapter already read reports its page count in the list.
    assert next(c for c in chapters if c.id == CHAPTER).page_count == 24


def test_a_reader_without_images_is_empty_and_not_cached(connector: Manga18fxConnector):
    html = _load("chapter_reader.html")
    stripped = html.replace('class="loading p', 'class="gone p')
    assert parse_chapter_pages(stripped, CHAPTER) == []
    with patch.object(connector._http, "get_text", side_effect=[stripped, html]):
        assert connector.get_chapter_pages(CHAPTER) == []
        assert len(connector.get_chapter_pages(CHAPTER)) == 24


def test_missing_chapter_is_empty(connector: Manga18fxConnector):
    with _mock_site(connector):
        assert connector.get_chapter_pages(f"{SERIES}/chapter-9999") == []
        assert connector.get_chapter_pages("") == []
        assert connector.find_page("garbage") is None


# --- failure paths ----------------------------------------------------------------


def test_a_cloudflare_page_served_as_200_answers_empty_everywhere(connector: Manga18fxConnector):
    block = _load("cloudflare_block.html")
    with patch.object(connector._http, "get_text", return_value=block):
        listing = connector.get_series_list(1)
        assert listing.items == [] and listing.has_more is False
        assert connector.search_series("boss", 1).items == []
        assert connector.get_series(SERIES) is None
        assert connector.get_chapters(SERIES) == []
        assert connector.get_chapter_pages(CHAPTER) == []


def test_an_upstream_error_answers_empty_instead_of_raising(connector: Manga18fxConnector):
    error = ConnectorHttpError("Client error '403 Forbidden'", status_code=403)
    with patch.object(connector._http, "get_text", side_effect=error):
        assert connector.get_series_list(3).items == []
        assert connector.search_series("boss", 1).has_more is False
        assert connector.get_series(SERIES) is None
        assert connector.get_chapters(SERIES) == []
        assert connector.get_chapter_pages(CHAPTER) == []


# --- descriptor -----------------------------------------------------------------


def test_descriptor(connector: Manga18fxConnector):
    assert connector.source_type == "manga18fx"
    assert connector.is_mature is True
    assert connector.is_browsable is True
    assert connector.allowed_image_hosts == frozenset({"manga18fx.com"})
    assert connector.image_fetch_headers() == {"Referer": "https://manga18fx.com/"}


def test_an_unnumbered_chapter_keeps_its_place_and_chapter_zero_stays_zero():
    html = _load("series_detail.html").replace(
        'href="/manga/my-sweet-boss/chapter-37" title="My Sweet Boss Chapter 37">Chapter 37<',
        'href="/manga/my-sweet-boss/epilogue" title="Epilogue">Epilogue<',
    )
    chapters = parse_chapters(html, SERIES)
    assert chapters[-1].id == "my-sweet-boss/epilogue"
    assert chapters[0].number == 0.0
