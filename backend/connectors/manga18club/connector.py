"""Manga18.club online source connector (adult manhwa + Korean raws, custom PHP).

Endpoint map (verified from the VPS 2026-10-13, inside the production image,
so through production's exact egress; plain httpx with a browser User-Agent
clears Cloudflare there -- a bare ``Mozilla/5.0`` or curl UA gets a 403
"Attention Required!" block page instead):

* ``/list-manga/N``                -- catalogue, 20 ``div.story_images`` cards.
  ``?order_by=views`` re-sorts it (``lastest`` -- sic -- is the default). The
  pager's ``&raquo;`` link names the last page (165 at capture).
* ``/list-manga/N?search=<terms>`` -- search, same cards and pager; the path
  page number is honoured exactly like the pager's own ``?page=``.
* ``/manhwa/<slug>``               -- detail AND the full chapter list
  (``a.chapter_num``, newest-first; rows past the first few are only
  ``li.hide``, not absent, and a label can carry a language-flag ``<img>``).
  Unknown slugs are a real 404.
* ``/manhwa/<slug>/<chapter>``     -- reader. Page URLs are NOT in the markup:
  they are base64 strings in the inline ``var slides_p_path = [...]``.

Chapter slugs are not uniform even within one series (``chapter-316-uncen``,
``311``, ``chap-289``, ``chapter-309-5``), so the chapter number is read from
the link label ("Chapter 309.5"), never from the slug.

Images: covers and pages are on ``cdn.manga18.club``, no Referer needed. The
detail page's ``og:image`` points at ``azmin.manga18.club``, which does not
resolve -- the cover is taken from the ``detail_avatar`` image on the CDN, and
only the CDN host is allowlisted.

Keys: a series is its slug; a chapter is ``<slug>/<chapter-slug>``; a page is
``<chapter key>:<n>``. Slugs never contain a colon.
"""

from __future__ import annotations

import base64
import binascii
import html as html_lib
import logging
import re
from dataclasses import replace
from typing import Any

from connectors.base import SourceConnector
from connectors.http.cache import TTLCache
from connectors.http.client import ConnectorHttpError, SyncConnectorHttpClient
from connectors.ids import fully_unquote
from connectors.models import BrowseMode, Chapter, Page, PaginatedSeriesList, Series

logger = logging.getLogger(__name__)

SITE_BASE = "https://manga18.club"
IMAGE_HOST = "cdn.manga18.club"
#: Cards per listing page, counted on browse and search alike.
PAGE_SIZE = 20
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

#: Mode id -> (label, ``order_by`` value; ``None`` = the site default).
BROWSE_MODES: dict[str, tuple[str, str | None]] = {
    "default": ("Latest", None),
    "popular": ("Most Views", "views"),
}

# --- markup -------------------------------------------------------------------

CARD_RE = re.compile(
    r'<div class="story_images">\s*<a href="https://manga18\.club/manhwa/([^"/?#]+)" title="([^"]*)">'
    r'\s*<img src="([^"]*)"',
    re.S,
)
#: The pager's "last page" arrow; absent when everything fits on one page.
LAST_PAGE_RE = re.compile(r'(?:/list-manga/(\d+)|[?&]page=(\d+))[^"]*">&raquo;</a>')

TITLE_RE = re.compile(r'<div class="detail_name">\s*<h1>(.*?)</h1>', re.S)
COVER_RE = re.compile(r'<div class="detail_avatar">\s*<img src="([^"]+)"')
DESC_RE = re.compile(r'<div class="detail_reviewContent">(.*?)</div>', re.S)
INFO_RE = re.compile(
    r'<div class="info_label">.*?</i>\s*([^<]*?)\s*</div>\s*<div class="info_value">(.*?)</div>',
    re.S,
)
ANCHOR_TEXT_RE = re.compile(r"<a [^>]*>(.*?)</a>", re.S)
SLIDES_RE = re.compile(r"var slides_p_path\s*=\s*\[(.*?)\]", re.S)
QUOTED_RE = re.compile(r'"([^"]*)"')
CHAPTER_NUMBER_RE = re.compile(r"(\d+(?:\.\d+)?)")

#: Placeholder the site prints where it has no credit.
_UNKNOWN = {"", "updating", "unknown"}


def _clean(value: str) -> str:
    text = re.sub(r"<[^>]+>", " ", value or "")
    return html_lib.unescape(re.sub(r"\s+", " ", text)).strip()


# --- identity -----------------------------------------------------------------


def _path_parts(value: str) -> list[str]:
    text = fully_unquote(str(value or "")).strip()
    text = re.sub(r"^https?://[^/]+", "", text).strip("/")
    return [p for p in text.removeprefix("manhwa/").split("/") if p]


def normalize_series_key(value: str) -> str:
    """``work-me-out`` from a bare slug, a ``/manhwa/...`` path or a full URL."""
    parts = _path_parts(value)
    return parts[0] if parts else ""


def normalize_chapter_key(value: str) -> str:
    """``work-me-out/chapter-15``; empty when either half is missing."""
    parts = _path_parts(value)
    return f"{parts[0]}/{parts[1]}" if len(parts) >= 2 else ""


def page_id_chapter_key(page_id: str) -> str | None:
    chapter_key, sep, _index = (page_id or "").rpartition(PAGE_ID_SEPARATOR)
    return chapter_key if sep and chapter_key else None


# --- parsing ------------------------------------------------------------------


def parse_last_page(html: str) -> int:
    match = LAST_PAGE_RE.search(html)
    return int(match.group(1) or match.group(2)) if match else 1


def parse_series_list(html: str, *, page: int) -> PaginatedSeriesList:
    items: list[Series] = []
    seen: set[str] = set()
    for slug, title, cover in CARD_RE.findall(html):
        if slug in seen:
            continue
        seen.add(slug)
        items.append(
            Series(
                id=slug,
                title=_clean(title),
                cover_url=html_lib.unescape(cover) or None,
                canonical_path=f"/manhwa/{slug}",
            )
        )
    last_page = parse_last_page(html) if items else page
    return PaginatedSeriesList(
        items=items,
        page=page,
        page_size=PAGE_SIZE,
        total=last_page * PAGE_SIZE if last_page > 1 else len(items),
        api_has_more=bool(items) and page < last_page,
    )


def parse_series_detail(html: str, series_key: str) -> Series | None:
    title = TITLE_RE.search(html)
    if title is None:
        return None
    info = {_clean(label).casefold(): value for label, value in INFO_RE.findall(html)}

    def credit(label: str) -> str | None:
        text = _clean(info.get(label, ""))
        return None if text.casefold() in _UNKNOWN else text

    genres = tuple(
        t for t in (_clean(a) for a in ANCHOR_TEXT_RE.findall(info.get("categories", ""))) if t
    )
    cover = COVER_RE.search(html)
    desc = DESC_RE.search(html)
    return Series(
        id=series_key,
        title=_clean(title.group(1)),
        canonical_path=f"/manhwa/{series_key}",
        description=_clean(desc.group(1)) or None if desc else None,
        cover_url=html_lib.unescape(cover.group(1)) if cover else None,
        author=credit("author"),
        artist=credit("artist"),
        status=credit("status"),
        genres=genres,
    )


def parse_chapters(html: str, series_key: str) -> list[Chapter]:
    """Chapters oldest-first (the page lists them newest-first)."""
    pattern = re.compile(
        rf'<a [^>]*href="/manhwa/{re.escape(series_key)}/([^"/]+)"[^>]*class="chapter_num"[^>]*>(.*?)</a>',
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
        match = CHAPTER_NUMBER_RE.search(title)
        chapters.append(
            Chapter(
                id=f"{series_key}/{chapter_slug}",
                series_id=series_key,
                title=title,
                # A label without digits keeps its place in the site's order.
                number=float(match.group(1)) if match else float(len(rows) - index),
                page_count=0,
            )
        )
    chapters.reverse()
    # Stable: an uncensored re-upload of a number keeps the site's order.
    chapters.sort(key=lambda c: c.number or 0.0)
    return chapters


def parse_chapter_pages(html: str, chapter_key: str) -> list[Page]:
    match = SLIDES_RE.search(html)
    if match is None:
        return []
    urls: list[str] = []
    for encoded in QUOTED_RE.findall(match.group(1)):
        try:
            url = base64.b64decode(encoded, validate=True).decode("utf-8").strip()
        except (binascii.Error, UnicodeDecodeError):
            continue
        if url.startswith("https://"):
            urls.append(url)
    return [
        Page(
            id=f"{chapter_key}{PAGE_ID_SEPARATOR}{index}",
            chapter_id=chapter_key,
            number=index,
            remote_url=url,
        )
        for index, url in enumerate(urls, start=1)
    ]


# --- connector ----------------------------------------------------------------


class Manga18ClubConnector(SourceConnector):
    """Browse and read adult manhwa and Korean raws from Manga18.club.

    One GET per stage: listing, detail (shared by ``get_series`` and
    ``get_chapters``), chapter. Every failure answers empty rather than
    raising, so a Cloudflare wall or an outage shows as "nothing here".
    """

    SOURCE_TYPE = "manga18club"
    DISPLAY_NAME = "Manga18.club"
    DESCRIPTION = (
        "Browse and read adult manhwa and Korean raws from Manga18.club. "
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
        return frozenset({IMAGE_HOST})

    def list_browse_modes(self) -> list[BrowseMode]:
        return [BrowseMode(id=key, label=label) for key, (label, _) in BROWSE_MODES.items()]

    # --- helpers --------------------------------------------------------------

    def _get(self, operation: str, path: str, params: dict[str, Any] | None = None) -> str | None:
        """The document, or ``None`` (logged) on any upstream failure."""
        try:
            return self._http.get_text(path, params=params)
        except ConnectorHttpError as exc:
            logger.info(
                "Manga18Club %s %s%s params=%s status=error detail=%s",
                operation, SITE_BASE, path, params or {}, exc,
            )
            return None

    def _listing(self, operation: str, page: int, params: dict[str, Any]) -> PaginatedSeriesList:
        html = self._get(operation, f"/list-manga/{page}", params)
        if html is None:
            return PaginatedSeriesList(items=[], page=page, page_size=PAGE_SIZE, api_has_more=False)
        return parse_series_list(html, page=page)

    def _fetch_detail(self, series_key: str) -> tuple[Series | None, list[Chapter]]:
        if not series_key:
            return None, []
        cached = self._detail_cache.get(series_key)
        if cached is not None:
            return cached
        html = self._get("detail", f"/manhwa/{series_key}")
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
        _label, order_by = BROWSE_MODES.get(sort or "default", BROWSE_MODES["default"])
        return self._listing("browse", max(page, 1), {"order_by": order_by} if order_by else {})

    def search_series(self, query: str, page: int, *, sort: str | None = None) -> PaginatedSeriesList:
        normalized = query.strip()
        if not normalized:
            return self.get_series_list(page, sort=sort)
        return self._listing("search", max(page, 1), {"search": normalized})

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
        html = self._get("pages", f"/manhwa/{chapter_key}")
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
