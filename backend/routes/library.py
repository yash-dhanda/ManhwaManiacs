"""Per-profile library (source-native, spec §4.2).

A series is in the library iff a ``followed_series`` row exists for it. All
endpoints are scoped to the request's ``(user_id, profile_id)``.
"""

from __future__ import annotations

from typing import Annotated, Literal

from fastapi import APIRouter, Depends, Query, Request, Response
from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator
from sqlalchemy.orm import Session

from core.errors import AppError

from core.profile_context import require_profile_context
from core.rate_limit import limiter, sources_limit, suggest_limit
from database.session import get_db
from services.cover_colour import attach_cover_colours
from services.followed_series_service import (
    FollowedSeriesService,
    get_followed_series_service,
)
from services.suggestion_service import (
    SuggestionService,
    get_suggestion_service,
)
from services.world_recs import WorldRecs, get_world_recs
from utils.api_pagination import set_list_total_header

router = APIRouter(prefix="/library", tags=["library"])

ServiceDep = Annotated[FollowedSeriesService, Depends(get_followed_series_service)]
SuggestDep = Annotated[SuggestionService, Depends(get_suggestion_service)]
WorldDep = Annotated[WorldRecs, Depends(get_world_recs)]
DbDep = Annotated[Session, Depends(get_db)]


class FollowRequest(BaseModel):
    source_id: str = Field(min_length=1, max_length=64)
    series_key: str = Field(min_length=1, max_length=512)


class SeriesPatchRequest(BaseModel):
    is_favorite: bool | None = None
    reading_status: str | None = None
    notify: bool | None = None
    mature_override: bool | None = None
    sort_order: int | None = None


class RepointRequest(BaseModel):
    source_id: str = Field(min_length=1, max_length=64)
    series_key: str = Field(min_length=1, max_length=512)
    keep_old: bool = False


class RuleCondition(BaseModel):
    """One smart-shelf condition (cinematic §15.5). Stored, never evaluated."""

    model_config = ConfigDict(extra="forbid")

    field: Literal["reading_status", "is_favorite", "new_count", "format", "content_kind"]
    op: Literal["eq", "gte", "in", "ne"]
    value: (
        bool
        | int
        | str
        | Annotated[list[str], Field(min_length=1, max_length=20)]
    )

    @model_validator(mode="after")
    def _shape(self) -> "RuleCondition":
        if (self.op == "in") != isinstance(self.value, list):
            raise ValueError("'in' takes a list of strings; every other op a scalar")
        if self.op == "gte" and self.field != "new_count":
            raise ValueError("'gte' applies to new_count only")
        return self


class CollectionRules(BaseModel):
    model_config = ConfigDict(extra="forbid")

    all: list[RuleCondition] = Field(min_length=1, max_length=8)


class CollectionCreateRequest(BaseModel):
    name: str = Field(min_length=1, max_length=255)
    description: str | None = None
    rules: CollectionRules | None = None


class CollectionUpdateRequest(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=255)
    description: str | None = None
    sort_order: int | None = None
    rules: CollectionRules | None = None


class CollectionOrderRequest(BaseModel):
    items: list["CollectionSeriesRequest"]


class CollectionSeriesRequest(BaseModel):
    source_id: str = Field(min_length=1, max_length=64)
    series_key: str = Field(min_length=1, max_length=512)


class TagCreateRequest(BaseModel):
    name: str = Field(min_length=1, max_length=255)
    category: str = Field(default="custom")
    color: str | None = Field(default=None, max_length=16)


class TagPatchRequest(BaseModel):
    name: str | None = Field(default=None, max_length=255)
    color: str | None = Field(default=None, pattern=r"^#[0-9A-Fa-f]{6}$")

    @field_validator("name")
    @classmethod
    def _trimmed(cls, value: str | None) -> str | None:
        if value is not None and not value.strip():
            raise ValueError("name must not be blank")
        return value.strip() if value is not None else None


class SeriesTagRequest(BaseModel):
    source_id: str = Field(min_length=1, max_length=64)
    series_key: str = Field(min_length=1, max_length=512)
    tag_id: int = Field(ge=1)


# ---------------------------------------------------------------------------
# Followed series
# ---------------------------------------------------------------------------


@router.get("/series")
def list_series(
    service: ServiceDep,
    db: DbDep,
    page: int = Query(1, ge=1),
    per_page: int = Query(40, ge=1, le=200),
    sort: str = Query("title"),
    search: str | None = None,
    reading_status: str | None = None,
    is_favorite: bool | None = None,
    tag_ids: str | None = None,
    new_only: bool = False,
) -> dict[str, object]:
    """Paginated list of the profile's followed series.

    Each item carries ``read_state`` — started or not, the furthest chapter
    opened and how many lie past it — so a card can say where the reader is
    without a request per series — and its ``tags``.

    Every filter and sort runs over the whole library before paging:
    ``tag_ids=1,4`` (any-of), ``new_only``, and the sorts ``last_read_at`` /
    ``-last_read_at`` (never-read last) and ``-new_count`` (unknown last).
    """
    listing = service.list_series(
        page=page,
        per_page=per_page,
        sort=sort,
        search=search,
        reading_status=reading_status,
        is_favorite=is_favorite,
        tag_ids=_tag_ids(tag_ids),
        new_only=new_only,
    )
    attach_cover_colours(db, listing["items"])
    return listing


def _tag_ids(raw: str | None) -> list[int] | None:
    """``"1,4"`` -> ``[1, 4]``; anything but positive integers is 422."""
    if raw is None:
        return None
    try:
        ids = [int(part) for part in raw.split(",")]
    except ValueError:
        ids = []
    if not ids or any(i < 1 for i in ids):
        raise AppError(
            "tag_ids must be comma-separated positive integers.",
            code="invalid_tag_ids",
            status_code=422,
        )
    return ids


@router.get("/series/{followed_id}")
def get_series(followed_id: int, service: ServiceDep, db: DbDep) -> dict[str, object]:
    """Followed-series detail: snapshot + cached meta + live chapter list."""
    return attach_cover_colours(db, [service.get_detail(followed_id)])[0]


@router.patch(
    "/series/{followed_id}", dependencies=[Depends(require_profile_context)]
)
def patch_series(
    followed_id: int, body: SeriesPatchRequest, service: ServiceDep, db: DbDep
) -> dict[str, object]:
    """Update favorite / reading_status / notify / mature_override / sort_order."""
    row = service.patch(followed_id, **body.model_dump(exclude_unset=True))
    return attach_cover_colours(db, [row])[0]


@router.post(
    "/series/{followed_id}/repoint", dependencies=[Depends(require_profile_context)]
)
def repoint_series(
    followed_id: int, body: RepointRequest, service: ServiceDep, db: DbDep
) -> dict[str, object]:
    """Move a follow to another source (``keep_old`` keeps the old one too).

    Completed chapters carry over by chapter number without inventing reading
    time; ``mapped_chapter_key`` is where the reader resumes on the target.
    """
    result = service.repoint(
        followed_id, body.source_id, body.series_key, keep_old=body.keep_old
    )
    attach_cover_colours(db, [result["followed"]])
    return result


@router.post("/follow", dependencies=[Depends(require_profile_context)])
def follow_series(
    body: FollowRequest, service: ServiceDep, db: DbDep
) -> dict[str, object]:
    """Follow a series (add it to the profile's library)."""
    return attach_cover_colours(db, [service.follow(body.source_id, body.series_key)])[0]


@router.delete(
    "/follow/{followed_id}",
    status_code=204,
    dependencies=[Depends(require_profile_context)],
)
def unfollow_series(followed_id: int, service: ServiceDep) -> None:
    """Unfollow a series. Reading progress (keyed by source/series) survives."""
    service.unfollow(followed_id)


# ---------------------------------------------------------------------------
# Strips / stats
# ---------------------------------------------------------------------------


@router.get("/continue-reading")
def continue_reading(
    service: ServiceDep,
    db: DbDep,
    response: Response,
    limit: int = Query(10, ge=1, le=50),
) -> list[dict[str, object]]:
    items = service.continue_reading(limit=limit)
    set_list_total_header(response, len(items))
    return attach_cover_colours(db, items)


@router.get("/recently-updated")
def recently_updated(
    service: ServiceDep,
    response: Response,
    limit: int = Query(10, ge=1, le=50),
) -> list[dict[str, object]]:
    items = service.recently_updated(limit=limit)
    set_list_total_header(response, len(items))
    return items


@router.get("/recommendations")
def recommendations(
    service: ServiceDep,
    response: Response,
    limit: int = Query(10, ge=1, le=50),
) -> list[dict[str, object]]:
    items = service.recommendations(limit=limit)
    set_list_total_header(response, len(items))
    return items


class SuggestRequest(BaseModel):
    prompt: str = Field(min_length=3, max_length=600)
    limit: int = Field(default=6, ge=1, le=8)


@router.get("/suggest/availability")
def suggest_availability(service: SuggestDep) -> dict[str, object]:
    """Whether AI suggestions can run, without running one.

    Free and local: it reads whether a key is configured and how much of
    today's allowance is left. The clients call it on mount and hide the
    prompt box when it says no, rather than offering a button that 503s —
    an unconfigured key is a deployment state, not an error to surface at
    the moment somebody finally types a sentence.
    """
    return service.availability()


@router.post("/suggest")
@limiter.limit(suggest_limit)
def suggest(
    body: SuggestRequest,
    request: Request,
    response: Response,  # slowapi injects X-RateLimit-* headers into this
    service: SuggestDep,
    db: DbDep,
) -> dict[str, object]:
    """Describe what you feel like reading; get series this server can open.

    Every returned item is a real row in the catalog cache, so every card
    opens. Titles the model names that are not on that shelf are counted in
    ``dropped`` and discarded — a suggestion nobody can read is worse than
    one fewer suggestion.

    Rate-limited on its own bucket and capped on its own daily ledger,
    because one accepted request here is one paid API call.
    """
    result = service.suggest(
        body.prompt,
        base_url=str(request.base_url),
        limit=body.limit,
    )
    attach_cover_colours(
        db, result["items"], key=lambda item: (item["source"], item["series_id"])
    )
    return result


class WorldSuggestRequest(BaseModel):
    prompt: str = Field(min_length=3, max_length=600)
    limit: int = Field(default=12, ge=1, le=15)


@router.get("/world/recommendations")
@limiter.limit(sources_limit)
def world_recommendations(
    request: Request,
    response: Response,  # slowapi injects X-RateLimit-* headers into this
    world: WorldDep,
    seeds: int = Query(5, ge=1, le=8),
    per_seed: int = Query(10, ge=3, le=15),
) -> dict[str, object]:
    """Worldwide recommendations for the series this profile reads most.

    Candidates come from AniList, chapter counts from MangaUpdates; each item
    says which of this reader's sources carry it (``available``), and an item
    none of them carries is still returned, as information. Rate-limited on
    the sources bucket: a cold page makes a few dozen public-API calls.
    """
    return world.recommendations(seeds=seeds, per_seed=per_seed)


@router.post("/world/suggest")
@limiter.limit(suggest_limit)
def world_suggest(
    body: WorldSuggestRequest,
    request: Request,
    response: Response,  # slowapi injects X-RateLimit-* headers into this
    service: SuggestDep,
    world: WorldDep,
) -> dict[str, object]:
    """The AI box, answered from the whole medium rather than the local cache.

    Every title the model names is confirmed against AniList before it is
    returned; the ones AniList cannot match are counted in ``dropped``.
    Shares ``/suggest``'s daily ledger and rate-limit bucket.
    """
    return service.world_suggest(body.prompt, world=world, limit=body.limit)


@router.get("/statistics")
def statistics(
    service: ServiceDep,
    days: int = Query(30, ge=1, le=365),
    tz_offset_minutes: int = Query(0, ge=-720, le=840),
) -> dict[str, object]:
    """Library shape plus reading activity from ``reading_sessions``.

    ``tz_offset_minutes`` is the caller's fixed offset from UTC and decides
    where a day starts for the daily buckets, the hour histogram and the
    streak; the server stores naive UTC and will not guess. The value is
    echoed back under ``range`` so a chart can label its axis with the same
    definition it was bucketed by. Range is UTC-12:00 to UTC+14:00.
    """
    return service.statistics(days=days, tz_offset_minutes=tz_offset_minutes)


@router.post(
    "/statistics/milestones/{days}/seen",
    status_code=204,
    dependencies=[Depends(require_profile_context)],
)
def milestone_seen(days: int, service: ServiceDep) -> Response:
    """Record that this profile has seen a streak milestone card (idempotent)."""
    service.mark_milestone_seen(days)
    return Response(status_code=204)


@router.get("/annual")
def annual(
    service: ServiceDep,
    year: int | None = Query(None, ge=2000, le=2100),
    tz_offset_minutes: int = Query(..., ge=-720, le=840),
) -> dict[str, object]:
    """The year in reading (The Annual / Wrapped); cached per profile per day."""
    return service.annual(year, tz_offset_minutes)


@router.get("/search")
def search(
    service: ServiceDep,
    db: DbDep,
    q: str = Query(..., min_length=1),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=200),
) -> dict[str, object]:
    """Search over the profile's followed series (title LIKE)."""
    result = service.search(q, page=page, per_page=per_page)
    attach_cover_colours(db, result["items"])
    return result


# ---------------------------------------------------------------------------
# Collections
# ---------------------------------------------------------------------------


@router.get("/collections")
def list_collections(service: ServiceDep, response: Response) -> list[dict[str, object]]:
    items = service.list_collections()
    set_list_total_header(response, len(items))
    return items


@router.post("/collections", dependencies=[Depends(require_profile_context)])
def create_collection(
    body: CollectionCreateRequest, service: ServiceDep
) -> dict[str, object]:
    return service.create_collection(
        name=body.name,
        description=body.description,
        rules=body.rules.model_dump() if body.rules is not None else None,
    )


@router.get("/collections/{collection_id}")
def get_collection(collection_id: int, service: ServiceDep) -> dict[str, object]:
    return service.get_collection(collection_id)


@router.patch(
    "/collections/{collection_id}",
    dependencies=[Depends(require_profile_context)],
)
def update_collection(
    collection_id: int, body: CollectionUpdateRequest, service: ServiceDep
) -> dict[str, object]:
    return service.update_collection(
        collection_id, **body.model_dump(exclude_unset=True)
    )


@router.delete(
    "/collections/{collection_id}",
    status_code=204,
    dependencies=[Depends(require_profile_context)],
)
def delete_collection(collection_id: int, service: ServiceDep) -> None:
    service.delete_collection(collection_id)


@router.post(
    "/collections/{collection_id}/series",
    dependencies=[Depends(require_profile_context)],
)
def add_series_to_collection(
    collection_id: int, body: CollectionSeriesRequest, service: ServiceDep
) -> dict[str, object]:
    return service.add_series_to_collection(
        collection_id, body.source_id, body.series_key
    )


@router.put(
    "/collections/{collection_id}/series/order",
    status_code=204,
    dependencies=[Depends(require_profile_context)],
)
def reorder_collection(
    collection_id: int, body: CollectionOrderRequest, service: ServiceDep
) -> None:
    """The full ordered list of the members this profile can see."""
    service.reorder_collection(
        collection_id, [(i.source_id, i.series_key) for i in body.items]
    )


@router.delete(
    "/collections/{collection_id}/series",
    status_code=204,
    dependencies=[Depends(require_profile_context)],
)
def remove_series_from_collection(
    collection_id: int, body: CollectionSeriesRequest, service: ServiceDep
) -> None:
    service.remove_series_from_collection(
        collection_id, body.source_id, body.series_key
    )


# ---------------------------------------------------------------------------
# Tags
# ---------------------------------------------------------------------------


@router.get("/tags")
def list_tags(
    service: ServiceDep, response: Response, category: str | None = None
) -> list[dict[str, object]]:
    items = service.list_tags(category=category)
    set_list_total_header(response, len(items))
    return items


@router.post("/tags", dependencies=[Depends(require_profile_context)])
def create_tag(body: TagCreateRequest, service: ServiceDep) -> dict[str, object]:
    return service.create_tag(
        name=body.name, category=body.category, color=body.color
    )


@router.patch("/tags/{tag_id}", dependencies=[Depends(require_profile_context)])
def update_tag(
    tag_id: int, body: TagPatchRequest, service: ServiceDep
) -> dict[str, object]:
    """Rename and/or recolour; ``"color": null`` clears the colour."""
    return service.update_tag(tag_id, **body.model_dump(exclude_unset=True))


@router.delete(
    "/tags/{tag_id}",
    status_code=204,
    dependencies=[Depends(require_profile_context)],
)
def delete_tag(tag_id: int, service: ServiceDep) -> None:
    service.delete_tag(tag_id)


@router.post("/series-tags", dependencies=[Depends(require_profile_context)])
def add_tag_to_series(
    body: SeriesTagRequest, service: ServiceDep
) -> dict[str, object]:
    return service.add_tag_to_series(body.source_id, body.series_key, body.tag_id)


@router.delete(
    "/series-tags",
    status_code=204,
    dependencies=[Depends(require_profile_context)],
)
def remove_tag_from_series(
    body: SeriesTagRequest, service: ServiceDep
) -> None:
    service.remove_tag_from_series(body.source_id, body.series_key, body.tag_id)
