"""Parsing and validation of the alternate-egress settings.

Kept outside the ``connectors`` package on purpose: importing anything under
``connectors`` registers every connector, and ``core.config`` (which
``alembic/env.py`` and every lightweight script load) must be able to read
these settings without that.
"""

from __future__ import annotations

from urllib.parse import urlsplit


class EgressConfigError(ValueError):
    """``MM_ALT_EGRESS_PROXY`` is not a usable proxy URL.

    The message never contains the offending value: it is a credential in the
    common case, and a startup traceback ends up in the container log.
    """


_SOCKS_SCHEMES = frozenset({"socks4", "socks4a", "socks5", "socks5h"})


def parse_proxy_url(raw: str | None) -> str:
    """Validate ``MM_ALT_EGRESS_PROXY``; ``""`` means the feature is off.

    ``http://`` and ``https://`` only, with an explicit port (the port is what
    the log line and the docs name, and a default would hide a typo). SOCKS is
    refused, not because libcurl cannot do it -- it can -- but because httpx
    needs the optional ``socksio`` package for it, which this deployment does
    not ship (``httpx.Client(proxy="socks5://...")`` raises ImportError). A
    source routed through SOCKS would work on the curl_cffi stack and fail on
    the httpx one, so it is rejected up front rather than half-working.
    """
    value = (raw or "").strip()
    if not value:
        return ""
    if any(ch.isspace() or ord(ch) < 32 for ch in value):
        raise EgressConfigError(
            "MM_ALT_EGRESS_PROXY contains whitespace or control characters; "
            "expected http://[user:password@]host:port."
        )
    try:
        parts = urlsplit(value)
        port = parts.port
        host = parts.hostname
    except ValueError:
        raise EgressConfigError(
            "MM_ALT_EGRESS_PROXY is not a valid URL; "
            "expected http://[user:password@]host:port."
        ) from None
    scheme = parts.scheme.lower()
    if scheme in _SOCKS_SCHEMES:
        raise EgressConfigError(
            "MM_ALT_EGRESS_PROXY: SOCKS proxies are not supported (httpx needs "
            "the optional 'socksio' package, which is not installed); run an "
            "HTTP CONNECT proxy and use an http:// or https:// URL."
        )
    if scheme not in {"http", "https"}:
        raise EgressConfigError(
            "MM_ALT_EGRESS_PROXY must start with http:// or https://."
        )
    if not host:
        raise EgressConfigError("MM_ALT_EGRESS_PROXY has no host.")
    if port is None:
        raise EgressConfigError(
            "MM_ALT_EGRESS_PROXY needs an explicit port, e.g. "
            "http://user:password@203.0.113.7:3128."
        )
    if port == 0:
        raise EgressConfigError("MM_ALT_EGRESS_PROXY has an invalid port.")
    if parts.path not in {"", "/"} or parts.query or parts.fragment:
        raise EgressConfigError(
            "MM_ALT_EGRESS_PROXY must not have a path, query or fragment."
        )
    return value


def parse_source_ids(raw: str | None) -> tuple[str, ...]:
    """``MM_ALT_EGRESS_SOURCES``: comma-separated ids, lowercased, deduplicated."""
    seen: dict[str, None] = {}
    for item in (raw or "").split(","):
        source_id = item.strip().lower()
        if source_id:
            seen.setdefault(source_id)
    return tuple(seen)
