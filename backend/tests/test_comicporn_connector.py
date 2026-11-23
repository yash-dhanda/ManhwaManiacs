from __future__ import annotations

from pathlib import Path
from unittest.mock import patch

import pytest

from connectors.comicporn import ComicPornConnector
from connectors.http.client import ConnectorHttpError
from connectors.registry import create_connector, list_installed_connectors


FIXTURES = Path(__file__).parent / "fixtures" / "comicporn"
CHALLENGE_HTML = (
    "<!DOCTYPE html><html><head><title>Just a moment...</title></head><body>"
    '<h1 class="zone-name-title h1">comicporn.xxx</h1>'
    "<p>Checking if the site connection is secure</p></body></html>"
)


def _load(name: str) -> str:
    return (FIXTURES / name).read_text(encoding="utf-8")


@pytest.fixture
def connector() -> ComicPornConnector:
    return ComicPornConnector()


def test_registry_lists_comicporn_as_mature():
    descriptors = {item.source_type: item for item in list_installed_connectors(include_mature=True)}
    assert descriptors["comicporn"].mature is True
    assert descriptors["comicporn"].name == "ComicPorn"
    assert "comicporn" not in {
        item.source_type for item in list_installed_connectors(include_mature=False)
    }


def test_create_comicporn_connector():
    assert isinstance(create_connector("comicporn"), ComicPornConnector)


def test_browse_page_one_asks_for_the_paged_listing(connector: ComicPornConnector):
    # ``/`` groups 30 cards by category with no pager.
    with patch.object(connector, "_fetch_html", return_value=_load("home_listing.html")) as fetch:
        listing = connector.get_series_list(1)

    fetch.assert_called_once_with("/?page=1")
    assert len(listing.items) == 20
    assert listing.items[0].id == "1115842"
    assert listing.items[0].cover_url == "https://m11.comicporn.xxx/033/rp9oz8khe4/cover.jpg"
    assert listing.has_more is True


def test_search_uses_key_parameter(connector: ComicPornConnector):
    with patch.object(connector, "_fetch_html", return_value=_load("search_listing.html")) as fetch:
        listing = connector.search_series("naruto", 2)

    fetch.assert_called_once_with("/search/?key=naruto&page=2")
    assert len(listing.items) == 3
    assert all("naruto" in item.title.lower() for item in listing.items)


def test_series_chapters_and_pages(connector: ComicPornConnector):
    detail = _load("gallery_detail.html")
    reader = _load("reader_page.html")

    def fake_fetch(path: str) -> str:
        if path == "/gallery/1115822/":
            return detail
        if path == "/view/1115822/14/":
            return reader
        raise AssertionError(f"unexpected path {path}")

    with patch.object(connector, "_fetch_html", side_effect=fake_fetch):
        series = connector.get_series("1115822")
        chapters = connector.get_chapters("1115822")
        pages = connector.get_chapter_pages("1115822")

    assert series is not None
    assert series.title == "[Gakispark] 夜のクィディッチ"
    assert series.cover_url == "https://m11.comicporn.xxx/033/utvixh4rl7/cover.jpg"
    assert len(chapters) == 1 and chapters[0].page_count == 14
    assert len(pages) == 14
    assert pages[0].remote_url == "https://m11.comicporn.xxx/033/utvixh4rl7/1.webp"
    assert pages[-1].remote_url == "https://m11.comicporn.xxx/033/utvixh4rl7/14.webp"


def test_image_hosts(connector: ComicPornConnector):
    from connectors.http.redirect_policy import host_matches_allowlist

    for host in ("m6.comicporn.xxx", "m10.comicporn.xxx", "m11.comicporn.xxx"):
        assert host_matches_allowlist(host, connector.allowed_image_hosts)
    assert connector.image_fetch_headers()["Referer"] == "https://comicporn.xxx/"


def test_cloudflare_challenge_yields_nothing(connector: ComicPornConnector):
    with patch.object(connector, "_fetch_html", return_value=CHALLENGE_HTML):
        assert connector.get_series("1") is None
        assert connector.get_chapters("1") == []
        assert connector.get_chapter_pages("1") == []
        assert connector.search_series("naruto", 1).items == []


def test_blocked_gallery_returns_empty(connector: ComicPornConnector):
    blocked = ConnectorHttpError("403 Forbidden", status_code=403)
    with patch.object(connector, "_fetch_html", side_effect=blocked):
        assert connector.get_series("2") is None
        assert connector.get_chapters("2") == []
        assert connector.get_chapter_pages("2") == []
