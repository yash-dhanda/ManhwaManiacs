"""httpx timeouts are per socket read: a host trickling one byte every few
seconds never trips them. Every request path needs a wall-clock bound too, or
one such fetch holds the update sweep's lock until the process restarts."""

from __future__ import annotations

import time
from unittest.mock import MagicMock, patch

import httpx
import pytest

from connectors.http.client import ConnectorHttpError, SyncConnectorHttpClient
from core.errors import AppError
from services.browse_service import BrowseService
from tests.test_browse_service_ssrf import _FakeConnector


class _Trickle(httpx.SyncByteStream):
    """Endless body, one small chunk every ``gap`` seconds."""

    def __init__(self, gap: float, limit: int = 10_000):
        self.gap, self.sent, self.limit = gap, 0, limit

    def __iter__(self):
        while self.sent < self.limit:
            time.sleep(self.gap)
            self.sent += 1
            yield b"x"


def _client(handler, *, total_timeout, max_retries=1):
    client = SyncConnectorHttpClient(
        "https://example.com",
        min_interval=0,
        max_retries=max_retries,
        total_timeout=total_timeout,
    )
    # Keep the production event hooks; swap only what answers.
    hooks = client._client.event_hooks
    client._client = httpx.Client(
        base_url="https://example.com",
        transport=httpx.MockTransport(handler),
        event_hooks=hooks,
        follow_redirects=True,
    )
    return client


@pytest.mark.parametrize("method", ["get_text", "get_json", "post_text", "get_bytes"])
def test_a_trickling_body_is_cut_off_at_the_deadline(method):
    trickle = _Trickle(gap=0.02)

    def handler(request):  # noqa: ANN001
        return httpx.Response(200, headers={"content-type": "text/html"}, stream=trickle)

    client = _client(handler, total_timeout=0.2)
    started = time.monotonic()
    with pytest.raises(ConnectorHttpError):
        getattr(client, method)("/x")
    assert time.monotonic() - started < 2.0
    assert trickle.sent < 100  # stopped reading, did not drain 10_000 chunks


def test_a_capped_bytes_fetch_is_cut_off_too():
    trickle = _Trickle(gap=0.02)

    def handler(request):  # noqa: ANN001
        return httpx.Response(200, headers={"content-type": "image/jpeg"}, stream=trickle)

    client = _client(handler, total_timeout=0.2)
    with pytest.raises(ConnectorHttpError):
        client.get_bytes("/x", max_bytes=10_000_000)
    assert trickle.sent < 100


def test_a_slow_attempt_is_retried_like_any_timeout():
    calls = []

    def handler(request):  # noqa: ANN001
        calls.append(1)
        if len(calls) == 1:
            return httpx.Response(200, stream=_Trickle(gap=0.02))
        return httpx.Response(200, text="<html>ok</html>")

    client = _client(handler, total_timeout=0.2, max_retries=2)
    assert client.get_text("/x") == "<html>ok</html>"
    assert len(calls) == 2


def test_a_body_that_finishes_in_time_is_untouched():
    def handler(request):  # noqa: ANN001
        return httpx.Response(200, json={"ok": True})

    client = _client(handler, total_timeout=5.0)
    assert client.get_json("/x") == {"ok": True}


def test_the_default_deadline_scales_with_the_per_read_timeout():
    short = SyncConnectorHttpClient("https://example.com", timeout=30.0)
    long = SyncConnectorHttpClient("https://example.com", timeout=60.0)
    assert short._total_timeout >= 60.0
    assert long._total_timeout > short._total_timeout


def test_the_image_proxy_stops_a_trickling_upstream(monkeypatch):
    import services.browse_service as browse_service

    monkeypatch.setattr(browse_service, "_IMAGE_FETCH_DEADLINE_SECONDS", 0.2)
    sent = []

    def chunks():
        while len(sent) < 10_000:
            time.sleep(0.02)
            sent.append(1)
            yield b"x"

    response = MagicMock()
    response.is_redirect = False
    response.headers = {}
    response.raise_for_status = MagicMock()
    response.iter_bytes = chunks
    cm = MagicMock()
    cm.__enter__ = MagicMock(return_value=response)
    cm.__exit__ = MagicMock(return_value=False)

    connector = _FakeConnector(frozenset({"example.com"}))
    with patch("services.outbound_security.is_public_address", return_value=True):
        with patch("services.browse_service._image_stream", return_value=cm):
            with pytest.raises(AppError) as raised:
                BrowseService()._fetch_url("https://example.com/x", connector)
    assert raised.value.code == "remote_fetch_failed"
    assert raised.value.status_code == 502
    assert len(sent) < 100
