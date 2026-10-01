"""Circle core (backend/08): sharing switches, activity record, S, feed, presence."""

from __future__ import annotations

from datetime import timedelta

import pytest
from sqlalchemy import select, update

from core.time_utils import utcnow
from database.models import (
    ChapterProgress,
    CircleEvent,
    CircleHiddenSeries,
    ReadingProfile,
    User,
)

SRC = "asurascans"  # an installed, non-mature manga source
X = "series-x"
Y = "series-y"


@pytest.fixture
def world(make_user, make_profile, db_session):
    u1, u2, u3 = make_user("acct1"), make_user("acct2"), make_user("acct3")
    a = make_profile(u1.id, "A")
    b = make_profile(u1.id, "B")
    c = make_profile(u2.id, "C")
    d = make_profile(u3.id, "D")
    return {"u1": u1.id, "u2": u2.id, "u3": u3.id, "a": a.id, "b": b.id, "c": c.id, "d": d.id}


@pytest.fixture
def H(as_user, world):
    def make(who: str) -> dict:
        u = {"a": "u1", "b": "u1", "c": "u2", "d": "u3"}[who]
        return as_user(world[u], world[who])

    return make


def share(client, H, world, who, **body):
    body = {"activity": True, **body}
    r = client.patch(f"/profiles/{world[who]}/sharing", json=body, headers=H(who))
    assert r.status_code == 200, r.text
    return r.json()


def push(client, H, who, series=X, ch=1, done=True, **kw):
    body = {
        "source_id": SRC, "series_key": series, "chapter_key": f"ch-{ch}",
        "chapter_number": float(ch), "last_page": 5, "page_count": 5,
        "is_completed": done, "time_spent_seconds": 60, **kw,
    }
    r = client.post("/reader/progress", json=body, headers=H(who))
    assert r.status_code in (200, 201), r.text
    return r


def feed(client, H, who="a", **params):
    r = client.get("/circle/feed", params=params, headers=H(who))
    assert r.status_code == 200, r.text
    return r.json()


def backdate_since(db_session, pid, **delta):
    db_session.execute(
        update(ReadingProfile)
        .where(ReadingProfile.id == pid)
        .values(share_activity_since=utcnow() - timedelta(days=1))
    )
    db_session.commit()


def test_sharing_defaults(client, H, world):
    r = client.get(f"/profiles/{world['a']}/sharing", headers=H("a"))
    assert r.json() == {
        "activity": False, "reactions": True, "shelves": True, "recommendations": True,
        "include_mature": False, "show_presence": False, "share_streak": False,
        "excluded_series": [],
    }


def test_sharing_patch_partial_and_ownership(client, H, world):
    r = client.patch(f"/profiles/{world['a']}/sharing", json={"reactions": False}, headers=H("a"))
    body = r.json()
    assert body["reactions"] is False and body["activity"] is False
    assert client.patch(
        f"/profiles/{world['a']}/sharing", json={"nope": 1}, headers=H("a")
    ).status_code == 422
    for verb in ("get", "patch"):
        kw = {"json": {}} if verb == "patch" else {}
        assert getattr(client, verb)(
            f"/profiles/{world['c']}/sharing", headers=H("a"), **kw
        ).status_code == 404
    r = client.patch(
        f"/profiles/{world['a']}/sharing",
        json={"excluded_series": [
            {"source_id": SRC, "series_key": "a%2Fb"},
            {"source_id": SRC, "series_key": "z", "title": "Zed"},
        ]},
        headers=H("a"),
    )
    ex = {e["series_key"]: e["title"] for e in r.json()["excluded_series"]}
    assert ex == {"a/b": "a/b", "z": "Zed"}
    r = client.patch(
        f"/profiles/{world['a']}/sharing", json={"excluded_series": []}, headers=H("a")
    )
    assert r.json()["excluded_series"] == []


def test_sharing_patch_keeps_hidden_titles_and_order(client, H, world):
    url = f"/profiles/{world['a']}/sharing"
    client.patch(url, json={"excluded_series": [{"source_id": SRC, "series_key": "a1", "title": "Ay"}]}, headers=H("a"))
    r = client.patch(url, json={"excluded_series": [
        {"source_id": SRC, "series_key": "m", "title": "Em"},
        {"source_id": SRC, "series_key": "a1"},
    ]}, headers=H("a"))
    ex = r.json()["excluded_series"]
    assert {e["series_key"]: e["title"] for e in ex} == {"a1": "Ay", "m": "Em"}
    assert [e["series_key"] for e in ex] == ["m", "a1"]  # newest first: a1 kept its place


def test_no_retroactive_sharing(client, H, world):
    push(client, H, "c", ch=1)  # sharing off: nothing recorded
    share(client, H, world, "c")
    push(client, H, "c", ch=2)
    items = feed(client, H)["items"]
    assert [(i["kind"], i["chapter_number"]) for i in items] == [("finished_chapter", 2.0)]
    client.patch(f"/profiles/{world['c']}/sharing", json={"activity": False}, headers=H("c"))
    assert feed(client, H)["items"] == []
    share(client, H, world, "c")
    assert feed(client, H)["items"] == []


def test_isolation_across_accounts_and_profiles(client, H, world, seed_follow):
    seed_follow(world["u2"], world["c"], source_id=SRC, series_key="private-y", title="SECRETTITLE")
    share(client, H, world, "b")
    share(client, H, world, "c")
    push(client, H, "c")
    push(client, H, "b", series=Y)
    r = client.get("/circle/members", headers=H("a"))
    assert {m["profile_id"] for m in r.json()} == {world["b"], world["c"]}
    everything = r.text + str(feed(client, H))
    everything += client.get(f"/circle/members/{world['c']}", headers=H("a")).text
    assert "SECRETTITLE" not in everything and "private-y" not in everything
    client.patch(f"/profiles/{world['b']}/sharing", json={"activity": False}, headers=H("b"))
    assert {m["profile_id"] for m in client.get("/circle/members", headers=H("a")).json()} == {world["c"]}
    assert all(i["actor"]["profile_id"] == world["c"] for i in feed(client, H)["items"])


def test_reciprocity_viewer_shares_nothing(client, H, world):
    share(client, H, world, "c")
    push(client, H, "c")
    assert client.get("/circle/members", headers=H("a")).json()[0]["profile_id"] == world["c"]
    assert len(feed(client, H)["items"]) == 2  # started + finished_chapter
    r = client.get("/circle/series", params={"source": SRC, "series": X}, headers=H("a"))
    assert [x["profile"]["profile_id"] for x in r.json()["readers"]] == [world["c"]]


def test_hidden_series_vanishes_everywhere(client, H, world, db_session):
    share(client, H, world, "c", show_presence=True)
    push(client, H, "c")
    def visible():
        m = client.get("/circle/members", headers=H("a")).json()[0]
        page = client.get(f"/circle/members/{world['c']}", headers=H("a")).json()
        sr = client.get("/circle/series", params={"source": SRC, "series": X}, headers=H("a")).json()
        home = client.get("/home", params={"content_kind": "manga", "tz_offset_minutes": 0}, headers=H("a")).json()
        circle = [s for s in home["sections"] if s["type"] == "circle"][0]
        return (bool(feed(client, H)["items"]), m["now"] is not None, bool(page["reading"]),
                bool(sr["readers"]), bool(circle["items"]))
    assert all(visible())
    client.patch(f"/profiles/{world['c']}/sharing", json={"excluded_series": [{"source_id": SRC, "series_key": X}]}, headers=H("c"))
    assert not any(visible())
    client.patch(f"/profiles/{world['c']}/sharing", json={"excluded_series": []}, headers=H("c"))
    assert all(visible())


def test_presence(client, H, world, db_session):
    share(client, H, world, "c")
    push(client, H, "c")
    m = client.get("/circle/members", headers=H("a")).json()[0]
    assert m["now"] is None and m["last_active_at"] is not None
    share(client, H, world, "c", show_presence=True)
    m = client.get("/circle/members", headers=H("a")).json()[0]
    assert m["now"]["since"] and m["now"]["series_key"] == X and m["now"]["title"] == X
    assert m["now"]["chapter_number"] == 1.0
    backdate_since(db_session, world["c"])
    db_session.execute(update(ChapterProgress).where(ChapterProgress.profile_id == world["c"]).values(
        last_read_at=utcnow() - timedelta(minutes=16)))
    db_session.commit()
    m = client.get("/circle/members", headers=H("a")).json()[0]
    assert m["now"] is None and m["last_active_at"] is not None
    client.patch(f"/profiles/{world['c']}/sharing", json={"excluded_series": [{"source_id": SRC, "series_key": X}]}, headers=H("c"))
    m = client.get("/circle/members", headers=H("a")).json()[0]
    assert m["now"] is None and m["last_active_at"] is None


def test_streak_only_when_shared(client, H, world):
    share(client, H, world, "c")
    push(client, H, "c")
    assert client.get("/circle/members", headers=H("a")).json()[0]["streak"] is None
    share(client, H, world, "c", share_streak=True)
    s = client.get("/circle/members", headers=H("a")).json()[0]["streak"]
    assert s["current_days"] == 1 and s["alive_today"] is True


def test_member_page(client, H, world, db_session):
    r = client.get(f"/circle/members/{world['c']}", headers=H("a"))
    assert r.status_code == 404 and r.json()["code"] == "circle_member_not_sharing"
    share(client, H, world, "a")
    assert client.get(f"/circle/members/{world['a']}", headers=H("a")).status_code == 404
    share(client, H, world, "d")
    db_session.execute(update(User).where(User.id == world["u3"]).values(is_active=False))
    db_session.commit()
    assert client.get(f"/circle/members/{world['d']}", headers=H("a")).status_code == 404
    share(client, H, world, "c")
    push(client, H, "c", series=X)
    push(client, H, "c", series=Y)
    page = client.get(f"/circle/members/{world['c']}", headers=H("a")).json()
    assert {s["series_key"] for s in page["reading"]} == {X, Y}
    assert all("chapter_number" not in s and "last_page" not in s for s in page["reading"])
    assert page["shelves"] == [] and page["finished"] == []
    db_session.add(CircleEvent(
        user_id=world["u2"], profile_id=world["c"], kind="finished_series", source_id=SRC,
        series_key=X, title="X", created_at=utcnow() + timedelta(seconds=5)))
    db_session.commit()
    page = client.get(f"/circle/members/{world['c']}", headers=H("a")).json()
    assert {s["series_key"] for s in page["reading"]} == {Y}
    assert [s["series_key"] for s in page["finished"]] == [X]


def test_feed_paging_and_filters(client, H, world, db_session):
    share(client, H, world, "c")
    share(client, H, world, "b")
    backdate_since(db_session, world["c"])
    backdate_since(db_session, world["b"])
    base = utcnow() - timedelta(hours=5)
    for i in range(120):
        db_session.add(CircleEvent(
            user_id=world["u2"], profile_id=world["c"], kind="finished_chapter", source_id=SRC,
            series_key=X, chapter_key=f"c{i}", chapter_number=float(i), title="X",
            created_at=base + timedelta(seconds=i // 2)))  # pairs share a timestamp
    db_session.add(CircleEvent(
        user_id=world["u2"], profile_id=world["c"], kind="reacted", source_id=SRC,
        series_key=X, reaction="fire", title="X", created_at=base + timedelta(hours=1)))
    db_session.add(CircleEvent(
        user_id=world["u1"], profile_id=world["b"], kind="started", source_id=SRC,
        series_key=Y, title="Y", created_at=base + timedelta(hours=2)))
    db_session.commit()
    ids, cursor, sizes = [], None, []
    while True:
        page = feed(client, H, kind="reading", profile_id=world["c"], **({"cursor": cursor} if cursor else {}))
        sizes.append(len(page["items"]))
        ids += [i["id"] for i in page["items"]]
        cursor = page["next_cursor"]
        if not cursor:
            break
    assert sizes == [50, 50, 20] and len(set(ids)) == 120
    keys = [(i["created_at"], i["id"]) for i in feed(client, H, limit=100)["items"]]
    assert keys == sorted(keys, reverse=True)
    assert {i["kind"] for i in feed(client, H, kind="reaction")["items"]} == {"reacted"}
    assert "reacted" not in {i["kind"] for i in feed(client, H, kind="reading", limit=100)["items"]}
    assert {i["actor"]["profile_id"] for i in feed(client, H, profile_id=world["b"])["items"]} == {world["b"]}
    assert feed(client, H, profile_id=world["a"]) == {"items": [], "next_cursor": None}
    r = client.get("/circle/feed", params={"cursor": "garbage"}, headers=H("a"))
    assert r.status_code == 422 and r.json()["code"] == "invalid_cursor"
    assert client.get("/circle/feed", params={"kind": "letter"}, headers=H("a")).status_code == 422
    it = feed(client, H, kind="reading", profile_id=world["b"])["items"][0]
    assert it["followed_by_viewer"] is False and it["content_kind"] == "manga"


def test_events_recording_rules(client, H, world, db_session, seed_follow):
    share(client, H, world, "c")
    push(client, H, "c", ch=1, manual=True)
    assert db_session.execute(select(CircleEvent)).first() is None
    push(client, H, "c", ch=2)
    push(client, H, "c", ch=2)  # re-completing: nothing new
    kinds = [e.kind for e in db_session.execute(select(CircleEvent).order_by(CircleEvent.id)).scalars()]
    assert kinds == ["finished_chapter"]  # ch-1 row (manual) existed, so no `started` for ch-2
    f = seed_follow(world["u2"], world["c"], source_id=SRC, series_key=X, title="Ex")
    r = client.patch(f"/library/series/{f.id}", json={"reading_status": "completed"}, headers=H("c"))
    assert r.status_code == 200, r.text
    client.patch(f"/library/series/{f.id}", json={"reading_status": "completed"}, headers=H("c"))
    db_session.expire_all()
    kinds = [e.kind for e in db_session.execute(select(CircleEvent).order_by(CircleEvent.id)).scalars()]
    assert kinds == ["finished_chapter", "finished_series"]


def test_delete_activity(client, H, world):
    share(client, H, world, "c")
    push(client, H, "c")
    assert feed(client, H)["items"]
    assert client.delete("/circle/activity", headers=H("c")).status_code == 204
    assert client.delete("/circle/activity", headers=H("c")).status_code == 204
    assert feed(client, H)["items"] == []


def test_home_sections(client, H, world):
    share(client, H, world, "c")
    share(client, H, world, "b")
    push(client, H, "c", series=X)
    push(client, H, "b", series=X)
    push(client, H, "c", series=Y)
    def sections():
        home = client.get("/home", params={"content_kind": "manga", "tz_offset_minutes": 0}, headers=H("a")).json()
        return {s["type"]: s for s in home["sections"]}
    s = sections()
    assert s["circle"]["title"] == "From the Circle" and s["circle"]["state"] == "ready"
    assert len(s["circle"]["items"]) == 3  # one per (member, series)
    top = s["circle_top"]["items"]
    assert [t["rank"] for t in top] == [1, 2] and top[0]["series"]["series_key"] == X
    order = list(s)
    assert order.index("circle") < order.index("circle_top")
    for who in ("b", "c"):
        client.patch(f"/profiles/{world[who]}/sharing", json={"activity": False}, headers=H(who))
    s = sections()
    assert s["circle"]["state"] == "empty" and s["circle_top"]["state"] == "empty"
    assert s["circle"]["items"] == []


def test_annual_block(client, H, world, db_session, seed_follow):
    year = utcnow().year
    url = f"/library/annual?year={year}&tz_offset_minutes=0"
    push(client, H, "a")
    assert client.get(url, headers=H("a")).json()["circle"] is None
    share(client, H, world, "a")
    share(client, H, world, "c")
    push(client, H, "a", ch=2)
    push(client, H, "c")
    c = client.get(url, headers=H("a")).json()["circle"]
    assert [o["both"] for o in c["overlaps"]] == ["read"]
    assert c["overlaps"][0]["series"]["series_key"] == X
    assert [w["profile_id"] for w in c["with"]] == [world["c"]]
    # both finish: the viewer's library row completes and C's finished_series lands
    seed_follow(world["u1"], world["a"], source_id=SRC, series_key=X, reading_status="completed")
    db_session.add(CircleEvent(
        user_id=world["u2"], profile_id=world["c"], kind="finished_series", source_id=SRC,
        series_key=X, title="X", created_at=utcnow()))
    db_session.commit()
    c = client.get(url, headers=H("a")).json()["circle"]
    assert [o["both"] for o in c["overlaps"]] == ["finished"]


def test_profile_delete_cascades_circle_rows(client, H, world, db_session):
    share(client, H, world, "c", excluded_series=[{"source_id": SRC, "series_key": Y}])
    push(client, H, "c")
    assert db_session.execute(select(CircleEvent)).first() is not None
    assert client.delete(f"/profiles/{world['c']}", headers=H("c")).status_code == 204
    db_session.expire_all()
    assert db_session.execute(select(CircleEvent)).first() is None
    assert db_session.execute(select(CircleHiddenSeries)).first() is None
