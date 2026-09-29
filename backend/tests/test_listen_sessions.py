"""``POST /novels/listen-sessions`` and the Annual's ``top_voices``."""

from __future__ import annotations

import json

import pytest
from sqlalchemy import func, select

from database.models import ListenSession
from services import voice_pack

STAMP = "2025-03-01T10:00:00"


@pytest.fixture
def pack(tmp_path, monkeypatch):
    monkeypatch.setenv("MM_VOICES_DIR", str(tmp_path))
    for name in ("a.opus", "b.opus"):
        (tmp_path / name).write_bytes(b"OggS")
    clips = [
        {
            "voice_id": vid,
            "name": nm,
            "gender": "male",
            "median_f0_hz": 120.0,
            "pitch_spread": 0.2,
            "seconds": 6.0,
            "license": "CC BY 4.0",
            "attribution": "x",
            "transcript": "t",
            "sample": sample,
        }
        for vid, nm, sample in (("v1", "Atlas", "a.opus"), ("v2", "Lucian", "b.opus"))
    ]
    (tmp_path / "manifest.json").write_text(json.dumps({"version": "t", "clips": clips}))
    voice_pack._cached.cache_clear()
    yield
    voice_pack._cached.cache_clear()


@pytest.fixture
def novels_client(monkeypatch, session_factory, as_user):
    from core.config import get_settings
    from fastapi.testclient import TestClient
    from database.session import get_db
    from main import create_app

    monkeypatch.setenv("MM_NOVELS_ENABLED", "true")
    get_settings.cache_clear()

    def override_get_db():
        db = session_factory()
        try:
            yield db
        finally:
            db.close()

    app = create_app(run_migrations=False, run_workers=False)
    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as c:
        yield c
    get_settings.cache_clear()


@pytest.fixture
def acct(make_user, make_profile):
    user = make_user("listener")
    return user.id, make_profile(user.id, "Main").id, make_profile(user.id, "Other").id


def _item(n=1, **kw):
    base = {
        "source_id": "novelarchive",
        "series_key": "book",
        "chapter_key": f"ch-{n}",
        "seconds": 600,
        "voice_ids": ["v1"],
        "started_at": f"2025-03-0{n}T10:00:00",
    }
    base.update(kw)
    return base


def test_save_replay_and_duplicates(novels_client, as_user, acct, session_factory):
    uid, pid, _ = acct
    h = as_user(uid, pid)
    body = [_item(1), _item(2), _item(3)]
    r = novels_client.post("/novels/listen-sessions", json=body, headers=h)
    assert r.status_code == 200, r.text
    assert r.json() == {"saved": 3, "duplicates": 0, "rejected": []}
    r = novels_client.post("/novels/listen-sessions", json=body, headers=h)
    assert r.json() == {"saved": 0, "duplicates": 3, "rejected": []}
    with session_factory() as s:
        assert s.execute(select(func.count()).select_from(ListenSession)).scalar_one() == 3


def test_batch_cap_and_bad_items(novels_client, as_user, acct):
    uid, pid, _ = acct
    h = as_user(uid, pid)
    r = novels_client.post(
        "/novels/listen-sessions", json=[_item(1)] * 201, headers=h
    )
    assert r.status_code == 413
    assert r.json()["code"] == "batch_too_large"
    body = [_item(1, seconds=5), _item(2), "junk", _item(3, voice_ids=["a", "b", "c", "d"])]
    r = novels_client.post("/novels/listen-sessions", json=body, headers=h)
    out = r.json()
    assert out["saved"] == 1
    assert [x["index"] for x in out["rejected"]] == [0, 2, 3]


def test_unknown_voice_dropped_and_top_voices(
    novels_client, as_user, acct, pack, session_factory
):
    uid, pid, other = acct
    h = as_user(uid, pid)
    body = [
        _item(1, seconds=100, voice_ids=["v1", "v2", "v1"]),
        _item(2, seconds=50, voice_ids=["v1", "ghost"]),
    ]
    assert novels_client.post("/novels/listen-sessions", json=body, headers=h).json()["saved"] == 2
    # another profile's listening never counts
    novels_client.post(
        "/novels/listen-sessions", json=[_item(3, seconds=9000)], headers=as_user(uid, other)
    )
    with session_factory() as s:
        stored = s.execute(select(ListenSession.voice_ids).order_by(ListenSession.id)).scalars().all()
    assert json.loads(stored[0]) == ["v1", "v2"]
    r = novels_client.get("/library/annual?year=2025&tz_offset_minutes=0", headers=h)
    assert r.json()["top_voices"] == [
        {"voice_id": "v1", "name": "Atlas", "seconds": 150},
        {"voice_id": "v2", "name": "Lucian", "seconds": 100},
    ]
    r = novels_client.get("/library/annual?year=2025&tz_offset_minutes=0", headers=as_user(uid, other))
    assert [v["voice_id"] for v in r.json()["top_voices"]] == ["v1"]


def test_404_with_novels_disabled(client, as_user, acct):
    uid, pid, _ = acct
    r = client.post("/novels/listen-sessions", json=[_item(1)], headers=as_user(uid, pid))
    assert r.status_code == 404
