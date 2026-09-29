"""Taste (``PUT``/``GET /profiles/{id}/taste``), ``GET /onboarding/catalog`` and
``POST /library/taste/seed``."""

from __future__ import annotations

import json

import pytest

from database.models import FollowedSeries, SourcePin, SourceSeriesCache
from services import ai_desk
from services.browse_service import BrowseService
from tests import _ai_stubs
from tests._ai_stubs import MATURE, SRC, media

MANGA = ("hm_manga", "hm_manga2", "hm_manga3", "hm_manga4")


@pytest.fixture(autouse=True)
def paid(monkeypatch, tmp_path, session_factory):
    p = _ai_stubs.install(monkeypatch, tmp_path, session_factory, key=False)
    monkeypatch.setattr(ai_desk, "run_in_background", lambda key, job: True)
    return p


@pytest.fixture
def anilist(monkeypatch):
    return _ai_stubs.install_anilist(monkeypatch)


@pytest.fixture
def acct(make_user, make_profile):
    user = make_user("taste")
    gated = make_profile(user.id, "Kid", mature_content_enabled=False)
    opened = make_profile(user.id, "Riya", mature_content_enabled=True)
    return user.id, gated.id, opened.id


def put(client, as_user, acct, who=1, **body):
    return client.put(f"/profiles/{acct[who]}/taste", json=body, headers=as_user(acct[0], acct[who]))


def test_put_merges_partial_bodies_and_zero_deletes(client, as_user, acct):
    r = put(client, as_user, acct, step=3, formats=["manhwa"], genres={"Action": 2, "Romance": 1, "Horror": -1})
    assert r.status_code == 200
    assert r.json() == {"step": 3, "formats": ["manhwa"], "genres": {"Action": 2, "Romance": 1, "Horror": -1},
                        "styles": [], "seeds": []}
    r = put(client, as_user, acct, genres={"Romance": 0, "Comedy": 1}, styles=["noir", "cel"],
            seeds=[{"anilist_id": 5}, {"source_id": SRC, "series_key": "s"}])
    assert r.json() == {"step": 3, "formats": ["manhwa"], "genres": {"Action": 2, "Horror": -1, "Comedy": 1},
                        "styles": ["noir", "cel"],
                        "seeds": [{"anilist_id": 5}, {"source_id": SRC, "series_key": "s"}]}
    got = client.get(f"/profiles/{acct[1]}/taste", headers=as_user(acct[0], acct[1])).json()
    assert got == r.json()
    prof = client.get("/profiles", headers=as_user(acct[0])).json()
    assert next(p for p in prof if p["id"] == acct[1])["onboarding_step"] == 3


@pytest.mark.parametrize("step", [1, 2, 3, 4, 5, 6, 7, "done"])
def test_step_round_trips(client, as_user, acct, step):
    assert put(client, as_user, acct, step=step).json()["step"] == step
    got = client.get(f"/profiles/{acct[1]}/taste", headers=as_user(acct[0], acct[1])).json()
    assert got["step"] == step


@pytest.mark.parametrize("body", [
    {"step": 8}, {"step": 0}, {"styles": ["glitter"]}, {"formats": ["comic"]},
    {"genres": {"Action": 3}}, {"genres": {"": 1}}, {"genres": {"x" * 65: 1}},
    {"seeds": [{}]}, {"seeds": [{"source_id": SRC}]}, {"seeds": [{"anilist_id": i} for i in range(1, 52)]},
    {"genres": {f"G{i}": 1 for i in range(81)}}, {"surprise": 1},
])
def test_put_validation(client, as_user, acct, body):
    assert put(client, as_user, acct, **body).status_code == 422


def test_the_80_key_cap_applies_after_the_merge(client, as_user, acct):
    assert put(client, as_user, acct, genres={f"G{i}": 1 for i in range(80)}).status_code == 200
    assert put(client, as_user, acct, genres={"One More": 1}).status_code == 422
    assert put(client, as_user, acct, genres={"G0": 0, "One More": 1}).status_code == 200


def test_another_accounts_profile_is_a_404(client, as_user, acct, make_user, make_profile):
    other = make_user("other")
    theirs = make_profile(other.id, "Theirs")
    h = as_user(acct[0], acct[1])
    r = client.put(f"/profiles/{theirs.id}/taste", json={"step": 1}, headers=h)
    assert r.status_code == 404 and r.json()["code"] == "profile_not_found"
    assert client.get(f"/profiles/{theirs.id}/taste", headers=h).status_code == 404


# --- catalogue ----------------------------------------------------------------------


@pytest.fixture
def genres(monkeypatch):
    common = [f"G{i:02d}" for i in range(33)]
    labels = {
        "hm_manga": common + ["Action", "Adult"],
        "hm_manga2": ["Action", "adult", "Romance"],
        "hm_manga3": ["Action", "ADULT"],
        "hm_manga4": ["Action", "Mature"],
        MATURE: ["Steamy", "Action"],
        "hm_novel": ["Litrpg"],
    }
    monkeypatch.setattr(BrowseService, "list_genres",
                        lambda self, sid: [{"id": g, "label": g} for g in labels[sid]])


def catalog(client, as_user, acct, who, **q):
    qs = "&".join(f"{k}={v}" for k, v in q.items())
    return client.get(f"/onboarding/catalog?{qs}", headers=as_user(acct[0], acct[who]))


def test_catalog_genres_are_gated_ordered_and_bounded(client, as_user, acct, anilist, genres):
    shut = catalog(client, as_user, acct, 1, formats="manhwa").json()["genres"]
    names = {g["name"] for g in shut}
    assert "Steamy" not in names and "Adult" not in names and "Mature" not in names
    assert 30 <= len(shut) <= 40
    assert [g["weight"] for g in shut] == sorted((g["weight"] for g in shut), reverse=True)
    assert shut[0] == {"name": "Action", "weight": 4}
    assert "Litrpg" not in names                       # a manhwa reader is not shown novel genres
    open_ = catalog(client, as_user, acct, 2, formats="manhwa").json()["genres"]
    names = {g["name"] for g in open_}
    assert {"Steamy", "Adult", "Mature"} <= names
    assert next(g for g in open_ if g["name"].casefold() == "adult")["weight"] == 3
    assert next(g for g in open_ if g["name"] == "Action")["weight"] == 5


def test_catalog_seeds_are_gated_and_available_first(client, as_user, acct, anilist, genres, db_session):
    anilist.trending["manhwa"] = [
        media(31, "Adult Title", adult=True), media(32, "Nowhere"), media(33, "Here On Alpha"),
    ]
    db_session.add(SourceSeriesCache(source_id=SRC, series_key="here", title="Here On Alpha",
                                     genres="[]", chapters="[]"))
    db_session.commit()
    shut = catalog(client, as_user, acct, 1, formats="manhwa").json()
    assert [i["title"] for i in shut["seeds"]] == ["Here On Alpha", "Nowhere"]
    assert shut["seeds"][0]["available"] and shut["unavailable_reason"] is None
    assert shut["formats"][0]["format"] == "manhwa" and len(shut["formats"][0]["covers"]) == 2
    open_ = catalog(client, as_user, acct, 2, formats="manhwa").json()
    assert [i["title"] for i in open_["seeds"]] == ["Here On Alpha", "Adult Title", "Nowhere"]


def test_an_open_gate_leaves_the_adult_filter_out_of_the_query(client, as_user, acct, anilist, genres):
    """AniList reads ``isAdult: null`` as "not adult", so the variable is omitted."""
    anilist.trending["manhwa"] = [media(41, "Actiony")]
    catalog(client, as_user, acct, 2, formats="manhwa", genres="Action")
    assert anilist.trending_vars and all("adult" not in v for v in anilist.trending_vars)
    anilist.trending_vars.clear()
    catalog(client, as_user, acct, 1, formats="manga")
    assert anilist.trending_vars and all(v["adult"] is False for v in anilist.trending_vars)


def test_catalog_genre_filter_and_all_formats(client, as_user, acct, anilist, genres):
    anilist.trending["manhwa"] = [media(41, "Actiony", genres=("Action",)), media(42, "Romcom", genres=("Romance",))]
    anilist.trending["novel"] = [media(43, "Nov", fmt="NOVEL", country="JP")]
    body = catalog(client, as_user, acct, 1, formats="manhwa", genres="action").json()
    assert [i["title"] for i in body["seeds"]] == ["Actiony"]
    every = catalog(client, as_user, acct, 1).json()
    assert [f["format"] for f in every["formats"]] == ["manhwa", "manga", "manhua", "novel"]
    assert catalog(client, as_user, acct, 1, formats="comic").status_code == 422
    assert catalog(client, as_user, acct, 1, styles="glitter").status_code == 422


def test_catalog_is_cached_for_a_day(client, as_user, acct, anilist, genres):
    anilist.trending["manhwa"] = [media(41, "Actiony")]
    catalog(client, as_user, acct, 1, formats="manhwa")
    calls = anilist.calls
    catalog(client, as_user, acct, 1, formats="manhwa")
    assert calls > 0 and anilist.calls == calls


def test_anilist_down_still_serves_genres(client, as_user, acct, anilist, genres):
    anilist.down = True
    body = catalog(client, as_user, acct, 1, formats="manhwa").json()
    assert body["unavailable_reason"] == "The worldwide catalogue could not be reached."
    assert body["seeds"] == [] and body["formats"] == [{"format": "manhwa", "covers": []}]
    assert len(body["genres"]) >= 30


# --- sources-only seed wall ---------------------------------------------------------------


def test_taste_seed_never_touches_a_connector(client, as_user, acct, db_session, monkeypatch):
    def boom(*a, **k):
        raise AssertionError("no connector call allowed")

    for name in ("list_series", "get_series", "get_chapters", "search"):
        monkeypatch.setattr(BrowseService, name, boom, raising=False)
    uid, gated, opened = acct
    db_session.add(SourcePin(user_id=uid, profile_id=gated, source_id=SRC, sort_order=0))
    for i in range(30):
        db_session.add(SourceSeriesCache(
            source_id=SRC, series_key=f"k{i}", title=f"T{i}",
            genres=json.dumps(["Action", "Romance"] if i % 2 else ["Drama"]), chapters="[]"))
    db_session.add(SourceSeriesCache(source_id=SRC, series_key="hot", title="Hot", genres="[]",
                                     content_rating="mature", chapters="[]"))
    db_session.add(FollowedSeries(user_id=uid, profile_id=gated, source_id=SRC, series_key="k1",
                                  title="T1", known_chapters="[]"))
    db_session.commit()
    r = client.post("/library/taste/seed", headers=as_user(uid, gated),
                    json={"formats": ["manhwa"], "genres": {"Action": 2, "Drama": -1}, "styles": []})
    assert r.status_code == 200
    body = r.json()
    assert body["basis"] == "sources" and len(body["items"]) == 24
    keys = [i["id"] for i in body["items"]]
    assert "hot" not in keys and "k1" not in keys
    assert all(int(k[1:]) % 2 == 1 for k in keys[:14])       # liked-genre rows first
    assert {"id", "source_id", "title", "cover_url", "genres"} <= set(body["items"][0])


def test_taste_seed_needs_a_profile(client, as_user, acct):
    assert client.post("/library/taste/seed", json={}, headers=as_user(acct[0])).status_code == 400


# --- home ----------------------------------------------------------------------------------


def test_home_of_a_new_profile_lists_taste_genres_loved_first(client, as_user, acct):
    put(client, as_user, acct, 2, genres={"Comedy": 1, "Action": 2, "Horror": -1, "Drama": 2})
    body = client.get("/home?tz_offset_minutes=0", headers=as_user(acct[0], acct[2])).json()
    section = next(s for s in body["sections"] if s["type"] == "genres")
    assert section["items"] == [{"genre": "Action", "weight": 2}, {"genre": "Drama", "weight": 2},
                                {"genre": "Comedy", "weight": 1}]
    bare = client.get("/home?tz_offset_minutes=0", headers=as_user(acct[0], acct[1])).json()
    assert "genres" not in [s["type"] for s in bare["sections"]]
