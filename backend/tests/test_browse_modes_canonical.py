"""Canonical popular/latest/new browse ids on the gallery-style connectors."""

from __future__ import annotations

from unittest.mock import patch

import pytest

from connectors.registry import create_connector


def _ids(source: str) -> list[str]:
    return [m.id for m in create_connector(source).list_browse_modes()]


@pytest.mark.parametrize(
    ("source", "expected"),
    [
        ("nhentai", ["latest", "popular", "new", "english"]),
        ("3hentai", ["latest", "popular", "new", "english"]),
        ("ehentai", ["latest", "popular", "new", "english"]),
        ("doujins", ["latest", "popular", "new"]),
        ("akuma", ["latest", "new", "english"]),
        ("mangafreak", ["default", "popular", "latest", "all"]),
        ("comicasura", ["latest", "popular", "rating", "name_asc", "name_desc"]),
    ],
)
def test_advertised_ids_and_order(source, expected):
    assert _ids(source) == expected


def test_8muses_advertised_ids_and_order():
    # Deregistered (its browse returns no series), so built directly.
    from connectors.eightmuses.connector import EightMusesConnector

    ids = [m.id for m in EightMusesConnector().list_browse_modes()]
    assert ids == ["default", "popular", "latest", "new"]


def test_nhentai_new_uses_the_latest_feed_and_popular_its_own():
    connector = create_connector("nhentai")
    seen: list[str] = []
    with patch.object(
        type(connector), "_fetch_listing", lambda self, path, page: seen.append(path) or None
    ), patch("connectors.nhentai.connector.logger"):
        for sort in (None, "latest", "new", "popular"):
            try:
                connector.get_series_list(2, sort=sort)
            except AttributeError:
                pass  # the stubbed listing is None; only the path matters
    assert seen == [
        "/api/v2/galleries", "/api/v2/galleries", "/api/v2/galleries",
        "/api/v2/galleries/popular",
    ]


def test_eightmuses_sort_params_keep_old_ids_and_add_new():
    from connectors.eightmuses.mappers import normalize_sort

    assert normalize_sort(None) is None
    assert normalize_sort("latest") == "date"
    assert normalize_sort("new") == "date"
    assert normalize_sort("popular") == "like"


def test_mangafreak_latest_is_the_default_feed():
    connector = create_connector("mangafreak")
    modes = connector._BROWSE_MODES
    assert modes["latest"] == modes["default"]
    assert modes["popular"] != modes["default"]


def test_threehentai_new_and_latest_request_the_default_listing():
    connector = create_connector("3hentai")
    calls: list[dict] = []

    def fake_fetch(page, *, query=None, sort=None):
        calls.append({"page": page, "query": query, "sort": sort})
        raise RuntimeError("stop")

    with patch.object(connector, "_fetch_listing", side_effect=fake_fetch):
        for sort in (None, "latest", "new", "popular"):
            with pytest.raises(RuntimeError):
                connector.get_series_list(2, sort=sort)
    assert [c["sort"] for c in calls] == [None, None, None, "popular"]
    assert all(c["page"] == 2 for c in calls)
