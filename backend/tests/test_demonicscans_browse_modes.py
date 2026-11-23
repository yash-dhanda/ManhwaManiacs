from __future__ import annotations

from connectors.demonicscans.connector import DemonicScansConnector
from connectors.demonicscans.mappers import listing_path


def test_browse_modes_canonical_order():
    connector = DemonicScansConnector()
    assert [m.id for m in connector.list_browse_modes()] == ["default", "popular", "latest"]


def test_latest_and_default_use_the_updates_feed_and_popular_uses_home():
    connector = DemonicScansConnector()
    seen: list[str] = []

    def fake_get_text(path: str, *, params=None):
        seen.append(path)
        return "<html></html>"

    connector._http.get_text = fake_get_text  # type: ignore[method-assign]
    for sort in (None, "default", "latest", "popular"):
        connector.get_series_list(2, sort=sort)
    assert seen[:3] == [listing_path(2, kind="latest")] * 3
    assert seen[3] == listing_path(2, kind="popular")
