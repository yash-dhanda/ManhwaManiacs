"""``POST /ai/feedback``: the five signals, and that each takes effect for one profile only."""

from __future__ import annotations

import json

import pytest

from database.models import AiFeedback, FollowedSeries
from services import ai_desk
from services.taste_service import taste_block
from tests import _ai_stubs
from tests._ai_stubs import SRC, media, seed_series

SEED = media(1, "Regressor")


@pytest.fixture(autouse=True)
def paid(monkeypatch, tmp_path, session_factory):
    p = _ai_stubs.install(monkeypatch, tmp_path, session_factory)
    monkeypatch.setattr(ai_desk, "run_in_background", lambda key, job: True)  # no editorial thread
    p.answer = {"why": {str(i): f"Line {i}" for i in range(10, 16)}}
    return p


@pytest.fixture
def anilist(monkeypatch):
    fake = _ai_stubs.install_anilist(monkeypatch)
    fake.search["regressor"] = SEED
    fake.recs[1] = [(100 - i, media(10 + i, f"Cand {i}")) for i in range(6)]
    return fake


@pytest.fixture
def two(make_user, make_profile, db_session, anilist):
    """One account, two profiles that both follow and read the seed."""
    user = make_user("fb")
    a = make_profile(user.id, "A", mature_content_enabled=True)
    b = make_profile(user.id, "B", mature_content_enabled=True)
    for p in (a, b):
        seed_series(db_session, user.id, p.id, read=range(1, 4), ocr=range(0))
        db_session.add(FollowedSeries(user_id=user.id, profile_id=p.id, source_id=SRC,
                                      series_key="s", title="Regressor", known_chapters="[]"))
    db_session.commit()
    return user.id, a.id, b.id


def post(client, as_user, two, who, **body):
    return client.post("/ai/feedback", json=body, headers=as_user(two[0], two[who]))


def similar_ids(client, as_user, two, who):
    r = client.get(f"/ai/similar?source={SRC}&series=s", headers=as_user(two[0], two[who]))
    return [i["anilist_id"] for i in r.json()["items"]]


def home_picked_ids(client, as_user, two, who):
    r = client.get("/home?tz_offset_minutes=0&refresh=1", headers=as_user(two[0], two[who]))
    return [i["item"]["anilist_id"] for s in r.json()["sections"] if s["type"] == "picked"
            for i in s["items"] if i["kind"] == "world"]


def world_ids(client, as_user, two, who):
    r = client.get("/library/world/recommendations", headers=as_user(two[0], two[who])).json()
    return [i["anilist_id"] for i in r["for_you"]]


@pytest.mark.parametrize("body", [
    {"signal": "nope"},
    {"signal": "not_interested"},
    {"signal": "not_interested", "source_id": SRC},
    {"signal": "undo"},
    {"signal": "liked_pick"},
    {"signal": "tag_rejected", "source_id": SRC, "series_key": "s"},
    {"signal": "tag_rejected", "anilist_id": 3, "tag": "x"},
    {"signal": "tag_rejected", "source_id": SRC, "series_key": "s", "tag": "x" * 65},
    {"signal": "clear", "surprise": 1},
])
def test_validation(client, as_user, two, body):
    assert post(client, as_user, two, 1, **body).status_code == 422


def test_writes_need_a_profile(client, as_user, two):
    r = client.post("/ai/feedback", json={"signal": "clear"}, headers=as_user(two[0]))
    assert r.status_code == 400 and r.json()["code"] == "profile_required"


def test_not_interested_undo_and_clear_for_one_profile_only(client, as_user, two):
    for who in (1, 2):
        assert similar_ids(client, as_user, two, who)[:1] == [10]
        assert 10 in home_picked_ids(client, as_user, two, who)
        assert 10 in world_ids(client, as_user, two, who)

    assert post(client, as_user, two, 1, signal="not_interested", anilist_id=10).status_code == 204
    assert 10 not in similar_ids(client, as_user, two, 1)
    assert 10 not in home_picked_ids(client, as_user, two, 1)
    assert 10 not in world_ids(client, as_user, two, 1)
    # the other profile of the same account still sees it
    assert 10 in similar_ids(client, as_user, two, 2)
    assert 10 in home_picked_ids(client, as_user, two, 2)
    assert 10 in world_ids(client, as_user, two, 2)

    assert post(client, as_user, two, 1, signal="undo", anilist_id=10).status_code == 204
    assert 10 in similar_ids(client, as_user, two, 1) and 10 in world_ids(client, as_user, two, 1)
    assert post(client, as_user, two, 1, signal="undo", anilist_id=10).status_code == 204  # nothing to undo

    post(client, as_user, two, 1, signal="not_interested", anilist_id=10)
    post(client, as_user, two, 1, signal="not_interested", anilist_id=11)
    post(client, as_user, two, 1, signal="liked_pick", anilist_id=12)
    assert {10, 11}.isdisjoint(similar_ids(client, as_user, two, 1))
    assert post(client, as_user, two, 1, signal="clear").status_code == 204
    assert {10, 11} <= set(similar_ids(client, as_user, two, 1))
    assert {10, 11} <= set(home_picked_ids(client, as_user, two, 1))


def test_undo_removes_only_the_newest_row(client, as_user, two, db_session):
    for _ in range(2):
        post(client, as_user, two, 1, signal="not_interested", anilist_id=10)
    post(client, as_user, two, 1, signal="undo", anilist_id=10)
    assert db_session.query(AiFeedback).filter_by(signal="not_interested").count() == 1


def test_a_source_pair_target_is_dropped_from_the_picks(client, as_user, two, db_session):
    add = _ai_stubs  # noqa: F841
    from database.models import SourceSeriesCache

    db_session.add(SourceSeriesCache(source_id=SRC, series_key="cand-10", title="Cand 0",
                                     genres="[]", chapters="[]"))
    db_session.commit()
    assert post(client, as_user, two, 1, signal="not_interested", source_id=SRC, series_key="cand-10").status_code == 204
    assert 10 not in world_ids(client, as_user, two, 1) and 10 in world_ids(client, as_user, two, 2)


def test_tag_rejected_hides_the_tag(client, as_user, two, paid):
    paid.answer = {"tags": ["regression", "revenge", "school"]}
    h = as_user(two[0], two[1])
    assert client.get(f"/ai/tags?source={SRC}&series=s", headers=h).json()["tags"] == ["regression", "revenge", "school"]
    assert post(client, as_user, two, 1, signal="tag_rejected", source_id=SRC, series_key="s", tag="Revenge").status_code == 204
    assert client.get(f"/ai/tags?source={SRC}&series=s", headers=h).json()["tags"] == ["regression", "school"]
    other = client.get(f"/ai/tags?source={SRC}&series=s", headers=as_user(two[0], two[2])).json()
    assert other["tags"] == ["regression", "revenge", "school"]


def test_liked_picks_join_the_taste_block_as_titles(client, as_user, two, db_session):
    post(client, as_user, two, 1, signal="liked_pick", source_id=SRC, series_key="s")
    block = taste_block(db_session, two[0], two[1])
    assert block["liked_picks"] == ["Regressor"]
    assert taste_block(db_session, two[0], two[2]) is None
