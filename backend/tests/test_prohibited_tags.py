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
