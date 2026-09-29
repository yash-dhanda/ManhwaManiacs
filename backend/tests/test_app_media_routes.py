from __future__ import annotations

import fnmatch
from pathlib import Path

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import sessionmaker

from database.session import get_db
from main import create_app
from routes import app_media

IMMUTABLE = "public, max-age=31536000, immutable"
SIZE = 512


@pytest.fixture
def dirs(tmp_path, monkeypatch):
    snd, fonts, brand = tmp_path / "snd", tmp_path / "fonts", tmp_path / "brand"
    (snd / "glass").mkdir(parents=True)
    (brand / "icons").mkdir(parents=True)
    fonts.mkdir()
    for name in app_media.CINEMATIC_SOUNDSCAPES:
        (snd / name).write_bytes(bytes(range(256)) * 2)
    for name in app_media.GLASS_LAYERS:
        (snd / "glass" / name).write_bytes(name.encode() * 20)
    (snd / "SOURCES.md").write_text("x")
    (snd / "glass" / "SOURCES.md").write_text("x")
    for name in app_media.FONT_FILES:
        (fonts / name).write_bytes(b"wOF2" + b"\0" * 60)
    (fonts / "evil.woff2").write_bytes(b"wOF2")
    (fonts / "fonts.json").write_text("[]")
    (brand / "og.png").write_bytes(b"\x89PNG-og")
    (brand / "icons" / "icon-192.png").write_bytes(b"\x89PNG-192")
    (brand / "icons" / "apple-touch-icon.png").write_bytes(b"\x89PNG-touch")
    (brand / "sw.js").write_text("x")
    monkeypatch.setattr(app_media, "SOUNDSCAPES_DIR", snd)
    monkeypatch.setattr(app_media, "FONTS_DIR", fonts)
    monkeypatch.setattr(app_media, "BRAND_DIR", brand)
    return snd, fonts, brand


@pytest.fixture
def client(db_engine, dirs):
    factory = sessionmaker(bind=db_engine, autoflush=False, autocommit=False)

    def override():
        db = factory()
        try:
            yield db
        finally:
            db.close()

    app = create_app(run_migrations=False, run_workers=False)
    app.dependency_overrides[get_db] = override
    with TestClient(app) as c:
        yield c


def test_cinematic_soundscapes_are_served_immutable(client):
    assert len(app_media.CINEMATIC_SOUNDSCAPES) == 16
    for name in sorted(app_media.CINEMATIC_SOUNDSCAPES):
        r = client.get(f"/app/soundscapes/{name}")
        assert r.status_code == 200, name
        assert r.headers["content-type"] == (
            "audio/ogg" if name.endswith(".ogg") else "audio/mp4"
        )
        assert r.headers["cache-control"] == IMMUTABLE
        assert r.headers["accept-ranges"] == "bytes"


def test_glass_layers_in_both_spellings(client):
    assert len(app_media.GLASS_LAYERS) == 36
    for name in sorted(app_media.GLASS_LAYERS)[:6]:
        a = client.get(f"/app/soundscapes/glass/{name}")
        b = client.get(f"/app/soundscapes/glass-{name}")
        assert a.status_code == b.status_code == 200
        assert a.content == b.content
        assert a.headers["cache-control"] == IMMUTABLE
        assert a.headers["content-type"] in ("audio/ogg", "audio/mp4")


def test_range_and_unsatisfiable_range(client):
    url = "/app/soundscapes/cafe.ogg"
    r = client.get(url, headers={"Range": "bytes=0-99"})
    assert r.status_code == 206
    assert r.headers["content-range"] == f"bytes 0-99/{SIZE}"
    assert len(r.content) == 100
    assert client.get(url, headers={"Range": f"bytes={SIZE}-"}).status_code == 416


@pytest.mark.parametrize(
    "path",
    [
        "/app/soundscapes/lofi.ogg",
        "/app/soundscapes/cafe.mp3",
        "/app/soundscapes/SOURCES.md",
        "/app/soundscapes/glass/rain-bass.ogg",
        "/app/soundscapes/glass/SOURCES.md",
        "/app/soundscapes/glass-rain.ogg",
        "/app/fonts/evil.woff2",
        "/app/fonts/fonts.json",
        "/app/fonts/archivo-latin.ttf",
        "/app/brand/favicon.svg",
        "/app/brand/favicon.ico",
        "/app/brand/icons/icon-192.png",
        "/app/brand/sw.js",
    ],
)
def test_allowlists_refuse_everything_else(client, path):
    r = client.get(path)
    assert r.status_code == 404


def test_allowlisted_name_with_missing_file_is_404(client, dirs):
    snd, fonts, brand = dirs
    (snd / "cafe.ogg").unlink()
    (fonts / "archivo-latin.woff2").unlink()
    (brand / "og.png").unlink()
    for path in ("/app/soundscapes/cafe.ogg", "/app/fonts/archivo-latin.woff2", "/app/brand/og.png"):
        assert client.get(path).status_code == 404


@pytest.mark.parametrize(
    "path",
    [
        "/app/soundscapes/..%2F..%2Fmain.py",
        "/app/soundscapes/%2e%2e%2f%2e%2e%2fmain.py",
        "/app/soundscapes/glass/..%2Fcafe.ogg",
        "/app/soundscapes/glass/%2e%2e/cafe.ogg",
        "/app/fonts/..%2Fsoundscapes%2Fcafe.ogg",
        "/app/fonts/%2Fetc%2Fpasswd",
        "/app/brand/..%2F..%2Fbackend%2Fmain.py",
        "/app/soundscapes/cafe.ogg%00.woff2",
        "/app/soundscapes/cafe.ogg/..",
        "/app/media/soundscapes/glass/rain-bed.ogg",
        "/app/media/fonts/archivo-latin.woff2",
        "/app/media/og.png",
    ],
)
def test_traversal_is_404(client, path):
    assert client.get(path).status_code == 404


def test_fonts_and_brand_headers(client, dirs):
    _, _, brand = dirs
    r = client.get("/app/fonts/archivo-latin.woff2")
    assert r.status_code == 200
    assert r.headers["content-type"] == "font/woff2"
    assert r.headers["cache-control"] == IMMUTABLE
    og = client.get("/app/brand/og.png")
    assert og.headers["content-type"] == "image/png"
    assert og.headers["cache-control"] == "public, max-age=86400"
    icon = client.get("/app/brand/icon-192.png")
    assert icon.status_code == 200
    assert icon.content == (brand / "icons" / "icon-192.png").read_bytes()


def test_routes_are_public(client):
    assert not client.cookies
    for path in (
        "/app/soundscapes/cafe.ogg",
        "/app/soundscapes/glass/rain-bed.m4a",
        "/app/soundscapes/glass-rain-bed.m4a",
        "/app/fonts/archivo-latin.woff2",
        "/app/brand/apple-touch-icon.png",
    ):
        assert client.get(path).status_code == 200, path


def test_media_ships_in_the_image():
    ignore = Path(__file__).resolve().parents[1] / ".dockerignore"
    patterns = [
        ln.strip()
        for ln in ignore.read_text().splitlines()
        if ln.strip() and not ln.strip().startswith("#")
    ]
    for target in ("media", "media/soundscapes/cafe.ogg", "media/fonts/x.woff2"):
        for pat in patterns:
            for p in {pat, pat.rstrip("/")}:
                assert not fnmatch.fnmatch(target, p), (pat, target)
