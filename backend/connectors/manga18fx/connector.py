"""Manga18fx online source connector (adult manhwa, custom PHP site).

Endpoint map (verified from the VPS 2026-10-13, inside the production image,
so through production's exact egress; plain httpx clears Cloudflare there):

* ``/page/N``                 -- latest updates, 24 ``div.thumb-manga`` cards.
  Page 1 is the bare ``/``. The pager prints only a five-page window and no
  last page, so "more" is read from its ``li.next`` link.
* ``/search?q=<terms>&page=N`` -- same card markup, same pager.
* ``/manga/<slug>``           -- detail AND the full chapter list in one
  document (``a.chapter-name``, newest-first). An unknown slug does not 404:
  it 302s to the home page, which carries no ``div.post-title`` -- that is
  how a missing series is told apart from a parse failure.
* ``/manga/<slug>/<chapter>`` -- reader; every page is an inline
  ``<img class="loading pN" data-src=...>`` on ``img02.manga18fx.com``.
  An unknown chapter is a real 404.

Covers live on the apex (``manga18fx.com/webtoon/...``) and pages on
``img0N.manga18fx.com``, so one suffix allowlists both. Neither CDN checks the
Referer (both answered 200 without one); it is sent anyway because it is what
a browser sends and costs nothing.

``manga18.me`` mirrors this catalogue; it must never be registered as well.

Keys: a series is its slug; a chapter is ``<slug>/<chapter-slug>`` (the
chapter slug is the site's own and is not always ``chapter-N``); a page is
``<chapter key>:<n>``. Slugs never contain a colon.
"""

from __future__ import annotations

import html as html_lib
import logging
import re
from dataclasses import replace
from typing import Any

from connectors.base import SourceConnector
from connectors.http.cache import TTLCache
from connectors.http.client import ConnectorHttpError, SyncConnectorHttpClient
from connectors.ids import fully_unquote
from connectors.models import Chapter, Page, PaginatedSeriesList, Series

logger = logging.getLogger(__name__)

SITE_BASE = "https://manga18fx.com"
IMAGE_HOST_SUFFIX = "manga18fx.com"
#: Cards per listing page, counted on browse and search alike.
PAGE_SIZE = 24
PAGE_ID_SEPARATOR = ":"

BROWSER_USER_AGENT = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
)
HTML_HEADERS = {
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.9",
    "Referer": f"{SITE_BASE}/",
}

# --- markup -------------------------------------------------------------------

CARD_SPLIT = '<div class="thumb-manga">'
CARD_LINK_RE = re.compile(r'<a href="/manga/([^"/?#]+)" title="([^"]*)"')
CARD_IMG_RE = re.compile(r'<img[^>]*data-src="([^"]+)"')
#: A pager with an enabled "next" arrow. On the last page the arrow renders as
#: ``<li class="next disabled"><span>`` with no anchor.
NEXT_PAGE_RE = re.compile(r'<li class="next"><a ')

TITLE_RE = re.compile(r'<div class="post-title">\s*<h1>(.*?)</h1>', re.S)
OG_IMAGE_RE = re.compile(r'<meta property="og:image" content="([^"]+)"')
DESC_RE = re.compile(r'<div class="dsct">(.*?)</div>', re.S)
STATUS_RE = re.compile(
    r'Status\s*</h5>\s*</div>\s*<div class="summary-content"[^>]*>(.*?)</div>', re.S
)
ANCHOR_TEXT_RE = re.compile(r"<a [^>]*>(.*?)</a>", re.S)
CHAPTER_NUMBER_RE = re.compile(r"(\d+(?:\.\d+)?)")
PAGE_IMG_RE = re.compile(r'<img class="loading p\d+"[^>]*data-src="([^"]+)"')


def _block_re(css_class: str) -> re.Pattern[str]:
    return re.compile(rf'<div class="{css_class}">(.*?)</div>', re.S)


AUTHOR_RE = _block_re("author-content")
ARTIST_RE = _block_re("artist-content")
GENRES_RE = _block_re("genres-content")


def _clean(value: str) -> str:
    text = re.sub(r"<[^>]+>", " ", value or "")
    return html_lib.unescape(re.sub(r"\s+", " ", text)).strip()


def _anchors(html: str, pattern: re.Pattern[str]) -> tuple[str, ...]:
    match = pattern.search(html)
    if match is None:
        return ()
    return tuple(t for t in (_clean(a) for a in ANCHOR_TEXT_RE.findall(match.group(1))) if t)


# --- identity -----------------------------------------------------------------


def normalize_series_key(value: str) -> str:
    """``my-sweet-boss`` from a bare slug, a ``/manga/...`` path or a full URL."""
    text = fully_unquote(str(value or "")).strip()
    text = re.sub(r"^https?://[^/]+", "", text).strip("/")
    text = text.removeprefix("manga/")
    return text.split("/", 1)[0]


def normalize_chapter_key(value: str) -> str:
    """``my-sweet-boss/chapter-18``; empty when either half is missing."""
    text = fully_unquote(str(value or "")).strip()
    text = re.sub(r"^https?://[^/]+", "", text).strip("/")
    parts = text.removeprefix("manga/").split("/")
    if len(parts) < 2 or not parts[0] or not parts[1]:
        return ""
    return f"{parts[0]}/{parts[1]}"


def page_id_chapter_key(page_id: str) -> str | None:
    chapter_key, sep, _index = (page_id or "").rpartition(PAGE_ID_SEPARATOR)
    return chapter_key if sep and chapter_key else None


def chapter_number(label: str, chapter_slug: str) -> float | None:
    """From the label ("Chapter 10.5"), else the slug ("chapter-10-5")."""
    match = CHAPTER_NUMBER_RE.search(label or "")
    if match:
        return float(match.group(1))
    match = re.search(r"(\d+)(?:-(\d+))?$", chapter_slug or "")
    if match is None:
        return None
    return float(match.group(1) + (f".{match.group(2)}" if match.group(2) else ""))


# --- parsing ------------------------------------------------------------------


def parse_series_list(html: str, *, page: int) -> PaginatedSeriesList:
    items: list[Series] = []
    seen: set[str] = set()
    for chunk in html.split(CARD_SPLIT)[1:]:
        link = CARD_LINK_RE.search(chunk)
        if link is None or link.group(1) in seen:
            continue
        slug = link.group(1)
        seen.add(slug)
        img = CARD_IMG_RE.search(chunk)
        items.append(
            Series(
                id=slug,
                title=_clean(link.group(2)),
                cover_url=html_lib.unescape(img.group(1)) if img else None,
                canonical_path=f"/manga/{slug}",
            )
        )
    has_more = bool(items) and NEXT_PAGE_RE.search(html) is not None
    # No result count is published; the honest total is what has been seen so
    # far, plus one more page when the pager offers one.
    total = (page - 1) * PAGE_SIZE + len(items) + (PAGE_SIZE if has_more else 0)
    return PaginatedSeriesList(
        items=items, page=page, page_size=PAGE_SIZE, total=total, api_has_more=has_more
    )


def parse_series_detail(html: str, series_key: str) -> Series | None:
    title = TITLE_RE.search(html)
    if title is None:
        return None
    cover = OG_IMAGE_RE.search(html)
    desc = DESC_RE.search(html)
    status = STATUS_RE.search(html)
    authors = _anchors(html, AUTHOR_RE)
    artists = _anchors(html, ARTIST_RE)
    return Series(
        id=series_key,
        title=_clean(title.group(1)),
        canonical_path=f"/manga/{series_key}",
        description=_clean(desc.group(1)) or None if desc else None,
        cover_url=html_lib.unescape(cover.group(1)) if cover else None,
        author=", ".join(authors) or None,
        artist=", ".join(artists) or None,
        status=_clean(status.group(1)) or None if status else None,
        genres=_anchors(html, GENRES_RE),
    )


def parse_chapters(html: str, series_key: str) -> list[Chapter]:
    """Chapters oldest-first (the page lists them newest-first)."""
    pattern = re.compile(
        rf'<a class="chapter-name[^"]*" href="/manga/{re.escape(series_key)}/([^"/]+)"[^>]*>(.*?)</a>',
        re.S,
    )
    rows = pattern.findall(html)
    chapters: list[Chapter] = []
    seen: set[str] = set()
    for index, (chapter_slug, label) in enumerate(rows):
        if chapter_slug in seen:
            continue
        seen.add(chapter_slug)
        title = _clean(label) or chapter_slug
        number = chapter_number(title, chapter_slug)
        chapters.append(
            Chapter(
                id=f"{series_key}/{chapter_slug}",
                series_id=series_key,
                title=title,
                # Neither label nor slug numbered: keep the site's position.
                number=float(len(rows) - index) if number is None else number,
                page_count=0,
            )
        )
    chapters.reverse()
    # Stable: two uploads of one number (raw + translated) keep site order.
    chapters.sort(key=lambda c: c.number or 0.0)
    return chapters


def parse_chapter_pages(html: str, chapter_key: str) -> list[Page]:
    return [
        Page(
            id=f"{chapter_key}{PAGE_ID_SEPARATOR}{index}",
            chapter_id=chapter_key,
            number=index,
            remote_url=html_lib.unescape(url).strip(),
        )
        for index, url in enumerate(PAGE_IMG_RE.findall(html), start=1)
    ]


# --- connector ----------------------------------------------------------------


class Manga18fxConnector(SourceConnector):
    """Browse and read adult manhwa from Manga18fx (manga18fx.com).

    One GET per stage: listing, detail (shared by ``get_series`` and
    ``get_chapters``), chapter. Every failure answers empty rather than
    raising, so a Cloudflare wall or an outage shows as "nothing here".
    """

    SOURCE_TYPE = "manga18fx"
    DISPLAY_NAME = "Manga18fx"
    DESCRIPTION = (
        "Browse and read adult manhwa from Manga18fx. "
        "Images are proxied through ManhwaManiacs."
    )
    BROWSABLE = True
    SUPPORTS_IMPORT = False
    MATURE = True

    def __init__(self) -> None:
        self._http = SyncConnectorHttpClient(
            SITE_BASE,
            headers=HTML_HEADERS,
            user_agent=BROWSER_USER_AGENT,
        )
        self._detail_cache: TTLCache[tuple[Series, list[Chapter]]] = TTLCache(ttl_seconds=300.0)
        self._page_cache: TTLCache[list[Page]] = TTLCache(ttl_seconds=600.0)
        self._page_count_cache: TTLCache[int] = TTLCache(ttl_seconds=600.0)

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

    def image_fetch_headers(self) -> dict[str, str]:
        return {"Referer": f"{SITE_BASE}/"}

    # --- helpers --------------------------------------------------------------

    def _get(self, operation: str, path: str, params: dict[str, Any] | None = None) -> str | None:
        """The document, or ``None`` (logged) on any upstream failure."""
        try:
            return self._http.get_text(path, params=params)
        except ConnectorHttpError as exc:
            logger.info(
                "Manga18fx %s %s%s params=%s status=error detail=%s",
                operation, SITE_BASE, path, params or {}, exc,
            )
            return None

    def _listing(self, operation: str, path: str, params: dict[str, Any] | None, page: int) -> PaginatedSeriesList:
        html = self._get(operation, path, params)
        if html is None:
            return PaginatedSeriesList(items=[], page=page, page_size=PAGE_SIZE, api_has_more=False)
        return parse_series_list(html, page=page)

    def _fetch_detail(self, series_key: str) -> tuple[Series | None, list[Chapter]]:
        if not series_key:
            return None, []
        cached = self._detail_cache.get(series_key)
        if cached is not None:
            return cached
        html = self._get("detail", f"/manga/{series_key}")
        series = parse_series_detail(html, series_key) if html else None
        if series is None:
            return None, []
        chapters = parse_chapters(html, series_key)
        if chapters:
            series = replace(series, chapter_count=len(chapters), latest_chapter=chapters[-1].title)
        self._detail_cache.set(series_key, (series, chapters))
        return series, chapters

    # --- catalog --------------------------------------------------------------

    def get_series_list(self, page: int, *, sort: str | None = None) -> PaginatedSeriesList:
        del sort
        page = max(page, 1)
        return self._listing("browse", "/" if page == 1 else f"/page/{page}", None, page)

    def search_series(self, query: str, page: int, *, sort: str | None = None) -> PaginatedSeriesList:
        page = max(page, 1)
        normalized = query.strip()
        if not normalized:
            return self.get_series_list(page, sort=sort)
        return self._listing("search", "/search", {"q": normalized, "page": page}, page)

    # --- series / chapters ----------------------------------------------------

    def get_series(self, series_id: str) -> Series | None:
        return self._fetch_detail(normalize_series_key(series_id))[0]

    def get_chapters(self, series_id: str) -> list[Chapter]:
        chapters = self._fetch_detail(normalize_series_key(series_id))[1]
        return [
            replace(c, page_count=n) if (n := self._page_count_cache.get(c.id)) else c
            for c in chapters
        ]

    def get_chapter_pages(self, chapter_id: str) -> list[Page]:
        chapter_key = normalize_chapter_key(chapter_id)
        if not chapter_key:
            return []
        cached = self._page_cache.get(chapter_key)
        if cached is not None:
            return cached
        html = self._get("pages", f"/manga/{chapter_key}")
        pages = parse_chapter_pages(html, chapter_key) if html else []
        if pages:
            self._page_cache.set(chapter_key, pages)
            self._page_count_cache.set(chapter_key, len(pages))
        return pages

    def find_page(self, page_id: str) -> Page | None:
        chapter_key = page_id_chapter_key(page_id)
        if chapter_key is None:
            return None
        return next((p for p in self.get_chapter_pages(chapter_key) if p.id == page_id), None)
