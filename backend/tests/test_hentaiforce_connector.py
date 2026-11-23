from __future__ import annotations

from pathlib import Path
from unittest.mock import patch

import pytest

from connectors.hentaiforce.connector import HentaiForceConnector
from connectors.http.client import ConnectorHttpError


FIXTURES = Path(__file__).parent / "fixtures" / "hentaiforce"
GALLERY = "732946"


def _fixture(name: str) -> str:
    return (FIXTURES / name).read_text(encoding="utf-8")


@pytest.fixture
def connector() -> HentaiForceConnector:
    return HentaiForceConnector()


def test_descriptor_is_mature(connector: HentaiForceConnector):
    assert connector.source_type == "hentaiforce"
    assert connector.is_mature is True
    assert connector.allowed_image_hosts == frozenset({"hentaiforce.me"})


def test_browse_listing(connector: HentaiForceConnector):
    with patch.object(connector, "_fetch_html", return_value=_fixture("home_listing.html")) as fetch:
        listing = connector.get_series_list(1)
        connector.get_series_list(2)

    assert [call.args[0] for call in fetch.call_args_list] == ["/", "/page/2"]
    assert len(listing.items) == 10
    first = listing.items[0]
    assert first.id == GALLERY
    assert first.title.startswith("[CandleLight (Suigi)] Kyokkou no Sora")
    assert first.cover_url == "https://m1.hentaiforce.me/img/2481388-thumb.jpg"
    assert listing.has_more is True


def test_search_uses_q(connector: HentaiForceConnector):
    with patch.object(connector, "_fetch_html", return_value=_fixture("search.html")) as fetch:
        listing = connector.search_series("aurora", 2)

    fetch.assert_called_once_with("/search?q=aurora&page=2")
    assert len(listing.items) == 10
    assert listing.has_more is True


def test_gallery_is_one_chapter(connector: HentaiForceConnector):
    with patch.object(connector, "_fetch_html", return_value=_fixture("gallery_detail.html")) as fetch:
        series = connector.get_series(GALLERY)
        chapters = connector.get_chapters(GALLERY)

    fetch.assert_called_once_with(f"/view/{GALLERY}")
    assert series is not None
    assert "Kyokkou no Sora" in series.title
    assert series.cover_url == "https://m1.hentaiforce.me/img/2481388-cover.jpg"
    assert series.artist == "suigi"
    assert "dog girl" in series.genres
    assert "english" in series.genres
    assert len(chapters) == 1
    assert chapters[0].id == GALLERY
    assert chapters[0].page_count == 53


def test_pages_from_reader(connector: HentaiForceConnector):
    with patch.object(connector, "_fetch_html", return_value=_fixture("reader_page.html")) as fetch:
        pages = connector.get_chapter_pages(GALLERY)
        found = connector.find_page(f"{GALLERY}:27")

    fetch.assert_called_once_with(f"/view/{GALLERY}/1")
    assert len(pages) == 53
    assert [page.number for page in pages] == list(range(1, 54))
    assert pages[0].remote_url == "https://m1.hentaiforce.me/img/2481388-1.jpg"
    assert pages[0].width and pages[0].height
    assert found == pages[26]


def test_failures_return_empty(connector: HentaiForceConnector):
    with patch.object(connector._http, "get_text", return_value=_fixture("cloudflare_challenge.html")):
        assert connector.get_series_list(1).items == []
        assert connector.search_series("x", 1).items == []
        assert connector.get_series(GALLERY) is None
        assert connector.get_chapters(GALLERY) == []
        assert connector.get_chapter_pages(GALLERY) == []
    with patch.object(connector._http, "get_text", side_effect=ConnectorHttpError("404", status_code=404)):
        assert connector.get_series("1") is None
        assert connector.find_page("1:1") is None
    # A soft 404 page and a reader without readerPages both parse to nothing.
    with patch.object(connector, "_fetch_html", return_value=_fixture("missing_gallery.html")):
        assert connector.get_series("2") is None
        assert connector.get_chapter_pages("2") == []
    assert connector.get_series("not-a-number") is None
    assert connector.find_page("garbage") is None
