# Backend 06: page tints, panel reports and novel audio fields

## Goal

Two reader extras of new feature 4 (page-tinted chrome and the panel-by-panel guided view) run their image work on the **clients**: the web samples a decoded page in a Web Worker, Flutter in a `compute()` isolate, because the shared VPS image proxy must never decode and analyse chapter pages (cinematic §2.1.5, §9.4.3, §15.10 S1 and S11; glass §15.10 G6 and G14). The backend's job is only to **remember what clients report** so the next reader of the same chapter, on any profile or device, gets the tint and the panel boxes in the manifest from frame 0. This step adds `POST /reader/page-tints` and `POST /reader/panels` (stored per page identity, unknown pages ignored), `pages[].tint`, `pages[].panels` and `panels_ready` in every manifest (single and bulk), and `GET /reader/panels` for downloaded chapters. It also gives the owner's Audiobook sheet what `RE-VOICE` needs: `chapters[].rendered_at` and `cast_changed_at` on `GET /novels/audio/series`, with the existing `force` flag on narrate requests proven by tests, and it closes an 18+ gap on that endpoint. Everything is additive.

## Precondition: record the sign-off (before any code; never ask and wait)

This step implements amendments that the design contracts mark **sign-off** (cinematic §15.10 S1 and S11, glass §15.10 G6 and G14): per-page tint and panel detection move from the backend (as `stack-decision.md` §2.6 item 2 says) to the clients, and the backend only caches client reports. The owner already decided both: cinematic §15.10's **Owner calls** paragraph lists "Per-page tint placement: S1 above. Panel detection placement: S11 above.", and glass G6 and G14 say Cinematic's sign-off covers both skins. This step runs first of the three steps that record it (`backend/06` at plan order 31, then `web/12` and `mobile/12`), so it writes the record in the exact line format those two steps look for, and they cite it instead of writing their own:

1. `grep -n "^S1 \|^S11 \|^G6 \|^G14 " docs/redesign/signoffs.md` (the file may not exist). If all four lines are there, cite them in the report and change nothing.
2. Otherwise create `docs/redesign/signoffs.md` if needed with the heading `# Owner sign-offs` and one blank line, and append whichever of these four lines is missing, with today's date in place of `YYYY-MM-DD`:
   ```text
   S1 — per-page tint computed on the client, backend caches client reports (cinematic §15.10 owner call) — recorded YYYY-MM-DD by backend/06
   S11 — panel detection computed on the client, backend caches client reports (cinematic §15.10 owner call) — recorded YYYY-MM-DD by backend/06
   G6 — Glass page samples on the client, covered by S1 (glass §15.10 G6) — recorded YYYY-MM-DD by backend/06
   G14 — Glass panel detection on the client, covered by S11 (glass §15.10 G14) — recorded YYYY-MM-DD by backend/06
   ```
3. Commit that file alone (`git add docs/redesign/signoffs.md && git commit -m "docs(redesign): record S1 S11 G6 G14 sign-off"`), push, and continue. The owner can reverse the call later; reversing it is a new plan step, not something this session decides.

## Read first

1. `docs/redesign/prompts-plan.json`, the entry whose `path` is `docs/redesign/prompts/backend/06-reader-tints-panels-novel-audio.md` (binding scope).
2. `docs/redesign/cinematic/DESIGN.md`:
   - §2.1.5 Ambient colour: the "Where each colour is computed" table (row **Reader page (cache)**), **Why page tint is client-side**, **The page seed picker**, **Greyscale rules**.
   - §9.4.3 Panel-by-panel guided view (**Detection**, **Rule**, **Parity**, **Cache**, **States**) and §9.4.4 page-tinted chrome (**Source**).
   - §8.16.5 Voices and the cast (the `RE-VOICING` row state and the `Re-narrate 38 chapters` footer), §8.16.8 Audiobook (the `RE-VOICE` quick pick: "selects the narrated chapters whose `rendered_at` is older than the book's `cast_changed_at`", `force: true`, `priority` 0 and 9).
   - §15.5 rows `pages[].tint`, `pages[].panels`, `GET /novels/audio/series gains …`; §15.6 (page-tint sampling at most every 600 ms, panel detection at 360 px one page ahead, so the proxy does no colour or panel work); §15.10 S1 and S11.
3. `docs/redesign/glass/DESIGN.md`: §9.4.3 Guided view (**Data**: "A manifest's `pages[].panels` is used first when present; on chapter exit the engine posts `POST /reader/panels`"), §9.4.4 page-tinted chrome (**Source**: "The manifest's `pages[].tint` … paints first"), §15.5 rows `pages[].tint + POST /reader/page-tints`, §15.10 G6 and G14.
4. `docs/redesign/stack-decision.md` §2.6 item 2 (what S1/S11 amend), and `docs/redesign/inventory/00-decisions.md` (new feature 4: panel-by-panel guided view and reader chrome tinted by dynamic colour from the current page; flagship-only, no degraded fallbacks).
5. `docs/redesign/inventory/capabilities.md` §1 (identity, the 18+ gate is absence, `X-Profile-Id`), §13 (the manifest and the bulk manifest), §16.4 (the image proxy: nothing is stored for pages), §19.3 and §19.4 (narration, voices, casting).
6. `docs/redesign/00-baseline.md` and `docs/redesign/proof/backend-00/pytest-baseline.txt`.
7. Code: `backend/routes/reader.py` (the manifest routes, `ProgressRequest`, the `require_profile_context` writes, `GET /reader/progress/series` and its gate docstring), `backend/services/reader_service.py` (`manifest`, `manifest_batch`, `_assemble`, the "byte-identical per-chapter payloads" rule), `backend/services/browse_service.py` (`ensure_visible`, `get_chapter_pages`, `_serialize_page`), `backend/services/source_cache_service.py` (`_series_key_hides`), `backend/routes/sources.py` (`get_source_page_image`, `_etag_for`: the served-bytes ETag depends on `w` and `Accept`, and the server keeps no page bytes), `backend/routes/novels.py` (`get_novel_series_audio`, `AudioRenderRequest.force`, `request_novel_audio`, `/cast`, `/cast/alias`, `/narrator`, `OWNER_ONLY`), `backend/services/chapter_audio_store.py` (`rendered_chapters`, `chapter_paths`), `backend/services/novel_render_queue.py` (`enqueue` and its `force` rule), `backend/services/novel_attribution_service.py` (`bump_cast_version`, `set_narrator_voice`, `correct_cast_member`, `merge_alias`), `backend/database/models.py` (`NovelSeriesCastState`), `backend/core/cache_tables.py`, `backend/tests/test_reader_manifest.py`, `test_reader_manifest_bulk.py`, `test_reader_manifest_gate_depth.py`, `test_novel_render_queue.py`, `test_novel_audio_formats.py`, `test_migrations_alembic.py`, `backend/tests/conftest.py`, `backend/tests/_fakes.py`.

## Track rule (applies to every `backend/*` prompt)

- Work only in `backend/` (never `backend/connectors/`) plus `docs/redesign/proof/backend-06/` and the sign-off line in `docs/redesign/signoffs.md`. This step touches no `ops/`, `frontend/` or `mobile/` file.
- Stage only the paths you changed, by name. Never `git add -A` or `git add .`.
- Alembic revisions continue after the newest file in `backend/alembic/versions/`; ids at most 32 characters.
- Every endpoint is profile-scoped. The 18+ gate is applied when **serving**, never when storing.
- Changes are additive: responses only gain fields, and a new parameter's default keeps today's behaviour.
- Tests run with `backend/.venv/bin/python -m pytest -q --no-header` from `backend/`.

## Preconditions (after the sign-off; stop and report if one fails)

1. Branch is `feat/vps-slim-source-native`; `backend/.venv/bin/python -m pytest --version` prints `pytest 9.1.1`.
2. `grep -rn "page-tints\|reader/panels" backend/routes` finds nothing (this step has not run before).
3. `free -m`: `available` is 1024 or more.

## Skills

- `superpowers:writing-plans` first: the plan goes to `docs/redesign/proof/backend-06/plan.md`.
- `superpowers:executing-plans` to run it inline (one migration, shared reader code: no subagent fan-out).
- `superpowers:test-driven-development`: failing tests first.
- `superpowers:verification-before-completion` before claiming done.
- `impeccable`, `taste-skill:taste-skill` and `frontend-design` are UI skills and are not used: this step has no UI.

## Scope, item by item

### A. Baseline

`cd backend && free -m && timeout 1800 .venv/bin/python -m pytest -q --no-header 2>&1 | tail -25 > ../docs/redesign/proof/backend-06/pytest-before.txt`; list pre-existing failures under `PRE-EXISTING FAILURES:` and leave them alone.

### B. What "per page ETag" means here (decided; write it in the model's docstring)

The image proxy's `ETag` is a hash of the **served bytes**, which change with `?w=` and `Accept` (WebP or JPEG), and the server stores no page bytes, so it cannot know a byte ETag without fetching and decoding the page, which is exactly what S1 and S11 forbid. The page identity the server does know without touching any image is the page's proxy URL in the manifest (`pages[].url`, for example `/sources/mangadex/pages/<page_key>/image`), which embeds the upstream page key: when a source re-uploads a page it gets a new key, so a stored tint or panel list of the old image is never attached to the new one. So:

`page_etag = sha256(page_url.encode("utf-8")).hexdigest()[:32]`

One helper, `page_etag(url: str) -> str`, in `backend/services/page_annotations.py`, used by every write and every read.

### C. Migration and model (one revision after the current head, for example `0024_reader_page_annotations`)

Table `reader_page_annotations`, a shared cache of client reports (not personal data: a page's colour and panel layout are the same for every reader, cinematic §2.1.5 "in the next manifest for any profile"):

| Column | Type | Notes |
|---|---|---|
| `id` | Integer PK | |
| `source_id` | `String(64)` not null | |
| `series_key` | `String(512)` not null | |
| `chapter_key` | `String(512)` not null | canonical (`fully_unquote`) |
| `page_number` | Integer not null | the manifest's `pages[].number` |
| `page_etag` | `String(32)` not null | B |
| `page_count` | Integer not null | the chapter's page count when reported (for `panels_ready` without a manifest) |
| `tint` | `String(7)` nullable | `#RRGGBB`, upper case |
| `panels` | Text nullable | JSON list of `{x, y, w, h}`; `[]` means "analysed, no panels found" |
| `updated_at` | DateTime not null | |

Unique constraint `uq_reader_page_annotations_page (source_id, series_key, chapter_key, page_etag)`; index `ix_reader_page_annotations_chapter (source_id, series_key, chapter_key)`. ORM class `ReaderPageAnnotation` matching exactly (`test_alembic_head_matches_models`). Add `"reader_page_annotations"` to `CACHE_TABLES` (a restore comes up cold and clients report again; `ops/vps/backup-db.sh` reads that tuple, so no ops edit). `tests/test_migrations_alembic.py`: `_HEAD`, `_REVISIONS`, `_EXPECTED_TABLES`. Mark the table in the model docstring `# ponytail: no pruning; add an updated_at sweep if it passes 1M rows` (a few thousand chapters for 2 to 3 readers is tens of thousands of rows).

### D. `POST /reader/page-tints` (`backend/routes/reader.py`; logic in `backend/services/page_annotations.py`, new)

`dependencies=[Depends(require_profile_context)]` (400 `profile_required` without `X-Profile-Id` on an account with profiles, 404 `profile_not_found` for another account's profile, the house rule). Body:

```json
{"source_id": "mangadex", "series_key": "…", "chapter_key": "…", "tints": [{"page": 1, "hex": "#3A5F8C"}, {"page": 2, "hex": null}]}
```

- `source_id` 1 to 64, `series_key` and `chapter_key` 1 to 512 characters; `tints` 1 to 500 entries; `page` ≥ 1; `hex` matches `^#[0-9A-Fa-f]{6}$` or is `null` (a greyscale page: the client's picker returns `null`, cinematic §2.1.5; a `null` entry is accepted and ignored, because a greyscale page keeps the previous page's tint on the client and must never be stored as a colour). Anything else is 422.
- Resolve the chapter's page list through `ReaderService.manifest(source_id, series_key, chapter_key)`, the same code path the manifest route uses, which applies this caller's gate first (`ensure_visible`) and answers 404 exactly as the manifest does for a gated or unknown source or chapter; that 404 propagates and nothing is stored. Any other `AppError` from resolving the page list (an upstream failure) answers 204 and stores nothing: the post is fire and forget (cinematic §2.1.5), and the next reader reports again. The connector serves the page list from its in-memory page cache when the reader has just opened the chapter; mark the call `# ponytail: may refetch the chapter's page list when the connector cache has evicted it; add a stored page index if that shows up in the health log`.
- For each entry with a `hex` whose `page` exists in the resolved list: upsert on `(source_id, series_key, chapter_key, page_etag(url))`, set `tint` (upper-cased), `page_number`, `page_count`, `updated_at`. Entries for page numbers not in the list are ignored (cinematic §15.5 "unknown pages are ignored"). One transaction.
- Answer `204` with no body.

### E. `POST /reader/panels`

Same dependency, identity fields and resolution as D. Body `pages`: 1 to 500 entries of `{"page": int ≥ 1, "panels": [{"x": float, "y": float, "w": float, "h": float}]}`, each panel in page fractions (cinematic §9.4.3: "Panels are `{x, y, w, h}` in page fractions, in reading order"), with `0 ≤ x, y ≤ 1`, `0 < w, h ≤ 1`, `x + w ≤ 1.0001`, `y + h ≤ 1.0001`, at most 64 panels per page; an empty list is valid and stored as `[]` (the "whole page" result, so no client analyses that page again). Panels are stored in the order sent (reading order is the client's rule, including right-to-left). Unknown pages ignored; `204`.

### F. Manifests carry the reports

In `backend/services/reader_service.py`, both `manifest` and `manifest_batch` attach the stored reports through one function, so the two stay byte-identical per chapter:

- `pages[i].tint` (`"#RRGGBB"`) is present only when a row with that page's `page_etag` has a tint.
- `pages[i].panels` (a list, possibly empty) is present only when that row has `panels`.
- Top level `panels_ready: bool`: true when every page of the chapter has stored `panels` (including `[]`), else false.
- One query per single manifest, and one query for the whole window in `manifest_batch` (`WHERE source_id = ? AND series_key = ? AND chapter_key IN (…)`), never one per chapter or page.
- Nothing else in the manifest changes; a chapter with no rows is identical to today's payload plus `panels_ready: false`.

### G. `GET /reader/panels?source=&series=&chapter=`

For a downloaded chapter whose local manifest copy has no panels yet (glass §9.4.3 "Downloaded chapters keep their panels in the local manifest copy"): stored rows only, no page-list resolution and no upstream call. Gate exactly as `GET /reader/progress/series` does: `BrowseService.ensure_visible(source)` first (404 `source_not_found` for a gated or unknown source); a series that is 18+ on a general source (`SourceCacheService._series_key_hides`) answers the empty result. Response:

```json
{"source_id": "…", "series_key": "…", "chapter_key": "…", "panels_ready": true, "pages": [{"page": 1, "panels": [{"x": 0.0, "y": 0.0, "w": 1.0, "h": 0.31}]}]}
```

`pages` holds every stored page with `panels` (ordered by `page_number`); `panels_ready` is true when that count equals the rows' `page_count`. The client matches entries to its local manifest by page number. No `tint` here: tints travel in manifests only.

### H. The image proxy stays dumb

No code path added here imports Pillow, decodes an image, or calls `BrowseService.resolve_page_image` or `resolve_series_cover`. `backend/routes/sources.py` is not edited. A test enforces it (section K).

### I. `GET /novels/audio/series` gains `rendered_at` and `cast_changed_at`, and the 18+ gate

1. `chapters[].rendered_at`: the ISO-8601 UTC time (`YYYY-MM-DDTHH:MM:SSZ`) of the chapter audio file's modification time. `complete` replaces the file atomically, so its mtime is the render time. Add a keyword to `chapter_audio_store.rendered_chapters(..., with_mtime: bool = False)` that adds `"rendered_at": st_mtime` from the `stat()` it already makes (no second stat); the default keeps its return shape exactly as `test_novel_audio_formats.py` asserts it. The route passes `with_mtime=True` and formats the value.
2. Top-level `cast_changed_at`: the latest owner change to the book's cast (`POST /novels/cast`, `/novels/cast/alias` or `/novels/narrator`), ISO-8601 UTC, or `null` when the cast was never changed by hand. `novel_series_cast_state` rows are written only by `bump_cast_version` and `set_narrator_voice`, which only those three routes reach, and both stamp `updated_at`: so `cast_changed_at = state.updated_at` for the book's row, and no new column is needed. Verify with `grep -rn "NovelSeriesCastState\|bump_cast_version\|set_narrator_voice" backend/services backend/routes` before relying on it; if anything else writes that row, add a nullable `cast_changed_at` column to it in this step's migration, set it in those two helpers, and read it instead.
3. The endpoint had no 18+ gate. Add it the way `GET /reader/progress/series` gates: `BrowseService.ensure_visible(source)` first (404 for a gated or unknown source); a series that is 18+ on a general source answers `{source_id, series_key, chapters: [], narratable: [], can_render, cast_changed_at: null}`. Inject the browse service with its usual dependency.
4. `RE-VOICE` (cinematic §8.16.8) is a client rule on these two fields: narrated chapters whose `rendered_at` is older than `cast_changed_at`. The server adds no other field.

### J. Narrate requests accept `force`

`AudioRenderRequest.force` already exists and `enqueue` already honours it (`test_force_renders_a_chapter_again`, `test_force_still_cannot_queue_a_chapter_twice`). Do not change it. Prove the Audiobook sheet's request shape with one more test: a book with two narrated chapters (one rendered before a `POST /novels/narrator`, one after) and one un-narrated chapter; the client's `RE-VOICE` selection (from I) plus the un-narrated one, sent in one `POST /novels/audio/render {chapter_keys: [...], force: true, priority: 0}`, queues all three; the same request with `force: false` queues only the un-narrated one and skips the others with `already_rendered`; `priority: 9` is stored on the job.

### K. Tests (write them first)

- `backend/tests/test_reader_page_annotations.py` (HTTP through `client` and `as_user`; the connector faked with `FakeBrowse`):
  1. Tints: a POST for pages 1 to 3 of a 3-page chapter stores three rows; the next `GET /reader/chapter/manifest` for **another profile of another account** carries `pages[i].tint` for all three (the shared cache); a POST with page 9 stores nothing for it and still answers 204; `hex: null` stores nothing; `#3a5f8c` is stored as `#3A5F8C`.
  2. Panels: stored lists round-trip into `pages[i].panels` in order; `[]` is stored and served as `[]`; `panels_ready` is false with 2 of 3 pages and true with 3 of 3; a panel with `x + w = 1.2`, `w = 0`, or 65 panels is 422.
  3. Page identity: after the fake source re-keys page 2 (a new URL), the manifest no longer carries the old tint or panels for page 2 and still carries them for pages 1 and 3.
  4. Bulk: `POST /reader/chapters/manifest` for a window of 3 chapters, two with reports, returns per-chapter manifests equal to the single-chapter manifests (tints, panels, `panels_ready` included), and the window costs one annotations query (count with a `before_cursor_execute` listener).
  5. `GET /reader/panels`: returns stored pages with `panels_ready`; makes no connector call (`FakeBrowse` raising on any fetch); 404 for a gated source.
  6. Profile scoping: both POSTs without `X-Profile-Id` on an account with profiles → 400 `profile_required`; with another account's profile id → 404 `profile_not_found`.
  7. 18+: with the gate closed, both POSTs for a chapter on a mature source → 404 and nothing stored; the manifest and `GET /reader/panels` → 404; with the gate open, the same calls succeed.
  8. No image work: with `BrowseService.resolve_page_image` and `resolve_series_cover` monkeypatched to raise, every call in this file still succeeds.
  9. Upstream failure: `get_chapter_pages` raising a non-404 `AppError` makes both POSTs answer 204 and store nothing.
- `backend/tests/test_novel_audio_series_fields.py`: `rendered_at` equals the file mtime in UTC; `cast_changed_at` is `null` before any change and moves forward after each of `POST /novels/cast`, `/cast/alias` and `/narrator` (owner); a gated profile gets 404 for a mature novel source; `rendered_chapters` without `with_mtime` returns exactly `{"bytes", "has_timing"}` per chapter; the J request cases.
- `backend/tests/test_migrations_alembic.py`: the new head and table.

## File layout

| Path | Change |
|---|---|
| `docs/redesign/signoffs.md` | the sign-off line (precondition) |
| `backend/alembic/versions/00NN_reader_page_annotations.py` | new |
| `backend/database/models.py` | class `ReaderPageAnnotation` (and only if I.2's grep finds another writer, `NovelSeriesCastState.cast_changed_at`) |
| `backend/core/cache_tables.py` | `"reader_page_annotations"` |
| `backend/services/page_annotations.py` | new: `page_etag`, validation helpers, `store_tints`, `store_panels`, `annotations_for(db, source_id, series_key, chapter_keys)`, `attach(manifest, rows)` |
| `backend/services/reader_service.py` | attach in `manifest` and `manifest_batch` |
| `backend/routes/reader.py` | `POST /reader/page-tints`, `POST /reader/panels`, `GET /reader/panels` |
| `backend/services/chapter_audio_store.py` | `with_mtime` |
| `backend/routes/novels.py` | `rendered_at`, `cast_changed_at`, the gate on `/audio/series` |
| `backend/tests/test_reader_page_annotations.py`, `test_novel_audio_series_fields.py` | new |
| `backend/tests/test_migrations_alembic.py` | updated |
| `backend/docs/reader-reports-api.md` | new: the three reader endpoints, the manifest additions, the page identity rule of B, the two novel audio fields and the `RE-VOICE` rule, with request and response examples |
| `docs/redesign/proof/backend-06/` | `plan.md`, `pytest-before.txt`, `pytest-after.txt`, the captures of L |

### L. Proof (dev stack; never production)

`free -m`, `backend/scripts/dev_stack.sh reset`. For Riya's newest continue-reading chapter (read its `source_id`, `series_key`, `chapter_key` from `GET /library/continue-reading`), save into `docs/redesign/proof/backend-06/`:

- `manifest-before.json` (`GET /reader/chapter/manifest?source=…&series=…&chapter=…`: no tints, `panels_ready: false`),
- `page-tints.txt` (the `204` of a `POST /reader/page-tints` for pages 1 and 2 with `#3A5F8C` and `#8C3A3A`),
- `panels.txt` (the `204` of a `POST /reader/panels` giving every page one full-page panel `{x: 0, y: 0, w: 1, h: 1}`),
- `manifest-after.json` (the same manifest: two tints, every page's panels, `panels_ready: true`),
- `manifest-after-aarav.json` (the same manifest as Aarav: the shared cache serves the same tints),
- `reader-panels.json` (`GET /reader/panels`),
- `novel-audio-series.json` (`GET /novels/audio/series` for Riya's first novel follow: `cast_changed_at` null and no rendered chapters on the dev stack, which has no render worker).

Stop the dev stack afterwards. No web screen changes here, so there are no Playwright screenshots; these files are the proof.

## Acceptance criteria

- [ ] `docs/redesign/signoffs.md` holds the four lines `S1 …`, `S11 …`, `G6 …` and `G14 …` in the precondition's format (committed on their own before any code, or already present and cited).
- [ ] `pytest-after.txt` shows every test that passed in `pytest-before.txt` still passing, plus the new files.
- [ ] `POST /reader/page-tints` and `POST /reader/panels` validate as D and E, resolve pages through the gated manifest path, ignore unknown pages and `null` tints, store per page identity (B), and answer 204 (404 only for a gated or unknown source or chapter).
- [ ] Every manifest, single and bulk, carries `pages[].tint` and `pages[].panels` when stored and `panels_ready` always, with one annotations query per manifest or window; bulk and single stay equal per chapter.
- [ ] `GET /reader/panels` serves stored panels with `panels_ready` and never calls a connector.
- [ ] A re-keyed page never inherits the old image's tint or panels.
- [ ] Reports from one profile are served to every profile that may see the chapter (a shared cache), and to none whose gate hides it.
- [ ] No code added in this step decodes an image or calls the image proxy's resolvers; `backend/routes/sources.py` is unchanged.
- [ ] `GET /novels/audio/series` carries `chapters[].rendered_at` and `cast_changed_at`, is gated like `GET /reader/progress/series`, and keeps every existing field; `rendered_chapters()`'s default return shape is unchanged.
- [ ] `force` on `POST /novels/audio/render` re-queues narrated chapters and never double-queues an in-flight one (existing tests plus J).
- [ ] Per-skin: both skins' reader engines post the same two reports and read the same manifest fields (cinematic §9.4.3 is the contract for both; glass §9.4.3 says so); Cinematic's chrome derives `page.tint`/`page.light` and Glass's derives its OKLCH-clamped tint from the same stored hex. The Audiobook `RE-VOICE` pick is Cinematic's (§8.16.8); Glass reads the same two fields. Nothing here branches on the skin.
- [ ] UI rules (reduced motion, keyboard access, 44 pt targets) belong to the reader steps (`web/12`, `web/23`, `web/44` and their mobile twins). This step serves them by making the tint and panels available from the manifest before any sampling, so a reduced-motion client can apply the stored tint at once without a transition, and guided view can open framed on the first panel.
- [ ] `backend/docs/reader-reports-api.md` matches the implementation.
- [ ] `git show --name-only --format= <hash> -- frontend mobile ops backend/connectors backend/routes/sources.py` for each of your own commits (never a branch or range diff: parallel sessions commit on the same branch) prints nothing.

## Verification

One heavy command at a time, `free -m` before each; stop under 1024 MB available.

```bash
cd /srv/manhwamaniacs/dev/ManhwaManiacs/backend
free -m
.venv/bin/python -m pytest -q --no-header tests/test_reader_page_annotations.py tests/test_novel_audio_series_fields.py tests/test_reader_manifest.py tests/test_reader_manifest_bulk.py tests/test_reader_manifest_gate_depth.py tests/test_novel_render_queue.py tests/test_novel_audio_formats.py tests/test_migrations_alembic.py tests/test_audit_backup_cache_tables.py
free -m
timeout 1800 .venv/bin/python -m pytest -q --no-header 2>&1 | tail -25 > ../docs/redesign/proof/backend-06/pytest-after.txt
cat ../docs/redesign/proof/backend-06/pytest-after.txt
```

Web and mobile are not run because nothing under `frontend/` or `mobile/` changes (`git show --name-only --format= <hash> -- frontend mobile` for each of your own commits (never a branch or range diff: parallel sessions commit on the same branch) prints nothing). Their baseline commands, if you ever touch them: `npm run lint` and `npm run build` in `frontend/`; `/srv/manhwamaniacs/dev/flutter/bin/flutter analyze` and `/srv/manhwamaniacs/dev/flutter/bin/flutter test` in `mobile/`.

## RAM guard

Production and five Minecraft bots share this box (7,746 MB). `free -m` before each pytest run and before starting the dev stack; stop and report if `available` is under 1024 MB. Never run two heavy commands at once; never run `next build` here.

## Git

- Branch `feat/vps-slim-source-native`; commit small and often and push after each: `git push origin feat/vps-slim-source-native:master`.
- Suggested commits: (0) `docs(redesign): record S1 S11 G6 G14 sign-off` (when a line was missing), (1) `test(reader): page tint, panel report and novel audio field cases` (failing), (2) `feat(backend): reader_page_annotations cache table`, (3) `feat(reader): page-tint and panel reports`, (4) `feat(reader): manifests carry tints, panels and panels_ready`, (5) `feat(reader): GET /reader/panels`, (6) `feat(novels): rendered_at, cast_changed_at and the 18+ gate on audio series`, (7) `docs(backend): reader reports API note`, (8) `docs(redesign): backend-06 proof`.
- Stage by explicit path only. No Claude or AI attribution anywhere (no `Co-Authored-By`, no "generated with" line, no AI author). Never commit secrets, `.env`, `.claude/`, `backend/.venv/` or dev data.
- No frontend change, so no `next build` before pushing; if `git status` shows a frontend change you made, stop.

## Never

- Never edit `backend/connectors/` or `backend/routes/sources.py`; never touch production containers, `/srv/manhwamaniacs/app` or `/srv/manhwamaniacs/data`.
- Never decode, sample or analyse a page image on the server, and never fetch a page image to fill a report.

## Report back

Reply with:
1. The sign-off status (found and cited, or recorded today) and the commit SHA of the sign-off lines.
2. Done items B to L, each with its commit SHA; the revision id and the head it follows.
3. Whether I.2's grep found another writer of `novel_series_cast_state` (and so whether a column was added).
4. Backend test counts before and after, and the new test files with their case counts.
5. The proof folder `docs/redesign/proof/backend-06/` and its files (no screenshots in this step).
6. Open issues, including how often a page-tints POST had to refetch a page list on the dev stack (from the dev backend log).

Next prompt file in the series: `docs/redesign/prompts/web/09-cinematic-library-shelf-browse.md`. Next file in the backend track: `docs/redesign/prompts/backend/07-media-routes-and-install-page.md`.
