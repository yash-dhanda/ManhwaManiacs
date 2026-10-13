"""HentaiPaw online source connector (adult galleries, Next.js SSR HTML).

Endpoint map (verified from the VPS 2026-10-13, inside the production backend
image, so through production's exact egress):

* ``/?page=N``                                -- listing. Page 1 leads with a
  10-card "Daily Ranking" strip, then 30 newest; later pages are 30 newest.
* ``/articles/search?keyword=Q&page=N``       -- search, same card markup.
* ``/articles/<id>``                          -- detail: h1 title, facet rows
  (Artists/Groups/Parodies/Characters/Tags/Language/Category), one thumbnail
  per page.
* ``/viewer?articleId=<id>&page=1``           -- the reader. Its RSC payload
  carries EVERY page as ``cdn.imagedeliveries.com/<id>/<sha1>/<n>.<ext>``,
  so one GET opens the whole chapter.

An article is one gallery, so it is published as a single chapter whose key
is the article id. Unknown ids answer a real 404. No Referer is needed on the
CDN: covers and pages came back 200 from a bare httpx GET.
"""

from __future__ import annotations

import html as html_lib
import logging
import re
from typing import Any

from connectors.base import SourceConnector
from connectors.http.cache import TTLCache
from connectors.http.cf_client import CfSyncHttpClient
from connectors.http.client import ConnectorHttpError
from connectors.models import BrowseMode, Chapter, Page, PaginatedSeriesList, Series

logger = logging.getLogger(__name__)

SITE_BASE = "https://hentaipaw.com"

#: Covers, thumbnails and page images all live on ``cdn.imagedeliveries.com``.
IMAGE_HOST_SUFFIX = "imagedeliveries.com"

#: Cards per listing page after page 1 (page 1 adds the ranking strip).
PAGE_SIZE = 30

#: Separates the article id from the 1-based page index in a page id.
PAGE_ID_SEPARATOR = ":"

CHAPTER_TITLE = "Gallery"

# --- parsing ----------------------------------------------------------------

# One listing card: the anchor, its cover <img>, and the title div whose
# ``title`` attribute is the bare title (the img alt appends ", <Language>").
_CARD_RE = re.compile(
    r'<a[^>]+href="/articles/(?P<id>\d+)"[^>]*>\s*<div[^>]*>\s*'
    r'<img[^>]*?src="(?P<cover>[^"]+)"[^>]*>.*?'
    r'<div class="line-clamp-2[^"]*" title="(?P<title>[^"]*)"',
    re.S,
)
_PAGE_LINK_RE = re.compile(r'href="[^"]*[?&](?:amp;)?page=(\d+)')
_H1_RE = re.compile(r"<h1[^>]*>(.*?)</h1>", re.S)
_DETAIL_COVER_RE = re.compile(
    r'<img src="(https://cdn\.imagedeliveries\.com/\d+/thumbnails/cover\.[a-z]+)"'
)
# One facet row: ``<h3>Label<!-- -->:</h3>`` then chips or a ``N/A`` <p>,
# up to the next row.
_FACET_RE = re.compile(
    r'<h3[^>]*>([^<]+)<!-- -->:</h3>(.*?)(?=<div class="flex flex-wrap gap-1">|</div></div></div>)',
    re.S,
)
_CHIP_RE = re.compile(r'<a href="/[a-z]+/\d+"><div[^>]*>([^<]+)</div></a>')
_TAG_RE = re.compile(r"<[^>]+>")


def _clean(value: str | None) -> str | None:
    text = html_lib.unescape(_TAG_RE.sub("", value or "")).strip()
    return text or None


def normalize_article_id(value: str) -> str:
    """The numeric article id, from a bare id, a path or a full URL."""
    text = (value or "").strip()
    match = re.search(r"(?:articles/|articleId=)(\d+)", text)
    if match:
        return match.group(1)
    return text.strip("/")


def canonical_path(article_id: str) -> str:
    return f"/articles/{article_id}"


def make_page_id(article_id: str, number: int) -> str:
    return f"{article_id}{PAGE_ID_SEPARATOR}{number}"


def page_id_article_id(page_id: str) -> str | None:
    article_id, sep, _index = (page_id or "").rpartition(PAGE_ID_SEPARATOR)
    if not sep or not article_id:
        return None
    return article_id


def parse_listing(html: str, *, page: int) -> PaginatedSeriesList:
    """Cards from a home or search page; ``has_more`` from the pager links."""
    items: list[Series] = []
    seen: set[str] = set()
    for match in _CARD_RE.finditer(html):
        article_id = match.group("id")
        title = _clean(match.group("title"))
        if not title or article_id in seen:
            continue
        seen.add(article_id)
        items.append(
            Series(
                id=article_id,
                title=title,
                canonical_path=canonical_path(article_id),
                cover_url=html_lib.unescape(match.group("cover")),
                status="completed",
                chapter_count=1,
                latest_chapter=CHAPTER_TITLE,
            )
        )
    # The pager always links the last page, so any number above ours means
    # there is more; the last page links nothing beyond itself.
    highest = max((int(n) for n in _PAGE_LINK_RE.findall(html)), default=0)
    return PaginatedSeriesList(
        items=items,
        page=page,
        page_size=PAGE_SIZE,
        total=len(items),
        api_has_more=bool(items) and highest > page,
    )


def parse_detail(html: str, article_id: str) -> tuple[Series | None, Chapter | None]:
    """The detail page as a Series and its single gallery Chapter."""
    title_match = _H1_RE.search(html)
    title = _clean(title_match.group(1)) if title_match else None
    if not title:
        return None, None

    facets: dict[str, tuple[str, ...]] = {}
    for label, body in _FACET_RE.findall(html):
        names = tuple(n for n in (_clean(c) for c in _CHIP_RE.findall(body)) if n)
        facets[label.strip().lower()] = names

    artists = facets.get("artists") or facets.get("groups") or ()
    # Category and language are their own rows here; folding them into genres
    # keeps the chips reading like the other registered gallery sources.
    genres = (
        facets.get("category", ())
        + facets.get("language", ())
        + facets.get("parodies", ())
        + facets.get("tags", ())
    )
    page_count = len(set(re.findall(rf"imagedeliveries\.com/{article_id}/thumbnails/(\d+)\.", html)))
    cover = _DETAIL_COVER_RE.search(html)

    series = Series(
        id=article_id,
        title=title,
        canonical_path=canonical_path(article_id),
        cover_url=cover.group(1) if cover else None,
        artist=", ".join(artists) if artists else None,
        status="completed",
        genres=genres,
        chapter_count=1,
        latest_chapter=f"{page_count} pages" if page_count else CHAPTER_TITLE,
    )
    chapter = Chapter(
        id=article_id,
        series_id=article_id,
        title=CHAPTER_TITLE,
        number=1.0,
        page_count=page_count,
    )
    return series, chapter


def parse_viewer_pages(html: str, article_id: str) -> list[Page]:
    """Every page URL in the viewer's RSC payload, ordered by page number.

    Anchored on this article's id and the sha1 path segment, so thumbnails,
    the cover and other articles' covers in the sidebar never match.
    """
    pattern = re.compile(
        rf"https://cdn\.imagedeliveries\.com/{re.escape(article_id)}/[0-9a-f]{{40}}/(\d+)\.[A-Za-z0-9]+"
    )
    by_number: dict[int, str] = {}
    for match in pattern.finditer(html):
        by_number.setdefault(int(match.group(1)), match.group(0))
    return [
        Page(
            id=make_page_id(article_id, index),
            chapter_id=article_id,
            number=index,
            remote_url=url,
        )
        for index, (_n, url) in enumerate(sorted(by_number.items()), start=1)
    ]


# --- connector --------------------------------------------------------------


class HentaiPawConnector(SourceConnector):
    """Browse and read adult galleries from HentaiPaw.

    Request budget: browse/search 1 GET; series + chapter list 1 GET (shared
    through ``_detail_cache``); chapter open 1 GET; images 0 here.

    Every upstream failure -- network, 404, Cloudflare interstitial -- is
    logged and answered empty, never raised.
    """

    SOURCE_TYPE = "hentaipaw"
    DISPLAY_NAME = "HentaiPaw"
    DESCRIPTION = (
        "Browse and read adult doujinshi, manga and webtoons from HentaiPaw. "
        "Images are proxied through ManhwaManiacs."
    )
    BROWSABLE = True
    SUPPORTS_IMPORT = False
    MATURE = True

    def __init__(self, *, http_client: Any | None = None) -> None:
        # curl_cffi: the site sits behind Cloudflare, and this client also
        # recognises a challenge page instead of parsing it as zero cards.
        self._http = http_client or CfSyncHttpClient(SITE_BASE)
        self._detail_cache: TTLCache[tuple[Series, Chapter]] = TTLCache(ttl_seconds=300.0)
        self._page_cache: TTLCache[list[Page]] = TTLCache(ttl_seconds=600.0)

    @property
    def source_type(self) -> str:
        return self.SOURCE_TYPE

    @property
    def display_name(self) -> str:
        return self.DISPLAY_NAME

    @property
    def description(self) -> str:
        return self.DESCRIPTION

    @property
    def is_browsable(self) -> bool:
        return self.BROWSABLE

    @property
    def supports_import(self) -> bool:
        return self.SUPPORTS_IMPORT

    @property
    def allowed_image_hosts(self) -> frozenset[str]:
        return frozenset({IMAGE_HOST_SUFFIX})

    def list_browse_modes(self) -> list[BrowseMode]:
        return [BrowseMode(id="default", label="Latest")]

    def _get(self, path: str, params: dict[str, Any] | None = None) -> str | None:
        try:
            return self._http.get_text(path, params=params)
        except ConnectorHttpError as exc:
            logger.info("HentaiPaw GET %s params=%s failed: %s", path, params or {}, exc)
            return None

    def _empty(self, page: int) -> PaginatedSeriesList:
        return PaginatedSeriesList(items=[], page=page, page_size=PAGE_SIZE, api_has_more=False)

    def get_series_list(self, page: int, *, sort: str | None = None) -> PaginatedSeriesList:
        del sort  # the site exposes one chronological listing
        page = max(page, 1)
        html = self._get("/", {"page": page} if page > 1 else None)
        return parse_listing(html, page=page) if html else self._empty(page)

    def search_series(
        self, query: str, page: int, *, sort: str | None = None
    ) -> PaginatedSeriesList:
        page = max(page, 1)
        keyword = query.strip()
        if not keyword:
            return self.get_series_list(page, sort=sort)
        html = self._get("/articles/search", {"keyword": keyword, "page": page})
        return parse_listing(html, page=page) if html else self._empty(page)

    def _detail(self, series_id: str) -> tuple[Series, Chapter] | None:
        article_id = normalize_article_id(series_id)
        cached = self._detail_cache.get(article_id)
        if cached is not None:
            return cached
        html = self._get(canonical_path(article_id))
        if not html:
            return None
        series, chapter = parse_detail(html, article_id)
        if series is None or chapter is None:
            logger.info("HentaiPaw detail %s did not parse", article_id)
            return None
        self._detail_cache.set(article_id, (series, chapter))
        return series, chapter

    def get_series(self, series_id: str) -> Series | None:
        detail = self._detail(series_id)
        return detail[0] if detail else None

    def get_chapters(self, series_id: str) -> list[Chapter]:
        detail = self._detail(series_id)
        return [detail[1]] if detail else []

    def get_chapter_pages(self, chapter_id: str) -> list[Page]:
        # A gallery is its own chapter: the chapter key IS the article id.
        article_id = normalize_article_id(chapter_id)
        cached = self._page_cache.get(article_id)
        if cached is not None:
            return cached
        html = self._get("/viewer", {"articleId": article_id, "page": 1})
        pages = parse_viewer_pages(html, article_id) if html else []
        if pages:
            self._page_cache.set(article_id, pages)
        return pages

    def find_page(self, page_id: str) -> Page | None:
        article_id = page_id_article_id(page_id)
        if article_id is None:
            return None
        for page in self.get_chapter_pages(article_id):
            if page.id == page_id:
                return page
        return None
