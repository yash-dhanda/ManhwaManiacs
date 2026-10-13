"""Offline tests for the Manga18.club connector.

Fixtures under ``tests/fixtures/manga18club/`` were captured live 2026-10-13
FROM THE VPS (inside the production image, so through production's egress),
then trimmed of styles, ad slots and every script except the reader's
``slides_p_path``. ``cloudflare_block.html`` is the site's real Cloudflare
"Attention Required!" page, served to a bare ``Mozilla/5.0`` User-Agent.
No test touches the network: ``_http.get_text`` is patched.
"""

from __future__ import annotations

import base64
from contextlib import contextmanager
from pathlib import Path
from typing import Any, Iterator
from unittest.mock import patch
from urllib.parse import urlparse

import pytest

from connectors.http.client import ConnectorHttpError
from connectors.manga18club.connector import (
    Manga18ClubConnector,
    normalize_chapter_key,
    normalize_series_key,
    page_id_chapter_key,
    parse_chapter_pages,
    parse_chapters,
    parse_last_page,
    parse_series_detail,
    parse_series_list,
)
from services.outbound_security import host_matches_allowlist

FIXTURES = Path(__file__).parent / "fixtures" / "manga18club"
SERIES = "secret-class"
CHAPTER = "work-me-out/chapter-15"


def _load(name: str) -> str:
    return (FIXTURES / name).read_text(encoding="utf-8")


@pytest.fixture()
def connector() -> Manga18ClubConnector:
    return Manga18ClubConnector()


@contextmanager
def _mock_site(connector: Manga18ClubConnector, calls: list[tuple[str, dict]] | None = None) -> Iterator[None]:
    def fake_get_text(path: str, *, params: dict[str, Any] | None = None) -> str:
        params = params or {}
        if calls is not None:
            calls.append((path, params))
        if path.startswith("/list-manga/"):
            if params.get("search"):
                return _load("search_boss.html")
            if params.get("order_by") == "views":
                return _load("browse_views.html")
            return _load("browse_page2.html" if path.endswith("/2") else "browse_page1.html")
        if path == f"/manhwa/{SERIES}":
            return _load("series_detail.html")
        if path == f"/manhwa/{CHAPTER}":
            return _load("chapter_reader.html")
        # Unknown series and chapters are real 404s on this site.
        raise ConnectorHttpError(f"Client error '404 Not Found' for url '{path}'")

    with patch.object(connector._http, "get_text", side_effect=fake_get_text):
        yield


def _allowed(connector: Manga18ClubConnector, url: str | None) -> bool:
    return host_matches_allowlist(urlparse(url or "").hostname or "", connector.allowed_image_hosts)


# --- identity -----------------------------------------------------------------


def test_keys_normalize_from_any_inbound_shape():
    assert normalize_series_key(SERIES) == SERIES
    assert normalize_series_key("https://manga18.club/manhwa/secret-class") == SERIES
    assert normalize_series_key("/manhwa/secret-class/") == SERIES
    assert normalize_chapter_key("https://manga18.club/manhwa/work-me-out/chapter-15") == CHAPTER
    assert normalize_chapter_key(CHAPTER) == CHAPTER
    assert normalize_chapter_key(SERIES) == ""
    assert page_id_chapter_key(f"{CHAPTER}:3") == CHAPTER
    assert page_id_chapter_key("no-separator") is None


# --- listings -----------------------------------------------------------------


def test_browse_reads_every_card_and_the_pagers_last_page():
    listing = parse_series_list(_load("browse_page1.html"), page=1)
    assert len(listing.items) == 20
    first = listing.items[0]
    assert (first.id, first.title) == ("the-man-on-the-rise-raw", "The Man on the Rise Raw")
    assert first.cover_url == "https://cdn.manga18.club/manga/the-man-on-the-rise-raw/cover/cover_thumb_2.webp"
    assert parse_last_page(_load("browse_page2.html")) == 165
    assert listing.total == 165 * 20 and listing.has_more is True


def test_page_two_and_most_views_are_different_requests(connector: Manga18ClubConnector):
    calls: list[tuple[str, dict]] = []
    with _mock_site(connector, calls):
        page1 = connector.get_series_list(1)
        page2 = connector.get_series_list(2)
        popular = connector.get_series_list(1, sort="popular")
    assert calls == [("/list-manga/1", {}), ("/list-manga/2", {}), ("/list-manga/1", {"order_by": "views"})]
    assert {s.id for s in page1.items}.isdisjoint({s.id for s in page2.items})
    assert popular.items[0].id == SERIES
    assert [m.id for m in connector.list_browse_modes()] == ["default", "popular"]


def test_search_sends_the_query_and_reads_its_two_page_pager(connector: Manga18ClubConnector):
    calls: list[tuple[str, dict]] = []
    with _mock_site(connector, calls):
        result = connector.search_series(" boss ", 2)
    assert calls == [("/list-manga/2", {"search": "boss"})]
    assert any("boss" in s.title.casefold() for s in result.items)
    # The fixture is page 1 of 2, so as page 2 it is the last one.
    assert result.has_more is False
    assert parse_series_list(_load("search_boss.html"), page=1).has_more is True


# --- detail / chapters ----------------------------------------------------------


def test_detail_reads_every_field_and_takes_the_cover_from_the_cdn():
    series = parse_series_detail(_load("series_detail.html"), SERIES)
    assert series is not None
    assert series.title == "Secret Class"
    # og:image names azmin.manga18.club, which does not resolve.
    assert series.cover_url == "https://cdn.manga18.club/manga/secret-class/cover/cover_250x350.jpg"
    assert (series.author, series.artist, series.status) == ("Wang Kang Cheol", "Mina-Chan", "On Going")
    assert series.genres == ("Adult", "Romance", "Drama", "Smut", "Manhwa", "Mature")
    assert series.description and "Dae-ho" in series.description


def test_placeholder_credits_are_none():
    html = _load("series_detail.html").replace("Wang Kang Cheol", "Updating")
    assert parse_series_detail(html, SERIES).author is None


def test_chapters_read_labels_not_slugs_and_include_hidden_rows():
    chapters = parse_chapters(_load("series_detail.html"), SERIES)
    # Every row, including the ``li.hide`` ones and labels carrying a flag <img>.
    assert len(chapters) == 334
    by_id = {c.id: c for c in chapters}
    assert by_id["secret-class/chapter-316-uncen"].number == 316.5
    assert by_id["secret-class/chap-289"].number == 289.0
    assert by_id["secret-class/100"].title == "Chapter 100"
    assert by_id["secret-class/chapter-309-6"].number == 309.6
    numbers = [c.number for c in chapters]
    assert numbers == sorted(numbers)
    assert chapters[-1].id == "secret-class/chapter-320"


def test_detail_and_chapters_share_one_fetch(connector: Manga18ClubConnector):
    calls: list[tuple[str, dict]] = []
    with _mock_site(connector, calls):
        series = connector.get_series(SERIES)
        chapters = connector.get_chapters(f"https://manga18.club/manhwa/{SERIES}")
    assert len(calls) == 1
    assert series is not None and series.chapter_count == len(chapters) == 334
    assert series.latest_chapter == "Chapter 320"
    assert _allowed(connector, series.cover_url)


def test_missing_series_is_none(connector: Manga18ClubConnector):
    with _mock_site(connector):
        assert connector.get_series("zz-no-such-series") is None
        assert connector.get_chapters("zz-no-such-series") == []
        assert connector.get_series("") is None


# --- reader -------------------------------------------------------------------


def test_reader_pages_are_the_base64_slides_in_order(connector: Manga18ClubConnector):
    with _mock_site(connector):
        pages = connector.get_chapter_pages(CHAPTER)
        assert connector.find_page(pages[4].id) == pages[4]
    assert len(pages) == 23
    assert [p.number for p in pages] == list(range(1, 24))
    assert pages[0].remote_url == "https://cdn.manga18.club/manga/work-me-out/chapters/chapter-15/01.jpg"
    assert all(_allowed(connector, p.remote_url) for p in pages)


def test_undecodable_or_non_https_slides_are_skipped():
    good = base64.b64encode(b"https://cdn.manga18.club/a/01.jpg").decode()
    plain = base64.b64encode(b"http://cdn.manga18.club/a/02.jpg").decode()
    html = f'var slides_p_path = ["{good}","not base64!","{plain}"];'
    pages = parse_chapter_pages(html, CHAPTER)
    assert [p.remote_url for p in pages] == ["https://cdn.manga18.club/a/01.jpg"]


def test_a_reader_without_slides_is_empty_and_not_cached(connector: Manga18ClubConnector):
    html = _load("chapter_reader.html")
    stripped = html.replace("var slides_p_path", "var gone")
    assert parse_chapter_pages(stripped, CHAPTER) == []
    with patch.object(connector._http, "get_text", side_effect=[stripped, html]):
        assert connector.get_chapter_pages(CHAPTER) == []
        assert len(connector.get_chapter_pages(CHAPTER)) == 23


def test_missing_chapter_is_empty(connector: Manga18ClubConnector):
    with _mock_site(connector):
        assert connector.get_chapter_pages("work-me-out/chapter-9999") == []
        assert connector.get_chapter_pages("work-me-out") == []
        assert connector.find_page("garbage") is None


# --- failure paths ----------------------------------------------------------------


def test_a_cloudflare_page_served_as_200_answers_empty_everywhere(connector: Manga18ClubConnector):
    block = _load("cloudflare_block.html")
    with patch.object(connector._http, "get_text", return_value=block):
        listing = connector.get_series_list(1)
        assert listing.items == [] and listing.has_more is False
        assert connector.search_series("boss", 1).items == []
        assert connector.get_series(SERIES) is None
        assert connector.get_chapter_pages(CHAPTER) == []


def test_an_upstream_error_answers_empty_instead_of_raising(connector: Manga18ClubConnector):
    error = ConnectorHttpError("Client error '403 Forbidden'", status_code=403)
    with patch.object(connector._http, "get_text", side_effect=error):
        assert connector.get_series_list(1).items == []
        assert connector.search_series("boss", 1).has_more is False
        assert connector.get_series(SERIES) is None
        assert connector.get_chapters(SERIES) == []
        assert connector.get_chapter_pages(CHAPTER) == []


# --- descriptor -----------------------------------------------------------------


def test_descriptor(connector: Manga18ClubConnector):
    assert connector.source_type == "manga18club"
    assert connector.is_mature is True
    assert connector.is_browsable is True
    # Only the CDN: the og:image host azmin.manga18.club must not be proxied.
    assert connector.allowed_image_hosts == frozenset({"cdn.manga18.club"})
    assert not _allowed(connector, "https://azmin.manga18.club/uploads/x.jpg")
    assert connector.image_fetch_headers() == {}
