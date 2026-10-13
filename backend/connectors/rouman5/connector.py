"""Rouman5 (肉漫屋, rouman5.com) online source connector -- adult Korean manhwa, zh-Hant.

The site is a TanStack Start app, but every view this connector needs is
server-rendered: listing cards, the detail page (cover, title, author, status,
chapter links) and, for a chapter, the page list -- which lives only in the
seroval hydration stream as ``imagePaths:$R[k]=[...]``. ``/`` is an age gate;
``/books`` and ``/search`` answer directly, so it is never touched.

Pagination is ZERO-based upstream: ``/books`` is page 1, ``/books?page=1`` page 2.

Images are signed imgproxy URLs on rotating hosts (``kelv47.xyz``,
``towm85.xyz`` and their ``v1``-``v5`` shards, observed 2026-10-13). The
allowlist is therefore learned: every host an image URL parsed from the site's
own HTML points at is remembered, and only those are proxied. The proxy always
resolves a page/cover through ``find_page``/``get_series`` on this (singleton)
instance first, so a host is learned before it is validated.

Each URL carries ``wm:``/``sr:`` flags. ``wm`` is a burned-in watermark and
cannot be undone. ``sr:1`` pages are SCRAMBLED: the image is cut into 5-14
horizontal strips stacked in reverse order, the count derived from the MD5 of
the URL's own base64 path segment (port of the site's reader canvas code).
``fetch_proxied_image`` puts them back, so readers get a normal image.
"""

from __future__ import annotations

import base64
import hashlib
import html
import io
import json
import logging
import re
from urllib.parse import quote, urlparse

from connectors.base import SourceConnector
from connectors.http.cache import TTLCache
from connectors.http.cf_client import is_cloudflare_challenge
from connectors.http.client import ConnectorHttpError, SyncConnectorHttpClient
from connectors.models import Chapter, Page, PaginatedSeriesList, Series

logger = logging.getLogger(__name__)

SITE_BASE = "https://rouman5.com"
PAGE_SIZE = 24
BROWSER_USER_AGENT = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
)

_CARD_RE = re.compile(r'<a class="site-comic" href="/books/([\w-]+)">(.*?)</a>', re.S)
_IMG_SRC_RE = re.compile(r'<img[^>]*?src="([^"]+)"')
_H3_RE = re.compile(r'<h3 title="([^"]*)"')
_CARD_CHAPTER_RE = re.compile(r'class="site-comic-chapter"[^>]*>([^<]*)<')
_NEXT_RE = re.compile(r'<a class="site-button" href="[^"]*">下一頁')
_TOTAL_PAGES_RE = re.compile(r'site-pagination-mobile">\d+<!-- --> / <!-- -->(\d+)')
_H1_RE = re.compile(r"<h1>(.*?)</h1>", re.S)
_DETAIL_COVER_RE = re.compile(r'<img class="site-detail-cover" src="([^"]+)"')
_DATA_RE = re.compile(r"<dt>(.*?)</dt><dd>(.*?)</dd>", re.S)
_SYNOPSIS_RE = re.compile(r'<div class="site-book-synopsis[^"]*"><p>(.*?)</p>', re.S)
_TAGS_RE = re.compile(r"tags:\$R\[\d+\]=(\[[^\]]*\])")
_IMAGE_PATHS_RE = re.compile(r"imagePaths:\$R\[\d+\]=(\[[^\]]*\])")
#: Signed imgproxy shape: https://<host>/m/<signature>/<flags...>/<b64 source>.<ext>
_IMGPROXY_RE = re.compile(r"^https://[^/]+/m/[\w-]+/")


def _text(value: str) -> str:
    return html.unescape(re.sub(r"<[^>]+>", "", value)).strip()


def _chapter_re(book_id: str) -> re.Pattern[str]:
    return re.compile(
        rf'<a href="/books/{re.escape(book_id)}/(\d+)" class="site-chapter-link[^"]*">'
        r'<span title="([^"]*)"'
    )


def listing_path(page: int, query: str | None = None) -> str:
    """Upstream path for app page ``page`` (1-based; the site is 0-based)."""
    upstream = max(page, 1) - 1
    if query:
        path = f"/search?term={quote(query)}"
        return f"{path}&page={upstream}" if upstream else path
    return f"/books?page={upstream}" if upstream else "/books"


def parse_listing(document: str, *, page: int) -> PaginatedSeriesList:
    items: list[Series] = []
    for book_id, body in _CARD_RE.findall(document):
        title = _H3_RE.search(body)
        cover = _IMG_SRC_RE.search(body)
        latest = _CARD_CHAPTER_RE.search(body)
        items.append(
            Series(
                id=book_id,
                title=html.unescape(title.group(1)).strip() if title else "Untitled",
                cover_url=html.unescape(cover.group(1)) if cover else None,
                latest_chapter=_text(latest.group(1)) or None if latest else None,
            )
        )
    total_pages = _TOTAL_PAGES_RE.search(document)
    return PaginatedSeriesList(
        items=items,
        page=page,
        page_size=PAGE_SIZE,
        total=int(total_pages.group(1)) * PAGE_SIZE if total_pages else len(items),
        api_has_more=bool(items) and bool(_NEXT_RE.search(document)),
    )


def parse_chapters(document: str, *, book_id: str) -> list[Chapter]:
    chapters: dict[int, Chapter] = {}
    for ind_text, title in _chapter_re(book_id).findall(document):
        ind = int(ind_text)
        chapters.setdefault(
            ind,
            Chapter(
                id=f"{book_id}/{ind}",
                series_id=book_id,
                title=html.unescape(title).strip() or f"第{ind + 1}話",
                # ``ind`` is a 0-based position; the printed "第N話" drifts
                # (specials, re-numbered seasons), so the position is the number.
                number=float(ind + 1),
                page_count=0,
            ),
        )
    return [chapters[key] for key in sorted(chapters)]


def parse_series(document: str, *, book_id: str) -> Series | None:
    title = _H1_RE.search(document)
    if title is None:
        return None
    cover = _DETAIL_COVER_RE.search(document)
    fields = {_text(dt): _text(dd) for dt, dd in _DATA_RE.findall(document)}
    status_text = fields.get("狀態", "")
    status = (
        "completed" if "完結" in status_text else "ongoing" if "連載" in status_text else None
    )
    synopsis = _SYNOPSIS_RE.search(document)
    genres: list[str] = []
    # Tags live only in the hydration stream; the book's own object comes first
    # after ``book:$R[n]={id:"<id>"``, recommendations follow much later.
    start = document.find(f'={{id:"{book_id}",name:')
    if start >= 0:
        end = document.find("chapterNames", start)
        for raw in _TAGS_RE.findall(document[start : end if end > 0 else start + 6000]):
            try:
                genres.extend(tag for tag in json.loads(raw) if isinstance(tag, str))
            except ValueError:
                continue
    chapters = parse_chapters(document, book_id=book_id)
    return Series(
        id=book_id,
        title=_text(title.group(1)) or "Untitled",
        chapter_count=len(chapters),
        description=_text(synopsis.group(1)) if synopsis else None,
        cover_url=html.unescape(cover.group(1)) if cover else None,
        author=fields.get("作者") or None,
        status=status,
        genres=tuple(dict.fromkeys(genres)),
        latest_chapter=chapters[-1].title if chapters else None,
    )


def parse_pages(document: str, *, chapter_id: str) -> list[Page]:
    match = _IMAGE_PATHS_RE.search(document)
    if match is None:
        return []
    try:
        urls = json.loads(match.group(1))
    except ValueError:
        return []
    return [
        Page(id=f"{chapter_id}/{number}", chapter_id=chapter_id, number=number, remote_url=url)
        for number, url in enumerate((u for u in urls if isinstance(u, str)), start=1)
    ]


def strip_count(url: str) -> int:
    """How many strips an ``sr:1`` image was cut into (the reader's formula)."""
    segment = url.rsplit("/", 1)[-1].rsplit(".", 1)[0]
    source = base64.urlsafe_b64decode(segment + "=" * (-len(segment) % 4))
    return int(hashlib.md5(source).hexdigest()[-2:], 16) % 10 + 5


def unscramble(data: bytes, url: str) -> bytes:
    """Undo ``sr:1`` strip scrambling; returns a JPEG.

    Upstream draws strip ``i`` of the output from source rows counted from the
    BOTTOM, the first strip absorbing the ``height % strips`` remainder.
    """
    from PIL import Image

    strips = strip_count(url)
    with Image.open(io.BytesIO(data)) as image:
        source = image.convert("RGB")
    width, height = source.size
    base, rest = divmod(height, strips)
    out = Image.new("RGB", source.size)
    for index in range(strips):
        strip_height = base + (rest if index == 0 else 0)
        dest_y = base * index + (rest if index else 0)
        src_y = height - base * (index + 1) - rest
        out.paste(source.crop((0, src_y, width, src_y + strip_height)), (0, dest_y))
    buffer = io.BytesIO()
    out.save(buffer, "JPEG", quality=92)
    return buffer.getvalue()


class Rouman5Connector(SourceConnector):
    """Browse and read adult manhwa (Traditional Chinese) from 肉漫屋.

    Request budget: browse/search 1 GET; series + chapters 1 GET (shared via
    ``_detail_cache``); chapter open 1 GET; plain page image 0 here, an
    ``sr:1`` page image 1 GET + an in-process strip reorder.
    """

    SOURCE_TYPE = "rouman5"
    DISPLAY_NAME = "肉漫屋 Rouman5"
    DESCRIPTION = (
        "Browse and read adult Korean manhwa in Traditional Chinese from 肉漫屋 (rouman5.com). "
        "Images are proxied through ManhwaManiacs."
    )
    BROWSABLE = True
    SUPPORTS_IMPORT = False
    MATURE = True

    def __init__(self) -> None:
        self._http = SyncConnectorHttpClient(
            SITE_BASE,
            headers={"Accept": "text/html,application/xhtml+xml", "Accept-Language": "zh-TW,zh;q=0.9"},
            user_agent=BROWSER_USER_AGENT,
            min_interval=0.3,
        )
        self._detail_cache: TTLCache[tuple[Series | None, list[Chapter]]] = TTLCache(
            ttl_seconds=300.0
        )
        self._page_cache: TTLCache[list[Page]] = TTLCache(ttl_seconds=600.0)
        self._image_hosts: set[str] = set()

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
        # Exact hosts learned from the site's own image URLs (see module doc);
        # empty until something was parsed, which fails closed.
        return frozenset(self._image_hosts)

    def fetch_proxied_image(self, url: str) -> tuple[str, bytes] | None:
        if "/sr:1/" not in url:
            return None
        _media_type, data = self._http.get_bytes(url)
        try:
            return "image/jpeg", unscramble(data, url)
        except Exception as exc:  # Pillow raises a zoo of types on bad bytes
            raise ConnectorHttpError(f"Could not unscramble page image: {exc}") from exc

    # --- helpers ------------------------------------------------------------

    def _remember_hosts(self, urls: list[str | None]) -> None:
        for url in urls:
            if url and _IMGPROXY_RE.match(url):
                host = urlparse(url).hostname
                if host:
                    self._image_hosts.add(host)

    def _fetch_html(self, path: str) -> str | None:
        try:
            document = self._http.get_text(path)
        except ConnectorHttpError as exc:
            logger.info("Rouman5 GET %s%s failed: %s", SITE_BASE, path, exc)
            return None
        if is_cloudflare_challenge(document):
            logger.info("Rouman5 GET %s%s answered a Cloudflare challenge", SITE_BASE, path)
            return None
        return document

    @staticmethod
    def _book_id(key: str) -> str:
        return key.strip().strip("/").removeprefix("books/").split("/", 1)[0]

    def _listing(self, page: int, query: str | None = None) -> PaginatedSeriesList:
        page = max(page, 1)
        path = listing_path(page, query)
        document = self._fetch_html(path)
        if document is None:
            return PaginatedSeriesList(items=[], page=page, page_size=PAGE_SIZE, api_has_more=False)
        listing = parse_listing(document, page=page)
        self._remember_hosts([item.cover_url for item in listing.items])
        logger.info("Rouman5 listing %s count=%d has_more=%s", path, len(listing.items), listing.has_more)
        return listing

    def _detail(self, series_id: str) -> tuple[Series | None, list[Chapter]]:
        book_id = self._book_id(series_id)
        cached = self._detail_cache.get(book_id)
        if cached is not None:
            return cached
        document = self._fetch_html(f"/books/{book_id}")
        if document is None:
            return None, []
        series = parse_series(document, book_id=book_id)
        if series is None:
            return None, []
        result = (series, parse_chapters(document, book_id=book_id))
        self._remember_hosts([series.cover_url])
        self._detail_cache.set(book_id, result)
        return result

    # --- catalog ------------------------------------------------------------

    def get_series_list(self, page: int, *, sort: str | None = None) -> PaginatedSeriesList:
        return self._listing(page)

    def search_series(self, query: str, page: int, *, sort: str | None = None) -> PaginatedSeriesList:
        normalized = query.strip()
        return self._listing(page, normalized or None)

    def get_series(self, series_id: str) -> Series | None:
        return self._detail(series_id)[0]

    def get_chapters(self, series_id: str) -> list[Chapter]:
        return self._detail(series_id)[1]

    def get_chapter_pages(self, chapter_id: str) -> list[Page]:
        parts = chapter_id.strip().strip("/").removeprefix("books/").split("/")
        if len(parts) < 2 or not parts[1].isdigit():
            return []
        key = f"{parts[0]}/{parts[1]}"
        cached = self._page_cache.get(key)
        if cached is not None:
            return cached
        document = self._fetch_html(f"/books/{key}")
        if document is None:
            return []
        pages = parse_pages(document, chapter_id=key)
        if pages:
            self._remember_hosts([page.remote_url for page in pages])
            self._page_cache.set(key, pages)
        return pages

    def find_page(self, page_id: str) -> Page | None:
        chapter_id, _, _number = page_id.strip().rpartition("/")
        if not chapter_id:
            return None
        return next((p for p in self.get_chapter_pages(chapter_id) if p.id == page_id.strip()), None)
