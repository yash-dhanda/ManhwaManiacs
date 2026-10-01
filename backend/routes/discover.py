"""Discover's genre grid: ``GET /discover/genre/{genre}/ai``."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, Path, Query, Request, Response

from core.rate_limit import limiter, sources_limit
from services.suggestion_service import SuggestionService, get_suggestion_service
from services.world_recs import WorldRecs, get_world_recs

router = APIRouter(prefix="/discover", tags=["discover"])


@router.get("/genre/{genre}/ai")
@limiter.limit(sources_limit)
def genre_ai(
    request: Request,
    response: Response,  # slowapi injects X-RateLimit-* headers into this
    service: Annotated[SuggestionService, Depends(get_suggestion_service)],
    world: Annotated[WorldRecs, Depends(get_world_recs)],
    genre: Annotated[str, Path(min_length=1, max_length=64)],
    cursor: Annotated[int, Query(ge=0, le=1000)] = 0,
) -> dict[str, object]:
    """One page of manhwa in ``genre``: DeepSeek names ~40 not on earlier pages,
    AniList confirms each (invented titles are dropped, counted in
    ``dropped``), cards are WorldItems. ``next_cursor`` is null only when the
    AI is unavailable AND the catalogue's own listing has run out.
    Rate-limited on the sources bucket: a cold page is ~40 AniList lookups."""
    return service.genre_page(genre, cursor, world=world)
