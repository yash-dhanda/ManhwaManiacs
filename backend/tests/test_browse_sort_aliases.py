"""Legacy browse sort ids share the canonical id's cache row.

Connectors changed the ids they advertise (``popular`` / ``latest`` / ``new``)
but still accept the old ones and send the same upstream request for them. The
browse cache serves a sort only if the connector advertises it, so without an
alias an older client's id went upstream on every request: no cache, no
next-page warm, and a 502 instead of the stale page when the source is down.
"""

from __future__ import annotations

import json
from datetime import timedelta

import pytest

from connectors.base import SourceConnector
from connectors.models import BrowseMode
from core.time_utils import utcnow
from database.models import SourceBrowseCache
from services.source_cache_service import SourceCacheService
from tests._fakes import FakeBrowse

SRC = "alias-stub-source"


def _listing(tag: str) -> dict:
    return {
        "items": [
            {
                "id": f"{tag}-0",
                "source_id": SRC,
                "title": f"{tag} series",
                "genres": ["Action"],
            }
        ],
        "page": 1,
        "page_size": 1,
        "total": 1,
        "total_pages": 1,
        "has_more": False,
    }


class _Connector:
    LEGACY_SORT_ALIASES = {"updated": "latest"}

    def list_browse_modes(self):
        return [
            BrowseMode(id="latest", label="Latest"),
            BrowseMode(id="popular", label="Popular"),
        ]

    def list_genres(self):
        return []


class _Browse(FakeBrowse):
    def _get_connector(self, source_id):
        return _Connector()


def _seed(db, sort: str, tag: str, *, age_minutes: float = 1.0):
    db.add(
        SourceBrowseCache(
            source_id=SRC,
            sort=sort,
            genre="",
            page=1,
            payload=json.dumps(_listing(tag)),
            fetched_at=utcnow() - timedelta(minutes=age_minutes),
        )
    )
    db.commit()


def _svc(db):
    browse = _Browse(listings={(SRC, "latest", "", 1): _listing("live-latest")})
    return SourceCacheService(db, browse), browse


def test_a_legacy_id_is_served_from_the_canonical_row(db_session):
    _seed(db_session, "latest", "cached")
    svc, browse = _svc(db_session)

    payload = svc.get_browse_page(SRC, sort="updated")

    assert browse.calls == []
    assert payload["cache"]["status"] == "fresh"
    assert payload["items"][0]["title"] == "cached series"


def test_a_legacy_id_writes_the_canonical_row_and_asks_for_the_canonical_id(db_session):
    svc, browse = _svc(db_session)

    payload = svc.get_browse_page(SRC, sort="updated")

    assert payload["items"][0]["title"] == "live-latest series"
    assert browse.calls == [
        f"list_series:{SRC}?page=1&sort=latest&genre=None&query=None&apply_gate=False"
    ]
    assert db_session.get(SourceBrowseCache, (SRC, "latest", "", 1)) is not None
    assert db_session.get(SourceBrowseCache, (SRC, "updated", "", 1)) is None
    # and the next read, under either spelling, is a pure cache hit
    browse.calls.clear()
    assert svc.get_browse_page(SRC, sort="latest")["cache"]["status"] == "fresh"
    assert svc.get_browse_page(SRC, sort="updated")["cache"]["status"] == "fresh"
    assert browse.calls == []


def test_a_legacy_id_gets_the_stale_fallback_when_the_source_fails(db_session):
    _seed(db_session, "latest", "old", age_minutes=999)
    svc, browse = _svc(db_session)
    browse.down = True

    payload = svc.get_browse_page(SRC, sort="updated")

    assert payload["cache"]["status"] == "stale"
    assert payload["items"][0]["title"] == "old series"


def test_an_id_with_no_alias_is_still_served_live_and_stored_nowhere(db_session):
    svc, browse = _svc(db_session)
    browse.listings[(SRC, "hot", "", 1)] = _listing("live-hot")

    payload = svc.get_browse_page(SRC, sort="hot")

    assert payload["cache"]["status"] == "live"
    assert db_session.get(SourceBrowseCache, (SRC, "hot", "", 1)) is None
    assert db_session.get(SourceBrowseCache, (SRC, "latest", "", 1)) is None


# (source id, legacy id, canonical id, what each resolves to upstream). The
# last column is the connector's OWN resolution of the id, so an alias that
# points at a different request fails here rather than serving the wrong list.
def _cases():
    from connectors.aurorascans import mappers as aurora
    from connectors.comicasura import mappers as comicasura
    from connectors.asurascans import connector as asura
    from connectors.guazimanhua import mappers as guazi
    from connectors.hentaihand import mappers as hentaihand
    from connectors.mangabuddy import mappers as buddy
    from connectors.mangadex import connector as dex
    from connectors.mangatown import mappers as town
    from connectors.manhwa18 import mappers as m18
    from connectors.manhwa18net import mappers as m18net
    from connectors.fanfox import mappers as fanfox
    from connectors.manhwaweb import connector as manhwaweb
    from connectors.omegascans import mappers as omega

    def captured_request(source_id):
        """The connector's own first upstream request for ``sort`` (HTTP stubbed)."""
        from connectors.registry import create_connector

        def request_for(sort):
            connector = create_connector(source_id)
            seen: list = []
            if source_id == "freeadultcomix":
                connector._fetch_html = lambda path: seen.append(path) or "<html></html>"
            else:  # comicland: fake catalogue of 30, every request recorded
                def fake(path, *, params=None):
                    seen.append((path, dict(params or {})))
                    return {"code": 0, "data": {"list": []}}

                connector._http.get_json = fake
                connector._size_cache.set("size", 30)
            connector.get_series_list(2, sort=sort)
            return seen

        return request_for

    def asura_req(sort):
        return asura._API_SORT.get(sort, sort)

    def dex_req(sort):
        return dex.MANGA_SORT_ORDERS.get(sort or "default")

    return [
        ("asurascans", "updated", "new", asura_req),
        ("aurorascans", "top_rated", "popular", aurora.resolve_sort),
        ("comicasura", "bookmark", "popular", lambda s: comicasura.listing_path(1, sort=s)),
        ("guazimanhua", "update", "latest", lambda s: guazi.browse_params(s, 1)),
        ("guazimanhua", "hits", "popular", lambda s: guazi.browse_params(s, 1)),
        ("hentaihand", "popularity", "popular", lambda s: hentaihand.browse_params(s, 1)),
        ("mangabuddy", "newest", "new", buddy.explicit_sort),
        ("comicland", "latest", "new", captured_request("comicland")),
        ("fanfox", "news", "new", lambda s: fanfox.listing_path(2, sort=s)),
        ("freeadultcomix", "latest", "new", captured_request("freeadultcomix")),
        ("mangadex", "updated", "latest", dex_req),
        ("manhwaweb", "latest", "new", lambda s: manhwaweb.SORTS[s]),
        ("mangatown", "hot", "popular", lambda s: town.listing_path(1, sort=s)),
        ("manhwa18", "trending", "popular", lambda s: m18._BROWSE_BY_ID[s]),
        ("manhwa18net", "top", "popular", lambda s: m18net.browse_params(s, 1)),
        ("omegascans", "added", "new", lambda s: omega.SORT_TO_ORDER[s]),
    ]


@pytest.mark.parametrize("source_id,legacy,canonical,request_for", _cases())
def test_each_declared_alias_is_the_same_upstream_request(
    source_id, legacy, canonical, request_for
):
    from connectors.registry import create_connector

    connector = create_connector(source_id)
    advertised = {mode.id for mode in connector.list_browse_modes()}

    assert connector.LEGACY_SORT_ALIASES[legacy] == canonical
    assert legacy not in advertised
    assert canonical in advertised
    assert request_for(legacy) == request_for(canonical)


def test_the_declared_aliases_are_exactly_the_ones_checked_above():
    from connectors import registry

    declared = {
        (source_id, legacy)
        for source_id, cls in registry._REGISTRY.items()
        for legacy in cls.LEGACY_SORT_ALIASES
    }
    assert declared == {(sid, legacy) for sid, legacy, _c, _r in _cases()}


def test_the_base_connector_declares_no_aliases():
    assert SourceConnector.LEGACY_SORT_ALIASES == {}
