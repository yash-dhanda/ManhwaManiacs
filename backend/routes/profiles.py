"""Reading-profile CRUD, scoped to the session user (household model).

Every endpoint operates only on the current user's profiles; a profile id that
belongs to another account (or does not exist) returns 404. The optional
``X-Profile-Id`` header is recorded into request-scoped context via a router-level
dependency — supplying it never fails a request.
"""

from __future__ import annotations

from typing import Annotated, Literal

from fastapi import APIRouter, Depends, Response, status
from pydantic import BaseModel, ConfigDict, Field

from core.errors import AppError
from core.profile_context import get_active_profile_id
from services import taste_service
from services.home_service import invalidate_profile
from services.profile_service import (
    REDESIGN_FIELDS,
    ProfileService,
    get_profile_service,
)

# Kept in lockstep with services.profile_service.ALLOWED_MOODS.
Mood = Literal[
    "romantic", "action", "comedy", "horror", "slice_of_life", "fantasy", "default"
]

router = APIRouter(
    prefix="/profiles",
    tags=["profiles"],
    dependencies=[Depends(get_active_profile_id)],
)

ProfileDep = Annotated[ProfileService, Depends(get_profile_service)]


class ProfileCreate(BaseModel):
    name: str = Field(min_length=1, max_length=255)
    avatar_key: str | None = Field(default=None, max_length=64)
    mood: Mood = "default"
    sort_order: int | None = Field(default=None, ge=0)
    mature_content_enabled: bool | None = None


class ProfileUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=255)
    avatar_key: str | None = Field(default=None, max_length=64)
    mood: Mood | None = None
    sort_order: int | None = Field(default=None, ge=0)
    mature_content_enabled: bool | None = None
    # Redesign fields. An explicit ``null`` resets skin / onboarding_step /
    # daily_goal_minutes; omitting a field leaves it alone (the route passes
    # only the fields the client sent). ``notify_enabled: null`` is "not sent".
    skin: Literal["cinematic", "glass"] | None = None
    notify_enabled: bool | None = None
    onboarding_step: Literal["done"] | Annotated[int, Field(ge=1, le=7)] | None = None
    daily_goal_minutes: Literal[5, 10, 15, 20, 30, 45, 60] | None = None


@router.get("")
def list_profiles(service: ProfileDep) -> list[dict[str, object]]:
    """List the current user's profiles, ordered by sort_order."""
    return [service.serialize(p) for p in service.list_profiles()]


@router.post("", status_code=status.HTTP_201_CREATED)
def create_profile(body: ProfileCreate, service: ProfileDep) -> dict[str, object]:
    """Create a profile for the current user (max 5 per account)."""
    profile = service.create_profile(
        name=body.name,
        avatar_key=body.avatar_key,
        mood=body.mood,
        sort_order=body.sort_order,
        mature_content_enabled=body.mature_content_enabled,
    )
    return service.serialize(profile)


@router.patch("/{profile_id}")
def update_profile(
    profile_id: int, body: ProfileUpdate, service: ProfileDep
) -> dict[str, object]:
    """Update a profile the current user owns (404 otherwise)."""
    profile = service.update_profile(
        profile_id,
        name=body.name,
        avatar_key=body.avatar_key,
        mood=body.mood,
        sort_order=body.sort_order,
        mature_content_enabled=body.mature_content_enabled,
        redesign=body.model_dump(
            exclude_unset=True, include=set(REDESIGN_FIELDS)
        ),
    )
    return service.serialize(profile)


@router.delete("/{profile_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_profile(profile_id: int, service: ProfileDep) -> Response:
    """Delete a profile the current user owns (404 otherwise)."""
    service.delete_profile(profile_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


class TasteSeed(BaseModel):
    model_config = ConfigDict(extra="forbid")

    anilist_id: int | None = Field(default=None, ge=1)
    source_id: str | None = Field(default=None, min_length=1, max_length=64)
    series_key: str | None = Field(default=None, min_length=1, max_length=512)


class TasteBody(BaseModel):
    """Every field optional; partial bodies merge into the stored taste."""

    model_config = ConfigDict(extra="forbid")

    step: Literal["done"] | Annotated[int, Field(ge=1, le=7)] | None = None
    formats: list[taste_service.Format] | None = Field(default=None, max_length=4)
    genres: dict[
        Annotated[str, Field(min_length=1, max_length=64)], Literal[-1, 0, 1, 2]
    ] | None = None
    styles: list[taste_service.Style] | None = Field(default=None, max_length=11)
    seeds: list[TasteSeed] | None = Field(default=None, max_length=taste_service.MAX_SEEDS)


def _seed_ok(seed: TasteSeed) -> bool:
    return seed.anilist_id is not None or bool(seed.source_id and seed.series_key)


@router.put("/{profile_id}/taste")
def put_taste(profile_id: int, body: TasteBody, service: ProfileDep) -> dict[str, object]:
    """Merge onboarding answers into the profile's taste (404 for another
    account's profile). ``step`` is written to ``onboarding_step``."""
    profile = service._get_owned(profile_id)
    patch = body.model_dump(exclude_unset=True)
    if body.seeds is not None:
        if not all(_seed_ok(s) for s in body.seeds):
            raise AppError(
                "A seed needs anilist_id, or source_id and series_key.",
                code="taste_invalid",
                status_code=422,
            )
        patch["seeds"] = [
            {"anilist_id": s.anilist_id}
            if s.anilist_id is not None
            else {"source_id": s.source_id, "series_key": s.series_key}
            for s in body.seeds
        ]
    out = taste_service.write_taste(profile, patch)
    service._db.commit()
    invalidate_profile(profile_id)
    return out


@router.get("/{profile_id}/taste")
def get_taste(profile_id: int, service: ProfileDep) -> dict[str, object]:
    return taste_service.read_taste(service._get_owned(profile_id))
