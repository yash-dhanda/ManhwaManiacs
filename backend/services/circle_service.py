"""The Circle: sharing switches, the activity record and the one shareable-set rule.

``S(member, viewer)`` (:meth:`CircleService._events`, :meth:`_passes`) is the
only place that decides what one profile may see of another. Every endpoint,
the ``/home`` sections and the Annual block call it; nothing else re-implements
any part of it (``backend/09`` builds on it too).

An event or a live reading position of member M is in S when M is a member
(active account, ``share_activity`` on, not the viewer), its timestamp is at or
after ``share_activity_since``, the series is not in M's hidden list, a
``reacted`` event needs ``share_reactions``, and a mature series needs M's
effective ``include_mature`` AND the viewer's open 18+ gate. A failing mature
item is absent: no placeholder, no count. The gate applies when SERVING, never
when storing.
"""

from __future__ import annotations

import json
from collections import defaultdict
from datetime import datetime, timedelta
from typing import Annotated, Any, Iterator

from fastapi import Depends
from sqlalchemy import and_, delete, exists, func, or_, select, tuple_
from sqlalchemy.orm import Session

from connectors.ids import fully_unquote
from core.connector_directory import descriptor_for_source, is_mature_source
from core.content_rating import (
    TRACKER_RATING_MATURE,
    resolve_mature_gate,
    resolve_series_rating,
    resolve_tracker_rating,
)
from core.errors import AppError
from core.profile_context import ProfileContext, require_profile_context
from core.time_utils import utcnow
from database.models import (
    ChapterProgress,
    CircleEvent,
    CircleHiddenSeries,
    FollowedSeries,
    ReadingProfile,
    ReadingSession,
    SourceSeriesCache,
    User,
)
from database.session import get_db
from services.cover_colour import attach_cover_colours

#: §15.10 owner call: a viewer that shares nothing still sees sharers. Flip to
#: True and every ``/circle/*`` read answers as if there were no members.
CIRCLE_REQUIRES_VIEWER_SHARING = False

PRESENCE_WINDOW = timedelta(minutes=15)
READING_KINDS = ("started", "finished_chapter", "finished_series")
_CHUNK = 200
_EPOCH = datetime(1970, 1, 1)

SHARING_FIELDS = {  # API field -> column
    "activity": "share_activity",
    "reactions": "share_reactions",
    "shelves": "share_shelves",
    "recommendations": "share_recommendations",
    "include_mature": "share_include_mature",
    "show_presence": "share_presence",
    "share_streak": "share_streak",
}


def _iso(value: datetime | None) -> str | None:
    return value.isoformat() if value else None


def _cursor_of(event: CircleEvent) -> str:
    return f"{event.created_at:%Y%m%d%H%M%S%f}-{event.id}"


def _parse_cursor(raw: str) -> tuple[datetime, int]:
    try:
        stamp, ident = raw.rsplit("-", 1)
        return datetime.strptime(stamp, "%Y%m%d%H%M%S%f"), int(ident)
    except (ValueError, TypeError):
        raise AppError("Malformed cursor.", code="invalid_cursor", status_code=422)


def _kind_of(source_id: str) -> str:
    descriptor = descriptor_for_source(source_id)
    return "novel" if descriptor and descriptor.content_kind == "novel" else "manga"


# ---------------------------------------------------------------------------
# Sharing switches (per owned profile; no viewer needed)
# ---------------------------------------------------------------------------


def read_sharing(db: Session, profile: ReadingProfile) -> dict[str, Any]:
    out: dict[str, Any] = {
        api: bool(getattr(profile, col)) for api, col in SHARING_FIELDS.items()
    }
    rows = db.execute(
        select(CircleHiddenSeries)
        .where(CircleHiddenSeries.profile_id == profile.id)
        .order_by(CircleHiddenSeries.created_at.desc(), CircleHiddenSeries.series_key)
    ).scalars()
    out["excluded_series"] = [
        {"source_id": r.source_id, "series_key": r.series_key, "title": r.title}
        for r in rows
    ]
    return out


def _title_for(db: Session, profile: ReadingProfile, source_id: str, series_key: str) -> str:
    title = db.execute(
        select(FollowedSeries.title).where(
            FollowedSeries.profile_id == profile.id,
            FollowedSeries.source_id == source_id,
            FollowedSeries.series_key == series_key,
        )
    ).scalar_one_or_none()
    if not title:
        title = db.execute(
            select(SourceSeriesCache.title).where(
                SourceSeriesCache.source_id == source_id,
                SourceSeriesCache.series_key == series_key,
            )
        ).scalar_one_or_none()
    return title or series_key


def patch_sharing(
    db: Session, profile: ReadingProfile, changes: dict[str, Any]
) -> dict[str, Any]:
    for api, col in SHARING_FIELDS.items():
        if changes.get(api) is None:
            continue
        value = bool(changes[api])
        if api == "activity" and value != bool(profile.share_activity):
            profile.share_activity_since = utcnow() if value else None
        setattr(profile, col, value)
    if changes.get("excluded_series") is not None:
        db.execute(
            delete(CircleHiddenSeries).where(CircleHiddenSeries.profile_id == profile.id)
        )
        seen: set[tuple[str, str]] = set()
        for entry in changes["excluded_series"]:
            source_id = entry["source_id"]
            series_key = fully_unquote(entry["series_key"])
            if (source_id, series_key) in seen:
                continue
            seen.add((source_id, series_key))
            db.add(
                CircleHiddenSeries(
                    user_id=profile.user_id,
                    profile_id=profile.id,
                    source_id=source_id,
                    series_key=series_key,
                    title=entry.get("title")
                    or _title_for(db, profile, source_id, series_key),
                    created_at=utcnow(),
                )
            )
    db.commit()
    return read_sharing(db, profile)


# ---------------------------------------------------------------------------
# Recording (inside the caller's transaction, no commit)
# ---------------------------------------------------------------------------


def record_event(
    db: Session,
    *,
    user_id: int,
    profile_id: int,
    kind: str,
    source_id: str,
    series_key: str,
    at: datetime,
    chapter_key: str | None = None,
    chapter_number: float | None = None,
) -> None:
    """Add a ``circle_events`` row iff the actor shares and ``at`` is not
    before ``share_activity_since``. The 18+ rating is not checked here."""
    profile = db.get(ReadingProfile, profile_id)
    if profile is None or not profile.share_activity:
        return
    if profile.share_activity_since and at < profile.share_activity_since:
        return
    title = cover = None
    follow = db.execute(
        select(FollowedSeries.title, FollowedSeries.cover_url).where(
            FollowedSeries.profile_id == profile_id,
            FollowedSeries.source_id == source_id,
            FollowedSeries.series_key == series_key,
        )
    ).first()
    if follow:
        title, cover = follow
    else:
        cache = db.execute(
            select(SourceSeriesCache.title, SourceSeriesCache.cover_url).where(
                SourceSeriesCache.source_id == source_id,
                SourceSeriesCache.series_key == series_key,
            )
        ).first()
        if cache:
            title, cover = cache
    db.add(
        CircleEvent(
            user_id=user_id,
            profile_id=profile_id,
            kind=kind,
            source_id=source_id,
            series_key=series_key,
            chapter_key=chapter_key,
            chapter_number=chapter_number,
            title=title or series_key,
            cover_url=cover,
            created_at=at,
        )
    )


# ---------------------------------------------------------------------------
# The viewer-scoped service
# ---------------------------------------------------------------------------


class CircleService:
    def __init__(self, db: Session, user_id: int, profile_id: int) -> None:
        self._db = db
        self.user_id = user_id
        self.profile_id = profile_id
        self._gate: bool | None = None
        self._members_cache: dict[int, tuple[ReadingProfile, str]] | None = None
        self._hidden_cache: set[tuple[int, str, str]] | None = None
        self._mature_memo: dict[tuple[int, str, str], bool] = {}
        self._viewer_follow_memo: dict[tuple[str, str], FollowedSeries | None] = {}

    # --- members ---------------------------------------------------------

    def _viewer_gate(self) -> bool:
        if self._gate is None:
            self._gate = bool(
                resolve_mature_gate(self._db, self.profile_id, self.user_id)
            )
        return self._gate

    def _viewer_shares(self) -> bool:
        return bool(self._db.get(ReadingProfile, self.profile_id).share_activity)

    def members(self) -> dict[int, tuple[ReadingProfile, str]]:
        """Rule 1: profile id -> (profile, username), evaluated now."""
        if self._members_cache is None:
            self._members_cache = {}
            if not CIRCLE_REQUIRES_VIEWER_SHARING or self._viewer_shares():
                rows = self._db.execute(
                    select(ReadingProfile, User.username)
                    .join(User, User.id == ReadingProfile.user_id)
                    .where(
                        User.is_active == 1,
                        ReadingProfile.share_activity == 1,
                        ReadingProfile.id != self.profile_id,
                    )
                ).all()
                self._members_cache = {p.id: (p, u) for p, u in rows}
        return self._members_cache

    def _hidden(self) -> set[tuple[int, str, str]]:
        if self._hidden_cache is None:
            ids = list(self.members())
            self._hidden_cache = set()
            if ids:
                self._hidden_cache = {
                    tuple(r)
                    for r in self._db.execute(
                        select(
                            CircleHiddenSeries.profile_id,
                            CircleHiddenSeries.source_id,
                            CircleHiddenSeries.series_key,
                        ).where(CircleHiddenSeries.profile_id.in_(ids))
                    ).all()
                }
        return self._hidden_cache

    def profile_ref(self, member_id: int) -> dict[str, Any]:
        profile, username = self.members()[member_id]
        return {
            "profile_id": profile.id,
            "name": profile.name,
            "avatar_key": profile.avatar_key,
            "username": username,
        }

    @staticmethod
    def shares_of(profile: ReadingProfile) -> dict[str, bool]:
        return {
            "activity": bool(profile.share_activity),
            "reactions": bool(profile.share_reactions),
            "shelves": bool(profile.share_shelves),
            "recommendations": bool(profile.share_recommendations),
        }

    # --- the S rule ------------------------------------------------------

    def series_mature(self, member_id: int, source_id: str, series_key: str) -> bool:
        key = (member_id, source_id, series_key)
        if key in self._mature_memo:
            return self._mature_memo[key]
        descriptor = descriptor_for_source(source_id)
        follow = self._db.execute(
            select(FollowedSeries).where(
                FollowedSeries.profile_id == member_id,
                FollowedSeries.source_id == source_id,
                FollowedSeries.series_key == series_key,
            )
        ).scalar_one_or_none()
        if follow is not None:
            rating = resolve_tracker_rating(follow, descriptor)
        else:
            cache = self._db.get(SourceSeriesCache, (source_id, series_key))
            if cache is not None:
                try:
                    genres = json.loads(cache.genres) if cache.genres else None
                except ValueError:
                    genres = None
                rating = resolve_series_rating(
                    cache.content_rating,
                    [str(g) for g in genres] if isinstance(genres, list) else None,
                    source_mature=is_mature_source(source_id),
                )
            else:
                rating = (
                    TRACKER_RATING_MATURE if is_mature_source(source_id) else "unknown"
                )
        mature = rating == TRACKER_RATING_MATURE
        if not mature:
            pair = (source_id, series_key)
            if pair not in self._viewer_follow_memo:
                self._viewer_follow_memo[pair] = self._db.execute(
                    select(FollowedSeries).where(
                        FollowedSeries.profile_id == self.profile_id,
                        FollowedSeries.source_id == source_id,
                        FollowedSeries.series_key == series_key,
                    )
                ).scalar_one_or_none()
            mine = self._viewer_follow_memo[pair]
            mature = (
                mine is not None
                and resolve_tracker_rating(mine, descriptor) == TRACKER_RATING_MATURE
            )
        self._mature_memo[key] = mature
        return mature

    def _mature_ok(self, member_id: int, source_id: str, series_key: str) -> bool:
        """Rule 5."""
        if not self.series_mature(member_id, source_id, series_key):
            return True
        profile = self.members()[member_id][0]
        return bool(
            profile.share_include_mature
            and profile.mature_content_enabled
            and self._viewer_gate()
        )

    def passes(
        self,
        member_id: int,
        source_id: str,
        series_key: str,
        at: datetime,
        kind: str | None = None,
    ) -> bool:
        """Rules 2-5 for one item of a member (rule 1 = membership)."""
        member = self.members().get(member_id)
        if member is None:
            return False
        profile = member[0]
        if at < (profile.share_activity_since or _EPOCH):
            return False
        if (member_id, source_id, series_key) in self._hidden():
            return False
        if kind == "reacted" and not profile.share_reactions:
            return False
        return self._mature_ok(member_id, source_id, series_key)

    def _events(
        self,
        kinds: tuple[str, ...] | None = None,
        *,
        member_id: int | None = None,
        cursor: tuple[datetime, int] | None = None,
        since: datetime | None = None,
    ) -> Iterator[CircleEvent]:
        """S events newest first. SQL prefilter for rules 1-4, then rule 5.

        ponytail: Python-side 18+ filter, fine for a 2-3 user server; move it
        into SQL with aliased followed_series joins if the feed ever exceeds
        50 ms.
        """
        ids = [member_id] if member_id is not None else list(self.members())
        ids = [i for i in ids if i in self.members()]
        if not ids:
            return
        hidden = (
            select(1)
            .select_from(CircleHiddenSeries)
            .where(
                CircleHiddenSeries.profile_id == CircleEvent.profile_id,
                CircleHiddenSeries.source_id == CircleEvent.source_id,
                CircleHiddenSeries.series_key == CircleEvent.series_key,
            )
        )
        while True:
            stmt = (
                select(CircleEvent)
                .join(ReadingProfile, ReadingProfile.id == CircleEvent.profile_id)
                .where(
                    CircleEvent.profile_id.in_(ids),
                    CircleEvent.created_at
                    >= func.coalesce(ReadingProfile.share_activity_since, _EPOCH),
                    ~exists(hidden),
                    or_(
                        CircleEvent.kind != "reacted",
                        ReadingProfile.share_reactions == 1,
                    ),
                )
                .order_by(CircleEvent.created_at.desc(), CircleEvent.id.desc())
                .limit(_CHUNK)
            )
            if kinds:
                stmt = stmt.where(CircleEvent.kind.in_(kinds))
            if since is not None:
                stmt = stmt.where(CircleEvent.created_at >= since)
            if cursor is not None:
                stmt = stmt.where(
                    tuple_(CircleEvent.created_at, CircleEvent.id)
                    < tuple_(cursor[0], cursor[1])
                )
            rows = self._db.execute(stmt).scalars().all()
            for ev in rows:
                if self._mature_ok(ev.profile_id, ev.source_id, ev.series_key):
                    yield ev
            if len(rows) < _CHUNK:
                return
            cursor = (rows[-1].created_at, rows[-1].id)

    # --- shapes ----------------------------------------------------------

    @staticmethod
    def series_shape(
        source_id: str, series_key: str, title: str, cover_url: str | None
    ) -> dict[str, Any]:
        return {
            "source_id": source_id,
            "series_key": series_key,
            "title": title,
            "cover_url": cover_url,
            "ambient": None,
            "palette": None,
            "content_kind": _kind_of(source_id),
        }

    def _colour(self, items: list[dict[str, Any]]) -> None:
        attach_cover_colours(
            self._db, items, key=lambda i: (i["source_id"], i["series_key"])
        )

    # --- presence --------------------------------------------------------

    def _presence(
        self, member_id: int, tz_offset_minutes: int
    ) -> tuple[dict | None, str | None, dict | None]:
        profile = self.members()[member_id][0]
        rows = self._db.execute(
            select(ChapterProgress)
            .where(ChapterProgress.profile_id == member_id)
            .order_by(ChapterProgress.last_read_at.desc(), ChapterProgress.id.desc())
            .limit(50)
        ).scalars().all()
        ok = [
            r
            for r in rows
            if self.passes(member_id, r.source_id, r.series_key, r.last_read_at)
        ]
        last_active = _iso(ok[0].last_read_at) if ok else None
        now = None
        if (
            profile.share_presence
            and rows
            and rows[0] is (ok[0] if ok else None)
            and utcnow() - rows[0].last_read_at <= PRESENCE_WINDOW
        ):
            r = rows[0]
            title = _title_for(self._db, profile, r.source_id, r.series_key)
            now = {
                "source_id": r.source_id,
                "series_key": r.series_key,
                "chapter_key": r.chapter_key,
                "chapter_number": r.chapter_number,
                "title": title,
                "ambient": None,
                "palette": None,
                "since": _iso(r.last_read_at),
            }
        streak = None
        if profile.share_streak:
            from services.reading_stats_service import ReadingStatsService

            stats = ReadingStatsService(
                self._db,
                user_id=profile.user_id,
                profile_id=member_id,
                gate_open=True,
                tz_offset_minutes=tz_offset_minutes,
            )
            info = stats._streak(stats._active_days())
            today = stats._local_now().date().isoformat()
            streak = {
                "current_days": info["current_days"],
                "alive_today": info["last_active_date"] == today,
            }
        return now, last_active, streak

    def members_list(self, tz_offset_minutes: int = 0) -> list[dict[str, Any]]:
        out = []
        for member_id, (profile, _u) in self.members().items():
            now, last_active, streak = self._presence(member_id, tz_offset_minutes)
            out.append(
                {
                    **self.profile_ref(member_id),
                    "shares": self.shares_of(profile),
                    "now": now,
                    "last_active_at": last_active,
                    "streak": streak,
                }
            )
        self._colour([o["now"] for o in out if o["now"]])
        # nulls last, then name: name first, then a stable reverse sort on the stamp
        out.sort(key=lambda o: o["name"])
        out.sort(key=lambda o: o["last_active_at"] or "", reverse=True)
        return out

    def member_page(self, member_id: int, tz_offset_minutes: int = 0) -> dict[str, Any]:
        if member_id not in self.members():
            raise AppError(
                "This profile isn't sharing with you.",
                code="circle_member_not_sharing",
                status_code=404,
            )
        profile = self.members()[member_id][0]
        now, last_active, streak = self._presence(member_id, tz_offset_minutes)
        newest: dict[tuple[str, str], CircleEvent] = {}  # newest of the 3 kinds
        finished: dict[tuple[str, str], CircleEvent] = {}
        reacted: list[CircleEvent] = []
        for ev in self._events(member_id=member_id):
            pair = (ev.source_id, ev.series_key)
            if ev.kind == "reacted":
                if len(reacted) < 30:
                    reacted.append(ev)
                continue
            newest.setdefault(pair, ev)
            if ev.kind == "finished_series":
                finished.setdefault(pair, ev)

        def shape(ev: CircleEvent, **extra: Any) -> dict[str, Any]:
            return {
                **self.series_shape(ev.source_id, ev.series_key, ev.title, ev.cover_url),
                **extra,
            }

        reading = [
            shape(ev, last_activity_at=_iso(ev.created_at))
            for ev in newest.values()
            if ev.kind != "finished_series"
        ]
        done = [shape(ev, finished_at=_iso(ev.created_at)) for ev in finished.values()]
        done.sort(key=lambda d: d["finished_at"], reverse=True)
        reactions = [
            shape(
                ev,
                chapter_key=ev.chapter_key,
                chapter_number=ev.chapter_number,
                reaction=ev.reaction,
                created_at=_iso(ev.created_at),
            )
            for ev in reacted
        ]
        for group in (reading, done, reactions):
            self._colour(group)
        self._colour([now] if now else [])
        return {
            "profile": self.profile_ref(member_id),
            "shares": self.shares_of(profile),
            "now": now,
            "last_active_at": last_active,
            "streak": streak,
            "reading": reading,
            "finished": done,
            "reactions": reactions,
            "shelves": [],
        }

    # --- feed ------------------------------------------------------------

    def feed(
        self,
        *,
        cursor: str | None,
        limit: int,
        profile_id: int | None,
        kind: str | None,
    ) -> dict[str, Any]:
        parsed = _parse_cursor(cursor) if cursor else None
        if profile_id is not None and profile_id not in self.members():
            return {"items": [], "next_cursor": None}
        kinds = {"reading": READING_KINDS, "reaction": ("reacted",)}.get(kind or "")
        kept: list[CircleEvent] = []
        for ev in self._events(kinds, member_id=profile_id, cursor=parsed):
            kept.append(ev)
            if len(kept) > limit:
                break
        page = kept[:limit]
        followed: set[tuple[str, str]] = set()
        if page:
            followed = {
                tuple(r)
                for r in self._db.execute(
                    select(FollowedSeries.source_id, FollowedSeries.series_key).where(
                        FollowedSeries.profile_id == self.profile_id,
                        tuple_(FollowedSeries.source_id, FollowedSeries.series_key).in_(
                            {(e.source_id, e.series_key) for e in page}
                        ),
                    )
                ).all()
            }
        items = [
            {
                "id": ev.id,
                "kind": ev.kind,
                "actor": self.profile_ref(ev.profile_id),
                **self.series_shape(ev.source_id, ev.series_key, ev.title, ev.cover_url),
                "chapter_key": ev.chapter_key,
                "chapter_number": ev.chapter_number,
                "reaction": ev.reaction,
                "followed_by_viewer": (ev.source_id, ev.series_key) in followed,
                "created_at": _iso(ev.created_at),
            }
            for ev in page
        ]
        self._colour(items)
        return {
            "items": items,
            "next_cursor": _cursor_of(page[-1]) if len(kept) > limit else None,
        }

    # --- one series ------------------------------------------------------

    def series(self, source_id: str, series_key: str) -> dict[str, Any]:
        series_key = fully_unquote(series_key)
        members = self.members()
        followers: list[dict[str, Any]] = []
        readers: list[dict[str, Any]] = []
        if members:
            rows = self._db.execute(
                select(FollowedSeries.profile_id, FollowedSeries.created_at)
                .where(
                    FollowedSeries.profile_id.in_(list(members)),
                    FollowedSeries.source_id == source_id,
                    FollowedSeries.series_key == series_key,
                )
                .order_by(FollowedSeries.created_at.desc())
            ).all()
            followers = [
                self.profile_ref(pid)
                for pid, at in rows
                if self.passes(pid, source_id, series_key, at)
            ]
            latest: dict[int, ChapterProgress] = {}
            for r in self._db.execute(
                select(ChapterProgress)
                .where(
                    ChapterProgress.profile_id.in_(list(members)),
                    ChapterProgress.source_id == source_id,
                    ChapterProgress.series_key == series_key,
                )
                .order_by(ChapterProgress.last_read_at.desc(), ChapterProgress.id.desc())
            ).scalars():
                latest.setdefault(r.profile_id, r)
            readers = [
                {
                    "profile": self.profile_ref(pid),
                    "chapter_key": r.chapter_key,
                    "chapter_number": r.chapter_number,
                    "last_read_at": _iso(r.last_read_at),
                }
                for pid, r in latest.items()
                if self.passes(pid, source_id, series_key, r.last_read_at)
            ]
            readers.sort(key=lambda r: r["last_read_at"], reverse=True)
        return {"followers": followers, "readers": readers}

    # --- clear -----------------------------------------------------------

    def clear_activity(self) -> None:
        self._db.execute(
            delete(CircleEvent).where(CircleEvent.profile_id == self.profile_id)
        )
        me = self._db.get(ReadingProfile, self.profile_id)
        if me.share_activity:
            me.share_activity_since = utcnow()
        self._db.commit()

    # --- /home sections --------------------------------------------------

    def home_sections(self, content_kind: str, generated_at: str) -> list[dict[str, Any]]:
        def of_kind(ev: CircleEvent) -> bool:
            descriptor = descriptor_for_source(ev.source_id)
            return descriptor is not None and descriptor.content_kind == content_kind

        now = utcnow()
        recent: list[CircleEvent] = []
        seen: set[tuple[int, str, str]] = set()
        for ev in self._events(READING_KINDS, since=now - timedelta(days=14)):
            if not of_kind(ev):
                continue
            key = (ev.profile_id, ev.source_id, ev.series_key)
            if key in seen:
                continue
            seen.add(key)
            recent.append(ev)
            if len(recent) == 20:
                break

        groups: dict[tuple[str, str], list[CircleEvent]] = defaultdict(list)
        for ev in self._events(READING_KINDS, since=now - timedelta(days=7)):
            if of_kind(ev):
                groups[(ev.source_id, ev.series_key)].append(ev)
        ranked = sorted(
            groups.values(),
            key=lambda evs: (
                len({e.profile_id for e in evs}),
                len(evs),
                evs[0].created_at,
                evs[0].id,
            ),
            reverse=True,
        )[:10]

        def item(ev: CircleEvent, **extra: Any) -> dict[str, Any]:
            return {
                "member": self.profile_ref(ev.profile_id),
                "series": self.series_shape(
                    ev.source_id, ev.series_key, ev.title, ev.cover_url
                ),
                **extra,
            }

        circle = [item(ev) for ev in recent]
        top = [item(evs[0], rank=i) for i, evs in enumerate(ranked, 1)]
        self._colour([i["series"] for i in circle + top])
        return [
            {
                "type": kind,
                "title": title,
                "seed": None,
                "note": None,
                "fallback": None,
                "items": items,
                "state": "ready" if items else "empty",
                "generated_at": generated_at,
            }
            for kind, title, items in (
                ("circle", "From the Circle", circle),
                ("circle_top", "Most read in the circle", top),
            )
        ]

    # --- The Annual ------------------------------------------------------

    def annual_block(
        self, since: datetime, until: datetime
    ) -> dict[str, Any] | None:
        if not self._viewer_shares():
            return None
        seconds = {
            (r.source_id, r.series_key): int(r.secs or 0)
            for r in self._db.execute(
                select(
                    ReadingSession.source_id,
                    ReadingSession.series_key,
                    func.sum(ReadingSession.duration_seconds).label("secs"),
                )
                .where(
                    ReadingSession.profile_id == self.profile_id,
                    ReadingSession.started_at >= since,
                    ReadingSession.started_at < until,
                )
                .group_by(ReadingSession.source_id, ReadingSession.series_key)
            ).all()
        }
        if not seconds:
            return {"overlaps": [], "with": []}
        completed = {
            (r.source_id, r.series_key)
            for r in self._db.execute(
                select(FollowedSeries).where(
                    FollowedSeries.profile_id == self.profile_id,
                    FollowedSeries.reading_status == "completed",
                )
            ).scalars()
        }
        # (member, series) -> event kinds seen in the window, plus a title/cover
        seen: dict[tuple[int, str, str], dict[str, Any]] = {}
        for ev in self._events(since=since):
            if ev.created_at >= until or (ev.source_id, ev.series_key) not in seconds:
                continue
            slot = seen.setdefault(
                (ev.profile_id, ev.source_id, ev.series_key),
                {"finished": False, "ev": ev},
            )
            slot["finished"] = slot["finished"] or ev.kind == "finished_series"
        overlaps = []
        for (pid, source_id, series_key), slot in seen.items():
            both = (
                "finished"
                if slot["finished"] and (source_id, series_key) in completed
                else "read"
            )
            overlaps.append((both, pid, source_id, series_key, slot["ev"]))
        overlaps.sort(
            key=lambda o: (o[0] != "finished", -seconds[(o[2], o[3])], o[1])
        )
        with_count: dict[int, int] = defaultdict(int)
        for o in overlaps:
            with_count[o[1]] += 1
        top = [
            {
                "member": self.profile_ref(pid),
                "series": self.series_shape(sid, key, ev.title, ev.cover_url),
                "both": both,
            }
            for both, pid, sid, key, ev in overlaps[:5]
        ]
        self._colour([t["series"] for t in top])
        return {
            "overlaps": top,
            "with": [
                self.profile_ref(pid)
                for pid, _n in sorted(with_count.items(), key=lambda kv: (-kv[1], kv[0]))
            ],
        }


def get_circle_service(
    db: Annotated[Session, Depends(get_db)],
    ctx: Annotated[ProfileContext, Depends(require_profile_context)],
) -> CircleService:
    if ctx.profile_id is None or ctx.user_id is None:
        raise AppError(
            "An active profile is required for this action.",
            code="profile_required",
            status_code=400,
        )
    return CircleService(db, ctx.user_id, ctx.profile_id)


def _home_builder(home: Any, payload: dict[str, Any]) -> list[dict[str, Any]]:
    """The ``LIVE_SECTION_BUILDERS`` hook: fresh per request, never cached."""
    if home.profile_id is None or home.user_id is None:
        return []
    from services.home_service import _iso as home_iso

    return CircleService(home._db, home.user_id, home.profile_id).home_sections(
        payload.get("content_kind", "manga"), home_iso(utcnow())
    )
