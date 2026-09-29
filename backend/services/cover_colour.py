"""Cover colours for both skins: Cinematic ``ambient`` and Glass ``palette``.

Cinematic paints every series in its "issue colour", ``ambient {duo, tint,
ink}`` (cinematic DESIGN.md §2.1.5); Glass floats its chrome over a field of
three blobs from ``palette {a, l, lMax}`` (glass DESIGN.md §2.1.8). Both come
out of ONE Pillow pass over the cover, run in exactly one place: the cover
proxy (``routes/sources.get_source_series_cover``), the first time a cover is
served at any width. The result lives in ``cover_palette`` for 30 days.

Everything else only READS: ``attach_cover_colours`` fills ``ambient`` and
``palette`` on a list of series payloads from one batched query, and never
fetches, decodes or enqueues. The page-image proxy is never touched: page tint
is the client's (cinematic §15.10 S1, glass §15.10 G6).

World recommendations have no source cover, so their colours come from the
AniList cover through the same ``extract``, on a background thread limited to
20 fetch starts a minute, stored in ``world_catalog_cache`` as
``al:colour:{anilist_id}`` (not in ``cover_palette``, whose orphan rule
deletes any ``source_id`` that is not a connector).

Layout: pure functions (bytes in, dicts out), then the DB helpers, then the
AniList worker.
"""

from __future__ import annotations

import collections
import colorsys
import io
import json
import logging
import math
import queue
import threading
import time
from collections.abc import Callable, Iterable
from datetime import timedelta
from typing import Any
from urllib.parse import urlsplit

from sqlalchemy import select, tuple_
from sqlalchemy.orm import Session

from connectors.ids import fully_unquote
from core.time_utils import utcnow
from database.models import CoverPalette, WorldCatalogCache
from services.image_resize import (
    _DECODABLE_FORMATS,
    _MAX_SOURCE_PIXELS,
    _flatten_to_rgb,
)

logger = logging.getLogger("manhwamaniacs.cover_colour")

#: A stored row older than this is treated as absent and recomputed on the
#: next cover serve; the retention sweep deletes it.
COLOUR_TTL = timedelta(days=30)

#: Cinematic §2.1.5 fallbacks: missing, undecodable or greyscale cover.
FALLBACK_AMBIENT: dict[str, str] = {"duo": "#B8B2A4", "tint": "#0E0D0B", "ink": "#F3F0E8"}

#: "The w=96 cover" of glass §2.1.8: the analysis width.
_ANALYSIS_WIDTH = 96

# ---------------------------------------------------------------------------
# Colour maths (pure)
# ---------------------------------------------------------------------------


def _linear(c: float) -> float:
    """One sRGB channel (0-1) to linear light, WCAG 2.x / OKLab."""
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


_LIN = [_linear(i / 255) for i in range(256)]
_LUM_R = [0.2126 * v for v in _LIN]
_LUM_G = [0.7152 * v for v in _LIN]
_LUM_B = [0.0722 * v for v in _LIN]


def _hex(rgb: Iterable[float]) -> str:
    """Channels in 0-1 to uppercase ``#RRGGBB``."""
    return "#" + "".join(f"{max(0, min(255, round(c * 255))):02X}" for c in rgb)


def _rgb8(hex_: str) -> tuple[int, int, int]:
    return int(hex_[1:3], 16), int(hex_[3:5], 16), int(hex_[5:7], 16)


def relative_luminance(hex_: str) -> float:
    """WCAG 2.x relative luminance of ``#RRGGBB``."""
    r, g, b = _rgb8(hex_)
    return _LUM_R[r] + _LUM_G[g] + _LUM_B[b]


def contrast(a: str, b: str) -> float:
    """WCAG 2.x contrast ratio between two ``#RRGGBB`` colours."""
    la, lb = relative_luminance(a), relative_luminance(b)
    hi, lo = max(la, lb), min(la, lb)
    return (hi + 0.05) / (lo + 0.05)


def _clamp(v: float, lo: float, hi: float) -> float:
    return max(lo, min(hi, v))


def derive_ambient(h: float, s: float) -> dict[str, str]:
    """The three Cinematic roles from a seed hue and saturation (HLS, 0-1)."""
    ink_s = _clamp(s, 0.35, 0.70)
    ink_l = 0.78
    ink = _hex(colorsys.hls_to_rgb(h, ink_l, ink_s))
    while contrast(ink, "#000000") < 7.0 and ink_l < 1.0:
        ink_l = min(1.0, ink_l + 0.03)
        ink = _hex(colorsys.hls_to_rgb(h, ink_l, ink_s))
    return {
        "duo": _hex(colorsys.hls_to_rgb(h, 0.62, _clamp(s, 0.45, 0.90))),
        "tint": _hex(colorsys.hls_to_rgb(h, 0.06, min(s, 0.35))),
        "ink": ink,
    }


def _oklch(rgb: tuple[int, int, int]) -> tuple[float, float]:
    """``(L, C)`` in Björn Ottosson's OKLab for an 8-bit sRGB colour."""
    r, g, b = (_LIN[c] for c in rgb)
    l_ = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ** (1 / 3)
    m_ = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ** (1 / 3)
    s_ = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ** (1 / 3)
    lightness = 0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_
    a = 1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_
    bb = 0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_
    return lightness, math.hypot(a, bb)


# ---------------------------------------------------------------------------
# Extraction (pure: bytes in, dicts out)
# ---------------------------------------------------------------------------


def _decode(data: bytes):
    """The cover as a <=96 px wide RGB image, or ``None``.

    Same guards as the proxy's own resize (``image_resize``): only the boring
    bitmap decoders, nothing past the pixel ceiling, frame 0 only.
    """
    try:
        from PIL import Image

        img = Image.open(io.BytesIO(data))
        fmt = (img.format or "").upper()
        if fmt not in _DECODABLE_FORMATS:
            return None
        width, height = img.size
        if width <= 0 or height <= 0 or width * height > _MAX_SOURCE_PIXELS:
            return None
        img.seek(0)
        if fmt in ("JPEG", "MPO"):
            # libjpeg emits a 1/2-1/8 scale straight from the DCT.
            img.draft("RGB", (192, 288))
        img = _flatten_to_rgb(img)
        if img.mode != "RGB":
            img = img.convert("RGB")
        width, height = img.size
        if width > _ANALYSIS_WIDTH:
            img = img.resize(
                (_ANALYSIS_WIDTH, max(1, round(_ANALYSIS_WIDTH * height / width))),
                Image.Resampling.BILINEAR,
            )
        else:
            img.load()
        return img
    except Exception:  # noqa: BLE001 - hostile upstream bytes are "no colour"
        return None


def ambient_from(img) -> dict[str, str]:
    """Cinematic §2.1.5: 48 x 48 bilinear, 8-colour median cut, HLS seed."""
    from PIL import Image

    quant = img.resize((48, 48), Image.Resampling.BILINEAR).quantize(
        colors=8, method=Image.Quantize.MEDIANCUT
    )
    pal = quant.getpalette() or []
    best: tuple[float, int, float, float] | None = None
    for count, index in quant.getcolors() or []:
        r, g, b = pal[index * 3 : index * 3 + 3]
        h, l, s = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
        # Paper, ink, and swatches with no hue (the page picker's 0.08).
        if l < 0.08 or l > 0.94 or s < 0.08:
            continue
        candidate = (count * (0.35 + s), count, h, s)
        if best is None or candidate[:2] > best[:2]:
            best = candidate
    if best is None:  # greyscale cover
        return dict(FALLBACK_AMBIENT)
    return derive_ambient(best[2], best[3])


def palette_from(img) -> dict[str, Any]:
    """Glass §2.1.8 Extraction item 1 on the 96-wide cover."""
    from PIL import Image

    quant = img.quantize(colors=6, method=Image.Quantize.MEDIANCUT)
    pal = quant.getpalette() or []
    swatches = []
    for count, index in quant.getcolors() or []:
        rgb = tuple(pal[index * 3 : index * 3 + 3])
        lightness, chroma = _oklch(rgb)
        swatches.append((count, rgb, lightness, chroma))
    kept = [s for s in swatches if 0.12 <= s[2] <= 0.94 and s[3] >= 0.025]
    if not kept:
        kept = sorted(swatches, key=lambda s: -s[0])[:2]
    kept.sort(key=lambda s: (-(s[0] * (0.5 + s[3])), -s[0]))

    reds, greens, blues = (band.tobytes() for band in img.split())
    lum = sorted(
        _LUM_R[r] + _LUM_G[g] + _LUM_B[b] for r, g, b in zip(reds, greens, blues)
    )
    n = len(lum)
    return {
        "a": [_hex(c / 255 for c in s[1]) for s in kept[:3]],
        "l": round(min(1.0, sum(lum) / n), 3),
        "lMax": round(min(1.0, lum[math.ceil(0.95 * n) - 1]), 3),
    }


def extract(data: bytes) -> tuple[dict[str, str], dict[str, Any]] | None:
    """``(ambient, palette)`` from cover bytes, or ``None`` if they do not decode."""
    img = _decode(data)
    if img is None:
        return None
    return ambient_from(img), palette_from(img)


# ---------------------------------------------------------------------------
# cover_palette: write once in the cover proxy, read in batches everywhere
# ---------------------------------------------------------------------------


def ensure_cover_colours(db: Session, source_id: str, series_key: str, data: bytes) -> None:
    """Compute and store a cover's colours unless a fresh row exists.

    Called by the cover proxy on every serve; a fresh row costs one
    primary-key read. An undecodable cover stores nothing (retried on a later
    serve). Never raises: a colour failure must not break a cover.
    """
    try:
        row = db.get(CoverPalette, (source_id, fully_unquote(series_key)))
        if row is not None and row.computed_at >= utcnow() - COLOUR_TTL:
            return
        result = extract(data)
        if result is None:
            return
        ambient, palette = result
        if row is None:
            row = CoverPalette(source_id=source_id, series_key=fully_unquote(series_key))
            db.add(row)
        row.ambient = json.dumps(ambient)
        row.palette = json.dumps(palette)
        row.computed_at = utcnow()
        db.commit()
    except Exception:  # noqa: BLE001
        logger.warning(
            "cover colours failed for %s/%s", source_id, series_key, exc_info=True
        )
        try:
            db.rollback()
        except Exception:  # noqa: BLE001
            pass


#: Pairs per row-value ``IN``: 800 bound parameters, inside SQLite's limit.
_ATTACH_CHUNK = 400


def _default_key(item: dict[str, Any]) -> tuple[Any, Any]:
    return item["source_id"], item["series_key"]


def attach_cover_colours(
    db: Session,
    items: list[dict[str, Any]],
    key: Callable[[dict[str, Any]], tuple[Any, Any]] = _default_key,
) -> list[dict[str, Any]]:
    """Set ``ambient`` and ``palette`` on every item (``None`` for a miss).

    One indexed read per 400 items; never fetches, decodes or enqueues.
    Returns ``items`` so a route can wrap its return value.
    """
    pairs: list[tuple[str, str] | None] = []
    for item in items:
        try:
            source_id, series_key = key(item)
        except (KeyError, TypeError):
            source_id = series_key = None
        pairs.append(
            (str(source_id), fully_unquote(str(series_key)))
            if source_id and series_key
            else None
        )
    wanted = list({p for p in pairs if p is not None})
    found: dict[tuple[str, str], tuple[Any, Any]] = {}
    cutoff = utcnow() - COLOUR_TTL
    for start in range(0, len(wanted), _ATTACH_CHUNK):
        chunk = wanted[start : start + _ATTACH_CHUNK]
        rows = db.execute(
            select(
                CoverPalette.source_id,
                CoverPalette.series_key,
                CoverPalette.ambient,
                CoverPalette.palette,
            ).where(
                tuple_(CoverPalette.source_id, CoverPalette.series_key).in_(chunk),
                CoverPalette.computed_at >= cutoff,
            )
        ).all()
        for source_id, series_key, ambient, palette in rows:
            found[(source_id, series_key)] = (json.loads(ambient), json.loads(palette))
    for item, pair in zip(items, pairs):
        hit = found.get(pair) if pair is not None else None
        item["ambient"] = hit[0] if hit else None
        item["palette"] = hit[1] if hit else None
    return items


# ---------------------------------------------------------------------------
# WorldItems: AniList covers, fetched in the background, 20 a minute
# ---------------------------------------------------------------------------

#: False in tests (conftest), so no test ever starts the thread.
ANILIST_WORKER_ENABLED = True

_ANILIST_HOST = "s4.anilist.co"
_COLOUR_KEY = "al:colour:{}"
_RATE_LIMIT = 20
_RATE_WINDOW = 60.0
_MAX_COVER_BYTES = 5 * 1024 * 1024

_queue: queue.Queue[tuple[int, str]] = queue.Queue(maxsize=200)
_pending: set[int] = set()
_starts: collections.deque[float] = collections.deque()
_lock = threading.Lock()
_thread: threading.Thread | None = None


def _allowed_url(url: Any) -> bool:
    if not isinstance(url, str):
        return False
    parts = urlsplit(url)
    return parts.scheme == "https" and parts.netloc == _ANILIST_HOST


def pending_anilist_ids() -> set[int]:
    with _lock:
        return set(_pending)


def enqueue_anilist_colour(anilist_id: int, url: str) -> bool:
    """Queue one AniList cover for colouring. False when refused or dropped
    (bad host, already pending, queue full: a later visit re-enqueues)."""
    if not _allowed_url(url):
        return False
    with _lock:
        if anilist_id in _pending:
            return False
        try:
            _queue.put_nowait((anilist_id, url))
        except queue.Full:
            return False
        _pending.add(anilist_id)
    _start_worker()
    return True


def attach_world_colours(db: Session, items: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """``ambient``/``palette`` on WorldItems from ``al:colour:*``; queue misses.

    Only visible items reach here (the gate drops hidden media before they
    are built), so a hidden item is never served or enqueued.
    """
    ids = {i["anilist_id"] for i in items if i.get("anilist_id") is not None}
    found: dict[str, Any] = {}
    if ids:
        rows = db.execute(
            select(WorldCatalogCache.key, WorldCatalogCache.payload).where(
                WorldCatalogCache.key.in_([_COLOUR_KEY.format(i) for i in ids]),
                WorldCatalogCache.fetched_at >= utcnow() - COLOUR_TTL,
            )
        ).all()
        found = {key: json.loads(payload) for key, payload in rows}
    for item in items:
        anilist_id = item.get("anilist_id")
        hit = found.get(_COLOUR_KEY.format(anilist_id)) if anilist_id is not None else None
        item["ambient"] = hit.get("ambient") if hit else None
        item["palette"] = hit.get("palette") if hit else None
        if hit is None and anilist_id is not None:
            enqueue_anilist_colour(anilist_id, item.get("cover_url"))
    return items


def _wait_for_slot(clock: Callable[[], float], sleep: Callable[[float], None]) -> None:
    """Sliding window: at most ``_RATE_LIMIT`` fetch starts per ``_RATE_WINDOW``."""
    now = clock()
    while _starts and now - _starts[0] >= _RATE_WINDOW:
        _starts.popleft()
    if len(_starts) >= _RATE_LIMIT:
        sleep(_starts[0] + _RATE_WINDOW - now)
        now = clock()
        while _starts and now - _starts[0] >= _RATE_WINDOW:
            _starts.popleft()
    _starts.append(now)


def drain_anilist_colours(
    db: Session,
    *,
    fetch: Callable[[str], bytes | None],
    clock: Callable[[], float],
    sleep: Callable[[float], None],
    max_items: int,
    block: bool = False,
) -> int:
    """Colour up to ``max_items`` queued AniList covers; returns how many were
    taken off the queue. ``block`` waits for the first item (the thread)."""
    done = 0
    while done < max_items:
        try:
            anilist_id, url = _queue.get(block=block)
        except queue.Empty:
            break
        try:
            if _allowed_url(url):
                _wait_for_slot(clock, sleep)
                data = fetch(url)
                result = extract(data) if data else None
                if result is not None:
                    ambient, palette = result
                    db.merge(
                        WorldCatalogCache(
                            key=_COLOUR_KEY.format(anilist_id),
                            payload=json.dumps({"ambient": ambient, "palette": palette}),
                            fetched_at=utcnow(),
                        )
                    )
                    db.commit()
        except Exception:  # noqa: BLE001 - one bad cover must not stop the worker
            logger.warning("anilist colour failed for %s", anilist_id, exc_info=True)
            db.rollback()
        finally:
            with _lock:
                _pending.discard(anilist_id)
        done += 1
    return done


def _fetch_anilist_cover(url: str) -> bytes | None:
    import httpx

    from services import world_recs

    with httpx.stream(
        "GET",
        url,
        timeout=world_recs.HTTP_TIMEOUT,
        follow_redirects=False,
        headers={"User-Agent": world_recs.USER_AGENT},
    ) as response:
        if response.status_code != 200:
            return None
        body = bytearray()
        for chunk in response.iter_bytes():
            body += chunk
            if len(body) > _MAX_COVER_BYTES:
                return None
        return bytes(body)


def _worker() -> None:
    from database.session import SessionLocal

    while True:
        db = SessionLocal()
        try:
            drain_anilist_colours(
                db,
                fetch=_fetch_anilist_cover,
                clock=time.monotonic,
                sleep=time.sleep,
                max_items=1,
                block=True,
            )
        except Exception:  # noqa: BLE001
            logger.warning("anilist colour worker iteration failed", exc_info=True)
        finally:
            db.close()


def _start_worker() -> None:
    global _thread
    if not ANILIST_WORKER_ENABLED:
        return
    with _lock:
        if _thread is not None and _thread.is_alive():
            return
        _thread = threading.Thread(target=_worker, name="anilist-colour", daemon=True)
        _thread.start()


def reset_anilist_colour_worker() -> None:
    """Empty the queue, the pending set and the limiter (tests)."""
    with _lock:
        while True:
            try:
                _queue.get_nowait()
            except queue.Empty:
                break
        _pending.clear()
        _starts.clear()
