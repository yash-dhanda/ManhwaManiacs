"""Recommendations from the worldwide catalogs, marked with what this reader's
sources actually carry.

The earlier recommender could only pick from ``source_series_cache`` -- series
some connector had already served -- so it recommended from a few thousand
rows, a third of them Asura re-caching the same titles under rotating slugs,
and it could never mention a series nobody here had browsed. The owner asked
for the opposite: search the whole world, and when a title is not on one of
his sources, still show it -- its name, what it is, how many chapters it has,
and how it is rated.

So the candidates come from AniList (crowd recommendations for the series this
reader is deepest into, and title verification for the AI box) and the latest
chapter from MangaUpdates, both public APIs that need no key. Each result is
then matched against the series cache and this profile's follows by title and
alternate titles; a match is a card that opens, a miss is a card that informs
and offers a search. Nothing here ever asks a source connector anything, so a
page of recommendations is never a scrape storm.

Only catalog metadata is kept (``WorldCatalogCache``): titles, format, status,
chapter count, rating, genres, cover and official links. Never descriptions.
"""

from __future__ import annotations

import difflib
import json
import logging
import re
from collections.abc import Callable
from concurrent.futures import ThreadPoolExecutor
from datetime import timedelta
from typing import Annotated, Any

import httpx
from fastapi import Depends
from sqlalchemy import delete, select
from sqlalchemy.orm import Session

from core.connector_directory import descriptor_for_source
from core.time_utils import utcnow
from database.models import FollowedSeries, SourceSeriesCache, WorldCatalogCache
from database.session import get_db
from services import ai_feedback
from services.cover_colour import attach_world_colours
from services.followed_series_service import (
    FollowedSeriesService,
    get_followed_series_service,
)

logger = logging.getLogger(__name__)

ANILIST_URL = "https://graphql.anilist.co"
MU_API = "https://api.mangaupdates.com/v1"
#: AniList's edge refuses a request with no User-Agent (403).
USER_AGENT = "ManhwaManiacs/3.4 (private reader)"
HTTP_TIMEOUT = 10.0

#: Recommendations and catalog entries change slowly; chapter counts weekly.
TTL = timedelta(days=7)
MU_TTL = timedelta(days=3)
PRUNE_AFTER = timedelta(days=30)

#: Parallel lookups per phase. AniList allows 90 requests a minute; a cold
#: page asks it about 2 per seed.
WORKERS = 6
#: MangaUpdates lookups (two requests each) per page, beyond which a card
#: simply shows no chapter count until a later visit fills the cache.
MAX_MU_LOOKUPS = 40

#: How close a catalog title must be to the name we asked about. The AniList
#: search is fuzzy and always returns its best guess; below this it is a
#: different book.
MATCH_RATIO = 0.8

FOR_YOU_LIMIT = 24

_MEDIA_FIELDS = (
    "id title{romaji english native} synonyms format countryOfOrigin status "
    "chapters averageScore genres isAdult coverImage{large} siteUrl "
    "externalLinks{site url type}"
)
_SEARCH_QUERY = (
    "query($s:String){Media(search:$s,type:MANGA){" + _MEDIA_FIELDS + "}}"
)
_RECS_QUERY = (
    "query($id:Int){Media(id:$id){recommendations(sort:RATING_DESC,perPage:15)"
    "{nodes{rating mediaRecommendation{" + _MEDIA_FIELDS + "}}}}}"
)

def _trending_query(adult_filter: bool) -> str:
    # AniList treats ``isAdult: null`` as "not adult" too, so the filter is
    # left out of the query entirely when adult entries are wanted.
    return (
        "query($country:CountryCode,$formats:[MediaFormat],$genres:[String]"
        + (",$adult:Boolean)" if adult_filter else ")")
        + "{Page(perPage:24){media(type:MANGA,sort:TRENDING_DESC,"
        + ("isAdult:$adult," if adult_filter else "")
        + "countryOfOrigin:$country,format_in:$formats,genre_in:$genres){"
        + _MEDIA_FIELDS
        + "}}}"
    )


#: Onboarding format -> (AniList country, AniList formats).
TRENDING_FORMATS: dict[str, tuple[str | None, list[str]]] = {
    "manhwa": ("KR", ["MANGA", "ONE_SHOT"]),
    "manga": ("JP", ["MANGA", "ONE_SHOT"]),
    "manhua": ("CN", ["MANGA", "ONE_SHOT"]),
    "novel": (None, ["NOVEL"]),
}
TRENDING_TTL = timedelta(hours=24)
#: AniList's fixed genre facet (``genre_in`` accepts only these).
ANILIST_GENRES = (
    "Action", "Adventure", "Comedy", "Drama", "Ecchi", "Fantasy", "Hentai", "Horror",
    "Mahou Shoujo", "Mecha", "Music", "Mystery", "Psychological", "Romance", "Sci-Fi",
    "Slice of Life", "Sports", "Supernatural", "Thriller",
)

_STATUS = {
    "RELEASING": "Ongoing",
    "FINISHED": "Completed",
    "HIATUS": "Hiatus",
    "CANCELLED": "Cancelled",
    "NOT_YET_RELEASED": "Upcoming",
}
_SOCIAL_SITES = {"twitter", "x", "instagram", "facebook", "youtube", "tiktok"}
_STRAIGHT = str.maketrans({"\u2019": "'", "\u2018": "'", "\u201c": '"', "\u201d": '"'})


def _transport() -> httpx.BaseTransport:
    """What carries the catalog requests -- a seam for the tests' mock."""
    return httpx.HTTPTransport()


_NON_ALNUM = re.compile(r"[^0-9a-z]+")


def match_key(title: str | None) -> str:
    """Title normalisation for cross-catalog matching: case, punctuation and a
    leading "the" do not make two titles different books."""
    text = _NON_ALNUM.sub(" ", (title or "").casefold()).strip()
    return text[4:] if text.startswith("the ") else text


def _names(media: dict[str, Any]) -> list[str]:
    title = media.get("title") or {}
    names = [title.get("english"), title.get("romaji"), title.get("native")]
    names += list(media.get("synonyms") or [])
    return [n for n in names if n]


def _close(name: str, media: dict[str, Any]) -> bool:
    want = match_key(name)
    if not want:
        return False
    for candidate in _names(media):
        got = match_key(candidate)
        if got == want or difflib.SequenceMatcher(None, want, got).ratio() >= MATCH_RATIO:
            return True
    return False


def _format(media: dict[str, Any]) -> str:
    fmt = media.get("format")
    if fmt == "NOVEL":
        return "Novel"
    if fmt == "ONE_SHOT":
        return "One-shot"
    return {"KR": "Manhwa", "CN": "Manhua", "TW": "Manhua", "JP": "Manga"}.get(
        media.get("countryOfOrigin") or "", "Comic"
    )


def enrichment_payload(media: dict[str, Any]) -> dict[str, Any]:
    """What ``GET /series/enrichment`` caches for one confident AniList match.

    ``is_adult`` is stored so the 18+ gate can be applied when serving; it is
    never serialized."""
    score = media.get("averageScore")
    official = [
        {"site": link.get("site"), "url": link["url"]}
        for link in media.get("externalLinks") or []
        if link.get("url")
        and link.get("type") != "SOCIAL"
        and (link.get("site") or "").casefold() not in _SOCIAL_SITES
    ][:6]
    return {
        "anilist_id": media["id"],
        "format": _format(media),
        "score": round(score / 10, 1) if isinstance(score, (int, float)) else None,
        "official": official,
        "is_adult": bool(media.get("isAdult")),
    }


class WorldCatalog:
    """AniList + MangaUpdates lookups behind a table cache.

    Network calls run in a small thread pool; the SQLAlchemy session is only
    ever touched on the calling thread (it is not thread-safe).
    """

    def __init__(self, db: Session) -> None:
        self._db = db
        self.failed = False

    # --- cache ------------------------------------------------------------

    def _read(self, keys: list[str], ttl: timedelta) -> dict[str, Any]:
        if not keys:
            return {}
        cutoff = utcnow() - ttl
        rows = self._db.execute(
            select(WorldCatalogCache.key, WorldCatalogCache.payload).where(
                WorldCatalogCache.key.in_(keys),
                WorldCatalogCache.fetched_at >= cutoff,
            )
        ).all()
        return {key: json.loads(payload) for key, payload in rows}

    def _write(self, answers: dict[str, Any]) -> None:
        if not answers:
            return
        now = utcnow()
        # Pruned BEFORE the merges: a key being refreshed may itself be past
        # PRUNE_AFTER, and deleting it under a pending merge made the flush's
        # UPDATE match nothing (StaleDataError).
        self._db.execute(
            delete(WorldCatalogCache).where(
                WorldCatalogCache.fetched_at < now - PRUNE_AFTER
            )
        )
        for key, value in answers.items():
            self._db.merge(
                WorldCatalogCache(key=key, payload=json.dumps(value), fetched_at=now)
            )
        self._db.commit()

    def _lookup(
        self,
        keys: dict[str, Any],
        fetch: Callable[[httpx.Client, Any], Any],
        ttl: timedelta,
    ) -> dict[str, Any]:
        """``keys`` maps cache key -> fetch argument. Misses are fetched in
        parallel; a failed fetch is left out (and not cached) rather than
        raised, so one slow catalog costs a card detail, not the page."""
        found = self._read(list(keys), ttl)
        missing = [k for k in keys if k not in found]
        if not missing:
            return found
        fresh: dict[str, Any] = {}
        with httpx.Client(
            transport=_transport(),
            timeout=HTTP_TIMEOUT,
            follow_redirects=False,
            headers={"User-Agent": USER_AGENT, "Accept": "application/json"},
        ) as client:

            def one(key: str) -> tuple[str, Any, bool]:
                try:
                    return key, fetch(client, keys[key]), True
                except (httpx.HTTPError, ValueError, KeyError, TypeError) as exc:
                    logger.warning("world catalog lookup failed (%s): %s", key[:60], exc)
                    return key, None, False

            with ThreadPoolExecutor(max_workers=WORKERS) as pool:
                for key, value, ok in pool.map(one, missing):
                    if ok:
                        fresh[key] = value
                    else:
                        self.failed = True
        self._write(fresh)
        return {**found, **fresh}

    # --- AniList ----------------------------------------------------------

    @staticmethod
    def _anilist(client: httpx.Client, query: str, variables: dict[str, Any]) -> Any:
        response = client.post(
            ANILIST_URL, json={"query": query, "variables": variables}
        )
        if response.status_code == 404:
            return None  # "Not Found." -- a real answer, cached as a miss
        response.raise_for_status()
        return response.json()["data"]["Media"]

    def search(self, titles: list[str]) -> dict[str, dict[str, Any] | None]:
        """Best catalog entry per title, or None when AniList has nothing
        close enough to be the same book."""
        keys = {f"al:search:{match_key(t)}": t for t in titles if match_key(t)}
        answers = self._lookup(
            keys,
            # AniList's search misses a title spelled with a curly apostrophe
            # ("Swordmaster’s Youngest Son"), which is how sources print them.
            lambda client, title: self._anilist(
                client, _SEARCH_QUERY, {"s": title.translate(_STRAIGHT)}
            ),
            TTL,
        )
        out: dict[str, dict[str, Any] | None] = {}
        for key, title in keys.items():
            media = answers.get(key)
            out[title] = media if media and _close(title, media) else None
        return out

    def recommendations(self, media_ids: list[int]) -> dict[int, list[tuple[int, dict[str, Any]]]]:
        keys = {f"al:recs:{i}": i for i in media_ids}
        answers = self._lookup(
            keys,
            lambda client, media_id: self._anilist(client, _RECS_QUERY, {"id": media_id}),
            TTL,
        )
        out: dict[int, list[tuple[int, dict[str, Any]]]] = {}
        for key, media_id in keys.items():
            nodes = ((answers.get(key) or {}).get("recommendations") or {}).get("nodes") or []
            out[media_id] = [
                (int(n.get("rating") or 0), n["mediaRecommendation"])
                for n in nodes
                if n.get("mediaRecommendation")
            ]
        return out

    @staticmethod
    def _anilist_page(client: httpx.Client, args: dict[str, Any]) -> Any:
        response = client.post(
            ANILIST_URL,
            json={"query": _trending_query("adult" in args), "variables": args},
        )
        response.raise_for_status()
        return response.json()["data"]["Page"]["media"] or []

    def trending(
        self, fmt: str, genres: list[str] | None = None, *, adult: bool = False
    ) -> list[dict[str, Any]]:
        """Trending AniList entries of one onboarding format, cached 24 hours.

        ``adult`` False asks AniList to leave adult entries out; True leaves the
        filter off. ``genres`` must already be AniList spellings."""
        country, formats = TRENDING_FORMATS[fmt]
        names = sorted(genres or [])
        key = f"al:trending:{fmt}:{','.join(names)}:{int(adult)}"
        args = {
            "country": country,
            "formats": formats,
            "genres": names or None,
        }
        if not adult:
            args["adult"] = False
        return self._lookup({key: args}, self._anilist_page, TRENDING_TTL).get(key) or []

    # --- MangaUpdates -----------------------------------------------------

    @staticmethod
    def _mangaupdates(client: httpx.Client, title: str) -> dict[str, Any] | None:
        found = client.post(
            f"{MU_API}/series/search", json={"search": title, "perpage": 3}
        )
        found.raise_for_status()
        best = None
        for result in found.json().get("results") or []:
            record = result.get("record") or {}
            if match_key(record.get("title")) == match_key(title) or (
                difflib.SequenceMatcher(
                    None, match_key(record.get("title")), match_key(title)
                ).ratio()
                >= MATCH_RATIO
            ):
                best = record
                break
        if best is None:
            return None
        detail = client.get(f"{MU_API}/series/{int(best['series_id'])}")
        detail.raise_for_status()
        data = detail.json()
        latest = data.get("latest_chapter")
        rating = data.get("bayesian_rating")
        return {
            "latest_chapter": int(latest) if isinstance(latest, (int, float)) else None,
            "rating": float(rating) if isinstance(rating, (int, float)) else None,
        }

    def chapters(self, titles: list[str]) -> dict[str, dict[str, Any] | None]:
        keys = {f"mu:{match_key(t)}": t for t in titles[:MAX_MU_LOOKUPS] if match_key(t)}
        answers = self._lookup(keys, self._mangaupdates, MU_TTL)
        return {title: answers.get(key) for key, title in keys.items()}


class WorldRecs:
    """Builds WorldItems (see the 3.4.3 API contract) for one reader."""

    def __init__(self, db: Session, library: FollowedSeriesService) -> None:
        self._db = db
        self._library = library
        self.catalog = WorldCatalog(db)

    # --- availability -----------------------------------------------------

    def _availability_index(self, gate_open: bool) -> dict[str, list[tuple[str, str]]]:
        """match_key(title) -> [(source_id, series_key)] this profile can open."""
        index: dict[str, list[tuple[str, str]]] = {}
        rows = list(
            self._db.execute(
                select(SourceSeriesCache.source_id, SourceSeriesCache.series_key, SourceSeriesCache.title)
            ).all()
        ) + list(
            self._db.execute(
                self._library._scope(
                    select(FollowedSeries.source_id, FollowedSeries.series_key, FollowedSeries.title)
                )
            ).all()
        )
        for source_id, series_key, title in rows:
            descriptor = descriptor_for_source(source_id)
            if descriptor is None or (descriptor.mature and not gate_open):
                continue
            key = match_key(title)
            if key:
                index.setdefault(key, [])
                if (source_id, series_key) not in index[key]:
                    index[key].append((source_id, series_key))
        return index

    @staticmethod
    def _available(
        media: dict[str, Any],
        index: dict[str, list[tuple[str, str]]],
        preferred: set[str],
    ) -> list[dict[str, str]]:
        seen: dict[str, str] = {}
        for name in _names(media):
            for source_id, series_key in index.get(match_key(name), []):
                seen.setdefault(source_id, series_key)
        ordered = sorted(seen.items(), key=lambda kv: (kv[0] not in preferred, kv[0]))
        out = []
        for source_id, series_key in ordered:
            descriptor = descriptor_for_source(source_id)
            out.append(
                {
                    "source_id": source_id,
                    "source_name": descriptor.name if descriptor else source_id,
                    "series_key": series_key,
                }
            )
        return out

    # --- items ------------------------------------------------------------

    @staticmethod
    def _hidden(media: dict[str, Any], gate_open: bool) -> bool:
        if gate_open:
            return False
        return bool(media.get("isAdult")) or "Hentai" in (media.get("genres") or [])

    def _items(
        self,
        medias: list[tuple[dict[str, Any], str | None]],
        *,
        gate_open: bool,
        index: dict[str, list[tuple[str, str]]],
        preferred: set[str],
    ) -> list[dict[str, Any]]:
        """WorldItems for (media, why) pairs, chapter counts filled from
        MangaUpdates where AniList has none (it leaves ongoing series blank)."""
        need_mu = [
            _names(m)[0]
            for m, _ in medias
            if _names(m) and m.get("chapters") is None
        ]
        mu = self.catalog.chapters(list(dict.fromkeys(need_mu)))
        items = []
        for media, why in medias:
            names = _names(media)
            if not names:
                continue
            title = (media.get("title") or {}).get("english") or names[0]
            extra = mu.get(names[0]) or {}
            chapters = media.get("chapters") or extra.get("latest_chapter")
            score = media.get("averageScore")
            rating = round(score / 10, 1) if isinstance(score, (int, float)) else None
            if rating is None and extra.get("rating") is not None:
                rating = round(float(extra["rating"]), 1)
            platforms = [
                {"site": link["site"], "url": link["url"]}
                for link in media.get("externalLinks") or []
                if link.get("url")
                and link.get("type") != "SOCIAL"
                and str(link.get("site", "")).casefold() not in _SOCIAL_SITES
            ][:3]
            items.append(
                {
                    "anilist_id": media.get("id"),
                    "title": title,
                    "alt_titles": [n for n in names if n != title][:4],
                    "format": _format(media),
                    "country": media.get("countryOfOrigin"),
                    "status": _STATUS.get(media.get("status") or ""),
                    "chapters": int(chapters) if chapters else None,
                    "rating": rating,
                    "rating_count_hint": None,
                    "genres": list(media.get("genres") or [])[:5],
                    "cover_url": (media.get("coverImage") or {}).get("large"),
                    "is_adult": bool(media.get("isAdult")),
                    "platforms": platforms,
                    "anilist_url": media.get("siteUrl"),
                    "available": self._available(media, index, preferred),
                    "why": why,
                }
            )
        # Colours from the AniList cover (``al:colour:{id}``), null until the
        # background fetch has run; only these visible items are enqueued.
        return attach_world_colours(self._db, items)

    def _context(self) -> tuple[dict[str, Any], set[str], set[str]]:
        taste = self._library.taste_profile()
        excluded = {match_key(t) for t in taste.get("excluded_titles", [])}
        excluded |= {match_key(t["title"]) for t in taste.get("titles", [])}
        preferred = {t.get("source_id") for t in taste.get("titles", []) if t.get("source_id")}
        return taste, excluded, preferred

    @staticmethod
    def _is_excluded(media: dict[str, Any], excluded: set[str]) -> bool:
        return any(match_key(n) in excluded for n in _names(media))

    # --- public -----------------------------------------------------------

    def not_interested(self) -> tuple[set[tuple[str, str]], set[int]]:
        """This profile's "Not interested" targets: source pairs, AniList ids."""
        return ai_feedback.not_interested(
            self._db, self._library._user_id, self._library._profile_id
        )

    def drop_not_interested(self, items: list[dict[str, Any]]) -> list[dict[str, Any]]:
        pairs, ids = self.not_interested()
        if not pairs and not ids:
            return items
        return [
            i
            for i in items
            if i.get("anilist_id") not in ids
            and not any((a["source_id"], a["series_key"]) in pairs for a in i.get("available") or [])
        ]

    def recommendations(
        self, *, seeds: int = 5, per_seed: int = 10, genre: str | None = None
    ) -> dict[str, Any]:
        self._library._require_owner()
        taste, excluded, preferred = self._context()
        gate_open = bool(taste.get("gate_open"))
        # Read ones first: taste_profile already ranks by read depth.
        picked = [t for t in taste.get("titles", []) if t.get("chapters_read")][:seeds]
        if len(picked) < seeds:
            picked += [t for t in taste.get("titles", []) if t not in picked][: seeds - len(picked)]
        if not picked:
            return {"for_you": [], "sections": [], "unavailable_reason": None}

        found = self.catalog.search([t["title"] for t in picked])
        seeds_found = [(t, found.get(t["title"])) for t in picked]
        recs = self.catalog.recommendations(
            [m["id"] for _, m in seeds_found if m and m.get("id")]
        )

        scores: dict[int, float] = {}
        media_by_id: dict[int, dict[str, Any]] = {}
        section_media: list[tuple[dict[str, Any], list[dict[str, Any]]]] = []
        for rank, (seed, media) in enumerate(seeds_found):
            if not media:
                continue
            nodes = [
                (rating, m)
                for rating, m in recs.get(media["id"], [])
                if not self._hidden(m, gate_open) and not self._is_excluded(m, excluded)
            ]
            section_media.append((seed, [m for _, m in nodes][:per_seed]))
            top = max((r for r, _ in nodes), default=1) or 1
            seed_weight = 1.0 / (1 + 0.25 * rank)
            for rating, m in nodes:
                media_by_id[m["id"]] = m
                scores[m["id"]] = scores.get(m["id"], 0.0) + seed_weight * max(rating, 1) / top

        for media_id, media in media_by_id.items():
            score = media.get("averageScore")
            if isinstance(score, (int, float)):
                scores[media_id] += 0.3 * score / 100
        ranked = sorted(media_by_id, key=lambda i: -scores[i])[:FOR_YOU_LIMIT]

        index = self._availability_index(gate_open)
        wanted = [media_by_id[i] for i in ranked]
        for _, medias in section_media:
            wanted += medias
        unique = list({m["id"]: m for m in wanted}.values())
        built = {
            item["anilist_id"]: item
            for item in self._items(
                [(m, None) for m in unique], gate_open=gate_open, index=index, preferred=preferred
            )
        }
        want = genre.strip().casefold() if genre else None

        def keep(items: list[dict[str, Any]]) -> list[dict[str, Any]]:
            items = self.drop_not_interested(items)
            if want:
                items = [
                    i for i in items if want in {g.casefold() for g in i.get("genres") or []}
                ]
            return items

        sections = [
            {
                "because": {
                    "title": seed["title"],
                    "source_id": seed.get("source_id"),
                    "series_key": seed.get("series_key"),
                },
                "items": keep([built[m["id"]] for m in medias if m["id"] in built]),
            }
            for seed, medias in section_media
            if medias
        ]
        return {
            "for_you": keep([built[i] for i in ranked if i in built]),
            "sections": [sec for sec in sections if sec["items"]],
            "unavailable_reason": (
                "The worldwide catalog could not be reached; showing what was cached."
                if self.catalog.failed
                else None
            ),
        }

    def verify(
        self, entries: list[tuple[str, str]], *, gate_open: bool, limit: int
    ) -> tuple[list[dict[str, Any]], int]:
        """Titles a model named -> WorldItems for the ones AniList confirms.
        Returns (items, dropped)."""
        taste, excluded, preferred = self._context()
        found = self.catalog.search([title for title, _ in entries])
        medias: list[tuple[dict[str, Any], str | None]] = []
        dropped = 0
        seen: set[int] = set()
        for title, why in entries:
            media = found.get(title)
            if (
                media is None
                or media["id"] in seen
                or self._hidden(media, gate_open)
                or self._is_excluded(media, excluded)
            ):
                dropped += 1
                continue
            seen.add(media["id"])
            medias.append((media, why or None))
            if len(medias) >= limit:
                break
        index = self._availability_index(gate_open)
        return (
            self._items(medias, gate_open=gate_open, index=index, preferred=preferred),
            dropped,
        )


def get_world_recs(
    db: Annotated[Session, Depends(get_db)],
    library: Annotated[FollowedSeriesService, Depends(get_followed_series_service)],
) -> WorldRecs:
    return WorldRecs(db, library)
