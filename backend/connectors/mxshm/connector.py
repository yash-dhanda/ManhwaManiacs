"""漫小肆韓漫 (mxshm.top) online source connector (Chinese adult manhwa).

A plain server-rendered PHP catalogue (ikanmh.top is the same site):

* ``/booklist?page=N`` -- 28 cards a page; ``id="nextPage"`` while more exist.
* ``/search?keyword=Q`` -- one unpaginated page; it also matches descriptions,
  and a one-character keyword returns nothing, so those are not sent.
* ``/book/{id}`` -- metadata plus the FULL chapter list (``#detail-list-select``;
  "显示全部章节" only unhides rows already in the HTML).
* ``/chapter/{id}`` -- pages are ``<img class="lazy" data-original=...>``.

Unknown ids answer HTTP 500. Chapter ids are global, so a page id needs no
series context.

Images (covers and pages) live on a separate domain that the site rotates
(``www.jjmhw9.top`` when this was written). Rather than hard-code a domain
that will be stale next month, ``allowed_image_hosts`` is built at runtime
from the ``/static/upload/`` image URLs this instance has itself parsed out of
the site's pages. That stays a tight SSRF allowlist -- only hosts the site
named, never hosts a client supplied -- and it is always populated in time:
the image proxy resolves every URL through this connector first
(``find_page`` -> ``get_chapter_pages``, cover -> ``get_series``), which parses
the page that names the host. The CDN needs no Referer (verified from the VPS).
"""

from __future__ import annotations

import html
import logging
import re
import threading
from urllib.parse import urlparse

from connectors.base import SourceConnector
from connectors.http.cache import TTLCache
from connectors.http.cf_client import is_cloudflare_challenge
from connectors.http.client import ConnectorHttpError, SyncConnectorHttpClient
from connectors.ids import fully_unquote
from connectors.models import BrowseMode, Chapter, Page, PaginatedSeriesList, Series

logger = logging.getLogger(__name__)

SITE_BASE = "https://mxshm.top"
PAGE_SIZE = 28
BROWSER_USER_AGENT = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
)

CARD_RE = re.compile(
    r'<a href="/book/(\d+)" title="([^"]*)">\s*'
    r'<p class="mh-cover" style="background-image: url\(([^)\s]+)\)"'
)
NEXT_PAGE_RE = re.compile(r'id="nextPage"')
TITLE_RE = re.compile(r"<h1>(.*?)</h1>", re.S)
# The banner cover comes before the "related" shelf, which reuses class="cover".
COVER_RE = re.compile(r'<div class="cover">\s*<img src="(https://[^"]+)"')
AUTHOR_RE = re.compile(r'<p class="subtitle">作者：(.*?)</p>', re.S)
STATUS_RE = re.compile(r"状态：<span>(.*?)</span>")
TAG_RE = re.compile(r'<a href="/booklist/\?tag=[^"]*"[^>]*>(.*?)</a>')
DESCRIPTION_RE = re.compile(r'<p class="content"[^>]*>(.*?)</p>', re.S)
CHAPTER_LIST_RE = re.compile(r'id="detail-list-select">(.*?)</ul>', re.S)
CHAPTER_RE = re.compile(r'<a href="/chapter/(\d+)"[^>]*>(.*?)</a>', re.S)
CHAPTER_NUMBER_RE = re.compile(r"第\s*(\d+(?:\.\d+)?)\s*[話话回章]")
PAGE_IMG_RE = re.compile(r'<img class="lazy" data-original="(https://[^"]+)"')
TAG_STRIP_RE = re.compile(r"<[^>]+>")

STATUSES = {"连载中": "ongoing", "連載中": "ongoing", "已完结": "completed", "已完結": "completed"}


def _text(fragment: str) -> str:
    return re.sub(r"\s+", " ", html.unescape(TAG_STRIP_RE.sub("", fragment))).strip()


def _image_host(url: str | None) -> str | None:
    """Host of a site upload URL; None for anything else (ads, icons, ...)."""
    if not url:
        return None
    parsed = urlparse(url)
    if parsed.scheme != "https" or not parsed.path.startswith("/static/upload/"):
        return None
    return parsed.hostname


def parse_series_list(document: str, *, page: int, paginated: bool = True) -> PaginatedSeriesList:
    seen: dict[str, Series] = {}
    for book_id, title, cover in CARD_RE.findall(document):
        name = _text(title)
        if name and book_id not in seen:
            seen[book_id] = Series(id=book_id, title=name, cover_url=cover)
    items = list(seen.values())
    has_more = paginated and bool(items) and NEXT_PAGE_RE.search(document) is not None
    return PaginatedSeriesList(
        items=items,
        page=page,
        page_size=PAGE_SIZE,
        total=(page - 1) * PAGE_SIZE + len(items) + (1 if has_more else 0),
        api_has_more=has_more,
    )


def parse_series_detail(document: str, *, series_id: str) -> Series | None:
    title = TITLE_RE.search(document)
    if title is None or not _text(title.group(1)):
        return None
    cover = COVER_RE.search(document)
    author = AUTHOR_RE.search(document)
    status = STATUS_RE.search(document)
    description = DESCRIPTION_RE.search(document)
    # Tags are read from the info block only; the page footer links tags too.
    info_end = document.find('class="content"')
    tags = TAG_RE.findall(document[: info_end if info_end > 0 else len(document)])
    return Series(
        id=series_id,
        title=_text(title.group(1)),
        chapter_count=len(parse_chapters(document, series_id=series_id)),
        canonical_path=f"/book/{series_id}",
        description=(_text(description.group(1)) or None) if description else None,
        cover_url=cover.group(1) if cover else None,
        author=(_text(author.group(1)) or None) if author else None,
        status=STATUSES.get(_text(status.group(1))) if status else None,
        genres=tuple(dict.fromkeys(t for t in map(_text, tags) if t)),
    )


def parse_chapters(document: str, *, series_id: str) -> list[Chapter]:
    block = CHAPTER_LIST_RE.search(document)
    if block is None:
        return []
    chapters: dict[str, Chapter] = {}
    for index, (chapter_id, label) in enumerate(CHAPTER_RE.findall(block.group(1)), start=1):
        title = _text(label) or f"第{index}話"
        match = CHAPTER_NUMBER_RE.search(title)
        chapters.setdefault(
            chapter_id,
            Chapter(
                id=chapter_id,
                series_id=series_id,
                title=title,
                number=float(match.group(1)) if match else float(index),
                page_count=0,
            ),
        )
    # The list is already oldest-first; the stable sort only settles a stray
    # out-of-order label without reshuffling the rest.
    return sorted(chapters.values(), key=lambda c: c.number or 0.0)


def make_page_id(chapter_id: str, number: int) -> str:
    return f"{chapter_id}:{number}"


def page_id_chapter_id(page_id: str) -> str | None:
    chapter_id, sep, number = page_id.rpartition(":")
    return chapter_id if sep and chapter_id.isdigit() and number.isdigit() else None


def parse_chapter_pages(document: str, *, chapter_id: str) -> list[Page]:
    return [
        Page(id=make_page_id(chapter_id, n), chapter_id=chapter_id, number=n, remote_url=url)
        for n, url in enumerate(dict.fromkeys(PAGE_IMG_RE.findall(document)), start=1)
    ]


class MxshmConnector(SourceConnector):
    """Browse and read Chinese-translated adult manhwa from 漫小肆韓漫."""

    SOURCE_TYPE = "mxshm"
    DISPLAY_NAME = "MXSHM"
    DESCRIPTION = (
        "Browse and read adult Korean manhwa in Chinese from 漫小肆韓漫 (mxshm.top). "
        "Images are proxied through ManhwaManiacs."
    )
    BROWSABLE = True
    SUPPORTS_IMPORT = False
    MATURE = True

    def __init__(self) -> None:
        self._http = SyncConnectorHttpClient(
            SITE_BASE,
            headers={"Accept": "text/html,application/xhtml+xml"},
            user_agent=BROWSER_USER_AGENT,
            min_interval=0.35,
        )
        self._series_cache: TTLCache[Series] = TTLCache(ttl_seconds=300.0)
        self._chapter_list_cache: TTLCache[list[Chapter]] = TTLCache(ttl_seconds=180.0)
        self._page_cache: TTLCache[list[Page]] = TTLCache(ttl_seconds=600.0)
        self._image_hosts: frozenset[str] = frozenset()
        self._hosts_lock = threading.Lock()

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
        # Exact hosts parsed from the site's own upload URLs (see module doc).
        return self._image_hosts

    def _remember_hosts(self, urls: list[str | None]) -> None:
        hosts = {h for h in map(_image_host, urls) if h} - self._image_hosts
        if hosts:
            with self._hosts_lock:
                self._image_hosts = self._image_hosts | hosts

    def list_browse_modes(self) -> list[BrowseMode]:
        return [BrowseMode(id="default", label="Latest")]

    def _fetch_html(self, path: str, *, params: dict[str, str] | None = None) -> str | None:
        """GET a page, or None on HTTP failure or a Cloudflare interstitial."""
        try:
            document = self._http.get_text(path, params=params)
        except ConnectorHttpError as exc:
            logger.warning("mxshm GET %s failed: %s", path, exc)
            return None
        if is_cloudflare_challenge(document):
            logger.warning("mxshm GET %s hit a Cloudflare challenge", path)
            return None
        return document

    def _listing(self, document: str | None, *, page: int, paginated: bool) -> PaginatedSeriesList:
        if document is None:
            return PaginatedSeriesList(items=[], page=page, page_size=PAGE_SIZE, api_has_more=False)
        listing = parse_series_list(document, page=page, paginated=paginated)
        self._remember_hosts([s.cover_url for s in listing.items])
        return listing

    def get_series_list(self, page: int, *, sort: str | None = None) -> PaginatedSeriesList:
        del sort  # one catalogue order (newest book first)
        page = max(page, 1)
        listing = self._listing(
            self._fetch_html("/booklist", params={"page": str(page)}), page=page, paginated=True
        )
        logger.info("mxshm browse page=%d count=%d", page, len(listing.items))
        return listing

    def search_series(self, query: str, page: int, *, sort: str | None = None) -> PaginatedSeriesList:
        page = max(page, 1)
        normalized = query.strip()
        if not normalized:
            return self.get_series_list(page, sort=sort)
        if len(normalized) < 2 or page > 1:
            # The site ignores one-character keywords and has no second page.
            return self._listing(None, page=page, paginated=False)
        listing = self._listing(
            self._fetch_html("/search", params={"keyword": normalized}), page=page, paginated=False
        )
        logger.info("mxshm search query=%r count=%d", normalized, len(listing.items))
        return listing

    @staticmethod
    def _normalize_id(value: str, prefix: str) -> str:
        text = fully_unquote(value).strip().strip("/")
        text = text.rsplit(f"{prefix}/", 1)[-1]
        return text if text.isdigit() else ""

    def _load_book(self, book_id: str) -> tuple[Series | None, list[Chapter]]:
        document = self._fetch_html(f"/book/{book_id}")
        if document is None:
            return None, []
        series = parse_series_detail(document, series_id=book_id)
        chapters = parse_chapters(document, series_id=book_id)
        if series is not None:
            self._remember_hosts([series.cover_url])
            self._series_cache.set(book_id, series)
        if chapters:
            self._chapter_list_cache.set(book_id, chapters)
        return series, chapters

    def get_series(self, series_id: str) -> Series | None:
        book_id = self._normalize_id(series_id, "book")
        if not book_id:
            return None
        cached = self._series_cache.get(book_id)
        if cached is not None:
            return cached
        return self._load_book(book_id)[0]

    def get_chapters(self, series_id: str) -> list[Chapter]:
        book_id = self._normalize_id(series_id, "book")
        if not book_id:
            return []
        cached = self._chapter_list_cache.get(book_id)
        if cached is not None:
            return cached
        return self._load_book(book_id)[1]

    def get_chapter_pages(self, chapter_id: str) -> list[Page]:
        cid = self._normalize_id(chapter_id, "chapter")
        if not cid:
            return []
        cached = self._page_cache.get(cid)
        if cached is not None:
            return cached
        document = self._fetch_html(f"/chapter/{cid}")
        pages = parse_chapter_pages(document, chapter_id=cid) if document else []
        if pages:  # never pin a transient failure for the TTL
            self._remember_hosts([p.remote_url for p in pages])
            self._page_cache.set(cid, pages)
        return pages

    def find_page(self, page_id: str) -> Page | None:
        normalized = fully_unquote(page_id).strip()
        chapter_id = page_id_chapter_id(normalized)
        if chapter_id is None:
            return None
        for page in self.get_chapter_pages(chapter_id):
            if page.id == normalized:
                return page
        return None
