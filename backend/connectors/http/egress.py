"""Alternate egress: send selected sources' outbound requests through one proxy.

Some sources refuse the production VPS's datacenter address while working fine
from elsewhere (see ``connectors.excluded.ALT_EGRESS_ONLY_CONNECTORS``).
``MM_ALT_EGRESS_PROXY`` names a forward proxy on a second server and
``MM_ALT_EGRESS_SOURCES`` lists the sources whose requests go through it. Both
are read once per process, so a change needs a restart.

The HTTP clients are built inside connector constructors and do not know which
source they serve. Rather than thread a source id through ~60 constructors,
the registry (and the one other place that builds a connector class directly)
declares the source being built with :func:`constructing_source`, and each
client reads :func:`current_proxy` in its own constructor. A connector built
any other way -- a test calling its class directly -- simply gets no proxy.

Only ``MM_ALT_EGRESS_PROXY`` counts. The ``HTTPS_PROXY`` / ``ALL_PROXY``
environment variables are not read here: httpx still honours them for direct
requests, exactly as before, and a routed client's explicit proxy overrides
them.

The proxy URL carries a credential. It is never logged, never put in an
exception message and never serialised: everything that has to name the proxy
uses :func:`endpoint`, which is ``host:port`` only.
"""

from __future__ import annotations

import logging
from collections.abc import Iterator
from contextlib import contextmanager
from contextvars import ContextVar
from typing import Any
from urllib.parse import urlsplit

from core.egress_config import (  # noqa: F401 - re-exported for existing importers
    EgressConfigError,
    parse_proxy_url,
    parse_source_ids,
)

logger = logging.getLogger(__name__)


def _settings() -> Any:
    from core.config import get_settings

    return get_settings()


def proxy_url() -> str | None:
    """The configured proxy URL (a credential -- hand it to a client, never to a log)."""
    secret = getattr(_settings(), "alt_egress_proxy", None)
    value = secret.get_secret_value() if secret is not None else ""
    return value or None


def endpoint() -> str | None:
    """``host:port`` of the proxy: the only form of it that may be logged."""
    value = proxy_url()
    if value is None:
        return None
    parts = urlsplit(value)
    host = parts.hostname or ""
    return f"[{host}]:{parts.port}" if ":" in host else f"{host}:{parts.port}"


def routed_source_ids() -> frozenset[str]:
    """Sources whose requests go through the proxy. Empty unless a proxy is set."""
    if proxy_url() is None:
        return frozenset()
    return frozenset(getattr(_settings(), "alt_egress_sources", ()) or ())


def proxy_for_source(source_id: str | None) -> str | None:
    """The proxy URL a request for ``source_id`` must use, or None for direct."""
    if source_id and source_id in routed_source_ids():
        return proxy_url()
    return None


# The source whose connector is being constructed on this thread/task. A
# ContextVar rather than a module global: connectors are built from request
# threads and the search fan-out's pool concurrently.
_constructing: ContextVar[str | None] = ContextVar("connector_constructing_source", default=None)


@contextmanager
def constructing_source(source_id: str | None) -> Iterator[None]:
    """Mark the connector for ``source_id`` as being built inside this block."""
    token = _constructing.set(source_id)
    try:
        yield
    finally:
        _constructing.reset(token)


def current_source() -> str | None:
    return _constructing.get()


def current_proxy() -> str | None:
    """The proxy for the connector being constructed; what every client's
    constructor asks. None outside a registry-built connector."""
    return proxy_for_source(_constructing.get())


def httpx_kwargs() -> dict[str, Any]:
    """Extra ``httpx.Client`` arguments for the connector being constructed.

    Empty (not ``proxy=None``) for a direct client, so those are built exactly
    as they were before this existed.
    """
    proxy = current_proxy()
    return {"proxy": proxy} if proxy else {}


def curl_kwargs() -> dict[str, Any]:
    """Extra ``curl_cffi`` ``Session`` arguments for the connector being constructed."""
    proxy = current_proxy()
    return {"proxy": proxy} if proxy else {}


def is_proxy_failure(source_id: str | None, exc: BaseException | None) -> bool:
    """Did this failure happen reaching the proxy, rather than the site?

    Only meaningful for a routed source: for any other, a refused connection
    is the site's. For a routed one, httpx connects to nothing but the proxy
    (the destination is the proxy's business), so a ``ConnectError`` /
    ``ConnectTimeout`` is the proxy being down and a ``ProxyError`` is it
    refusing the tunnel (bad credential, IP not allowed, or it could not reach
    the site -- the proxy's own answer, not the site's). libcurl reports the
    same two conditions as ``ProxyError`` and as a connect-stage error whose
    message names the proxy's host and port.
    """
    if source_id is None or proxy_for_source(source_id) is None:
        return False
    import httpx

    try:
        from curl_cffi.const import CurlECode
        from curl_cffi.requests import exceptions as curl_exc
    except ImportError:  # pragma: no cover - curl_cffi is a hard dependency
        curl_exc = None
        CurlECode = None

    marker = endpoint() or ""
    hostport = marker.rsplit(":", 1)
    seen: list[BaseException] = []
    current = exc
    while current is not None and len(seen) < 8 and all(current is not s for s in seen):
        seen.append(current)
        if isinstance(current, (httpx.ProxyError, httpx.ConnectError, httpx.ConnectTimeout)):
            return True
        if curl_exc is not None:
            if isinstance(current, curl_exc.ProxyError):
                return True
            if isinstance(current, curl_exc.ConnectionError) and getattr(
                current, "code", None
            ) in {CurlECode.COULDNT_CONNECT, CurlECode.OPERATION_TIMEDOUT}:
                # libcurl: "Failed to connect to <host> port <port> ..." names
                # whichever hop it could not reach; the proxy's own host:port
                # in it is what makes it the proxy.
                text = str(current)
                if hostport[0].strip("[]") in text and f"port {hostport[-1]}" in text:
                    return True
        current = current.__cause__ or (
            None if current.__suppress_context__ else current.__context__
        )
    return False


def log_proxy_failure(source_id: str, exc: BaseException) -> None:
    """Server-side line for a proxy failure: host:port, never the credential."""
    logger.warning(
        "alternate egress proxy %s failed for source %s (%s)",
        endpoint(),
        source_id,
        type(exc).__name__,
    )


def log_startup_status(registered: set[str] | frozenset[str], target: logging.Logger | None = None) -> None:
    """One INFO line naming the proxy and its sources; one WARNING for ids
    that are not registered sources.

    Called once from the app's startup, next to the registry listing.
    """
    out = target or logger
    value = endpoint()
    if value is None:
        if getattr(_settings(), "alt_egress_sources", ()):
            out.info(
                "MM_ALT_EGRESS_SOURCES is set but MM_ALT_EGRESS_PROXY is not; "
                "alternate egress is off."
            )
        return
    routed = sorted(routed_source_ids() & set(registered))
    unknown = sorted(routed_source_ids() - set(registered))
    out.info(
        "Alternate egress on via %s for sources: %s",
        value,
        ", ".join(routed) or "none",
    )
    if unknown:
        out.warning(
            "MM_ALT_EGRESS_SOURCES names sources that are not registered and "
            "were ignored: %s",
            ", ".join(unknown),
        )
