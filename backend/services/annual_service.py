"""``GET /library/annual``: the year in reading (Cinematic's The Annual, Glass's Wrapped).

Everything here is the calendar year in the caller's fixed
``tz_offset_minutes``, gate-filtered on serve exactly like the statistics
payload, except ``shareable`` (never mature, whatever the gate) and the
``busiest_day`` / ``firsts_lasts`` series lists (same rule).
"""

from __future__ import annotations

import collections
import json
from datetime import date, datetime, timedelta
from typing import Any

from sqlalchemy import and_, distinct, func, select

from core.connector_directory import descriptors_by_source, is_mature_source
from core.content_rating import mature_tracker_case
from core.errors import AppError
from database.models import FollowedSeries, ListenSession, ReadingSession
from services.reading_stats_service import (
    _CHAPTER_ID,
    _SECONDS,
    ReadingStatsService,
    _iso,
)
from services.voice_pack import load_voices

_CACHE_MAX = 64
# ponytail: per-process cache; the backend runs one process (python main.py),
# move to a table if it ever runs several.
_CACHE: collections.OrderedDict[tuple, dict[str, Any]] = collections.OrderedDict()


def reset_annual_cache() -> None:
    _CACHE.clear()


def _longest_run(days: list[str]) -> dict[str, Any]:
    """Longest run of consecutive ISO dates (earliest wins a tie)."""
    best: tuple[int, str, str] | None = None
    run_start = prev = None
    length = 0
    for d in days:
        cur = date.fromisoformat(d)
        if prev is not None and (cur - prev).days == 1:
            length += 1
        else:
            run_start, length = cur, 1
        prev = cur
        if best is None or length > best[0]:
            best = (length, run_start.isoformat(), cur.isoformat())
    if best is None:
        return {"days": 0, "month": None, "start": None, "end": None}
    return {
        "days": best[0],
        "month": int(best[1][5:7]),
        "start": best[1],
        "end": best[2],
    }


class AnnualService(ReadingStatsService):
    def build(self, year: int | None = None) -> dict[str, Any]:  # type: ignore[override]
        local_today = self._local_now().date()
        year = local_today.year if year is None else year
        if year > local_today.year:
            raise AppError(
                "That year has not happened yet.",
                code="invalid_year",
                status_code=422,
            )
        key = (
            self._user_id,
            self._profile_id,
            self._gate_open,
            year,
            self._tz,
            local_today.isoformat(),
        )
        hit = _CACHE.get(key)
        if hit is not None:
            _CACHE.move_to_end(key)
            return hit
        payload = self._compose(year)
        _CACHE[key] = payload
        while len(_CACHE) > _CACHE_MAX:
            _CACHE.popitem(last=False)
        return payload

    # --- composition -----------------------------------------------------

    def _window_where(self, stmt, since: datetime, until: datetime):
        return stmt.where(ReadingSession.started_at >= since).where(
            ReadingSession.started_at < until
        )

    def _compose(self, year: int) -> dict[str, Any]:
        offset = timedelta(minutes=self._tz)
        since = datetime(year, 1, 1) - offset
        until = min(datetime(year + 1, 1, 1) - offset, self._now)
        partial = year == self._local_now().year

        totals = self._roll(
            self._db.execute(
                self._window_where(
                    self._sessions(
                        select(*self._aggregates()).select_from(ReadingSession)
                    ),
                    since,
                    until,
                )
            ).one()
        )

        day = self._day().label("day")
        day_rows = self._db.execute(
            self._window_where(
                self._sessions(
                    select(day, func.count(distinct(_CHAPTER_ID)).label("chapters"))
                    .select_from(ReadingSession)
                ),
                since,
                until,
            ).group_by(day)
        ).all()
        active = sorted(r.day for r in day_rows if r.day)

        month = func.strftime("%m", ReadingSession.started_at, self._modifier).label("m")
        by_month = {
            int(r.m): int(r.n)
            for r in self._db.execute(
                self._window_where(
                    self._sessions(
                        select(month, func.count(distinct(_CHAPTER_ID)).label("n"))
                        .select_from(ReadingSession)
                    ),
                    since,
                    until,
                ).group_by(month)
            ).all()
        }

        hour = self._hour().label("hour")
        by_hour_rows = {
            int(r.hour): int(r.seconds or 0)
            for r in self._db.execute(
                self._window_where(
                    self._sessions(
                        select(hour, func.coalesce(func.sum(_SECONDS), 0).label("seconds"))
                        .select_from(ReadingSession)
                    ),
                    since,
                    until,
                ).group_by(hour)
            ).all()
            if r.hour is not None
        }

        series = self._series_rows(since, until)
        top_series = self._with_titles_and_colours([dict(r) for r in series[:5]])
        names = {sid: d.name for sid, d in descriptors_by_source().items()}
        total_seconds = sum(r["seconds_read"] for r in series)
        by_source: dict[str, int] = {}
        for r in series:
            by_source[r["source_id"]] = by_source.get(r["source_id"], 0) + r["seconds_read"]
        top_sources = [
            {
                "source_id": sid,
                "name": names.get(sid, sid),
                "share": round(sec / total_seconds, 3),
            }
            for sid, sec in sorted(by_source.items(), key=lambda kv: (-kv[1], kv[0]))[:3]
            if total_seconds
        ]

        return {
            "year": year,
            "partial": partial,
            "since": _iso(since),
            "until": _iso(until),
            "recorded_days": len(active),
            "seconds_read": totals["seconds_read"],
            "chapters_read": totals["chapters_read"],
            "pages_read": totals["pages_read"],
            "chapters_by_month": [by_month.get(m, 0) for m in range(1, 13)],
            "top_series": top_series,
            "genres": self._genre_weights(series, drop_mature_words=False),
            "by_hour": [
                {"hour": h, "seconds_read": by_hour_rows.get(h, 0)} for h in range(24)
            ],
            "longest_streak": _longest_run(active),
            "top_sources": top_sources,
            "busiest_day": self._busiest_day(day_rows),
            "firsts_lasts": self._firsts_lasts(since, until),
            "circle": None,
            "top_voices": self._top_voices(since, until),
            "available_years": self._available_years(),
            "shareable": self.shareable(since, until),
        }

    def _busiest_day(self, day_rows) -> dict[str, Any] | None:
        rows = [r for r in day_rows if r.day]
        if not rows:
            return None
        best = min(rows, key=lambda r: (-int(r.chapters), r.day))
        start = datetime.fromisoformat(best.day) - timedelta(minutes=self._tz)
        found = self._series_rows(start, start + timedelta(days=1), nonmature=True)
        found = [r for r in found if not is_mature_source(r["source_id"])][:5]
        self._with_titles_and_colours(found)
        return {
            "date": best.day,
            "chapters": int(best.chapters),
            "series": [
                {k: r[k] for k in ("source_id", "series_key", "title", "cover_url")}
                for r in found
            ],
        }

    def _firsts_lasts(self, since: datetime, until: datetime) -> dict[str, Any] | None:
        def pick(order):
            stmt = self._window_where(
                self._sessions(
                    select(
                        ReadingSession.source_id,
                        ReadingSession.series_key,
                        ReadingSession.started_at,
                        FollowedSeries.title.label("title"),
                        FollowedSeries.cover_url.label("cover_url"),
                    ).select_from(ReadingSession),
                    needs_follow=True,
                    nonmature=True,
                ),
                since,
                until,
            )
            for r in self._db.execute(
                stmt.order_by(order, ReadingSession.id).limit(200)
            ).all():
                if is_mature_source(r.source_id):
                    continue
                item = {
                    "source_id": r.source_id,
                    "series_key": r.series_key,
                    "title": r.title,
                    "cover_url": r.cover_url,
                }
                self._fill_cached_titles([item], with_cover=True)
                return {"series": item, "read_at": _iso(r.started_at)}
            return None

        first = pick(ReadingSession.started_at.asc())
        if first is None:
            return None
        return {"first": first, "last": pick(ReadingSession.started_at.desc())}

    def _top_voices(self, since: datetime, until: datetime) -> list[dict[str, Any]]:
        stmt = (
            select(ListenSession.voice_ids, ListenSession.seconds)
            .outerjoin(
                FollowedSeries,
                and_(
                    FollowedSeries.user_id == ListenSession.user_id,
                    FollowedSeries.profile_id == ListenSession.profile_id,
                    FollowedSeries.source_id == ListenSession.source_id,
                    FollowedSeries.series_key == ListenSession.series_key,
                ),
            )
            .where(ListenSession.user_id == self._user_id)
            .where(ListenSession.profile_id == self._profile_id)
            .where(ListenSession.started_at >= since)
            .where(ListenSession.started_at < until)
        )
        if not self._gate_open:
            stmt = stmt.where(mature_tracker_case(ListenSession.source_id) == 0)
        seconds: dict[str, int] = {}
        for blob, secs in self._db.execute(stmt).all():
            try:
                ids = json.loads(blob or "[]")
            except ValueError:
                continue
            for vid in ids:
                seconds[vid] = seconds.get(vid, 0) + int(secs)
        pack = {v.voice_id: v.name for v in load_voices()}
        top = sorted(seconds.items(), key=lambda kv: (-kv[1], kv[0]))[:3]
        return [
            {"voice_id": vid, "name": pack.get(vid, vid), "seconds": sec}
            for vid, sec in top
        ]

    def _available_years(self) -> list[int]:
        day = self._day().label("day")
        rows = self._db.execute(
            self._sessions(select(day).select_from(ReadingSession)).group_by(day)
        ).scalars()
        per_year: dict[int, int] = {}
        for d in rows:
            if d:
                per_year[int(d[:4])] = per_year.get(int(d[:4]), 0) + 1
        return sorted((y for y, n in per_year.items() if n >= 7), reverse=True)
