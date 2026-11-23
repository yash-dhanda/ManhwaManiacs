"""Alternate egress: selected sources go out through one forward proxy.

``MM_ALT_EGRESS_PROXY`` + ``MM_ALT_EGRESS_SOURCES`` (connectors/http/egress.py).
Everything here is offline. The registration cases run a fresh interpreter,
because the registry decides what to register at import time, from settings
that are read once per process -- exactly the production lifecycle.
"""

from __future__ import annotations

import json
import logging
import socket
import subprocess
import sys
import threading
from pathlib import Path
from urllib.parse import quote
from unittest.mock import MagicMock

import httpx
import pytest
from curl_cffi.requests import Session as CurlSession
from curl_cffi.requests import exceptions as curl_exc
from fastapi.testclient import TestClient

import connectors.http.cf_client as cf_client
import connectors.http.client as http_client
import connectors.http.ddg_client as ddg_client
import connectors.registry as registry
import services.browse_service as browse_service
from connectors.base import SourceConnector
from connectors.catalog import MADARA_CATALOG
from connectors.http import egress
from connectors.http.cf_client import CfSyncHttpClient
from connectors.http.client import ConnectorHttpError, SyncConnectorHttpClient
from connectors.http.ddg_client import DdgSyncHttpClient
from connectors.madara.factory import build_madara_connector_class
from core.config import get_settings
from core.errors import AppError
from services.browse_service import BrowseService

BACKEND = Path(__file__).resolve().parents[1]
PASSWORD = "s3cr3t-Pa55"
PROXY = f"http://mm:{PASSWORD}@203.0.113.7:3128"
ROUTED = "routedsrc"
OTHER = "othersrc"


def _configure(monkeypatch, proxy: str | None = PROXY, sources: str | None = ROUTED) -> None:
    for key, value in (("MM_ALT_EGRESS_PROXY", proxy), ("MM_ALT_EGRESS_SOURCES", sources)):
        if value is None:
            monkeypatch.delenv(key, raising=False)
        else:
            monkeypatch.setenv(key, value)
    get_settings.cache_clear()


@pytest.fixture(autouse=True)
def _fresh_settings():
    get_settings.cache_clear()
    yield
    get_settings.cache_clear()


# --- settings -----------------------------------------------------------------


def test_unset_means_off(monkeypatch):
    _configure(monkeypatch, None, None)
    settings = get_settings()
    assert egress.proxy_url() is None
    assert egress.endpoint() is None
    assert egress.routed_source_ids() == frozenset()
    assert egress.proxy_for_source(ROUTED) is None
    assert settings.alt_egress_sources == ()


def test_blank_means_off(monkeypatch):
    _configure(monkeypatch, "   ", " , ")
    assert egress.proxy_url() is None
    assert get_settings().alt_egress_sources == ()


def test_a_valid_url_is_parsed_and_only_the_host_and_port_are_exposed(monkeypatch):
    _configure(monkeypatch, f"  {PROXY}  ", "Routedsrc, othersrc ,routedsrc,,")
    assert egress.proxy_url() == PROXY
    assert egress.endpoint() == "203.0.113.7:3128"
    # Lowercased, trimmed, deduplicated, in order.
    assert get_settings().alt_egress_sources == ("routedsrc", "othersrc")
    assert egress.proxy_for_source(ROUTED) == PROXY
    assert egress.proxy_for_source("somethingelse") is None
    assert egress.proxy_for_source(None) is None


@pytest.mark.parametrize("scheme", ["http", "https"])
def test_http_and_https_proxies_are_accepted(monkeypatch, scheme):
    _configure(monkeypatch, f"{scheme}://proxy.example.net:8443")
    assert egress.endpoint() == "proxy.example.net:8443"


def test_with_no_proxy_the_source_list_has_no_effect(monkeypatch):
    _configure(monkeypatch, None, ROUTED)
    assert egress.routed_source_ids() == frozenset()
    assert egress.proxy_for_source(ROUTED) is None


@pytest.mark.parametrize(
    "bad",
    [
        f"ftp://mm:{PASSWORD}@203.0.113.7:3128",
        f"mm:{PASSWORD}@203.0.113.7:3128",  # no scheme
        f"http://mm:{PASSWORD}@203.0.113.7",  # no port
        f"http://mm:{PASSWORD}@:3128",  # no host
        f"http://mm:{PASSWORD}@203.0.113.7:notaport",
        f"http://mm:{PASSWORD}@203.0.113.7:99999",
        f"http://mm:{PASSWORD}@203.0.113.7:0",
        f"http://mm:{PASSWORD}@203.0.113.7:3128/some/path",
        f"http://mm:{PASSWORD}@203.0.113.7:3128?x=1",
        f"http://mm:{PASSWORD}@[::1:3128",  # broken IPv6 literal
        f"http://mm:{PASSWORD}@203.0.113.7:3128 extra",
    ],
)
def test_a_malformed_value_fails_at_load_without_echoing_it(monkeypatch, bad):
    _configure(monkeypatch, bad)
    with pytest.raises(egress.EgressConfigError) as raised:
        get_settings()
    assert PASSWORD not in str(raised.value)
    assert PASSWORD not in repr(raised.value)
    assert PASSWORD not in repr(raised.value.__cause__)
    assert raised.value.__suppress_context__ or raised.value.__context__ is None


@pytest.mark.parametrize("scheme", ["socks5", "socks5h", "socks4", "socks4a"])
def test_socks_is_rejected_with_a_clear_message(monkeypatch, scheme):
    _configure(monkeypatch, f"{scheme}://mm:{PASSWORD}@203.0.113.7:1080")
    with pytest.raises(egress.EgressConfigError) as raised:
        get_settings()
    assert "SOCKS" in str(raised.value) and "http://" in str(raised.value)
    assert PASSWORD not in str(raised.value)


def test_socks_rejection_rests_on_a_real_limit_of_the_installed_httpx():
    """If this starts failing, httpx[socks] was added and SOCKS can be allowed."""
    with pytest.raises(ImportError, match="socksio"):
        httpx.Client(proxy="socks5://127.0.0.1:1080")


def test_the_credential_never_appears_in_the_settings_object(monkeypatch):
    _configure(monkeypatch)
    settings = get_settings()
    for rendered in (
        repr(settings),
        str(settings),
        repr(settings.alt_egress_proxy),
        json.dumps(settings.model_dump(mode="json")),
        json.dumps(settings.model_dump_json()),
    ):
        assert PASSWORD not in rendered
    assert PASSWORD not in repr(settings.model_dump())


def test_settings_json_cannot_supply_the_proxy(monkeypatch, tmp_path):
    import core.config as config

    path = tmp_path / "settings.json"
    path.write_text(json.dumps({"alt_egress_proxy": PROXY, "alt_egress_sources": ["x"]}))
    monkeypatch.setattr(config, "SETTINGS_PATH", path)
    _configure(monkeypatch, None, None)
    assert egress.proxy_url() is None
    assert get_settings().alt_egress_sources == ()


def test_the_startup_line_names_host_and_port_only(monkeypatch, caplog):
    _configure(monkeypatch, PROXY, "routedsrc,toonily,nosuchsource")
    with caplog.at_level(logging.DEBUG):
        egress.log_startup_status({"routedsrc", "toonily"}, logging.getLogger("startup"))
        egress.log_startup_status({"routedsrc", "toonily"}, logging.getLogger("startup"))
    text = caplog.text
    assert "203.0.113.7:3128" in text
    assert PASSWORD not in text and "mm:" not in text
    on_lines = [r for r in caplog.records if "Alternate egress on" in r.getMessage()]
    assert "routedsrc, toonily" in on_lines[0].getMessage()
    warnings = [r for r in caplog.records if r.levelno == logging.WARNING]
    # One warning per call -- the app calls it once, at startup.
    assert len(warnings) == 2 and all("nosuchsource" in w.getMessage() for w in warnings)


# --- registration (fresh interpreter: the registry decides at import) ---------

_PROBE = r"""
import json, logging, sys
logging.basicConfig(stream=sys.stdout, level=logging.INFO, format="LOG %(levelname)s %(message)s")
from connectors import registry
from core.connector_directory import is_mature_source, known_source_ids
from connectors.excluded import EXCLUDED_CONNECTORS
registry.log_registered_connectors(logging.getLogger("startup"))
descriptors = {d.source_type: d for d in registry.list_installed_connectors()}
print("RESULT " + json.dumps({
    "registered": sorted(set(descriptors) & {"toonily", "weebcentral", "comick"}),
    "toonily_mature": is_mature_source("toonily"),
    "toonily_descriptor_mature": descriptors["toonily"].mature if "toonily" in descriptors else None,
    "known": sorted(known_source_ids() & {"toonily", "weebcentral"}),
    "excluded": sorted(EXCLUDED_CONNECTORS & {"toonily", "weebcentral"}),
}))
"""


def _boot(monkeypatch_env: dict[str, str]) -> tuple[dict, str]:
    import os

    env = {k: v for k, v in os.environ.items() if not k.startswith("MM_ALT_EGRESS")}
    env.update(monkeypatch_env)
    done = subprocess.run(
        [sys.executable, "-c", _PROBE],
        cwd=BACKEND,
        env=env,
        capture_output=True,
        text=True,
        timeout=120,
    )
    assert done.returncode == 0, done.stderr[-2000:]
    line = next(l for l in done.stdout.splitlines() if l.startswith("RESULT "))
    return json.loads(line[len("RESULT "):]), done.stdout


def test_toonily_and_weebcentral_are_absent_by_default():
    result, out = _boot({})
    assert result["registered"] == []
    assert result["known"] == []
    # Neither is in the plain excluded set any more; the alt-egress set holds them.
    assert result["excluded"] == []
    assert "Alternate egress" not in out


def test_they_register_when_the_proxy_and_the_list_include_them():
    result, out = _boot(
        {"MM_ALT_EGRESS_PROXY": PROXY, "MM_ALT_EGRESS_SOURCES": "toonily,weebcentral"}
    )
    assert result["registered"] == ["toonily", "weebcentral"]
    assert result["known"] == ["toonily", "weebcentral"]
    assert result["toonily_descriptor_mature"] is True
    assert result["toonily_mature"] is True
    assert "Alternate egress on via 203.0.113.7:3128 for sources: toonily, weebcentral" in out
    assert PASSWORD not in out


def test_only_the_listed_one_registers():
    result, _ = _boot({"MM_ALT_EGRESS_PROXY": PROXY, "MM_ALT_EGRESS_SOURCES": "toonily"})
    assert result["registered"] == ["toonily"]


def test_the_list_alone_registers_nothing():
    result, out = _boot({"MM_ALT_EGRESS_SOURCES": "toonily,weebcentral"})
    assert result["registered"] == []
    assert "alternate egress is off" in out


def test_the_proxy_alone_registers_nothing():
    result, out = _boot({"MM_ALT_EGRESS_PROXY": PROXY})
    assert result["registered"] == []
    assert PASSWORD not in out


def test_toonily_is_18_plus_whether_or_not_it_is_registered():
    off, _ = _boot({})
    on, _ = _boot({"MM_ALT_EGRESS_PROXY": PROXY, "MM_ALT_EGRESS_SOURCES": "toonily"})
    assert off["registered"] == [] and off["toonily_mature"] is True
    assert on["registered"] == ["toonily"] and on["toonily_mature"] is True


def test_unknown_ids_warn_once_and_comick_stays_excluded():
    result, out = _boot(
        {
            "MM_ALT_EGRESS_PROXY": PROXY,
            "MM_ALT_EGRESS_SOURCES": "toonily,nosuchsource,comick,nosuchsource",
        }
    )
    assert result["registered"] == ["toonily"]  # comick is excluded outright
    warnings = [l for l in out.splitlines() if l.startswith("LOG WARNING")]
    assert len(warnings) == 1
    assert "comick" in warnings[0] and "nosuchsource" in warnings[0]
    assert warnings[0].count("nosuchsource") == 1


def test_a_malformed_proxy_stops_the_boot_without_the_credential():
    import os

    env = {k: v for k, v in os.environ.items() if not k.startswith("MM_ALT_EGRESS")}
    env["MM_ALT_EGRESS_PROXY"] = f"socks5://mm:{PASSWORD}@203.0.113.7:1080"
    done = subprocess.run(
        [sys.executable, "-c", "import connectors.registry"],
        cwd=BACKEND,
        env=env,
        capture_output=True,
        text=True,
        timeout=120,
    )
    assert done.returncode != 0
    assert "SOCKS proxies are not supported" in done.stderr
    assert PASSWORD not in done.stderr and PASSWORD not in done.stdout


def test_cache_rows_of_a_deregistered_source_are_swept_and_a_registered_one_is_kept():
    """The sweep keys on ``known_source_ids()`` -- which follows registration."""
    off, _ = _boot({})
    on, _ = _boot({"MM_ALT_EGRESS_PROXY": PROXY, "MM_ALT_EGRESS_SOURCES": "toonily"})
    assert "toonily" not in off["known"]  # swept on the next boot after turning it off
    assert "toonily" in on["known"]  # left alone while it is on


# --- routing ------------------------------------------------------------------


class _RecordingHttpx(httpx.Client):
    calls: list[dict] = []

    def __init__(self, *args, **kwargs):
        type(self).calls.append(kwargs)
        super().__init__(*args, **kwargs)


class _RecordingCurl(CurlSession):
    calls: list[dict] = []

    def __init__(self, *args, **kwargs):
        type(self).calls.append(kwargs)
        super().__init__(*args, **kwargs)


@pytest.fixture
def recorded(monkeypatch):
    _RecordingHttpx.calls = []
    _RecordingCurl.calls = []
    monkeypatch.setattr(http_client.httpx, "Client", _RecordingHttpx)
    monkeypatch.setattr(cf_client, "Session", _RecordingCurl)
    monkeypatch.setattr(ddg_client, "Session", _RecordingCurl)
    return _RecordingHttpx, _RecordingCurl


def _build(cls, source_id, base="https://example.test"):
    with egress.constructing_source(source_id):
        return cls(base)


@pytest.mark.parametrize(
    "cls,which",
    [
        (SyncConnectorHttpClient, "httpx"),
        (CfSyncHttpClient, "curl"),
        (DdgSyncHttpClient, "curl"),
    ],
)
def test_a_routed_sources_client_gets_the_proxy_and_another_does_not(
    monkeypatch, recorded, cls, which
):
    _configure(monkeypatch)
    httpx_rec, curl_rec = recorded
    rec = httpx_rec if which == "httpx" else curl_rec

    _build(cls, ROUTED)
    assert rec.calls[-1]["proxy"] == PROXY

    _build(cls, OTHER)
    assert "proxy" not in rec.calls[-1] and "proxies" not in rec.calls[-1]

    # Built by a test (or anything else) outside the registry: direct.
    cls("https://example.test")
    assert "proxy" not in rec.calls[-1]


def test_nothing_is_routed_when_the_feature_is_off(monkeypatch, recorded):
    _configure(monkeypatch, None, ROUTED)
    httpx_rec, curl_rec = recorded
    _build(SyncConnectorHttpClient, ROUTED)
    _build(CfSyncHttpClient, ROUTED)
    assert "proxy" not in httpx_rec.calls[-1] and "proxy" not in curl_rec.calls[-1]


def test_the_routed_httpx_client_really_has_a_proxy_transport(monkeypatch):
    _configure(monkeypatch)
    routed = _build(SyncConnectorHttpClient, ROUTED)
    direct = _build(SyncConnectorHttpClient, OTHER)
    pools = [type(t._pool).__name__ for t in routed._client._mounts.values() if t]
    assert pools == ["HTTPProxy"]
    # (The host's own HTTPS_PROXY may give a direct client a mount of its own;
    # what matters is that it is never THIS proxy.)
    assert not any(
        getattr(getattr(t, "_pool", None), "_proxy_url", None) is not None
        and t._pool._proxy_url.host == b"203.0.113.7"
        for t in direct._client._mounts.values()
        if t
    )
    routed.close()
    direct.close()


class _Stub(SourceConnector):
    """A connector with one client of each stack, built like the real ones."""

    SOURCE_TYPE = "stub"

    def __init__(self) -> None:
        self._http = SyncConnectorHttpClient("https://example.test")
        self._cf = CfSyncHttpClient("https://example.test")
        self._ddg = DdgSyncHttpClient("https://example.test")

    source_type = property(lambda self: self.SOURCE_TYPE)
    display_name = property(lambda self: "Stub")

    def get_series_list(self, page, *, sort=None):  # pragma: no cover
        raise NotImplementedError

    def search_series(self, query, page, *, sort=None):  # pragma: no cover
        raise NotImplementedError

    def get_series(self, series_id):  # pragma: no cover
        raise NotImplementedError

    def get_chapters(self, series_id):  # pragma: no cover
        raise NotImplementedError

    def get_chapter_pages(self, chapter_id):  # pragma: no cover
        raise NotImplementedError


def _stub_class(source_id):
    return type("Stub_" + source_id, (_Stub,), {"SOURCE_TYPE": source_id})


def test_create_connector_routes_every_client_of_a_cached_configless_connector(
    monkeypatch, recorded
):
    _configure(monkeypatch)
    httpx_rec, curl_rec = recorded
    monkeypatch.setattr(registry, "_INSTANCE_CACHE", {})
    for source_id in (ROUTED, OTHER):
        monkeypatch.setitem(registry._REGISTRY, source_id, _stub_class(source_id))
        monkeypatch.setattr(
            registry, "_CONFIGLESS_CONNECTORS", registry._CONFIGLESS_CONNECTORS | {source_id}
        )

    first = registry.create_connector(ROUTED)
    assert registry.create_connector(ROUTED) is first  # cached: built once, proxied once
    assert [c.get("proxy") for c in httpx_rec.calls] == [PROXY]
    assert [c.get("proxy") for c in curl_rec.calls] == [PROXY, PROXY]

    httpx_rec.calls.clear()
    curl_rec.calls.clear()
    registry.create_connector(OTHER)
    assert httpx_rec.calls and not any("proxy" in c for c in httpx_rec.calls + curl_rec.calls)


def test_a_configured_connector_is_routed_too(monkeypatch, recorded):
    _configure(monkeypatch)
    httpx_rec, _ = recorded
    monkeypatch.setitem(registry._REGISTRY, ROUTED, _stub_class(ROUTED))
    registry.create_connector(ROUTED)
    assert httpx_rec.calls[-1]["proxy"] == PROXY


def test_a_madara_catalogue_connector_is_routed(monkeypatch, recorded):
    _configure(monkeypatch, sources="toonily,apcomics")
    httpx_rec, curl_rec = recorded
    monkeypatch.setattr(registry, "_INSTANCE_CACHE", {})
    by_id = {c.source_id: c for c in MADARA_CATALOG}
    assert by_id["toonily"].use_cf is True and by_id["apcomics"].use_cf is False
    for source_id in ("toonily", "apcomics", "cocomic"):
        monkeypatch.setitem(
            registry._REGISTRY, source_id, build_madara_connector_class(by_id[source_id])
        )
        monkeypatch.setattr(
            registry, "_CONFIGLESS_CONNECTORS", registry._CONFIGLESS_CONNECTORS | {source_id}
        )

    registry.create_connector("toonily")  # curl_cffi flavour
    assert curl_rec.calls[-1]["proxy"] == PROXY
    registry.create_connector("apcomics")  # httpx flavour
    assert httpx_rec.calls[-1]["proxy"] == PROXY
    httpx_rec.calls.clear()
    registry.create_connector("cocomic")  # same flavour, not listed
    assert httpx_rec.calls and "proxy" not in httpx_rec.calls[-1]


def test_the_search_scoped_instance_is_routed_as_well(monkeypatch, recorded):
    _configure(monkeypatch)
    httpx_rec, _ = recorded
    monkeypatch.setattr(registry, "_INSTANCE_CACHE", {})
    monkeypatch.setattr(browse_service, "_search_connectors", {})
    monkeypatch.setitem(registry._REGISTRY, ROUTED, _stub_class(ROUTED))
    monkeypatch.setattr(
        registry, "_CONFIGLESS_CONNECTORS", registry._CONFIGLESS_CONNECTORS | {ROUTED}
    )
    registry.create_connector(ROUTED)
    httpx_rec.calls.clear()
    browse_service._search_connector(ROUTED)  # builds type(connector)() itself
    assert httpx_rec.calls[-1]["proxy"] == PROXY


def test_a_client_rebuilt_later_keeps_its_sources_route(monkeypatch, recorded):
    """mangahub swaps its chapter client on every spent nonce -- long after the
    registry's construction context is gone."""
    _configure(monkeypatch, sources="mangahub")
    httpx_rec, _ = recorded
    monkeypatch.setattr(registry, "_INSTANCE_CACHE", {})
    connector = registry.create_connector("mangahub")
    assert httpx_rec.calls[-1]["proxy"] == PROXY
    httpx_rec.calls.clear()
    connector._build_client({"x-mhub-access": "n"})
    assert httpx_rec.calls[-1]["proxy"] == PROXY


def test_the_freeadultcomix_session_is_proxied_and_skips_the_direct_dns_lookup(
    monkeypatch, recorded
):
    import connectors.freeadultcomix.http as fac

    _configure(monkeypatch, sources="freeadultcomix")
    _, curl_rec = recorded
    monkeypatch.setattr(fac, "Session", _RecordingCurl)

    def no_lookup():  # a DoH request made for this source would be direct egress
        raise AssertionError("DoH lookup for a routed source")

    monkeypatch.setattr(fac, "build_resolve_entries", no_lookup)
    with egress.constructing_source("freeadultcomix"):
        client = fac.FacSyncHttpClient("https://example.test")
    assert curl_rec.calls[-1]["proxy"] == PROXY
    client.refresh_dns()  # outside the context
    assert curl_rec.calls[-1]["proxy"] == PROXY

    monkeypatch.setattr(fac, "build_resolve_entries", lambda: [])
    other = fac.FacSyncHttpClient("https://example.test")
    assert "proxy" not in curl_rec.calls[-1]
    other.close()
    client.close()


def test_the_proxy_environment_is_not_read_for_the_feature(monkeypatch):
    """Only MM_ALT_EGRESS_PROXY counts; HTTPS_PROXY/ALL_PROXY never enable it."""
    _configure(monkeypatch, None, ROUTED)
    for key in ("HTTPS_PROXY", "https_proxy", "ALL_PROXY", "all_proxy"):
        monkeypatch.setenv(key, "http://198.51.100.9:8080")
    get_settings.cache_clear()
    assert egress.proxy_for_source(ROUTED) is None
    assert egress.endpoint() is None
    assert egress.curl_kwargs() == {} and egress.httpx_kwargs() == {}


# --- the image proxy's shared path --------------------------------------------


@pytest.fixture
def clean_image_clients():
    browse_service._image_http_client = None
    browse_service._proxied_image_http_client = None
    yield
    for name in ("_image_http_client", "_proxied_image_http_client"):
        client = getattr(browse_service, name)
        if client is not None:
            client.close()
        setattr(browse_service, name, None)


def test_the_proxied_image_client_is_separate_reused_and_configured_alike(
    monkeypatch, clean_image_clients
):
    _configure(monkeypatch)
    direct = browse_service._image_client()
    proxied = browse_service._proxied_image_client()
    assert proxied is not direct
    assert browse_service._proxied_image_client() is proxied
    assert proxied.follow_redirects is False and direct.follow_redirects is False
    assert proxied.timeout == direct.timeout
    assert [type(t._pool).__name__ for t in proxied._mounts.values() if t] == ["HTTPProxy"]
    pool = next(t for t in proxied._mounts.values() if t)._pool
    assert pool._max_connections == browse_service._IMAGE_POOL_MAX_CONNECTIONS
    assert not any(
        t and getattr(getattr(t._pool, "_proxy_url", None), "host", None) == b"203.0.113.7"
        for t in direct._mounts.values()
    )
    assert next(t for t in proxied._mounts.values() if t)._pool._proxy_url.host == b"203.0.113.7"
    proxied.close()
    assert browse_service._proxied_image_client() is not proxied  # rebuilt, like the direct one


class _ImageConnector(_Stub):
    @property
    def allowed_image_hosts(self):
        return frozenset({"example.com"})


def _fake_stream(content=b"img"):
    response = MagicMock()
    response.is_redirect = False
    response.headers = {"content-type": "image/png"}
    response.iter_bytes = lambda: iter([content])
    cm = MagicMock()
    cm.__enter__ = MagicMock(return_value=response)
    cm.__exit__ = MagicMock(return_value=False)
    return cm


def test_the_shared_image_path_uses_the_proxied_client_only_for_routed_sources(monkeypatch):
    _configure(monkeypatch)
    monkeypatch.setattr("services.outbound_security.is_public_address", lambda host: True)
    direct, proxied = MagicMock(), MagicMock()
    direct.stream.side_effect = lambda *a, **k: _fake_stream()
    proxied.stream.side_effect = lambda *a, **k: _fake_stream()
    monkeypatch.setattr(browse_service, "_image_client", lambda: direct)
    monkeypatch.setattr(browse_service, "_proxied_image_client", lambda: proxied)
    service = BrowseService.__new__(BrowseService)

    def connector(source_id):
        conn = _ImageConnector.__new__(_ImageConnector)
        conn.SOURCE_TYPE = source_id
        return conn

    service._fetch_url("https://example.com/1.png", connector(ROUTED))
    assert proxied.stream.call_count == 1 and direct.stream.call_count == 0
    service._fetch_url("https://example.com/2.png", connector(OTHER))
    assert proxied.stream.call_count == 1 and direct.stream.call_count == 1


def test_the_ssrf_guard_still_validates_the_destination_of_a_routed_source(monkeypatch):
    _configure(monkeypatch)
    monkeypatch.setattr(
        browse_service, "_proxied_image_client", lambda: pytest.fail("fetched past the guard")
    )
    service = BrowseService.__new__(BrowseService)
    conn = _ImageConnector.__new__(_ImageConnector)
    conn.SOURCE_TYPE = ROUTED
    for url in ("http://example.com/x.png", "https://evil.test/x.png"):
        with pytest.raises(AppError) as raised:
            service._fetch_url(url, conn)
        assert raised.value.code == "ssrf_blocked"


# --- proxy failures are not the site failing ----------------------------------


def _chain(outer: Exception, inner: BaseException) -> Exception:
    outer.__cause__ = inner
    return outer


def _httpx_connect_failure():
    return _chain(
        ConnectorHttpError("[Errno 111] Connection refused"),
        httpx.ConnectError("[Errno 111] Connection refused"),
    )


def _curl_proxy_failure():
    return _chain(
        ConnectorHttpError("Failed to perform, curl: (56) CONNECT tunnel failed, response 403."),
        curl_exc.ProxyError("Failed to perform, curl: (56) CONNECT tunnel failed, response 403."),
    )


def _curl_connect_to_proxy_failure():
    err = curl_exc.ConnectionError(
        "Failed to perform, curl: (7) Failed to connect to 203.0.113.7 port 3128 "
        "after 0 ms: Could not connect to server."
    )
    err.code = 7
    return _chain(ConnectorHttpError(str(err)), err)


@pytest.mark.parametrize(
    "make", [_httpx_connect_failure, _curl_proxy_failure, _curl_connect_to_proxy_failure]
)
def test_classification_only_applies_to_a_routed_source(monkeypatch, make):
    _configure(monkeypatch)
    assert egress.is_proxy_failure(ROUTED, make()) is True
    # The same failure for a direct source is the site's: refused is refused.
    assert egress.is_proxy_failure(OTHER, make()) is False
    _configure(monkeypatch, None, None)
    assert egress.is_proxy_failure(ROUTED, make()) is False


def test_a_curl_connect_failure_to_the_site_is_not_blamed_on_the_proxy(monkeypatch):
    _configure(monkeypatch)
    err = curl_exc.ConnectionError(
        "Failed to perform, curl: (7) Failed to connect to 198.51.100.20 port 443 after 3 ms"
    )
    err.code = 7
    assert egress.is_proxy_failure(ROUTED, _chain(ConnectorHttpError("x"), err)) is False


def test_a_read_timeout_is_not_a_proxy_failure(monkeypatch):
    _configure(monkeypatch)
    exc = _chain(ConnectorHttpError("timed out"), httpx.ReadTimeout("timed out"))
    assert egress.is_proxy_failure(ROUTED, exc) is False


class _DownConnector:
    is_browsable = True
    is_mature = False
    source_type = ROUTED
    exc: Exception

    def get_series(self, series_id):
        raise self.exc

    def get_chapters(self, series_id):
        raise self.exc

    def get_chapter_pages(self, chapter_id):
        raise self.exc

    def find_page(self, page_id):
        raise self.exc


@pytest.fixture
def lenient(app):
    with TestClient(app, raise_server_exceptions=False) as c:
        yield c


@pytest.mark.parametrize(
    "make", [_httpx_connect_failure, _curl_proxy_failure, _curl_connect_to_proxy_failure]
)
def test_a_proxy_failure_on_a_source_route_is_a_502_naming_host_and_port_in_the_log(
    monkeypatch, lenient, caplog, make
):
    _configure(monkeypatch)
    connector = _DownConnector()
    connector.exc = make()
    monkeypatch.setattr(browse_service, "create_connector", lambda source_id: connector)
    key = quote("some-series", safe="")
    with caplog.at_level(logging.WARNING):
        resp = lenient.get(f"/sources/{ROUTED}/series/{key}/chapters")
    assert resp.status_code == 502, resp.text
    body = resp.json()
    assert body["code"] == "source_unreachable"
    assert PASSWORD not in resp.text and "203.0.113.7" not in resp.text
    lines = [r.getMessage() for r in caplog.records if "alternate egress proxy" in r.getMessage()]
    assert len(lines) == 1
    assert "203.0.113.7:3128" in lines[0] and ROUTED in lines[0]
    assert PASSWORD not in caplog.text


def test_the_same_failure_for_a_direct_source_logs_no_proxy_line(monkeypatch, lenient, caplog):
    _configure(monkeypatch)
    connector = _DownConnector()
    connector.exc = _httpx_connect_failure()
    monkeypatch.setattr(browse_service, "create_connector", lambda source_id: connector)
    key = quote("some-series", safe="")
    with caplog.at_level(logging.WARNING):
        resp = lenient.get(f"/sources/{OTHER}/series/{key}/chapters")
    assert resp.status_code == 502 and resp.json()["code"] == "source_unreachable"
    assert "alternate egress proxy" not in caplog.text


def test_a_proxy_failure_fetching_an_image_is_the_same_502(monkeypatch):
    _configure(monkeypatch)
    monkeypatch.setattr("services.outbound_security.is_public_address", lambda host: True)
    service = BrowseService.__new__(BrowseService)
    conn = _ImageConnector.__new__(_ImageConnector)
    conn.SOURCE_TYPE = ROUTED

    class _Boom:
        def stream(self, *a, **k):
            raise httpx.ProxyError("403 Forbidden")

    monkeypatch.setattr(browse_service, "_proxied_image_client", lambda: _Boom())
    with pytest.raises(AppError) as raised:
        service._fetch_url("https://example.com/1.png", conn)
    assert raised.value.code == "source_unreachable" and raised.value.status_code == 502

    # A connector-handled fetch (its own client) lands in the same place.
    conn2 = _ImageConnector.__new__(_ImageConnector)
    conn2.SOURCE_TYPE = ROUTED
    conn2.fetch_proxied_image = lambda url: (_ for _ in ()).throw(_curl_proxy_failure())
    with pytest.raises(AppError) as raised:
        service._fetch_url("https://example.com/1.png", conn2)
    assert raised.value.code == "source_unreachable"


# --- traffic really goes through a proxy, on both stacks ----------------------


class _LocalProxy:
    """A forward proxy on loopback for plain-HTTP absolute-URI requests, which
    is what both stacks send for an ``http://`` destination."""

    def __init__(self, user: str | None = None, password: str | None = None) -> None:
        self.seen: list[tuple[str, str | None]] = []
        self._user, self._password = user, password
        self._srv = socket.socket()
        self._srv.bind(("127.0.0.1", 0))
        self._srv.listen(10)
        self.port = self._srv.getsockname()[1]
        threading.Thread(target=self._loop, daemon=True).start()

    def _loop(self):
        while True:
            try:
                conn, _ = self._srv.accept()
            except OSError:
                return
            threading.Thread(target=self._serve, args=(conn,), daemon=True).start()

    def _serve(self, conn):
        import base64

        with conn:
            data = b""
            while b"\r\n\r\n" not in data:
                chunk = conn.recv(65536)
                if not chunk:
                    return
                data += chunk
            lines = data.split(b"\r\n\r\n")[0].decode("latin1").split("\r\n")
            headers = {
                l.split(":", 1)[0].lower(): l.split(":", 1)[1].strip() for l in lines[1:] if ":" in l
            }
            self.seen.append((lines[0], headers.get("proxy-authorization")))
            if self._user is not None:
                want = "Basic " + base64.b64encode(f"{self._user}:{self._password}".encode()).decode()
                if headers.get("proxy-authorization") != want:
                    conn.sendall(b"HTTP/1.1 407 Proxy Authentication Required\r\nContent-Length: 0\r\n\r\n")
                    return
            body = b"<html>via-proxy</html>"
            conn.sendall(
                b"HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nConnection: close\r\n"
                + f"Content-Length: {len(body)}\r\n\r\n".encode()
                + body
            )

    def close(self):
        self._srv.close()


@pytest.mark.parametrize("cls", [SyncConnectorHttpClient, CfSyncHttpClient, DdgSyncHttpClient])
def test_a_routed_client_sends_through_the_proxy_with_its_credential(monkeypatch, cls):
    proxy = _LocalProxy("mm", "p@ss")
    try:
        _configure(monkeypatch, f"http://mm:p%40ss@127.0.0.1:{proxy.port}")
        # Whatever the host environment says, only MM_ALT_EGRESS_PROXY counts.
        for key in ("HTTP_PROXY", "http_proxy", "ALL_PROXY", "all_proxy"):
            monkeypatch.setenv(key, "http://127.0.0.1:9")
        client = _build(cls, ROUTED, base="http://origin.test")
        assert "via-proxy" in client.get_text("/series")
        assert proxy.seen and proxy.seen[0][0].startswith("GET http://origin.test/series")
        assert proxy.seen[0][1] is not None  # Proxy-Authorization reached it
        client.close()
    finally:
        proxy.close()


def test_get_settings_does_not_load_the_connector_registry():
    # Migrations and scripts read settings; they must not depend on every
    # connector importing and registering cleanly.
    import subprocess
    import sys

    code = (
        "import sys\n"
        "from core.config import get_settings\n"
        "get_settings()\n"
        "bad = [m for m in ('connectors.registry', 'connectors.http.egress') "
        "if m in sys.modules]\n"
        "sys.exit(1 if bad else 0)\n"
    )
    result = subprocess.run(
        [sys.executable, "-c", code], capture_output=True, text=True, timeout=60
    )
    assert result.returncode == 0, result.stderr


# --- the proxy's address stays out of anything a client can read --------------


def _proxy_down_outcomes():
    return {
        ROUTED: _curl_connect_to_proxy_failure(),
        OTHER: ConnectorHttpError("Failed to connect to origin.example port 443"),
    }


@pytest.mark.parametrize(
    "make",
    [_httpx_connect_failure, _curl_proxy_failure, _curl_connect_to_proxy_failure],
)
def test_a_federated_search_error_for_a_routed_source_names_nothing_of_the_proxy(
    monkeypatch, db_session, make
):
    from services.source_health import load_states

    _configure(monkeypatch)
    service = BrowseService(mature_enabled=True, db=db_session)
    exc = make()

    class _Descriptor:
        source_type = ROUTED
        name = "Routed"
        icon_url = None
        mature = False

    from services.source_health import SourceHealthState

    group, _score = service._build_source_group(
        _Descriptor(),
        exc,
        query_norm="q",
        tokens=["q"],
        health=SourceHealthState(source_id=ROUTED, status="unknown", consecutive_failures=0),
        gate_open=True,
    )
    service._merge_health({ROUTED: exc})
    stored = load_states(db_session)[ROUTED].last_error

    for message in (group["error"], stored):
        assert message == "Could not reach the source site."
        assert "203.0.113.7" not in message and "3128" not in message
        assert PASSWORD not in message


def test_a_direct_sources_search_error_keeps_its_own_text(monkeypatch, db_session):
    from services.source_health import load_states

    _configure(monkeypatch)
    outcomes = _proxy_down_outcomes()
    BrowseService(mature_enabled=True, db=db_session)._merge_health(outcomes)
    stored = load_states(db_session)
    assert stored[OTHER].last_error == "Failed to connect to origin.example port 443"
    assert stored[ROUTED].last_error == "Could not reach the source site."
