# GET /home

One server-composed feed for both skins (Cinematic "Tonight", Glass Home). The backend picks
tonight's cover story, writes its headline and deck, and builds every section; clients only
render. Requires a session; profile-scoped through `X-Profile-Id`; the 18+ gate is applied when
serving.

## Query

| Parameter | Rule |
|---|---|
| `content_kind` | `manga` (default) or `novel`; anything else is 422 |
| `tz_offset_minutes` | required int, -720 to 840 (web: `-new Date().getTimezoneOffset()`, Flutter: `DateTime.now().timeZoneOffset.inMinutes`); 422 when missing or outside |
| `refresh` | `0` (default) or `1`; `1` skips the composed-cache read and writes a fresh entry (Glass pull to refresh) |

## Response

Every field is always present.

| Field | Meaning |
|---|---|
| `issue_no` | whole local days since the profile's first reading session, plus 1 (1 with no session) |
| `generated_at` | ISO UTC of the compose; identical for cached responses |
| `content_kind` | echo |
| `headline`, `deck` | the cover story's strings, sent whole (the client types `headline`, never streams it) |
| `kicker_title` | the series title when the headline overflowed 60 graphemes and dropped it, else null |
| `streak` | the one streak object of `GET /library/statistics` for this `tz_offset_minutes`: `current_days`, `longest_days`, `at_risk`, `last_active_date`, `milestones_seen` |
| `cover` | see below, or null |
| `also` | 2 or 3 `{kind, source_id, series_key, title, headline, deck, ambient}`; `[]` below two |
| `sections` | ordered list, empty sections omitted |
| `ai` | `{available, reason}` of the desk: `ok`, `not_configured`, `budget_exhausted`, `rate_limited`, `ai_failed` |

### cover

`{reason, source_id, series_key, chapter_key, chapter_number, last_page, page_count, title,
cover_url, content_kind, ambient, palette, new_count, paused_days, recap, why, world}`.
`reason` is the first rule that yields a candidate: `new_chapters`, `in_progress` (read in the
last 21 days, unfinished), `paused` (7 to 60 days, recap available), `first_pick` (follows but no
history in this kind), `ai_pick` (history but nothing reading; from world recs, `world` holds the
WorldItem), `caught_up`, `popular`. `cover` is null when nothing can be served; the headline is
then "Your first issue starts here.".

Streak at risk (`streak.at_risk` and `current_days >= 2`) replaces the headline and deck of every
reason except `popular` and `caught_up`, keeping the cover series.

`recap` is the availability object:

```json
{"available": true, "reason": "ok",
 "range": {"from_key": "c131", "to_key": "c142", "from_number": 131, "to_number": 142},
 "est_seconds": 104, "cached": false}
```

`reason` is `ok`, `first_chapter`, `no_dialogue`, `not_configured` or `budget_exhausted`. It appears
on the cover, on `continue` and `where_were_we` items and on every row of
`GET /library/continue-reading`. It never calls the AI and costs nothing.

### sections

Order: `first_picks`, `continue`, `new_this_week`, `almost_there`, `where_were_we`, `sent_to_you`,
`picked`, `because` (one per seed), `circle`, `circle_top`, `popular`, `sources`, `genres`,
`numbers`. Each is `{type, title, seed, note, fallback, items, state, generated_at}`;
`state` is `ready`, `stale` or `unavailable`.

| type | items |
|---|---|
| `first_picks` | `{kind: "source", item: SourceSeries, why: null}` (only when the cover reason is `first_pick`) |
| `continue` | the continue-reading row plus `recap`, `ambient`, `palette`, `nudge` (`new`, `almost_done`, `paused`, null), `new_count`, `paused_days` |
| `new_this_week` | the library row with `read_state`, `ambient`, `palette` (follows whose update check found chapters in the last 7 days, notifications on or off) |
| `almost_there` | library row plus `chapters_left` (1 to 3) |
| `where_were_we` | library row plus `recap` (last read 21 to 120 days ago) |
| `picked` | `{kind: "world", item: WorldItem, why}`; when the AI desk is unavailable and no editorial of the last 7 days exists it becomes "From your shelf": `fallback: "shelf"`, `state: "unavailable"`, `note` = the `ai.reason`, items are favourites then plan-to-read follows as `{kind: "source", ...}` |
| `because` | `{kind: "world", item, why}` with `seed: {title, source_id, series_key}` |
| `popular` | `{kind: "source", item: SourceSeries, why: null}`; only for a profile that follows nothing or has no history |
| `sources` | pin row (`source_id`, `name`, `icon_url`, `mature`, `available`) plus `latest_covers` (up to 3) and `suggested`; with no pins of the kind these are the 3 healthiest non-18+ sources with `suggested: true` |
| `genres` | `{genre, weight}` |
| `numbers` | one item `{streak, chapters_week, seconds_week}` |

`picked` and `because` carry `state: "stale"` and the old editorial's `generated_at` when today's
editorial is missing and one from the last 7 days exists.

## Cache and AI

The composed payload is cached in process per `(profile, 18+ gate, content_kind, tz offset, local
hour)` for 10 minutes; a gate change reads a different entry. `refresh=1` bypasses it. The AI only
writes the cover `deck` and the `why` lines, at most once per profile, gate, content kind and
local day, in a background job on its own "desk" ledger (100 requests a day server-wide), stored in
`ai_result_cache`. `/home` never waits for it: the first compose after a miss uses the fallbacks
and the job drops the profile's cache entries when it finishes.

## Live sections

`services.home_service.LIVE_SECTION_BUILDERS` is a list of `(service, payload) -> [section]`
callables run on every request after the cache is read and inserted at their place in the order
above. The Circle steps (`backend/08`, `backend/09`) append here so their sections are computed
per request and never cached.

## Examples

Returning reader (trimmed):

```json
{"issue_no": 184, "generated_at": "2026-09-29T15:34:12Z", "content_kind": "manga",
 "headline": "Tonight: chapter 143 of Omniscient Reader.", "deck": "A fine night for it.",
 "kicker_title": null,
 "streak": {"current_days": 12, "longest_days": 30, "at_risk": false,
            "last_active_date": "2026-09-29", "milestones_seen": [7]},
 "cover": {"reason": "new_chapters", "source_id": "mangadex", "series_key": "or-1",
           "chapter_key": "c143", "chapter_number": 143, "last_page": 1, "page_count": 0,
           "title": "Omniscient Reader", "cover_url": "/sources/mangadex/series/or-1/cover",
           "content_kind": "manga", "ambient": null, "palette": null, "new_count": 2,
           "paused_days": 0, "recap": {"available": true, "reason": "ok", "range": {"from_key": "c131",
           "to_key": "c142", "from_number": 131, "to_number": 142}, "est_seconds": 104, "cached": false},
           "why": null, "world": null},
 "also": [{"kind": "almost_there", "source_id": "mangadex", "series_key": "tog", "title": "Tower of God",
           "headline": "Two chapters left in Tower of God", "deck": null, "ambient": null}, "..."],
 "sections": [{"type": "continue", "title": "Continue reading", "seed": null, "note": null,
               "fallback": null, "items": ["..."], "state": "ready", "generated_at": "2026-09-29T15:34:12Z"}],
 "ai": {"available": true, "reason": "ok"}}
```

New profile (no pins, no follows):

```json
{"issue_no": 1, "content_kind": "manga", "headline": "Your first issue starts here.",
 "deck": "Follow three series and this page fills itself in.", "kicker_title": null,
 "streak": {"current_days": 0, "longest_days": 0, "at_risk": false, "last_active_date": null,
            "milestones_seen": []},
 "cover": {"reason": "popular", "title": "Top of Alpha Scans", "...": "..."}, "also": [],
 "sections": [{"type": "popular", "title": "Popular on your sources", "state": "ready", "items": ["..."]},
              {"type": "sources", "title": "Sources", "state": "ready",
               "items": [{"source_id": "mangadex", "name": "MangaDex", "suggested": true, "latest_covers": []}]}],
 "ai": {"available": false, "reason": "not_configured"}}
```

## Fields beyond cinematic §9.1.7

Top level `generated_at`, `content_kind`, `kicker_title`; `cover.title`, `cover_url`,
`chapter_number`, `last_page`, `page_count`, `new_count`, `paused_days`, `why`, `world`, `palette`;
`section.fallback`, `section.seed`; `sources[].suggested`. `backend/05`, `08` and `09` append their
own sections.
