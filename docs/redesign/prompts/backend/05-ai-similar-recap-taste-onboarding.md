# Backend 05: similar, recaps, feedback, taste and onboarding catalogue (new feature 1, part 2)

## Goal

This step finishes the server half of new feature 1 (the AI home and recommendations) for both skins. It ships "More like this" (`GET /ai/similar`, with the server-side genre fallback Glass needs and the 3-item `anilist_id` form onboarding needs), the "Previously on" recap endpoints (`GET /ai/recap/availability` on top of the availability service `backend/04` wrote, and `GET /ai/recap` as a Server-Sent Events stream in Cinematic's prose shape and Glass's deck shape, series or chapter scope), suggested tags (`GET /ai/tags`), feedback on AI picks (`POST /ai/feedback`: not interested, undo, liked pick, rejected tag, clear), the profile's taste (`PUT` and `GET /profiles/{id}/taste`, which also drives onboarding resume), the onboarding catalogue (`GET /onboarding/catalog`), a sources-only seed fallback (`POST /library/taste/seed`), the `genre=` filter on world recommendations, and Glass's `use_taste` and `content_kind` on the two suggest calls. Every per-series AI cache is stored ungated and gated on serve, every call is profile-scoped, the AI is reached only through the existing DeepSeek client on the ledgers `backend/04` set up, and all of it is additive.

## Read first

1. `docs/redesign/prompts-plan.json`, the entry whose `path` is `docs/redesign/prompts/backend/05-ai-similar-recap-taste-onboarding.md` (binding scope).
2. `docs/redesign/cinematic/DESIGN.md`:
   - §8.7 Onboarding (the **18+ gate here**, **Resume** and **Backend.** paragraphs, the step table's Data column, the **States** paragraph: catalog unreachable, AI unavailable, offline).
   - §9.1.3 Picks (the World card `Not for me` and `More like this` behaviour and the feedback signals), §9.1.4 More like this and Because you read, §9.1.5 "Previously on" (the whole section: layout, cast list, footnote, availability and range, entry behaviours, states), §9.1.6 fallbacks, §9.1.7 the endpoint table (rows `GET /ai/similar`, `GET /ai/recap/availability`, `GET /ai/recap` with its **No stream** and **Stream headers** rules, `POST /ai/feedback`, `PUT /profiles/{id}/taste`, `GET /ai/tags`), §9.1.8 the state vocabulary.
   - §8.17 the feature page aside (suggested tags line).
   - §15.5 rows for these endpoints and `Per-profile composed caches`.
3. `docs/redesign/glass/DESIGN.md`: §8.7 Onboarding (steps 4 to 6: genre weights 1, 2, 0, −1; the art-style ids; seeds; **Storage**; **States**), §9.1.1 (Not interested with Undo, liked pick), §9.1.2 For you and Ask (`use_taste`, `content_kind`, `?genre=`), §9.1.3 recaps (the deck's four sections, the chapter recap, the footer with `model`, `range` and `covered_through`, leaving during generation, every state), §9.1.4 More like this (`fallback=genres`), §9.1.5 reasons, §9.1.6 backend used, §8.25.16 (Clear "Not interested"), §15.5 and §15.6 (the recap setting lives on the device; `styles` is the 11-value union; `step` 1 to 7; recap stream shapes).
4. `docs/redesign/stack-decision.md` §2.6.
5. `docs/redesign/inventory/00-decisions.md` (new feature 1), `docs/redesign/inventory/capabilities.md` §1, §9, §16.1, §16.2, §19 (novel text cache), §20 (OCR).
6. `docs/redesign/00-baseline.md` and `docs/redesign/proof/backend-00/pytest-baseline.txt`.
7. `docs/redesign/prompts/backend/04-ai-home-composition.md` and `backend/docs/home-api.md` (what `backend/04` built: `services/ai_desk.py`, `services/recap_service.py`, `services/home_service.py`, the `ai_result_cache` table and its `cache_key`/`cache_get`/`cache_put` helpers, `run_in_background`, `desk_availability`, `HomeService._excluded`, `invalidate_profile`).
8. `docs/redesign/prompts/backend/02-library-series-ocr-extensions.md` (the `GET /series/enrichment` cache this step must also gate on serve).
9. Code: `backend/services/suggestion_service.py` (`SuggestionService.availability`, `_complete`, `suggest`, `world_suggest`, `_user_message`, `_world_message`, `shelf`, `_excluded_keys`), `backend/services/world_recs.py` (`WorldCatalog._lookup`, `_anilist`, `search`, `recommendations`, `WorldRecs._items`, `_availability_index`, `_hidden`), `backend/services/source_cache_service.py` (`_series_key_hides`, `_rating_hides`, `get_browse_page`), `backend/services/browse_service.py` (`ensure_visible`, `list_genres`), `backend/core/content_rating.py` (`rating_from_genres`, `hidden_by_gate`, the mature genre set), `backend/services/ocr_ingest_service.py` (`coverage`, `_may_read`), `backend/database/models.py` (`ChapterOcr.page_texts`/`full_text`, `NovelChapterCache.paragraphs`, `NovelSeriesCast`), `backend/routes/profiles.py` and `backend/services/profile_service.py` (`_get_owned`, `serialize`), `backend/routes/library.py`, `backend/tests/test_world_recs.py` (how AniList is faked through `_transport`), `backend/tests/test_suggestion_service.py` (how `complete_json` and the ledgers are faked).

## Track rule (applies to every `backend/*` prompt)

- Work only in `backend/` (never `backend/connectors/`) plus `docs/redesign/proof/backend-05/`. This step touches no `ops/`, `frontend/` or `mobile/` file.
- Stage only the paths you changed, by name. Never `git add -A` or `git add .`.
- Alembic revisions continue after the newest file in `backend/alembic/versions/`; ids at most 32 characters.
- Every endpoint is profile-scoped. The 18+ gate is applied when **serving**, never when storing (shared caches too).
- Changes are additive: no field is renamed or removed; existing responses only gain fields; a new request parameter's default keeps today's behaviour exactly.
- Tests run with `backend/.venv/bin/python -m pytest -q --no-header` from `backend/`.

## Preconditions (check before any edit; stop and report if one fails)

1. Branch is `feat/vps-slim-source-native`.
2. `backend/04` landed: `grep -rn '"/home"' backend/routes` finds the route, and `backend/services/ai_desk.py` and `backend/services/recap_service.py` exist.
3. `backend/02` landed: `grep -rn "enrichment" backend/routes` finds `GET /series/enrichment`.
4. `grep -rn '"/ai/' backend/routes` finds nothing (this step has not run before).
5. `free -m`: `available` is 1024 or more.

## Skills

- `superpowers:writing-plans` first: the plan goes to `docs/redesign/proof/backend-05/plan.md`.
- `superpowers:executing-plans` to run it inline (one migration, shared services: no subagent fan-out).
- `superpowers:test-driven-development`: every endpoint's failing test first.
- `superpowers:verification-before-completion` before claiming done.
- `impeccable`, `taste-skill:taste-skill` and `frontend-design` are UI skills and are not used: this step has no UI. The only user-visible strings here are the recap section titles and the AI-written text; copy the titles exactly from glass §9.1.3.

## Scope, item by item

### A. Baseline

`cd backend && free -m && timeout 1800 .venv/bin/python -m pytest -q --no-header 2>&1 | tail -25 > ../docs/redesign/proof/backend-05/pytest-before.txt`; list pre-existing failures under `PRE-EXISTING FAILURES:` and leave them alone.

### B. Migration and models (one revision after the current head, for example `0023_ai_taste_feedback`)

1. `reading_profiles.taste` (`Text`, nullable): the profile's taste as JSON `{"formats": [...], "genres": {"name": weight}, "styles": [...], "seeds": [...]}`. It follows the profile to every device (glass §8.7 **Storage**); `onboarding_step` (from `backend/00`) keeps the step.
2. Table `ai_feedback` (per profile, owned data, not a cache):
   - `id` Integer PK; `user_id` Integer not null FK `users.id`; `profile_id` Integer not null; composite `ForeignKeyConstraint(["user_id", "profile_id"], ["reading_profiles.user_id", "reading_profiles.id"], ondelete="CASCADE", name="fk_ai_feedback_scope")` (the house pattern of `followed_series`);
   - `signal` `String(16)` not null (`not_interested`, `liked_pick`, `tag_rejected`); `anilist_id` Integer nullable; `source_id` `String(64)` nullable; `series_key` `String(512)` nullable; `tag` `String(64)` nullable; `created_at` DateTime not null;
   - index `ix_ai_feedback_scope (user_id, profile_id, signal)`.
3. ORM classes matching exactly (`ReadingProfile.taste`, `AiFeedback`); `tests/test_migrations_alembic.py` gains the revision in `_HEAD`/`_REVISIONS` and `"ai_feedback"` in `_EXPECTED_TABLES`. `ai_feedback` is not a cache table (do not add it to `CACHE_TABLES`).

### C. Gating one series (used by every endpoint below)

If `backend/02` already added a helper for `/series/enrichment` that gates a single series (`grep -rn "def .*visible" backend/services`), reuse it. Otherwise create `backend/services/series_gate.py` with `require_series_visible(browse, cache, library, source_id, series_key) -> None`: `browse.ensure_visible(source_id)` (404 `source_not_found` for a gated or unknown source), then, if this profile follows the series, the follow's own resolved rating decides (the rule `FollowedSeriesService._visible` applies, which honours `mature_override`); otherwise `cache._series_key_hides(source_id, series_key)`; hidden raises `AppError("Series not found.", code="series_not_found", status_code=404)`. Denial is always a 404, never a 403, and it happens before any AI call, any cache read and any AniList call. `/series/enrichment` keeps its own gate and its `backend/02` contract; section K adds a test that it never leaks a stored row to a gated profile.

### D. `GET /ai/similar` (`backend/routes/ai.py`, new, prefix `/ai`; logic in `backend/services/ai_series_service.py`, new)

Query: `source` + `series`, **or** `anilist_id` (exactly one form; both or neither is 422); `fallback` optional, only `genres`. Rate limit: `@limiter.limit(sources_limit)` (it may call AniList). Response:

```json
{"items": [WorldItem & {"why": "Same regression premise, darker art.", "basis": "ai"}], "available": true, "reason": "ok", "basis": "ai", "generated_at": "2026-09-29T15:34:12Z"}
```

1. **Seed** (`source` + `series`): gate (C); the title and genres come from the profile's followed row or the `source_series_cache` row, never from an upstream fetch (neither exists → 404 `series_not_found`). The AniList match is `WorldCatalog.search([title])`; candidates are `WorldCatalog.recommendations([media_id])` (both cached 7 days in `world_catalog_cache`). **Seed** (`anilist_id`): the candidates are `WorldCatalog.recommendations([anilist_id])` directly.
2. **Candidates** are turned into WorldItems with `WorldRecs._items` (availability index, formats, chapter counts), then filtered on serve: `is_adult` true, or every `available[]` source mature, is dropped while the gate is closed; the seed itself, followed series, series with progress and "Not interested" targets (E) are dropped. `source`+`series`: up to 10, available items first; `anilist_id`: exactly the first 3 (onboarding step 5 inserts 3).
3. **The `why` lines** come from one desk call per seed, cached 7 days: `cache_key("similar", source_id, series_key)` or `cache_key("similar", "anilist", str(anilist_id))`, `kind="similar"`, payload `{"why": {"<anilist_id>": "…"}}`, stored for all candidates before the gate filter (a cache row is never gated when stored). On a miss, when `desk_availability()` is `ok`, start the job with `ai_desk.run_and_wait(key, job, timeout_s=25)` (add this to `ai_desk.py`: the same single-flight registry as `run_in_background`, keeping a `threading.Event` per running key; it returns `True` when the job finished inside the timeout). Finished: answer with the lines. Not finished in 25 s: answer the items with `why: null`, `basis: "ai"`, `available: true`, `reason: "ok"`; the job keeps running and the next request is served from the cache. The desk prompt gets the seed title and genres and each candidate's `anilist_id`, title, format and genres, never descriptions; each line is at most 90 characters; unknown ids are dropped; a malformed answer is `ai_failed`.
4. **When the desk is unavailable** (`not_configured`, `budget_exhausted`, `rate_limited`, `ai_failed`) and no cached lines exist: `source`+`series` answers `available: false`, the reason, `basis: "genres"` and the genre fallback items (5), so both skins can show the `SAME GENRES` / "Same genres" rail beside the notice (cinematic §9.1.4 and §9.1.8, glass §9.1.4); `anilist_id` answers `available: false`, the reason and `items: []` (onboarding inserts nothing, cinematic §8.7 and glass §8.7 States).
5. **The genre fallback** (`fallback=genres`, or case 4, or a `source`+`series` seed AniList cannot match): no AI and no AniList. "The profile's sources" are its pinned sources plus the sources of its followed series, of the seed's content kind. From `source_series_cache` rows on those sources: rows sharing at least 2 genres with the seed (case-insensitive, stripped), not the seed, not followed, not excluded, visible on serve (mature sources dropped while the gate is closed, `_rating_hides` on each row); ordered by the number of shared genres (descending), then `fetched_at` (newest first); up to 10. Fewer than 3 → `items: []` (the rail is omitted, glass §9.1.4). Each item is WorldItem-shaped so both clients render the available World card: `{anilist_id: null, title, alt_titles: [], format: null, country: null, status, chapters: chapter_count, rating: null, genres: genres[:5], cover_url, is_adult: false, platforms: [], anilist_url: null, available: [{source_id, source_name, series_key}], why: null, basis: "genres", ambient, palette}`. Response `basis: "genres"`, `available` true for an explicit `fallback=genres`, `reason: "ok"`.

### E. `POST /ai/feedback` (profile context required: `dependencies=[Depends(require_profile_context)]`)

Body `{signal, anilist_id?, source_id?, series_key?, tag?}` → 204. `signal`:

| Signal | Required | Effect |
|---|---|---|
| `not_interested` | `anilist_id`, or `source_id` + `series_key` | Insert a row. The target is dropped from `/home` (`picked`, `because`, the `ai_pick`/`caught_up` cover, `popular`), `/ai/similar`, `GET /library/world/recommendations` and the onboarding seeds for this profile. |
| `undo` | the same target | Delete this profile's newest `not_interested` row for that target (glass §9.1.1 Undo). No row → still 204. |
| `liked_pick` | `anilist_id`, or `source_id` + `series_key` | Insert a row (cinematic sends it from `More like this` on a World card; pressing it again only clears the button locally, so there is no server unlike). Liked picks join the taste block of the home editorial and of asks sent with `use_taste: true` as "Picks this reader liked" (titles only). |
| `tag_rejected` | `source_id`, `series_key`, `tag` (1 to 64 characters) | Insert a row; `/ai/tags` never suggests that tag for that series to this profile again. |
| `clear` | nothing | Delete every `not_interested` row of this profile (glass §8.25.16 "Clear 'Not interested'"). |

Anything else, or a missing required field, is 422. After every write call `home_service.invalidate_profile(profile_id)`. Extend `HomeService._excluded()` (the one method `backend/04` left for this) to add this profile's `not_interested` targets: pairs for `source_id`/`series_key` rows, and a set of `anilist_id`s checked against WorldItems.

### F. `GET /ai/tags?source=&series=`

Gate (C) first. Response `{tags: [string] (at most 5), available, reason, generated_at}`. Tags are short lower-case labels for the series (for example `regression`, `revenge`, `slow burn`), 1 to 24 characters each, from one desk call per series cached 30 days (`cache_key("tags", source_id, series_key)`, `kind="tags"`, payload `{"tags": [...]}` with up to 8 stored so rejections still leave 5), using `run_and_wait(…, timeout_s=25)` like D. On serve, remove this profile's `tag_rejected` tags for the series and every tag equal (case-insensitive) to one of this profile's own tags already on the series. Desk unavailable and nothing cached → `{tags: [], available: false, reason}` (the line is absent, cinematic §8.17). Prompt input: the title, the genres and the profile's own tag vocabulary names (`GET /library/tags` data) so suggestions reuse the reader's words; never descriptions.

### G. Recaps (`backend/services/recap_service.py`, extended; routes in `backend/routes/ai.py`)

#### G1. `GET /ai/recap/availability?source=&series=&to=&scope=series|chapter`

Gate (C), then `RecapService.availability(source, series, to, scope=scope)` exactly as `backend/04` wrote it. `scope` defaults to `series`. No AI call, no budget cost.

#### G2. `GET /ai/recap?source=&series=&to=&shape=prose|deck&scope=series|chapter`

Defaults `shape=prose` (Cinematic, unchanged by Glass) and `scope=series`. `shape=prose` with `scope=chapter` is 422 (Cinematic never asks for it).

Everything that needs the database happens **before** the response starts (the request's session is closed once the stream begins):

1. Gate (C).
2. `availability = RecapService.availability(...)`. Not available → **no stream**: plain JSON 200 `{"available": false, "reason": "<reason>"}` (reasons `not_configured`, `budget_exhausted`, `rate_limited`, `no_dialogue`, `first_chapter`), exactly the cinematic §9.1.7 **No stream** rule.
3. **Per-account limiter** for cache misses only: at most 3 recap writes started per rolling 60 s per account (an in-process `deque` of start times per `user_id` under a lock). Over the limit → the JSON answer `{"available": false, "reason": "rate_limited"}` with a `Retry-After` header (whole seconds until the oldest start leaves the window). Mark it `# ponytail: per-process limiter; one uvicorn worker in production`.
4. **Cached** (`cache_key("recap", shape, scope, source_id, series_key, from_key, to_key)`) → stream the stored payload at once, no AI call, no budget.
5. **Miss** → load the source text for the range only, in chapter order: manga from `chapter_ocr.full_text` (fall back to the joined `page_texts`), novels from `novel_chapter_cache.paragraphs`; label each chapter `Chapter {number}`; cap the whole block at 24,000 characters by giving each chapter an equal share and cutting at a word boundary. **Never include a chapter at or after `to`, and never a chapter outside the range.** Novels also load the cast: up to 6 `novel_series_cast` rows by `line_count` (display names); manga gets its cast from the AI answer.
6. Return a `StreamingResponse` with headers `Content-Type: text/event-stream; charset=utf-8`, `Cache-Control: no-cache, no-transform`, `X-Accel-Buffering: no` (cinematic §9.1.7 **Stream headers**). The generator:
   - starts a worker thread that calls `SuggestionService._complete(system, message)` (the ask ledgers: one ask on a cache miss, charged to this account, cinematic §9.1.5 **Budget**), validates the JSON, writes the cache row with its own `SessionLocal()` and hands the result back through a `queue.Queue`. The thread runs to the end even if the client disconnects, so a recap closed during generation is cached for the next open (glass §9.1.3 "Leaving during generation");
   - for `shape=deck` yields `event: phase` `{"phase": "writing"}` first;
   - yields an SSE comment line `: keep-alive` every 15 s while it waits (the AI call can take up to 90 s; Cloudflare cuts idle responses at 100 s);
   - then yields the events of G3, or on failure one `event: error` with data `{"code": "<reason>", "message": "…"}`, where `code` is `not_configured`, `budget_exhausted`, `ai_failed` or `rate_limited` (mapped from `_complete`'s `ai_not_configured`, `ai_budget_exhausted`, `ai_failed`; `rate_limited` also carries `"retry_after": 30`), and nothing is cached.
   - SSE framing: every event is `event: <name>\ndata: <one-line JSON>\n\n`, JSON with `ensure_ascii=False`.

#### G3. The events

**`shape=prose`** (Cinematic, cinematic §9.1.5 and §9.1.7):

1. `event: meta` `{"range": {"from_key", "to_key", "from_number", "to_number"}, "cast": [{"name": "Kim Dokja", "note": "the reader"}], "sourced_from": "ocr" | "text"}` (`sourced_from` is `ocr` for manga, `text` for novels).
2. `event: delta` `{"text": "…"}` repeated: the recap's 3 to 5 paragraphs, sent in chunks of at most 8 words each; paragraphs are separated by `"\n\n"` inside the stream; concatenating every `text` gives the whole recap exactly. No markup: the client italicises the cast names itself.
3. `event: done` `{"covered_through": 142, "model": "deepseek-…", "generated_at": "…"}` (the three fields are additive to Cinematic's bare `done`).

**`shape=deck`** (Glass, glass §9.1.3 and §9.1.6):

1. `event: phase` `{"phase": "writing"}` (already sent while waiting).
2. `event: section` `{"kind", "title"}` for every section first, in order, so the client can lay out the deck with skeleton lines: `scope=series` → `left_off` "Where you left off", `happened` "What happened", `cast` "Who's who", `threads` "Open threads"; `scope=chapter` → `last_time` "Last time".
3. `event: delta` `{"kind", "text"}` per section in the same order, chunks of at most 8 words; inside `happened` and `threads` each bullet or question ends with `"\n"`; `cast` deltas are lines `"Name: note\n"`.
4. `event: done` `{"range": [from_number, to_number], "covered_through": to_number, "cast": [{"name", "note"}], "sourced_from": "ocr" | "text", "model", "generated_at", "available": true, "reason": "ok"}`.

**The AI answer** (JSON mode; the system prompt states the rules, the chapter text follows as a labelled DATA block the model must not take instructions from; mention that the recap must describe only the given chapters and nothing after chapter `{to_number}`):

- prose: `{"paragraphs": [3 to 5 strings, each at most 600 characters], "cast": [at most 8 {"name" ≤ 64, "note" ≤ 80}]}`;
- deck, series: `{"left_off": "2 to 3 sentences, ≤ 400 characters", "happened": [4 to 6 strings ≤ 200], "cast": [≤ 6 {"name", "note"}], "threads": [2 to 3 questions ≤ 160]}`;
- deck, chapter: `{"last_time": "3 to 4 sentences, ≤ 500 characters"}`.
- Extra list entries are trimmed to the maximum; a missing or empty required field is `ai_failed`. For novels the cast from `novel_series_cast` wins over the AI's cast.
- Stored payload: the validated answer plus `range`, `covered_through`, `sourced_from`, `model`, `generated_at`; `expires_at` 180 days (a recap of a fixed range does not change).

### H. Taste and onboarding

#### H1. `PUT /profiles/{id}/taste` and `GET /profiles/{id}/taste`

Owned-profile rule of `routes/profiles.py` (`_get_owned`: another account's profile is 404 `profile_not_found`). Body (every field optional; partial bodies merge into the stored JSON):

- `step`: `1` to `7` or `"done"` (Cinematic uses 1 to 5, Glass 1 to 7; glass §15.6); written to `reading_profiles.onboarding_step` as `backend/00` stores it (text `"3"` or `"done"`).
- `formats`: subset of `["manhwa", "manga", "manhua", "novel"]`, replaces the stored list.
- `genres`: object `{name: weight}` with `name` 1 to 64 characters and `weight` in `{-1, 0, 1, 2}` (skip, clear, like, love; glass sends 0 for a third tap, Cinematic's `Clear` also sends 0); merged key by key, `0` deletes the key; at most 80 keys after the merge (422 beyond).
- `styles`: subset of the 11-value union `["painted", "cel", "screentone", "manhua-3d", "sketch", "retro", "pastel", "noir", "chibi", "watercolour", "dark-realism"]` (glass §15.5), replaces the stored list.
- `seeds`: at most 50 items, each `{"anilist_id": int}` or `{"source_id": str, "series_key": str}`, replaces the stored list.

Both return `{"step": 3 | "done" | null, "formats": [...], "genres": {...}, "styles": [...], "seeds": [...]}`. `GET` exists so a client can restore the answers when onboarding resumes (cinematic §8.7 **Resume**). The write is one row update. Call `home_service.invalidate_profile` after it.

#### H2. `GET /onboarding/catalog?formats=&genres=&styles=` (`backend/routes/onboarding.py`, new; logic in `backend/services/taste_service.py`, new)

Comma-separated lists, validated like H1 (unknown values are 422). `@limiter.limit(sources_limit)` (AniList calls). Response `{formats: [{format, covers: [url, url, url]}], genres: [{name, weight}], seeds: [WorldItem], unavailable_reason: string | null}` (cinematic §8.7 **Backend.**):

- `formats`: one entry per requested format, or all four when none is requested (`novel` only when the server's `novels_enabled` is true); `covers` are the 3 trending AniList covers for that format: `Page(perPage: 3) { media(type: MANGA, sort: TRENDING_DESC, isAdult: false, countryOfOrigin: KR | JP | CN, format_in: [MANGA, ONE_SHOT]) }` for manhwa, manga and manhua, and `format_in: [NOVEL]` without a country for novels. Add the queries to `WorldCatalog` (cached through `_lookup` in `world_catalog_cache` for 24 hours, key `al:trending:{format}:{sorted genres}:{adult}`).
- `genres`: the union of `BrowseService.list_genres(source_id)` labels over every installed browsable source this profile may see (mature sources left out while the gate is closed), de-duplicated case-insensitively (keep the most common spelling); while the gate is closed, labels that `rating_from_genres([label])` rates mature are removed too; `weight` = the number of sources offering the label; ordered by weight then name; the first 40 (all of them when fewer than 30 remain, cinematic §8.7). `list_genres` reads each connector's declared list; it makes no network call. Computed per request (it is cheap), never cached across gates.
- `seeds`: 24 WorldItems from the AniList trending query of the requested formats, filtered by the liked and loved genres in `genres=` (intersected case-insensitively with AniList's genre list; no intersection means no genre filter), `is_adult` excluded unless the gate is open, followed series and "Not interested" targets excluded, `available` items first. Built with `WorldRecs._items`.
- `styles` are validated and stored by H1; AniList has no art-style facet, so the catalogue does not filter by them (they reach the AI through the taste block).
- AniList unreachable: `formats[].covers` and `seeds` empty, `genres` still served, `unavailable_reason` = "The worldwide catalogue could not be reached." (the clients show typographic plates and the H3 fallback).

#### H3. `POST /library/taste/seed {formats, genres, styles}` (profile context required)

The sources-only seed wall for when the catalogue cannot reach AniList (glass §8.7 States: "step 6 shows the pinned and popular source catalogues' Popular lists"). No AniList, no AI, no upstream fetch. Returns `{"items": [SourceSeries × up to 24], "basis": "sources"}`: `source_series_cache` rows on the profile's sources (pins, else `backend/04`'s 3 healthiest non-18+ sources of the kind), limited to manga sources when `formats` holds only manhwa/manga/manhua and to novel sources when it holds only `novel`, not followed, not excluded, visible on serve; ordered by the number of liked and loved genres they share (descending), then `fetched_at` (newest first); when fewer than 24 match, filled from the same sources' cached `source_browse_cache` page 1 of their `popular` mode (read only, never fetched).

#### H4. Taste on the rest of the backend

- `/home`'s `genres` section (`backend/04`) for a profile with no follows: the taste genres with weight 2 first, then 1, as `{genre, weight}`; omitted when there are none (cinematic §8.8 new profile).
- The home editorial input (`backend/04` E8) gains the taste block: formats, loved, liked and skipped genres, styles, liked picks (titles only).

### I. World recommendations and suggest additions (`backend/routes/library.py`, `backend/services/suggestion_service.py`)

1. `GET /library/world/recommendations` gains `genre` (optional, 1 to 64 characters): `for_you` and each section's `items` keep only WorldItems whose `genres` contain it (case-insensitive); sections left empty are dropped. Not-interested targets are dropped from both lists for this profile. Without `genre` the response is unchanged apart from that exclusion.
2. `POST /library/suggest` and `POST /library/world/suggest` gain `use_taste: bool = False` (glass §9.1.2): when true, the user message gains one more labelled DATA block with the taste (H1 fields and liked picks, titles and genre names only). With the default `false` the prompt is byte-for-byte what it is today (assert it in a test).
3. `POST /library/suggest` gains `content_kind: "manga" | "novel" | None = None`: when set, `shelf()` keeps only rows whose source descriptor has that `content_kind`.

### J. Per-series caches gate on serve (cinematic §15.5)

`/ai/similar`, `/ai/tags` and `/series/enrichment` read shared rows written for anyone. The first two gate the series (C) before reading their row and filter mature items on the way out; `/series/enrichment` keeps the gate `backend/02` gave it, and this step only proves it (section K). No per-series AI row is ever written with a profile's gate applied.

### K. Tests (write them first; the AI mocked as `test_suggestion_service.py` does it, AniList faked through `world_recs._transport` as `test_world_recs.py` does it)

- `backend/tests/test_ai_recap_stream.py`:
  1. **Prose framing**: a stubbed `complete_json` answering 4 paragraphs; the response has the three stream headers; events parse as `meta`, then only `delta`, then `done`; the joined `delta` texts equal the four paragraphs joined by `"\n\n"`; no chunk exceeds 8 words; `done` carries `covered_through`, `model`, `generated_at`.
  2. **Deck framing**: `shape=deck`: `phase` first, then four `section` events in the order left_off, happened, cast, threads, then deltas grouped by kind in that order, then `done` with `range`, `covered_through`, `cast`, `sourced_from`, `model`, `generated_at`, `available: true`, `reason: "ok"`; `scope=chapter` sends one `last_time` section.
  3. **Never past `covered_through`**: OCR rows exist for chapters 131 to 145, the profile completed 131 to 142 and asks `to=143`; the message sent to the stub contains the marker text of 131 to 142 and none of 143, 144, 145; `done.covered_through == 142`; a cached recap for 131 to 142 is not served for a request whose range is 131 to 141.
  4. **No stream**: `first_chapter`, `no_dialogue`, `not_configured`, `budget_exhausted` answer JSON 200 `{"available": false, "reason": …}` with no `text/event-stream` header; the fourth cache miss inside 60 s answers `rate_limited` with a `Retry-After` header.
  5. **Cached**: the second request for the same range makes no `complete_json` call and spends nothing on either ledger; the ask ledger records exactly one request after the first.
  6. **Failure**: `complete_json` raising `LLMError` yields one `event: error` with `code: "ai_failed"` and writes no cache row.
  7. **Gate**: a mature series with the gate closed → 404 `series_not_found` for both `/ai/recap` and `/ai/recap/availability`, and the stub is never called.
- `backend/tests/test_ai_similar_tags.py`: the AI path (10 items, available first, `why` lines, `basis: "ai"`); the `anilist_id` path (exactly 3); `run_and_wait` timing out returns items with `why: null` and the next call serves the cached lines; desk unavailable → `available: false` plus genre-fallback items for `source`+`series` and `[]` for `anilist_id`; `fallback=genres` (≥ 2 shared genres, the profile's sources only, never followed, fewer than 3 → `[]`); **18+ absence**: a similar row cached with an `is_adult` item and a mature-source item is served to a gated profile without them, and to an open-gate profile with them; `/ai/tags` removes rejected and already-owned tags, caps at 5, and 404s a gated series; `/series/enrichment` keeps the answer `backend/02` gives a hidden series (`null` or 404; its contract is not changed here), and the test asserts that a gated profile never receives the stored enrichment row: the stored `anilist_id` and `official` links are absent from the body.
- `backend/tests/test_ai_feedback.py`: each signal's validation (422 cases); `not_interested` removes the target from `/home` `picked`, `/ai/similar` and `GET /library/world/recommendations` for that profile only (another profile of the same account still sees it); `undo` restores it; `clear` restores everything; `tag_rejected` hides the tag; writes without `X-Profile-Id` on an account with profiles → 400 `profile_required`.
- `backend/tests/test_taste_onboarding.py`: `PUT` merges partial bodies, `0` deletes a genre, `step` 1 to 7 and `"done"` round-trip, 8 is 422, an unknown style is 422, another account's profile is 404, `GET` returns what was stored; the catalogue's `genres` exclude mature sources' labels and mature labels for a gated profile and include them for an open one, hold 30 to 40 entries when enough exist, and are ordered by weight; `seeds` exclude `is_adult` while gated and list `available` items first; AniList down → `unavailable_reason` set and `genres` still served; `/library/taste/seed` returns up to 24 non-followed, non-mature rows on the profile's sources and never calls a connector (`FakeBrowse` raising on any fetch); `/home` for a new profile with taste genres has a `genres` section with loved first.
- `backend/tests/test_suggestion_service.py` gains: `use_taste` false leaves the message identical to today's; true adds the taste block; `content_kind="novel"` keeps only novel rows on the shelf.

## File layout

| Path | Change |
|---|---|
| `backend/alembic/versions/00NN_ai_taste_feedback.py` | new |
| `backend/database/models.py` | `ReadingProfile.taste`, class `AiFeedback` |
| `backend/services/series_gate.py` | new, unless `backend/02` already has the helper (C) |
| `backend/services/ai_desk.py` | `run_and_wait` |
| `backend/services/ai_series_service.py` | new: similar, genre fallback, tags, feedback, exclusions |
| `backend/services/recap_service.py` | the stream (G) |
| `backend/services/taste_service.py` | new: taste read/write, catalogue, seed fallback |
| `backend/services/world_recs.py` | the trending queries, the `genre` filter |
| `backend/services/suggestion_service.py` | `use_taste`, `content_kind` |
| `backend/services/home_service.py` | `_excluded` feedback, taste genres, taste in the editorial input |
| `backend/routes/ai.py`, `backend/routes/onboarding.py` | new |
| `backend/routes/profiles.py` | `PUT`/`GET /profiles/{id}/taste` |
| `backend/routes/library.py` | `POST /library/taste/seed`, `genre=`, the suggest fields |
| `backend/api/router.py` | include the two new routers |
| `backend/docs/home-api.md` | append sections for every endpoint of this step (query, body, response, SSE event list, error codes) |
| `backend/tests/test_ai_recap_stream.py`, `test_ai_similar_tags.py`, `test_ai_feedback.py`, `test_taste_onboarding.py` | new |
| `backend/tests/test_migrations_alembic.py`, `test_suggestion_service.py` | updated |
| `docs/redesign/proof/backend-05/` | `plan.md`, `pytest-before.txt`, `pytest-after.txt`, the captures of L |

### L. Proof (dev stack; never production)

`free -m`, `backend/scripts/dev_stack.sh reset`. Save into `docs/redesign/proof/backend-05/` (pretty JSON through the `api` helper, `MM_DEV_PROFILE` as named):

- `taste-put.json` and `taste-get.json` (Aarav: `PUT /profiles/{id}/taste {"step": 3, "formats": ["manhwa"], "genres": {"Action": 2, "Romance": 1, "Horror": -1}}`, then `GET`),
- `catalog-aarav.json` and `catalog-riya.json` (`GET /onboarding/catalog?formats=manhwa&genres=Action`; the first is gated, the second open),
- `taste-seed-aarav.json` (`POST /library/taste/seed`),
- `similar-genres.json` (`GET /ai/similar?source=…&series=…&fallback=genres` for Riya's first follow),
- `similar-ai-unavailable.json` (the same without `fallback`: the dev stack has no AI key, so this shows `available: false` with the genre items),
- `recap-availability.json` (`GET /ai/recap/availability` for Riya's newest continue row),
- `recap-no-stream.txt`: `curl -s -i` of `GET /ai/recap` for the same row (the JSON no-stream answer, headers included; build the `curl` with the cookie jar and `X-Profile-Id` the way `dev_stack.sh api` does),
- `feedback.txt`: the `204` of a `POST /ai/feedback {"signal": "clear"}`.

Stop the dev stack afterwards. No web screen changes here, so there are no Playwright screenshots; these files are the proof.

## Acceptance criteria

- [ ] `pytest-before.txt` and `pytest-after.txt` show every previously passing test still passing, plus the new files.
- [ ] `GET /ai/similar` serves the AI path (10 or 3 items with `why`), the genre fallback and the unavailable path exactly as D says, and never shows an adult or mature-source item to a gated profile, including from a cache row written for an open-gate profile.
- [ ] `GET /ai/recap/availability` returns the `backend/04` object for both scopes with no AI call.
- [ ] `GET /ai/recap` streams Cinematic's prose (`meta`, `delta`, `done`) and Glass's deck (`phase`, `section`, `delta`, `done` with `model` and `covered_through`) with the three stream headers, sends keep-alive comments every 15 s while waiting, answers the no-stream JSON for every unavailable reason, never sends text from a chapter at or after `to`, caches per (series, range, shape, scope), and spends one ask only on a cache miss.
- [ ] `GET /ai/tags` returns at most 5 tags without the profile's rejected or already-owned tags, and `{tags: [], available: false, reason}` when the desk is closed and nothing is cached.
- [ ] `POST /ai/feedback` accepts exactly the five signals, and each takes effect for that profile only.
- [ ] `PUT`/`GET /profiles/{id}/taste` merge and validate as H1, write `onboarding_step`, and refuse another account's profile with 404.
- [ ] `GET /onboarding/catalog` returns formats, 30 to 40 gated genres and 24 gated seeds, cached 24 hours per gate, formats and genres; `POST /library/taste/seed` returns up to 24 gated rows without any network call.
- [ ] `GET /library/world/recommendations?genre=` filters; the two suggest calls accept `use_taste` and (local) `content_kind`, and their defaults keep today's prompt byte-identical.
- [ ] Per-skin: Cinematic uses `shape=prose` (the default), `/ai/similar` without `fallback` (reading `basis` to caption `SAME GENRES`), `liked_pick`, `not_interested`, `tag_rejected`, onboarding steps 1 to 5; Glass uses `shape=deck` with `scope=series|chapter`, `fallback=genres`, `undo` and `clear`, `use_taste`, `?genre=`, onboarding steps 1 to 7 and the `/library/taste/seed` fallback. One backend serves both; no endpoint branches on the skin.
- [ ] UI rules (reduced motion, keyboard, 44 pt targets) belong to `web/19`, `mobile/19`, `web/41`, `mobile/41` and the onboarding steps. This step serves them by streaming whole words (a reduced-motion client can append text without animation), by sending the deck's section titles before any text (a screen reader gets the headings first), and by answering the no-stream JSON at once instead of opening a stream that only errors.
- [ ] `backend/docs/home-api.md` documents every endpoint of this step.
- [ ] `git diff --stat -- frontend mobile ops backend/connectors` prints nothing.

## Verification

One heavy command at a time, `free -m` before each; stop under 1024 MB available.

```bash
cd /srv/manhwamaniacs/dev/ManhwaManiacs/backend
free -m
.venv/bin/python -m pytest -q --no-header tests/test_ai_recap_stream.py tests/test_ai_similar_tags.py tests/test_ai_feedback.py tests/test_taste_onboarding.py tests/test_suggestion_service.py tests/test_world_recs.py tests/test_home_feed.py tests/test_recap_availability.py tests/test_migrations_alembic.py
free -m
timeout 1800 .venv/bin/python -m pytest -q --no-header 2>&1 | tail -25 > ../docs/redesign/proof/backend-05/pytest-after.txt
cat ../docs/redesign/proof/backend-05/pytest-after.txt
```

Web and mobile are not run because nothing under `frontend/` or `mobile/` changes (`git diff --stat -- frontend mobile` prints nothing). Their baseline commands, if you ever touch them: `npm run lint` and `npm run build` in `frontend/`; `/srv/manhwamaniacs/dev/flutter/bin/flutter analyze` and `/srv/manhwamaniacs/dev/flutter/bin/flutter test` in `mobile/`.

## RAM guard

Production and five Minecraft bots share this box (7,746 MB). `free -m` before each pytest run and before starting the dev stack; stop and report if `available` is under 1024 MB. Never run two heavy commands at once; never run `next build` here.

## Git

- Branch `feat/vps-slim-source-native`; commit small and often and push after each: `git push origin feat/vps-slim-source-native`.
- Suggested commits: (1) `test(ai): recap stream, similar, tags, feedback and taste cases` (failing), (2) `feat(backend): reading_profiles.taste and ai_feedback`, (3) `feat(ai): series gate helper and GET /ai/similar with the genre fallback`, (4) `feat(ai): feedback signals and exclusions`, (5) `feat(ai): suggested tags`, (6) `feat(recap): availability endpoint and SSE stream`, (7) `feat(onboarding): taste, catalogue and seed fallback`, (8) `feat(library): world recs genre filter, use_taste and content_kind`, (9) `docs(backend): AI endpoints in the home API note`, (10) `docs(redesign): backend-05 proof`.
- Stage by explicit path only. No Claude or AI attribution anywhere (no `Co-Authored-By`, no "generated with" line, no AI author). Never commit secrets, `.env`, `.claude/`, `backend/.venv/` or dev data.
- No frontend change, so no `next build` before pushing; if `git status` shows a frontend change you made, stop.

## Never

- Never edit `backend/connectors/`; never touch production containers, `/srv/manhwamaniacs/app` or `/srv/manhwamaniacs/data`.
- Never send scraped descriptions to the AI; never call an AI provider except through `deepseek_client.complete_json`; never fetch a chapter from a source to write a recap.
- Never store a per-series AI row with a gate applied, and never serve one without gating it.

## Report back

Reply with:
1. Done items A to L, each with its commit SHA.
2. The revision id and the head it follows.
3. Backend test counts before and after, and the new test files with their case counts.
4. The proof folder `docs/redesign/proof/backend-05/` and its files (no screenshots in this step).
5. Open issues: any cinematic §9.1.7 or glass §9.1.6 field you could not serve exactly, whether `backend/02`'s enrichment helper was reused or `series_gate.py` was created, and the `run_and_wait` timings you saw in the tests.

Next prompt file in the series: `docs/redesign/prompts/web/08-cinematic-tonight.md`. Next file in the backend track: `docs/redesign/prompts/backend/06-reader-tints-panels-novel-audio.md`.
