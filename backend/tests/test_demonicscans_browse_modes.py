from __future__ import annotations

from connectors.demonicscans.connector import DemonicScansConnector
from connectors.demonicscans.mappers import listing_path


def test_browse_modes_canonical_order():
    connector = DemonicScansConnector()
    assert [m.id for m in connector.list_browse_modes()] == ["default", "popular", "latest", "new"]


def test_latest_and_default_use_the_updates_feed():
    # default and latest are the updates feed, whose `list` is the 1-based page.
    connector = DemonicScansConnector()
    seen: list[str] = []

    def fake_get_text(path: str, *, params=None):
        seen.append(path)
        return "<html></html>"

    connector._http.get_text = fake_get_text  # type: ignore[method-assign]
    for sort in (None, "default", "latest"):
        connector.get_series_list(2, sort=sort)
    assert seen == [listing_path(2, kind="latest")] * 3
    assert seen[0] == "/lastupdates.php?list=2"
    assert listing_path(1, kind="latest") == "/lastupdates.php?list=1"


# --- popular / new: the site's catalogue ordered server-side -----------------

from pathlib import Path  # noqa: E402

from connectors.demonicscans.mappers import (  # noqa: E402
    advanced_params,
    parse_advanced_list,
)

_FIXTURES = Path(__file__).parent / "fixtures" / "demonicscans"


def _fixture(name: str) -> str:
    return (_FIXTURES / name).read_text(encoding="utf-8")


def test_popular_and_new_ask_the_advanced_catalogue_for_the_right_order():
    connector = DemonicScansConnector()
    seen: list[tuple[str, dict | None]] = []

    def fake_get_text(path: str, *, params=None):
        seen.append((path, params))
        return _fixture("advanced_views_page1.html")

    connector._http.get_text = fake_get_text  # type: ignore[method-assign]
    connector.get_series_list(1, sort="popular")
    connector.get_series_list(3, sort="popular")
    connector.get_series_list(2, sort="new")
    assert seen == [
        ("/advanced.php", {"list": 1, "status": "all", "orderby": "VIEWS DESC"}),
        ("/advanced.php", {"list": 3, "status": "all", "orderby": "VIEWS DESC"}),
        ("/advanced.php", {"list": 2, "status": "all", "orderby": "ID DESC"}),
    ]
    assert advanced_params(0, "new")["list"] == 1


def test_advanced_cards_parse_with_cover_and_pager():
    first = parse_advanced_list(_fixture("advanced_views_page1.html"), page=1)
    assert [s.id for s in first.items][:2] == ["Martial-Peak", "Pick-Me-Up"]
    assert first.items[0].title == "Martial Peak"
    assert first.items[0].cover_url.startswith("https://readermc.org/images/thumbnails/")
    assert first.has_more is True
    second = parse_advanced_list(_fixture("advanced_new_page2.html"), page=2)
    assert second.items[0].id == "My-Slain-Dragon-Bride"
    assert {s.id for s in first.items}.isdisjoint({s.id for s in second.items})
    assert parse_advanced_list("<html></html>", page=1).items == []
