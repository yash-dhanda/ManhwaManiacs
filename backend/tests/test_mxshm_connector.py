from __future__ import annotations

from pathlib import Path
from unittest.mock import patch

import pytest

from connectors.http.client import ConnectorHttpError
from connectors.http.redirect_policy import host_matches_allowlist
from connectors.mxshm.connector import (
    MxshmConnector,
    page_id_chapter_id,
    parse_chapter_pages,
    parse_chapters,
    parse_series_detail,
    parse_series_list,
)

FIXTURES = Path(__file__).parent / "fixtures" / "mxshm"
CDN = "www.jjmhw9.top"
CHALLENGE = "<html><title>Just a moment...</title>Enable JavaScript and cookies to continue</html>"


def _load(name: str) -> str:
    return (FIXTURES / name).read_text(encoding="utf-8")


@pytest.fixture
def connector() -> MxshmConnector:
    return MxshmConnector()


def _route(routes: dict[str, str]):
    calls: list[tuple[str, dict | None]] = []

    def fake(path: str, *, params=None):
        calls.append((path, params))
        if path in routes:
            return routes[path]
        raise ConnectorHttpError("Retryable HTTP 500", status_code=500)  # site's unknown-id answer

    return fake, calls


def test_identity(connector: MxshmConnector):
    assert connector.source_type == "mxshm"
    assert connector.is_mature is True
    assert connector.image_fetch_headers() == {}


def test_parse_booklist():
    listing = parse_series_list(_load("booklist_p1.html"), page=1)
    assert len(listing.items) == 12
    assert listing.has_more is True
    assert listing.items[0].id == "1248"
    assert listing.items[0].title == "一家有多妻"
    assert listing.items[0].cover_url == f"https://{CDN}/static/upload/book/1248/cover.jpg"


def test_last_and_past_end_pages():
    assert parse_series_list(_load("booklist_last.html"), page=45).has_more is False
    empty = parse_series_list(_load("booklist_empty.html"), page=46)
    assert empty.items == [] and empty.has_more is False


def test_browse_learns_cdn_host(connector: MxshmConnector):
    assert connector.allowed_image_hosts == frozenset()
    fake, calls = _route({"/booklist": _load("booklist_p1.html")})
    with patch.object(connector._http, "get_text", side_effect=fake):
        listing = connector.get_series_list(2)
    assert calls == [("/booklist", {"page": "2"})]
    assert len(listing.items) == 12
    assert connector.allowed_image_hosts == frozenset({CDN})
    assert not host_matches_allowlist("jjmhw9.top.evil.com", connector.allowed_image_hosts)


def test_search(connector: MxshmConnector):
    fake, calls = _route({"/search": _load("search.html")})
    with patch.object(connector._http, "get_text", side_effect=fake):
        listing = connector.search_series("媽媽", 1)
        assert connector.search_series("媽媽", 2).items == []  # unpaginated
        assert connector.search_series("媽", 1).items == []  # one char: never sent
    assert calls == [("/search", {"keyword": "媽媽"})]
    assert listing.has_more is False
    assert sum("媽媽" in s.title for s in listing.items) >= 4


def test_parse_detail_ignores_related_shelf():
    series = parse_series_detail(_load("book_100.html"), series_id="100")
    assert series is not None
    assert series.title == "小一輪的純愛女孩"
    assert series.cover_url == f"https://{CDN}/static/upload/book/100/cover.jpg"
    assert series.author == "柚子"
    assert series.status == "completed"
    assert series.genres == ("都市",)
    assert series.description and series.description.startswith("剛入學")


def test_parse_chapters_from_list_only():
    chapters = parse_chapters(_load("book_100.html"), series_id="100")
    assert [c.id for c in chapters] == ["2742", "2774", "2793", "3196", "3218", "3697", "3719"]
    assert [c.number for c in chapters] == [1.0, 2.0, 3.0, 19.0, 20.0, 39.0, 40.0]
    assert chapters[-1].title == "第40話 - 差一輪"


def test_series_chapters_pages_find_page(connector: MxshmConnector):
    fake, calls = _route(
        {"/book/100": _load("book_100.html"), "/chapter/3196": _load("chapter_3196.html")}
    )
    with patch.object(connector._http, "get_text", side_effect=fake):
        series = connector.get_series("100")
        chapters = connector.get_chapters("/book/100")
        pages = connector.get_chapter_pages("3196")
        found = connector.find_page("3196:3")
    assert series is not None and len(chapters) == 7
    assert [c[0] for c in calls].count("/book/100") == 1  # one fetch fills both caches
    assert len(pages) == 5
    assert pages[0].remote_url == f"https://{CDN}/static/upload/book/100/3196/75959.jpg"
    assert found == pages[2]
    assert host_matches_allowlist(CDN, connector.allowed_image_hosts)


def test_hosts_only_from_upload_urls(connector: MxshmConnector):
    connector._remember_hosts(["https://ads.example.com/banner.gif", "http://x.top/static/upload/a.jpg", None])
    assert connector.allowed_image_hosts == frozenset()


def test_cloudflare_challenge_returns_empty(connector: MxshmConnector):
    with patch.object(connector._http, "get_text", return_value=CHALLENGE):
        assert connector.get_series_list(1).items == []
        assert connector.get_series("100") is None
        assert connector.get_chapter_pages("3196") == []
    assert connector.allowed_image_hosts == frozenset()


def test_failures_return_empty(connector: MxshmConnector):
    fake, _ = _route({})
    with patch.object(connector._http, "get_text", side_effect=fake):
        assert connector.get_series("999999") is None
        assert connector.get_chapters("999999") == []
        assert connector.get_chapter_pages("99999999") == []
        assert connector.find_page("99999999:1") is None
        assert connector.search_series("媽媽", 1).items == []
    assert connector.get_series("not-a-number") is None


def test_empty_page_list_not_cached(connector: MxshmConnector):
    fake, calls = _route({"/chapter/5": "<html><div class='comicpage'></div></html>"})
    with patch.object(connector._http, "get_text", side_effect=fake):
        assert connector.get_chapter_pages("5") == []
        assert connector.get_chapter_pages("5") == []
    assert len(calls) == 2
    assert parse_chapter_pages("", chapter_id="5") == []


def test_page_id_round_trip():
    assert page_id_chapter_id("3196:12") == "3196"
    assert page_id_chapter_id("abc:1") is None
