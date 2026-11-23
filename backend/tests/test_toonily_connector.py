"""Toonily is stock Madara (/serie/ segment). It registers only through the
alternate egress (``connectors.excluded.ALT_EGRESS_ONLY_CONNECTORS``), so these
tests build the class directly."""

from __future__ import annotations

from pathlib import Path

import pytest

from connectors.catalog import MADARA_CATALOG
from connectors.excluded import ALT_EGRESS_ONLY_CONNECTORS, EXCLUDED_CONNECTORS
from connectors.madara.factory import build_madara_connector_class, madara_connector_classes
from connectors.registry import list_installed_connectors

FIXTURES = Path(__file__).parent / "fixtures" / "toonily"


@pytest.fixture
def toonily():
    config = next(c for c in MADARA_CATALOG if c.source_id == "toonily")
    return build_madara_connector_class(config)()


def test_toonily_is_not_registered_without_the_alternate_egress():
    assert "toonily" in ALT_EGRESS_ONLY_CONNECTORS
    assert "toonily" not in EXCLUDED_CONNECTORS
    assert all(c.SOURCE_TYPE != "toonily" for c in madara_connector_classes(MADARA_CATALOG))
    assert "toonily" not in {d.source_type for d in list_installed_connectors(include_mature=True)}


def test_toonily_metadata(toonily):
    assert toonily.is_mature is True
    assert toonily.CONFIG.url_segment == "serie"
    assert "data.tnlycdn.com" in toonily.allowed_image_hosts or "tnlycdn.com" in toonily.allowed_image_hosts
    assert toonily.image_fetch_headers()["Referer"] == "https://toonily.com/"
    assert [m.id for m in toonily.list_browse_modes()] == ["latest", "popular", "new", "rating"]


def test_toonily_chapter_rows_numbers_dates_and_extras(toonily):
    """Real rows (2026-11-23): dates print a two-digit year ("May 31, 23");
    side stories carry no number (None, not a guess)."""
    html = (FIXTURES / "chapter_rows.html").read_text(encoding="utf-8")
    chapters = toonily._html.parse_chapters(html, "solo-leveling-574def58")
    by_slug = {c.id.rsplit("/", 1)[1]: c for c in chapters}
    assert by_slug["chapter-0"].number == 0.0
    assert by_slug["chapter-0"].release_date == "2021-09-24"
    assert by_slug["side-story-21"].number is None
    assert by_slug["side-story-21"].release_date == "2023-05-31"
    # numbered chapters oldest first, unnumbered extras after them
    assert [c.number for c in chapters][:2] == [0.0, 1.0]


def test_toonily_chapter_pages_drop_the_site_credit_image(toonily):
    html = (FIXTURES / "chapter_with_credit_image.html").read_text(encoding="utf-8")
    pages = toonily._html.parse_chapter_pages(html, "solo-leveling-574def58/chapter-0")
    assert pages
    assert all("/wp-content/assets/" not in p.remote_url for p in pages)
    assert all(p.remote_url.startswith("https://data.tnlycdn.com/") for p in pages)
    assert [p.number for p in pages] == list(range(1, len(pages) + 1))
