"""ManhwaWeb online source connector (Spanish, public JSON API).

manhwaweb.com is a Vite SPA; everything it renders comes from
``api.manhwaweb.com``, which answers plain JSON without a challenge:

* ``/manhwa/library?...&page=N`` -- 30 cards per page (0-based) plus ``next``.
  ``erotico=si`` restricts the catalogue to the adult shelf, which is the only
  part this (18+) source serves; ``buscar=`` is the site's own title search.
* ``/manhwa/see/{real_id}`` -- metadata and the chapter list in one payload.
* ``/chapters/see/{chapter_key}`` -- ``chapter.img`` is the ordered page list.

A chapter key is the path after ``/leer/`` in the chapter link (for example
``teamo_1747080624029-25`` or ``countryside_1681701042099-12_01``); it embeds
the series id, so a page id resolves without any other state.

Images: page art is on img1mw.xyz / img2mw.xyz (Cloudflare hotlink rules:
403 without a manhwaweb.com Referer, verified from the VPS) and, for some
scanlation uploads, imagizer.imageshack.com. Covers add ccdn.lezhin.com.
"""

from __future__ import annotations

import logging
from datetime import UTC, datetime
from typing import Any
from urllib.parse import urlparse

from connectors.base import SourceConnector
from connectors.http.cache import TTLCache
from connectors.http.client import ConnectorHttpError, SyncConnectorHttpClient
from connectors.ids import fully_unquote
from connectors.models import BrowseMode, Chapter, Page, PaginatedSeriesList, Series

logger = logging.getLogger(__name__)

SITE_BASE = "https://manhwaweb.com"
API_BASE = "https://api.manhwaweb.com"
PAGE_SIZE = 30
BROWSER_USER_AGENT = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
)

#: Browse mode -> the library's ``order_item`` (all served descending).
SORTS = {"popular": "popularidad", "latest": "creacion", "alphabetical": "alfabetico"}

#: Library-card ``_categoris`` ids, from the filter menu in the site's own JS
#: bundle. Ids the menu does not name are dropped rather than guessed.
GENRES = {
    1: "Drama", 2: "Romance", 3: "Acción", 5: "Venganza", 6: "Harem", 8: "Milf",
    18: "Comedia", 23: "Fantasía", 25: "Tragedia", 27: "Girls love",
    28: "Historias cortas", 29: "Aventura", 30: "Ecchi", 31: "Sobrenatural",
    32: "Horror", 33: "Ciencia ficción", 34: "Gore", 35: "Cultivación (cultivo)",
    37: "Sistema de niveles", 38: "Apocalíptico", 39: "Artes marciales",
    40: "Superpoderes", 41: "Reencarnación", 42: "Recuentos de la vida",
    43: "Psicológico", 44: "Thriller", 45: "Boys love",
}

STATUSES = {"publicandose": "ongoing", "finalizado": "completed", "pausado": "hiatus"}

READER_PREFIX = f"{SITE_BASE}/leer/"


def _empty(page: int) -> PaginatedSeriesList:
    return PaginatedSeriesList(items=[], page=page, page_size=PAGE_SIZE, total=0, api_has_more=False)


def _title(item: dict[str, Any]) -> str:
    for key in ("the_real_name", "name_esp", "_name"):
        value = item.get(key)
        if isinstance(value, str) and value.strip():
            return value.strip()
    return ""


def _card(item: Any) -> Series | None:
    if not isinstance(item, dict):
        return None
    series_id = item.get("real_id") or item.get("_id")
    title = _title(item)
    if not isinstance(series_id, str) or not series_id or not title:
        return None
    cover = item.get("_imagen")
    return Series(
        id=series_id,
        title=title,
        chapter_count=int(item.get("_numero_cap") or 0),
        cover_url=cover if isinstance(cover, str) and cover.startswith("https://") else None,
        status=STATUSES.get(str(item.get("_status") or "")),
        genres=_genres(item.get("_categoris")),
    )


def _genres(raw: Any) -> tuple[str, ...]:
    """Library cards list bare ids; the detail payload lists ``{"1": "Drama"}``."""
    names: list[str] = []
    for entry in raw if isinstance(raw, list) else ():
        if isinstance(entry, dict):
            names.extend(v.strip() for v in entry.values() if isinstance(v, str) and v.strip())
        elif isinstance(entry, int) and entry in GENRES:
            names.append(GENRES[entry])
    return tuple(names)


def parse_library(payload: Any, *, page: int) -> PaginatedSeriesList:
    """Map a ``/manhwa/library`` payload to a listing (``page`` is 1-based)."""
    if not isinstance(payload, dict) or not isinstance(payload.get("data"), list):
        return _empty(page)
    items = [s for s in map(_card, payload["data"]) if s is not None]
    has_more = bool(payload.get("next")) and bool(items)
    return PaginatedSeriesList(
        items=items,
        page=page,
        page_size=PAGE_SIZE,
        total=(page - 1) * PAGE_SIZE + len(items) + (1 if has_more else 0),
        api_has_more=has_more,
    )


def parse_series(payload: Any, *, series_id: str) -> Series | None:
    card = _card(payload)
    if card is None:
        return None
    authors = [a for a in (payload.get("_extras") or {}).get("autores") or () if isinstance(a, str)]
    synopsis = payload.get("_sinopsis")
    return Series(
        id=series_id,
        title=card.title,
        chapter_count=len(parse_chapters(payload, series_id=series_id)),
        canonical_path=f"/manhwa/{series_id}",
        description=synopsis.strip() if isinstance(synopsis, str) and synopsis.strip() else None,
        cover_url=card.cover_url,
        author=", ".join(authors) or None,
        status=card.status,
        genres=card.genres,
    )


def _chapter_key(entry: dict[str, Any]) -> str | None:
    """The ``/leer/`` key of a chapter entry, or None when it reads off-site.

    Most entries carry ``link``; some only carry ``versions[].link``. A link
    to another site (the SPA hides those rows) has nothing this API can serve.
    """
    links = [entry.get("link")] + [
        v.get("link") for v in entry.get("versions") or () if isinstance(v, dict)
    ]
    for link in links:
        if isinstance(link, str) and link.startswith(READER_PREFIX):
            key = link.removeprefix(READER_PREFIX).strip("/")
            if key:
                return key
    return None


def parse_chapters(payload: Any, *, series_id: str) -> list[Chapter]:
    if not isinstance(payload, dict):
        return []
    chapters: dict[str, Chapter] = {}
    for entry in payload.get("chapters") or ():
        if not isinstance(entry, dict):
            continue
        key = _chapter_key(entry)
        number = entry.get("chapter")
        if key is None or not isinstance(number, (int, float)) or key in chapters:
            continue
        versions = [v for v in entry.get("versions") or () if isinstance(v, dict)]
        created = entry.get("create") or (versions[0].get("create") if versions else None)
        release = (
            datetime.fromtimestamp(created / 1000, tz=UTC).date().isoformat()
            if isinstance(created, (int, float)) and created > 0
            else None
        )
        label = int(number) if float(number).is_integer() else number
        chapters[key] = Chapter(
            id=key,
            series_id=series_id,
            title=f"Capítulo {label}",
            number=float(number),
            page_count=0,
            release_date=release,
        )
    return sorted(chapters.values(), key=lambda c: c.number or 0.0)


def make_page_id(chapter_id: str, number: int) -> str:
    return f"{chapter_id}:{number}"


def page_id_chapter_id(page_id: str) -> str | None:
    chapter_id, sep, number = page_id.rpartition(":")
    return chapter_id if sep and chapter_id and number.isdigit() else None


def parse_pages(payload: Any, *, chapter_id: str) -> list[Page]:
    chapter = payload.get("chapter") if isinstance(payload, dict) else None
    images = chapter.get("img") if isinstance(chapter, dict) else None
    urls = [u for u in images or () if isinstance(u, str) and u.startswith("https://")]
    return [
        Page(id=make_page_id(chapter_id, n), chapter_id=chapter_id, number=n, remote_url=url)
        for n, url in enumerate(urls, start=1)
    ]


class ManhwaWebConnector(SourceConnector):
    """Browse and read the adult catalogue of ManhwaWeb (Spanish)."""

    SOURCE_TYPE = "manhwaweb"
    DISPLAY_NAME = "ManhwaWeb"
    DESCRIPTION = (
        "Browse and read adult manhwa in Spanish from ManhwaWeb. "
        "Images are proxied through ManhwaManiacs."
    )
    BROWSABLE = True
    SUPPORTS_IMPORT = False
    MATURE = True

    def __init__(self) -> None:
        self._http = SyncConnectorHttpClient(
            API_BASE,
            headers={"Referer": f"{SITE_BASE}/", "Origin": SITE_BASE},
            user_agent=BROWSER_USER_AGENT,
            min_interval=0.3,
        )
        # One /manhwa/see payload holds both the metadata and the chapter list.
        self._series_cache: TTLCache[dict[str, Any]] = TTLCache(ttl_seconds=300.0)
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
        # Every host seen across 300 library cards and a 24-series chapter
        # sample from the VPS; manhwaweb.com serves the "no cover" placeholder.
        return frozenset(
            {"img1mw.xyz", "img2mw.xyz", "imagizer.imageshack.com", "ccdn.lezhin.com", "manhwaweb.com"}
        )

    def image_fetch_headers(self) -> dict[str, str]:
        # img1mw/img2mw answer a Cloudflare 403 without it; lezhin ignores it.
        return {"Referer": f"{SITE_BASE}/", "User-Agent": BROWSER_USER_AGENT}

    def list_browse_modes(self) -> list[BrowseMode]:
        return [
            BrowseMode(id="popular", label="Popular"),
            BrowseMode(id="latest", label="Recently Added"),
            BrowseMode(id="alphabetical", label="A-Z"),
        ]

    def _get(self, path: str, params: dict[str, Any] | None = None) -> Any:
        """GET JSON, or None on any upstream failure (404s included)."""
        try:
            return self._http.get_json_value(path, params=params)
        except ConnectorHttpError as exc:
            logger.warning("ManhwaWeb GET %s failed: %s", path, exc)
            return None

    def _library(self, page: int, *, query: str, sort: str | None) -> PaginatedSeriesList:
        page = max(page, 1)
        order = SORTS.get((sort or "").strip().casefold(), SORTS["popular"])
        params = {
            "buscar": query,
            "estado": "",
            "tipo": "",
            "erotico": "si",
            "demografia": "",
            "order_item": order,
            "order_dir": "desc",
            "page": page - 1,
            "generes": "",
        }
        listing = parse_library(self._get("/manhwa/library", params), page=page)
        logger.info(
            "ManhwaWeb library page=%d order=%s query=%r count=%d",
            page, order, query, len(listing.items),
        )
        return listing

    def get_series_list(self, page: int, *, sort: str | None = None) -> PaginatedSeriesList:
        return self._library(page, query="", sort=sort)

    def search_series(self, query: str, page: int, *, sort: str | None = None) -> PaginatedSeriesList:
        normalized = query.strip()
        if not normalized:
            return self.get_series_list(page, sort=sort)
        # Alphabetical unless asked: the site's own search page orders that way.
        return self._library(page, query=normalized, sort=sort or "alphabetical")

    def _normalize_series_id(self, series_id: str) -> str:
        value = fully_unquote(series_id).strip().strip("/")
        return urlparse(value).path.rstrip("/").rsplit("/", 1)[-1] if "/" in value else value

    def _detail(self, series_id: str) -> dict[str, Any] | None:
        cached = self._series_cache.get(series_id)
        if cached is not None:
            return cached
        payload = self._get(f"/manhwa/see/{series_id}")
        if not isinstance(payload, dict) or not payload.get("real_id"):
            return None
        self._series_cache.set(series_id, payload)
        return payload

    def get_series(self, series_id: str) -> Series | None:
        sid = self._normalize_series_id(series_id)
        payload = self._detail(sid) if sid else None
        return parse_series(payload, series_id=sid) if payload else None

    def get_chapters(self, series_id: str) -> list[Chapter]:
        sid = self._normalize_series_id(series_id)
        payload = self._detail(sid) if sid else None
        return parse_chapters(payload, series_id=sid) if payload else []

    def get_chapter_pages(self, chapter_id: str) -> list[Page]:
        cid = fully_unquote(chapter_id).strip().strip("/").removeprefix("leer/")
        if not cid:
            return []
        cached = self._page_cache.get(cid)
        if cached is not None:
            return cached
        pages = parse_pages(self._get(f"/chapters/see/{cid}"), chapter_id=cid)
        if pages:  # never pin a transient failure for the TTL
            self._page_cache.set(cid, pages)
        return pages

    def find_page(self, page_id: str) -> Page | None:
        chapter_id = page_id_chapter_id(fully_unquote(page_id).strip())
        if chapter_id is None:
            return None
        for page in self.get_chapter_pages(chapter_id):
            if page.id == page_id:
                return page
        return None
