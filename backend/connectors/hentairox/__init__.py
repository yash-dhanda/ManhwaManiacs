"""HentaiRox online source connector."""

from __future__ import annotations

from connectors.hentaifamily.connector import build_hentai_family_connector
from connectors.hentaifamily.mappers import HentaiFamilySite

HENTAIROX_SITE = HentaiFamilySite(
    source_id="hentairox",
    display_name="HentaiRox",
    site_base="https://hentairox.com",
    reader_segment="view",
    image_host_suffix="hentairox.com",
    search_param="key",
    explicit_first_page=True,
)

HentaiRoxConnector = build_hentai_family_connector(HENTAIROX_SITE)

__all__ = ["HentaiRoxConnector", "HENTAIROX_SITE"]
