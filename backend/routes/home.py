"""``GET /home``: the one server-composed home feed both skins render."""

from __future__ import annotations

from typing import Annotated, Literal

from fastapi import APIRouter, Depends, Query

from services.home_service import HomeService, get_home_service

router = APIRouter(tags=["home"])

HomeDep = Annotated[HomeService, Depends(get_home_service)]


@router.get("/home")
def get_home(
    service: HomeDep,
    tz_offset_minutes: Annotated[int, Query(ge=-720, le=840)],
    content_kind: Literal["manga", "novel"] = "manga",
    refresh: Annotated[int, Query(ge=0, le=1)] = 0,
) -> dict[str, object]:
    """Cover story, Also in this issue and every section; see docs/home-api.md.

    ``refresh=1`` skips the 10-minute composed cache (Glass's pull to refresh).
    """
    return service.compose(content_kind, tz_offset_minutes, refresh=bool(refresh))
