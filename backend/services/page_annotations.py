"""Client-reported page tints and panel boxes, cached per page identity.

The server never decodes or analyses an image (cinematic S1/S11, glass G6/G14):
clients sample the decoded page and report; this module only remembers and
serves. ``pages[].tint`` and ``pages[].panels`` ride in every reader manifest.
"""

from __future__ import annotations

import hashlib
import json
from collections.abc import Sequence
from typing import Any

from sqlalchemy import select
from sqlalchemy.orm import Session

from core.errors import AppError
from core.time_utils import utcnow
from database.models import ReaderPageAnnotation


def page_etag(url: str) -> str:
    """Identity of a page image without touching it: hash of its proxy URL.

    The image proxy's own ETag hashes served bytes (varies with ``?w=`` and
    ``Accept``) and the server keeps no page bytes, so it cannot be known
    without decoding. The proxy URL embeds the upstream page key, which a
    source changes when it re-uploads a page, so a stale tint or panel list is
    never attached to a new image.
    """
    return hashlib.sha256(url.encode("utf-8")).hexdigest()[:32]


def resolve_pages(reader: Any, source_id: str, series_key: str, chapter_key: str):
    """The chapter's ``pages`` list via the gated manifest path, or ``None``.

    404 (gated or unknown source or chapter) propagates; any other upstream
    failure returns ``None`` (fire and forget: the next reader reports again).
    """
    try:
        # ponytail: may refetch the chapter's page list when the connector cache has evicted it; add a stored page index if that shows up in the health log
        return reader.manifest(source_id, series_key, chapter_key)["pages"]
    except AppError as exc:
        if exc.status_code == 404:
            raise
        return None


def _upsert(
    db: Session, source_id: str, series_key: str, chapter_key: str,
    pages: list[dict[str, Any]], reports: dict[int, dict[str, Any]],
) -> None:
    by_number = {p["number"]: p for p in pages}
    wanted = {
        page_etag(by_number[n]["url"]): (n, fields)
        for n, fields in reports.items() if n in by_number
    }
    if not wanted:
        return
    rows = {
        r.page_etag: r
        for r in db.execute(
            select(ReaderPageAnnotation).where(
                ReaderPageAnnotation.source_id == source_id,
                ReaderPageAnnotation.series_key == series_key,
                ReaderPageAnnotation.chapter_key == chapter_key,
                ReaderPageAnnotation.page_etag.in_(list(wanted)),
            )
        ).scalars()
    }
    now = utcnow()
    for etag, (number, fields) in wanted.items():
        row = rows.get(etag)
        if row is None:
            row = ReaderPageAnnotation(
                source_id=source_id, series_key=series_key, chapter_key=chapter_key,
                page_etag=etag,
            )
            db.add(row)
        row.page_number = number
        row.page_count = len(pages)
        row.updated_at = now
        for name, value in fields.items():
            setattr(row, name, value)
    db.commit()


def store_tints(
    db: Session, source_id: str, series_key: str, chapter_key: str,
    pages: list[dict[str, Any]], tints: Sequence[tuple[int, str | None]],
) -> None:
    """Upsert tints; ``None`` (greyscale) and unknown pages are ignored."""
    _upsert(
        db, source_id, series_key, chapter_key, pages,
        {n: {"tint": hx.upper()} for n, hx in tints if hx},
    )


def store_panels(
    db: Session, source_id: str, series_key: str, chapter_key: str,
    pages: list[dict[str, Any]], panels: Sequence[tuple[int, list[dict[str, float]]]],
) -> None:
    """Upsert panel lists in the order sent; ``[]`` means analysed, none found."""
    _upsert(
        db, source_id, series_key, chapter_key, pages,
        {n: {"panels": json.dumps(p)} for n, p in panels},
    )


def annotations_for(
    db: Session, source_id: str, series_key: str, chapter_keys: Sequence[str]
) -> dict[str, list[ReaderPageAnnotation]]:
    """Stored rows for a whole window in ONE query, grouped by chapter."""
    out: dict[str, list[ReaderPageAnnotation]] = {k: [] for k in chapter_keys}
    if not chapter_keys:
        return out
    for row in db.execute(
        select(ReaderPageAnnotation).where(
            ReaderPageAnnotation.source_id == source_id,
            ReaderPageAnnotation.series_key == series_key,
            ReaderPageAnnotation.chapter_key.in_(list(chapter_keys)),
        )
    ).scalars():
        out.setdefault(row.chapter_key, []).append(row)
    return out


def attach(manifest: dict[str, Any], rows: Sequence[ReaderPageAnnotation]) -> dict[str, Any]:
    """Add ``pages[].tint``, ``pages[].panels`` and ``panels_ready`` in place."""
    by_etag = {r.page_etag: r for r in rows}
    ready = bool(manifest["pages"])
    for page in manifest["pages"]:
        row = by_etag.get(page_etag(page["url"]))
        if row is not None and row.tint:
            page["tint"] = row.tint
        if row is not None and row.panels is not None:
            page["panels"] = json.loads(row.panels)
        else:
            ready = False
    manifest["panels_ready"] = ready
    return manifest


def stored_panels(
    db: Session, source_id: str, series_key: str, chapter_key: str
) -> tuple[bool, list[dict[str, Any]]]:
    """``(panels_ready, pages)`` from stored rows only: no connector call."""
    rows = annotations_for(db, source_id, series_key, [chapter_key])[chapter_key]
    with_panels = sorted((r for r in rows if r.panels is not None), key=lambda r: r.page_number)
    pages = [{"page": r.page_number, "panels": json.loads(r.panels)} for r in with_panels]
    count = max((r.page_count for r in rows), default=0)
    return bool(pages) and len(pages) == count, pages
