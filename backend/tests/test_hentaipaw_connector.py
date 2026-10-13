"""HentaiPaw connector: offline against pages captured from the VPS 2026-10-13."""

from __future__ import annotations

from pathlib import Path
from typing import Any

from connectors.hentaipaw.connector import (
    SITE_BASE,
    HentaiPawConnector,
    normalize_article_id,
    parse_detail,
    parse_listing,
    parse_viewer_pages,
)
from connectors.http.cf_client import CfSyncHttpClient
from connectors.http.client import ConnectorHttpError

FIXTURES = Path(__file__).parent / "fixtures" / "hentaipaw"
ARTICLE = "3410192"


def _fixture(name: str) -> str:
    return (FIXTURES / name).read_text(encoding="utf-8")


class _FakeHttp:
    """Answers ``get_text`` from a route table; records every call."""

    def __init__(self, routes: dict[str, str | Exception]) -> None:
        self.routes = routes
        self.calls: list[tuple[str, dict[str, Any] | None]] = []

    def get_text(self, path: str, *, params: dict[str, Any] | None = None) -> str:
        self.calls.append((path, params))
        answer = self.routes[path]
        if isinstance(answer, Exception):
            raise answer
        return answer


def _connector(routes: dict[str, str | Exception]) -> tuple[HentaiPawConnector, _FakeHttp]:
    http = _FakeHttp(routes)
    return HentaiPawConnector(http_client=http), http


# --- parsers ----------------------------------------------------------------


def test_home_listing_parses_ranking_and_latest_cards() -> None:
    listing = parse_listing(_fixture("home.html"), page=1)
    assert len(listing.items) == 40  # 10 daily-ranking + 30 newest
    first = listing.items[0]
    assert first.id == ARTICLE
    # The title attribute, not the img alt that appends ", English".
    assert first.title == "My Landlady Noona (decensored)"
    assert first.cover_url == f"https://cdn.imagedeliveries.com/{ARTICLE}/thumbnails/cover.webp"
    assert listing.has_more is True


def test_second_listing_page_and_search() -> None:
    assert len(parse_listing(_fixture("home_page2.html"), page=2).items) == 30
    search = parse_listing(_fixture("search_sister.html"), page=1)
    assert len(search.items) == 30
    assert all("sister" in s.title.lower() for s in search.items[:5])
    assert search.has_more is True


def test_empty_search_has_no_more() -> None:
    listing = parse_listing(_fixture("search_empty.html"), page=1)
    assert listing.items == []
    assert listing.has_more is False


def test_detail_parses_facets_and_page_count() -> None:
    series, chapter = parse_detail(_fixture("article_3410192.html"), ARTICLE)
    assert series is not None and chapter is not None
    assert series.title == "My Landlady Noona (decensored)"
    assert series.cover_url.endswith(f"/{ARTICLE}/thumbnails/cover.webp")
    assert series.genres == ("Hentai Manga", "English", "original", "uncensored", "webtoon")
    assert series.artist is None  # both Artists and Groups read N/A
    assert chapter.id == ARTICLE and chapter.page_count == 95


def test_detail_404_page_does_not_parse() -> None:
    assert parse_detail(_fixture("article_404.html"), "999999999") == (None, None)


def test_viewer_pages_are_ordered_and_only_this_article() -> None:
    pages = parse_viewer_pages(_fixture("viewer_3410192.html"), ARTICLE)
    assert len(pages) == 95
    assert [p.number for p in pages] == list(range(1, 96))
    assert pages[0].id == f"{ARTICLE}:1"
    assert all(f"imagedeliveries.com/{ARTICLE}/" in p.remote_url for p in pages)
    assert all("/thumbnails/" not in p.remote_url for p in pages)
    assert pages[-1].remote_url.endswith("/95.webp")


def test_normalize_article_id_accepts_paths_and_urls() -> None:
    assert normalize_article_id(ARTICLE) == ARTICLE
    assert normalize_article_id(f"/articles/{ARTICLE}") == ARTICLE
    assert normalize_article_id(f"{SITE_BASE}/viewer?articleId={ARTICLE}&page=3") == ARTICLE


# --- connector --------------------------------------------------------------


def test_browse_and_search_requests() -> None:
    connector, http = _connector(
        {"/": _fixture("home.html"), "/articles/search": _fixture("search_sister.html")}
    )
    assert len(connector.get_series_list(1).items) == 40
    connector.get_series_list(2)
    assert len(connector.search_series(" sister ", 1).items) == 30
    assert http.calls == [
        ("/", None),
        ("/", {"page": 2}),
        ("/articles/search", {"keyword": "sister", "page": 1}),
    ]


def test_series_chapters_pages_and_find_page_share_fetches() -> None:
    connector, http = _connector(
        {
            f"/articles/{ARTICLE}": _fixture("article_3410192.html"),
            "/viewer": _fixture("viewer_3410192.html"),
        }
    )
    series = connector.get_series(ARTICLE)
    chapters = connector.get_chapters(ARTICLE)
    pages = connector.get_chapter_pages(chapters[0].id)
    assert series is not None and series.title.startswith("My Landlady")
    assert len(chapters) == 1 and chapters[0].page_count == len(pages) == 95
    assert connector.find_page(f"{ARTICLE}:50") == pages[49]
    assert connector.find_page("garbage") is None
    # detail once (series + chapters), viewer once (pages + find_page)
    assert http.calls == [
        (f"/articles/{ARTICLE}", None),
        ("/viewer", {"articleId": ARTICLE, "page": 1}),
    ]


def test_failures_answer_empty_instead_of_raising() -> None:
    boom = ConnectorHttpError("Client error '404 Not Found'", status_code=404)
    connector, _http = _connector(
        {"/": boom, "/articles/search": boom, "/articles/1": boom, "/viewer": boom}
    )
    assert connector.get_series_list(1).items == []
    assert connector.search_series("x", 1).has_more is False
    assert connector.get_series("1") is None
    assert connector.get_chapters("1") == []
    assert connector.get_chapter_pages("1") == []
    assert connector.find_page("1:1") is None


def test_viewer_without_slides_is_an_empty_chapter_and_not_cached() -> None:
    connector, http = _connector({"/viewer": _fixture("search_empty.html")})
    assert connector.get_chapter_pages(ARTICLE) == []
    assert connector.get_chapter_pages(ARTICLE) == []
    assert len(http.calls) == 2


class _CurlResponse:
    status_code = 403
    reason = "Forbidden"
    headers: dict[str, str] = {}
    text = (
        "<!DOCTYPE html><html><head><title>Just a moment...</title></head>"
        "<body>Enable JavaScript and cookies to continue</body></html>"
    )


class _CurlSession:
    def request(self, *_args: Any, **_kwargs: Any) -> _CurlResponse:
        return _CurlResponse()


def test_cloudflare_challenge_answers_empty() -> None:
    http = CfSyncHttpClient(SITE_BASE, max_retries=1)
    http._session = _CurlSession()
    connector = HentaiPawConnector(http_client=http)
    assert connector.get_series_list(1).items == []
    assert connector.get_series(ARTICLE) is None
    assert connector.get_chapter_pages(ARTICLE) == []


def test_descriptor() -> None:
    connector = HentaiPawConnector(http_client=_FakeHttp({}))
    assert connector.source_type == "hentaipaw"
    assert connector.is_mature is True
    assert connector.allowed_image_hosts == frozenset({"imagedeliveries.com"})
    assert connector.image_fetch_headers() == {}
