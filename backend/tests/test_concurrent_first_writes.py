"""Two requests creating the same row at once: the loser must not get a 500.

Each of these reads "no row", does slow work (an upstream fetch), then INSERTs
against a unique key. Two requests overlapping in that window both insert, and
the second tripped the UNIQUE constraint as an unhandled ``IntegrityError``.
"""

from __future__ import annotations

import threading

import pytest
from sqlalchemy import create_engine, event, func, select
from sqlalchemy.orm import sessionmaker

from database.models import (
    Base,
    FollowedSeries,
    ReaderPageAnnotation,
    ReadingProfile,
    SourceSeriesCache,
    User,
)
from services.followed_series_service import FollowedSeriesService
from services.page_annotations import page_etag, store_tints
from services.source_cache_service import SourceCacheService
from tests._fakes import FakeBrowse

SRC = "mangadex"
KEY = "series-1"
FIXTURE = {
    (SRC, KEY): {
        "meta": {"title": "Series One", "genres": ["action"]},
        "chapters": [
            {"id": "c1", "number": 1.0, "title": "1"},
            {"id": "c2", "number": 2.0, "title": "2"},
        ],
    }
}


@pytest.fixture
def factory(tmp_path):
    engine = create_engine(
        f"sqlite:///{tmp_path / 'race.db'}", connect_args={"check_same_thread": False}
    )

    @event.listens_for(engine, "connect")
    def _pragmas(dbapi_connection, _record):
        cur = dbapi_connection.cursor()
        cur.execute("PRAGMA journal_mode=WAL")
        cur.execute("PRAGMA foreign_keys=ON")
        cur.execute("PRAGMA busy_timeout=5000")
        cur.close()

    Base.metadata.create_all(engine)
    yield sessionmaker(
        bind=engine, autoflush=False, autocommit=False, expire_on_commit=False
    )
    engine.dispose()


class _RacingBrowse(FakeBrowse):
    """Both callers reach the "network" before either one writes."""

    def __init__(self, series, barrier):
        super().__init__(series)
        self._barrier = barrier

    def get_chapters(self, source_id, series_key):
        self._barrier.wait()
        return super().get_chapters(source_id, series_key)


def _run_two(work):
    errors: dict[int, BaseException] = {}
    results: dict[int, object] = {}

    def runner(n: int) -> None:
        try:
            results[n] = work(n)
        except BaseException as exc:  # noqa: BLE001
            errors[n] = exc

    threads = [threading.Thread(target=runner, args=(n,)) for n in (0, 1)]
    for t in threads:
        t.start()
    for t in threads:
        t.join(timeout=20)
    return results, errors


def test_two_cold_series_fetches_both_succeed_and_one_row_exists(factory):
    barrier = threading.Barrier(2, timeout=10)

    def work(_n):
        db = factory()
        try:
            return SourceCacheService(db, _RacingBrowse(FIXTURE, barrier)).get_series_meta(
                SRC, KEY
            )
        finally:
            db.close()

    results, errors = _run_two(work)
    assert errors == {}, {k: repr(v)[:200] for k, v in errors.items()}
    assert [len(r["chapters"]) for r in results.values()] == [2, 2]
    with factory() as s:
        assert s.scalar(select(func.count()).select_from(SourceSeriesCache)) == 1


def test_metadata_only_merge_onto_a_racing_row_does_not_extend_freshness(factory):
    """The loser of a metadata-only write must treat the winner's row as
    existing: no ``fetched_at`` bump."""
    with factory() as s:
        cache = SourceCacheService(s, FakeBrowse())
        row = cache._upsert(SRC, KEY, {"title": "T"}, [{"id": "c1", "number": 1}])
        fetched = row.fetched_at
    with factory() as s:
        cache = SourceCacheService(s, FakeBrowse())
        merged = cache._merge_series_row(SRC, KEY, {"title": "T2"}, None)
        s.commit()
        assert merged.fetched_at == fetched
        assert merged.title == "T2"


def _seed_profile(factory):
    with factory() as s:
        user = User(username="u", password_hash="x", is_admin=False, is_active=True)
        s.add(user)
        s.commit()
        prof = ReadingProfile(user_id=user.id, name="P", sort_order=0)
        s.add(prof)
        s.commit()
        return user.id, prof.id


def test_a_double_tapped_follow_is_an_idempotent_success(factory):
    uid, pid = _seed_profile(factory)
    barrier = threading.Barrier(2, timeout=10)

    def work(_n):
        db = factory()
        try:
            browse = _RacingBrowse(FIXTURE, barrier)
            return FollowedSeriesService(
                db, browse, user_id=uid, profile_id=pid
            ).follow(SRC, KEY)
        finally:
            db.close()

    results, errors = _run_two(work)
    assert errors == {}, {k: repr(v)[:200] for k, v in errors.items()}
    assert results[0]["id"] == results[1]["id"]
    with factory() as s:
        assert s.scalar(select(func.count()).select_from(FollowedSeries)) == 1


def test_two_readers_reporting_the_same_page_both_succeed(factory):
    pages = [{"number": 1, "url": "/p/1"}, {"number": 2, "url": "/p/2"}]
    barrier = threading.Barrier(2, timeout=10)

    from sqlalchemy.orm import Session

    # Holds both reporters between their SELECT and their INSERT.
    original = Session.commit

    def commit_after_both_selected(self):
        if getattr(self, "_race_gate", False):
            self._race_gate = False
            barrier.wait()
        return original(self)

    def work(n):
        db = factory()
        db._race_gate = True
        try:
            store_tints(db, SRC, KEY, "c1", pages, [(1, "#AABBCC")])
        finally:
            db.close()

    Session.commit = commit_after_both_selected
    try:
        results, errors = _run_two(work)
    finally:
        Session.commit = original
    assert errors == {}, {k: repr(v)[:200] for k, v in errors.items()}
    with factory() as s:
        rows = s.scalars(select(ReaderPageAnnotation)).all()
        assert [(r.page_etag, r.tint) for r in rows] == [(page_etag("/p/1"), "#AABBCC")]
