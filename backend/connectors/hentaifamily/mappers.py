"""Map HentaiFox-family gallery HTML to normalized connector models."""

from __future__ import annotations

import html
import json
import re
from dataclasses import dataclass
from urllib.parse import quote

from connectors.models import Chapter, Page, PaginatedSeriesList, Series

HOME_PAGE_SIZE = 32
SEARCH_PAGE_SIZE = 32

LISTING_CARD_RE = re.compile(
    r'href="(/gallery/(\d+)/)"[^>]*>.*?'
    r'data-src="([^"]+)".*?'
    r'class="(?:g_title|gallery_title)"><a[^>]*>([^<]+)</a>',
    re.S | re.I,
)
NEXT_PAGE_RE = re.compile(r"page-link['\"][^>]*>\s*Next", re.I)
TITLE_H1_RE = re.compile(r'<h1[^>]*>([^<]+)', re.I)
TITLE_TAG_RE = re.compile(r"<title>([^<]+?)\s*-\s*", re.I)
PAGE_COUNT_RE = re.compile(r'id="load_pages"[^>]+value="(\d+)"', re.I)
THUMB_PAGE_RE = re.compile(r'data-src="(https://[^"]+/(\d+)t\.jpg)"', re.I)
READER_IMAGE_RE = re.compile(r'data-src="(https://[^"]+\.(?:webp|png|jpg|jpeg))"', re.I)
# Per-page "type,width,height" map the reader script ships on the gallery
# page, e.g. ``g_th = $.parseJSON('{"1":"j,1151,900","2":"w,1280,1811"}')``.
# Older galleries are all jpg and even new ones mix jpg into webp, so guessing
# one extension 404s those pages.
PAGE_TYPES_RE = re.compile(r"g_th\s*=\s*\$\.parseJSON\('(\{[^']*\})'\)")
PAGE_TYPE_EXTENSIONS = {"j": "jpg", "p": "png", "b": "bmp", "g": "gif", "w": "webp"}
TAG_LINK_RE = re.compile(
    r'<a[^>]+class="tag[^"]*"[^>]*>([^<]+)</a>',
    re.I,
)


@dataclass(frozen=True, slots=True)
class HentaiFamilySite:
    source_id: str
    display_name: str
    site_base: str
    reader_segment: str  # ``g`` (hentaifox) or ``view`` (hentaiera)
    image_host_suffix: str  # e.g. hentaifox.com
    # The search box's query parameter. hentaifox reads ``q``; hentaiera,
    # hentairox and comicporn read ``key`` and silently ignore ``q``, which
    # answers every search with the unfiltered latest listing.
    search_param: str = "q"
    # hentairox and comicporn serve a sectioned front page at ``/`` (10-30
    # mixed cards, no pager); the paginated latest listing starts at
    # ``/?page=1``. hentaifox and hentaiera list it at ``/`` directly.
    explicit_first_page: bool = False


def _clean_text(value: str) -> str:
    text = html.unescape(re.sub(r"<[^>]+>", " ", value))
    return re.sub(r"\s+", " ", text).strip()


def home_listing_path(
    page: int, *, sort: str | None = None, explicit_first_page: bool = False
) -> str:
    params: list[str] = []
    if sort == "popular":
        params.append("sort=popular")
    elif sort == "new":
        params.append("sort=new")
    elif sort in {"rating", "top_rated"}:
        params.append("sort=rating")
    if page > 1 or explicit_first_page:
        params.append(f"page={page}")
    if not params:
        return "/"
    return f"/?{'&'.join(params)}"


def search_listing_path(
    query: str, page: int, *, sort: str | None = None, param: str = "q"
) -> str:
    params = [f"{param}={quote(query)}"]
    if page > 1:
        params.append(f"page={page}")
    if sort == "popular":
        params.append("sort=popular")
    elif sort == "new":
        params.append("sort=new")
    elif sort in {"rating", "top_rated"}:
        params.append("sort=rating")
    return f"/search/?{'&'.join(params)}"


def gallery_path(gallery_id: str) -> str:
    return f"/gallery/{gallery_id.strip().strip('/')}/"


def reader_path(site: HentaiFamilySite, gallery_id: str, page_number: int) -> str:
    return f"/{site.reader_segment}/{gallery_id.strip().strip('/')}/{page_number}/"


def make_page_id(gallery_id: str, page_number: int) -> str:
    return f"{gallery_id}:{page_number}"


def page_id_gallery_id(page_id: str) -> str | None:
    if ":" not in page_id:
        return None
    gallery_id, _, _page_number = page_id.rpartition(":")
    return gallery_id or None


def parse_series_list(
    document: str,
    *,
    page: int,
    page_size: int,
) -> PaginatedSeriesList:
    seen: set[str] = set()
    items: list[Series] = []
    for _href, gallery_id, thumb_url, title in LISTING_CARD_RE.findall(document):
        if gallery_id in seen:
            continue
        seen.add(gallery_id)
        clean_title = _clean_text(title)
        items.append(
            Series(
                id=gallery_id,
                title=clean_title or "Untitled",
                chapter_count=1,
                cover_url=thumb_url.replace("/thumb.jpg", "/cover.jpg"),
            )
        )
    has_next = bool(NEXT_PAGE_RE.search(document))
    return PaginatedSeriesList(
        items=items,
        page=page,
        page_size=page_size,
        api_has_more=has_next or len(items) >= page_size,
    )


def _page_count(document: str) -> int:
    match = PAGE_COUNT_RE.search(document)
    if match:
        try:
            return int(match.group(1))
        except ValueError:
            pass
    thumbs = THUMB_PAGE_RE.findall(document)
    return max((int(number) for _url, number in thumbs), default=0)


def _media_base(document: str) -> str | None:
    match = THUMB_PAGE_RE.search(document)
    if match is None:
        return None
    thumb_url = match.group(1)
    return thumb_url.rsplit("/", 1)[0] + "/"


def parse_series_detail(document: str, *, gallery_id: str) -> Series | None:
    title_match = TITLE_H1_RE.search(document) or TITLE_TAG_RE.search(document)
    if title_match is None:
        return None
    title = _clean_text(title_match.group(1))
    page_count = _page_count(document)
    media_base = _media_base(document)
    if page_count <= 0 and media_base is None:
        # No page count and no thumbs: not a gallery page at all (a
        # Cloudflare interstitial or an error page that still has an <h1>).
        return None
    cover_url = f"{media_base}cover.jpg" if media_base else None
    tags = tuple(_clean_text(name) for name in TAG_LINK_RE.findall(document))
    return Series(
        id=gallery_id,
        title=title or "Untitled",
        chapter_count=1 if page_count > 0 else 0,
        cover_url=cover_url,
        status="completed",
        genres=tags,
        latest_chapter=f"{page_count} pages" if page_count else None,
    )


def parse_chapters(document: str, *, gallery_id: str) -> list[Chapter]:
    page_count = _page_count(document)
    if page_count <= 0:
        return []
    return [
        Chapter(
            id=gallery_id,
            series_id=gallery_id,
            title="Gallery",
            number=1.0,
            page_count=page_count,
        )
    ]


def _page_extensions(document: str) -> dict[int, str]:
    match = PAGE_TYPES_RE.search(document)
    if match is None:
        return {}
    try:
        raw = json.loads(match.group(1))
    except ValueError:
        return {}
    if not isinstance(raw, dict):
        return {}
    extensions: dict[int, str] = {}
    for number, spec in raw.items():
        ext = PAGE_TYPE_EXTENSIONS.get(str(spec).split(",", 1)[0])
        if ext and str(number).isdigit():
            extensions[int(number)] = ext
    return extensions


def parse_gallery_pages_from_detail(document: str, *, gallery_id: str) -> list[Page]:
    """Build page URLs from gallery detail thumbs, typed by the ``g_th`` map
    when the page ships one and webp otherwise."""
    page_count = _page_count(document)
    media_base = _media_base(document)
    if page_count <= 0 or not media_base:
        return []
    extensions = _page_extensions(document)
    pages: list[Page] = []
    for number in range(1, page_count + 1):
        pages.append(
            Page(
                id=make_page_id(gallery_id, number),
                chapter_id=gallery_id,
                number=number,
                remote_url=f"{media_base}{number}.{extensions.get(number, 'webp')}",
            )
        )
    return pages


def parse_reader_image_url(document: str) -> str | None:
    match = READER_IMAGE_RE.search(document)
    return match.group(1) if match else None
