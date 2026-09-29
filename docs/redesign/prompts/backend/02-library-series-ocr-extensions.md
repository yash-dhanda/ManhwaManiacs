# Backend 02: library, collections, tags, series enrichment and OCR boxes

## Goal

The library, series and discover clusters of both skins ask the server for things today's API cannot answer: mark read and unread without inventing reading time, move a follow to another source with its progress, smart shelves that look the same on every device, collection plates without one request per shelf, tags on shelf rows and a tag filter over the whole library, sorts and the NEW ONLY filter evaluated over the whole library rather than the 200-row page, a credits block from AniList for the feature page, and the exact speech bubble a dialogue-search hit came from. This step adds exactly the rows of cinematic §15.5 those clusters need, plus the Glass library rows of glass §15.5 that serve both skins (tag `series_count`, collection `created_at`, the member reorder call). Everything is profile-scoped, gated for 18+ on serve, additive, and covered by tests including profile isolation and gate-closed absence.

## Read first

1. `docs/redesign/cinematic/DESIGN.md` §15.5, these rows: `POST /reader/progress/batch … manual: true` and `DELETE /reader/progress`, `POST /library/series/{followed_id}/repoint`, `rules` on collections, `preview_covers` and `preview_ambient_duo`, `tags` on `FollowedSeries` rows with `tag_ids=` and `PATCH /library/tags/{id}`, the `GET /library/series` sorts and `new_only`, `GET /series/enrichment`, and `/ocr/search` `page` and `box`. Then §8.9 (the shelf toolbar paragraph: "Every sort and filter runs on the server over the whole library"), §8.11 (collections, smart shelves evaluated on the device), §8.17 (feature page: DETAILS credits, Mark read / Mark read up to here / Mark unread, Move to another source), §8.24 (dialogue search's subtitled stills).
2. `docs/redesign/glass/DESIGN.md` §15.5 rows: first four member covers, `tags` and `tag_ids=`, `PATCH /library/tags/{id} {name}`, `series_count` on `GET /library/tags`, `PUT /library/collections/{id}/series/order` and `created_at`; §15.6 rows **Collection order and creation date**; §8.0.3 (the **Library query names** paragraph: `tags` maps to `tag_ids=`); §8.17 (Manage tags: "12 series", rename max 24 characters); §8.18 (collections: fanned stacks, reorder, "Recently created"); §8.23 (dialogue search).
3. `docs/redesign/inventory/capabilities.md` §7 (Library), §11 (Collections), §12 (Tags), §13 (progress), §20 (OCR search), §9 (world catalog).
4. `docs/redesign/inventory/00-decisions.md`; `docs/redesign/00-baseline.md`; `docs/redesign/proof/backend-00/pytest-baseline.txt` and `docs/redesign/proof/backend-01/pytest-after.txt` (the pass count to keep).
5. Code: `backend/routes/library.py`, `backend/routes/reader.py` (`ProgressRequest`, `save_progress_batch`, `PROGRESS_BATCH_MAX_ITEMS`), `backend/routes/ocr.py`, `backend/services/followed_series_service.py` (`list_series`, `_read_states`, `_reading_state`, `serialize`, `follow`, `_followed_under_another_key`, the collection methods `_visible_members`, `_member_counts`, `list_collections`, `get_collection`, `update_collection`, `_serialize_collection`, and the tag methods), `backend/services/progress_service.py` (`ProgressInput`, `_apply_one`, `_storage`, `record_session`), `backend/services/ocr_search.py`, `backend/services/source_cache_service.py` (`_series_key_hides`), `backend/services/browse_service.py` (`ensure_visible`, `get_series`, `get_chapters`, the `source_unreachable` errors), `backend/services/world_recs.py` (`WorldCatalog.search`, `_read`, `_write`, `_format`, `_SOCIAL_SITES`, `_close`), `backend/services/cover_colour.py` (`attach_cover_colours`, from backend/01), `backend/core/content_rating.py` (`mature_tracker_case`), `backend/api/router.py`, `mobile/lib/features/ocr/models/page_text.dart` (box geometry is normalised 0..1 with a top-left origin), and the tests `test_library_endpoints.py`, `test_audit_mature_collections.py`, `test_progress_db.py`, `test_ocr_search_query.py`, `test_ocr_scope.py`, `test_profile_isolation.py`, `test_world_recs.py`.

## Track rule (every `backend/*` prompt)

- Work only in `backend/` (never `backend/connectors/`) plus `docs/redesign/proof/backend-02/`.
- Stage only the paths you changed, by name; never `git add -A`.
- Alembic revisions continue; this step's revision is `0020_collection_rules`.
- Every endpoint is profile-scoped and applies the 18+ gate when serving, never when storing (the enrichment cache too). Writes stay ungated, as the reader routes already are ("a shut gate is a request not to be shown adult series, not a request to forget").
- Additive only. Tests: `backend/.venv/bin/python -m pytest -q --no-header` from `backend/`.

## Preconditions

1. Branch `feat/vps-slim-source-native`.
2. `backend/services/cover_colour.py` and `backend/alembic/versions/0019_cover_palette.py` exist (backend/01 landed); the newest revision file is `0019_cover_palette.py`. Otherwise stop and report.
3. `free -m` shows at least 1024 MB available.

## Skills

- `superpowers:writing-plans` first; plan in `docs/redesign/proof/backend-02/plan.md`, one task per item below.
- `superpowers:subagent-driven-development` to run it: the items are independent (progress, repoint, collections, tags and library list, enrichment, OCR). Give each subagent exactly one item, this file's section for it, and the instruction to touch only the files that item names; integrate and run the full suite yourself afterwards. Items C and D both edit `followed_series_service.py`, so run them in the same subagent, one after the other.
- `superpowers:test-driven-development` inside every item.
- `superpowers:verification-before-completion` before reporting.
- Not `impeccable`, `taste-skill:taste-skill` or `frontend-design`: no UI here.

## Scope, item by item

### A. Mark read without reading time, and mark unread

1. `ProgressRequest` (`backend/routes/reader.py`) and `ProgressInput` (`progress_service.py`) gain `manual: bool = False`. It is accepted on `POST /reader/progress` and on every item of `POST /reader/progress/batch` (both parse through `ProgressRequest`). In `_apply_one`, when `payload.manual` is true, the position merge and the update-notification clearing run as usual but `record_session` is **not** called, so a mark-read creates no `ReadingSession` and no time, pages or streak day (cinematic §15.5, §8.17 Mark read / Mark read up to here).
2. `DELETE /reader/progress` (`require_profile_context`, status 204) with the JSON body `{source_id: 1..64 chars, series_key: 1..512, chapter_keys: list of 1..200 strings of 1..512 chars}` (more than 200 → 422 from the model). Each key is resolved with the same `_storage(source_id, fully_unquote(series_key), fully_unquote(chapter_key))` mapping the save path uses, so a follow whose key drifted deletes the rows it actually reads, and the matching `ChapterProgress` rows in the caller's scope are deleted in one transaction through the `_write` retry wrapper. Unknown keys are ignored. `reading_sessions` are never touched (history and statistics keep what was read). Another profile's rows are unreachable by construction (the scope), and a series the gate hides is still deletable (writes are ungated).

### B. Move a follow to another source: `POST /library/series/{followed_id}/repoint`

`require_profile_context`. Body `{source_id: 1..64, series_key: 1..512, keep_old: bool = false}`. Response 200:

```json
{"followed": FollowedSeries, "mapped_chapter_key": "…" , "mapped_chapter_number": 41.0}
```

(`mapped_chapter_key` and `mapped_chapter_number` may each be `null`). `followed` is the `serialize` payload with `read_state`, `tags`, `ambient` and `palette`.

Rules:

1. The follow must be the caller's and visible under the gate, else 404 `series_not_found`. The target source must pass `BrowseService.ensure_visible`, and a target series that the gate hides answers 404 `series_not_found`.
2. Target equal to the current `(source_id, series_key)` → 422 `same_series`. The profile already following the target (exact key or `_followed_under_another_key`) → 409 `already_followed` with `details: {"followed_id": <id>}`.
3. Fetch the target's metadata and chapter list live (`browse.get_series`, `browse.get_chapters`). A connector failure surfaces as the browse layer's own `source_unreachable` error; nothing is written.
4. **Progress mapped by chapter number.** The old series' furthest chapter comes from its `read_state` (`_read_states([row])`), giving number N (or none). Every completed old `ChapterProgress` row with a `chapter_number` is copied to the target chapter whose `number` equals it (compare `round(x, 3)`), as a completed row with the old `last_page`, `page_count`, `completed_at` and `last_read_at` and `time_spent_seconds = 0`, written directly (no `record_session`, so no reading time is invented). `mapped_chapter_key` is the target chapter whose number equals N, else the target chapter with the greatest number at or below N, else `null`; `mapped_chapter_number` is that chapter's number or `null`. The old rows stay.
5. `keep_old: false`: the row is repointed in place: `source_id`, `series_key`, `title`, `cover_url` and `content_rating` from the target, `known_chapters` set to the live target list (so the next sweep does not notify every chapter as new), `mature_override` reset to `null`, and the existing columns `migrated_from_source`, `migrated_from_series_key` filled with the old pair and `migrated_at = utcnow()`. The profile's `collection_series` and `profile_series_tags` rows for the old pair are moved to the new pair. Notifications stay as they are.
6. `keep_old: true`: a **new** follow row is created for the target (subject to `max_follows_per_profile`, refusing with the same error `follow` raises), copying `is_favorite`, `reading_status`, `notify` and `sort_order`, with `known_chapters` from the live list and `migrated_from_*` / `migrated_at` filled; collection and tag rows are copied, not moved; the old row is untouched.

### C. Collections: rules, previews, creation date and member order

Migration `backend/alembic/versions/0020_collection_rules.py` (`down_revision = "0019_cover_palette"`): `op.add_column("collections", sa.Column("rules", sa.Text(), nullable=True))`; downgrade drops it (lossy, commented). Model: `rules: Mapped[str | None] = mapped_column(Text)` on `Collection`. Update `_HEAD` and `_REVISIONS` in `test_migrations_alembic.py`.

1. **`rules`** on `POST /library/collections`, `PATCH /library/collections/{id}`, `GET /library/collections` rows and `GET /library/collections/{id}`: `null` or `{"all": [{"field", "op", "value"}]}` with 1 to 8 conditions (cinematic §15.5). Validate with Pydantic: `field` ∈ `reading_status`, `is_favorite`, `new_count`, `format`, `content_kind`; `op` ∈ `eq`, `gte`, `in`, `ne`; `value` is a string, integer, boolean, or (only with `in`) a list of 1 to 20 strings; `in` requires a list and every other op requires a scalar; `gte` only with `new_count`. Anything else → 422. The server only stores the JSON; membership is computed on the device (cinematic §8.11). Every serialized collection gains `rules` (parsed, or `null`) and `smart` (`rules is not null`). `PATCH` with `"rules": null` clears them (use `model_dump(exclude_unset=True)`, as the existing handler already does).
2. **List rows** of `GET /library/collections` gain `preview_covers` (the first four **visible** members' cover URLs in `(sort_order, added_at)` order: the profile's follow's `cover_url` when followed, else `/sources/{source_id}/series/{quote(series_key, safe='')}/cover`) and `preview_ambient_duo` (the `ambient.duo` of the first preview member from `cover_palette` via `attach_cover_colours`, else `null`). One query for all collections: `ROW_NUMBER() OVER (PARTITION BY collection_id ORDER BY sort_order, added_at)` filtered to `<= 4`, run through `_visible_members` so a gated profile's plate never shows a mature cover.
3. **`created_at`** (ISO string) on every serialized collection (glass §15.5; the column already exists).
4. **`PUT /library/collections/{id}/series/order`** (`require_profile_context`, 204), body `{"items": [{"source_id", "series_key"}]}`: the full ordered list of the members the caller can see. It must equal the visible membership exactly (same pairs after `fully_unquote`, no duplicates), else 422 `order_mismatch`. Visible members get `sort_order = index`; members hidden by the gate keep their relative order after them (`sort_order = len(items) + previous rank`). Another profile's collection → 404. (backend/09 adds the 403 for shared-shelf members; nothing about sharing exists yet.)

### D. Tags and the library list

1. **`tags`** on every `FollowedSeries` row of `GET /library/series` and `GET /library/search`: `[{id, name, category, color}]` (the `_serialize_tag` object), sorted by name, loaded for the page window in one query (`ProfileSeriesTag` joined to `Tag` in the caller's scope, keyed by `(source_id, series_key)`).
2. **`GET /library/series` gains:**
   - `tag_ids=1,4` (any-of): comma-separated positive integers, else 422 `invalid_tag_ids`; applied as an `EXISTS` on `profile_series_tags` in the caller's scope **before** paging, so it filters the whole library. Ids the caller does not own match nothing.
   - `sort=last_read_at` and `sort=-last_read_at`: by the series' newest `ChapterProgress.last_read_at` in the caller's scope (one grouped query over the visible rows); never-read series sort last in both directions; ties by title.
   - `sort=-new_count`: by `read_state.new_count` descending; `null` (unknown) sorts last; ties by title. This needs `_read_states` over the whole filtered set, not just the page, so compute it only when this sort or `new_only` is requested.
   - `new_only=true`: keeps rows whose `read_state.new_count >= 1`.
   - The existing sorts and filters keep their current behaviour; `total`, `has_next` and `total_pages` describe the filtered set.
3. **`PATCH /library/tags/{id}`** (`require_profile_context`) body `{name?: 1..255 chars after trimming, color?: "#RRGGBB" | null}`: rename and recolour. A name equal, case-insensitively, to another tag in the same scope → 409 `tag_exists`; a colour not matching `^#[0-9A-Fa-f]{6}$` → 422; explicit `color: null` clears it; another profile's tag → 404 `not_found` (the existing `_owned_tag`). Returns the serialized tag with `series_count`.
4. **`series_count`** on every `GET /library/tags` row (glass §15.5): the number of distinct `(source_id, series_key)` pairs carrying the tag in the caller's scope, counted through the same gate rule as `_visible_members` (outer join on the profile's follow, `mature_tracker_case(ProfileSeriesTag.source_id) == 0` when the gate is shut), so a gated profile never learns that hidden series carry the tag.

### E. Series enrichment: `GET /series/enrichment?source=&series=`

New router file `backend/routes/series.py` (`APIRouter(prefix="/series", tags=["series"])`), registered in `backend/api/router.py` beside the others, rate limited with `@limiter.limit(sources_limit)` (take `request: Request` and `response: Response` as the other limited routes do).

Response 200: `{"anilist_id": int, "format": str, "score": float | null, "official": [{"site", "url"}]}` or JSON `null` when AniList has no confident match.

1. Gate first: `BrowseService.ensure_visible(source)`, then the series-rating check the cover route uses (`SourceCacheService._series_key_hides`; promote it to a public `series_hidden(source_id, series_key)` and keep the old name as a one-line alias only if something else calls it). Hidden → 404 `series_not_found`.
2. Cache in `world_catalog_cache` under `enrich:` + the SHA-1 hex of `source_id + "\x1f" + fully_unquote(series_key)` (47 characters, inside the 300-character key), with a 30-day freshness window through `WorldCatalog._read(keys, timedelta(days=30))` and `_write`. A miss is cached too (payload `null`), so a series AniList does not know is asked once a month, not per visit.
3. On a miss: the title comes from the caller's follow row, else `source_series_cache.title`, else one live `browse.get_series`. `WorldCatalog.search([title])` asks AniList and accepts only a match `_close()` confirms against AniList's romaji, English and native titles and synonyms (the "alternate titles"). Store `{"anilist_id": media["id"], "format": _format(media), "score": round(averageScore / 10, 1) or null, "official": [...], "is_adult": bool(media["isAdult"])}` where `official` is `externalLinks` with a `url`, `type != "SOCIAL"` and a site not in `_SOCIAL_SITES`, at most 6.
4. On serve: when the cached `is_adult` is true and the caller's gate is shut, answer `null`. `is_adult` is never serialized. An AniList outage answers `null` without caching (the `_lookup` behaviour) and never 5xx.

### F. Dialogue search boxes: `/ocr/search` items gain `page` and `box`

In `OcrSearchService.search` (`backend/services/ocr_search.py`), select `c.page_texts` with the rows (only for the returned page of results) and, per item:

1. Parse the JSON pages (`[{page, text, boxes}]`); a missing or unparsable value gives `page: null, box: null`.
2. `page` is the first page, in ascending page order, whose `text` or any box `text` contains a query term, case-insensitive (the same `terms` the snippet highlights).
3. `box` is the first box on that page whose `text` contains a term, as `{x, y, w, h}` in page fractions: from `x`, `y`, `width`, `height`, or from `left`, `top`, `right`, `bottom` (`w = right - left`, `h = bottom - top`), each rounded to 4 decimals. If any of the four values is missing or lies outside `[0, 1]` (older pixel-space uploads), `box` is `null` and `page` is kept.
4. No match inside `page_texts` (the FTS matched on tokenisation only) gives `page: null, box: null`.

The scope and gate of the search are unchanged (`_allowed_series`).

### G. Tests (write them first)

`backend/tests/test_library_extensions.py` (A to D), `backend/tests/test_series_enrichment.py` (E), and additions to `backend/tests/test_ocr_search_query.py` (F). Use `as_user`, `make_user`, `make_profile`, `seed_follow`, `seed_progress` and `tests/_fakes.py`. At minimum:

1. A batch item with `manual: true` saves `is_completed` and creates **no** `reading_sessions` row; the same item without `manual` creates one.
2. `DELETE /reader/progress` removes exactly the named chapters for the caller's profile, leaves another profile's identical keys untouched, leaves `reading_sessions` untouched, answers 204 for unknown keys, and 422 for 201 keys.
3. Repoint `keep_old: false`: the row's key changes, `migrated_from_*` holds the old pair, completed chapters 1–5 map by number, `mapped_chapter_key` is the target's chapter 5, collection and tag rows moved, no `reading_sessions` created. `keep_old: true`: two rows, the old one untouched. A target number gap (old 5, target has 4 and 6) maps to 4. `already_followed` 409, `same_series` 422, another profile's follow 404, a mature target with the gate shut 404.
4. Collections: rules round-trip on POST, PATCH and both GETs; `smart` follows `rules`; every invalid shape listed in C.1 gives 422; `preview_covers` holds at most 4 in order and excludes a mature member for a gated profile (and `preview_ambient_duo` then comes from the first visible member); `created_at` present; the order `PUT` reorders, rejects a mismatched set with 422, keeps hidden members after the visible ones, and 404s for another profile.
5. Tags: rows carry `tags`; `tag_ids` any-of across the whole library (page 2 contains matches beyond the first page); `invalid_tag_ids` 422; `PATCH` rename, recolour, clear colour, `tag_exists` 409, other profile 404; `series_count` excludes a mature series when the gate is shut.
6. Sorts: `-last_read_at` puts the most recently read first and never-read last; `-new_count` orders by unread count with unknown last; `new_only=true` returns only rows with `new_count >= 1` and its `total` counts the whole library.
7. Enrichment with the AniList transport mocked as in `test_world_recs.py`: a confident match returns the four fields; a second call does not reach the transport (cached); an unmatched title caches `null`; an adult match answers `null` to a gated profile and the object to an open one; a gated profile asking about a mature series gets 404; an AniList 500 answers `null` and caches nothing.
8. OCR: a hit whose second page holds the term returns `page: 2` and the first matching box as fractions; `left/top/right/bottom` geometry converts; pixel-space geometry gives `box: null` with `page` kept; a row with no `page_texts` gives both `null`; an unfollowed series and a gated mature series stay absent (the existing scope tests keep passing).
9. Profile isolation for every new route: two profiles on one account and two accounts, each seeing only its own rows.

### H. Proof

`backend/scripts/dev_stack.sh restart`, then save with `backend/scripts/dev_stack.sh api …` into `docs/redesign/proof/backend-02/`:

- `library-sorted.json`: `GET /library/series?sort=-last_read_at`
- `collections.json`: `GET /library/collections` (shows `preview_covers`, `preview_ambient_duo`, `rules`, `smart`, `created_at`)
- `tags.json`: after `POST /library/tags {"name":"Rewatch","color":"#FF8A3D"}` and one `POST /library/series-tags`, `GET /library/tags` and `GET /library/series?tag_ids=<id>`
- `enrichment.json`: `GET /series/enrichment?source=<first seeded source>&series=<its key>`
- `pytest-after.txt`: the last 25 lines of the full suite.

## File layout

Created: `backend/routes/series.py`, `backend/alembic/versions/0020_collection_rules.py`, `backend/tests/test_library_extensions.py`, `backend/tests/test_series_enrichment.py`, `docs/redesign/proof/backend-02/*`.

Changed: `backend/routes/reader.py`, `backend/routes/library.py`, `backend/api/router.py`, `backend/services/progress_service.py`, `backend/services/followed_series_service.py`, `backend/services/ocr_search.py`, `backend/services/source_cache_service.py` (the public `series_hidden` name only), `backend/services/world_recs.py` (only if a small helper for the enrichment payload belongs there), `backend/database/models.py` (`Collection.rules`), `backend/tests/test_migrations_alembic.py`, `backend/tests/test_ocr_search_query.py`.

## Acceptance criteria

- [ ] `manual: true` progress creates no `ReadingSession`; `DELETE /reader/progress` deletes up to 200 named chapters for the caller only and answers 204.
- [ ] Repoint answers `{followed, mapped_chapter_key, mapped_chapter_number}`, maps progress by chapter number without inventing reading time, fills `migrated_from_*` when repointing in place, and honours `keep_old`.
- [ ] Collections carry `rules`, `smart` and `created_at`; list rows carry `preview_covers` (at most 4, gate-filtered) and `preview_ambient_duo`; the member order `PUT` works for the owner profile only.
- [ ] Library rows carry `tags`; `tag_ids`, `sort=last_read_at|-last_read_at|-new_count` and `new_only=true` are evaluated over the whole library before paging.
- [ ] `PATCH /library/tags/{id}` renames and recolours; `GET /library/tags` rows carry a gate-aware `series_count`.
- [ ] `GET /series/enrichment` returns `{anilist_id, format, score, official}` or `null`, caches 30 days in `world_catalog_cache`, and is 18+ gated on serve (404 for a hidden series, `null` for an adult match under a shut gate).
- [ ] `/ocr/search` items carry `page` and `box {x, y, w, h}` in page fractions or `null`.
- [ ] Every new route is profile-scoped; tests prove isolation across profiles and accounts and gate-closed absence.
- [ ] Revision `0020_collection_rules` is the head and matches the models.
- [ ] Per-skin difference: none on the server. Cinematic uses `sort=-last_read_at`, `-new_count`, `new_only`, `rules`, `preview_covers` and `preview_ambient_duo` (plates), `enrichment` (DETAILS credits), `page`/`box` (subtitled stills); Glass uses the same library query mapping plus `series_count` (Manage tags), `created_at` ("Recently created") and the member order `PUT` (Reorder); both use `repoint`, `manual` and `DELETE /reader/progress`.
- [ ] No UI changes: `git diff --stat -- frontend mobile` is empty, so reduced-motion, keyboard access and 44 pt hit targets are unaffected by construction.
- [ ] The full backend suite passes with the backend-01 pass count plus the new tests; nothing that passed before fails.

## Verification

```bash
cd /srv/manhwamaniacs/dev/ManhwaManiacs/backend
free -m
.venv/bin/python -m pytest -q --no-header tests/test_library_extensions.py tests/test_series_enrichment.py tests/test_ocr_search_query.py tests/test_ocr_scope.py tests/test_library_endpoints.py tests/test_audit_mature_collections.py tests/test_progress_db.py tests/test_profile_isolation.py tests/test_migrations_alembic.py
free -m
timeout 1800 .venv/bin/python -m pytest -q --no-header
```

Web and mobile suites are not run: `git diff --stat -- frontend mobile` must print nothing. Their baseline commands, for the record: `npm run lint` and `npm run build` in `frontend/`; `/srv/manhwamaniacs/dev/flutter/bin/flutter analyze` and `/srv/manhwamaniacs/dev/flutter/bin/flutter test` in `mobile/`.

## RAM guard

`free -m` before every pytest run and before `dev_stack.sh restart`; stop and report under 1024 MB available. Subagents run tests one at a time: never two pytest processes at once.

## Git

- Branch `feat/vps-slim-source-native`; one commit per item (A to F, then proof), pushed after each: `git push origin feat/vps-slim-source-native`.
- Suggested subjects: `feat(backend): manual progress and mark unread`, `feat(backend): repoint a follow to another source`, `feat(backend): collection rules, previews and member order`, `feat(backend): library tags, tag filter and server-side sorts`, `feat(backend): series enrichment from AniList`, `feat(backend): OCR search page and box`, `docs(redesign): backend-02 proof`.
- Stage explicit paths only. No Claude or AI attribution (no `Co-Authored-By`, no "generated with" line). Never commit secrets, `.claude/`, `backend/.venv/` or dev data.

## Never

- Never edit `backend/connectors/`.
- Never touch production containers, `/srv/manhwamaniacs/app` or `/srv/manhwamaniacs/data`.

## Report back

1. Done items A to H with commit SHAs.
2. Backend test counts before and after, and the new test names.
3. Proof path `docs/redesign/proof/backend-02/` and its files (no screenshots: no screen changes).
4. Open issues, and a note for backend/09: the member order `PUT` must answer 403 `forbidden` to shared-shelf members once shelves are shared.

Next prompt file in the series: `docs/redesign/prompts/web/05-cinematic-primitives-overlays-controls-states.md`. Next file in the backend track: `docs/redesign/prompts/backend/03-stats-streaks-annual-listen-sessions.md`.
