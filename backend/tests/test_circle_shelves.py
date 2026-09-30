"""Shared shelves: roles, the permission table, payloads, 18+ (backend/09)."""

from __future__ import annotations

import pytest
from sqlalchemy import func, select

from database.models import (
    CircleLetter,
    CircleReaction,
    CollectionSeries,
    CollectionShare,
    ReadingProfile,
)

SRC = "asurascans"
MATURE_SRC = "18porncomic"


@pytest.fixture
def world(make_user, make_profile):
    u1, u2, u3 = make_user("acct1"), make_user("acct2"), make_user("acct3")
    return {
        "u1": u1.id, "u2": u2.id, "u3": u3.id,
        "a": make_profile(u1.id, "A", mature_content_enabled=True).id,
        "b": make_profile(u1.id, "B", mature_content_enabled=True).id,
        "c": make_profile(u2.id, "C", mature_content_enabled=False).id,
        "d": make_profile(u3.id, "D", mature_content_enabled=True).id,
    }


@pytest.fixture
def H(as_user, world):
    def make(who: str) -> dict:
        u = {"a": "u1", "b": "u1", "c": "u2", "d": "u3"}[who]
        return as_user(world[u], world[who])

    return make


@pytest.fixture
def on(client, H, world):
    def turn(who, **body):
        r = client.patch(f"/profiles/{world[who]}/sharing", json={"activity": True, **body}, headers=H(who))
        assert r.status_code == 200, r.text

    for who in "abcd":
        turn(who)
    return turn


@pytest.fixture
def shelf(client, H, world, seed_follow, on):
    seed_follow(world["u1"], world["a"], source_id=SRC, series_key="a-one", title="Alpha One", cover_url="http://c/a1.jpg")
    seed_follow(world["u1"], world["a"], source_id=SRC, series_key="a-two", title="Alpha Two")
    r = client.post("/library/collections", json={"name": "Weekend binge"}, headers=H("a"))
    sid = r.json()["id"]
    for key in ("a-one", "a-two"):
        assert client.post(f"/library/collections/{sid}/series", json={"source_id": SRC, "series_key": key}, headers=H("a")).status_code == 200
    return sid


def share(client, H, world, sid, ids, mode="can_add", who="a"):
    return client.post(
        f"/library/collections/{sid}/share",
        json={"profile_ids": [world.get(i, i) for i in ids], "mode": mode}, headers=H(who),
    )


def add(client, H, sid, key, who, src=SRC):
    return client.post(f"/library/collections/{sid}/series", json={"source_id": src, "series_key": key}, headers=H(who))


def remove(client, H, sid, key, who, src=SRC):
    return client.request("DELETE", f"/library/collections/{sid}/series", json={"source_id": src, "series_key": key}, headers=H(who))


def keys(body):
    return [s["series_key"] for s in body["series"]]


def test_share_and_list_shapes(client, H, world, shelf):
    r = share(client, H, world, shelf, ["b"])
    assert r.status_code == 200
    row = r.json()
    assert row["role"] == "owner" and row["shared"]["mode"] == "can_add" and row["shared"]["member_profile_ids"] == [world["b"]]
    assert row["shared"]["members"][0]["name"] == "B" and row["shared"]["owner_profile_id"] == world["a"]
    r = share(client, H, world, shelf, ["c"], mode="view_only")
    assert r.json()["shared"]["member_profile_ids"] == [world["c"]] and r.json()["shared"]["mode"] == "view_only"
    r = share(client, H, world, shelf, ["b", "c"])
    assert sorted(r.json()["shared"]["member_profile_ids"]) == sorted([world["b"], world["c"]])
    mine = client.get("/library/collections", headers=H("a"))
    assert isinstance(mine.json(), list) and mine.headers["x-total-count"] == "1"
    assert mine.json()[0]["role"] == "owner" and mine.json()[0]["series_count"] == 2
    b_default = client.get("/library/collections", headers=H("b"))
    assert b_default.json() == []
    inc = client.get("/library/collections", params={"include_shared": "true"}, headers=H("b")).json()
    assert inc["collections"] == [] and len(inc["shared_with_me"]) == 1
    sh = inc["shared_with_me"][0]
    assert sh["role"] == "can_add" and sh["owner"]["name"] == "A" and sh["series_count"] == 2
    assert sh["rules"] is None and sh["created_at"] and len(sh["preview_covers"]) == 2 and sh["shared"]["mode"] == "can_add"
    # unsharing
    assert share(client, H, world, shelf, []).json()["shared"] is None
    assert client.get("/library/collections", params={"include_shared": "true"}, headers=H("b")).json()["shared_with_me"] == []


def test_member_and_stranger_permissions(client, H, world, shelf):
    view_shelf = client.post("/library/collections", json={"name": "Read only"}, headers=H("a")).json()["id"]
    add(client, H, view_shelf, "a-one", "a")
    share(client, H, world, shelf, ["b"], mode="can_add")
    share(client, H, world, view_shelf, ["c"], mode="view_only")
    # B (can_add) adds, sees the snapshot and the adder, removes its own, is refused A's
    body = add(client, H, shelf, "b-only", "b").json()
    row = [s for s in body["series"] if s["series_key"] == "b-only"][0]
    assert row["added_by_profile_id"] == world["b"] and row["title"] == "b-only" and row["added_by"]["name"] == "B"
    assert remove(client, H, shelf, "b-only", "b").status_code == 204
    assert remove(client, H, shelf, "a-one", "b").status_code == 403
    assert "a-one" in keys(client.get(f"/library/collections/{shelf}", headers=H("b")).json())
    # C (view_only) reads but cannot add or remove
    assert client.get(f"/library/collections/{view_shelf}", headers=H("c")).json()["role"] == "view_only"
    assert add(client, H, view_shelf, "x", "c").status_code == 403
    assert remove(client, H, view_shelf, "a-one", "c").status_code == 403
    assert add(client, H, view_shelf, "x", "b").status_code == 404  # B is not a member of that shelf
    # a stranger gets 404 everywhere
    assert client.get(f"/library/collections/{shelf}", headers=H("d")).status_code == 404
    assert add(client, H, shelf, "x", "d").status_code == 404
    assert remove(client, H, shelf, "a-one", "d").status_code == 404
    assert share(client, H, world, shelf, ["b"], who="d").status_code == 404
    assert client.delete(f"/library/collections/{shelf}/share/me", headers=H("d")).status_code == 404


def test_members_cannot_manage_and_the_owner_can(client, H, world, shelf):
    share(client, H, world, shelf, ["b", "c"])
    order = {"items": [{"source_id": SRC, "series_key": k} for k in ("a-two", "a-one")]}
    for who in ("b", "c"):
        assert client.patch(f"/library/collections/{shelf}", json={"name": "Mine"}, headers=H(who)).status_code == 403
        assert client.delete(f"/library/collections/{shelf}", headers=H(who)).status_code == 403
        assert client.put(f"/library/collections/{shelf}/series/order", json=order, headers=H(who)).status_code == 403
        assert share(client, H, world, shelf, [], who=who).status_code == 403
    assert client.put(f"/library/collections/{shelf}/series/order", json=order, headers=H("a")).status_code == 204
    assert keys(client.get(f"/library/collections/{shelf}", headers=H("b")).json()) == ["a-two", "a-one"]
    bad = {"items": [{"source_id": SRC, "series_key": "a-one"}]}
    r = client.put(f"/library/collections/{shelf}/series/order", json=bad, headers=H("a"))
    assert r.status_code == 422 and r.json()["code"] == "order_mismatch"
    add(client, H, shelf, "b-one", "b")
    assert remove(client, H, shelf, "b-one", "a").status_code == 204  # the owner removes any row
    assert remove(client, H, shelf, "a-one", "a").status_code == 204
    assert keys(client.get(f"/library/collections/{shelf}", headers=H("a")).json()) == ["a-two"]


def test_leave_and_remove(client, H, world, shelf):
    share(client, H, world, shelf, ["b", "c"])
    add(client, H, shelf, "b-one", "b")
    assert client.delete(f"/library/collections/{shelf}/share/me", headers=H("b")).status_code == 204
    shared = lambda who: client.get("/library/collections", params={"include_shared": "true"}, headers=H(who)).json()["shared_with_me"]  # noqa: E731
    assert shared("b") == [] and len(shared("c")) == 1
    assert "b-one" in keys(client.get(f"/library/collections/{shelf}", headers=H("a")).json())
    assert client.delete(f"/library/collections/{shelf}/share/{world['b']}", headers=H("c")).status_code == 403
    assert client.delete(f"/library/collections/{shelf}/share/{world['c']}", headers=H("a")).status_code == 204
    assert client.delete(f"/library/collections/{shelf}/share/{world['c']}", headers=H("a")).status_code == 204
    assert shared("c") == []
    assert client.delete(f"/library/collections/{shelf}/share/me", headers=H("a")).status_code == 403
    assert client.delete(f"/library/collections/{shelf}/share/nope", headers=H("a")).status_code == 422


def test_refusals_and_effect_of_switches(client, H, world, shelf, on):
    smart = client.post(
        "/library/collections",
        json={"name": "Smart", "rules": {"all": [{"field": "is_favorite", "op": "eq", "value": "true"}]}},
        headers=H("a"),
    )
    assert smart.status_code == 200, smart.text
    r = share(client, H, world, smart.json()["id"], ["b"])
    assert r.status_code == 409 and r.json()["code"] == "smart_shelf_not_shareable"
    on("c", shelves=False)
    r = share(client, H, world, shelf, ["b", "c"])
    assert r.status_code == 409 and r.json()["code"] == "member_unavailable"
    assert r.json()["details"] == {"profile_ids": [world["c"]]}
    assert share(client, H, world, shelf, ["a"]).json()["code"] == "member_unavailable"
    assert share(client, H, world, shelf, [9999]).status_code == 409
    assert client.get("/library/collections", headers=H("a")).json()[0]["shared"] is None  # nothing written
    assert share(client, H, world, shelf, ["b"]).status_code == 200
    seen = lambda: client.get("/library/collections", params={"include_shared": "true"}, headers=H("b")).json()["shared_with_me"]  # noqa: E731
    assert len(seen()) == 1
    client.patch(f"/profiles/{world['a']}/sharing", json={"activity": False}, headers=H("a"))
    assert seen() == [] and client.get(f"/library/collections/{shelf}", headers=H("b")).status_code == 404
    r = share(client, H, world, shelf, ["b"])
    assert r.status_code == 409 and r.json()["code"] == "sharing_off"
    on("a")
    assert len(seen()) == 1
    client.patch(f"/profiles/{world['b']}/sharing", json={"shelves": False}, headers=H("b"))
    assert seen() == [] and client.get(f"/library/collections/{shelf}", headers=H("b")).status_code == 404


def test_mature_rows_follow_each_viewers_gate(client, H, world, shelf):
    share(client, H, world, shelf, ["b", "c"])
    add(client, H, shelf, "m1", "a", src=MATURE_SRC)
    b = client.get(f"/library/collections/{shelf}", headers=H("b")).json()
    c = client.get(f"/library/collections/{shelf}", headers=H("c")).json()
    assert "m1" in keys(b) and b["series_count"] == 3
    assert "m1" not in keys(c) and c["series_count"] == 2
    assert "18porncomic" not in str(c)
    shared = client.get("/library/collections", params={"include_shared": "true"}, headers=H("c")).json()["shared_with_me"][0]
    assert shared["series_count"] == 2 and all("18porncomic" not in cov for cov in shared["preview_covers"])
    # the owner (gate open) still sees all three
    assert client.get("/library/collections", headers=H("a")).json()[0]["series_count"] == 3


def test_detail_rows_and_member_page(client, H, world, shelf):
    share(client, H, world, shelf, ["b"])
    body = client.get(f"/library/collections/{shelf}", headers=H("b")).json()
    assert body["role"] == "can_add" and body["owner"]["name"] == "A" and body["shared"]["mode"] == "can_add"
    first = body["series"][0]
    assert {"title", "cover_url", "ambient", "palette", "added_by_profile_id", "added_by"} <= set(first)
    assert first["title"] == "Alpha One" and first["cover_url"] == "http://c/a1.jpg"
    assert first["added_by_profile_id"] == world["a"] and first["added_by"]["name"] == "A"
    page = client.get(f"/circle/members/{world['a']}", headers=H("b")).json()
    assert [s["name"] for s in page["shelves"]] == ["Weekend binge"] and page["shelves"][0]["role"] == "can_add"
    other = client.get(f"/circle/members/{world['c']}", headers=H("b")).json()
    assert other["shelves"] == []


def test_deleting_a_profile_removes_what_it_owned_in_the_circle(client, H, world, shelf, db_session):
    share(client, H, world, shelf, ["b", "c"])
    add(client, H, shelf, "b-one", "b")
    client.post("/circle/reactions", json={"source_id": SRC, "series_key": "a-one", "chapter_key": "c1", "kind": "loved"}, headers=H("b"))
    for frm, to in (("b", "c"), ("c", "b")):
        r = client.post("/circle/letters", json={"to_profile_ids": [world[to]], "source_id": SRC, "series_key": "a-one"}, headers=H(frm))
        assert r.status_code == 201, r.text
    count = lambda model, col: db_session.execute(select(func.count()).select_from(model).where(col == world["b"])).scalar_one()  # noqa: E731
    assert count(CollectionShare, CollectionShare.profile_id) == 1 and count(CircleReaction, CircleReaction.profile_id) == 1
    db_session.delete(db_session.get(ReadingProfile, world["b"]))
    db_session.commit()
    assert count(CollectionShare, CollectionShare.profile_id) == 0 and count(CircleReaction, CircleReaction.profile_id) == 0
    assert db_session.execute(select(func.count()).select_from(CircleLetter)).scalar_one() == 0
    assert "b-one" not in keys(client.get(f"/library/collections/{shelf}", headers=H("a")).json())
    assert db_session.execute(select(func.count()).select_from(CollectionSeries).where(CollectionSeries.added_by_profile_id == world["b"])).scalar_one() == 0
