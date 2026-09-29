"""The Circle: members, member page, feed, per-series readers, clear (backend/08)."""

from __future__ import annotations

from typing import Annotated, Literal

from fastapi import APIRouter, Depends, Query, Response

from core.profile_context import require_profile_context
from services.circle_service import CircleService, _home_builder, get_circle_service
from services.home_service import LIVE_SECTION_BUILDERS

router = APIRouter(
    prefix="/circle",
    tags=["circle"],
    dependencies=[Depends(require_profile_context)],
)

ServiceDep = Annotated[CircleService, Depends(get_circle_service)]
TzQuery = Annotated[int, Query(ge=-720, le=840)]

if _home_builder not in LIVE_SECTION_BUILDERS:
    LIVE_SECTION_BUILDERS.append(_home_builder)


@router.get("/members")
def members(service: ServiceDep, tz_offset_minutes: TzQuery = 0) -> list[dict]:
    return service.members_list(tz_offset_minutes)


@router.get("/members/{profile_id}")
def member(profile_id: int, service: ServiceDep, tz_offset_minutes: TzQuery = 0) -> dict:
    return service.member_page(profile_id, tz_offset_minutes)


@router.get("/feed")
def feed(
    service: ServiceDep,
    cursor: str | None = None,
    limit: Annotated[int, Query(ge=1, le=100)] = 50,
    profile_id: int | None = None,
    kind: Literal["reading", "reaction"] | None = None,
) -> dict:
    return service.feed(cursor=cursor, limit=limit, profile_id=profile_id, kind=kind)


@router.get("/series")
def series(
    service: ServiceDep,
    source: Annotated[str, Query(min_length=1)],
    series: Annotated[str, Query(min_length=1)],
) -> dict:
    return service.series(source, series)


@router.delete("/activity", status_code=204)
def clear_activity(service: ServiceDep) -> Response:
    service.clear_activity()
    return Response(status_code=204)
