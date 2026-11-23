from __future__ import annotations

import io
from pathlib import Path
from unittest.mock import patch

import pytest
from PIL import Image

from connectors.http.client import ConnectorHttpError
from connectors.rouman5.connector import Rouman5Connector, strip_count, unscramble


FIXTURES = Path(__file__).parent / "fixtures" / "rouman5"
BOOK = "cmjgqyjf00050s65albxbxg04"
#: A real ``sr:1`` page URL from the chapter fixture (11 strips).
SCRAMBLED_URL = (
    "https://v1.towm85.xyz/m/lfcAWL1tCpViLHk7k9SdZbJfdSCsv4AeHbeLQwkf3zc/wm:0/sr:1/"
    "czM6Ly9yb3VtYW4vaW1hZ2VzL2NtamdxeWpmMDAwNTBzNjVhbGJ4YnhnMDQvMThjLzEyMzk0MTcvMDAwMDEud2VicA.webp"
)


def _fixture(name: str) -> str:
    return (FIXTURES / name).read_text(encoding="utf-8")


@pytest.fixture
def connector() -> Rouman5Connector:
    return Rouman5Connector()


def test_descriptor_is_mature(connector: Rouman5Connector):
    assert connector.source_type == "rouman5"
    assert connector.is_mature is True
    # Nothing parsed yet: the learned allowlist fails closed.
    assert connector.allowed_image_hosts == frozenset()


def test_browse_maps_zero_based_pages(connector: Rouman5Connector):
    with patch.object(connector, "_fetch_html", return_value=_fixture("books_page1.html")) as fetch:
        listing = connector.get_series_list(1)
        connector.get_series_list(3)

    assert [call.args[0] for call in fetch.call_args_list] == ["/books", "/books?page=2"]
    assert len(listing.items) == 12
    first = listing.items[0]
    assert first.id == "cmjhdzow3000ws6aer48cpzrk"
    assert first.title == "素拉與海娜！"
    assert first.cover_url.startswith("https://towm85.xyz/m/")
    assert first.latest_chapter
    assert listing.has_more is True
    assert "towm85.xyz" in connector.allowed_image_hosts


def test_search_uses_term(connector: Rouman5Connector):
    with patch.object(connector, "_fetch_html", return_value=_fixture("search.html")) as fetch:
        listing = connector.search_series("教授", 1)

    fetch.assert_called_once_with("/search?term=%E6%95%99%E6%8E%88")
    assert listing.items
    assert all(item.id for item in listing.items)
    assert "教授" in listing.items[0].title


def test_series_and_chapters_share_one_fetch(connector: Rouman5Connector):
    with patch.object(connector, "_fetch_html", return_value=_fixture("series_detail.html")) as fetch:
        series = connector.get_series(BOOK)
        chapters = connector.get_chapters(BOOK)

    fetch.assert_called_once_with(f"/books/{BOOK}")
    assert series is not None
    assert series.title == "教授探索日志"
    assert series.author == "MIMI"
    assert series.status == "ongoing"
    assert "無修正" in series.genres
    assert series.cover_url.startswith("https://towm85.xyz/m/")
    assert series.chapter_count == 19
    assert len(chapters) == 19
    assert chapters[0].id == f"{BOOK}/0"
    assert chapters[0].number == 1.0
    assert chapters[-1].id == f"{BOOK}/18"
    assert chapters[-1].number == 19.0


def test_chapter_pages_and_find_page(connector: Rouman5Connector):
    with patch.object(connector, "_fetch_html", return_value=_fixture("chapter_reader.html")) as fetch:
        pages = connector.get_chapter_pages(f"{BOOK}/9")
        found = connector.find_page(pages[2].id)

    fetch.assert_called_once_with(f"/books/{BOOK}/9")
    assert len(pages) == 8
    assert pages[0].id == f"{BOOK}/9/1"
    assert pages[0].remote_url == SCRAMBLED_URL
    assert found == pages[2]
    hosts = connector.allowed_image_hosts
    assert {"v1.towm85.xyz", "v2.towm85.xyz"} <= hosts
    assert "rouman5.com" not in hosts


def test_failures_return_empty(connector: Rouman5Connector):
    challenge = _fixture("cloudflare_challenge.html")
    with patch.object(connector._http, "get_text", return_value=challenge):
        assert connector.get_series_list(1).items == []
        assert connector.search_series("教授", 1).items == []
        assert connector.get_series(BOOK) is None
        assert connector.get_chapters(BOOK) == []
        assert connector.get_chapter_pages(f"{BOOK}/0") == []
    with patch.object(connector._http, "get_text", side_effect=ConnectorHttpError("boom", status_code=404)):
        assert connector.get_series("missing") is None
        assert connector.find_page("missing/0/1") is None
    # A chapter page whose stream has no imagePaths is an empty list, not an error.
    with patch.object(connector, "_fetch_html", return_value=_fixture("series_detail.html")):
        assert connector.get_chapter_pages(f"{BOOK}/1") == []
    assert connector.get_chapter_pages(BOOK) == []


def test_strip_count_matches_site_formula():
    assert strip_count(SCRAMBLED_URL) == 11


def test_unscramble_reverses_strips():
    # Rows labelled by brightness; 110 rows / 11 strips = 10 rows each, no remainder.
    height = 110
    scrambled = Image.new("L", (8, height))
    for y in range(height):
        scrambled.paste(y * 2, (0, y, 8, y + 1))
    buffer = io.BytesIO()
    scrambled.save(buffer, "PNG")

    restored = Image.open(io.BytesIO(unscramble(buffer.getvalue(), SCRAMBLED_URL))).convert("L")

    # Output strip i comes from source strip (10 - i): row 5 <- 105, row 15 <- 95.
    assert abs(restored.getpixel((4, 5)) - 210) <= 6
    assert abs(restored.getpixel((4, 15)) - 190) <= 6
    assert abs(restored.getpixel((4, 105)) - 10) <= 6


def test_fetch_proxied_image_only_handles_scrambled(connector: Rouman5Connector):
    plain = SCRAMBLED_URL.replace("/sr:1/", "/sr:0/")
    assert connector.fetch_proxied_image(plain) is None

    image = Image.new("RGB", (8, 22), "white")
    buffer = io.BytesIO()
    image.save(buffer, "WEBP")
    with patch.object(connector._http, "get_bytes", return_value=("image/webp", buffer.getvalue())):
        media_type, data = connector.fetch_proxied_image(SCRAMBLED_URL)
    assert media_type == "image/jpeg"
    assert Image.open(io.BytesIO(data)).size == (8, 22)

    with patch.object(connector._http, "get_bytes", return_value=("text/html", b"<html>")):
        with pytest.raises(ConnectorHttpError):
            connector.fetch_proxied_image(SCRAMBLED_URL)
