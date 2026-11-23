"""An upstream failure on a cold cache is a 502 ``source_unreachable``, not a 500.

``list_series`` always mapped a connector failure; every other read on a source
let ``ConnectorHttpError`` reach the app's catch-all, so a source answering
403/5xx with nothing cached gave ``500 internal_error`` and a traceback.
"""

from __future__ import annotations

from urllib.parse import quote

import pytest
from fastapi.testclient import TestClient

import services.browse_service as browse_service
from connectors.base import ChapterLockedError
from connectors.http.client import ConnectorHttpError
from core.errors import AppError
from services.browse_service import BrowseService

SRC = "fakesrc"
SERIES = "some-series"
CHAPTER = "some-series/chapter-1"


class _DownConnector:
    """Every upstream call fails the way a blocked / dead source does."""

    is_browsable = True
    is_mature = False
    exc: Exception = ConnectorHttpError("upstream 503", status_code=503)

    def get_series(self, series_id):
        raise self.exc

    def get_chapters(self, series_id):
        raise self.exc

    def get_chapter_pages(self, chapter_id):
        raise self.exc

    def find_page(self, page_id):
        raise self.exc


@pytest.fixture
def down(monkeypatch):
    connector = _DownConnector()
    monkeypatch.setattr(browse_service, "create_connector", lambda source_id: connector)
    return connector


@pytest.fixture
def lenient(app):
    with TestClient(app, raise_server_exceptions=False) as c:
        yield c


def _routes():
    key = quote(SERIES, safe="")
    chap = quote(CHAPTER, safe="")
    return [
        f"/sources/{SRC}/series/{key}",
        f"/sources/{SRC}/series/{key}/chapters",
        f"/sources/{SRC}/series/{key}/chapters/{chap}/reader",
        f"/sources/{SRC}/series/{key}/cover",
        f"/sources/{SRC}/chapters/{chap}/pages",
        f"/sources/{SRC}/pages/{chap}%3A1/image",
        f"/reader/chapter/manifest?source={SRC}&series={key}&chapter={chap}",
    ]


@pytest.mark.parametrize("path", _routes())
def test_upstream_503_on_a_cold_cache_is_502_source_unreachable(lenient, down, path):
    resp = lenient.get(path)
    assert resp.status_code == 502, (path, resp.text)
    assert resp.json()["code"] == "source_unreachable"


@pytest.mark.parametrize("path", _routes())
def test_a_transport_oserror_is_the_same_502(lenient, down, path):
    down.exc = OSError("timed out")
    resp = lenient.get(path)
    assert resp.status_code == 502, (path, resp.text)
    assert resp.json()["code"] == "source_unreachable"


@pytest.mark.parametrize("path", _routes())
def test_a_gated_source_still_answers_source_not_found(lenient, monkeypatch, path):
    gated = _DownConnector()
    gated.is_mature = True
    monkeypatch.setattr(browse_service, "create_connector", lambda source_id: gated)
    resp = lenient.get(path)
    assert resp.status_code == 404, (path, resp.text)
    assert resp.json()["code"] == "source_not_found"


def test_the_failure_is_still_counted_against_source_health(monkeypatch, db_session):
    recorded = []
    monkeypatch.setattr(
        browse_service,
        "record_traffic_outcome",
        lambda bind, source_id, error: recorded.append((source_id, error)),
    )
    connector = _DownConnector()
    service = BrowseService(
        mature_enabled=True, db=db_session, record_traffic_health=True
    )
    monkeypatch.setattr(service, "_get_connector", lambda source_id: connector)
    with pytest.raises(AppError) as raised:
        service.get_series(SRC, SERIES)
    assert raised.value.code == "source_unreachable"
    assert [src for src, error in recorded if error] == [SRC]


def test_chapter_locked_and_not_found_pass_through_untouched(monkeypatch):
    class _Locked(_DownConnector):
        def get_chapter_pages(self, chapter_id):
            raise ChapterLockedError("2026-11-23T14:15:24Z")

        def find_page(self, page_id):
            return None

    service = BrowseService(mature_enabled=True)
    connector = _Locked()
    connector.display_name = "Fake"
    monkeypatch.setattr(service, "_get_connector", lambda source_id: connector)
    monkeypatch.setattr(service, "_require_visible_chapter", lambda *a, **k: None)
    with pytest.raises(AppError) as locked:
        service.get_chapter_pages(SRC, CHAPTER)
    assert locked.value.code == "chapter_locked"
    with pytest.raises(AppError) as missing:
        service.resolve_page_image(SRC, "x:1")
    assert missing.value.code == "page_not_found"


def test_the_update_sweep_still_reads_a_mapped_transport_failure_as_transport():
    import services.update_service as us

    try:
        BrowseService._raise_source_connector_error(SRC, OSError("timed out"))
    except AppError as mapped:
        assert us._health_failure(mapped) == us._HEALTH_TRANSPORT
    http = ConnectorHttpError("boom", status_code=503)
    try:
        BrowseService._raise_source_connector_error(SRC, http)
    except AppError as mapped:
        assert us._health_failure(mapped) == us._HEALTH_BROKE
