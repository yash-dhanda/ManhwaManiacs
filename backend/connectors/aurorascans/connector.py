"""Aurora Scans online source connector (QiManga / EZManhwa API)."""

from __future__ import annotations

import logging
from typing import Any

from connectors.aurorascans.mappers import (
    API_BASE,
    PAGE_SIZE,
    SITE_BASE,
    chapter_item_to_chapter,
    chapter_pages_to_pages,
    genres_to_browse_modes,
    page_id_chapter_id,
    parse_chapter_id,
    payload_requires_purchase,
    resolve_sort,
    series_detail_to_series,
    series_list_to_paginated,
)
from connectors.base import ChapterLockedError, SourceConnector
from connectors.http import swallowed
from connectors.http.cache import TTLCache
from connectors.http.client import ConnectorHttpError
from connectors.http.ddg_client import DdgSyncHttpClient
from connectors.models import BrowseMode, Chapter, Page, PaginatedSeriesList, Series

logger = logging.getLogger(__name__)

API_HEADERS = {
    "Accept": "application/json, text/plain, */*",
    "Origin": SITE_BASE,
    "Referer": f"{SITE_BASE}/browse",
}


class AuroraScansConnector(SourceConnector):
    """Browse and read from Aurora Scans (aurorascans.com → qimanga.com)."""

    SOURCE_TYPE = "aurorascans"
    DISPLAY_NAME = "Aurora Scans"
    DESCRIPTION = (
        "Browse and read manhwa and manga from Aurora Scans (QiManga). "
        "Images are proxied through ManhwaManiacs."
    )
    BROWSABLE = True
    SUPPORTS_IMPORT = False

    def __init__(self) -> None:
        self._http = DdgSyncHttpClient(API_BASE, headers=API_HEADERS)
        self._series_cache: TTLCache[Series] = TTLCache(ttl_seconds=300.0)
        self._chapter_list_cache: TTLCache[list[Chapter]] = TTLCache(ttl_seconds=180.0)
        self._page_cache: TTLCache[list[Page]] = TTLCache(ttl_seconds=600.0)
        self._genre_cache: TTLCache[list[BrowseMode]] = TTLCache(ttl_seconds=3600.0)

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
        return frozenset({"media.qimanga.com", "media.qimanhwa.com", "qimanga.com"})

    def image_fetch_headers(self) -> dict[str, str]:
        return {"Referer": f"{SITE_BASE}/"}

    #: Ids advertised before the canonical popular/latest/new set. ``resolve_sort`` maps both to the API's ``popular``.
    LEGACY_SORT_ALIASES = {"top_rated": "popular"}

    def list_browse_modes(self) -> list[BrowseMode]:
        # Canonical order: default (latest) first, then popular, latest, new.
        # ``top_rated`` was dropped as an exact duplicate of ``popular`` (see
        # resolve_sort, which still accepts it); /series accepts only latest,
        # newest, popular and alphabetical (a 400 names them, 2026-11-23), and
        # page 1 of each differs.
        return [
            BrowseMode(id="latest", label="Latest"),
            BrowseMode(id="popular", label="Popular"),
            BrowseMode(id="new", label="New"),
            BrowseMode(id="alphabetical", label="A-Z"),
        ]

    def list_genres(self) -> list[BrowseMode]:
        return self._genre_cache.get_or_set("genres", self._fetch_genres)

    def _fetch_genres(self) -> list[BrowseMode]:
        payload = self._http.get_json("/series/genres")
        return genres_to_browse_modes(payload)

    def _listing_params(
        self,
        page: int,
        *,
        sort: str | None = None,
        query: str | None = None,
        genre: str | None = None,
    ) -> dict[str, Any]:
        params: dict[str, Any] = {
            "page": page,
            "perPage": PAGE_SIZE,
        }
        if query:
            # /series/search rejects the `sort` param with a 400; only the
            # browse endpoint (/series) accepts it.
            params["q"] = query
        else:
            params["sort"] = resolve_sort(sort)
        if genre:
            params["genre"] = genre.strip().lower().replace(" ", "-")
        return params

    def _fetch_listing(
        self,
        page: int,
        *,
        sort: str | None = None,
        query: str | None = None,
        genre: str | None = None,
    ) -> PaginatedSeriesList:
        if page < 1:
            page = 1
        path = "/series/search" if query else "/series"
        payload = self._http.get_json(
            path,
            params=self._listing_params(page, sort=sort, query=query, genre=genre),
        )
        if not isinstance(payload, dict):
            raise ConnectorHttpError("Expected JSON object response.")
        return series_list_to_paginated(payload, page=page)

    def get_series_list(self, page: int, *, sort: str | None = None) -> PaginatedSeriesList:
        listing = self._fetch_listing(page, sort=sort)
        logger.info(
            "Aurora Scans browse sort=%r page=%d count=%d has_more=%s",
            sort,
            page,
            len(listing.items),
            listing.has_more,
        )
        return listing

    def browse_by_genre(
        self,
        genre: str,
        page: int,
        *,
        sort: str | None = None,
    ) -> PaginatedSeriesList:
        return self._fetch_listing(page, sort=sort, genre=genre)

    def search_series(self, query: str, page: int, *, sort: str | None = None) -> PaginatedSeriesList:
        if page < 1:
            page = 1
        normalized = query.strip()
        if not normalized:
            return self.get_series_list(page, sort=sort)
        listing = self._fetch_listing(page, sort=sort, query=normalized)
        logger.info(
            "Aurora Scans search page=%d count=%d sort=%r query=%r",
            page,
            len(listing.items),
            sort,
            normalized,
        )
        return listing

    def _normalize_series_slug(self, series_id: str) -> str:
        return series_id.strip().strip("/").split("/", 1)[0]

    def get_series(self, series_id: str) -> Series | None:
        slug = self._normalize_series_slug(series_id)
        cached = self._series_cache.get(slug)
        if cached is not None:
            return cached
        try:
            payload = self._http.get_json(f"/series/{slug}")
        except ConnectorHttpError as exc:
            # A 404 is "no such series"; anything else is the source failing,
            # which the None below would otherwise pass off as the same thing.
            swallowed.note(exc)
            return None
        if not isinstance(payload, dict):
            return None
        series = series_detail_to_series(payload)
        if series is None:
            return None
        self._series_cache.set(slug, series)
        return series

    def get_chapters(self, series_id: str) -> list[Chapter]:
        slug = self._normalize_series_slug(series_id)
        cached = self._chapter_list_cache.get(slug)
        if cached is not None:
            return cached
        chapters = self._fetch_chapters(slug)
        # An empty list is never cached: it is either a series with nothing
        # published yet (cheap to ask again) or a failure noted in
        # ``_fetch_chapters``, and ``TTLCache.get_or_set`` would have kept
        # either one for three minutes.
        if chapters:
            self._chapter_list_cache.set(slug, chapters)
        return chapters

    def _fetch_chapters(self, series_slug: str) -> list[Chapter]:
        chapters: list[Chapter] = []
        page = 1
        total_pages = 1
        while page <= total_pages:
            try:
                payload = self._http.get_json(
                    f"/series/{series_slug}/chapters",
                    # perPage is capped at 100 by the API (a larger value is a
                    # 400 "perPage must not be greater than 100", 2026-11-23).
                    params={"page": page, "perPage": 100, "sort": "desc"},
                )
            except ConnectorHttpError as exc:
                if page == 1:
                    # Nothing fetched yet: the caller's "no chapters" is the
                    # honest answer to a 404 and is what the convention gives
                    # a failure too, so note it for source health.
                    swallowed.note(exc)
                    return []
                # Page 2+ failed. A list missing its oldest (or newest)
                # chapters is not "the chapters", and the reader, progress and
                # update detection would all take it for the whole series, so
                # this is raised instead of returned short.
                raise
            if not isinstance(payload, dict):
                if page == 1:
                    return []
                raise ConnectorHttpError("Expected JSON object response.")
            total_pages = int(payload.get("totalPages") or page)
            for entry in payload.get("data") or []:
                if isinstance(entry, dict):
                    chapter = chapter_item_to_chapter(entry, series_slug=series_slug)
                    if chapter is not None:
                        chapters.append(chapter)
            page += 1
        # API returns chapters newest-first (sort=desc); the reader and
        # prev/next navigation (BrowseService.get_reader_chapter) require
        # ascending order, so normalize before returning.
        chapters.sort(key=lambda chapter: chapter.number if chapter.number is not None else 0.0)
        return chapters

    def get_chapter_pages(self, chapter_id: str) -> list[Page]:
        cached = self._page_cache.get(chapter_id)
        if cached is not None:
            return cached
        pages = self._fetch_chapter_pages(chapter_id)
        if pages:
            self._page_cache.set(chapter_id, pages)
        return pages

    def _fetch_chapter_pages(self, chapter_id: str) -> list[Page]:
        parsed = parse_chapter_id(chapter_id)
        if parsed is None:
            return []
        series_slug, chapter_slug = parsed
        try:
            payload = self._http.get_json(f"/series/{series_slug}/chapters/{chapter_slug}")
        except ConnectorHttpError as exc:
            if exc.status_code == 404:
                # "Chapter not found" from the API itself (measured
                # 2026-11-23): the one failure that really is an empty list.
                return []
            # Anything else is the source failing. BrowseService maps a raised
            # ConnectorHttpError to a 502; an empty list would have been a
            # 404 "Chapter not found" about a chapter that exists.
            raise
        if not isinstance(payload, dict):
            return []
        if payload_requires_purchase(payload):
            # Paid chapters are dropped from the list (chapter_item_to_chapter),
            # so this is a chapter that went paid after the list was cached, a
            # bookmark, or a pasted link. The API states no unlock time
            # (``becameFreeAt`` is null until it happens, checked 2026-11-23),
            # so there is nothing to count down to: locked, no instant.
            raise ChapterLockedError(None)
        return chapter_pages_to_pages(chapter_id, payload)

    def find_page(self, page_id: str) -> Page | None:
        chapter_id = page_id_chapter_id(page_id)
        if chapter_id is None:
            return None
        try:
            pages = self.get_chapter_pages(chapter_id)
        except ChapterLockedError:
            # A page id only exists for a chapter that served pages, so this
            # is one that went paid since. To the image route: not there.
            return None
        for page in pages:
            if page.id == page_id:
                return page
        return None
