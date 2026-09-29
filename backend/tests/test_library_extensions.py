"""backend/02: manual progress, mark unread, repoint, collection rules and
previews, member order, library tags, tag filter and server-side sorts.

HTTP-level, through ``client`` + ``as_user`` so profile scoping, the 18+ gate
and profile ownership run for real. ``FakeBrowse`` stands in for connectors.
"""

from __future__ import annotations

import json
from datetime import timedelta

import pytest
from sqlalchemy import func, select

from core.time_utils import utcnow
from database.models import (
    ChapterProgress,
    Collection,
    CollectionSeries,
    CoverPalette,
    FollowedSeries,
    ProfileSeriesTag,
    ReadingSession,
    Tag,
)
from services.browse_service import get_browse_service
from tests._fakes import FakeBrowse

SRC = "mangadex"
OTHER = "comick"
MATURE_SRC = "nhentai"


def _chapters(prefix: str, numbers) -> list[dict]:
    return [
        {"id": f"{prefix}-{n:g}", "number": float(n), "title": f"Ch {n:g}",
         "release_date": "2026-01-01"}
        for n in numbers
    ]


FIXTURE = {
    (SRC, "old"): {"meta": {"title": "Old Home", "genres": ["action"]},
                   "chapters": _chapters("old", range(1, 11))},
    (OTHER, "new"): {"meta": {"title": "New Home", "genres": ["action"],
                              "cover_url": "http://x/new.jpg"},
                     "chapters": _chapters("new", range(1, 13))},
    (OTHER, "gap"): {"meta": {"title": "Gappy", "genres": ["action"]},
                     "chapters": _chapters("gap", [1, 2, 3, 4, 6, 7])},
    (OTHER, "adult"): {"meta": {"title": "Adult", "genres": ["hentai"]},
                       "chapters": _chapters("ad", [1, 2])},
}


@pytest.fixture
def world(make_user, make_profile):
    """Account 1 with profiles A (gate shut) and B; account 2 with profile C."""
    u1 = make_user("acct1")
    u2 = make_user("acct2")
    return {
        "u1": u1.id, "u2": u2.id,
        "a": make_profile(u1.id, "A").id,
        "b": make_profile(u1.id, "B").id,
        "c": make_profile(u2.id, "C").id,
    }


@pytest.fixture
def api(app, client):
    browse = FakeBrowse({k: json.loads(json.dumps(v)) for k, v in FIXTURE.items()})
    app.dependency_overrides[get_browse_service] = lambda: browse
    return client


@pytest.fixture
def ha(as_user, world):
    return as_user(world["u1"], world["a"])


@pytest.fixture
def hb(as_user, world):
    return as_user(world["u1"], world["b"])


@pytest.fixture
def hc(as_user, world):
    return as_user(world["u2"], world["c"])


def _push(**kw):
    item = {"source_id": SRC, "series_key": "s", "chapter_key": "c1",
            "chapter_number": 1, "last_page": 5, "page_count": 5,
            "is_completed": True, "time_spent_seconds": 30}
    item.update(kw)
    return item


def _sessions(db):
    db.expire_all()
    return db.execute(select(func.count()).select_from(ReadingSession)).scalar_one()


def _progress_keys(db, uid, pid, series_key=None):
    db.expire_all()
    stmt = select(ChapterProgress).where(
        ChapterProgress.user_id == uid, ChapterProgress.profile_id == pid
    )
    if series_key:
        stmt = stmt.where(ChapterProgress.series_key == series_key)
    return {r.chapter_key for r in db.execute(stmt).scalars()}


# ===========================================================================
# A. manual progress and mark unread
# ===========================================================================


def test_manual_batch_item_saves_without_a_session(api, ha, db_session):
    resp = api.post("/reader/progress/batch", json=[_push(manual=True)], headers=ha)
    assert resp.status_code == 200, resp.text
    assert resp.json()["items"][0]["is_completed"] is True
    assert _sessions(db_session) == 0

    resp = api.post("/reader/progress/batch", json=[_push(chapter_key="c2")], headers=ha)
    assert resp.status_code == 200
    assert _sessions(db_session) == 1


def test_manual_single_push_saves_without_a_session(api, ha, db_session):
    resp = api.post("/reader/progress", json=_push(manual=True), headers=ha)
    assert resp.status_code == 200, resp.text
    assert resp.json()["is_completed"] is True
    assert _sessions(db_session) == 0


def test_delete_progress_removes_named_chapters_for_caller_only(
    api, ha, hb, world, seed_progress, seed_session, db_session
):
    for key in ("c1", "c2", "c3"):
        seed_progress(world["u1"], world["a"], series_key="s", chapter_key=key)
        seed_progress(world["u1"], world["b"], series_key="s", chapter_key=key)
    seed_session(world["u1"], world["a"], series_key="s", chapter_key="c1")

    resp = api.request(
        "DELETE", "/reader/progress",
        json={"source_id": SRC, "series_key": "s", "chapter_keys": ["c1", "c2", "nope"]},
        headers=ha,
    )
    assert resp.status_code == 204, resp.text
    assert _progress_keys(db_session, world["u1"], world["a"]) == {"c3"}
    assert _progress_keys(db_session, world["u1"], world["b"]) == {"c1", "c2", "c3"}
    assert _sessions(db_session) == 1


def test_delete_progress_unknown_keys_204_and_cap_422(api, ha):
    resp = api.request(
        "DELETE", "/reader/progress",
        json={"source_id": SRC, "series_key": "zz", "chapter_keys": ["x"]}, headers=ha,
    )
    assert resp.status_code == 204
    resp = api.request(
        "DELETE", "/reader/progress",
        json={"source_id": SRC, "series_key": "zz",
              "chapter_keys": [f"k{i}" for i in range(201)]},
        headers=ha,
    )
    assert resp.status_code == 422
    resp = api.request(
        "DELETE", "/reader/progress",
        json={"source_id": SRC, "series_key": "zz",
              "chapter_keys": [f"k{i}" for i in range(200)]},
        headers=ha,
    )
    assert resp.status_code == 204


def test_delete_progress_other_account_untouched(api, hc, world, seed_progress, db_session):
    seed_progress(world["u1"], world["a"], series_key="s", chapter_key="c1")
    resp = api.request(
        "DELETE", "/reader/progress",
        json={"source_id": SRC, "series_key": "s", "chapter_keys": ["c1"]}, headers=hc,
    )
    assert resp.status_code == 204
    assert _progress_keys(db_session, world["u1"], world["a"]) == {"c1"}


def test_delete_progress_of_a_gated_series_still_deletes(
    api, ha, world, seed_follow, seed_progress, db_session
):
    seed_follow(world["u1"], world["a"], series_key="s", mature_override=True)
    seed_progress(world["u1"], world["a"], series_key="s", chapter_key="c1")
    resp = api.request(
        "DELETE", "/reader/progress",
        json={"source_id": SRC, "series_key": "s", "chapter_keys": ["c1"]}, headers=ha,
    )
    assert resp.status_code == 204
    assert _progress_keys(db_session, world["u1"], world["a"]) == set()


# ===========================================================================
# B. repoint
# ===========================================================================


def _follow(api, h, source_id=SRC, series_key="old"):
    resp = api.post("/library/follow", json={"source_id": source_id, "series_key": series_key},
                    headers=h)
    assert resp.status_code == 200, resp.text
    return resp.json()


def _read_old(seed_progress, uid, pid, upto=5):
    for n in range(1, upto + 1):
        seed_progress(uid, pid, source_id=SRC, series_key="old", chapter_key=f"old-{n}",
                      chapter_number=float(n), last_page=20, page_count=20,
                      is_completed=True, completed_at=utcnow(), last_read_at=utcnow(),
                      time_spent_seconds=300)


def _shelve(db, uid, pid, source_id, key):
    coll = Collection(user_id=uid, profile_id=pid, name=f"Shelf {key}")
    tag = Tag(user_id=uid, profile_id=pid, name=f"Tag {key}")
    db.add_all([coll, tag])
    db.commit()
    db.add_all([
        CollectionSeries(collection_id=coll.id, source_id=source_id, series_key=key),
        ProfileSeriesTag(user_id=uid, profile_id=pid, source_id=source_id,
                         series_key=key, tag_id=tag.id),
    ])
    db.commit()
    return coll.id, tag.id


def _pairs(db, model, **where):
    db.expire_all()
    rows = db.execute(select(model).filter_by(**where)).scalars()
    return {(r.source_id, r.series_key) for r in rows}


def test_repoint_in_place_maps_progress_and_moves_shelves(
    api, ha, world, seed_progress, db_session
):
    followed = _follow(api, ha)
    _read_old(seed_progress, world["u1"], world["a"])
    coll_id, tag_id = _shelve(db_session, world["u1"], world["a"], SRC, "old")

    resp = api.post(f"/library/series/{followed['id']}/repoint",
                    json={"source_id": OTHER, "series_key": "new"}, headers=ha)
    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert body["mapped_chapter_key"] == "new-5"
    assert body["mapped_chapter_number"] == 5.0
    f = body["followed"]
    assert (f["id"], f["source_id"], f["series_key"], f["title"]) == (
        followed["id"], OTHER, "new", "New Home")
    assert f["chapter_count"] == 12
    assert f["read_state"]["chapter_key"] == "new-5"
    assert f["read_state"]["new_count"] == 7
    assert [t["id"] for t in f["tags"]] == [tag_id]
    assert "ambient" in f and "palette" in f

    db_session.expire_all()
    row = db_session.get(FollowedSeries, followed["id"])
    assert (row.migrated_from_source, row.migrated_from_series_key) == (SRC, "old")
    assert row.migrated_at is not None and row.mature_override is None
    assert _progress_keys(db_session, world["u1"], world["a"], "new") == {
        f"new-{n}" for n in range(1, 6)}
    assert _progress_keys(db_session, world["u1"], world["a"], "old") == {
        f"old-{n}" for n in range(1, 6)}
    copied = db_session.execute(select(ChapterProgress).where(
        ChapterProgress.series_key == "new")).scalars().all()
    assert all(c.is_completed and c.time_spent_seconds == 0 and c.last_page == 20
               for c in copied)
    assert _sessions(db_session) == 0
    assert _pairs(db_session, CollectionSeries, collection_id=coll_id) == {(OTHER, "new")}
    assert _pairs(db_session, ProfileSeriesTag, tag_id=tag_id) == {(OTHER, "new")}


def test_repoint_keep_old_creates_a_second_row(api, ha, world, seed_progress, db_session):
    followed = _follow(api, ha)
    api.patch(f"/library/series/{followed['id']}", json={"is_favorite": True}, headers=ha)
    _read_old(seed_progress, world["u1"], world["a"], upto=2)
    coll_id, tag_id = _shelve(db_session, world["u1"], world["a"], SRC, "old")

    resp = api.post(f"/library/series/{followed['id']}/repoint",
                    json={"source_id": OTHER, "series_key": "new", "keep_old": True}, headers=ha)
    assert resp.status_code == 200, resp.text
    new = resp.json()["followed"]
    assert new["id"] != followed["id"] and new["is_favorite"] is True
    db_session.expire_all()
    old = db_session.get(FollowedSeries, followed["id"])
    assert (old.source_id, old.series_key, old.migrated_from_source) == (SRC, "old", None)
    assert db_session.get(FollowedSeries, new["id"]).migrated_from_series_key == "old"
    assert _pairs(db_session, CollectionSeries, collection_id=coll_id) == {
        (SRC, "old"), (OTHER, "new")}
    assert _pairs(db_session, ProfileSeriesTag, tag_id=tag_id) == {
        (SRC, "old"), (OTHER, "new")}
    listing = api.get("/library/series", headers=ha).json()
    assert listing["total"] == 2


def test_repoint_number_gap_maps_to_the_chapter_below(api, ha, world, seed_progress):
    followed = _follow(api, ha)
    _read_old(seed_progress, world["u1"], world["a"])
    body = api.post(f"/library/series/{followed['id']}/repoint",
                    json={"source_id": OTHER, "series_key": "gap"}, headers=ha).json()
    assert body["mapped_chapter_key"] == "gap-4"
    assert body["mapped_chapter_number"] == 4.0


def test_repoint_unstarted_maps_nothing(api, ha):
    followed = _follow(api, ha)
    body = api.post(f"/library/series/{followed['id']}/repoint",
                    json={"source_id": OTHER, "series_key": "new"}, headers=ha).json()
    assert body["mapped_chapter_key"] is None and body["mapped_chapter_number"] is None


def test_repoint_refusals(api, ha, hb, hc):
    followed = _follow(api, ha)
    target = _follow(api, ha, OTHER, "new")
    url = f"/library/series/{followed['id']}/repoint"

    resp = api.post(url, json={"source_id": OTHER, "series_key": "new"}, headers=ha)
    assert resp.status_code == 409
    assert resp.json()["details"] == {"followed_id": target["id"]}

    resp = api.post(url, json={"source_id": SRC, "series_key": "old"}, headers=ha)
    assert resp.status_code == 422 and resp.json()["code"] == "same_series"

    for other in (hb, hc):
        resp = api.post(url, json={"source_id": OTHER, "series_key": "gap"}, headers=other)
        assert resp.status_code == 404 and resp.json()["code"] == "series_not_found"

    resp = api.post(url, json={"source_id": OTHER, "series_key": "adult"}, headers=ha)
    assert resp.status_code == 404 and resp.json()["code"] == "series_not_found"


# ===========================================================================
# C. collections
# ===========================================================================

RULES = {"all": [
    {"field": "reading_status", "op": "eq", "value": "reading"},
    {"field": "new_count", "op": "gte", "value": 1},
    {"field": "format", "op": "in", "value": ["manhwa", "manga"]},
    {"field": "is_favorite", "op": "ne", "value": False},
]}


def test_collection_rules_round_trip(api, ha):
    created = api.post("/library/collections", json={"name": "Smart", "rules": RULES},
                       headers=ha).json()
    assert created["rules"] == RULES and created["smart"] is True
    assert created["created_at"]
    cid = created["id"]
    assert api.get(f"/library/collections/{cid}", headers=ha).json()["rules"] == RULES
    listed = api.get("/library/collections", headers=ha).json()
    assert listed[0]["rules"] == RULES and listed[0]["smart"] is True
    assert listed[0]["created_at"] == created["created_at"]

    patched = api.patch(f"/library/collections/{cid}", json={"name": "Renamed"},
                        headers=ha).json()
    assert patched["rules"] == RULES
    one = {"all": [RULES["all"][0]]}
    assert api.patch(f"/library/collections/{cid}", json={"rules": one},
                     headers=ha).json()["rules"] == one
    cleared = api.patch(f"/library/collections/{cid}", json={"rules": None}, headers=ha).json()
    assert cleared["rules"] is None and cleared["smart"] is False
    plain = api.post("/library/collections", json={"name": "Plain"}, headers=ha).json()
    assert plain["rules"] is None and plain["smart"] is False


@pytest.mark.parametrize("rules", [
    {"all": []},
    {"all": [RULES["all"][0]] * 9},
    {"any": [RULES["all"][0]]},
    {"all": [{"field": "title", "op": "eq", "value": "x"}]},
    {"all": [{"field": "format", "op": "lt", "value": "x"}]},
    {"all": [{"field": "format", "op": "in", "value": "manhwa"}]},
    {"all": [{"field": "format", "op": "eq", "value": ["manhwa"]}]},
    {"all": [{"field": "format", "op": "in", "value": []}]},
    {"all": [{"field": "format", "op": "in", "value": [f"f{i}" for i in range(21)]}]},
    {"all": [{"field": "format", "op": "in", "value": [1, 2]}]},
    {"all": [{"field": "reading_status", "op": "gte", "value": 1}]},
    {"all": [{"field": "format", "op": "eq", "value": {"a": 1}}]},
    {"all": [{"field": "format", "op": "eq", "value": None}]},
    {"all": [{"field": "format", "op": "eq"}]},
])
def test_collection_rules_invalid_shapes_422(api, ha, rules):
    assert api.post("/library/collections", json={"name": "Bad", "rules": rules},
                    headers=ha).status_code == 422
    cid = api.post("/library/collections", json={"name": "Ok"}, headers=ha).json()["id"]
    assert api.patch(f"/library/collections/{cid}", json={"rules": rules},
                     headers=ha).status_code == 422


def _collection_with(db, uid, pid, members, name="Shelf"):
    coll = Collection(user_id=uid, profile_id=pid, name=name)
    db.add(coll)
    db.commit()
    base = utcnow()
    for i, (src, key) in enumerate(members):
        db.add(CollectionSeries(collection_id=coll.id, source_id=src, series_key=key,
                                sort_order=i, added_at=base + timedelta(seconds=i)))
    db.commit()
    return coll.id


def _palette(db, src, key, duo):
    db.add(CoverPalette(source_id=src, series_key=key,
                        ambient=json.dumps({"duo": duo, "tint": "#000000", "ink": "#ffffff"}),
                        palette=json.dumps({"a": 1, "l": 1, "lMax": 1}), computed_at=utcnow()))
    db.commit()


def test_collection_previews_gate_filtered(api, ha, world, seed_follow, db_session):
    uid, pid = world["u1"], world["a"]
    seed_follow(uid, pid, series_key="adult", mature_override=True, cover_url="http://x/adult")
    seed_follow(uid, pid, series_key="s1", cover_url="http://x/s1")
    members = [(SRC, "adult"), (SRC, "s1"), (SRC, "s/2"), (MATURE_SRC, "999"),
               (SRC, "s3"), (SRC, "s4"), (SRC, "s5")]
    cid = _collection_with(db_session, uid, pid, members)
    _palette(db_session, SRC, "adult", ["#111111", "#222222"])
    _palette(db_session, SRC, "s1", ["#333333", "#444444"])
    empty = _collection_with(db_session, uid, pid, [], name="Empty")

    rows = {c["id"]: c for c in api.get("/library/collections", headers=ha).json()}
    assert rows[cid]["preview_covers"] == [
        "http://x/s1", f"/sources/{SRC}/series/s%2F2/cover",
        f"/sources/{SRC}/series/s3/cover", f"/sources/{SRC}/series/s4/cover"]
    assert rows[cid]["preview_ambient_duo"] == ["#333333", "#444444"]
    assert rows[cid]["series_count"] == 5
    assert rows[empty]["preview_covers"] == [] and rows[empty]["preview_ambient_duo"] is None


def test_collection_previews_open_gate_shows_first_member(
    api, as_user, make_user, make_profile, seed_follow, db_session
):
    uid = make_user("adult").id
    pid = make_profile(uid, "Open", mature_content_enabled=True).id
    seed_follow(uid, pid, series_key="adult", mature_override=True, cover_url="http://x/adult")
    cid = _collection_with(db_session, uid, pid, [(SRC, "adult"), (SRC, "s1")])
    _palette(db_session, SRC, "adult", ["#111111", "#222222"])
    row = api.get("/library/collections", headers=as_user(uid, pid)).json()[0]
    assert row["id"] == cid
    assert row["preview_covers"] == ["http://x/adult", f"/sources/{SRC}/series/s1/cover"]
    assert row["preview_ambient_duo"] == ["#111111", "#222222"]


def _order(db, cid):
    db.expire_all()
    rows = db.execute(select(CollectionSeries).where(CollectionSeries.collection_id == cid)
                      .order_by(CollectionSeries.sort_order)).scalars()
    return [(r.series_key, r.sort_order) for r in rows]


def test_collection_member_order(api, ha, hb, hc, world, seed_follow, db_session):
    uid, pid = world["u1"], world["a"]
    seed_follow(uid, pid, series_key="h1", mature_override=True)
    seed_follow(uid, pid, series_key="h2", mature_override=True)
    cid = _collection_with(db_session, uid, pid,
                           [(SRC, "h1"), (SRC, "a"), (SRC, "h2"), (SRC, "b"), (SRC, "c")])
    url = f"/library/collections/{cid}/series/order"
    items = [{"source_id": SRC, "series_key": k} for k in ("c", "a", "b")]

    resp = api.put(url, json={"items": items}, headers=ha)
    assert resp.status_code == 204, resp.text
    assert [k for k, _ in _order(db_session, cid)] == ["c", "a", "b", "h1", "h2"]
    got = api.get(f"/library/collections/{cid}", headers=ha).json()["series"]
    assert [m["series_key"] for m in got] == ["c", "a", "b"]

    for bad in (items[:2], items + [items[0]], items[:2] + [{"source_id": SRC, "series_key": "h1"}],
                items + [{"source_id": SRC, "series_key": "zz"}]):
        resp = api.put(url, json={"items": bad}, headers=ha)
        assert resp.status_code == 422 and resp.json()["code"] == "order_mismatch"
    for other in (hb, hc):
        assert api.put(url, json={"items": items}, headers=other).status_code == 404
    assert [k for k, _ in _order(db_session, cid)] == ["c", "a", "b", "h1", "h2"]


def test_collection_created_at_on_every_payload(api, ha):
    created = api.post("/library/collections", json={"name": "X"}, headers=ha).json()
    detail = api.get(f"/library/collections/{created['id']}", headers=ha).json()
    assert detail["created_at"] == created["created_at"] is not None


def test_collections_isolated(api, ha, hb, hc):
    cid = api.post("/library/collections", json={"name": "Mine", "rules": RULES},
                   headers=ha).json()["id"]
    for other in (hb, hc):
        assert api.get("/library/collections", headers=other).json() == []
        assert api.get(f"/library/collections/{cid}", headers=other).status_code == 404
        assert api.patch(f"/library/collections/{cid}", json={"rules": None},
                         headers=other).status_code == 404


# ===========================================================================
# D. tags, tag filter and sorts
# ===========================================================================


def _tag(api, h, name, color=None):
    resp = api.post("/library/tags", json={"name": name, "color": color}, headers=h)
    assert resp.status_code == 200, resp.text
    return resp.json()["id"]


def _tag_series(api, h, key, tag_id, source_id=SRC):
    resp = api.post("/library/series-tags",
                    json={"source_id": source_id, "series_key": key, "tag_id": tag_id}, headers=h)
    assert resp.status_code == 200, resp.text


def _library(uid, pid, seed_follow, n):
    for i in range(n):
        seed_follow(uid, pid, series_key=f"s{i:02d}", title=f"Series {i:02d}")


def test_rows_carry_tags_sorted_by_name(api, ha, world, seed_follow):
    _library(world["u1"], world["a"], seed_follow, 2)
    zed, alpha = _tag(api, ha, "Zed", "#FF8A3D"), _tag(api, ha, "alpha")
    _tag_series(api, ha, "s00", zed)
    _tag_series(api, ha, "s00", alpha)
    items = api.get("/library/series", headers=ha).json()["items"]
    assert [t["name"] for t in items[0]["tags"]] == ["Zed", "alpha"]  # as GET /tags orders
    assert set(items[0]["tags"][0]) == {"id", "name", "category", "color"}
    assert items[1]["tags"] == []
    found = api.get("/library/search", params={"q": "Series 00"}, headers=ha).json()["items"]
    assert {t["id"] for t in found[0]["tags"]} == {zed, alpha}


def test_tag_filter_is_any_of_over_the_whole_library(api, ha, hb, world, seed_follow):
    _library(world["u1"], world["a"], seed_follow, 30)
    t1, t2 = _tag(api, ha, "One"), _tag(api, ha, "Two")
    for key in ("s01", "s25", "s27"):
        _tag_series(api, ha, key, t1)
    _tag_series(api, ha, "s29", t2)

    page2 = api.get("/library/series", params={"per_page": 2, "page": 2,
                                               "tag_ids": f"{t1},{t2}"}, headers=ha).json()
    assert page2["total"] == 4 and page2["total_pages"] == 2 and page2["has_next"] is False
    assert [r["series_key"] for r in page2["items"]] == ["s27", "s29"]
    assert api.get("/library/series", params={"tag_ids": str(t2)},
                   headers=ha).json()["total"] == 1
    # Another profile's ids match nothing.
    _library(world["u1"], world["b"], seed_follow, 1)
    assert api.get("/library/series", params={"tag_ids": str(t1)},
                   headers=hb).json()["total"] == 0


@pytest.mark.parametrize("raw", ["", "a", "1,x", "0", "-1", "1,,2", "1.5"])
def test_invalid_tag_ids_422(api, ha, raw):
    resp = api.get("/library/series", params={"tag_ids": raw}, headers=ha)
    assert resp.status_code == 422 and resp.json()["code"] == "invalid_tag_ids"


def test_patch_tag(api, ha, hb, hc):
    tid = _tag(api, ha, "Rewatch", "#FF8A3D")
    _tag(api, ha, "Other")
    url = f"/library/tags/{tid}"
    body = api.patch(url, json={"name": "  Reread  "}, headers=ha).json()
    assert body["name"] == "Reread" and body["color"] == "#FF8A3D" and body["series_count"] == 0
    assert api.patch(url, json={"color": "#00aa11"}, headers=ha).json()["color"] == "#00aa11"
    assert api.patch(url, json={"color": None}, headers=ha).json()["color"] is None
    assert api.patch(url, json={"name": "reread"}, headers=ha).status_code == 200
    resp = api.patch(url, json={"name": "OTHER"}, headers=ha)
    assert resp.status_code == 409 and resp.json()["code"] == "tag_exists"
    for bad in ({"color": "red"}, {"color": "#12345"}, {"name": "   "}, {"name": "x" * 256}):
        assert api.patch(url, json=bad, headers=ha).status_code == 422
    for h in (hb, hc):
        resp = api.patch(url, json={"name": "Mine"}, headers=h)
        assert resp.status_code == 404 and resp.json()["code"] == "not_found"


def test_tag_series_count_is_gate_aware(api, ha, world, seed_follow, make_profile, as_user):
    uid, pid = world["u1"], world["a"]
    seed_follow(uid, pid, series_key="adult", mature_override=True)
    seed_follow(uid, pid, series_key="safe")
    tid = _tag(api, ha, "Mixed")
    for src, key in ((SRC, "adult"), (SRC, "safe"), (SRC, "unfollowed"), (MATURE_SRC, "9")):
        _tag_series(api, ha, key, tid, source_id=src)
    rows = api.get("/library/tags", headers=ha).json()
    assert rows[0]["series_count"] == 2
    patched = api.patch(f"/library/tags/{tid}", json={"color": "#FFFFFF"}, headers=ha).json()
    assert patched["series_count"] == 2
    # Isolation: another profile sees none of it.
    assert api.get("/library/tags", headers=as_user(uid, world["b"])).json() == []


def test_tag_series_count_open_gate_counts_all(api, as_user, make_user, make_profile, seed_follow):
    uid = make_user("open").id
    pid = make_profile(uid, "Open", mature_content_enabled=True).id
    h = as_user(uid, pid)
    seed_follow(uid, pid, series_key="adult", mature_override=True)
    tid = _tag(api, h, "All")
    _tag_series(api, h, "adult", tid)
    _tag_series(api, h, "9", tid, source_id=MATURE_SRC)
    assert api.get("/library/tags", headers=h).json()[0]["series_count"] == 2


def test_sort_last_read_at(api, ha, world, seed_follow, seed_progress):
    uid, pid = world["u1"], world["a"]
    for key, title in (("a", "Alpha"), ("b", "Beta"), ("c", "Gamma"), ("d", "Delta")):
        seed_follow(uid, pid, series_key=key, title=title)
    now = utcnow()
    seed_progress(uid, pid, series_key="a", chapter_key="1", last_read_at=now - timedelta(days=3))
    seed_progress(uid, pid, series_key="a", chapter_key="2", last_read_at=now - timedelta(days=1))
    seed_progress(uid, pid, series_key="c", chapter_key="1", last_read_at=now)
    seed_progress(world["u1"], world["b"], series_key="b", chapter_key="1", last_read_at=now)

    def keys(sort):
        return [r["series_key"] for r in api.get(
            "/library/series", params={"sort": sort}, headers=ha).json()["items"]]

    assert keys("-last_read_at") == ["c", "a", "b", "d"]
    assert keys("last_read_at") == ["a", "c", "b", "d"]
    page = api.get("/library/series", params={"sort": "-last_read_at", "per_page": 1,
                                              "page": 2}, headers=ha).json()
    assert [r["series_key"] for r in page["items"]] == ["a"] and page["total"] == 4


def _known(n):
    return json.dumps([{"key": f"k{i}", "number": float(i)} for i in range(1, n + 1)])


def test_sort_new_count_and_new_only(api, ha, world, seed_follow, seed_progress):
    uid, pid = world["u1"], world["a"]
    # new_count: A=4, B=1, C=0, D unknown (read a chapter not in the list), E not started.
    specs = {"a": ("Alpha", 5, "k1"), "b": ("Beta", 5, "k4"), "c": ("Gamma", 3, "k3"),
             "d": ("Delta", 3, "zz"), "e": ("Echo", 3, None), "f": ("Foxtrot", 9, "k5")}
    for key, (title, n, read) in specs.items():
        seed_follow(uid, pid, series_key=key, title=title, known_chapters=_known(n))
        if read:
            seed_progress(uid, pid, series_key=key, chapter_key=read, chapter_number=None)

    def keys(**params):
        body = api.get("/library/series", params=params, headers=ha).json()
        return [r["series_key"] for r in body["items"]], body["total"]

    assert keys(sort="-new_count") == (["a", "f", "b", "c", "d", "e"], 6)
    assert keys(new_only="true") == (["a", "b", "f"], 3)
    assert keys(new_only="true", sort="-new_count", per_page=2, page=2) == (["b"], 3)
    items = api.get("/library/series", params={"new_only": "true"}, headers=ha).json()["items"]
    assert all(r["read_state"]["new_count"] >= 1 for r in items)
