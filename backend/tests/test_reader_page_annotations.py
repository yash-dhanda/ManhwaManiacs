"""Page tint and panel reports: clients post, the manifest serves (backend/06).

The server never decodes an image. It remembers what a client reports, keyed by
the page's proxy URL, and hands it to every profile that may see the chapter.
"""

from __future__ import annotations

import pytest
from sqlalchemy import event, func, select

import services.browse_service as browse_mod
from core.errors import AppError
from database.models import ReaderPageAnnotation
from services.browse_service import get_browse_service
from tests._fakes import FakeBrowse

SRC = "mangadex"
MATURE = "toonily"
SERIES = "omniscient-reader"


def fixture(src: str = SRC) -> dict:
    return {
        (src, SERIES): {
            "meta": {"title": "OR"},
            "chapters": [
                {"id": f"ch-{n}", "number": float(n), "title": f"E{n}"}
                for n in range(1, 4)
            ],
            "pages": {
                f"ch-{n}": [
                    {"number": p, "image_url": f"/sources/{src}/pages/c{n}p{p}/image"}
                    for p in range(1, 4)
                ]
                for n in range(1, 4)
            },
        }
    }


@pytest.fixture
def fake():
    return FakeBrowse(fixture())


@pytest.fixture
def acct(make_user, make_profile):
    u = make_user("riya")
    return u.id, make_profile(u.id, "Riya").id


@pytest.fixture
def other(make_user, make_profile):
    u = make_user("aarav")
    return u.id, make_profile(u.id, "Aarav").id


@pytest.fixture
def api(app, client, fake):
    app.dependency_overrides[get_browse_service] = lambda: fake
    return client


@pytest.fixture
def h(as_user, acct):
    return as_user(*acct)


@pytest.fixture
def h2(as_user, other):
    return as_user(*other)


def ident(src=SRC, chapter="ch-1"):
    return {"source_id": src, "series_key": SERIES, "chapter_key": chapter}


def post_tints(api, h, tints, **kw):
    return api.post("/reader/page-tints", json={**ident(**kw), "tints": tints}, headers=h)


def post_panels(api, h, pages, **kw):
    return api.post("/reader/panels", json={**ident(**kw), "pages": pages}, headers=h)


def manifest(api, h, chapter="ch-1", src=SRC):
    r = api.get(
        "/reader/chapter/manifest",
        params={"source": src, "series": SERIES, "chapter": chapter},
        headers=h,
    )
    assert r.status_code == 200, r.text
    return r.json()


FULL = {"x": 0, "y": 0, "w": 1, "h": 1}


def test_tints_are_a_shared_cache(api, h, h2, db_session):
    r = post_tints(
        api, h,
        [{"page": 1, "hex": "#3a5f8c"}, {"page": 2, "hex": "#8C3A3A"},
         {"page": 3, "hex": "#112233"}],
    )
    assert r.status_code == 204 and r.content == b""
    assert db_session.scalar(select(func.count()).select_from(ReaderPageAnnotation)) == 3
    m = manifest(api, h2)
    assert [p["tint"] for p in m["pages"]] == ["#3A5F8C", "#8C3A3A", "#112233"]
    assert m["panels_ready"] is False
    assert all("panels" not in p for p in m["pages"])


def test_unknown_pages_and_null_tints_store_nothing(api, h, db_session):
    r = post_tints(api, h, [{"page": 9, "hex": "#3A5F8C"}, {"page": 1, "hex": None}])
    assert r.status_code == 204
    assert db_session.scalar(select(func.count()).select_from(ReaderPageAnnotation)) == 0
    assert all("tint" not in p for p in manifest(api, h)["pages"])


@pytest.mark.parametrize("hexv", ["3A5F8C", "#3A5F8", "#GGGGGG"])
def test_bad_hex_is_422(api, h, hexv):
    assert post_tints(api, h, [{"page": 1, "hex": hexv}]).status_code == 422


def test_panels_round_trip_and_ready(api, h):
    two = [{"x": 0, "y": 0, "w": 1, "h": 0.5}, {"x": 0, "y": 0.5, "w": 1, "h": 0.5}]
    assert post_panels(api, h, [{"page": 1, "panels": two}, {"page": 2, "panels": []}]).status_code == 204
    m = manifest(api, h)
    assert m["pages"][0]["panels"] == two
    assert m["pages"][1]["panels"] == []
    assert "panels" not in m["pages"][2]
    assert m["panels_ready"] is False
    post_panels(api, h, [{"page": 3, "panels": [FULL]}])
    assert manifest(api, h)["panels_ready"] is True


@pytest.mark.parametrize(
    "panel",
    [{"x": 0.5, "y": 0, "w": 0.7, "h": 1}, {"x": 0, "y": 0, "w": 0, "h": 1},
     {"x": -0.1, "y": 0, "w": 1, "h": 1}],
)
def test_bad_panel_is_422(api, h, panel):
    assert post_panels(api, h, [{"page": 1, "panels": [panel]}]).status_code == 422


def test_65_panels_is_422(api, h):
    cell = {"x": 0, "y": 0, "w": 0.01, "h": 0.01}
    assert post_panels(api, h, [{"page": 1, "panels": [cell] * 65}]).status_code == 422
    assert post_panels(api, h, [{"page": 1, "panels": [cell] * 64}]).status_code == 204


def test_rekeyed_page_does_not_inherit(api, h, fake):
    post_tints(api, h, [{"page": n, "hex": "#010203"} for n in (1, 2, 3)])
    post_panels(api, h, [{"page": n, "panels": [FULL]} for n in (1, 2, 3)])
    fake.series[(SRC, SERIES)]["pages"]["ch-1"][1]["image_url"] = "/sources/mangadex/pages/NEW/image"
    m = manifest(api, h)
    assert "tint" in m["pages"][0] and "tint" in m["pages"][2]
    assert "tint" not in m["pages"][1] and "panels" not in m["pages"][1]
    assert m["panels_ready"] is False


def _bulk(api, h, keys):
    r = api.post(
        "/reader/chapters/manifest",
        json={"source_id": SRC, "series_key": SERIES, "chapter_keys": keys},
        headers=h,
    )
    assert r.status_code == 200, r.text
    return r.json()


def test_bulk_equals_single_with_one_query(api, h, db_engine):
    post_tints(api, h, [{"page": 1, "hex": "#AABBCC"}], chapter="ch-1")
    post_panels(api, h, [{"page": n, "panels": [FULL]} for n in (1, 2, 3)], chapter="ch-2")
    seen: list[str] = []

    def spy(conn, cursor, statement, *a):
        if "reader_page_annotations" in statement:
            seen.append(statement)

    event.listen(db_engine, "before_cursor_execute", spy)
    try:
        body = _bulk(api, h, ["ch-1", "ch-2", "ch-3"])
    finally:
        event.remove(db_engine, "before_cursor_execute", spy)
    assert len(seen) == 1
    for item in body["items"]:
        assert item["manifest"] == manifest(api, h, item["chapter_key"])
    assert body["items"][1]["manifest"]["panels_ready"] is True
    assert body["items"][0]["manifest"]["pages"][0]["tint"] == "#AABBCC"


def test_get_panels_serves_rows_and_calls_no_connector(api, h, fake):
    post_panels(api, h, [{"page": 1, "panels": [FULL]}, {"page": 2, "panels": []}])
    fake.calls.clear()

    def boom(*a, **k):
        raise AssertionError("connector touched")

    fake.get_chapter_pages = fake.get_chapters = fake.get_series = boom
    r = api.get(
        "/reader/panels",
        params={"source": SRC, "series": SERIES, "chapter": "ch-1"},
        headers=h,
    )
    assert r.status_code == 200, r.text
    b = r.json()
    assert b["pages"] == [{"page": 1, "panels": [FULL]}, {"page": 2, "panels": []}]
    assert b["panels_ready"] is False and b["chapter_key"] == "ch-1"


def test_get_panels_ready_when_every_page_reported(api, h):
    post_panels(api, h, [{"page": n, "panels": [FULL]} for n in (1, 2, 3)])
    r = api.get(
        "/reader/panels",
        params={"source": SRC, "series": SERIES, "chapter": "ch-1"},
        headers=h,
    )
    assert r.json()["panels_ready"] is True


def test_profile_scoping(api, h, as_user, acct, other, make_user):
    body = {**ident(), "tints": [{"page": 1, "hex": "#010203"}]}
    uid, _pid = acct
    assert api.post("/reader/page-tints", json=body, headers=as_user(uid)).json()["code"] == "profile_required"
    assert api.post("/reader/panels", json={**ident(), "pages": [{"page": 1, "panels": []}]},
                    headers=as_user(uid)).json()["code"] == "profile_required"
    r = api.post("/reader/page-tints", json=body, headers=as_user(uid, other[1]))
    assert r.status_code == 404 and r.json()["code"] == "profile_not_found"
    r = api.post("/reader/panels", json={**ident(), "pages": [{"page": 1, "panels": []}]},
                 headers=as_user(uid, other[1]))
    assert r.status_code == 404 and r.json()["code"] == "profile_not_found"


def test_gate(app, client, h, db_session):
    fake = FakeBrowse(fixture(MATURE))
    fake.mature_sources = {MATURE}
    fake.gate_open = False
    app.dependency_overrides[get_browse_service] = lambda: fake
    assert post_tints(client, h, [{"page": 1, "hex": "#010203"}], src=MATURE).status_code == 404
    assert post_panels(client, h, [{"page": 1, "panels": []}], src=MATURE).status_code == 404
    assert db_session.scalar(select(func.count()).select_from(ReaderPageAnnotation)) == 0
    for url, params in (
        ("/reader/chapter/manifest", {"source": MATURE, "series": SERIES, "chapter": "ch-1"}),
        ("/reader/panels", {"source": MATURE, "series": SERIES, "chapter": "ch-1"}),
    ):
        assert client.get(url, params=params, headers=h).status_code == 404
    fake.gate_open = True
    assert post_tints(client, h, [{"page": 1, "hex": "#010203"}], src=MATURE).status_code == 204
    assert post_panels(client, h, [{"page": 1, "panels": []}], src=MATURE).status_code == 204
    r = client.get("/reader/panels", params={"source": MATURE, "series": SERIES, "chapter": "ch-1"}, headers=h)
    assert r.status_code == 200 and r.json()["pages"] == [{"page": 1, "panels": []}]


def test_no_image_work(api, h, monkeypatch):
    def boom(*a, **k):
        raise AssertionError("image work")

    monkeypatch.setattr(browse_mod.BrowseService, "resolve_page_image", boom, raising=False)
    monkeypatch.setattr(browse_mod.BrowseService, "resolve_series_cover", boom, raising=False)
    assert post_tints(api, h, [{"page": 1, "hex": "#010203"}]).status_code == 204
    assert post_panels(api, h, [{"page": 1, "panels": [FULL]}]).status_code == 204
    manifest(api, h)
    assert api.get("/reader/panels", params={"source": SRC, "series": SERIES, "chapter": "ch-1"},
                   headers=h).status_code == 200


def test_upstream_failure_is_204_and_stores_nothing(api, h, fake, db_session):
    def down(*a, **k):
        raise AppError("upstream", code="upstream_error", status_code=502)

    fake.get_chapter_pages = down
    assert post_tints(api, h, [{"page": 1, "hex": "#010203"}]).status_code == 204
    assert post_panels(api, h, [{"page": 1, "panels": [FULL]}]).status_code == 204
    assert db_session.scalar(select(func.count()).select_from(ReaderPageAnnotation)) == 0
