"""The profile's taste, the onboarding catalogue and the sources-only seed wall.

Taste is the onboarding answers as JSON on ``reading_profiles.taste`` so it
follows the profile to every device. The catalogue is what steps 3 to 6 of both
skins' onboarding show; AniList supplies covers and seeds, the installed
connectors' declared genre lists supply the genre chips (no network call).
"""

from __future__ import annotations

import json
from collections import Counter
from typing import Annotated, Any, Literal
from urllib.parse import quote

from fastapi import Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from connectors.registry import _novels_enabled, list_installed_connectors
from core.connector_directory import descriptor_for_source
from core.content_rating import rating_from_genres
from core.errors import AppError
from database.models import (
    ReadingProfile,
    SourceBrowseCache,
    SourceSeriesCache,
)
from database.session import get_db
from services import ai_feedback
from services.browse_service import BrowseService, get_browse_service, series_identity
from services.followed_series_service import (
    FollowedSeriesService,
    _loads,
    get_followed_series_service,
)
from services.profile_service import _onboarding_out
from services.source_pin_service import SourcePinService, get_source_pin_service
from services.suggestion_service import SuggestionService, get_suggestion_service
from services.world_recs import ANILIST_GENRES, WorldRecs, get_world_recs

Format = Literal["manhwa", "manga", "manhua", "novel"]
Style = Literal[
    "painted", "cel", "screentone", "manhua-3d", "sketch", "retro", "pastel", "noir",
    "chibi", "watercolour", "dark-realism",
]
FORMATS = ("manhwa", "manga", "manhua", "novel")
STYLES = (
    "painted", "cel", "screentone", "manhua-3d", "sketch", "retro", "pastel", "noir",
    "chibi", "watercolour", "dark-realism",
)
WEIGHTS = (-1, 0, 1, 2)
MAX_GENRES = 80
MAX_SEEDS = 50
CATALOG_GENRES = 40
CATALOG_SEEDS = 24
SEED_ITEMS = 24


def _invalid(message: str) -> AppError:
    return AppError(message, code="taste_invalid", status_code=422)


# --- taste JSON ------------------------------------------------------------------


def read_taste(profile: ReadingProfile) -> dict[str, Any]:
    stored = _loads(profile.taste) if profile.taste else None
    stored = stored if isinstance(stored, dict) else {}
    return {
        "step": _onboarding_out(profile.onboarding_step),
        "formats": [f for f in stored.get("formats", []) if f in FORMATS],
        "genres": {
            str(k): int(v)
            for k, v in (stored.get("genres") or {}).items()
            if isinstance(v, int)
        },
        "styles": [s for s in stored.get("styles", []) if s in STYLES],
        "seeds": [s for s in stored.get("seeds", []) if isinstance(s, dict)],
    }


def write_taste(profile: ReadingProfile, patch: dict[str, Any]) -> dict[str, Any]:
    """Merge ``patch`` (only the fields the client sent) into the profile.

    Does not commit; returns the merged view."""
    current = read_taste(profile)
    if patch.get("step") is not None:
        profile.onboarding_step = str(patch["step"])
    if patch.get("formats") is not None:
        current["formats"] = list(dict.fromkeys(patch["formats"]))
    if patch.get("styles") is not None:
        current["styles"] = list(dict.fromkeys(patch["styles"]))
    if patch.get("seeds") is not None:
        current["seeds"] = list(patch["seeds"])
    if patch.get("genres") is not None:
        merged = dict(current["genres"])
        for name, weight in patch["genres"].items():
            if weight == 0:
                merged.pop(name, None)
            else:
                merged[name] = weight
        if len(merged) > MAX_GENRES:
            raise _invalid(f"At most {MAX_GENRES} genres can be weighted.")
        current["genres"] = merged
    profile.taste = json.dumps(
        {k: current[k] for k in ("formats", "genres", "styles", "seeds")}
    )
    current["step"] = _onboarding_out(profile.onboarding_step)
    return current


def taste_block(
    db: Session, user_id: int | None, profile_id: int | None
) -> dict[str, Any] | None:
    """What the AI prompts may say about this profile's stated taste.

    Names and titles only. ``None`` when the profile has said nothing."""
    profile = db.get(ReadingProfile, profile_id) if profile_id is not None else None
    if profile is None or profile.user_id != user_id:
        return None
    taste = read_taste(profile)
    genres = taste["genres"]
    block = {
        "formats": taste["formats"],
        "loved": [g for g, w in genres.items() if w == 2],
        "liked": [g for g, w in genres.items() if w == 1],
        "skipped": [g for g, w in genres.items() if w == -1],
        "styles": taste["styles"],
        "liked_picks": ai_feedback.liked_titles(db, user_id, profile_id),
    }
    return block if any(block.values()) else None


def taste_text(block: dict[str, Any]) -> str:
    """The labelled DATA block (titles and genre names only)."""
    lines = []
    if block["formats"]:
        lines.append("Formats: " + ", ".join(block["formats"]))
    if block["loved"]:
        lines.append("Loves: " + ", ".join(block["loved"]))
    if block["liked"]:
        lines.append("Likes: " + ", ".join(block["liked"]))
    if block["skipped"]:
        lines.append("Skips: " + ", ".join(block["skipped"]))
    if block["styles"]:
        lines.append("Art styles: " + ", ".join(block["styles"]))
    if block["liked_picks"]:
        lines.append("Picks this reader liked: " + "; ".join(block["liked_picks"]))
    return "\n".join(lines)


def taste_genres(db: Session, profile_id: int | None) -> list[dict[str, Any]]:
    """``[{genre, weight}]``: loved (2) first, then liked (1). Home's genres
    section for a profile with no follows."""
    profile = db.get(ReadingProfile, profile_id) if profile_id is not None else None
    if profile is None:
        return []
    genres = read_taste(profile)["genres"]
    ranked = sorted(
        ((g, w) for g, w in genres.items() if w in (1, 2)), key=lambda t: (-t[1], t[0])
    )
    return [{"genre": g, "weight": w} for g, w in ranked]


# --- catalogue -------------------------------------------------------------------


class TasteService:
    def __init__(
        self,
        db: Session,
        library: FollowedSeriesService,
        browse: BrowseService,
        world: WorldRecs,
        pins: SourcePinService,
        suggest: SuggestionService,
    ) -> None:
        self._db = db
        self._library = library
        self._browse = browse
        self._world = world
        self._pins = pins
        self._suggest = suggest

    # --- genres ----------------------------------------------------------------

    def _genre_labels(self, formats: list[str], gate_open: bool) -> list[dict[str, Any]]:
        novel_only = bool(formats) and set(formats) <= {"novel"}
        no_novel = bool(formats) and "novel" not in formats
        counts: Counter[str] = Counter()
        spellings: dict[str, Counter[str]] = {}
        for d in list_installed_connectors(browsable_only=True, include_mature=gate_open):
            if d.mature and not gate_open:
                continue
            if (novel_only and d.content_kind != "novel") or (
                no_novel and d.content_kind == "novel"
            ):
                continue
            try:
                labels = self._browse.list_genres(d.source_type)
            except Exception:  # noqa: BLE001 - a broken connector never blocks onboarding
                continue
            seen: set[str] = set()
            for g in labels:
                label = " ".join(str(g.get("label") or "").split())
                folded = label.casefold()
                if not label or folded in seen:
                    continue
                if not gate_open and rating_from_genres([label]):
                    continue
                seen.add(folded)
                counts[folded] += 1
                spellings.setdefault(folded, Counter())[label] += 1
        out = [
            {"name": spellings[k].most_common(1)[0][0], "weight": n}
            for k, n in counts.items()
        ]
        out.sort(key=lambda g: (-g["weight"], g["name"].casefold()))
        return out[:CATALOG_GENRES]

    # --- catalogue ---------------------------------------------------------------

    def catalog(
        self, formats: list[str], genres: list[str], styles: list[str]
    ) -> dict[str, Any]:
        """``styles`` is validated by the route and only reaches the AI through
        the taste block: AniList has no art-style facet."""
        self._library._require_owner()
        gate_open = bool(self._library._gate_open())
        wanted = [
            f for f in (formats or FORMATS) if f != "novel" or _novels_enabled()
        ]
        catalog = self._world.catalog
        covers = []
        pools: list[list[dict[str, Any]]] = []
        facet = {g.casefold(): g for g in ANILIST_GENRES}
        chosen = [facet[g.casefold()] for g in genres if g.casefold() in facet]
        for fmt in wanted:
            plain = catalog.trending(fmt, [], adult=False)
            covers.append(
                {
                    "format": fmt,
                    "covers": [
                        (m.get("coverImage") or {}).get("large")
                        for m in plain
                        if (m.get("coverImage") or {}).get("large")
                    ][:3],
                }
            )
            pools.append(
                catalog.trending(fmt, chosen, adult=gate_open) if chosen or gate_open else plain
            )
        seeds = self._seeds(pools, gate_open)
        return {
            "formats": covers,
            "genres": self._genre_labels(list(formats), gate_open),
            "seeds": seeds,
            "unavailable_reason": (
                "The worldwide catalogue could not be reached." if catalog.failed else None
            ),
        }

    def _seeds(self, pools: list[list[dict[str, Any]]], gate_open: bool) -> list[dict[str, Any]]:
        world = self._world
        _, excluded, preferred = world._context()
        pairs, ids = world.not_interested()
        merged: list[dict[str, Any]] = []
        seen: set[int] = set()
        depth = max((len(p) for p in pools), default=0)
        for rank in range(depth):
            for pool in pools:
                if rank >= len(pool):
                    continue
                media = pool[rank]
                if (
                    media["id"] in seen
                    or media["id"] in ids
                    or world._hidden(media, gate_open)
                    or world._is_excluded(media, excluded)
                ):
                    continue
                seen.add(media["id"])
                merged.append(media)
        merged = merged[: CATALOG_SEEDS * 2]
        index = world._availability_index(gate_open)
        items = world._items(
            [(m, None) for m in merged], gate_open=gate_open, index=index, preferred=preferred
        )
        items = [
            i
            for i in items
            if not any((a["source_id"], a["series_key"]) in pairs for a in i["available"])
            and (
                gate_open
                or not i["available"]
                or not all(
                    (descriptor_for_source(a["source_id"]) or _Safe).mature
                    for a in i["available"]
                )
            )
        ]
        items.sort(key=lambda i: not i["available"])  # stable: available first
        return items[:CATALOG_SEEDS]

    # --- sources-only seed wall -----------------------------------------------------

    def seed_from_sources(
        self, formats: list[str], genres: dict[str, int] | list[str], styles: list[str]
    ) -> dict[str, Any]:
        """Up to 24 cached series on this profile's sources; no network at all."""
        self._library._require_owner()
        kinds = self._kinds(formats)
        sources = self._sources(kinds)
        liked = {
            g.casefold()
            for g in (
                [g for g, w in genres.items() if w in (1, 2)]
                if isinstance(genres, dict)
                else genres
            )
        }
        excluded = self._suggest._excluded_keys() | self._world.not_interested()[0]
        cache = self._library._cache
        rows = self._db.execute(
            select(SourceSeriesCache)
            .where(SourceSeriesCache.source_id.in_(sources or [""]), SourceSeriesCache.title != "")
            .order_by(SourceSeriesCache.fetched_at.desc())
            .limit(3000)
        ).scalars()
        scored: list[tuple[int, Any, SourceSeriesCache]] = []
        for i, r in enumerate(rows):
            if (r.source_id, r.series_key) in excluded or cache._rating_hides(r):
                continue
            shared = len({str(g).strip().casefold() for g in _loads(r.genres) or []} & liked)
            scored.append((shared, i, r))
        scored.sort(key=lambda t: (-t[0], t[1]))  # i preserves newest-first
        items = [self._series_item(r) for _, _, r in scored[:SEED_ITEMS]]
        if len(items) < SEED_ITEMS:
            have = {(i["source_id"], i["id"]) for i in items}
            for source_id in sources:
                page = self._db.get(SourceBrowseCache, (source_id, "popular", "", 1))
                for it in (_loads(page.payload) or {}).get("items", []) if page else []:
                    pair = (it.get("source_id") or source_id, it.get("id"))
                    if (
                        pair in have
                        or pair in excluded
                        or len(items) >= SEED_ITEMS
                        or not it.get("id")
                    ):
                        continue
                    if not self._library._gate_open() and rating_from_genres(
                        [str(g) for g in it.get("genres") or []]
                    ):
                        continue
                    have.add(pair)
                    items.append(it)
        return {"items": items, "basis": "sources"}

    @staticmethod
    def _kinds(formats: list[str]) -> set[str]:
        if formats and set(formats) <= {"novel"}:
            return {"novel"}
        if formats and "novel" not in formats:
            return {"manga"}
        return {"manga", "novel"} if formats else {"manga"}

    def _sources(self, kinds: set[str]) -> list[str]:
        pins = [
            str(p["source_id"])
            for p in self._pins.list_pins()
            if (descriptor_for_source(str(p["source_id"])) or _Safe).content_kind in kinds
        ]
        if pins:
            return pins
        # ponytail: health is not consulted here; the home fallback's ranking
        # is reused by name only when the health table has rows.
        from services.source_health import load_states

        states = load_states(self._db)
        ok = []
        for d in list_installed_connectors(browsable_only=True, include_mature=False):
            state = states.get(d.source_type)
            if d.mature or d.content_kind not in kinds or state is None or state.status != "ok":
                continue
            ok.append((state.consecutive_failures, d.name.casefold(), d.source_type))
        return [sid for _, _, sid in sorted(ok)][:3]

    @staticmethod
    def _series_item(r: SourceSeriesCache) -> dict[str, Any]:
        chapters = _loads(r.chapters) or []
        return {
            "id": r.series_key,
            "source_id": r.source_id,
            "series_identity": series_identity(r.source_id, r.series_key),
            "title": r.title,
            "cover_url": f"/sources/{r.source_id}/series/{quote(r.series_key, safe='')}/cover",
            "chapter_count": len(chapters) if isinstance(chapters, list) else 0,
            "genres": [str(g) for g in _loads(r.genres) or []],
            "status": r.status,
            "description": r.description,
            "author": r.author,
            "artist": r.artist,
            "content_rating": r.content_rating,
            "latest_chapter": None,
        }


class _Safe:
    mature = False
    content_kind = None


def get_taste_service(
    db: Annotated[Session, Depends(get_db)],
    library: Annotated[FollowedSeriesService, Depends(get_followed_series_service)],
    browse: Annotated[BrowseService, Depends(get_browse_service)],
    world: Annotated[WorldRecs, Depends(get_world_recs)],
    pins: Annotated[SourcePinService, Depends(get_source_pin_service)],
    suggest: Annotated[SuggestionService, Depends(get_suggestion_service)],
) -> TasteService:
    return TasteService(db, library, browse, world, pins, suggest)
