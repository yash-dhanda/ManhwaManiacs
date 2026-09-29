"""Seed the dev stack with a demo account for redesign proof screenshots.

Talks to a running dev backend over HTTP only (the real API, no app imports).
Refuses anything but loopback on the dev port, and refuses an already-seeded
database. Run through ``dev_stack.sh seed`` / ``dev_stack.sh reset``.
"""

from __future__ import annotations

import argparse
import os
import sys
from datetime import datetime, time, timedelta, timezone
from urllib.parse import quote, urlsplit

import httpx

USERNAME = "demo"
PASSWORD = "maniacs-demo-2026"
MANGA_SOURCES = ["mangadex", "weebcentral", "mangapill", "webtoons"]
NOVEL_SOURCES = ["standardebooks", "gutenberg", "royalroad"]
# Copy of core.content_rating.MATURE_CONTENT_RATINGS (this script imports no app code).
MATURE = frozenset(
    {"pornographic", "erotica", "smut", "hentai", "adult", "mature", "nsfw", "18+", "r18", "r-18"}
)
TIMEOUT = 15.0


def log(msg: str) -> None:
    print(msg, file=sys.stderr, flush=True)


def check_base(base: str) -> None:
    allowed_port = int(os.environ.get("MM_DEV_PORT", "8010"))
    parts = urlsplit(base)
    if parts.hostname not in {"127.0.0.1", "localhost"} or parts.port != allowed_port:
        sys.exit(f"refusing: --base must be http://127.0.0.1:{allowed_port} or localhost:{allowed_port}")


def is_mature(item: dict) -> bool:
    values = [item.get("content_rating") or ""] + list(item.get("genres") or [])
    return any(str(v).strip().lower() in MATURE for v in values)


def ok(res: httpx.Response) -> dict | list:
    res.raise_for_status()
    return res.json() if res.content else {}


class Api:
    def __init__(self, base: str) -> None:
        self.http = httpx.Client(base_url=base, timeout=TIMEOUT)

    def call(self, method: str, path: str, profile: int | None = None, **kw):
        headers = {"X-Profile-Id": str(profile)} if profile is not None else {}
        return ok(self.http.request(method, path, headers=headers, **kw))


def chapters_in_order(api: Api, source: str, key: str, pid: int) -> list[dict]:
    chapters = api.call("GET", f"/sources/{source}/series/{quote(key, safe='')}/chapters", pid)
    return sorted(chapters, key=lambda c: (c.get("number") is None, c.get("number") or 0))


def follow_from(api: Api, sources: list[str], pid: int, per_source: int, want_sources: int):
    """Follow ``per_source`` non-18+ items from the first ``want_sources`` sources that answer."""
    follows: list[tuple[str, str]] = []
    errors: dict[str, str] = {}
    done = 0
    for source in sources:
        if done >= want_sources:
            break
        try:
            listing = api.call("GET", f"/sources/{source}/series", pid, params={"page": 1})
            items = [i for i in listing.get("items") or [] if not is_mature(i)][:per_source]
            if not items:
                raise RuntimeError("no non-18+ items on page 1")
            for item in items:
                api.call("POST", "/library/follow", pid,
                         json={"source_id": source, "series_key": item["id"]})
                follows.append((source, item["id"]))
            done += 1
        except Exception as exc:  # noqa: BLE001 - a dead source is skipped, not fatal
            errors[source] = f"{type(exc).__name__}: {exc}"
            log(f"skipped {source}: {errors[source]}")
    return follows, errors


def at_21(days_ago: int) -> str:
    day = datetime.now(timezone.utc).date() - timedelta(days=days_ago)
    return datetime.combine(day, time(21, 0), tzinfo=timezone.utc).isoformat()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base", required=True)
    base = parser.parse_args().base
    check_base(base)
    api = Api(base)

    if not api.call("GET", "/auth/bootstrap-status")["needs_bootstrap"]:
        log("already seeded; run dev_stack.sh reset")
        return 1

    api.call("POST", "/auth/register", json={"username": USERNAME, "password": PASSWORD, "remember": True})
    api.call("PUT", "/updates/settings", json={"enabled": False, "check_on_startup": False})

    riya = api.call("POST", "/profiles", json={
        "name": "Riya", "mood": "fantasy", "mature_content_enabled": True, "sort_order": 0})["id"]
    aarav = api.call("POST", "/profiles", json={
        "name": "Aarav", "mood": "action", "mature_content_enabled": False, "sort_order": 1})["id"]

    manga, manga_errors = follow_from(api, MANGA_SOURCES, riya, per_source=3, want_sources=2)
    if len(manga) < 4:
        log(f"only {len(manga)} manga follows; source errors: {manga_errors}")
        return 1
    novels, _ = follow_from(api, NOVEL_SOURCES, riya, per_source=2, want_sources=1)
    for source, key in manga[:3]:
        api.call("POST", "/library/follow", aarav, json={"source_id": source, "series_key": key})

    # Riya: one chapter a day for the last 6 days (a live streak), walking her
    # first 4 follows round-robin through their first 3 chapters each.
    firsts = {s: chapters_in_order(api, s[0], s[1], riya)[:3] for s in manga[:4]}
    progress = {riya: 0, aarav: 0}
    for i in range(6):
        source, key = manga[i % 4]
        chapters = firsts[(source, key)]
        chapter = chapters[min(i // 4, len(chapters) - 1)]
        # ponytail: a chapter with no page_count gets 20, enough for page-4 progress.
        pages = chapter.get("page_count") or 20
        newest = i == 5
        api.call("POST", "/reader/progress", riya, json={
            "source_id": source, "series_key": key, "chapter_key": chapter["id"],
            "chapter_number": chapter.get("number"), "page_count": pages,
            "last_page": 4 if newest else pages, "is_completed": not newest,
            "last_read_at": at_21(5 - i), "time_spent_seconds": 300 + 120 * i,
        })
        progress[riya] += 1
    # Aarav: 2 completed chapters on one series 3 days ago (a broken streak).
    source, key = manga[0]
    for chapter in firsts[(source, key)][:2]:
        pages = chapter.get("page_count") or 20
        api.call("POST", "/reader/progress", aarav, json={
            "source_id": source, "series_key": key, "chapter_key": chapter["id"],
            "chapter_number": chapter.get("number"), "page_count": pages,
            "last_page": pages, "is_completed": True,
            "last_read_at": at_21(3), "time_spent_seconds": 420,
        })
        progress[aarav] += 1

    bookmarks = 0
    first = firsts[manga[0]][0]
    for page in (3, 7):
        api.call("POST", "/reader/bookmark", riya, json={
            "source_id": manga[0][0], "series_key": manga[0][1], "chapter_key": first["id"],
            "chapter_number": first.get("number"), "media_type": "manga", "anchor_index": page})
        bookmarks += 1
    if novels:
        n_source, n_key = novels[0]
        n_first = chapters_in_order(api, n_source, n_key, riya)[0]
        api.call("POST", "/reader/bookmark", riya, json={
            "source_id": n_source, "series_key": n_key, "chapter_key": n_first["id"],
            "chapter_number": n_first.get("number"), "media_type": "novel", "anchor_index": 5})
        bookmarks += 1

    collection = api.call("POST", "/library/collections", riya, json={
        "name": "Weekend binge", "description": "Seeded for screenshots"})
    for source, key in manga[:3]:
        api.call("POST", f"/library/collections/{collection['id']}/series", riya,
                 json={"source_id": source, "series_key": key})

    per_source: dict[str, int] = {}
    for source, _key in manga + novels:
        per_source[source] = per_source.get(source, 0) + 1
    print(f"account   {USERNAME} / {PASSWORD}")
    print(f"sources   {', '.join(f'{s}={n}' for s, n in per_source.items())}")
    print(f"{'profile':<8} {'follows':>7} {'progress':>8} {'bookmarks':>9} {'collections':>11}")
    print(f"{'Riya':<8} {len(manga) + len(novels):>7} {progress[riya]:>8} {bookmarks:>9} {1:>11}")
    print(f"{'Aarav':<8} {3:>7} {progress[aarav]:>8} {0:>9} {0:>11}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
