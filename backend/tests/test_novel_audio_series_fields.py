"""``rendered_at`` / ``cast_changed_at`` on GET /novels/audio/series, and RE-VOICE."""

from __future__ import annotations

import json
import os
from datetime import datetime, timezone

import pytest

from core.config import get_settings
from database.models import NovelAudioJob, NovelChapterCache
from services.chapter_audio_store import chapter_paths, rendered_chapters

from tests.test_novels_flag import (  # noqa: F401
    SERIES,
    STUB_SOURCE,
    novels_off,
    novels_on,
    stub_registered,
)


@pytest.fixture(autouse=True)
def _box(monkeypatch, tmp_path):
    monkeypatch.setenv("MM_RENDER_WORKER_TOKEN", "a-render-token")
    monkeypatch.setenv("MM_AUDIO_DIR", str(tmp_path))
    get_settings.cache_clear()
    yield
    get_settings.cache_clear()


def cache(db, key, n=1.0):
    db.add(NovelChapterCache(
        source_id=STUB_SOURCE, series_key=SERIES, chapter_key=key,
        title=f"C{n:g}", chapter_number=n, paragraphs=json.dumps(["Line."]), word_count=1))
    db.commit()


def render(key, mtime=None):
    audio, _ = chapter_paths(STUB_SOURCE, SERIES, key)
    audio.parent.mkdir(parents=True, exist_ok=True)
    audio.write_bytes(b"O" * 10)
    if mtime is not None:
        os.utime(audio, (mtime, mtime))
    return audio


def series(client, **kw):
    r = client.get("/novels/audio/series", params={"source": STUB_SOURCE, "series": SERIES}, **kw)
    assert r.status_code == 200, r.text
    return r.json()


def owner_headers(make_user, as_user):
    return as_user(make_user("owner", is_admin=True).id)


def test_rendered_at_is_file_mtime_utc(novels_on, db_session):
    cache(db_session, "ch-1")
    render("ch-1", mtime=1_700_000_000)
    body = series(novels_on)
    want = datetime.fromtimestamp(1_700_000_000, timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    assert body["chapters"][0]["rendered_at"] == want
    assert body["cast_changed_at"] is None


def test_rendered_chapters_default_shape_unchanged(db_session):
    render("ch-1")
    assert rendered_chapters(STUB_SOURCE, SERIES, ["ch-1"]) == {"ch-1": {"bytes": 10, "has_timing": 0}}
    with_m = rendered_chapters(STUB_SOURCE, SERIES, ["ch-1"], with_mtime=True)["ch-1"]
    assert set(with_m) == {"bytes", "has_timing", "rendered_at"}


def test_cast_changed_at_moves_after_each_change(novels_on, db_session, make_user, as_user):
    from datetime import timedelta

    from database.models import NovelSeriesCastState
    h = owner_headers(make_user, as_user)
    body = {"source_id": STUB_SOURCE, "series_key": SERIES}
    assert series(novels_on, headers=h)["cast_changed_at"] is None
    steps = (
        ("/novels/narrator", {**body, "voice_id": None}),
        ("/novels/cast", {**body, "name": "Kim", "gender": "male"}),
        ("/novels/cast/alias", {**body, "alias": "K", "canonical": "Kim"}),
    )
    prev = None
    for path, payload in steps:
        # push the stamp into the past so each change must visibly move it
        state = db_session.get(NovelSeriesCastState, (STUB_SOURCE, SERIES))
        if state is not None:
            state.updated_at = state.updated_at - timedelta(days=1)
            db_session.commit()
        before = series(novels_on, headers=h)["cast_changed_at"]
        r = novels_on.post(path, json=payload, headers=h)
        assert r.status_code == 200, (path, r.text)
        after = series(novels_on, headers=h)["cast_changed_at"]
        assert after is not None and (before is None or after > before)
        prev = after


def test_gated_profile_gets_404_for_mature_source(novels_on, db_session, make_user, make_profile, as_user, monkeypatch):
    import connectors.registry as registry
    from tests.test_novels_flag import StubNovelConnector
    u = make_user("kid")
    p = make_profile(u.id, "Kid")
    monkeypatch.setattr(StubNovelConnector, "MATURE", True)
    registry._INSTANCE_CACHE.pop(STUB_SOURCE, None)
    r = novels_on.get(
        "/novels/audio/series", params={"source": STUB_SOURCE, "series": SERIES},
        headers=as_user(u.id, p.id))
    assert r.status_code == 404


def _revoice_setup(db, make_user, as_user, novels_on):
    h = owner_headers(make_user, as_user)
    for k in ("ch-1", "ch-2", "ch-3"):
        cache(db, k)
    render("ch-1", mtime=1_600_000_000)
    render("ch-2", mtime=4_000_000_000)
    return h


def test_revoice_request_shapes(novels_on, db_session, make_user, as_user):
    h = _revoice_setup(db_session, make_user, as_user, novels_on)
    body = {"source_id": STUB_SOURCE, "series_key": SERIES,
            "chapter_keys": ["ch-1", "ch-2", "ch-3"]}
    plain = novels_on.post("/novels/audio/render", json={**body, "force": False}, headers=h).json()
    assert [q["chapter_key"] for q in plain["queued"]] == ["ch-3"]
    assert {s["reason"] for s in plain["skipped"]} == {"already_rendered", "already_queued"} or \
        [s["reason"] for s in plain["skipped"]] == ["already_rendered", "already_rendered"]
    for row in db_session.query(NovelAudioJob).all():
        db_session.delete(row)
    db_session.commit()
    forced = novels_on.post("/novels/audio/render", json={**body, "force": True, "priority": 0}, headers=h).json()
    assert sorted(q["chapter_key"] for q in forced["queued"]) == ["ch-1", "ch-2", "ch-3"]
    for row in db_session.query(NovelAudioJob).all():
        db_session.delete(row)
    db_session.commit()
    novels_on.post("/novels/audio/render", json={**body, "force": True, "priority": 9}, headers=h)
    assert {j.priority for j in db_session.query(NovelAudioJob).all()} == {9}
