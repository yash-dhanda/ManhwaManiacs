"""Catalogue search inside a genre, and a source's own content rating."""

from __future__ import annotations

from connectors.models import BrowseMode, PaginatedSeriesList, Series
from services import browse_service as bs
from services.browse_service import BrowseService

SRC = "stub-source"


class _Stub:
    is_browsable = True
    is_mature = False
    content_kind = "manga"

    def __init__(self, items: list[Series]) -> None:
        self.items = items
        self.searches: list[str] = []

    def list_genres(self) -> list[BrowseMode]:
        return [BrowseMode(id="martial-arts", label="Martial Arts")]

    def search_series(self, query: str, page: int, *, sort: str | None = None) -> PaginatedSeriesList:
        self.searches.append(query)
        return PaginatedSeriesList(items=list(self.items), page=page, page_size=20, total=len(self.items))


def test_search_inside_a_genre_searches_the_words_and_keeps_the_genre(monkeypatch):
    stub = _Stub([
        Series(id="a", title="Solo A", genres=["Martial Arts"]),
        Series(id="b", title="Solo B", genres=["Romance"]),
        Series(id="c", title="Solo C"),
    ])
    monkeypatch.setattr(bs, "create_connector", lambda source_id, **_cfg: stub)
    out = BrowseService(mature_enabled=True).list_series(SRC, query="solo", genre="martial-arts")
    assert stub.searches == ["solo"]
    assert [i["id"] for i in out["items"]] == ["a", "c"]


def test_live_rows_honour_the_source_content_rating(monkeypatch):
    stub = _Stub([
        Series(id="e", title="Solo E", content_rating="erotica"),
        Series(id="s", title="Solo S", content_rating="safe"),
    ])
    monkeypatch.setattr(bs, "create_connector", lambda source_id, **_cfg: stub)
    out = BrowseService(mature_enabled=False).list_series(SRC, query="solo")
    assert [i["id"] for i in out["items"]] == ["s"]
