"""``source_url`` on the source series detail: the series' page on its site, or null."""

from __future__ import annotations

from unittest.mock import patch

from connectors.branding import series_page_url
from connectors.comicsvalley.connector import ComicsValleyConnector
from connectors.local_filesystem.connector import LocalFilesystemConnector
from connectors.mangatown.connector import MangaTownConnector
from connectors.models import Series
from services.browse_service import BrowseService


def _series(path: str | None) -> Series:
    return Series(id="solo-leveling", title="Solo Leveling", canonical_path=path)


def test_relative_path_joins_the_site_base():
    assert series_page_url(MangaTownConnector, _series("/manga/solo_leveling/")) == (
        "https://www.mangatown.com/manga/solo_leveling/"
    )


def test_absolute_path_passes_through():
    url = "https://flamecomics.xyz/series/2"
    assert series_page_url(MangaTownConnector, _series(url)) == url


def test_null_without_a_path_a_site_or_an_http_url():
    assert series_page_url(MangaTownConnector, _series(None)) is None
    assert series_page_url(MangaTownConnector, _series("  ")) is None
    assert series_page_url(LocalFilesystemConnector, _series("Solo Leveling")) is None
    assert series_page_url(MangaTownConnector, _series("javascript:alert(1)")) is None


def test_series_detail_payload_carries_source_url():
    connector = ComicsValleyConnector()
    series = Series(id="some-series", title="Some Series", canonical_path="/manga/some-series/")
    try:
        with patch("services.browse_service.get_settings") as settings:
            settings.return_value.mature_content_enabled = True
            with patch("services.browse_service.create_connector", return_value=connector):
                with patch.object(connector, "get_series", return_value=series):
                    payload = BrowseService().get_series("comicsvalley", "some-series")
                with patch.object(connector, "get_series", return_value=_series(None)):
                    bare = BrowseService().get_series("comicsvalley", "solo-leveling")
    finally:
        connector._http.close()
    assert payload["source_url"].startswith("https://")
    assert payload["source_url"].endswith("/manga/some-series/")
    assert bare["source_url"] is None
