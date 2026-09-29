"""Streak object, milestones, progress answers, the Annual and ``shareable``."""

from __future__ import annotations

import json
from datetime import datetime

import pytest
from sqlalchemy.exc import OperationalError
from sqlalchemy import func, select

from database.models import SourceSeriesCache, StreakMilestone
from services import annual_service
from services.reading_stats_service import ReadingStatsService

MATURE_SOURCE = "nhentai"
NOW = datetime(2026, 9, 22, 10, 0, 0)


def freeze(monkeypatch, moment: datetime) -> None:
    monkeypatch.setattr("services.reading_stats_service.utcnow", lambda: moment)


@pytest.fixture
def acct(make_user, make_profile):
    user = make_user("streaker")
    return user.id, make_profile(user.id, "Main").id


@pytest.fixture
def h(as_user, acct):
    return as_user(*acct)


def _stats(db, acct, *, tz=0, gate_open=True):
    return ReadingStatsService(
        db, user_id=acct[0], profile_id=acct[1], gate_open=gate_open, tz_offset_minutes=tz
    )


# 1 ---------------------------------------------------------------------------


@pytest.mark.parametrize(
    "tz,longest,current",
    [(0, 2, 2), (330, 1, 1), (-300, 1, 1)],
)
def test_streaks_across_timezone_midnights(
    monkeypatch, db_session, acct, seed_session, tz, longest, current
):
    freeze(monkeypatch, datetime(2026, 9, 22, 10, 0))
    seed_session(*acct, chapter_key="a", started_at=datetime(2026, 9, 20, 0, 30))
    seed_session(*acct, chapter_key="b", started_at=datetime(2026, 9, 21, 23, 30))
    s = _stats(db_session, acct, tz=tz).streak()
    assert s["longest_days"] == longest
    assert s["current_days"] == current


# 2 ---------------------------------------------------------------------------


@pytest.mark.parametrize(
    "now,tz,expected",
    [
        (datetime(2026, 9, 22, 20, 30), 0, True),
        (datetime(2026, 9, 22, 19, 59), 0, False),
        (datetime(2026, 9, 22, 15, 0), 330, True),  # 20:30 local
        (datetime(2026, 9, 22, 15, 0), -300, False),  # 10:00 local
    ],
)
def test_at_risk(monkeypatch, db_session, acct, seed_session, now, tz, expected):
    freeze(monkeypatch, now)
    seed_session(*acct, started_at=datetime(2026, 9, 21, 12, 0))
    assert _stats(db_session, acct, tz=tz).streak()["at_risk"] is expected


def test_at_risk_false_when_read_today_or_no_streak(
    monkeypatch, db_session, acct, seed_session
):
    freeze(monkeypatch, datetime(2026, 9, 22, 21, 0))
    assert _stats(db_session, acct).streak()["at_risk"] is False
    seed_session(*acct, started_at=datetime(2026, 9, 21, 12, 0))
    seed_session(*acct, chapter_key="t", started_at=datetime(2026, 9, 22, 9, 0))
    assert _stats(db_session, acct).streak()["at_risk"] is False


# 3 ---------------------------------------------------------------------------


def test_milestone_once_per_profile(client, as_user, acct, make_profile, make_user, session_factory):
    uid, pid = acct
    h = as_user(uid, pid)
    for _ in range(2):
        assert client.post("/library/statistics/milestones/7/seen", headers=h).status_code == 204
    with session_factory() as s:
        assert s.execute(select(func.count()).select_from(StreakMilestone)).scalar_one() == 1
    assert client.get("/library/statistics", headers=h).json()["streak"]["milestones_seen"] == [7]
    sibling = make_profile(uid, "Sibling").id
    got = client.get("/library/statistics", headers=as_user(uid, sibling)).json()
    assert got["streak"]["milestones_seen"] == []
    r = client.post("/library/statistics/milestones/8/seen", headers=h)
    assert r.status_code == 422 and r.json()["code"] == "invalid_milestone"
    other = make_user("intruder")
    r = client.post("/library/statistics/milestones/30/seen", headers=as_user(other.id, pid))
    assert r.status_code != 204
    with session_factory() as s:
        assert s.execute(select(func.count()).select_from(StreakMilestone)).scalar_one() == 1


# 4 ---------------------------------------------------------------------------


def _push(**kw):
    base = {
        "source_id": "mangadex",
        "series_key": "s1",
        "chapter_key": "c1",
        "chapter_number": 1.0,
        "last_page": 5,
        "page_count": 20,
        "time_spent_seconds": 480,
        "last_read_at": "2026-09-22T09:50:00Z",
    }
    base.update(kw)
    return base


def test_progress_answers_streak_and_today(monkeypatch, client, h, acct, seed_session):
    freeze(monkeypatch, NOW)
    seed_session(*acct, chapter_key="old", started_at=datetime(2026, 9, 17, 12, 0))
    r = client.post("/reader/progress?tz_offset_minutes=0", json=_push(), headers=h)
    assert r.status_code == 200, r.text
    assert r.json()["streak"] == {"current_days": 1, "extended_today": True}
    assert r.json()["today_seconds"] == 480


def test_manual_save_does_not_extend(monkeypatch, client, h, acct, seed_session):
    freeze(monkeypatch, NOW)
    seed_session(*acct, chapter_key="old", started_at=datetime(2026, 9, 17, 12, 0))
    r = client.post("/reader/progress", json=_push(manual=True, time_spent_seconds=0), headers=h)
    assert r.json()["streak"] == {"current_days": 0, "extended_today": False}
    assert r.json()["today_seconds"] == 0


def test_batch_answers_at_top_level(monkeypatch, client, h):
    freeze(monkeypatch, NOW)
    r = client.post("/reader/progress/batch?tz_offset_minutes=0", json=[_push()], headers=h)
    body = r.json()
    assert body["streak"] == {"current_days": 1, "extended_today": True}
    assert body["today_seconds"] == 480


def test_snapshot_failure_never_fails_the_save(monkeypatch, client, h):
    def boom(self):
        raise OperationalError("x", {}, Exception("locked"))

    monkeypatch.setattr(ReadingStatsService, "streak", boom)
    r = client.post("/reader/progress", json=_push(), headers=h)
    assert r.status_code == 200
    assert r.json()["streak"] is None and r.json()["today_seconds"] is None


# 5 ---------------------------------------------------------------------------


def _seed_days(seed_session, acct, year, month, n, **kw):
    for d in range(1, n + 1):
        seed_session(
            *acct, chapter_key=f"{year}-{month}-{d}",
            started_at=datetime(year, month, d, 14, 0), **kw,
        )


def test_annual_shape(monkeypatch, client, h, acct, seed_session):
    freeze(monkeypatch, NOW)
    _seed_days(seed_session, acct, 2026, 9, 8)
    _seed_days(seed_session, acct, 2025, 4, 3)
    _seed_days(seed_session, acct, 2024, 5, 7)
    r = client.get("/library/annual?tz_offset_minutes=0", headers=h)
    assert r.status_code == 200, r.text
    a = r.json()
    for key in (
        "year partial since until recorded_days seconds_read chapters_read pages_read "
        "chapters_by_month top_series genres by_hour longest_streak top_sources "
        "busiest_day firsts_lasts circle top_voices available_years shareable"
    ).split():
        assert key in a, key
    assert a["year"] == 2026 and a["partial"] is True
    assert a["recorded_days"] == 8 and a["chapters_read"] == 8
    assert len(a["chapters_by_month"]) == 12 and a["chapters_by_month"][8] == 8
    assert len(a["by_hour"]) == 24 and a["by_hour"][14]["seconds_read"] == 8 * 600
    assert a["longest_streak"] == {"days": 8, "month": 9, "start": "2026-09-01", "end": "2026-09-08"}
    assert a["circle"] is None and a["top_voices"] == []
    assert a["available_years"] == [2026, 2024]
    assert set(a["shareable"]) == {"genre_weights", "top_series", "art_series", "top_sources"}
    assert a["busiest_day"]["date"] == "2026-09-01"
    assert a["firsts_lasts"]["first"]["read_at"].startswith("2026-09-01")
    past = client.get("/library/annual?year=2024&tz_offset_minutes=0", headers=h).json()
    assert past["partial"] is False and past["recorded_days"] == 7
    r = client.get("/library/annual?year=2027&tz_offset_minutes=0", headers=h)
    assert r.status_code == 422 and r.json()["code"] == "invalid_year"
    assert client.get("/library/annual", headers=h).status_code == 422


# 6 + 7 -----------------------------------------------------------------------


@pytest.fixture
def mixed(db_session, make_user, make_profile, seed_follow, seed_session):
    user = make_user("mixed")
    open_p = make_profile(user.id, "Open", mature_content_enabled=True).id
    closed_p = make_profile(user.id, "Closed").id
    for pid in (open_p, closed_p):
        seed_follow(user.id, pid, source_id=MATURE_SOURCE, series_key="m1",
                    title="Mature Source One", cover_url="https://c/m1.jpg")
        seed_follow(user.id, pid, series_key="adult1", title="Adult Rated",
                    cover_url="https://c/adult1.jpg", content_rating="adult")
        seed_follow(user.id, pid, series_key="over1", title="Overridden",
                    cover_url="https://c/over1.jpg", mature_override=True)
        seed_follow(user.id, pid, series_key="safe1", title="Safe One",
                    cover_url="https://c/safe1.jpg")
        for i, (src, key, hour) in enumerate(
            [(MATURE_SOURCE, "m1", 8), ("mangadex", "adult1", 9), ("mangadex", "over1", 10),
             ("mangadex", "safe1", 12), (MATURE_SOURCE, "m1", 20), ("mangadex", "over1", 21)]
        ):
            seed_session(user.id, pid, source_id=src, series_key=key,
                         chapter_key=f"c{i}", started_at=datetime(2026, 9, 10, hour, 0),
                         duration_seconds=300 if key == "safe1" else 900)
    db_session.add(SourceSeriesCache(
        source_id="mangadex", series_key="safe1", title="Safe One",
        genres=json.dumps(["Action", "Smut", "Ecchi"]),
    ))
    db_session.commit()
    return user.id, open_p, closed_p


MATURE_TITLES = ("Mature Source One", "Adult Rated", "Overridden")
MATURE_COVERS = ("m1.jpg", "adult1.jpg", "over1.jpg")


def _no_mature(blob: str) -> None:
    for word in MATURE_TITLES + MATURE_COVERS + ("Smut", "Ecchi", "smut", "ecchi"):
        assert word not in blob, word


def test_shareable_never_contains_mature(monkeypatch, client, as_user, mixed):
    freeze(monkeypatch, NOW)
    uid, open_p, _ = mixed
    h = as_user(uid, open_p)
    a = client.get("/library/annual?tz_offset_minutes=0", headers=h).json()
    assert {s["title"] for s in a["top_series"]} >= set(MATURE_TITLES)  # gated data
    assert {g["genre"] for g in a["genres"]} >= {"Smut", "Ecchi"}
    _no_mature(json.dumps(a["shareable"]))
    _no_mature(json.dumps(a["busiest_day"]["series"]))
    _no_mature(json.dumps(a["firsts_lasts"]))
    assert a["shareable"]["genre_weights"] == [{"genre": "Action", "weight": 1.0}]
    assert [s["title"] for s in a["shareable"]["top_series"]] == ["Safe One"]
    assert [s["source_id"] for s in a["shareable"]["top_sources"]] == ["mangadex"]
    assert a["shareable"]["top_sources"][0]["share"] == 1.0
    st = client.get("/library/statistics?days=365", headers=h).json()
    _no_mature(json.dumps(st["shareable"]))
    assert st["shareable"]["top_series"][0]["title"] == "Safe One"


def test_gate_closed_excludes_everything_on_serve(monkeypatch, client, as_user, mixed):
    freeze(monkeypatch, NOW)
    uid, _, closed_p = mixed
    a = client.get("/library/annual?tz_offset_minutes=0", headers=as_user(uid, closed_p)).json()
    assert a["chapters_read"] == 1 and a["seconds_read"] == 300
    assert [s["title"] for s in a["top_series"]] == ["Safe One"]
    assert a["available_years"] == []  # one recorded day only


# 8 ---------------------------------------------------------------------------


def test_annual_cache(monkeypatch, client, as_user, mixed, db_session):
    from database.models import ReadingProfile

    freeze(monkeypatch, NOW)
    uid, open_p, _ = mixed
    h = as_user(uid, open_p)
    calls = []
    real = annual_service.AnnualService._compose

    def counting(self, year):
        calls.append(year)
        return real(self, year)

    monkeypatch.setattr(annual_service.AnnualService, "_compose", counting)
    get = lambda q="tz_offset_minutes=0": client.get(f"/library/annual?{q}", headers=h)  # noqa: E731
    get(); get()
    assert len(calls) == 1
    get("year=2025&tz_offset_minutes=0")
    assert len(calls) == 2
    get("tz_offset_minutes=330")
    assert len(calls) == 3
    db_session.get(ReadingProfile, open_p).mature_content_enabled = False
    db_session.commit()
    get()
    assert len(calls) == 4
    freeze(monkeypatch, datetime(2026, 9, 23, 10, 0))
    get()
    assert len(calls) == 5


# 10 --------------------------------------------------------------------------


def test_isolation(monkeypatch, client, as_user, acct, make_profile, make_user, seed_session):
    freeze(monkeypatch, NOW)
    uid, pid = acct
    seed_session(uid, pid, started_at=datetime(2026, 9, 22, 8, 0))
    sibling = make_profile(uid, "Sib").id
    other = make_user("other")
    other_p = make_profile(other.id, "Main").id
    mine = client.get("/library/statistics", headers=as_user(uid, pid)).json()
    assert mine["streak"]["current_days"] == 1
    for h in (as_user(uid, sibling), as_user(other.id, other_p)):
        st = client.get("/library/statistics", headers=h).json()
        assert st["streak"]["current_days"] == 0
        an = client.get("/library/annual?tz_offset_minutes=0", headers=h).json()
        assert an["recorded_days"] == 0 and an["top_voices"] == []
