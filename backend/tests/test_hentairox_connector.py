from __future__ import annotations

from pathlib import Path
from unittest.mock import patch

import pytest

from connectors.hentairox import HentaiRoxConnector
from connectors.http.client import ConnectorHttpError
from connectors.registry import create_connector, list_installed_connectors


FIXTURES = Path(__file__).parent / "fixtures" / "hentairox"
# Cloudflare's interstitial still carries an <h1>, so it must not parse as a
# gallery titled after the zone.
CHALLENGE_HTML = (
    "<!DOCTYPE html><html><head><title>Just a moment...</title></head><body>"
    '<h1 class="zone-name-title h1">hentairox.com</h1>'
    "<p>Checking if the site connection is secure</p></body></html>"
)


def _load(name: str) -> str:
    return (FIXTURES / name).read_text(encoding="utf-8")


@pytest.fixture
def connector() -> HentaiRoxConnector:
    return HentaiRoxConnector()


def test_registry_lists_hentairox_as_mature():
    descriptors = {item.source_type: item for item in list_installed_connectors(include_mature=True)}
    assert descriptors["hentairox"].mature is True
    assert descriptors["hentairox"].name == "HentaiRox"
    assert "hentairox" not in {
        item.source_type for item in list_installed_connectors(include_mature=False)
    }


def test_create_hentairox_connector():
    assert isinstance(create_connector("hentairox"), HentaiRoxConnector)


def test_browse_page_one_asks_for_the_paged_listing(connector: HentaiRoxConnector):
    # ``/`` is a sectioned front page with 10 cards and no pager.
    with patch.object(connector, "_fetch_html", return_value=_load("home_listing.html")) as fetch:
        listing = connector.get_series_list(1)

    fetch.assert_called_once_with("/?page=1")
    assert len(listing.items) == 20
    assert listing.items[0].id == "862617"
    assert listing.items[0].cover_url == "https://m11.hentairox.com/033/rp9oz8khe4/cover.jpg"
    assert listing.has_more is True


def test_browse_page_two_path(connector: HentaiRoxConnector):
    with patch.object(connector, "_fetch_html", return_value=_load("home_listing.html")) as fetch:
        connector.get_series_list(2)
    fetch.assert_called_once_with("/?page=2")


def test_search_uses_key_parameter(connector: HentaiRoxConnector):
    with patch.object(connector, "_fetch_html", return_value=_load("search_listing.html")) as fetch:
        listing = connector.search_series("naruto", 1)

    fetch.assert_called_once_with("/search/?key=naruto")
    assert len(listing.items) == 3
    assert all("naruto" in item.title.lower() for item in listing.items)
    assert listing.has_more is False


def test_series_chapters_and_mixed_extension_pages(connector: HentaiRoxConnector):
    detail = _load("gallery_detail.html")
    reader = _load("reader_page.html")

    def fake_fetch(path: str) -> str:
        if path == "/gallery/862607/":
            return detail
        if path == "/view/862607/343/":
            return reader
        raise AssertionError(f"unexpected path {path}")

    with patch.object(connector, "_fetch_html", side_effect=fake_fetch):
        series = connector.get_series("862607")
        chapters = connector.get_chapters("862607")
        pages = connector.get_chapter_pages("862607")

    assert series is not None
    assert series.title == "[Artca9] Violets Wildlife Diary CH 1-7"
    assert series.cover_url == "https://m11.hentairox.com/033/cvxlsi5h0n/cover.jpg"
    assert len(chapters) == 1 and chapters[0].page_count == 343
    assert len(pages) == 343
    # g_th types each page; page 3 is a jpg inside a webp gallery.
    assert pages[0].remote_url == "https://m11.hentairox.com/033/cvxlsi5h0n/1.webp"
    assert pages[2].remote_url == "https://m11.hentairox.com/033/cvxlsi5h0n/3.jpg"
    assert pages[-1].remote_url == "https://m11.hentairox.com/033/cvxlsi5h0n/343.webp"
    assert connector.find_page(pages[2].id) == pages[2]


def test_old_jpg_gallery_pages(connector: HentaiRoxConnector):
    def fake_fetch(path: str) -> str:
        if path == "/gallery/378340/":
            return _load("gallery_detail_jpg.html")
        raise ConnectorHttpError("reader unavailable", status_code=503)

    with patch.object(connector, "_fetch_html", side_effect=fake_fetch):
        pages = connector.get_chapter_pages("378340")

    assert [page.remote_url for page in pages] == [
        f"https://m5.hentairox.com/017/zlsmftykng/{n}.jpg" for n in range(1, 5)
    ]


def test_image_hosts_cover_every_media_shard(connector: HentaiRoxConnector):
    from connectors.http.redirect_policy import host_matches_allowlist

    for host in ("m5.hentairox.com", "m10.hentairox.com", "m11.hentairox.com"):
        assert host_matches_allowlist(host, connector.allowed_image_hosts)
    assert not host_matches_allowlist("evilhentairox.com", connector.allowed_image_hosts)
    assert connector.image_fetch_headers()["Referer"] == "https://hentairox.com/"


def test_cloudflare_challenge_yields_nothing(connector: HentaiRoxConnector):
    with patch.object(connector, "_fetch_html", return_value=CHALLENGE_HTML):
        assert connector.get_series("1") is None
        assert connector.get_chapters("1") == []
        assert connector.get_chapter_pages("1") == []
        listing = connector.get_series_list(1)
    assert listing.items == []
    assert listing.has_more is False


def test_blocked_gallery_returns_empty(connector: HentaiRoxConnector):
    blocked = ConnectorHttpError("403 Forbidden", status_code=403)
    with patch.object(connector, "_fetch_html", side_effect=blocked):
        assert connector.get_series("2") is None
        assert connector.get_chapters("2") == []
        assert connector.get_chapter_pages("2") == []
