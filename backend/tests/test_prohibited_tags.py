"""Tags marking sexualised depictions of minors are never browsable.

Not the 18+ gate: several adult sources publish these as ordinary genres and
two connectors listed them as browse categories. A row carrying one is withheld
from every caller whatever their settings, the genres are not offered, and a
search for the words is refused before any request leaves for a source.
"""

from __future__ import annotations

import json

import pytest

from connectors.models import BrowseMode, PaginatedSeriesList, Series
from connectors.registry import create_connector
from core.content_rating import (
    TRACKER_RATING_MATURE,
    has_prohibited_tag,
    hidden_by_gate,
    is_prohibited_text,
    resolve_series_rating,
)
from core.errors import AppError
from database.models import SourceSeriesCache
from services.browse_service import BrowseService, _row_visible
from services.source_cache_service import SourceCacheService


@pytest.mark.parametrize(
    "tag",
    ["Lolicon", "lolicon", "LOLI", "oppai loli", "Shotacon", "shota-con", "straight shota", "Toddlercon"],
)
def test_the_tags_are_recognised(tag):
    assert is_prohibited_text(tag)
    assert has_prohibited_tag(["Romance", tag])


@pytest.mark.parametrize(
    "text",
    ["Lolita Fashion", "Shotgun Wedding", "Romance", "School Life", "Slice of Life", "", None, 7],
)
def test_ordinary_words_are_not(text):
    assert not is_prohibited_text(text)


def test_a_tagged_row_is_mature_and_no_override_lifts_it():
    assert resolve_series_rating(None, ["Lolicon"]) == TRACKER_RATING_MATURE
    assert resolve_series_rating("safe", ["Shotacon"], mature_override=False) == TRACKER_RATING_MATURE
    assert hidden_by_gate(resolve_series_rating(None, ["loli"]), gate_open=False)


def test_a_tagged_row_is_withheld_even_with_the_gate_open():
    tagged = Series(id="s", title="T", genres=("Comedy", "Lolicon"))
    plain = Series(id="p", title="P", genres=("Comedy",))
    for gate_open in (True, False):
        assert not _row_visible(tagged, gate_open=gate_open, source_mature=True)
    assert _row_visible(plain, gate_open=True, source_mature=True)


class _Source:
    """A connector that would happily serve anything it is asked for."""

    source_type = "18porncomic"
    display_name = "Source"
    is_mature = True
    is_browsable = True

    def __init__(self) -> None:
        self.calls: list[tuple] = []

    def list_genres(self):
        return [
            BrowseMode(id="romance", label="Romance"),
            BrowseMode(id="lolicon", label="Lolicon"),
            BrowseMode(id="x", label="Shotacon"),
        ]

    def _page(self):
        return PaginatedSeriesList(
            items=[
                Series(id="a", title="A", genres=("Romance",)),
                Series(id="b", title="B", genres=("Romance", "Shotacon")),
            ],
            page=1,
            page_size=20,
            total=2,
        )

    def get_series_list(self, page, *, sort=None):
        self.calls.append(("list", page, sort))
        return self._page()

    def search_series(self, query, page, *, sort=None):
        self.calls.append(("search", query))
        return self._page()

    def browse_by_genre(self, genre, page, *, sort=None):
        self.calls.append(("genre", genre))
        return self._page()


def _service(monkeypatch) -> tuple[BrowseService, _Source]:
    source = _Source()
    service = BrowseService(mature_enabled=True)
    monkeypatch.setattr(service, "_get_connector", lambda source_id: source)
    return service, source


def test_the_genres_are_not_offered(monkeypatch):
    service, _ = _service(monkeypatch)
    assert service.list_genres("18porncomic") == [{"id": "romance", "label": "Romance"}]


@pytest.mark.parametrize("kwargs", [{"genre": "lolicon"}, {"genre": "Shotacon"}, {"query": "shota"}, {"query": "cute loli"}])
def test_a_genre_or_search_for_them_is_refused_before_the_source_is_asked(monkeypatch, kwargs):
    service, source = _service(monkeypatch)
    with pytest.raises(AppError) as refused:
        service.list_series("18porncomic", **kwargs)
    assert refused.value.status_code == 404
    assert source.calls == []


def test_a_listing_drops_tagged_rows_with_the_gate_open(monkeypatch):
    service, _ = _service(monkeypatch)
    listing = service.list_series("18porncomic")
    assert [item["id"] for item in listing["items"]] == ["a"]


def test_the_shipped_connectors_no_longer_list_them():
    for source_id in ("18porncomic", "mangatown"):
        genres = create_connector(source_id).list_genres()
        assert genres, source_id
        assert not [g for g in genres if is_prohibited_text(g.id) or is_prohibited_text(g.label)]


def test_a_cached_listing_and_a_cached_series_are_withheld_with_the_gate_open(db_session):
    cache = SourceCacheService(db_session, BrowseService(mature_enabled=True))
    payload = {
        "items": [
            {"id": "a", "genres": ["Romance"]},
            {"id": "b", "genres": ["Romance", "Lolicon"]},
        ],
        "total": 2,
    }
    filtered = cache._gate_listing(payload)
    assert [item["id"] for item in filtered["items"]] == ["a"]

    row = SourceSeriesCache(source_id="18porncomic", series_key="b", genres=json.dumps(["Lolicon"]))
    assert cache._rating_hides(row) is True
    plain = SourceSeriesCache(source_id="18porncomic", series_key="a", genres=json.dumps(["Romance"]))
    assert cache._rating_hides(plain) is False


# --- the paths an open gate used to skip ----------------------------------

SRC = "18porncomic"


def _series_row(db, key: str, genres: list[str], chapters: list[str] | None = None):
    db.add(
        SourceSeriesCache(
            source_id=SRC,
            series_key=key,
            title=key,
            genres=json.dumps(genres),
            chapters=json.dumps([{"key": c} for c in chapters]) if chapters is not None else None,
        )
    )
    db.commit()


@pytest.mark.parametrize("gate_open", [True, False])
def test_series_hidden_refuses_a_tagged_series_whatever_the_gate(db_session, gate_open):
    _series_row(db_session, "tagged", ["Romance", "Lolicon"])
    _series_row(db_session, "plain", ["Romance"])
    cache = SourceCacheService(db_session, BrowseService(mature_enabled=gate_open))

    assert cache.series_hidden(SRC, "tagged") is True
    assert cache.series_hidden(SRC, "plain") is False
    assert cache.series_hidden(SRC, "never-seen") is False


def test_a_cached_cover_of_a_tagged_series_is_not_served_with_the_gate_open(db_session):
    _series_row(db_session, "tagged", ["Lolicon"])
    browse = BrowseService(mature_enabled=True)
    browse.ensure_visible = lambda source_id: None
    cache = SourceCacheService(db_session, browse)

    with pytest.raises(AppError) as refused:
        cache.get_series_cover(SRC, "tagged", width=None)
    assert refused.value.code == "series_not_found"


@pytest.mark.parametrize("gate_open", [True, False])
def test_the_chapter_of_a_tagged_series_is_refused_whatever_the_gate(db_session, gate_open):
    _series_row(db_session, "tagged", ["Lolicon"], chapters=["tagged/ch-1"])
    _series_row(db_session, "plain", ["Romance"], chapters=["plain/ch-1"])
    service = BrowseService(mature_enabled=gate_open, db=db_session)
    source = _Source()
    source.is_mature = False  # a general source: only the series' own tag decides

    with pytest.raises(AppError) as refused:
        service._require_visible_chapter(SRC, "tagged/ch-1", source)
    assert refused.value.code == "chapter_not_found"
    service._require_visible_chapter(SRC, "plain/ch-1", source)
    service._require_visible_chapter(SRC, "nobody-has-this", source)


class _TaggedSeriesSource(_Source):
    def get_series(self, series_id):
        return Series(id=series_id, title="T", genres=("Comedy", "Lolicon"))

    def get_chapters(self, series_id):
        return []


@pytest.mark.parametrize("gate_open", [True, False])
def test_a_series_detail_is_refused_whatever_the_gate(monkeypatch, gate_open):
    source = _TaggedSeriesSource()
    service = BrowseService(mature_enabled=gate_open)
    monkeypatch.setattr(service, "_get_connector", lambda source_id: source)

    for call in (service.get_series, service.get_chapters):
        with pytest.raises(AppError) as refused:
            call(SRC, "a")
        assert refused.value.code == "series_not_found"


class _NetworkGenres(_Source):
    """A source whose genre list still advertises a prohibited genre."""

    def list_browse_modes(self):
        return [BrowseMode(id="default", label="Browse")]


class _CacheBrowse:
    """Resolves the connector like ``BrowseService`` does and records calls."""

    def __init__(self, connector, error: Exception | None = None) -> None:
        self._connector = connector
        self._error = error
        self.listed: list[dict] = []

    def _gate_open(self):
        return True

    def ensure_visible(self, source_id):
        return None

    def _get_connector(self, source_id):
        return self._connector

    def list_series(self, source_id, **kwargs):
        self.listed.append(kwargs)
        if self._error is not None:
            raise self._error
        return {"items": [], "page": 1, "page_size": 1, "total": 0, "has_more": False}


def _browse_row(db, genre: str):
    from datetime import timedelta

    from core.time_utils import utcnow
    from database.models import SourceBrowseCache

    db.add(
        SourceBrowseCache(
            source_id=SRC,
            sort="",
            genre=genre,
            page=1,
            payload=json.dumps({"items": [{"id": "a", "genres": ["Romance"]}], "total": 1}),
            fetched_at=utcnow() - timedelta(minutes=1),
        )
    )
    db.commit()


@pytest.mark.parametrize("genre", ["lolicon", "Shotacon"])
def test_a_cached_page_of_a_prohibited_genre_is_never_served(db_session, genre):
    _browse_row(db_session, genre)
    browse = _CacheBrowse(_NetworkGenres())

    with pytest.raises(AppError) as refused:
        SourceCacheService(db_session, browse).get_browse_page(SRC, genre=genre)

    assert refused.value.code == "content_not_available"
    assert browse.listed == []


def test_a_content_refusal_is_never_answered_with_the_stale_row(db_session):
    # Whatever raised it, the refusal is the answer; the old page is not.
    _browse_row(db_session, "romance")
    refusal = AppError("Nothing found.", code="content_not_available", status_code=404)
    browse = _CacheBrowse(_NetworkGenres(), error=refusal)

    with pytest.raises(AppError) as refused:
        SourceCacheService(db_session, browse).get_browse_page(
            SRC, genre="romance", force=True
        )
    assert refused.value.code == "content_not_available"
