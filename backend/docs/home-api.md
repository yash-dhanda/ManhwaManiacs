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

# AI endpoints (backend/05)

All are profile-scoped, additive, and gated when served: a series the profile's
18+ gate hides is a `404 series_not_found` (a hidden source `404 source_not_found`)
before any AI call, cache read or AniList call. Per-series AI answers are stored
once for everyone in `ai_result_cache` (never with a gate applied) and filtered
on the way out.

## `GET /ai/similar`

Query: `source` + `series`, **or** `anilist_id` (exactly one form, else 422);
`fallback=genres` (series form only). Rate limit: the sources bucket.

```json
{"items": [WorldItem + {"why": "...", "basis": "ai"}], "available": true, "reason": "ok",
 "basis": "ai", "generated_at": "2026-09-29T15:34:12Z"}
```

- Series form: up to 10 items, available-on-your-sources first. `anilist_id` form
  (onboarding step 5): exactly the first 3.
- `why` lines come from one desk call per seed, cached 7 days. If the desk has
  not finished within 25 s the items come back with `why: null` (`available: true`)
  and the next request is served from the cache.
- Desk unavailable and nothing cached: series form answers `available: false`,
  `reason` (`not_configured`, `budget_exhausted`, `rate_limited`, `ai_failed`),
  `basis: "genres"` and up to 10 genre-fallback items (none when fewer than 3);
  `anilist_id` form answers `items: []`.
- `fallback=genres` (or a seed AniList cannot match): no AI, no AniList; rows of the
  profile's pinned and followed sources sharing at least 2 genres with the seed,
  WorldItem-shaped with `anilist_id: null`, `basis: "genres"`, `why: null`.
- Never returns adult (`is_adult`) titles, or titles only a mature source carries,
  to a gated profile, followed or read series, "Not interested" targets or the seed.

## `GET /ai/tags?source=&series=`

`{"tags": [<=5], "available": true, "reason": "ok", "generated_at": "..."}`.
Lower-case labels of 1 to 24 characters, cached 30 days (8 stored). The profile's
rejected tags and tags it already owns on the series are removed. Desk closed and
nothing cached: `{"tags": [], "available": false, "reason": "<reason>", "generated_at": null}`.

## `POST /ai/feedback` (needs `X-Profile-Id`) -> 204

Body `{signal, anilist_id?, source_id?, series_key?, tag?}`.

| signal | needs | effect |
|---|---|---|
| `not_interested` | `anilist_id` or `source_id`+`series_key` | dropped from `/home`, `/ai/similar`, `GET /library/world/recommendations` and the onboarding seeds for this profile |
| `undo` | same target | deletes the newest `not_interested` row; no row is still 204 |
| `liked_pick` | `anilist_id` or `source_id`+`series_key` | joins the taste block of the home editorial and of asks with `use_taste` (titles only) |
| `tag_rejected` | `source_id`, `series_key`, `tag` (1-64) | `/ai/tags` never suggests it for that series again |
| `clear` | nothing | deletes every `not_interested` row of the profile |

Anything else, or a missing field: 422 `feedback_invalid` (or the validation 422).
No `X-Profile-Id` on an account with profiles: 400 `profile_required`.

## `GET /ai/recap/availability?source=&series=&to=&scope=series|chapter`

The backend/04 availability object (`available`, `reason`, `range`, `est_seconds`,
`cached`); no AI call. `scope` defaults to `series`.

## `GET /ai/recap?source=&series=&to=&shape=prose|deck&scope=series|chapter`

`shape` defaults to `prose`, `scope` to `series`; `prose` + `chapter` is 422.

**No stream.** When no recap can be written the answer is plain JSON 200
`{"available": false, "reason": "..."}` (`not_configured`, `budget_exhausted`,
`rate_limited`, `no_dialogue`, `first_chapter`). `rate_limited` is also the answer
to a fourth cache miss within 60 s for one account and carries `Retry-After`.

**Stream.** Headers `Content-Type: text/event-stream; charset=utf-8`,
`Cache-Control: no-cache, no-transform`, `X-Accel-Buffering: no`. Every event is
`event: <name>\ndata: <one-line JSON>\n\n`; `: keep-alive` comment lines are sent
every 15 s while the AI works. A cached recap streams at once and costs nothing;
a miss costs one ask on the reader's ledger. The writer runs to the end if the
client leaves, so the next open is cached (180 days, per series, range, shape and
scope). Only chapters this profile completed before `to` are ever sent to the AI.

Prose (Cinematic): `meta` `{range: {from_key, to_key, from_number, to_number},
cast: [{name, note}], sourced_from: "ocr"|"text"}`, then `delta` `{text}` (at most
8 words each; paragraphs separated by `\n\n`; the texts concatenate to the recap),
then `done` `{covered_through, model, generated_at}`.

Deck (Glass): `phase` `{phase: "writing"}`; `section` `{kind, title}` for every
section first (series: `left_off` "Where you left off", `happened` "What happened",
`cast` "Who's who", `threads` "Open threads"; chapter: `last_time` "Last time");
`delta` `{kind, text}` per section in that order (bullets and questions end with
`\n`; cast lines are `Name: note\n`); `done` `{range: [from, to], covered_through,
cast, sourced_from, model, generated_at, available: true, reason: "ok"}`.

Failure: one `event: error` `{code, message}` with `code` one of `not_configured`,
`budget_exhausted`, `ai_failed`, `rate_limited` (which adds `retry_after: 30`);
nothing is cached.

## Taste and onboarding

`PUT /profiles/{id}/taste` (another account's profile is 404 `profile_not_found`).
Every field optional, partial bodies merge: `step` 1 to 7 or `"done"` (written to
`onboarding_step`); `formats` (subset of manhwa, manga, manhua, novel) and `styles`
(the 11-value union `painted, cel, screentone, manhua-3d, sketch, retro, pastel,
noir, chibi, watercolour, dark-realism`) replace; `genres` `{name: -1|0|1|2}` merge
key by key, `0` deletes, at most 80 keys after the merge; `seeds` (at most 50 of
`{anilist_id}` or `{source_id, series_key}`) replace. `GET /profiles/{id}/taste`
returns the stored answers. Both return
`{step, formats, genres, styles, seeds}`.

`GET /onboarding/catalog?formats=&genres=&styles=` (comma-separated, unknown
formats or styles are 422; sources rate-limit bucket):
`{formats: [{format, covers: [url x3]}], genres: [{name, weight}], seeds: [WorldItem x24],
unavailable_reason}`. Genres are the installed browsable sources' declared genres
(mature sources and mature labels left out while gated), weight = sources offering
the label, at most 40. Seeds are AniList trending filtered by liked genres, gated,
available-first. AniList down: `covers` and `seeds` empty, `genres` still served,
`unavailable_reason` set. Trending answers are cached 24 hours.

`POST /library/taste/seed {formats, genres, styles}` (needs `X-Profile-Id`):
`{items: [SourceSeries x<=24], basis: "sources"}` from the profile's sources'
cached rows (no network, no AI), most liked-genre overlap first.

## Additions to existing endpoints

- `GET /library/world/recommendations?genre=` keeps only items with that genre
  (case-insensitive); "Not interested" targets are dropped either way.
- `POST /library/suggest` and `POST /library/world/suggest` gain `use_taste`
  (default false: the prompt is byte-identical); `POST /library/suggest` also
  gains `content_kind` (`manga` | `novel`).
- `/home`: the `genres` section for a profile with no follows lists its taste
  genres, loved first, as `{genre, weight}`; the editorial input carries the taste
  block.
