"""``/ai/*``: More like this, Previously on recaps, tags and feedback on picks.

See ``docs/home-api.md`` for every query, body, response and SSE event.
"""

from __future__ import annotations

from typing import Annotated, Literal

from fastapi import APIRouter, Depends, Query, Request, Response
from fastapi.responses import JSONResponse, StreamingResponse
from pydantic import BaseModel, ConfigDict, Field

from core.errors import AppError
from core.profile_context import require_profile_context
from core.rate_limit import limiter, sources_limit
from services.ai_series_service import AiSeriesService, get_ai_series_service
from services.followed_series_service import (
    FollowedSeriesService,
    get_followed_series_service,
)
from services.recap_service import RecapService
from services.series_gate import require_series_visible
from services.suggestion_service import SuggestionService, get_suggestion_service
from database.session import get_db
from sqlalchemy.orm import Session

router = APIRouter(prefix="/ai", tags=["ai"])

AiDep = Annotated[AiSeriesService, Depends(get_ai_series_service)]
LibraryDep = Annotated[FollowedSeriesService, Depends(get_followed_series_service)]
SuggestDep = Annotated[SuggestionService, Depends(get_suggestion_service)]
DbDep = Annotated[Session, Depends(get_db)]

SourceQ = Annotated[str, Query(min_length=1, max_length=64)]
SeriesQ = Annotated[str, Query(min_length=1, max_length=512)]
ToQ = Annotated[str, Query(min_length=1, max_length=512)]


@router.get("/similar")
@limiter.limit(sources_limit)
def similar(
    request: Request,
    response: Response,  # slowapi injects X-RateLimit-* headers into this
    service: AiDep,
    source: Annotated[str | None, Query(min_length=1, max_length=64)] = None,
    series: Annotated[str | None, Query(min_length=1, max_length=512)] = None,
    anilist_id: Annotated[int | None, Query(ge=1)] = None,
    fallback: Literal["genres"] | None = None,
) -> dict[str, object]:
    """More like this: a series (``source`` + ``series``) or, for onboarding, an
    AniList id. Exactly one form; both or neither is 422."""
    by_series = source is not None or series is not None
    if by_series == (anilist_id is not None) or (by_series and (source is None or series is None)):
        raise AppError(
            "Send source and series, or anilist_id.", code="similar_bad_query", status_code=422
        )
    return service.similar(source=source, series=series, anilist_id=anilist_id, fallback=fallback)


@router.get("/tags")
def tags(service: AiDep, source: SourceQ, series: SeriesQ) -> dict[str, object]:
    return service.tags(source, series)


class FeedbackBody(BaseModel):
    model_config = ConfigDict(extra="forbid")

    signal: Literal["not_interested", "undo", "liked_pick", "tag_rejected", "clear"]
    anilist_id: int | None = Field(default=None, ge=1)
    source_id: str | None = Field(default=None, min_length=1, max_length=64)
    series_key: str | None = Field(default=None, min_length=1, max_length=512)
    tag: str | None = Field(default=None, min_length=1, max_length=64)


@router.post(
    "/feedback", status_code=204, dependencies=[Depends(require_profile_context)]
)
def feedback(body: FeedbackBody, service: AiDep) -> Response:
    service.feedback(
        body.signal,
        anilist_id=body.anilist_id,
        source_id=body.source_id,
        series_key=body.series_key,
        tag=body.tag,
    )
    return Response(status_code=204)


def _recap_service(db: Session, library: FollowedSeriesService, suggest: SuggestionService) -> RecapService:
    return RecapService(db, library, suggest)


@router.get("/recap/availability")
def recap_availability(
    db: DbDep,
    library: LibraryDep,
    suggest: SuggestDep,
    source: SourceQ,
    series: SeriesQ,
    to: ToQ,
    scope: Literal["series", "chapter"] = "series",
) -> dict[str, object]:
    key = require_series_visible(library, source, series)
    return _recap_service(db, library, suggest).availability(source, key, to, scope=scope)


@router.get("/recap")
def recap(
    db: DbDep,
    library: LibraryDep,
    suggest: SuggestDep,
    source: SourceQ,
    series: SeriesQ,
    to: ToQ,
    shape: Literal["prose", "deck"] = "prose",
    scope: Literal["series", "chapter"] = "series",
    fresh: bool = False,
):
    """Server-Sent Events, or plain JSON ``{available: false, reason}`` when no
    recap can be written (nothing is streamed then). ``fresh=1`` skips a cached
    recap and writes it again (budget and rate limit apply as for a miss)."""
    if shape == "prose" and scope == "chapter":
        raise AppError(
            "A prose recap covers the series.", code="recap_bad_query", status_code=422
        )
    key = require_series_visible(library, source, series)
    outcome = _recap_service(db, library, suggest).recap(
        source, key, to, shape=shape, scope=scope, fresh=fresh
    )
    if outcome.stream is None:
        return JSONResponse(outcome.body, headers=outcome.headers)
    return StreamingResponse(
        outcome.stream,
        media_type="text/event-stream; charset=utf-8",
        headers={"Cache-Control": "no-cache, no-transform", "X-Accel-Buffering": "no"},
    )
