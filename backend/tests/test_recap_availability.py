"""Recap availability (cinematic §9.1.5): local rows only, never an AI call."""

from __future__ import annotations

import json
from datetime import timedelta

import pytest
from sqlalchemy import event

from core.time_utils import utcnow
from database.models import ChapterOcr, ChapterProgress, NovelChapterCache
from services import ai_desk, deepseek_client, suggestion_service
from services.followed_series_service import FollowedSeriesService
from services.recap_service import RecapService
from services.suggestion_service import SuggestionService
from tests import _home_stubs
from tests._fakes import FakeBrowse

SRC, NOVEL = "hm_manga", "hm_novel"


@pytest.fixture(autouse=True)
def _env(monkeypatch, tmp_path):
    _home_stubs.install(monkeypatch)
    monkeypatch.setattr(suggestion_service, "BUDGET_PATH", tmp_path / "s.json")
    monkeypatch.setattr(suggestion_service, "ACCOUNT_BUDGET_PATH", tmp_path / "a.json")
    monkeypatch.setattr(deepseek_client, "is_configured", lambda: True)

    def boom(*a, **k):
        raise AssertionError("recap availability must never call the AI")

    monkeypatch.setattr(deepseek_client, "complete_json", boom)


@pytest.fixture
def svc(db_session, make_user, make_profile, seed_follow):
    user = make_user("recapper")
    profile = make_profile(user.id, "Main")
    lib = FollowedSeriesService(db_session, FakeBrowse({}), user_id=user.id, profile_id=profile.id)
    suggest = SuggestionService(db_session, lib, is_admin=True)
    svc = RecapService(db_session, lib, suggest)
    svc.uid, svc.pid, svc.suggest, svc.db = user.id, profile.id, suggest, db_session
    return svc


def read(svc, n_chapters, *, source=SRC, series="s", days_apart=1, upto=None):
    """Completed chapters c1..cN, one per ``days_apart``, plus the target c{N+1}."""
    base = utcnow() - timedelta(days=days_apart * n_chapters + 1)
    for i in range(1, n_chapters + 1):
        svc.db.add(ChapterProgress(
            user_id=svc.uid, profile_id=svc.pid, source_id=source, series_key=series,
            chapter_key=f"c{i}", chapter_number=float(i), is_completed=True,
            last_read_at=base + timedelta(days=days_apart * i),
        ))
    svc.db.add(ChapterProgress(
        user_id=svc.uid, profile_id=svc.pid, source_id=source, series_key=series,
        chapter_key=f"c{n_chapters + 1}", chapter_number=float(n_chapters + 1),
        last_page=2, page_count=10, last_read_at=utcnow(),
    ))
    svc.db.commit()


def ocr(svc, keys, *, source=SRC, series="s"):
    for k in keys:
        svc.db.add(ChapterOcr(source_id=source, series_key=series, chapter_key=k,
                              word_count=40, full_text="hello"))
    svc.db.commit()


def test_range_is_twelve_newest_first(svc):
    read(svc, 14)
    ocr(svc, [f"c{i}" for i in range(1, 15)])
    got = svc.availability(SRC, "s", "c15")
    assert got["available"] and got["reason"] == "ok" and got["cached"] is False
    assert got["range"] == {"from_key": "c3", "to_key": "c14", "from_number": 3, "to_number": 14}
    assert got["est_seconds"] == 104


def test_a_61_day_gap_stops_the_walk(svc):
    read(svc, 5, days_apart=1)
    # chapters 6..8 read 61+ days after chapter 5 would be newer; instead push 1..2 far back
    old = utcnow() - timedelta(days=300)
    for row in svc.db.query(ChapterProgress).filter(ChapterProgress.chapter_number <= 2):
        row.last_read_at = old
    svc.db.commit()
    ocr(svc, [f"c{i}" for i in range(1, 6)])
    got = svc.availability(SRC, "s", "c6")
    assert got["range"]["from_key"] == "c3" and got["range"]["to_key"] == "c5"


def test_chapter_scope_is_one_chapter(svc):
    read(svc, 6)
    ocr(svc, ["c6"])
    got = svc.availability(SRC, "s", "c7", scope="chapter")
    assert got["range"]["from_key"] == got["range"]["to_key"] == "c6"
    assert got["est_seconds"] == 20


def test_first_chapter_has_an_empty_range(svc):
    read(svc, 0)
    got = svc.availability(SRC, "s", "c1")
    assert got == {"available": False, "reason": "first_chapter", "range": None,
                   "est_seconds": 0, "cached": False}


def test_manga_needs_half_its_chapters_to_have_dialogue(svc):
    read(svc, 12)
    ocr(svc, [f"c{i}" for i in range(1, 6)])
    assert svc.availability(SRC, "s", "c13")["reason"] == "no_dialogue"
    ocr(svc, ["c6"])
    assert svc.availability(SRC, "s", "c13")["reason"] == "ok"


def test_novel_range_is_trimmed_to_cached_text(svc):
    read(svc, 12, source=NOVEL)
    assert svc.availability(NOVEL, "s", "c13")["reason"] == "no_dialogue"
    for k in ("c2", "c5", "c9"):
        svc.db.add(NovelChapterCache(source_id=NOVEL, series_key="s", chapter_key=k,
                                     paragraphs="[]"))
    svc.db.commit()
    got = svc.availability(NOVEL, "s", "c13")
    assert got["available"] and got["range"]["from_key"] == "c2" and got["range"]["to_key"] == "c9"
    assert got["est_seconds"] == round((40 + 30 * 3) / 230 * 60)


def test_cached_recap_is_available_even_with_the_ask_ledger_spent(svc, monkeypatch):
    from database.models import AiResultCache

    read(svc, 12)
    ocr(svc, [f"c{i}" for i in range(1, 13)])
    monkeypatch.setattr(deepseek_client, "spent_today", lambda path=None: 10**6)
    assert svc.availability(SRC, "s", "c13")["reason"] == "budget_exhausted"
    key = ai_desk.cache_key("recap", "prose", "series", SRC, "s", "c1", "c12")
    svc.db.add(AiResultCache(key=key, kind="recap", payload="{}", model="m",
                             generated_at=utcnow(), expires_at=utcnow() + timedelta(days=1)))
    svc.db.commit()
    got = svc.availability(SRC, "s", "c13")
    assert got["available"] and got["cached"] and got["reason"] == "ok"


def test_ask_allowance_reasons(svc, monkeypatch):
    read(svc, 12)
    ocr(svc, [f"c{i}" for i in range(1, 13)])
    monkeypatch.setattr(deepseek_client, "is_configured", lambda: False)
    got = svc.availability(SRC, "s", "c13")
    assert (got["available"], got["reason"]) == (False, "not_configured")
    assert got["range"] is not None


def test_est_seconds_for_one_chapter_and_twelve(svc):
    read(svc, 2)
    ocr(svc, ["c1", "c2"])
    assert svc.availability(SRC, "s", "c3")["est_seconds"] == round(100 / 230 * 60)


def test_availability_many_uses_a_bounded_number_of_queries(svc):
    for i in range(10):
        read(svc, 4, series=f"s{i}")
        ocr(svc, ["c1", "c2", "c3", "c4"], series=f"s{i}")
    rows = [(SRC, f"s{i}", "c5") for i in range(10)]
    seen: list[str] = []
    engine = svc.db.get_bind()

    def count(conn, cursor, statement, *a):
        seen.append(statement)

    event.listen(engine, "before_cursor_execute", count)
    try:
        out = svc.availability_many(rows)
    finally:
        event.remove(engine, "before_cursor_execute", count)
    assert len(out) == 10 and all(o["available"] for o in out)
    assert len(seen) <= 6, seen


def test_continue_reading_rows_carry_recap(client, as_user, make_user, make_profile,
                                            seed_follow, db_session):
    user = make_user("cr")
    profile = make_profile(user.id, "Main")
    seed_follow(user.id, profile.id, source_id=SRC, series_key="s", title="S",
                known_chapters=json.dumps([{"key": f"c{i}", "number": i} for i in range(1, 5)]))
    for i in (1, 2):
        db_session.add(ChapterProgress(user_id=user.id, profile_id=profile.id, source_id=SRC,
                                       series_key="s", chapter_key=f"c{i}", chapter_number=float(i),
                                       is_completed=True, last_read_at=utcnow()))
    db_session.commit()
    ocr_rows = [ChapterOcr(source_id=SRC, series_key="s", chapter_key=k, word_count=9) for k in ("c1", "c2")]
    db_session.add_all(ocr_rows)
    db_session.commit()
    resp = client.get("/library/continue-reading", headers=as_user(user.id, profile.id))
    assert resp.status_code == 200
    row = resp.json()[0]
    assert row["chapter_key"] == "c3" and row["title"] == "S"
    assert row["recap"]["available"] is True
    assert row["recap"]["range"]["to_key"] == "c2"
    assert "ambient" in row and resp.headers["X-Total-Count"] == "1"
