"""A profile's verdicts on AI picks, read where they take effect.

``ai_feedback`` is owned data (not a cache). Every surface that offers a pick
(``/home``, ``/ai/similar``, world recommendations, the onboarding seeds) drops
the ``not_interested`` targets through :func:`not_interested`; the taste block
of the AI prompts names the ``liked_pick`` titles through :func:`liked_titles`.
"""

from __future__ import annotations

import json

from sqlalchemy import select
from sqlalchemy.orm import Session

from database.models import AiFeedback, FollowedSeries, SourceSeriesCache, WorldCatalogCache


def _scope(stmt, user_id: int | None, profile_id: int | None, signal: str):
    return stmt.where(
        AiFeedback.user_id == user_id,
        AiFeedback.profile_id == profile_id,
        AiFeedback.signal == signal,
    )


def not_interested(
    db: Session, user_id: int | None, profile_id: int | None
) -> tuple[set[tuple[str, str]], set[int]]:
    """``(source pairs, anilist ids)`` this profile does not want offered."""
    if user_id is None or profile_id is None:
        return set(), set()
    pairs: set[tuple[str, str]] = set()
    ids: set[int] = set()
    rows = db.execute(
        _scope(
            select(AiFeedback.source_id, AiFeedback.series_key, AiFeedback.anilist_id),
            user_id,
            profile_id,
            "not_interested",
        )
    ).all()
    for source_id, series_key, anilist_id in rows:
        if source_id and series_key:
            pairs.add((source_id, series_key))
        if anilist_id is not None:
            ids.add(int(anilist_id))
    return pairs, ids


def anilist_title(db: Session, anilist_id: int) -> str | None:
    """A cached AniList title for ``anilist_id`` (search or recs payloads)."""
    like = f'%"id": {int(anilist_id)}, "title": %'
    payload = db.execute(
        select(WorldCatalogCache.payload)
        .where(WorldCatalogCache.payload.like(like))
        .limit(1)
    ).scalar_one_or_none()
    if payload is None:
        return None
    marker = f'"id": {int(anilist_id)}, "title": '
    try:
        text = payload[payload.index(marker) + len(marker) :]
        title, _ = json.JSONDecoder().raw_decode(text)
    except ValueError:
        return None
    if not isinstance(title, dict):
        return None
    return title.get("english") or title.get("romaji") or title.get("native")


def liked_titles(
    db: Session, user_id: int | None, profile_id: int | None, *, limit: int = 12
) -> list[str]:
    """Titles of this profile's liked picks, newest first (titles only)."""
    if user_id is None or profile_id is None:
        return []
    rows = db.execute(
        _scope(
            select(AiFeedback.source_id, AiFeedback.series_key, AiFeedback.anilist_id)
            .order_by(AiFeedback.id.desc()),
            user_id,
            profile_id,
            "liked_pick",
        )
    ).all()
    out: list[str] = []
    for source_id, series_key, anilist_id in rows:
        title = None
        if source_id and series_key:
            title = db.execute(
                select(FollowedSeries.title).where(
                    FollowedSeries.user_id == user_id,
                    FollowedSeries.profile_id == profile_id,
                    FollowedSeries.source_id == source_id,
                    FollowedSeries.series_key == series_key,
                )
            ).scalar_one_or_none() or db.execute(
                select(SourceSeriesCache.title).where(
                    SourceSeriesCache.source_id == source_id,
                    SourceSeriesCache.series_key == series_key,
                )
            ).scalar_one_or_none()
        elif anilist_id is not None:
            title = anilist_title(db, int(anilist_id))
        if title and title not in out:
            out.append(title)
        if len(out) >= limit:
            break
    return out
