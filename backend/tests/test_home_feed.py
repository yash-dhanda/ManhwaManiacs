"""``GET /home``: the server-composed feed both skins render."""

from __future__ import annotations

import json
from datetime import datetime, timedelta

import httpx
import pytest

from core.time_utils import utcnow
from database.models import (
    AiResultCache,
    ChapterProgress,
    FollowedSeries,
    SourceHealth,
    SourcePin,
    SourceSeriesCache,
)
from services import ai_desk, deepseek_client, home_service, suggestion_service
from services.home_service import HomeService, reset_home_cache
from services.llm import LLMError
from services.world_recs import WorldRecs
from tests import _home_stubs

SRC, SRC2, NOVEL, MATURE = "hm_manga", "hm_manga2", "hm_novel", "hm_mature"
WORLD: dict = {}
POPULAR: dict = {}


def chapters(n):
    return json.dumps([{"key": f"c{i}", "number": i, "title": f"Ch {i}"} for i in range(1, n + 1)])


def world_item(anilist_id=101, title="Faraway Land", **kw):
    return {
        "anilist_id": anilist_id, "title": title, "alt_titles": [], "format": "Manhwa",
        "country": "KR", "status": "Ongoing", "chapters": 40, "rating": 8.0,
        "genres": ["Fantasy"], "cover_url": "https://s4.anilist.co/x.jpg", "is_adult": False,
        "platforms": [], "anilist_url": None, "why": None, "ambient": None, "palette": None,
        "available": [{"source_id": SRC, "source_name": "Alpha Scans", "series_key": f"w{anilist_id}"}],
        **kw,
    }


@pytest.fixture(autouse=True)
def env(monkeypatch, tmp_path, session_factory):
    _home_stubs.install(monkeypatch)
    monkeypatch.setattr(suggestion_service, "BUDGET_PATH", tmp_path / "s.json")
    monkeypatch.setattr(suggestion_service, "ACCOUNT_BUDGET_PATH", tmp_path / "a.json")
    monkeypatch.setattr(ai_desk, "DESK_BUDGET_PATH", tmp_path / "desk.json")
    monkeypatch.delenv("DEEPSEEK_API_KEY", raising=False)
    monkeypatch.setattr(ai_desk, "run_in_background", lambda key, job: (job(), True)[1])
    monkeypatch.setattr(ai_desk, "open_session", session_factory)
    ai_desk.reset_desk_state()
    reset_home_cache()
    WORLD.clear()
    WORLD.update({"for_you": [], "sections": [], "unavailable_reason": None})
    POPULAR.clear()
    monkeypatch.setattr(WorldRecs, "recommendations", lambda self, **kw: WORLD)
    monkeypatch.setattr(HomeService, "_browse_popular", lambda self, sid: POPULAR.get(sid, []))
    yield
    reset_home_cache()


@pytest.fixture
def acct(make_user, make_profile):
    user = make_user("reader")
    profile = make_profile(user.id, "Riya", mature_content_enabled=True)
    return user.id, profile.id


def get(client, as_user, acct, kind="manga", tz=330, **extra):
    uid, pid = acct
    params = {"content_kind": kind, "tz_offset_minutes": tz, **extra}
    return client.get("/home", params=params, headers=as_user(uid, pid))


def follow(seed_follow, acct, key, title, n=5, **extra):
    uid, pid = acct
    return seed_follow(uid, pid, source_id=extra.pop("source_id", SRC), series_key=key,
                       title=title, known_chapters=chapters(n), **extra)


def read(seed_progress, acct, key, upto, *, source_id=SRC, ago_days=0, **extra):
    uid, pid = acct
    for i in range(1, upto + 1):
        seed_progress(uid, pid, source_id=source_id, series_key=key, chapter_key=f"c{i}",
                      chapter_number=float(i), is_completed=True,
                      last_read_at=utcnow() - timedelta(days=ago_days), **extra)


def types(body):
    return [s["type"] for s in body["sections"]]


def section(body, type_):
    return next(s for s in body["sections"] if s["type"] == type_)


@pytest.fixture
def rich(acct, seed_follow, seed_progress, seed_session, db_session):
    uid, pid = acct
    new = follow(seed_follow, acct, "new-one", "New One", 5, last_new_chapter_at=utcnow())
    almost = follow(seed_follow, acct, "almost", "Almost Done", 4, is_favorite=True)
    old = follow(seed_follow, acct, "old", "Old Times", 10)
    read(seed_progress, acct, "new-one", 2)
    read(seed_progress, acct, "almost", 2, ago_days=2)
    read(seed_progress, acct, "old", 3, ago_days=40)
    seed_session(uid, pid, series_key="new-one", chapter_key="c2")
    db_session.add(SourcePin(user_id=uid, profile_id=pid, source_id=SRC, sort_order=0))
    db_session.add(SourceSeriesCache(source_id=SRC, series_key="new-one", title="New One",
                                     genres=json.dumps(["Action", "Fantasy"]),
                                     description="A hero rises again. Then things happen."))
    db_session.commit()
    return new, almost, old


# --- validation, shape ------------------------------------------------------


def test_validation(client, as_user, acct):
    uid, pid = acct
    h = as_user(uid, pid)
    assert client.get("/home", headers=h).status_code == 422
    assert client.get("/home?tz_offset_minutes=841", headers=h).status_code == 422
    assert client.get("/home?tz_offset_minutes=-721", headers=h).status_code == 422
    assert client.get("/home?tz_offset_minutes=0&content_kind=comics", headers=h).status_code == 422
    assert client.get("/home?tz_offset_minutes=0&refresh=2", headers=h).status_code == 422
    assert client.get("/home?tz_offset_minutes=840", headers=h).status_code == 200


def test_returning_reader_has_every_top_level_field(client, as_user, acct, rich):
    body = get(client, as_user, acct).json()
    assert set(body) == {
        "issue_no", "generated_at", "content_kind", "headline", "deck", "kicker_title",
        "streak", "cover", "also", "sections", "ai",
    }
    assert body["content_kind"] == "manga" and body["issue_no"] >= 1
    cover = body["cover"]
    assert cover["reason"] == "new_chapters" and cover["series_key"] == "new-one"
    assert cover["chapter_key"] == "c3" and cover["new_count"] == 3
    assert set(cover) >= {"source_id", "series_key", "chapter_key", "chapter_number", "last_page",
                          "page_count", "title", "cover_url", "content_kind", "ambient", "palette",
                          "new_count", "paused_days", "recap", "why", "world"}
    assert body["headline"].endswith("chapter 3 of New One.")
    assert set(body["streak"]) >= {"current_days", "longest_days", "at_risk", "last_active_date",
                                   "milestones_seen"}
    order = types(body)
    ranks = [home_service.SECTION_ORDER.index(t) for t in order]
    assert ranks == sorted(ranks)
    assert {"continue", "new_this_week", "almost_there", "where_were_we", "sources", "genres",
            "numbers"} <= set(order)
    assert "popular" not in order  # has history and follows
    cont = section(body, "continue")["items"][0]
    assert {"recap", "ambient", "palette", "nudge", "new_count", "paused_days"} <= set(cont)
    ww = section(body, "where_were_we")["items"]
    assert [i["series_key"] for i in ww] == ["old"] and "recap" in ww[0]
    assert [(i["series_key"], i["chapters_left"]) for i in section(body, "almost_there")["items"]] == [
        ("almost", 2), ("new-one", 3)]
    assert [i["series_key"] for i in section(body, "new_this_week")["items"]] == ["new-one"]
    assert section(body, "numbers")["items"][0]["streak"] == body["streak"]
    assert all(set(s) == {"type", "title", "seed", "note", "fallback", "items", "state",
                          "generated_at"} for s in body["sections"])


# --- gate ------------------------------------------------------------------------


def test_gate_change_recomposes_with_a_valid_cover_story(
    client, as_user, acct, seed_follow, seed_progress
):
    uid, pid = acct
    follow(seed_follow, acct, "mature-key-xyz", "Steamy Tale", 5, mature_override=True)
    read(seed_progress, acct, "mature-key-xyz", 2)
    follow(seed_follow, acct, "safe", "Quiet Days", 1)
    seed_progress(uid, pid, source_id=SRC, series_key="safe", chapter_key="c1", chapter_number=1.0,
                  last_page=3, page_count=10, last_read_at=utcnow() - timedelta(days=1))
    body = get(client, as_user, acct).json()
    assert body["cover"]["title"] == "Steamy Tale" and body["cover"]["reason"] == "new_chapters"
    resp = client.put("/settings", json={"mature_content_enabled": False},
                      headers=as_user(uid, pid))
    assert resp.status_code == 200, resp.text
    closed = get(client, as_user, acct).json()
    assert closed["cover"]["title"] == "Quiet Days" and closed["cover"]["reason"] == "in_progress"
    dumped = json.dumps(closed)
    assert "Steamy Tale" not in dumped and "mature-key-xyz" not in dumped


# --- AI ----------------------------------------------------------------------------


def test_ai_outage_keeps_every_non_ai_section_ready(client, as_user, acct, rich, monkeypatch):
    body = get(client, as_user, acct).json()
    assert body["ai"] == {"available": False, "reason": "not_configured"}
    for t in ("continue", "new_this_week", "almost_there", "where_were_we", "sources", "numbers"):
        assert section(body, t)["state"] == "ready", t
    picked = section(body, "picked")
    assert (picked["state"], picked["fallback"], picked["note"], picked["title"]) == (
        "unavailable", "shelf", "not_configured", "From your shelf")
    assert [i["item"]["title"] for i in picked["items"]] == ["Almost Done"]
    assert body["cover"] and body["headline"]

    WORLD["for_you"] = [world_item()]
    monkeypatch.setenv("DEEPSEEK_API_KEY", "k")

    def boom(*a, **k):
        raise LLMError("nope")

    monkeypatch.setattr(deepseek_client, "complete_json", boom)
    get(client, as_user, acct, refresh=1)
    again = get(client, as_user, acct, refresh=1).json()
    assert again["ai"] == {"available": False, "reason": "ai_failed"}
    assert section(again, "picked")["state"] == "unavailable"
    assert section(again, "picked")["note"] == "ai_failed"
    for t in ("continue", "new_this_week", "almost_there", "where_were_we", "sources", "numbers"):
        assert section(again, t)["state"] == "ready"


def _mock_desk(monkeypatch, answer):
    calls = []

    def handler(request):
        calls.append(request)
        return httpx.Response(200, json={
            "model": "deepseek-flash",
            "choices": [{"finish_reason": "stop", "message": {"content": json.dumps(answer)}}],
            "usage": {"prompt_tokens": 5, "completion_tokens": 5},
        })

    monkeypatch.setenv("DEEPSEEK_API_KEY", "k")
    monkeypatch.setattr(suggestion_service, "_upstream_transport",
                        lambda: httpx.MockTransport(handler))
    return calls


def test_editorial_is_written_once_per_day_on_the_desk_ledger(
    client, as_user, acct, rich, monkeypatch, tmp_path
):
    WORLD["for_you"] = [world_item()]
    WORLD["sections"] = [{"because": {"title": "Old Times", "source_id": SRC, "series_key": "old"},
                          "items": [world_item(102, "Second Land")]}]
    calls = _mock_desk(monkeypatch, {"deck": "A fine night for it.",
                                     "why": {"101": "You like slow burns.", "999": "dropped"}})
    first = get(client, as_user, acct).json()
    assert first["cover"]["why"] is None and "A fine night" not in json.dumps(first)
    assert section(first, "picked")["items"][0]["why"] is None
    second = get(client, as_user, acct).json()
    assert second["deck"] == "A fine night for it."
    assert section(second, "picked")["items"][0]["why"] == "You like slow burns."
    assert "dropped" not in json.dumps(second)
    for _ in range(10):
        get(client, as_user, acct, refresh=1)
    assert len(calls) == 1
    assert deepseek_client.spent_today(ai_desk.DESK_BUDGET_PATH) == 1
    assert deepseek_client.spent_today(suggestion_service.BUDGET_PATH) == 0
    assert not suggestion_service.ACCOUNT_BUDGET_PATH.exists()
    body = json.loads(calls[0].content)
    sent = json.dumps(body)
    assert "Faraway Land" in sent and "DATA" in sent


def test_a_malformed_editorial_is_ai_failed_and_stores_nothing(
    client, as_user, acct, rich, monkeypatch, db_session
):
    WORLD["for_you"] = [world_item()]
    _mock_desk(monkeypatch, {"deck": "x" * 200})
    get(client, as_user, acct)
    body = get(client, as_user, acct, refresh=1).json()
    assert body["ai"]["reason"] == "ai_failed"
    assert db_session.query(AiResultCache).count() == 0


def test_stale_editorial_marks_picked_and_because(client, as_user, acct, rich, db_session):
    uid, pid = acct
    WORLD["for_you"] = [world_item()]
    WORLD["sections"] = [{"because": {"title": "Old Times", "source_id": SRC, "series_key": "old"},
                          "items": [world_item(102, "Second Land")]}]
    day = (utcnow() - timedelta(days=3)).date().isoformat()
    made = utcnow() - timedelta(days=3)
    key = ai_desk.cache_key("home_editorial", str(pid), "1", "manga", day)
    db_session.add(AiResultCache(
        key=key, kind="home_editorial", profile_id=pid, model="m", generated_at=made,
        expires_at=utcnow() + timedelta(days=4),
        payload=json.dumps({"deck": "Old deck.", "why": {"101": "Old reason."}})))
    db_session.commit()
    body = get(client, as_user, acct, tz=0).json()
    picked, because = section(body, "picked"), section(body, "because")
    assert picked["state"] == because["state"] == "stale"
    assert picked["generated_at"] == because["generated_at"] == made.isoformat(timespec="seconds") + "Z"
    assert picked["items"][0]["why"] == "Old reason."
    assert body["ai"]["available"] is False


# --- isolation ----------------------------------------------------------------------


def test_profiles_and_accounts_never_see_each_others_rows(
    client, as_user, make_user, make_profile, acct, rich
):
    uid, pid = acct
    p2 = make_profile(uid, "Second")
    other = make_user("stranger")
    p3 = make_profile(other.id, "Theirs")
    for headers in (as_user(uid, p2.id), as_user(other.id, p3.id), as_user(uid, p3.id)):
        body = client.get("/home?tz_offset_minutes=330", headers=headers).json()
        dumped = json.dumps(body)
        assert "New One" not in dumped and "Old Times" not in dumped
        assert body["cover"] is None or body["cover"]["reason"] == "popular"
        assert body["streak"]["current_days"] == 0
        assert not {"continue", "new_this_week", "numbers", "genres"} & set(types(body))
        assert body["headline"] == "Your first issue starts here."


# --- new / just onboarded ------------------------------------------------------------


def test_new_profile_falls_back_to_the_three_healthiest_non_mature_sources(
    client, as_user, acct, db_session
):
    now = utcnow()
    for sid, failures in ((SRC, 0), (SRC2, 1), ("hm_manga3", 0), ("hm_manga4", 0), (MATURE, 0), (NOVEL, 0)):
        db_session.add(SourceHealth(source_id=sid, consecutive_failures=failures,
                                    last_ok_at=now if failures == 0 else None))
    db_session.commit()
    for sid in (SRC, "hm_manga3", "hm_manga4"):
        POPULAR[sid] = [{"id": f"{sid}-top", "source_id": sid, "title": f"Top of {sid}",
                         "cover_url": f"/sources/{sid}/series/{sid}-top/cover", "genres": []}]
    body = get(client, as_user, acct).json()
    assert types(body) == ["popular", "sources"]
    srcs = section(body, "sources")["items"]
    assert [s["source_id"] for s in srcs] == [SRC, "hm_manga4", "hm_manga3"]
    assert all(s["suggested"] is True and s["mature"] is False for s in srcs)
    assert body["cover"]["reason"] == "popular" and body["cover"]["title"] == f"Top of {SRC}"
    assert body["headline"] == "Your first issue starts here."
    assert body["deck"] == "Follow three series and this page fills itself in."
    assert len(section(body, "popular")["items"]) == 3
    assert body["also"] == []


def test_just_onboarded_gets_first_picks(client, as_user, acct, seed_follow):
    follow(seed_follow, acct, "one", "First Follow", 3)
    follow(seed_follow, acct, "two", "Second Follow", 3)
    body = get(client, as_user, acct).json()
    assert body["cover"]["reason"] == "first_pick" and body["cover"]["chapter_key"] == "c1"
    assert types(body)[0] == "first_picks"
    assert [i["item"]["id"] for i in section(body, "first_picks")["items"]] == ["one", "two"]
    assert body["deck"] == "Chapter 1 is waiting. The rest of your picks are below."
    item = section(body, "first_picks")["items"][0]["item"]
    assert set(item) >= {"id", "source_id", "series_identity", "title", "cover_url", "chapter_count",
                         "genres", "status", "description", "author", "artist", "content_rating",
                         "latest_chapter"}


def test_content_kind_separates_manga_and_novels(client, as_user, acct, seed_follow):
    follow(seed_follow, acct, "mg", "Manga Only", 3)
    follow(seed_follow, acct, "nv", "Novel Only", 3, source_id=NOVEL)
    manga = get(client, as_user, acct, kind="manga").json()
    novel = get(client, as_user, acct, kind="novel").json()
    assert "Novel Only" not in json.dumps(manga) and "Manga Only" in json.dumps(manga)
    assert "Manga Only" not in json.dumps(novel) and "Novel Only" in json.dumps(novel)
    assert novel["content_kind"] == "novel" and novel["cover"]["content_kind"] == "novel"


def test_paused_cover_needs_a_recap_and_reads_its_own_headline(
    client, as_user, acct, seed_follow, seed_progress, db_session, monkeypatch
):
    from database.models import ChapterOcr

    uid, pid = acct
    follow(seed_follow, acct, "gone", "Gone Quiet", 7)
    read(seed_progress, acct, "gone", 6, ago_days=30)
    seed_progress(uid, pid, source_id=SRC, series_key="gone", chapter_key="c7", chapter_number=7.0,
                  last_page=3, page_count=10, last_read_at=utcnow() - timedelta(days=30))
    for i in range(1, 7):
        db_session.add(ChapterOcr(source_id=SRC, series_key="gone", chapter_key=f"c{i}", word_count=9))
    db_session.commit()
    body = get(client, as_user, acct).json()
    # the ask allowance says not_configured, so no recap: the paused rule is skipped
    assert body["cover"] is None or body["cover"]["reason"] != "paused"
    reset_home_cache()
    monkeypatch.setattr(deepseek_client, "is_configured", lambda: True)
    monkeypatch.setattr(deepseek_client, "spent_today", lambda path=None: 0)

    def boom(*a, **k):
        raise LLMError("offline")

    monkeypatch.setattr(deepseek_client, "complete_json", boom)
    body = get(client, as_user, acct).json()
    assert body["cover"]["reason"] == "paused" and body["cover"]["paused_days"] == 30
    assert body["cover"]["recap"]["available"] is True
    assert body["headline"].endswith(": back to Gone Quiet.")
    assert body["deck"] == "You paused 30 days ago at chapter 7. Previously on is ready."


def test_in_progress_cover(client, as_user, acct, seed_follow, seed_progress):
    uid, pid = acct
    follow(seed_follow, acct, "mid", "Midway", 2)
    seed_progress(uid, pid, source_id=SRC, series_key="mid", chapter_key="c2", chapter_number=2.0,
                  last_page=4, page_count=10, last_read_at=utcnow())
    body = get(client, as_user, acct).json()
    assert body["cover"]["reason"] == "in_progress"
    assert body["headline"].endswith(": finish chapter 2. Six pages left.")
    assert body["deck"] == "You were on page 4 of 10 today."


def test_caught_up_uses_the_world_pick(client, as_user, acct, seed_follow, seed_progress):
    follow(seed_follow, acct, "done", "All Read", 2)
    read(seed_progress, acct, "done", 2, ago_days=1)
    WORLD["for_you"] = [world_item()]
    body = get(client, as_user, acct).json()
    assert body["cover"]["reason"] == "caught_up" and body["cover"]["world"]["anilist_id"] == 101
    assert body["cover"]["series_key"] == "w101"
    assert body["headline"].endswith(": you're caught up.")


def test_ai_pick_when_reading_history_has_no_reading_follow(
    client, as_user, acct, seed_progress
):
    read(seed_progress, acct, "unfollowed", 3, ago_days=2)
    WORLD["for_you"] = [world_item(title="Solo Rising")]
    body = get(client, as_user, acct).json()
    assert body["cover"]["reason"] == "ai_pick"
    assert body["headline"].endswith(": start Solo Rising.")


# --- cache -------------------------------------------------------------------------


def test_composed_cache(client, as_user, acct, rich, monkeypatch):
    builds = []
    real = HomeService._build

    def counting(self, *a, **k):
        builds.append(1)
        return real(self, *a, **k)

    monkeypatch.setattr(HomeService, "_build", counting)
    clock = {"now": utcnow()}
    monkeypatch.setattr(home_service, "utcnow", lambda: clock["now"])
    a = get(client, as_user, acct).json()
    clock["now"] += timedelta(seconds=5)
    b = get(client, as_user, acct).json()
    assert a["generated_at"] == b["generated_at"] and len(builds) == 1
    c = get(client, as_user, acct, refresh=1).json()
    assert c["generated_at"] > a["generated_at"] and len(builds) == 2
    get(client, as_user, acct, tz=330 + 60)
    assert len(builds) == 3
    clock["now"] += timedelta(minutes=11)
    get(client, as_user, acct)
    assert len(builds) == 4


def test_live_section_builders_run_per_request_and_sit_in_order(
    client, as_user, acct, rich, monkeypatch
):
    seen = []

    def circle(service, payload):
        seen.append(1)
        return [{"type": "circle", "title": "Circle", "seed": None, "note": None, "fallback": None,
                 "items": [{"n": len(seen)}], "state": "ready", "generated_at": payload["generated_at"]}]

    monkeypatch.setattr(home_service, "LIVE_SECTION_BUILDERS", [circle])
    one = get(client, as_user, acct).json()
    two = get(client, as_user, acct).json()
    assert section(one, "circle")["items"] == [{"n": 1}]
    assert section(two, "circle")["items"] == [{"n": 2}]
    order = types(two)
    assert order.index("circle") > order.index("where_were_we")
    assert order.index("circle") < order.index("sources")


# --- also in this issue ----------------------------------------------------------------


def test_also_in_this_issue(client, as_user, acct, seed_follow, seed_progress):
    follow(seed_follow, acct, "a", "Alpha Tale", 6)
    follow(seed_follow, acct, "b", "Bravo Tale", 6)
    follow(seed_follow, acct, "c", "Charlie Tale", 4)
    follow(seed_follow, acct, "d", "Delta Tale", 3)
    read(seed_progress, acct, "d", 1, ago_days=4)   # 2 new
    read(seed_progress, acct, "a", 2, ago_days=0)   # cover: 4 new, most recent
    read(seed_progress, acct, "b", 4, ago_days=2)   # 2 new
    read(seed_progress, acct, "c", 3, ago_days=3)   # 1 new
    body = get(client, as_user, acct).json()
    assert body["cover"]["series_key"] == "a"
    also = body["also"]
    pairs = [(i["source_id"], i["series_key"]) for i in also]
    assert len(also) == 3 and len(set(pairs)) == 3 and (SRC, "a") not in pairs
    assert also[0]["kind"] == "new_chapters" and also[0]["series_key"] == "b"
    assert also[0]["headline"] == "Two new chapters of Bravo Tale"
    assert {"kind", "source_id", "series_key", "title", "headline", "deck", "ambient"} <= set(also[0])
    assert any(i["headline"] == "One chapter left in Charlie Tale" for i in also)


def test_also_is_empty_below_two_items(client, as_user, acct, seed_follow, seed_progress):
    follow(seed_follow, acct, "only", "Only One", 5)
    read(seed_progress, acct, "only", 2)
    assert get(client, as_user, acct).json()["also"] == []


def test_new_this_week_uses_last_new_chapter_at_not_notifications(
    client, as_user, acct, seed_follow
):
    follow(seed_follow, acct, "quiet", "Quiet Update", 3, notify=False,
           last_new_chapter_at=utcnow() - timedelta(days=2))
    follow(seed_follow, acct, "stale", "Stale Update", 3, last_new_chapter_at=utcnow() - timedelta(days=9))
    body = get(client, as_user, acct).json()
    assert [i["series_key"] for i in section(body, "new_this_week")["items"]] == ["quiet"]
