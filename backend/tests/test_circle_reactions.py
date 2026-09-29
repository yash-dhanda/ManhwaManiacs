"""Chapter reactions and the server half of the spoiler guard (backend/09)."""

from __future__ import annotations

import pytest
from sqlalchemy import func, select, update

from database.models import CircleEvent, CircleReaction, ReadingProfile

SRC = "asurascans"
MATURE_SRC = "18porncomic"
X = "series-x"
KINDS = ["loved", "shook", "laughed", "tears", "chefs_kiss", "hype", "wrecked"]


@pytest.fixture
def world(make_user, make_profile):
    u1, u2, u3 = make_user("acct1"), make_user("acct2"), make_user("acct3")
    return {
        "u1": u1.id, "u2": u2.id, "u3": u3.id,
        "a": make_profile(u1.id, "A").id, "b": make_profile(u1.id, "B").id,
        "c": make_profile(u2.id, "C").id, "d": make_profile(u3.id, "D").id,
    }


@pytest.fixture
def H(as_user, world):
    def make(who: str) -> dict:
        u = {"a": "u1", "b": "u1", "c": "u2", "d": "u3"}[who]
        return as_user(world[u], world[who])

    return make


def share(client, H, world, who, **body):
    r = client.patch(f"/profiles/{world[who]}/sharing", json={"activity": True, **body}, headers=H(who))
    assert r.status_code == 200, r.text


def push(client, H, who, ch=1, done=True, series=X, src=SRC, **kw):
    body = {
        "source_id": src, "series_key": series, "chapter_key": f"ch-{ch}",
        "chapter_number": float(ch), "last_page": 5, "page_count": 5,
        "is_completed": done, "time_spent_seconds": 60, **kw,
    }
    assert client.post("/reader/progress", json=body, headers=H(who)).status_code in (200, 201)


def react(client, H, who, ch=1, kind="loved", series=X, src=SRC, key=None):
    return client.post(
        "/circle/reactions",
        json={"source_id": src, "series_key": series, "chapter_key": key or f"ch-{ch}", "kind": kind},
        headers=H(who),
    )


def unreact(client, H, who, ch=1, series=X, src=SRC):
    return client.request(
        "DELETE", "/circle/reactions",
        json={"source_id": src, "series_key": series, "chapter_key": f"ch-{ch}"}, headers=H(who),
    )


def reactions(client, H, who, series=X, src=SRC):
    r = client.get("/circle/reactions", params={"source": src, "series": series}, headers=H(who))
    assert r.status_code == 200, r.text
    return {c["chapter_key"]: c for c in r.json()["chapters"]}


def test_insert_keep_move_delete(client, H, world, db_session):
    rows = lambda: db_session.execute(select(func.count()).select_from(CircleReaction)).scalar_one()  # noqa: E731
    r = react(client, H, "a")
    assert r.status_code == 200 and r.json()["mine"] == "loved" and r.json()["total"] == 1
    assert react(client, H, "a").json()["mine"] == "loved" and rows() == 1
    assert react(client, H, "a", kind="tears").json()["mine"] == "tears" and rows() == 1
    assert unreact(client, H, "a").status_code == 204 and rows() == 0
    assert unreact(client, H, "a").status_code == 204


def test_all_seven_kinds_and_bad_kind(client, H, world):
    for i, kind in enumerate(KINDS, 1):
        assert react(client, H, "a", ch=i, kind=kind).status_code == 200
    assert react(client, H, "a", ch=9, kind="wow").status_code == 422
    counts = reactions(client, H, "a")["ch-1"]["counts"]
    assert list(counts) == KINDS and counts["loved"] == 1 and counts["wrecked"] == 0


def test_counts_after_filtering_and_own_reaction(client, H, world):
    share(client, H, world, "a")
    share(client, H, world, "c")
    react(client, H, "c", kind="loved")
    react(client, H, "a", kind="tears")
    got = reactions(client, H, "a")["ch-1"]
    assert got["total"] == 2 and got["counts"]["loved"] == 1 and got["counts"]["tears"] == 1
    assert got["mine"] == "tears" and {b["profile_id"] for b in got["by"]} == {world["a"], world["c"]}
    assert set(got["by"][0]) == {"profile_id", "name", "avatar_key", "username", "kind", "created_at"}
    # sharing off: A still sees own (mine and by), C no longer sees A
    client.patch(f"/profiles/{world['a']}/sharing", json={"activity": False}, headers=H("a"))
    own = reactions(client, H, "a")["ch-1"]
    assert own["mine"] == "tears" and own["total"] == 2  # C still shares
    assert reactions(client, H, "c")["ch-1"]["total"] == 1
    # reactions switch off hides C's reactions from A
    client.patch(f"/profiles/{world['c']}/sharing", json={"reactions": False}, headers=H("c"))
    assert reactions(client, H, "a")["ch-1"]["total"] == 1
    # made while off, stays hidden after turning it back on
    react(client, H, "c", ch=2, kind="hype")
    client.patch(f"/profiles/{world['c']}/sharing", json={"reactions": True}, headers=H("c"))
    a_view = reactions(client, H, "a")
    assert "ch-2" not in a_view and a_view["ch-1"]["total"] == 2  # ch-1 was shared at write time
    assert reactions(client, H, "c")["ch-2"]["mine"] == "hype"


def test_feed_follows_the_reaction(client, H, world):
    share(client, H, world, "c")

    def items():
        return client.get("/circle/feed", params={"kind": "reaction"}, headers=H("a")).json()["items"]

    react(client, H, "c", kind="loved")
    assert [(i["kind"], i["reaction"]) for i in items()] == [("reacted", "loved")]
    react(client, H, "c", kind="shook")
    assert [(i["kind"], i["reaction"]) for i in items()] == [("reacted", "shook")]
    unreact(client, H, "c")
    assert items() == []


def test_spoiler_guard_sealed_flag(client, H, world):
    share(client, H, world, "c")
    share(client, H, world, "a")
    for ch in (1, 2, 3):
        push(client, H, "c", ch=ch)
        react(client, H, "c", ch=ch, kind="tears")

    def everywhere(ch):
        chapter = reactions(client, H, "a")[f"ch-{ch}"]
        feed = [
            i for i in client.get("/circle/feed", params={"kind": "reaction"}, headers=H("a")).json()["items"]
            if i["chapter_key"] == f"ch-{ch}"
        ][0]
        page = client.get(f"/circle/members/{world['c']}", headers=H("a")).json()
        member = [r for r in page["reactions"] if r["chapter_key"] == f"ch-{ch}"][0]
        assert chapter["counts"]["tears"] == 1 and feed["reaction"] == "tears" and member["reaction"] == "tears"
        assert chapter["sealed"] == feed["sealed"] == member["sealed"]
        return chapter["sealed"]

    assert everywhere(1) is True  # never opened
    push(client, H, "a", ch=1, done=False, last_page=5, page_count=20)
    assert everywhere(1) is True  # half read
    push(client, H, "a", ch=2)
    assert everywhere(2) is False  # finished
    push(client, H, "a", ch=1)  # completes the half-read chapter
    assert everywhere(1) is False
    # another chapter_key spelling with the same number also unseals
    push(client, H, "a", ch=3, chapter_key="other-3")
    assert everywhere(3) is False
    # non-reacted feed items carry sealed: null
    kinds = {i["kind"]: i["sealed"] for i in client.get("/circle/feed", headers=H("a")).json()["items"]}
    assert kinds["finished_chapter"] is None


@pytest.mark.parametrize("c_include", [True, False])
@pytest.mark.parametrize("a_open", [True, False])
def test_mature_reactions_need_both_sides(client, as_user, make_user, make_profile, c_include, a_open):
    u1, u2 = make_user("m1"), make_user("m2")
    a = make_profile(u1.id, "A", mature_content_enabled=a_open)
    c = make_profile(u2.id, "C", mature_content_enabled=True)
    ha, hc = as_user(u1.id, a.id), as_user(u2.id, c.id)
    client.patch(f"/profiles/{c.id}/sharing", json={"activity": True, "include_mature": c_include}, headers=hc)
    r = client.post(
        "/circle/reactions",
        json={"source_id": MATURE_SRC, "series_key": "m", "chapter_key": "ch-1", "kind": "loved"},
        headers=hc,
    )
    assert r.status_code == 200 and r.json()["total"] == 1  # stored, gate not checked
    got = client.get("/circle/reactions", params={"source": MATURE_SRC, "series": "m"}, headers=ha).json()
    assert bool(got["chapters"]) == (c_include and a_open)
    if got["chapters"]:
        assert got["chapters"][0]["total"] == 1


def test_isolation(client, H, world, db_session):
    share(client, H, world, "c")
    react(client, H, "c")
    react(client, H, "b", kind="tears")  # B never shares
    assert {b["profile_id"] for b in reactions(client, H, "a")["ch-1"]["by"]} == {world["c"]}
    assert {b["profile_id"] for b in reactions(client, H, "d")["ch-1"]["by"]} == {world["c"]}
    client.patch(f"/profiles/{world['c']}/sharing", json={"activity": False}, headers=H("c"))
    assert reactions(client, H, "d") == {}
    assert reactions(client, H, "c")["ch-1"]["mine"] == "loved"
    # shared is fixed at write time
    assert db_session.execute(select(CircleReaction.shared).where(CircleReaction.profile_id == world["b"])).scalar_one() == 0
    assert db_session.execute(select(func.count()).select_from(CircleEvent).where(CircleEvent.kind == "reacted", CircleEvent.profile_id == world["b"])).scalar_one() == 0
