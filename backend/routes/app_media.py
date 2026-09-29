"""Static media for the redesign: soundscapes, install-page fonts, brand files.

Public by living under ``/app/`` (see ``_PUBLIC_PREFIXES``). Every route looks
the requested name up in a literal allowlist of complete file names; request
text is never joined into a path before that lookup succeeds, so traversal
attempts can only miss.
"""

from __future__ import annotations

import os
from pathlib import Path

from fastapi import APIRouter, HTTPException
from fastapi.responses import FileResponse

from core.config import REPO_ROOT

router = APIRouter(tags=["app"])

BACKEND_DIR = Path(__file__).resolve().parents[1]
SOUNDSCAPES_DIR = Path(
    os.environ.get("MM_SOUNDSCAPES_DIR", str(BACKEND_DIR / "media" / "soundscapes"))
)
FONTS_DIR = Path(os.environ.get("MM_FONTS_DIR", str(BACKEND_DIR / "media" / "fonts")))
BRAND_DIR = Path(os.environ.get("MM_BRAND_DIR", str(REPO_ROOT / "frontend" / "public")))
IMMUTABLE = "public, max-age=31536000, immutable"

CINEMATIC_SOUNDSCAPES = frozenset(
    f"{sid}.{ext}"
    for sid in (
        "projector-room",
        "rain-on-glass",
        "night-city",
        "cafe",
        "night-wind",
        "low-drone",
        "afternoon-park",
        "temple-bells",
    )
    for ext in ("ogg", "m4a")
)
GLASS_LAYERS = frozenset(
    f"{scene}-{layer}.{ext}"
    for scene in ("rain", "wind", "ocean", "hearth", "stream", "deep")
    for layer in ("bed", "detail", "tone")
    for ext in ("ogg", "m4a")
)
AUDIO_TYPES = {".ogg": "audio/ogg", ".m4a": "audio/mp4"}
FONT_FILES = frozenset(
    {
        "bodoni-moda-latin.woff2",
        "bodoni-moda-latin-ext.woff2",
        "bodoni-moda-italic-latin.woff2",
        "bodoni-moda-italic-latin-ext.woff2",
        "archivo-latin.woff2",
        "archivo-latin-ext.woff2",
    }
)
# Published name -> path under BRAND_DIR.
BRAND_FILES = {
    "og.png": "og.png",
    "apple-touch-icon.png": "icons/apple-touch-icon.png",
    "icon-192.png": "icons/icon-192.png",
}


def _serve(path: Path, media_type: str, cache: str) -> FileResponse:
    if not path.is_file():
        raise HTTPException(status_code=404, detail="Not found.")
    return FileResponse(path, media_type=media_type, headers={"Cache-Control": cache})


def _audio(directory: Path, name: str) -> FileResponse:
    return _serve(directory / name, AUDIO_TYPES[Path(name).suffix], IMMUTABLE)


@router.get("/app/soundscapes/glass/{name}")
def glass_layer(name: str) -> FileResponse:
    if name not in GLASS_LAYERS:
        raise HTTPException(status_code=404, detail="Not found.")
    return _audio(SOUNDSCAPES_DIR / "glass", name)


@router.get("/app/soundscapes/{name}")
def soundscape(name: str) -> FileResponse:
    if name in CINEMATIC_SOUNDSCAPES:
        return _audio(SOUNDSCAPES_DIR, name)
    rest = name.removeprefix("glass-")
    if rest != name and rest in GLASS_LAYERS:
        return _audio(SOUNDSCAPES_DIR / "glass", rest)
    raise HTTPException(status_code=404, detail="Not found.")


@router.get("/app/fonts/{name}")
def font(name: str) -> FileResponse:
    if name not in FONT_FILES:
        raise HTTPException(status_code=404, detail="Not found.")
    return _serve(FONTS_DIR / name, "font/woff2", IMMUTABLE)


@router.get("/app/brand/{name}")
def brand(name: str) -> FileResponse:
    rel = BRAND_FILES.get(name)
    if rel is None:
        raise HTTPException(status_code=404, detail="Not found.")
    return _serve(BRAND_DIR / rel, "image/png", "public, max-age=86400")
