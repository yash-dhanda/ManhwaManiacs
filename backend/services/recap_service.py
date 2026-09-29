"""Whether a "Previously on" recap can be offered, never the recap itself.

``availability`` answers cinematic §9.1.5's object from local rows only: this
profile's completed chapters, the OCR / novel text already cached, the
``ai_result_cache`` and the caller's ask allowance. It makes no AI call and
costs no budget, so ``GET /library/continue-reading`` and ``GET /home`` can put
it on every row. ``backend/05`` adds the endpoint and the stream.
"""

from __future__ import annotations

import json
from datetime import timedelta
from typing import Any

from sqlalchemy import select, tuple_
from sqlalchemy.orm import Session

from core.connector_directory import descriptor_for_source
from core.time_utils import utcnow
from database.models import (
    AiResultCache,
    ChapterOcr,
    ChapterProgress,
    FollowedSeries,
    NovelChapterCache,
    SourceSeriesCache,
)
from services import ai_desk
from services.followed_series_service import FollowedSeriesService
from services.suggestion_service import SuggestionService

MAX_CHAPTERS = 12
MAX_GAP = timedelta(days=60)
_IN_CHUNK = 300  # pairs per row-value IN: inside SQLite's variable limit


def _num(value: float | None) -> int | float | None:
    if value is None:
        return None
    return int(value) if float(value).is_integer() else value


def _chunks(items: list[Any]) -> list[list[Any]]:
    return [items[i : i + _IN_CHUNK] for i in range(0, len(items), _IN_CHUNK)]


def _number_in(blob: str | None, key: str) -> float | None:
    try:
        chapters = json.loads(blob or "[]")
    except ValueError:
        return None
    for entry in chapters if isinstance(chapters, list) else []:
        if isinstance(entry, dict) and str(entry.get("key") or entry.get("id")) == key:
            number = entry.get("number")
            return float(number) if isinstance(number, (int, float)) else None
    return None


def _est_seconds(n: int, scope: str) -> int:
    if scope == "chapter":
        return 20
    return round(min(400, 40 + 30 * n) / 230 * 60)


def _empty(reason: str) -> dict[str, Any]:
    return {
        "available": False,
        "reason": reason,
        "range": None,
        "est_seconds": 0,
        "cached": False,
    }


class RecapService:
    def __init__(
        self, db: Session, library: FollowedSeriesService, suggest: SuggestionService
    ) -> None:
        self._db = db
        self._library = library
        self._suggest = suggest

    def availability(
        self,
        source_id: str,
        series_key: str,
        to_key: str,
        *,
        scope: str = "series",
        shape: str = "prose",
    ) -> dict[str, Any]:
        return self.availability_many(
            [(source_id, series_key, to_key)], scope=scope, shape=shape
        )[0]

    # ponytail: keys stored under another spelling of a drifting series (Asura)
    # are not walked; add _alias_rows here if a recap ever misses one.
    def availability_many(
        self,
        rows: list[tuple[str, str, str]],
        *,
        scope: str = "series",
        shape: str = "prose",
    ) -> list[dict[str, Any]]:
        """One object per ``(source_id, series_key, to_key)``, in a fixed
        number of statements (progress, chapter lists, OCR, novel text, cache)."""
        if not rows:
            return []
        pairs = list({(s, k) for s, k, _ in rows})
        progress = self._progress(pairs)
        numbers = self._to_numbers(rows, progress)

        walks: list[list[Any] | None] = []
        for source_id, series_key, to_key in rows:
            number = numbers.get((source_id, series_key, to_key))
            walks.append(
                None
                if number is None
                else self._walk(progress.get((source_id, series_key), []), number, scope)
            )

        ocr = self._ocr([(r, w) for r, w in zip(rows, walks) if w])
        novel = self._novel_cached([(r, w) for r, w in zip(rows, walks) if w])
        ranges: list[list[Any] | None] = []
        reasons: list[str | None] = []
        for (source_id, series_key, _), walk in zip(rows, walks):
            if not walk:
                ranges.append(None)
                reasons.append("first_chapter")
                continue
            descriptor = descriptor_for_source(source_id)
            if descriptor is not None and descriptor.content_kind == "novel":
                kept = [c for c in walk if (source_id, series_key, c.chapter_key) in novel]
                ranges.append(kept or None)
                reasons.append(None if kept else "no_dialogue")
            else:
                spoken = sum(
                    1 for c in walk if (source_id, series_key, c.chapter_key) in ocr
                )
                ok = spoken * 2 >= len(walk)
                ranges.append(walk if ok else None)
                reasons.append(None if ok else "no_dialogue")

        keys: list[str | None] = []
        for (source_id, series_key, _), rng in zip(rows, ranges):
            keys.append(
                ai_desk.cache_key(
                    "recap", shape, scope, source_id, series_key,
                    rng[-1].chapter_key, rng[0].chapter_key,
                )
                if rng
                else None
            )
        cached = self._cached([k for k in keys if k])
        allowance = self._suggest.availability()

        out: list[dict[str, Any]] = []
        for rng, reason, key in zip(ranges, reasons, keys):
            if rng is None:
                out.append(_empty(reason or "first_chapter"))
                continue
            info = {
                "range": {
                    "from_key": rng[-1].chapter_key,
                    "to_key": rng[0].chapter_key,
                    "from_number": _num(rng[-1].chapter_number),
                    "to_number": _num(rng[0].chapter_number),
                },
                "est_seconds": _est_seconds(len(rng), scope),
            }
            if key in cached:
                out.append({"available": True, "reason": "ok", **info, "cached": True})
            elif allowance["reason"] in ("not_configured", "budget_exhausted"):
                out.append(
                    {"available": False, "reason": allowance["reason"], **info, "cached": False}
                )
            else:
                out.append({"available": True, "reason": "ok", **info, "cached": False})
        return out

    # --- statements --------------------------------------------------------

    def _progress(self, pairs: list[tuple[str, str]]) -> dict[tuple[str, str], list[Any]]:
        out: dict[tuple[str, str], list[Any]] = {}
        for chunk in _chunks(pairs):
            stmt = self._library._progress_scope(
                select(ChapterProgress).where(
                    tuple_(ChapterProgress.source_id, ChapterProgress.series_key).in_(chunk)
                )
            )
            for row in self._db.execute(stmt).scalars():
                out.setdefault((row.source_id, row.series_key), []).append(row)
        return out

    def _to_numbers(
        self, rows: list[tuple[str, str, str]], progress: dict[tuple[str, str], list[Any]]
    ) -> dict[tuple[str, str, str], float | None]:
        """The chapter number of each ``to_key``: progress, else the follow's
        list, else the cached series' list."""
        found: dict[tuple[str, str, str], float | None] = {}
        for source_id, series_key, to_key in rows:
            for p in progress.get((source_id, series_key), []):
                if p.chapter_key == to_key and p.chapter_number is not None:
                    found[(source_id, series_key, to_key)] = p.chapter_number
        missing = [r for r in rows if r not in found]
        if missing:
            wanted = list({(s, k) for s, k, _ in missing})
            blobs: dict[tuple[str, str], list[str | None]] = {}
            for chunk in _chunks(wanted):
                for s, k, blob in self._db.execute(
                    self._library._scope(
                        select(
                            FollowedSeries.source_id,
                            FollowedSeries.series_key,
                            FollowedSeries.known_chapters,
                        ).where(
                            tuple_(FollowedSeries.source_id, FollowedSeries.series_key).in_(chunk)
                        )
                    )
                ):
                    blobs.setdefault((s, k), []).append(blob)
            for r in missing:
                for blob in blobs.get((r[0], r[1]), []):
                    n = _number_in(blob, r[2])
                    if n is not None:
                        found[r] = n
            still = [r for r in missing if r not in found]
            if still:
                for chunk in _chunks(list({(s, k) for s, k, _ in still})):
                    for s, k, blob in self._db.execute(
                        select(
                            SourceSeriesCache.source_id,
                            SourceSeriesCache.series_key,
                            SourceSeriesCache.chapters,
                        ).where(
                            tuple_(SourceSeriesCache.source_id, SourceSeriesCache.series_key).in_(chunk)
                        )
                    ):
                        for r in still:
                            if (r[0], r[1]) == (s, k):
                                n = _number_in(blob, r[2])
                                if n is not None:
                                    found[r] = n
        return found

    @staticmethod
    def _walk(progress: list[Any], to_number: float, scope: str) -> list[Any]:
        done = sorted(
            (
                p
                for p in progress
                if p.is_completed
                and p.chapter_number is not None
                and p.chapter_number < to_number
            ),
            key=lambda p: (p.chapter_number, p.last_read_at),
            reverse=True,
        )
        limit = 1 if scope == "chapter" else MAX_CHAPTERS
        walk: list[Any] = []
        for p in done:
            if walk and abs(walk[-1].last_read_at - p.last_read_at) > MAX_GAP:
                break
            walk.append(p)
            if len(walk) >= limit:
                break
        return walk

    def _triples(self, items: list[tuple[Any, list[Any]]]) -> list[tuple[str, str, str]]:
        return list(
            {(r[0], r[1], c.chapter_key) for r, walk in items for c in walk}
        )

    def _ocr(self, items: list[tuple[Any, list[Any]]]) -> set[tuple[str, str, str]]:
        found: set[tuple[str, str, str]] = set()
        triples = self._triples(items)
        for chunk in _chunks(triples):
            found.update(
                tuple(t)
                for t in self._db.execute(
                    select(ChapterOcr.source_id, ChapterOcr.series_key, ChapterOcr.chapter_key).where(
                        tuple_(ChapterOcr.source_id, ChapterOcr.series_key, ChapterOcr.chapter_key).in_(chunk),
                        ChapterOcr.word_count > 0,
                    )
                )
            )
        return found

    def _novel_cached(self, items: list[tuple[Any, list[Any]]]) -> set[tuple[str, str, str]]:
        found: set[tuple[str, str, str]] = set()
        for chunk in _chunks(self._triples(items)):
            found.update(
                tuple(t)
                for t in self._db.execute(
                    select(
                        NovelChapterCache.source_id,
                        NovelChapterCache.series_key,
                        NovelChapterCache.chapter_key,
                    ).where(
                        tuple_(
                            NovelChapterCache.source_id,
                            NovelChapterCache.series_key,
                            NovelChapterCache.chapter_key,
                        ).in_(chunk)
                    )
                )
            )
        return found

    def _cached(self, keys: list[str]) -> set[str]:
        found: set[str] = set()
        for start in range(0, len(keys), 500):
            found.update(
                self._db.execute(
                    select(AiResultCache.key).where(
                        AiResultCache.key.in_(keys[start : start + 500]),
                        AiResultCache.expires_at > utcnow(),
                    )
                ).scalars()
            )
        return found
