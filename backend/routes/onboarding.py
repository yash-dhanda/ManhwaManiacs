"""``GET /onboarding/catalog``: what the onboarding steps show."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, Query, Request, Response

from core.errors import AppError
from core.rate_limit import limiter, sources_limit
from services.taste_service import FORMATS, STYLES, TasteService, get_taste_service

router = APIRouter(prefix="/onboarding", tags=["onboarding"])


def _csv(raw: str | None, allowed: tuple[str, ...] | None, what: str) -> list[str]:
    values = [v.strip() for v in (raw or "").split(",") if v.strip()]
    bad = [v for v in values if (allowed is not None and v not in allowed) or len(v) > 64]
    if bad or len(values) > 80:
        raise AppError(f"Unknown {what}.", code="taste_invalid", status_code=422)
    return list(dict.fromkeys(values))


@router.get("/catalog")
@limiter.limit(sources_limit)
def catalog(
    request: Request,
    response: Response,  # slowapi injects X-RateLimit-* headers into this
    service: Annotated[TasteService, Depends(get_taste_service)],
    formats: Annotated[str | None, Query(max_length=200)] = None,
    genres: Annotated[str | None, Query(max_length=2000)] = None,
    styles: Annotated[str | None, Query(max_length=400)] = None,
) -> dict[str, object]:
    return service.catalog(
        _csv(formats, FORMATS, "format"),
        _csv(genres, None, "genre"),
        _csv(styles, STYLES, "style"),
    )
