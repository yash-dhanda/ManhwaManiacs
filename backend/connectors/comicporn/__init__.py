"""ComicPorn.XXX online source connector."""

from __future__ import annotations

from connectors.hentaifamily.connector import build_hentai_family_connector
from connectors.hentaifamily.mappers import HentaiFamilySite

COMICPORN_SITE = HentaiFamilySite(
    source_id="comicporn",
    display_name="ComicPorn",
    site_base="https://comicporn.xxx",
    reader_segment="view",
    image_host_suffix="comicporn.xxx",
    search_param="key",
    explicit_first_page=True,
)

ComicPornConnector = build_hentai_family_connector(COMICPORN_SITE)

__all__ = ["ComicPornConnector", "COMICPORN_SITE"]
