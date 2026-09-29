"""Series-level extras that are not a source's own data (cinematic §15.5).

``GET /series/enrichment``: the AniList credits block of the feature page.
Cached in ``world_catalog_cache`` for 30 days, a miss included, and gated for
18+ when served, never when stored.
"""

from __future__ import annotations

import hashlib
from datetime import timedelta
from typing import Annotated, Any

from fastapi import APIRouter, Depends, Query, Request, Response
from sqlalchemy import select
from sqlalchemy.orm import Session

from connectors.ids import fully_unquote
from core.errors import AppError
from core.rate_limit import limiter, sources_limit
from database.models import FollowedSeries, SourceSeriesCache
from database.session import get_db
from services.followed_series_service import (
    FollowedSeriesService,
    get_followed_series_service,
)
from services.world_recs import WorldCatalog, enrichment_payload

router = APIRouter(prefix="/series", tags=["series"])

LibraryDep = Annotated[FollowedSeriesService, Depends(get_followed_series_service)]
DbDep = Annotated[Session, Depends(get_db)]

ENRICHMENT_TTL = timedelta(days=30)
_SERVED = ("anilist_id", "format", "score", "official")


def enrichment_key(source_id: str, series_key: str) -> str:
    """``enrich:`` + SHA-1 hex: 47 characters, inside the 300-character key."""
    digest = hashlib.sha1(f"{source_id}\x1f{series_key}".encode()).hexdigest()
    return f"enrich:{digest}"


@router.get("/enrichment")
@limiter.limit(sources_limit)
def enrichment(
    request: Request,
    response: Response,  # slowapi injects X-RateLimit-* headers into this
    library: LibraryDep,
    db: DbDep,
    source: str = Query(..., min_length=1, max_length=64),
    series: str = Query(..., min_length=1, max_length=512),
) -> dict[str, Any] | None:
    """``{anilist_id, format, score, official}``, or ``null`` when AniList has
    no confident match, is down, or the match is adult and the gate is shut.

    404 ``series_not_found`` for a series this profile's gate hides.
    """
    library._browse.ensure_visible(source)
    series_key = fully_unquote(series)
    follow = db.execute(
        library._scope(
            select(FollowedSeries).where(
                FollowedSeries.source_id == source,
                FollowedSeries.series_key == series_key,
            )
        )
    ).scalar_one_or_none()
    if library._cache.series_hidden(source, series_key) or (
        follow is not None and library._hidden(follow)
    ):
        raise AppError("Series not found.", code="series_not_found", status_code=404)

    catalog = WorldCatalog(db)
    key = enrichment_key(source, series_key)
    found = catalog._read([key], ENRICHMENT_TTL)
    if key in found:
        payload = found[key]
    else:
        title = follow.title if follow is not None else None
        if not title:
            cached = db.get(SourceSeriesCache, (source, series_key))
            title = cached.title if cached is not None else None
        if not title:
            title = str(library._browse.get_series(source, series_key).get("title") or "")
        media = catalog.search([title]).get(title) if title else None
        if catalog.failed:
            return None  # an AniList outage: answered, never cached
        payload = enrichment_payload(media) if media else None
        catalog._write({key: payload})

    if payload is None or (payload.get("is_adult") and not library._gate_open()):
        return None
    return {field: payload.get(field) for field in _SERVED}
