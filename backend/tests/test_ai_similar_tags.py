"""``GET /ai/similar``, ``GET /ai/tags`` and the gate on every per-series cache."""

from __future__ import annotations

import json
import time

import pytest

from database.models import (
    AiFeedback,
    AiResultCache,
    ProfileSeriesTag,
    SourceSeriesCache,
    SourcePin,
    Tag,
    WorldCatalogCache,
)
from services import ai_desk, ai_series_service
from tests import _ai_stubs
from tests._ai_stubs import MATURE, SRC, media, seed_series

SEED = media(1, "Regressor")


@pytest.fixture(autouse=True)
def paid(monkeypatch, tmp_path, session_factory):
    return _ai_stubs.install(monkeypatch, tmp_path, session_factory)


@pytest.fixture
def anilist(monkeypatch):
    fake = _ai_stubs.install_anilist(monkeypatch)
    fake.search["regressor"] = SEED
    fake.recs[1] = [(100 - i, media(10 + i, f"Cand {i}")) for i in range(12)]
    return fake


@pytest.fixture
def users(make_user, make_profile):
    user = make_user("similar")
    gated = make_profile(user.id, "Kid", mature_content_enabled=False)
    open_ = make_profile(user.id, "Riya", mature_content_enabled=True)
    return user.id, gated.id, open_.id


@pytest.fixture
def seeded(db_session, users):
    uid, _, pid = users
    seed_series(db_session, uid, pid, read=range(1, 3), ocr=range(0))
    db_session.add(SourcePin(user_id=uid, profile_id=pid, source_id=SRC, sort_order=0))
    db_session.commit()
    return users


def add_cache(db, source, key, title, genres, *, rating=None):
    db.add(SourceSeriesCache(source_id=source, series_key=key, title=title,
                             genres=json.dumps(genres), content_rating=rating,
                             chapters=json.dumps([{"key": "c1", "number": 1}])))
    db.commit()


def why_for(ids, text="Same premise."):
    return {"why": {str(i): f"{text} {i}" for i in ids}}


def similar(client, as_user, users, who=2, **q):
    h = as_user(users[0], users[who])
    qs = "&".join(f"{k}={v}" for k, v in q.items())
    return client.get(f"/ai/similar?{qs}", headers=h)


def test_ai_path_gives_ten_items_available_first_with_why(client, as_user, seeded, anilist, paid, db_session):
    paid.answer = why_for(range(10, 22))
    for i in (9, 10, 11):
        add_cache(db_session, SRC, f"c{i}", f"Cand {i}", ["Action"])
    body = similar(client, as_user, seeded, source=SRC, series="s").json()
    assert body["available"] is True and body["reason"] == "ok" and body["basis"] == "ai"
    assert len(body["items"]) == 10 and body["generated_at"]
    assert [bool(i["available"]) for i in body["items"]][:2] == [True, True]
    assert all(i["basis"] == "ai" and i["why"].startswith("Same premise.") for i in body["items"])
    assert "Regressor" not in {i["title"] for i in body["items"]}
    # the desk got titles, formats and genres, never a description
    assert "description" not in paid.seen[0]["message"].lower()
    assert len(paid.seen) == 1
    again = similar(client, as_user, seeded, source=SRC, series="s").json()
    assert len(paid.seen) == 1 and again["items"][0]["why"]


def test_anilist_id_form_gives_exactly_three(client, as_user, seeded, anilist, paid):
    paid.answer = why_for(range(10, 22))
    body = similar(client, as_user, seeded, anilist_id=1).json()
    assert [i["anilist_id"] for i in body["items"]] == [10, 11, 12] and body["basis"] == "ai"


@pytest.mark.parametrize("query", ["", "source=hm_manga", "source=hm_manga&series=s&anilist_id=1", "fallback=genres", "anilist_id=1&fallback=genres"])
def test_exactly_one_form(client, as_user, seeded, anilist, query):
    assert client.get(f"/ai/similar?{query}", headers=as_user(seeded[0], seeded[2])).status_code == 422


def test_slow_desk_answers_without_why_then_serves_the_cache(client, as_user, seeded, anilist, paid, monkeypatch):
    monkeypatch.setattr(ai_series_service, "WAIT_SECONDS", 0.05)
    paid.answer = why_for(range(10, 22))
    paid.delay = 0.4
    t0 = time.monotonic()
    first = similar(client, as_user, seeded, source=SRC, series="s").json()
    assert time.monotonic() - t0 < 0.35
    assert first["available"] is True and first["reason"] == "ok" and first["basis"] == "ai"
    assert first["items"] and all(i["why"] is None for i in first["items"])
    for _ in range(100):
        if not ai_desk._RUNNING:
            break
        time.sleep(0.05)
    second = similar(client, as_user, seeded, source=SRC, series="s").json()
    assert all(i["why"] for i in second["items"]) and len(paid.seen) == 1


def genre_rows(db, n=4, *, source=SRC, shared=("Action", "Fantasy"), prefix="g"):
    for i in range(n):
        add_cache(db, source, f"{prefix}{i}", f"Genre {prefix}{i}", list(shared) + ["Extra"])


def test_desk_unavailable_gives_genre_fallback_for_a_series_and_nothing_for_onboarding(
    client, as_user, seeded, anilist, monkeypatch, tmp_path, session_factory, db_session
):
    monkeypatch.delenv("DEEPSEEK_API_KEY")
    genre_rows(db_session)
    body = similar(client, as_user, seeded, source=SRC, series="s").json()
    assert (body["available"], body["reason"], body["basis"]) == (False, "not_configured", "genres")
    assert len(body["items"]) == 4 and anilist.calls == 0
    item = body["items"][0]
    assert item["anilist_id"] is None and item["basis"] == "genres" and item["is_adult"] is False
    assert item["available"][0]["source_id"] == SRC and item["format"] is None
    assert set(item) >= {"title", "alt_titles", "country", "status", "chapters", "rating", "genres",
                         "cover_url", "platforms", "anilist_url", "why", "ambient", "palette"}
    onboarding = similar(client, as_user, seeded, anilist_id=1).json()
    assert onboarding["items"] == [] and onboarding["available"] is False and onboarding["reason"] == "not_configured"


def test_explicit_genre_fallback_rules(client, as_user, seeded, anilist, db_session, paid):
    uid, _, pid = seeded
    genre_rows(db_session, 2)                                  # only two: fewer than 3
    body = similar(client, as_user, seeded, source=SRC, series="s", fallback="genres").json()
    assert body["items"] == [] and body["available"] is True and body["basis"] == "genres"
    genre_rows(db_session, 3, prefix="h")
    add_cache(db_session, SRC, "one-shared", "One Shared", ["Action"])           # < 2 shared
    add_cache(db_session, "hm_manga2", "elsewhere", "Elsewhere", ["Action", "Fantasy"])  # not the profile's source
    from database.models import FollowedSeries
    db_session.add(FollowedSeries(user_id=uid, profile_id=pid, source_id=SRC, series_key="g0",
                                  title="Genre g0", known_chapters="[]"))
    db_session.commit()
    body = similar(client, as_user, seeded, source=SRC, series="s", fallback="genres").json()
    keys = [i["available"][0]["series_key"] for i in body["items"]]
    assert "g0" not in keys and "s" not in keys and "one-shared" not in keys and "elsewhere" not in keys
    assert set(keys) == {"g1", "h0", "h1", "h2"}
    assert paid.seen == [] and anilist.calls == 0


def test_18_plus_never_reaches_a_gated_profile_from_a_shared_cache_row(
    client, as_user, users, db_session, anilist, paid
):
    uid, gated, opened = users
    seed_series(db_session, uid, opened, read=range(1, 3), ocr=range(0))
    anilist.recs[1] = [(90, media(10, "Clean")), (80, media(11, "Lewd", adult=True)),
                       (70, media(12, "Adult Only Source"))]
    add_cache(db_session, MATURE, "as", "Adult Only Source", ["Action"])
    paid.answer = why_for([10, 11, 12])
    rich = similar(client, as_user, users, source=SRC, series="s").json()
    assert {i["title"] for i in rich["items"]} == {"Clean", "Lewd", "Adult Only Source"}
    assert len(paid.seen) == 1
    row = db_session.query(AiResultCache).filter_by(kind="similar").one()
    assert set(json.loads(row.payload)["why"]) == {"10", "11", "12"}     # stored ungated
    shut = similar(client, as_user, users, who=1, source=SRC, series="s").json()
    assert {i["title"] for i in shut["items"]} == {"Clean"}
    assert len(paid.seen) == 1                                            # served from that row
    assert "Lewd" not in json.dumps(shut) and "Adult Only Source" not in json.dumps(shut)


def test_gated_series_is_a_404_before_any_call(client, as_user, users, db_session, anilist, paid):
    uid, gated, opened = users
    add_cache(db_session, SRC, "hot", "Hot", ["Action"], rating="mature")
    for path in ("similar?source=hm_manga&series=hot", "tags?source=hm_manga&series=hot"):
        r = client.get(f"/ai/{path}", headers=as_user(uid, gated))
        assert r.status_code == 404 and r.json()["code"] == "series_not_found"
    assert paid.seen == [] and anilist.calls == 0
    assert client.get("/ai/similar?source=hm_manga&series=hot", headers=as_user(uid, opened)).status_code == 200


# --- tags ----------------------------------------------------------------------------


def tags(client, as_user, users, who=2):
    return client.get(f"/ai/tags?source={SRC}&series=s", headers=as_user(users[0], users[who])).json()


def test_tags_drop_rejected_and_owned_and_cap_at_five(client, as_user, seeded, db_session, paid):
    uid, _, pid = seeded
    paid.answer = {"tags": ["Regression", "revenge", "slow burn", "overpowered", "dungeon", "school", "magic", "war", "x" * 30]}
    tag = Tag(user_id=uid, profile_id=pid, name="Revenge")
    db_session.add(tag)
    db_session.commit()
    db_session.add(ProfileSeriesTag(user_id=uid, profile_id=pid, source_id=SRC, series_key="s", tag_id=tag.id))
    db_session.add(AiFeedback(user_id=uid, profile_id=pid, signal="tag_rejected", source_id=SRC,
                              series_key="s", tag="slow burn"))
    db_session.commit()
    body = tags(client, as_user, seeded)
    assert body["available"] is True and body["reason"] == "ok" and body["generated_at"]
    assert body["tags"] == ["regression", "overpowered", "dungeon", "school", "magic"]
    assert "reader_tags" in paid.seen[0]["message"] and "Revenge" in paid.seen[0]["message"]
    row = db_session.query(AiResultCache).filter_by(kind="tags").one()
    assert len(json.loads(row.payload)["tags"]) == 8
    tags(client, as_user, seeded)
    assert len(paid.seen) == 1


def test_tags_when_the_desk_is_closed(client, as_user, seeded, monkeypatch):
    monkeypatch.delenv("DEEPSEEK_API_KEY")
    assert tags(client, as_user, seeded) == {"tags": [], "available": False, "reason": "not_configured", "generated_at": None}


# --- /series/enrichment keeps its gate ---------------------------------------------------


def test_enrichment_never_leaks_a_stored_row_to_a_gated_profile(client, as_user, users, db_session):
    from routes.series import enrichment_key

    uid, gated, opened = users
    add_cache(db_session, SRC, "hot", "Hot", ["Action"], rating="mature")
    db_session.add(WorldCatalogCache(
        key=enrichment_key(SRC, "hot"),
        payload=json.dumps({"anilist_id": 424242, "format": "Manhwa", "score": 8.1,
                            "official": [{"site": "Official", "url": "https://x.example/official"}],
                            "is_adult": False}),
    ))
    db_session.commit()
    r = client.get(f"/series/enrichment?source={SRC}&series=hot", headers=as_user(uid, gated))
    assert r.status_code == 404 and "424242" not in r.text and "official" not in r.text
    ok = client.get(f"/series/enrichment?source={SRC}&series=hot", headers=as_user(uid, opened))
    assert ok.json()["anilist_id"] == 424242
