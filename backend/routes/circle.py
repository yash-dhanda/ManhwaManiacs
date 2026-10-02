"""The Circle: members, member page, feed, per-series readers, clear (backend/08)."""

from __future__ import annotations

from typing import Annotated, Literal

from fastapi import APIRouter, Depends, Query, Response
from pydantic import BaseModel, Field, field_validator

from core.errors import AppError
from core.profile_context import require_profile_context
from services.circle_service import (
    NOTE_MAX,
    CircleService,
    note_length,
    _home_builder,
    _letters_builder,
    get_circle_service,
)
from services.home_service import LIVE_SECTION_BUILDERS

router = APIRouter(
    prefix="/circle",
    tags=["circle"],
    dependencies=[Depends(require_profile_context)],
)

ServiceDep = Annotated[CircleService, Depends(get_circle_service)]
TzQuery = Annotated[int, Query(ge=-720, le=840)]

for _builder in (_home_builder, _letters_builder):
    if _builder not in LIVE_SECTION_BUILDERS:
        LIVE_SECTION_BUILDERS.append(_builder)

SourceId = Annotated[str, Field(min_length=1, max_length=64)]
SeriesKey = Annotated[str, Field(min_length=1, max_length=512)]


class ChapterRef(BaseModel):
    source_id: SourceId
    series_key: SeriesKey
    chapter_key: SeriesKey


class ReactionBody(ChapterRef):
    kind: Literal["loved", "shook", "laughed", "tears", "chefs_kiss", "hype", "wrecked"]


class LetterBody(BaseModel):
    to_profile_ids: Annotated[list[int], Field(min_length=1, max_length=10)]
    source_id: SourceId
    series_key: SeriesKey
    note: str | None = None

    @field_validator("to_profile_ids")
    @classmethod
    def _unique(cls, ids: list[int]) -> list[int]:
        if len(set(ids)) != len(ids):
            raise ValueError("to_profile_ids must be unique")
        return ids

    @field_validator("note")
    @classmethod
    def _note(cls, note: str | None) -> str | None:
        note = (note or "").strip()
        # Counted the way the apps count it; the code-point cap only stops a pile of combining marks.
        if note_length(note) > NOTE_MAX or len(note) > NOTE_MAX * 8:
            raise ValueError(f"note is at most {NOTE_MAX} characters")
        return note or None


class LetterPatch(BaseModel):
    state: Literal["read", "kept", "dismissed"]


@router.get("/members")
def members(
    service: ServiceDep,
    tz_offset_minutes: TzQuery = 0,
    source_id: str | None = None,
    series_key: str | None = None,
) -> list[dict]:
    if (source_id is None) != (series_key is None):
        raise AppError(
            "source_id and series_key go together.",
            code="validation_error",
            status_code=422,
        )
    return service.members_list(tz_offset_minutes, source_id, series_key)


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


@router.get("/reactions")
def reactions(
    service: ServiceDep,
    source: Annotated[str, Query(min_length=1)],
    series: Annotated[str, Query(min_length=1)],
) -> dict:
    return service.reactions(source, series)


@router.post("/reactions")
def react(body: ReactionBody, service: ServiceDep) -> dict:
    return service.react(body.source_id, body.series_key, body.chapter_key, body.kind)


@router.delete("/reactions", status_code=204)
def unreact(body: ChapterRef, service: ServiceDep) -> Response:
    service.unreact(body.source_id, body.series_key, body.chapter_key)
    return Response(status_code=204)


@router.post("/letters", status_code=201)
def send_letter(body: LetterBody, service: ServiceDep) -> dict:
    return service.send_letters(
        body.to_profile_ids, body.source_id, body.series_key, body.note
    )


@router.get("/letters")
def letters(
    service: ServiceDep, box: Literal["inbox", "sent"] = "inbox"
) -> list[dict]:
    return service.sent() if box == "sent" else service.inbox()


@router.patch("/letters/{letter_id}")
def patch_letter(letter_id: int, body: LetterPatch, service: ServiceDep) -> dict:
    return service.patch_letter(letter_id, body.state)
