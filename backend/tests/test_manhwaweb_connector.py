from __future__ import annotations

import json
from pathlib import Path
from unittest.mock import patch

import pytest

from connectors.http.client import ConnectorHttpError
from connectors.http.redirect_policy import host_matches_allowlist
from connectors.manhwaweb.connector import (
    ManhwaWebConnector,
    page_id_chapter_id,
    parse_chapters,
    parse_library,
    parse_pages,
)

FIXTURES = Path(__file__).parent / "fixtures" / "manhwaweb"


def _load(name: str):
    return json.loads((FIXTURES / name).read_text(encoding="utf-8"))


@pytest.fixture
def connector() -> ManhwaWebConnector:
    return ManhwaWebConnector()


def _route(routes: dict[str, object]):
    """Fake ``get_json_value``: answer by path, raise like the client on a miss."""

    calls: list[tuple[str, dict | None]] = []

    def fake(path: str, *, params=None):
        calls.append((path, params))
        if path in routes:
            return routes[path]
        raise ConnectorHttpError("Client error '404 Not Found'", status_code=None)

    return fake, calls


def test_identity_and_hosts(connector: ManhwaWebConnector):
    assert connector.source_type == "manhwaweb"
    assert connector.is_mature is True
    assert connector.image_fetch_headers()["Referer"] == "https://manhwaweb.com/"
    for host in ("img1mw.xyz", "img2mw.xyz", "imagizer.imageshack.com", "ccdn.lezhin.com"):
        assert host_matches_allowlist(host, connector.allowed_image_hosts)
    assert not host_matches_allowlist("example.com", connector.allowed_image_hosts)


def test_browse_requests_adult_shelf_and_maps_cards(connector: ManhwaWebConnector):
    fake, calls = _route({"/manhwa/library": _load("library_popular_p0.json")})
    with patch.object(connector._http, "get_json_value", side_effect=fake):
        listing = connector.get_series_list(1)

    path, params = calls[0]
    assert path == "/manhwa/library"
    assert params["erotico"] == "si"
    assert params["order_item"] == "popularidad"
    assert params["page"] == 0  # the API is 0-based
    assert len(listing.items) == 12
    assert listing.has_more is True
    first = listing.items[0]
    assert first.id == "mom_swap_1737633796754"
    assert first.title == "Plan de Intercambio de Madres"
    assert first.cover_url.startswith("https://img2mw.xyz/")
    assert first.genres == ("Drama", "Milf", "Ecchi")  # unknown ids dropped


def test_browse_modes_map_to_order_items(connector: ManhwaWebConnector):
    fake, calls = _route({"/manhwa/library": _load("library_end.json")})
    with patch.object(connector._http, "get_json_value", side_effect=fake):
        connector.get_series_list(3, sort="latest")
    assert calls[0][1]["order_item"] == "creacion"
    assert calls[0][1]["page"] == 2


def test_end_of_catalogue_is_empty():
    listing = parse_library(_load("library_end.json"), page=99)
    assert listing.items == []
    assert listing.has_more is False


def test_search_uses_buscar(connector: ManhwaWebConnector):
    fake, calls = _route({"/manhwa/library": _load("search_amo.json")})
    with patch.object(connector._http, "get_json_value", side_effect=fake):
        listing = connector.search_series("amo", 1)
    assert calls[0][1]["buscar"] == "amo"
    assert calls[0][1]["erotico"] == "si"
    assert listing.items[0].title == "¿Te amo?"
    assert all("amo" in s.title.casefold() for s in listing.items[:4])


def test_series_chapters_pages_and_find_page(connector: ManhwaWebConnector):
    fake, calls = _route(
        {
            "/manhwa/see/countryside_1681701042099": _load("series_countryside.json"),
            "/chapters/see/countryside_1681701042099-12_01": _load("chapter_countryside_12.json"),
        }
    )
    with patch.object(connector._http, "get_json_value", side_effect=fake):
        series = connector.get_series("countryside_1681701042099")
        chapters = connector.get_chapters("countryside_1681701042099")
        pages = connector.get_chapter_pages("countryside_1681701042099-12_01")
        found = connector.find_page(pages[2].id)

    assert series is not None
    assert series.title == "¿Viviremos Juntos en el Campo?"
    assert series.cover_url.startswith("https://ccdn.lezhin.com/")
    assert series.description and series.author
    # One /manhwa/see call serves both the metadata and the chapter list.
    assert [c[0] for c in calls].count("/manhwa/see/countryside_1681701042099") == 1
    assert [c.id for c in chapters] == [
        f"countryside_1681701042099-{n}_01" for n in (11, 12, 13, 14)
    ]
    assert [c.number for c in chapters] == [11.0, 12.0, 13.0, 14.0]
    assert len(pages) == 12
    assert pages[0].remote_url == (
        "https://img1mw.xyz/manhwas/countryside_1681701042099/chapter_12/ver_01/001.jpg"
    )
    assert found == pages[2]


def test_chapter_link_falls_back_to_versions():
    chapters = parse_chapters(_load("series_versions_only.json"), series_id="s")
    assert chapters[0].id == "historia-de-sexo_1790455123129-1_01"
    assert chapters[0].release_date == "2026-09-26"


def test_offsite_chapter_links_are_skipped():
    payload = _load("series_teamo.json")
    payload["chapters"][0]["link"] = "https://www.lezhin.com/ko/comic/x/1"
    payload["chapters"][0]["versions"] = []
    ids = [c.id for c in parse_chapters(payload, series_id="teamo_1747080624029")]
    assert "teamo_1747080624029-1" not in ids
    assert ids[0] == "teamo_1747080624029-2"


def test_imageshack_chapter_pages_parse():
    pages = parse_pages(_load("chapter_teamo_25.json"), chapter_id="teamo_1747080624029-25")
    assert len(pages) == 30
    assert pages[0].remote_url.startswith("https://imagizer.imageshack.com/")


def test_failures_return_empty(connector: ManhwaWebConnector):
    fake, _ = _route({})
    with patch.object(connector._http, "get_json_value", side_effect=fake):
        assert connector.get_series("missing_1") is None
        assert connector.get_chapters("missing_1") == []
        assert connector.get_chapter_pages("missing_1-1") == []
        assert connector.find_page("missing_1-1:1") is None
        listing = connector.get_series_list(1)
    assert listing.items == [] and listing.has_more is False


def test_empty_page_list_is_not_cached(connector: ManhwaWebConnector):
    empty = {"chapter": {"chapter": 1, "img": []}}
    fake, calls = _route({"/chapters/see/x_1-1": empty})
    with patch.object(connector._http, "get_json_value", side_effect=fake):
        assert connector.get_chapter_pages("x_1-1") == []
        assert connector.get_chapter_pages("x_1-1") == []
    assert len(calls) == 2


def test_page_id_round_trip():
    assert page_id_chapter_id("countryside_1681701042099-12_01:3") == "countryside_1681701042099-12_01"
    assert page_id_chapter_id("no-number") is None
