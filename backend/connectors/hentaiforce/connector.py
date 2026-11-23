"""HentaiForce (hentaiforce.net) online source connector -- adult doujinshi, multi-language.

Custom PHP gallery site. A gallery (``/view/ID``) is exactly one chapter. The
detail page only shows the first few page thumbnails, so the page list comes
from the reader (``/view/ID/1``), which embeds every page as
``var readerPages = JSON.parse(atob("..."))``: ``baseUriImg`` is a printf
template (``https://m1.hentaiforce.me/img/<media>-%s``) filled with each
``pages[n].f`` file name. Images sit on ``*.hentaiforce.me`` and need no Referer
(measured from the VPS 2026-10-13).
"""

from __future__ import annotations

import base64
import html
import json
import logging
import re
from urllib.parse import quote

from connectors.base import SourceConnector
from connectors.http.cache import TTLCache
from connectors.http.cf_client import is_cloudflare_challenge
from connectors.http.client import ConnectorHttpError, SyncConnectorHttpClient
from connectors.models import Chapter, Page, PaginatedSeriesList, Series

logger = logging.getLogger(__name__)

SITE_BASE = "https://hentaiforce.net"
IMAGE_HOST_SUFFIX = "hentaiforce.me"
PAGE_SIZE = 20
BROWSER_USER_AGENT = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
)

_CARD_RE = re.compile(
    r'<a class="gallery-thumb" href="https://hentaiforce\.net/view/(\d+)"[^>]*>.*?'
    r'data-src="([^"]+)".*?<div class="gallery-name">\s*<h2>\s*<a[^>]*>\s*(.*?)\s*</a>',
    re.S,
)
_NEXT_RE = re.compile(r'rel="next"')
#: Anchored on the info block: a 404 page has an <h1> too ("404 Not Found").
_H1_RE = re.compile(r'<div id="gallery-main-info">\s*<h1[^>]*>(.*?)</h1>', re.S)
_COVER_RE = re.compile(r'id="gallery-main-cover".*?data-src="([^"]+)"', re.S)
_FIELD_RE = re.compile(r'<div class="tag-container field-name">\s*(\w+):(.*?)</div>', re.S)
_TAG_RE = re.compile(r'<a class="tag-btn btn"[^>]*>\s*(.*?)\s*<span', re.S)
_PAGES_RE = re.compile(r"Pages:\s*(\d+)")
_READER_RE = re.compile(r'readerPages\s*=\s*JSON\.parse\(atob\("([A-Za-z0-9+/=]+)"\)\)')


def _text(value: str) -> str:
    return html.unescape(re.sub(r"\s+", " ", re.sub(r"<[^>]+>", " ", value))).strip()


def listing_path(page: int, query: str | None = None) -> str:
    page = max(page, 1)
    if query:
        path = f"/search?q={quote(query)}"
        return f"{path}&page={page}" if page > 1 else path
    return f"/page/{page}" if page > 1 else "/"


def parse_listing(document: str, *, page: int) -> PaginatedSeriesList:
    items = [
        Series(
            id=gallery_id,
            title=_text(title) or "Untitled",
            chapter_count=1,
            cover_url=html.unescape(thumb),
        )
        for gallery_id, thumb, title in _CARD_RE.findall(document)
    ]
    return PaginatedSeriesList(
        items=items,
        page=page,
        page_size=PAGE_SIZE,
        total=len(items),
        api_has_more=bool(items) and bool(_NEXT_RE.search(document)),
    )


def parse_detail(document: str, *, gallery_id: str) -> tuple[Series, list[Chapter]] | None:
    """The gallery as a series plus its single chapter (none when it has no pages)."""
    title = _H1_RE.search(document)
    if title is None:
        return None
    fields = {name: _TAG_RE.findall(body) for name, body in _FIELD_RE.findall(document)}
    genres = [_text(tag) for tag in fields.get("Tags", []) + fields.get("Languages", [])]
    cover = _COVER_RE.search(document)
    pages = _PAGES_RE.search(document)
    page_count = int(pages.group(1)) if pages else 0
    artists = [_text(a) for a in fields.get("Artists", [])]
    series = Series(
        id=gallery_id,
        title=_text(title.group(1)) or "Untitled",
        chapter_count=1 if page_count else 0,
        cover_url=html.unescape(cover.group(1)) if cover else None,
        author=", ".join(artists) or None,
        artist=", ".join(artists) or None,
        status="completed",
        genres=tuple(dict.fromkeys(genres)),
        latest_chapter=f"{page_count} pages" if page_count else None,
    )
    chapters = (
        [Chapter(id=gallery_id, series_id=gallery_id, title="Gallery", number=1.0, page_count=page_count)]
        if page_count
        else []
    )
    return series, chapters


def parse_reader_pages(document: str, *, gallery_id: str) -> list[Page]:
    match = _READER_RE.search(document)
    if match is None:
        return []
    try:
        data = json.loads(base64.b64decode(match.group(1)))
        template = str(data["baseUriImg"])
        entries = data["pages"]
    except (ValueError, KeyError, TypeError):
        return []
    if "%s" not in template or not isinstance(entries, dict):
        return []
    pages: list[Page] = []
    for key in sorted((k for k in entries if str(k).isdigit()), key=int):
        entry = entries[key]
        if not isinstance(entry, dict) or not entry.get("f"):
            continue
        number = int(key)
        pages.append(
            Page(
                id=f"{gallery_id}:{number}",
                chapter_id=gallery_id,
                number=number,
                remote_url=template.replace("%s", str(entry["f"]), 1),
                width=entry.get("w") if isinstance(entry.get("w"), int) else None,
                height=entry.get("h") if isinstance(entry.get("h"), int) else None,
            )
        )
    return pages


class HentaiForceConnector(SourceConnector):
    """Browse and read galleries from HentaiForce.

    Request budget: browse/search 1 GET; series + chapter 1 GET (shared via
    ``_detail_cache``); chapter open 1 GET (the reader); page image 0 here.
    """

    SOURCE_TYPE = "hentaiforce"
    DISPLAY_NAME = "HentaiForce"
    DESCRIPTION = (
        "Browse and read hentai doujinshi, manga and comics from HentaiForce. "
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
            min_interval=0.3,
        )
        self._detail_cache: TTLCache[tuple[Series | None, list[Chapter]]] = TTLCache(
            ttl_seconds=300.0
        )
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
        # Thumbs, covers and pages: m1.hentaiforce.me (suffix covers sibling shards).
        return frozenset({IMAGE_HOST_SUFFIX})

    def _fetch_html(self, path: str) -> str | None:
        try:
            document = self._http.get_text(path)
        except ConnectorHttpError as exc:
            logger.info("HentaiForce GET %s%s failed: %s", SITE_BASE, path, exc)
            return None
        if is_cloudflare_challenge(document):
            logger.info("HentaiForce GET %s%s answered a Cloudflare challenge", SITE_BASE, path)
            return None
        return document

    @staticmethod
    def _gallery_id(key: str) -> str:
        return key.strip().strip("/").removeprefix("view/").split("/", 1)[0].split(":", 1)[0]

    def _listing(self, page: int, query: str | None = None) -> PaginatedSeriesList:
        page = max(page, 1)
        path = listing_path(page, query)
        document = self._fetch_html(path)
        if document is None:
            return PaginatedSeriesList(items=[], page=page, page_size=PAGE_SIZE, api_has_more=False)
        listing = parse_listing(document, page=page)
        logger.info("HentaiForce listing %s count=%d has_more=%s", path, len(listing.items), listing.has_more)
        return listing

    def get_series_list(self, page: int, *, sort: str | None = None) -> PaginatedSeriesList:
        return self._listing(page)

    def search_series(self, query: str, page: int, *, sort: str | None = None) -> PaginatedSeriesList:
        return self._listing(page, query.strip() or None)

    def _detail(self, series_id: str) -> tuple[Series | None, list[Chapter]]:
        gallery_id = self._gallery_id(series_id)
        if not gallery_id.isdigit():
            return None, []
        cached = self._detail_cache.get(gallery_id)
        if cached is not None:
            return cached
        document = self._fetch_html(f"/view/{gallery_id}")
        parsed = parse_detail(document, gallery_id=gallery_id) if document else None
        if parsed is None:
            return None, []
        self._detail_cache.set(gallery_id, parsed)
        return parsed

    def get_series(self, series_id: str) -> Series | None:
        return self._detail(series_id)[0]

    def get_chapters(self, series_id: str) -> list[Chapter]:
        return self._detail(series_id)[1]

    def get_chapter_pages(self, chapter_id: str) -> list[Page]:
        gallery_id = self._gallery_id(chapter_id)
        if not gallery_id.isdigit():
            return []
        cached = self._page_cache.get(gallery_id)
        if cached is not None:
            return cached
        document = self._fetch_html(f"/view/{gallery_id}/1")
        pages = parse_reader_pages(document, gallery_id=gallery_id) if document else []
        if pages:
            self._page_cache.set(gallery_id, pages)
        return pages

    def find_page(self, page_id: str) -> Page | None:
        gallery_id, _, number = page_id.strip().rpartition(":")
        if not gallery_id or not number.isdigit():
            return None
        return next((p for p in self.get_chapter_pages(gallery_id) if p.id == page_id.strip()), None)
