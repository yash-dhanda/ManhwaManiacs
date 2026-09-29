"""The both-sided 18+ rule on every Circle surface (backend/08)."""

from __future__ import annotations

import pytest
from sqlalchemy import update

from core.time_utils import utcnow
from database.models import ReadingProfile

SRC = "asurascans"
MATURE_SRC = "18porncomic"  # mature by source
N_KEY = "mature-by-override"


@pytest.fixture
def world(make_user, make_profile):
    u1, u2 = make_user("acct1"), make_user("acct2")
    return {"u1": u1.id, "u2": u2.id, "mk": make_profile}


def _setup(client, as_user, world, db_session, seed_follow, *, c_include, a_open, c_gate=True, which):
    a = world["mk"](world["u1"], "A", mature_content_enabled=a_open)
    c = world["mk"](world["u2"], "C", mature_content_enabled=c_gate)
    ha, hc = as_user(world["u1"], a.id), as_user(world["u2"], c.id)
    r = client.patch(f"/profiles/{c.id}/sharing", json={
        "activity": True, "show_presence": True, "include_mature": c_include}, headers=hc)
    assert r.status_code == 200
    if which == "M":
        src, key = MATURE_SRC, "m-series"
    else:
        src, key = SRC, N_KEY
        seed_follow(world["u2"], c.id, source_id=src, series_key=key, title="N", mature_override=True)
    body = {"source_id": src, "series_key": key, "chapter_key": "ch-1", "chapter_number": 1.0,
            "last_page": 5, "page_count": 5, "is_completed": True, "time_spent_seconds": 60}
    assert client.post("/reader/progress", json=body, headers=hc).status_code in (200, 201)
    # the viewer reads it too (so the Annual has an overlap to consider)
    client.post("/reader/progress", json=body, headers=ha)
    client.patch(f"/profiles/{a.id}/sharing", json={"activity": True}, headers=ha)
    client.post("/reader/progress", json={**body, "chapter_key": "ch-2", "chapter_number": 2.0}, headers=ha)
    client.post("/reader/progress", json={**body, "chapter_key": "ch-2", "chapter_number": 2.0}, headers=hc)
    return a, c, ha, src, key


def surfaces(client, ha, c, src, key):
    """How many of the seven surfaces show the series."""
    from urllib.parse import quote

    n = 0
    feed = client.get("/circle/feed", headers=ha).json()
    n += any(i["series_key"] == key for i in feed["items"])
    m = client.get("/circle/members", headers=ha).json()
    n += bool(m and m[0]["now"])
    n += bool(m and m[0]["last_active_at"])
    page = client.get(f"/circle/members/{c.id}", headers=ha).json()
    n += any(s["series_key"] == key for s in page["reading"])
    sr = client.get("/circle/series", params={"source": src, "series": key}, headers=ha).json()
    n += bool(sr["readers"])
    home = client.get("/home", params={"content_kind": "manga", "tz_offset_minutes": 0}, headers=ha).json()
    n += any(s["items"] for s in home["sections"] if s["type"] in ("circle", "circle_top"))
    annual = client.get(f"/library/annual?year={utcnow().year}&tz_offset_minutes=0", headers=ha).json()
    n += bool((annual["circle"] or {}).get("overlaps"))
    return n, feed, m, page, sr


@pytest.mark.parametrize("which", ["M", "N"])
@pytest.mark.parametrize("c_include", [True, False])
@pytest.mark.parametrize("a_open", [True, False])
def test_matrix(client, as_user, world, db_session, seed_follow, which, c_include, a_open):
    a, c, ha, src, key = _setup(
        client, as_user, world, db_session, seed_follow,
        c_include=c_include, a_open=a_open, which=which)
    n, feed, m, page, sr = surfaces(client, ha, c, src, key)
    if c_include and a_open:
        assert n == 7
    else:
        assert n == 0
        assert feed["items"] == [] and page["reading"] == [] and sr["readers"] == []
        assert m[0]["now"] is None and m[0]["last_active_at"] is None


def test_stored_include_mature_with_closed_own_gate_counts_off(
    client, as_user, world, db_session, seed_follow
):
    a, c, ha, src, key = _setup(
        client, as_user, world, db_session, seed_follow,
        c_include=True, a_open=True, which="M")
    assert surfaces(client, ha, c, src, key)[0] == 7
    db_session.execute(update(ReadingProfile).where(ReadingProfile.id == c.id).values(
        mature_content_enabled=False))
    db_session.commit()
    assert surfaces(client, ha, c, src, key)[0] == 0


@pytest.mark.parametrize("a_open", [True, False])
def test_viewer_override_hides_series_c_shares_as_safe(
    client, as_user, world, db_session, seed_follow, a_open
):
    a = world["mk"](world["u1"], "A", mature_content_enabled=a_open)
    c = world["mk"](world["u2"], "C", mature_content_enabled=True)
    ha, hc = as_user(world["u1"], a.id), as_user(world["u2"], c.id)
    client.patch(f"/profiles/{c.id}/sharing", json={"activity": True, "include_mature": True}, headers=hc)
    seed_follow(world["u2"], c.id, source_id=SRC, series_key="shared-safe", title="S", mature_override=False)
    seed_follow(world["u1"], a.id, source_id=SRC, series_key="shared-safe", title="S", mature_override=True)
    client.post("/reader/progress", json={
        "source_id": SRC, "series_key": "shared-safe", "chapter_key": "ch-1", "chapter_number": 1.0,
        "last_page": 5, "page_count": 5, "is_completed": True}, headers=hc)
    items = client.get("/circle/feed", headers=ha).json()["items"]
    assert bool(items) is a_open
