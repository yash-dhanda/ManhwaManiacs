"""Cover colours: Cinematic ``ambient`` and Glass ``palette`` (backend/01).

Both are computed ONCE per cover, inside the cover proxy, and stored in
``cover_palette`` (30-day TTL). Every series payload then reads them in one
batched query; nothing that lists, searches or browses ever decodes a cover,
and the page-image proxy never analyses a chapter page. World items get the
same colours from a background AniList-cover fetch, 20 per minute.

Spec: cinematic DESIGN.md §2.1.5, glass DESIGN.md §2.1.8 / §15.8.
"""

from __future__ import annotations

import colorsys
import io
import json
import math
import time
from datetime import timedelta
from typing import Any

import httpx
import pytest
from PIL import Image
from sqlalchemy import select

from core.time_utils import utcnow
from database.models import CoverPalette, WorldCatalogCache
from services import cover_colour, world_recs
from services.browse_service import BrowseService
from services.cover_colour import (
    FALLBACK_AMBIENT,
    contrast,
    derive_ambient,
    extract,
)
from services.source_cache_service import SourceCacheService, sweep_cache_retention
from tests.test_cover_resize import _CoverConnector, _cover_get, _noise_jpeg
from tests.test_world_recs import Catalog

SRC = "asurascans"
KEY = "solo-leveling"
COVER = f"/sources/{SRC}/series/{KEY}/cover"


# --- image helpers ------------------------------------------------------------


def _png(img: Image.Image) -> bytes:
    buf = io.BytesIO()
    img.save(buf, "PNG")
    return buf.getvalue()


def _solid(hex_: str, size: tuple[int, int] = (200, 300)) -> bytes:
    return _png(Image.new("RGB", size, hex_))


def _grey_gradient() -> bytes:
    img = Image.new("RGB", (200, 300))
    for y in range(300):
        v = round(255 * y / 299)
        img.paste((v, v, v), (0, y, 200, y + 1))
    return _png(img)


def _hls(hex_: str) -> tuple[float, float, float]:
    r, g, b = (int(hex_[i : i + 2], 16) / 255 for i in (1, 3, 5))
    return colorsys.rgb_to_hls(r, g, b)


def _fmt(rgb: tuple[float, float, float]) -> str:
    return "#" + "".join(f"{round(c * 255):02X}" for c in rgb)


def _oklab_hue(hex_: str) -> float:
    def lin(c: float) -> float:
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

    r, g, b = (lin(int(hex_[i : i + 2], 16) / 255) for i in (1, 3, 5))
    l_ = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ** (1 / 3)
    m_ = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ** (1 / 3)
    s_ = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ** (1 / 3)
    a = 1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_
    bb = 0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_
    return math.degrees(math.atan2(bb, a)) % 360


def _clamp(v: float, lo: float, hi: float) -> float:
    return max(lo, min(hi, v))


# --- F1: ink contrast over 360 hues --------------------------------------------


def test_ink_is_at_least_7_to_1_on_black_for_every_hue_and_saturation():
    started = time.perf_counter()
    failures = [
        (h, s)
        for h in range(360)
        for s in (0.08, 0.35, 0.60, 0.90)
        if contrast(derive_ambient(h / 360, s)["ink"], "#000000") < 7.0
    ]
    elapsed = time.perf_counter() - started
    assert not failures, failures[:10]
    assert elapsed < 1.0, f"1,440 cases took {elapsed:.3f} s"


# --- F2: role rules ---------------------------------------------------------------


def test_role_rules_on_a_saturated_red_cover():
    h, _l, s = _hls("#D0202A")
    ambient, _palette = extract(_solid("#D0202A"))

    assert ambient["duo"] == _fmt(colorsys.hls_to_rgb(h, 0.62, _clamp(s, 0.45, 0.90)))
    _th, tl, ts = _hls(ambient["tint"])
    assert abs(tl - 0.06) <= 0.005
    assert abs(ts - min(s, 0.35)) <= 0.03
    ih, il, _is = _hls(ambient["ink"])
    assert il >= 0.78 - 0.005 and contrast(ambient["ink"], "#000000") >= 7.0
    for value in ambient.values():
        assert value == value.upper() and len(value) == 7 and value[0] == "#"


# --- F3: greyscale and undecodable -------------------------------------------------


@pytest.mark.parametrize(
    "data",
    [_grey_gradient(), _solid("#000000"), _solid("#FFFFFF")],
    ids=["grey-gradient", "black", "white"],
)
def test_greyscale_covers_get_the_fallbacks(data):
    ambient, _palette = extract(data)
    assert ambient == {"duo": "#B8B2A4", "tint": "#0E0D0B", "ink": "#F3F0E8"}
    assert ambient == FALLBACK_AMBIENT


def test_a_grey_gradient_palette_keeps_the_two_most_populous_greys():
    _ambient, palette = extract(_grey_gradient())
    assert len(palette["a"]) == 2
    for hex_ in palette["a"]:
        _h, _l, s = _hls(hex_)
        assert s < 0.05


@pytest.mark.parametrize(
    "data",
    [b"\x00\x01not an image at all", b"<!doctype html><html><body>502</body></html>", b""],
    ids=["junk", "html", "empty"],
)
def test_undecodable_bytes_extract_to_none(data):
    assert extract(data) is None


# --- F4: glass palette --------------------------------------------------------------


def test_palette_ranks_blue_before_orange_on_a_60_40_cover():
    img = Image.new("RGB", (200, 300), "#1E5BFF")
    img.paste(Image.new("RGB", (200, 120), "#FF8A3D"), (0, 180))
    _ambient, palette = extract(_png(img))

    a = palette["a"]
    assert 2 <= len(a) <= 3
    assert 230 <= _oklab_hue(a[0]) <= 290, a  # blue sector
    assert 20 <= _oklab_hue(a[1]) <= 90, a  # orange sector
    assert 0 <= palette["l"] <= palette["lMax"] <= 1


def test_a_dark_cover_with_one_white_patch_has_lmax_1():
    img = Image.new("RGB", (96, 144), "#000000")
    img.paste(Image.new("RGB", (48, 48), "#FFFFFF"), (24, 48))
    _ambient, palette = extract(_png(img))

    assert palette["lMax"] == 1.0
    assert 0.1 <= palette["l"] <= 0.2


# --- F5: the cover proxy computes once -------------------------------------------


@pytest.fixture
def cover():
    return _CoverConnector(_noise_jpeg())


@pytest.fixture
def count_extract(monkeypatch):
    calls = {"n": 0}
    real = cover_colour.extract

    def _counting(data):
        calls["n"] += 1
        return real(data)

    monkeypatch.setattr(cover_colour, "extract", _counting)
    return calls


def _rows(db_session) -> list[CoverPalette]:
    db_session.expire_all()
    return list(db_session.execute(select(CoverPalette)).scalars())


def test_first_sized_serve_computes_and_the_second_does_not(
    client, cover, count_extract, db_session
):
    first = _cover_get(client, cover, COVER, params={"w": 240})
    assert first.status_code == 200
    rows = _rows(db_session)
    assert [(r.source_id, r.series_key) for r in rows] == [(SRC, KEY)]
    assert set(json.loads(rows[0].ambient)) == {"duo", "tint", "ink"}
    assert set(json.loads(rows[0].palette)) == {"a", "l", "lMax"}
    assert count_extract["n"] == 1

    again = _cover_get(client, cover, COVER, params={"w": 240})
    other_width = _cover_get(client, cover, COVER, params={"w": 96})
    assert again.status_code == other_width.status_code == 200
    assert count_extract["n"] == 1
    assert len(_rows(db_session)) == 1


def test_an_unsized_serve_also_computes(client, cover, count_extract, db_session):
    response = _cover_get(client, cover, COVER)
    assert response.status_code == 200 and response.content == cover._data
    assert count_extract["n"] == 1
    assert len(_rows(db_session)) == 1


def test_a_colour_failure_never_breaks_the_cover(client, cover, monkeypatch, db_session):
    def _boom(data):
        raise RuntimeError("extractor exploded")

    monkeypatch.setattr(cover_colour, "extract", _boom)
    sized = _cover_get(client, cover, COVER, params={"w": 240})
    unsized = _cover_get(client, cover, COVER)
    assert sized.status_code == unsized.status_code == 200
    assert _rows(db_session) == []


def test_undecodable_cover_bytes_store_nothing(client, db_session):
    html = _CoverConnector(b"<!doctype html><p>blocked</p>")
    response = _cover_get(client, html, COVER)
    assert response.status_code in (200, 502)
    assert _rows(db_session) == []


# --- F6: TTL ------------------------------------------------------------------------------


def _seed_colours(db_session, *, source_id=SRC, series_key=KEY, age_days=0, duo="#AA3344"):
    ambient = {"duo": duo, "tint": "#140A0B", "ink": "#E6B3BA"}
    palette = {"a": ["#AA3344", "#223366"], "l": 0.12, "lMax": 0.8}
    db_session.merge(
        CoverPalette(
            source_id=source_id,
            series_key=series_key,
            ambient=json.dumps(ambient),
            palette=json.dumps(palette),
            computed_at=utcnow() - timedelta(days=age_days),
        )
    )
    db_session.commit()
    return ambient, palette


@pytest.fixture
def reader_profile(make_user, make_profile, seed_follow):
    def _make(*, mature: bool = False, name: str = "reader", **follow: Any):
        user = make_user(name)
        profile = make_profile(user.id, "Main", mature_content_enabled=mature)
        seed_follow(user.id, profile.id, source_id=SRC, series_key=KEY, **follow)
        return user.id, profile.id

    return _make


def test_an_expired_row_is_served_as_null_then_recomputed_then_swept(
    client, as_user, cover, reader_profile, db_session
):
    uid, pid = reader_profile()
    _seed_colours(db_session, age_days=31)

    items = client.get("/library/series", headers=as_user(uid, pid)).json()["items"]
    assert items[0]["ambient"] is None and items[0]["palette"] is None

    _cover_get(client, cover, COVER, params={"w": 96}, headers=as_user(uid, pid))
    (row,) = _rows(db_session)
    assert utcnow() - row.computed_at < timedelta(minutes=1)
    items = client.get("/library/series", headers=as_user(uid, pid)).json()["items"]
    assert items[0]["ambient"] == json.loads(row.ambient)
    assert items[0]["palette"] == json.loads(row.palette)

    _seed_colours(db_session, age_days=31)
    removed = sweep_cache_retention(db_session)
    assert removed.get("cover_palette", {}).get("aged out") == 1
    assert _rows(db_session) == []


# --- F7: lists never decode -------------------------------------------------------------


@pytest.fixture
def no_decoding(monkeypatch):
    def _boom(*a, **k):
        raise AssertionError("a list endpoint decoded a cover")

    monkeypatch.setattr(cover_colour, "extract", _boom)
    monkeypatch.setattr(cover_colour, "_decode", _boom)


def test_lists_serve_stored_colours_without_decoding(
    client, as_user, reader_profile, db_session, monkeypatch, no_decoding
):
    uid, pid = reader_profile()
    ambient, palette = _seed_colours(db_session)
    headers = as_user(uid, pid)

    listing = client.get("/library/series", headers=headers)
    assert listing.status_code == 200
    assert listing.json()["items"][0]["ambient"] == ambient
    assert listing.json()["items"][0]["palette"] == palette

    assert client.get("/library/continue-reading", headers=headers).status_code == 200

    monkeypatch.setattr(
        SourceCacheService,
        "get_browse_page",
        lambda self, source_id, **kw: {
            "items": [
                {"id": KEY, "source_id": source_id, "title": "Solo"},
                {"id": "never-served", "source_id": source_id, "title": "Other"},
            ]
        },
    )
    browse = client.get(f"/sources/{SRC}/series", headers=headers)
    assert browse.status_code == 200, browse.text
    first, second = browse.json()["items"]
    assert first["ambient"] == ambient and first["palette"] == palette
    assert second["ambient"] is None and second["palette"] is None

    async def _search(self, query, **kw):
        item = {"kind": "source", "source": SRC, "series_id": KEY, "title": "Solo"}
        return {"items": [item], "groups": [{"source": SRC, "items": [item]}]}

    monkeypatch.setattr(BrowseService, "federated_search", _search)
    search = client.get("/sources/search", params={"q": "solo"}, headers=headers)
    assert search.status_code == 200, search.text
    assert search.json()["items"][0]["ambient"] == ambient


# --- F8: no page analysis ---------------------------------------------------------------


def test_the_page_image_proxy_never_analyses_a_page(client, monkeypatch, db_session):
    page = _solid("#D0202A", (80, 120))

    def _boom(*a, **k):
        raise AssertionError("page image analysed")

    monkeypatch.setattr(cover_colour, "extract", _boom)
    monkeypatch.setattr(cover_colour, "ensure_cover_colours", _boom)
    monkeypatch.setattr(
        BrowseService, "resolve_page_image", lambda self, s, p: ("image/png", page)
    )

    response = client.get(f"/sources/{SRC}/pages/p1/image")
    assert response.status_code == 200 and response.content == page
    sized = client.get(f"/sources/{SRC}/pages/p1/image", params={"w": 360})
    assert sized.status_code == 200
    assert _rows(db_session) == []


# --- F9: profile isolation and the gate ---------------------------------------------


def test_a_gated_profile_never_receives_a_mature_rows_colours(
    client, as_user, make_user, make_profile, seed_follow, db_session
):
    user = make_user("household")
    shut = make_profile(user.id, "SFW", mature_content_enabled=False)
    open_ = make_profile(user.id, "NSFW", mature_content_enabled=True)
    for pid in (shut.id, open_.id):
        seed_follow(user.id, pid, source_id=SRC, series_key=KEY, mature_override=True)
    ambient, _palette = _seed_colours(db_session)

    closed = client.get("/library/series", headers=as_user(user.id, shut.id))
    assert closed.status_code == 200
    assert closed.json()["items"] == []
    assert ambient["duo"] not in closed.text

    opened = client.get("/library/series", headers=as_user(user.id, open_.id)).json()
    assert [i["series_key"] for i in opened["items"]] == [KEY]
    assert opened["items"][0]["ambient"] == ambient


def test_cover_palette_has_no_user_profile_or_gate_column():
    columns = {c.name for c in CoverPalette.__table__.columns}
    assert columns == {"source_id", "series_key", "ambient", "palette", "computed_at"}


# --- F10: WorldItem gating on serve -------------------------------------------------


LEWD_ID, BLADE_ID, SOLO_ID = 4, 2, 3


@pytest.fixture
def world_catalog(monkeypatch):
    fake = Catalog()
    monkeypatch.setattr(world_recs, "_transport", lambda: httpx.MockTransport(fake.handler))
    return fake


def _world_reader(make_user, make_profile, seed_follow, seed_progress, *, mature: bool):
    user = make_user("worldreader-" + ("open" if mature else "shut"))
    profile = make_profile(user.id, "Main", mature_content_enabled=mature)
    seed_follow(
        user.id, profile.id, source_id="asurascans",
        series_key="nano-machine-6f7fe6eb", title="Nano Machine",
    )
    for n in (1, 2, 3):
        seed_progress(
            user.id, profile.id, source_id="asurascans",
            series_key="nano-machine-6f7fe6eb", chapter_key=f"nano-machine-6f7fe6eb:{n}",
        )
    return user.id, profile.id


def _seed_world_colour(db_session, anilist_id: int, duo: str) -> dict[str, Any]:
    value = {
        "ambient": {"duo": duo, "tint": "#0F0A0B", "ink": "#EAC0C4"},
        "palette": {"a": [duo], "l": 0.2, "lMax": 0.7},
    }
    db_session.merge(
        WorldCatalogCache(
            key=f"al:colour:{anilist_id}", payload=json.dumps(value), fetched_at=utcnow()
        )
    )
    db_session.commit()
    return value


def test_world_items_carry_colours_and_the_gate_holds_on_serve(
    client, as_user, world_catalog, make_user, make_profile, seed_follow, seed_progress,
    db_session,
):
    lewd = _seed_world_colour(db_session, LEWD_ID, "#C21E7A")
    blade = _seed_world_colour(db_session, BLADE_ID, "#3A8F55")

    uid, pid = _world_reader(make_user, make_profile, seed_follow, seed_progress, mature=False)
    shut = client.get("/library/world/recommendations", headers=as_user(uid, pid))
    assert shut.status_code == 200, shut.text
    by_id = {i["anilist_id"]: i for i in shut.json()["for_you"]}
    assert LEWD_ID not in by_id
    assert lewd["ambient"]["duo"] not in shut.text
    assert by_id[BLADE_ID]["ambient"] == blade["ambient"]
    assert by_id[BLADE_ID]["palette"] == blade["palette"]
    # A miss is null in the payload and queued for the background fetch; the
    # hidden item is never queued.
    assert by_id[SOLO_ID]["ambient"] is None and by_id[SOLO_ID]["palette"] is None
    assert cover_colour.pending_anilist_ids() == {SOLO_ID}

    uid2, pid2 = _world_reader(make_user, make_profile, seed_follow, seed_progress, mature=True)
    opened = client.get("/library/world/recommendations", headers=as_user(uid2, pid2)).json()
    by_id = {i["anilist_id"]: i for i in opened["for_you"]}
    assert by_id[LEWD_ID]["ambient"] == lewd["ambient"]
    assert by_id[LEWD_ID]["palette"] == lewd["palette"]


# --- F11: 20 per minute -----------------------------------------------------------------


def test_the_anilist_worker_starts_at_most_20_fetches_a_minute(db_session):
    now = {"t": 0.0}
    fetched: list[tuple[str, float]] = []
    red = _solid("#D0202A", (60, 90))

    def fetch(url: str) -> bytes | None:
        fetched.append((url, now["t"]))
        now["t"] += 0.05
        return red

    def sleep(seconds: float) -> None:
        now["t"] += max(0.0, seconds)

    for i in range(1, 26):
        assert cover_colour.enqueue_anilist_colour(i, f"https://s4.anilist.co/file/{i}.jpg")
    assert not cover_colour.enqueue_anilist_colour(1, "https://s4.anilist.co/file/1.jpg")
    for bad in (
        "https://evil.example.com/cover.jpg",
        "http://s4.anilist.co/file/x.jpg",
        "https://s4.anilist.co.evil.example/x.jpg",
    ):
        assert not cover_colour.enqueue_anilist_colour(999, bad)

    done = cover_colour.drain_anilist_colours(
        db_session, fetch=fetch, clock=lambda: now["t"], sleep=sleep, max_items=100
    )

    assert done == 25
    assert len(fetched) == 25
    assert sum(1 for _, t in fetched if t < 60) == 20
    assert all(url.startswith("https://s4.anilist.co/") for url, _ in fetched)
    keys = set(
        db_session.execute(
            select(WorldCatalogCache.key).where(WorldCatalogCache.key.like("al:colour:%"))
        ).scalars()
    )
    assert keys == {f"al:colour:{i}" for i in range(1, 26)}
    assert cover_colour.pending_anilist_ids() == set()


def test_a_failed_or_undecodable_fetch_writes_nothing(db_session):
    cover_colour.enqueue_anilist_colour(7, "https://s4.anilist.co/file/7.jpg")
    cover_colour.enqueue_anilist_colour(8, "https://s4.anilist.co/file/8.jpg")
    answers = {"7": None, "8": b"<html>nope</html>"}

    done = cover_colour.drain_anilist_colours(
        db_session,
        fetch=lambda url: answers[url.rsplit("/", 1)[1].split(".")[0]],
        clock=time.monotonic,
        sleep=lambda s: None,
        max_items=10,
    )
    assert done == 2
    assert db_session.execute(select(WorldCatalogCache)).first() is None
    assert cover_colour.pending_anilist_ids() == set()
