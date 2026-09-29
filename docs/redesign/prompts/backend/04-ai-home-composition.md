# Backend 04: GET /home composition for the AI home (new feature 1, part 1)

## Goal

Both skins open on one server-composed home feed. Cinematic renders it as "Tonight" (a cover story with a typed headline, Also in this issue, numbered rails, the numbers teaser) and Glass renders it as Home (greeting, spotlight pager, AI rails), but neither client decides what goes on the page: the backend does, once, for both (stack-decision §2.6). This step builds `GET /home?content_kind=manga|novel&tz_offset_minutes=`, which picks tonight's cover story by the five priority rules of cinematic §9.1.2, writes its headline and deck, composes Also in this issue and every section type of cinematic §9.1.7 that does not need the Circle (`first_picks`, `continue`, `new_this_week`, `almost_there`, `where_were_we`, `picked`, `because`, `popular`, `sources`, `genres`, `numbers`), puts the recap availability object of cinematic §9.1.5 on the cover, on `continue` and `where_were_we` items and on every `GET /library/continue-reading` row, falls back to the 3 healthiest non-18+ sources for a profile with no pins, and caches the composed payload per profile for 10 minutes. The AI (the existing DeepSeek client) only writes the editorial lines (the cover deck and the `why` lines) in a background job, through a new "desk" ledger, and every AI-backed section has a deterministic non-AI fallback, so the page is never broken when the AI is not configured, over budget or failing. The Circle sections (`sent_to_you`, `circle`, `circle_top`) are spliced in by `backend/08` and `backend/09`; this step leaves the hook for them. Everything is additive: today's web and Flutter clients keep working unchanged.

## Read first

1. `docs/redesign/prompts-plan.json`, the entry whose `path` is `docs/redesign/prompts/backend/04-ai-home-composition.md` (binding scope).
2. `docs/redesign/cinematic/DESIGN.md`:
   - §8.8 Tonight (the whole section: hierarchy, the desktop section table with every section key, Also in this issue **Selection**, the **States** list: new profile, just onboarded, streak at risk, caught up, AI unavailable, offline, novels mode, stale).
   - §9.1.1 surfaces and entry points; §9.1.2 cover story selection and the headline/deck table (copy every string from it); §9.1.5 only its paragraph **Availability and range** and the **Entry behaviours** paragraph (for what `recap` is used for); §9.1.6 fallbacks; §9.1.7 the backend contract table and the "`GET /home` section items" table; §9.1.8 the AI state vocabulary and the unavailable copy table.
   - §8.0.8 content mode (Manga / Novels); §12.5 voice (numbers under ten spelled out, numerals elsewhere).
   - §15.5 rows `GET /home …`, `Per-profile composed caches`, `GET /home?content_kind= and also[]`, `GET /onboarding/catalog … GET /home falls back to the 3 healthiest non-18+ sources`; §15.10 the owner calls.
3. `docs/redesign/glass/DESIGN.md`: §8.8 Home (the paragraphs on `GET /home`, the greeting's at-risk subline, the spotlight order, the rails list, `?refresh=1` on pull to refresh, the states), §9.1.1 AI rails on Home, §9.1.5 the reason vocabulary, §9.1.6 backend used, §15.5 and §15.6 (both skins read the same `/home`; Glass adds nothing to it except `refresh=1`).
4. `docs/redesign/stack-decision.md` §2.6 (logic that must agree runs on the backend; shared caches gate 18+ on serve).
5. `docs/redesign/inventory/00-decisions.md` (new feature 1: AI home, external AI API only, loading and "AI unavailable" states).
6. `docs/redesign/inventory/capabilities.md` §1 (auth, `X-Profile-Id`, error envelope, the 18+ gate is absence), §8 home strips, §9 recommendations and AI, §10 statistics and streaks, §16.1 sources, health and pins.
7. `docs/redesign/00-baseline.md` and `docs/redesign/proof/backend-00/pytest-baseline.txt` (the backend pass count every later backend step must keep).
8. The earlier backend steps this one builds on: `docs/redesign/prompts/backend/01-cover-ambient-and-palette.md` (the `ambient` and `palette` fields) and `docs/redesign/prompts/backend/03-stats-streaks-annual-listen-sessions.md` (the one streak object). Read their "File layout" sections to find the helpers they added.
9. Code, before writing anything:
   - `backend/routes/library.py` (`continue_reading`, `recently_updated`, `recommendations`, `world_recommendations`, `statistics`).
   - `backend/services/followed_series_service.py`: `continue_reading`, `recently_updated`, `recommendations`, `taste_profile`, `_read_states`, `_visible`, `_scope`, `_progress_scope`, `_gate_open`, `serialize`, `READING_STATUSES`.
   - `backend/services/world_recs.py` (`WorldRecs.recommendations`, `WorldCatalog`, the `why` field is `None` today) and `backend/services/suggestion_service.py` (the ledgers `BUDGET_PATH`, `ACCOUNT_BUDGET_PATH`, `DAILY_CEILING`, `ACCOUNT_DAILY_CEILING`, `ADMIN_RESERVE`, `availability()`, `_complete()`, `_DeadlineTransport`, `TIMEOUT_SECONDS`, the "reader's text is DATA" prompt rule, and the "Never descriptions" rule in `taste_profile`).
   - `backend/services/deepseek_client.py` (`complete_json`, `is_configured`, `spent_today`, the retry on 429) and `backend/services/llm.py`.
   - `backend/services/reading_stats_service.py` and whatever `backend/03` added for the streak (`grep -rn "milestones_seen" backend/services backend/routes`).
   - `backend/services/source_health.py`, `backend/services/source_pin_service.py`, `backend/services/source_cache_service.py` (`get_browse_page`, `_series_key_hides`, `_rating_hides`), `backend/core/connector_directory.py` (`descriptor_for_source`, `content_kind`), `backend/core/content_rating.py`.
   - `backend/services/update_service.py` (`UpdateService._check_one`, the `new_chapters` list), `backend/database/models.py` (`FollowedSeries`, `ChapterProgress`, `ReadingSession`, `ChapterOcr`, `NovelChapterCache`, `UpdateNotification`), `backend/core/cache_tables.py`, `backend/tests/conftest.py` (`as_user`, `make_user`, `make_profile`, `seed_follow`, `client`), `backend/tests/_fakes.py` (`FakeBrowse`), `backend/tests/test_suggestion_service.py` (how the AI is mocked), `backend/tests/test_migrations_alembic.py` (`_HEAD`, `_REVISIONS`, `_EXPECTED_TABLES`).
   - `backend/scripts/README-dev-stack.md` (the dev stack from `backend/00`).

## Track rule (applies to every `backend/*` prompt)

- Work only in `backend/` (never `backend/connectors/`) plus `docs/redesign/proof/backend-04/`. This step touches no `ops/`, `frontend/` or `mobile/` file.
- Stage only the paths you changed, by name. Never `git add -A` or `git add .`: web, mobile and shared sessions commit in the same checkout.
- Alembic revisions continue after the newest file in `backend/alembic/versions/`. Revision ids stay at or under 32 characters (`alembic_version.version_num` is `VARCHAR(32)`).
- Every endpoint is profile-scoped. The 18+ gate is applied when **serving**, never when storing (shared caches too).
- Changes are additive: no field is renamed or removed, no existing response changes shape except by gaining fields.
- Tests run with `backend/.venv/bin/python -m pytest -q --no-header` from `backend/` (CI pins `pytest==9.1.1`).

## Preconditions (check before any edit; stop and report if one fails)

1. `git -C /srv/manhwamaniacs/dev/ManhwaManiacs branch --show-current` prints `feat/vps-slim-source-native`.
2. `backend/.venv/bin/python -m pytest --version` prints `pytest 9.1.1` (the venv `backend/00` created).
3. `backend/00` landed: `grep -n "onboarding_step\|notify_enabled" backend/database/models.py` finds both columns on `ReadingProfile`.
4. `backend/01` landed: `grep -rn "cover_palette" backend/database/models.py` finds the table, and `grep -rn '"ambient"' backend/services` finds the field on continue-reading and followed-series rows.
5. `backend/03` landed: `grep -rn "milestones_seen" backend/services` finds the streak object builder.
6. `grep -rn '"/home"' backend/routes backend/api` finds nothing (this step has not run before).
7. `free -m`: the `available` column reads 1024 or more.

## Skills

- `superpowers:writing-plans` before touching code: write the plan to `docs/redesign/proof/backend-04/plan.md`.
- `superpowers:executing-plans` to run it inline (the steps share one migration and one service, so do not fan out to subagents).
- `superpowers:test-driven-development` for every rule below: write the failing test first.
- `superpowers:verification-before-completion` before claiming anything is done.
- `impeccable`, `taste-skill:taste-skill` and `frontend-design` are for UI and are not used here: this step has no UI. The copy strings you emit are fixed by cinematic §9.1.2, §8.8 and §9.1.8; copy them exactly.

## Scope, item by item

### A. Record the backend baseline

`cd backend && free -m && timeout 1800 .venv/bin/python -m pytest -q --no-header 2>&1 | tail -25 > ../docs/redesign/proof/backend-04/pytest-before.txt`. If anything fails before your change, list it under a line `PRE-EXISTING FAILURES:` in that file and treat it as out of scope.

### B. Migration and models

One revision, numbered after the current head (read `ls backend/alembic/versions | sort | tail -1`; after backends 00 to 03 it is expected to be `0021_…`, so this one is `0022_home_feed`; use the real next number). House style: a module docstring saying what and why, as in `0017_world_catalog_cache.py`.

1. `followed_series.last_new_chapter_at` (`DateTime`, nullable). Backfill in the same `upgrade()`: for every followed row, the newest `update_notifications.created_at` whose `followed_series_id` is that row (`UPDATE followed_series SET last_new_chapter_at = (SELECT MAX(created_at) FROM update_notifications WHERE followed_series_id = followed_series.id)`). `downgrade()` drops the column (batch mode for SQLite).
2. Table `ai_result_cache`, the one cache for every AI answer this redesign stores (this step writes the home editorial; `backend/05` adds similar, tags and recaps):
   - `key` `String(64)` primary key (a SHA-256 hex digest of the logical key, so 512-character series keys never overflow it),
   - `kind` `String(32)` not null (`home_editorial` here; `similar`, `tags`, `recap` later),
   - `profile_id` `Integer` nullable, `ForeignKey("reading_profiles.id", ondelete="CASCADE")` (set only for per-profile answers such as the editorial, so a deleted profile takes its rows with it),
   - `source_id` `String(64)` nullable, `series_key` `String(512)` nullable (for per-series answers, so they can be found and dropped),
   - `payload` `Text` not null (JSON), `model` `String(64)` not null default `""`, `generated_at` `DateTime` not null, `expires_at` `DateTime` not null,
   - indexes `ix_ai_result_cache_expires_at (expires_at)`, `ix_ai_result_cache_series (source_id, series_key)`, `ix_ai_result_cache_profile (profile_id)`.
3. ORM: `FollowedSeries.last_new_chapter_at: Mapped[datetime | None]` and class `AiResultCache` in `backend/database/models.py`, matching the migration exactly so `test_alembic_head_matches_models` stays green.
4. Add `"ai_result_cache"` to `CACHE_TABLES` in `backend/core/cache_tables.py` (it is derived data: backups drop it, a restore comes up cold, and the next compose rewrites it). `ops/vps/backup-db.sh` reads that tuple from the Python file, so no ops edit is needed; `tests/test_audit_backup_cache_tables.py` must stay green.
5. `backend/tests/test_migrations_alembic.py`: set `_HEAD` to the new revision, append its file name to `_REVISIONS`, add `"ai_result_cache"` to `_EXPECTED_TABLES`, and add one test that upgrades a database holding one followed row and two notifications for it (created 3 and 1 days ago) and asserts `last_new_chapter_at` equals the newer one.
6. `backend/services/update_service.py`, `_check_one`: when `new_chapters and known`, set `row.last_new_chapter_at = utcnow()` **before** the notify checks, so it is recorded whether or not `row.notify`, the global switch or the profile's `notify_enabled` allow a notification. One line; the existing sweep tests must pass untouched.

### C. The AI desk (`backend/services/ai_desk.py`, new)

The existing external-API client is `services/deepseek_client.complete_json` (capabilities §9). Every AI call in this redesign goes through it; nothing opens its own HTTP client to an AI provider.

1. Two spending paths, both on `complete_json`:
   - **Asks** (a person's explicit request: Ask, recaps): reuse `SuggestionService` as it is. Recaps in `backend/05` call `SuggestionService._complete()` and read `SuggestionService.availability()`. Do not move or copy the ledger code: `test_suggestion_service.py` monkeypatches `suggestion_service.BUDGET_PATH` and `ACCOUNT_BUDGET_PATH`.
   - **Desk** (background editorial work nobody asked for by name: the home editorial here, similar `why` lines and suggested tags in `backend/05`): a third ledger so it can never eat a reader's asks or the novel attribution budget. Constants in `ai_desk.py`: `DESK_DAILY_CEILING = 100` (requests per UTC day, server-wide), `DESK_BUDGET_PATH = SETTINGS_PATH.parent / "deepseek-desk-usage.json"`, `DESK_MAX_TOKENS = 20000` (the same reasoning-token floor `suggestion_service.MAX_TOKENS` documents), `DESK_TEMPERATURE = 0.4`, `DESK_TIMEOUT_SECONDS = 90.0` with `suggestion_service._DeadlineTransport(DESK_TIMEOUT_SECONDS)` as the transport.
2. `desk_availability() -> {"available": bool, "reason": "ok" | "not_configured" | "budget_exhausted" | "rate_limited" | "ai_failed"}`: local and free. `not_configured` when `deepseek_client.is_configured()` is false; `budget_exhausted` when `deepseek_client.spent_today(DESK_BUDGET_PATH) >= DESK_DAILY_CEILING`; `rate_limited` or `ai_failed` when the last desk call failed that way less than 10 minutes ago (an in-process record, `_LAST_FAILURE = (reason, monotonic_time)` under a `threading.Lock`); otherwise `ok`.
3. `desk_complete(system: str, message: str) -> Completion`: calls `complete_json(message, system=system, max_tokens=DESK_MAX_TOKENS, temperature=DESK_TEMPERATURE, timeout=DESK_TIMEOUT_SECONDS, ceiling=DESK_DAILY_CEILING, budget_path=DESK_BUDGET_PATH, transport=…)`. It raises `DeskUnavailable(reason)` (a small exception class with a `reason` attribute) for `LLMNotConfigured` → `not_configured`, `LLMBudgetExhausted` → `budget_exhausted`, the new `LLMRateLimited` → `rate_limited`, any other `LLMError` → `ai_failed`, and records the failure for item 2. Never log the upstream body (the client already redacts; keep it that way).
4. Rate limit as its own error: add `class LLMRateLimited(LLMError)` to `backend/services/llm.py` and, in `deepseek_client.complete_json`, raise it instead of the plain `DeepSeekError` when the final attempt's status is 429 (message `"DeepSeek returned HTTP 429"`, unchanged text). It subclasses `LLMError`, so every existing `except LLMError` still catches it and `test_suggestion_service.py` stays green.
5. `run_in_background(key: str, job: Callable[[], None]) -> bool`: single-flight per key (a module-level `set` of running keys under a `threading.Lock`); starts a daemon `threading.Thread` and returns `True`, or returns `False` when that key is already running. The job opens its own `SessionLocal()` (never the request's session, which is closed when the response is sent). Tests replace it: `monkeypatch.setattr(ai_desk, "run_in_background", lambda key, job: (job(), True)[1])`.
6. Cache helpers on `ai_result_cache`: `cache_key(*parts: str) -> str` (SHA-256 hex of `"\x1f".join(parts)`), `cache_get(db, key) -> row | None` (ignores rows whose `expires_at` has passed), `cache_put(db, key, *, kind, payload, model, expires_at, profile_id=None, source_id=None, series_key=None)` (upsert with `db.merge`, then delete every row whose `expires_at` is older than 7 days in the same commit, the pruning pattern `WorldCatalog._write` uses).

### D. Recap availability (`backend/services/recap_service.py`, new; `backend/05` adds the endpoint and the stream)

`RecapService(db, library: FollowedSeriesService, suggest: SuggestionService)`, method `availability(source_id, series_key, to_key, *, scope="series", shape="prose") -> dict` returning exactly cinematic §9.1.5's object:

```json
{"available": true, "reason": "ok", "range": {"from_key": "c131", "to_key": "c142", "from_number": 131, "to_number": 142}, "est_seconds": 104, "cached": false}
```

Rules (cinematic §9.1.5 **Availability and range**, made exact):

1. **Range.** This profile's `chapter_progress` rows for the series with `is_completed` true and a `chapter_number` lower than the number of `to_key` (the number comes from the profile's progress row for `to_key`, else from the followed row's `known_chapters`, else from `source_series_cache`'s chapter list; if `to_key` has no number anywhere the range is empty). Newest first, at most 12, and the walk stops at the first gap of more than 60 days between consecutive `last_read_at` values. `from_*` is the oldest chapter in the walk, `to_*` the newest (the last chapter the recap covers, not `to_key` itself). For `scope="chapter"` (Glass's chapter recap) the range is only the newest completed chapter before `to_key`.
2. **Empty range** → `{"available": false, "reason": "first_chapter", "range": null, "est_seconds": 0, "cached": false}`.
3. **Manga** (the source descriptor's `content_kind == "manga"`): count the range's chapters that have a `chapter_ocr` row with `word_count > 0`; under 50 % → `reason: "no_dialogue"`.
4. **Novels**: trim the range to chapters present in `novel_chapter_cache` (a recap is never written from text the server would have to fetch: that is the scrape-storm rule `suggestion_service.py` documents); an empty trimmed range → `reason: "no_dialogue"` (the clients show "No recap for this one").
5. **Cached**: if `ai_result_cache` holds a row for `cache_key("recap", shape, scope, source_id, series_key, from_key, to_key)`, answer `available: true, reason: "ok", cached: true` whatever the AI state (a cached recap costs nothing).
6. Otherwise the caller's ask allowance decides: `suggest.availability()` answering `not_configured` or `budget_exhausted` → `available: false` with that reason; else `available: true, reason: "ok", cached: false`.
7. `est_seconds = round(min(400, 40 + 30 * n) / 230 * 60)` where `n` is the number of chapters in the (trimmed) range, and `20` for `scope="chapter"`. So 12 chapters read in 104 s (`PREVIOUSLY ON · 2 MIN`), one chapter in 18 s.
8. No AI call and no budget cost, ever.
9. `availability_many(rows)` computes the object for a list of `(source_id, series_key, to_key)` with a fixed number of queries (one for all progress rows of the listed series, one for all OCR rows, one for all novel cache rows, one for all cache keys), never one query set per row. Continue-reading and `/home` use it.

`GET /library/continue-reading` rows gain `recap` (the object above, computed with `availability_many` for the returned rows; `to_key` is the row's `chapter_key`). Additive; the list keeps its order, its `X-Total-Count` and every existing field.

### E. `GET /home` (`backend/routes/home.py`, new; logic in `backend/services/home_service.py`, new)

Register the router in `backend/api/router.py`. Not public (it needs a session). Query parameters:

- `content_kind`: `"manga"` (default) or `"novel"`; anything else is 422.
- `tz_offset_minutes`: required int, −720 to 840 (422 when missing or outside). Web sends `-new Date().getTimezoneOffset()`, Flutter `DateTime.now().timeZoneOffset.inMinutes` (cinematic §9.1.7).
- `refresh`: `0` (default) or `1`; `1` skips the composed-cache read (Glass's pull to refresh, glass §8.8) and writes a fresh entry.

Response (every field below is always present; `null` where stated):

```json
{
  "issue_no": 184,
  "generated_at": "2026-09-29T15:34:12Z",
  "content_kind": "manga",
  "headline": "Tonight: chapter 143 of Omniscient Reader.",
  "deck": "…",
  "kicker_title": null,
  "streak": {"current_days": 12, "longest_days": 30, "at_risk": false, "last_active_date": "2026-09-29", "milestones_seen": [7]},
  "cover": {"reason": "new_chapters", "source_id": "…", "series_key": "…", "chapter_key": "…", "chapter_number": 143, "last_page": 1, "page_count": 0, "title": "Omniscient Reader", "cover_url": "/sources/…/cover", "content_kind": "manga", "ambient": {…}, "palette": {…}, "new_count": 2, "paused_days": 0, "recap": {…}, "why": null, "world": null},
  "also": [{"kind": "new_chapters", "source_id": "…", "series_key": "…", "title": "Tower of God", "headline": "3 new chapters of Tower of God", "deck": "…", "ambient": {…}}],
  "sections": [{"type": "continue", "title": "Continue reading", "seed": null, "note": null, "fallback": null, "items": […], "state": "ready", "generated_at": "…"}],
  "ai": {"available": true, "reason": "ok"}
}
```

`streak` is the one streak object `backend/03` builds for `GET /library/statistics`, called with this request's `tz_offset_minutes` (never re-implemented here). `ambient` and `palette` come from `backend/01`'s serializers (null until the cover has been served once).

#### E1. The cover story (cinematic §9.1.2, in priority order; the first rule that yields a candidate wins)

All candidates are this profile's rows, 18+ gated on serve, of the requested `content_kind` (the source descriptor's `content_kind`; a source with no installed descriptor is skipped).

| `reason` | Rule |
|---|---|
| `new_chapters` | A followed series with reading status `reading` whose `read_state.new_count >= 1` (chapters past the furthest read one), the most recent `last_read_at` first. `chapter_key` is the first unread chapter; `new_count` is that count. |
| `in_progress` | A chapter in progress: the newest continue-reading row whose chapter is unfinished (`page_count > 0` and `last_page < page_count`) and read within 21 days. |
| `paused` | A followed series with status `reading`, last read 7 to 60 days ago, unfinished, whose `recap.available` is true; the most recent first. `paused_days` = whole local days since the last read. |
| `first_pick` | The profile follows at least one series and has no `chapter_progress` row in this content kind: the first followed series (oldest `created_at`), `chapter_key` its first chapter. |
| `ai_pick` | The profile has reading history but no followed series with status `reading`: world recs `for_you`, the first item with a non-empty `available[]` and not excluded (item E6); `source_id`/`series_key` from its first `available[]` entry, `world` = the WorldItem, `why` from the editorial or null. |
| `caught_up` | The profile has followed series with status `reading` and none of the rules above matched: the same pick as `ai_pick`; when there is none, the first title of the `popular` section (E3). |
| `popular` | Nothing followed and nothing read: the first title of the `popular` section. |

If a rule's candidate cannot be served (the series is gated, or its source is gone), move to the next candidate of the same rule, then the next rule. When nothing at all is found, `cover` is `null`, `headline` is "Your first issue starts here." and `deck` is "Follow three series and this page fills itself in.".

#### E2. Headline and deck (the strings of cinematic §9.1.2 and §8.8, exactly)

- **Time word** from the local hour (`utcnow() + tz_offset_minutes`): 05:00 to 11:59 "This morning", 12:00 to 17:59 "This afternoon", otherwise "Tonight".
- **Numbers**: a count that opens a sentence is spelled out and capitalised up to 100 ("Twelve", "Thirty-one", "One hundred"), and printed as a numeral from 101; any other count under ten is spelled out in lower case; chapter numbers are always numerals (decimals kept, `143.5`). One helper, `spell(n: int, *, capital: bool) -> str`, with a table test.
- **Length**: a headline is at most 60 graphemes. Count graphemes as `len(unicodedata.normalize("NFC", s))` minus the number of combining characters (`unicodedata.combining(ch) != 0`); mark it with `# ponytail: code-point grapheme count; use the regex module's \X if emoji titles ever overflow`.

| `reason` | `headline` | `deck` (AI when the editorial has it, else the fallback shown) |
|---|---|---|
| `new_chapters` | "{Time}: chapter {n} of {title}."; over 60 graphemes: "{Time}: chapter {n}." with `kicker_title = title`; a chapter with no number: "{Time}: a new chapter of {title}." / "{Time}: a new chapter." | editorial `deck`, else the synopsis's first sentence (E7), else null |
| `in_progress` (manga) | "{Time}: finish chapter {n}. {Pages} pages left." ("One page left." for one page) | "You were on page {last_page} of {page_count} {ago}." where `{ago}` is "today", "yesterday" or "{spelled or numeral} days ago" |
| `in_progress` (novel) | "{Time}: finish chapter {n}." | "You were {pct} % through it {ago}." (`pct` = `round(100 * last_page / page_count)`) |
| `paused` | "{Time}: back to {title}."; over 60: "{Time}: back to it." with `kicker_title = title` | "You paused {days} days ago at chapter {n}. Previously on is ready." |
| `ai_pick` | "{Time}: start {title}."; over 60: "{Time}: start something new." with `kicker_title = title` | the pick's `why`, else the synopsis's first sentence, else null |
| `first_pick` | "{Time}: start {title}." (same overflow rule) | "Chapter 1 is waiting. The rest of your picks are below." |
| `popular`, or `cover` null | "Your first issue starts here." | "Follow three series and this page fills itself in." |
| `caught_up` | "{Time}: you're caught up." | "Nothing new on your shelf. Here's something else." |

**Streak at risk** overrides the headline and deck of every row except `popular` and `caught_up`, and keeps the cover series: when `streak.at_risk` is true **and** `streak.current_days >= 2` (backend/03's `at_risk` is true from a 1-day streak up, because Cinematic's flame shows its at-risk state from 1 day, cinematic §9.2.2; the headline override needs 2 days or more, cinematic §9.1.2 and §8.8, so a 1-day streak keeps the normal headline and deck), `headline` = "{Spelled days} days and counting. One chapter keeps it alive." for `current_days <= 100` and "Your {n}-day streak ends at midnight." from 101; `deck` = "Open any chapter before midnight to keep your streak.". Both spellings stay within 60 graphemes (the longest spelled one, "Seventy-seven days and counting. One chapter keeps it alive.", is exactly 60): assert that in the table test for every n from 2 to 100.

`issue_no` = whole local days between the profile's first `reading_sessions.started_at` (in this `tz_offset_minutes`) and local today, plus 1; 1 when the profile has no session.

#### E3. Sections (types, titles, rules, item shapes)

Every section object is `{type, title, seed, note, fallback, items, state, generated_at}`. The sections this step builds are **omitted when they have no items** (except the `picked` fallback case below), so `state` here is one of `ready`, `unavailable`, `stale`. Order (cinematic §9.1.7; `sent_to_you`, `circle` and `circle_top` are later steps' and sit at their places): `first_picks`, `continue`, `new_this_week`, `almost_there`, `where_were_we`, `sent_to_you`, `picked`, `because` (one section per seed), `circle`, `circle_top`, `popular`, `sources`, `genres`, `numbers`.

| `type` | `title` | Rule | `items[]` |
|---|---|---|---|
| `first_picks` | "Your first picks" | Only when the cover reason is `first_pick`: followed series in follow order, up to 12 | `{kind: "source", item: SourceSeries, why: null}` |
| `continue` | "Continue reading" | `continue_reading(limit=50)` filtered to this content kind, the first 12 | the continue-reading row (which now carries `recap`) plus `ambient`, `palette`, `nudge`, `new_count`, `paused_days`: `nudge` is `"new"` when `new_count >= 1`, else `"almost_done"` when `page_count > 0` and `last_page / page_count >= 0.8`, else `"paused"` when `paused_days >= 7`, else `null` |
| `new_this_week` | "New this week" | Followed series with `last_new_chapter_at` within the last 7 days, newest first, up to 20 | the FollowedSeries list row (with `read_state`) plus `ambient`, `palette` |
| `almost_there` | "Almost there" | Status `reading` and `1 <= chapters_left <= 3`, where `chapters_left = read_state.new_count + (0 if the furthest chapter is completed else 1)`; fewest left first, then most recent read; up to 12 | the FollowedSeries list row plus `ambient`, `palette`, `chapters_left` |
| `where_were_we` | "Where were we?" | Status `reading`, last read 21 to 120 days ago, `chapters_left >= 1`; most recent first; up to 12 | the FollowedSeries list row plus `ambient`, `palette`, `recap` (for the long-press `Previously on`) |
| `picked` | "Picked for you" | World recs `for_you`, not excluded, up to 12 | `{kind: "world", item: WorldItem, why}` |
| `because` | "Because you read {seed title}" | World recs `sections[:3]`, one section each, up to 10 items, not excluded | `{kind: "world", item: WorldItem, why}`; `seed` = `{title, source_id, series_key}` |
| `popular` | "Popular on your sources" | Only when the profile follows nothing or has no reading history: page 1 of the `popular` browse mode (else the source's first mode) of each of up to 3 sources (the pins of this content kind, else the E5 fallback sources), through `SourceCacheService.get_browse_page`, which serves the cache and is gated on serve; round-robin across sources, up to 12 | `{kind: "source", item: SourceSeries, why: null}` |
| `sources` | "Sources" | The pinned sources of this content kind (`SourcePinService.list_pins`), else the E5 fallback sources | the pin row (`source_id`, `name`, `icon_url`, `mature`, `available`) plus `latest_covers` (up to 3 `cover_url`s: the newest `source_series_cache` rows of that source by `fetched_at`, read locally, never fetched) and `suggested` (true for E5 fallback sources, which the client captions `SUGGESTED SOURCES`) |
| `genres` | "Your genres" | `FollowedSeriesService.recommendations(limit=12)`, only when the profile follows something (`backend/05` adds taste genres for new profiles) | `{genre, weight}` |
| `numbers` | "This week in numbers" | Only when the profile has at least one reading session | one item: `{streak, chapters_week, seconds_week}`, where `streak` is the same object as the top-level `streak` and the two totals come from backend/03's statistics window of 7 days in this `tz_offset_minutes` |

`SourceSeries` items built from a followed row that has no `source_series_cache` row carry `{id: series_key, source_id, series_identity, title, cover_url, chapter_count, genres: [], status: null, description: null, author: null, artist: null, content_rating, latest_chapter: null}` so both clients parse one shape.

#### E4. Also in this issue (cinematic §8.8, **Selection**)

Walk the priority list and take the first candidate of each kind, then fill any remaining slots from the list in order, never repeating a series and never using the cover story's series, up to 3: (1) `new_chapters`: the followed series with the most unread new chapters, `headline` "{Count} new chapters of {title}" (count spelled when under ten: "Three new chapters of Tower of God"), `deck` its synopsis first sentence or null; (2) `because`: the top `because` item, `headline` "Because you read {seed title}", `deck` its `why` or null; (3) `letter`: added by `backend/09`, skip here; (4) `almost_there`: the followed series with the fewest chapters left, `headline` "{Count} chapters left in {title}" ("One chapter left in …"). Items: `{kind, source_id, series_key, title, headline, deck, ambient}`. Fewer than 2 items: `also` is `[]` (the row is not rendered; cinematic §8.8).

#### E5. The new-profile fallback (cinematic §8.8, new profile with 0 pins)

When the profile has no pins of the requested content kind: the 3 healthiest non-18+ sources of that kind, never a mature source even with the gate open: installed, browsable, `mature` false, `content_kind` matches, health `status == "ok"`, ordered by fewest `consecutive_failures`, then by name. They feed `popular` and `sources` (with `suggested: true`) and the `popular` cover.

#### E6. Exclusions

`HomeService._excluded()` returns the identity pairs never to offer as a pick: followed series and series with any progress (the same set `SuggestionService._excluded_keys` builds), applied to `picked`, `because`, `ai_pick`/`caught_up` covers and `popular`. `backend/05` extends this one method with "Not interested" feedback; keep it one method so that is a one-line change.

#### E7. The deterministic fallback per AI-backed field (cinematic §9.1.6, §9.1.8)

- Cover `deck`: the synopsis's first sentence: `source_series_cache.description` (displayed, never sent to the AI), whitespace collapsed, cut at the first `. `, `! ` or `? ` after at least 20 characters, at most 160 characters (cut at a word boundary with `…`), else null.
- `why` lines: `null`.
- `picked` when the AI desk is unavailable (`desk_availability()` not `ok` and no editorial of today or of the last 7 days): the section keeps its place with `title` "From your shelf", `fallback: "shelf"`, `state: "unavailable"`, `note` = the reason key (`not_configured`, `budget_exhausted`, `rate_limited` or `ai_failed`; the clients own the copy of cinematic §9.1.8 and glass §9.1.5), and `items` = the profile's favourites, then its `plan_to_read` follows, up to 12, as `{kind: "source", item: SourceSeries, why: null}`. If that list is empty too, the section is omitted.
- `because` is not AI-dependent: it is served from world recs whenever the catalogue answered, with `why` null when the editorial is missing, and omitted when world recs are empty or unreachable.
- `picked` and `because` are served with `state: "stale"` and the old editorial's `generated_at` when today's editorial is missing and one from the last 7 days exists for the same (profile, gate, content kind) (the clients print `PICKED 3 DAYS AGO` from `generated_at`).
- Top-level `ai` = `desk_availability()`.

#### E8. The home editorial (the only AI call in this step)

- **When**: at most once per `(profile_id, mature_content_enabled, content_kind, local date)`. `compose` looks it up with `cache_get(cache_key("home_editorial", str(profile_id), str(int(gate)), content_kind, local_date))`; on a miss, when `desk_availability()` is `ok`, it calls `run_in_background(key, job)` and composes **now** with the fallbacks (never waiting for the AI). When the job stores its row it also drops this profile's composed-cache entries (item E9), so the next `/home` carries the lines.
- **Input** (a `system` prompt with the rules, then the data as a labelled JSON block, never interpolated into the rules): the cover series (`title`, `genres`, `chapter_number`, `new_count` when reason is `new_chapters`), the `picked` and `because` items (`anilist_id`, `title`, `format`, `genres`), and `FollowedSeriesService.taste_profile()` titles and genres. Never descriptions (`taste_profile`'s rule) and never another profile's data.
- **Output** (JSON mode): `{"deck": "…", "why": {"<anilist_id>": "…"}}`. Validation: `deck` a string of at most 140 characters, one or two sentences, no spoilers beyond chapter numbers; each `why` at most 90 characters; ids not in the input are dropped; a malformed answer is `ai_failed`.
- **Storage**: `cache_put(kind="home_editorial", profile_id=…, payload=…, model=completion.model, expires_at=` the next local midnight plus 7 days `)` (7 days so a stale editorial can be served under E7).
- **Cost**: the desk ledger (`DESK_DAILY_CEILING`), never a reader's asks.

#### E9. The composed cache

An in-process dict in `home_service.py` keyed `(profile_id, mature_content_enabled, content_kind, tz_offset_minutes, local_hour)` with a 10-minute TTL (cinematic §9.1.7), at most 512 entries (drop the oldest on insert), under a `threading.Lock`; mark it `# ponytail: per-process cache; move it to a table if uvicorn ever runs more than one worker` (production runs `python main.py`, one uvicorn worker). A gate change reads a different entry and composes afresh with its own cover story, so no purge hook is needed for the gate. `invalidate_profile(profile_id)` drops every entry of a profile (the editorial job and `backend/05`'s feedback call it). `refresh=1` skips the read.

**Live sections after the cache read.** `compose()` returns the cached payload and then runs `LIVE_SECTION_BUILDERS`, a module-level list of callables `(ctx, payload) -> list[section]` that is empty in this step; each returned section is inserted at its place in the E3 order. `backend/08` (Circle) and `backend/09` (letters) append to this list so their sections are computed per request and never cached. Write a docstring on the list saying exactly that.

#### E10. 18+ and isolation

- Every row comes from the profile-scoped services (`FollowedSeriesService`, `ReadingStatsService`, `SourcePinService`), whose gates already run. World recs apply their own gate (`_hidden`), and `picked` and `because` items are re-checked on serve: an item with `is_adult` true, or whose every `available[]` source is mature, is dropped while the gate is closed.
- The editorial row belongs to one `(profile, gate)`; a closed-gate compose never reads an open-gate editorial (the gate is in the key).
- A request without `X-Profile-Id` for an account that has profiles resolves to the unscoped bucket (the lenient read rule of `core/profile_context.py`) and gets an empty-library home (the `popular` state), never another profile's rows.

### F. API note for the client steps

Write `backend/docs/home-api.md`: the `GET /home` query, the response with one full example for a returning reader and one for a new profile, every section `type` with its item shape, the recap availability object and where it appears, the `state` and `ai.reason` vocabularies, the at-risk rule, `refresh=1`, the 10-minute cache, and the `LIVE_SECTION_BUILDERS` hook. List the fields this step adds beyond cinematic §9.1.7 (`generated_at` at the top, `content_kind`, `kicker_title`, `cover.title/cover_url/chapter_number/last_page/page_count/new_count/paused_days/why/world/palette`, `section.fallback`, `section.seed`, `sources[].suggested`). `backend/05`, `08` and `09` append their own sections.

## Tests (write them first; HTTP-level through `client` and `as_user(uid, pid)` unless noted)

- `backend/tests/test_home_headline.py` (pure functions, no DB): every row of the E2 table at hours 04:59, 05:00, 11:59, 12:00, 17:59, 18:00 (time words); `spell()` for 0 to 101 with and without capitals; the 60-grapheme overflow for `new_chapters`, `paused`, `ai_pick`; the at-risk line for n = 2, 12, 31, 77, 100 (spelled) and 101, 123 (numeral) and the assertion that every n from 2 to 100 fits in 60 graphemes; a streak object with `at_risk: true` and `current_days: 1` keeps the cover row's normal headline and deck; the synopsis-sentence cutter.
- `backend/tests/test_recap_availability.py`: range walk with 14 completed chapters (only 12 returned, newest first); a 61-day gap stops the walk; `scope="chapter"` returns one chapter; empty range → `first_chapter`; manga with OCR for 5 of 12 → `no_dialogue`, 6 of 12 → `ok`; novel with 0 cached chapters → `no_dialogue`, with 3 cached of 12 → range trimmed to 3; a cached recap row → `available: true, cached: true` even with the ask ledger spent; `not_configured` and `budget_exhausted` from the ask ledger; `est_seconds` for n = 1 and 12; `availability_many` for 10 rows issues a bounded number of queries (count them with a SQLAlchemy `before_cursor_execute` listener: at most 6); continue-reading rows carry `recap`.
- `backend/tests/test_home_feed.py`:
  1. **Gate change recomposes with a valid cover story.** Profile with gate open follows a mature series with new chapters (cover candidate by rule 1) and a safe series in progress. `/home` → cover is the mature series. `PUT /settings {"mature_content_enabled": false}` for that profile, then `/home` (no refresh) → a different cache entry: the cover is the safe series (`in_progress`), and no mature series, title or cover appears anywhere in the JSON (`json.dumps(payload)` does not contain its title or key).
  2. **AI outage.** With `deepseek_client.is_configured` patched to return False: `continue`, `new_this_week`, `almost_there`, `where_were_we`, `sources` and `numbers` are `ready`; `picked` is `unavailable` with `fallback: "shelf"`, `note: "not_configured"` and the favourites as items; `ai == {"available": false, "reason": "not_configured"}`; the cover and headline exist. Then with the key configured and `complete_json` raising `LLMError`: the background job runs inline, the next `/home?refresh=1` has `ai.reason == "ai_failed"` and the same non-AI sections `ready`.
  3. **Editorial once per day.** With `complete_json` stubbed to return a valid editorial: the first `/home` composes without it and triggers the job; the second `/home` (the job dropped the cache) carries the `deck` and `why` lines; ten more `/home?refresh=1` calls make no further `complete_json` call; the desk ledger file records 1 request and the suggest ledgers record 0.
  4. **Stale editorial.** An editorial row dated 3 days ago and the desk unavailable today → `picked` has `state: "stale"` and that `generated_at`.
  5. **Isolation.** Account 1 has profiles P1 and P2, account 2 has P3. P1's follows, progress, streak and editorial never appear in P2's or P3's `/home`; `X-Profile-Id` naming P3 sent by account 1 gets the unscoped empty home.
  6. **New profile.** No pins, no follows: sections are `popular`, `sources`, and `genres` is absent; the `sources` items are the 3 healthiest non-mature sources of the kind with `suggested: true`, even when a mature source is healthier and the gate is open; `cover.reason == "popular"`, headline "Your first issue starts here.".
  7. **Just onboarded.** Follows, no progress: `cover.reason == "first_pick"`, first section `first_picks`.
  8. **Content kind.** A novel follow never appears with `content_kind=manga` and is the only content with `content_kind=novel`.
  9. **Validation.** Missing `tz_offset_minutes` → 422; 841 → 422; `content_kind=comics` → 422.
  10. **Cache.** Two calls within 10 minutes return the same `generated_at`; `refresh=1` returns a newer one; a different `tz_offset_minutes` hour composes a new entry.
  11. **Also in this issue** follows E4 (never the cover series, no repeats, `[]` below 2).
  12. **New this week** lists a series whose update check found new chapters while its `notify` is off (the `last_new_chapter_at` path).
- `backend/tests/test_update_service_sweep.py` gains one case: a sweep that finds new chapters sets `last_new_chapter_at` with the profile's `notify_enabled` false.

## File layout

| Path | Change |
|---|---|
| `backend/alembic/versions/00NN_home_feed.py` | new (NN = the next number) |
| `backend/database/models.py` | `FollowedSeries.last_new_chapter_at`, class `AiResultCache` |
| `backend/core/cache_tables.py` | `"ai_result_cache"` |
| `backend/services/llm.py` | `LLMRateLimited` |
| `backend/services/deepseek_client.py` | raise `LLMRateLimited` on a final 429 |
| `backend/services/ai_desk.py` | new (C) |
| `backend/services/recap_service.py` | new (D) |
| `backend/services/home_service.py` | new (E1 to E10, `spell`, grapheme counter, synopsis cutter, `LIVE_SECTION_BUILDERS`, `invalidate_profile`) |
| `backend/routes/home.py` | new: `GET /home` |
| `backend/api/router.py` | include the home router |
| `backend/routes/library.py` | `continue-reading` rows gain `recap` |
| `backend/services/update_service.py` | `last_new_chapter_at` |
| `backend/docs/home-api.md` | new (F) |
| `backend/tests/test_home_headline.py`, `test_recap_availability.py`, `test_home_feed.py` | new |
| `backend/tests/test_migrations_alembic.py`, `test_update_service_sweep.py` | updated as above |
| `docs/redesign/proof/backend-04/` | `plan.md`, `pytest-before.txt`, `pytest-after.txt`, the JSON captures of G |

### G. Proof (the dev stack from `backend/00`; never production)

`free -m`, then `backend/scripts/dev_stack.sh reset` (fresh seed). With the dev stack's `api` helper, save pretty-printed JSON into `docs/redesign/proof/backend-04/`:

- `home-riya-manga.json`: `MM_DEV_PROFILE=Riya backend/scripts/dev_stack.sh api GET '/home?content_kind=manga&tz_offset_minutes=330'` (18+ open),
- `home-aarav-manga.json`: the same for `Aarav` (18+ closed),
- `home-riya-novel.json`: `content_kind=novel`,
- `home-riya-2130.json`: the same as the first with a `tz_offset_minutes` that makes the local time 21:30 (compute it from `date -u +%H:%M`; this shows the at-risk headline when the seeded streak has no read today),
- `continue-reading-riya.json`: `GET /library/continue-reading`.

The dev stack has no `DEEPSEEK_API_KEY`, so these show the `not_configured` path (`picked` as "From your shelf"); say so in the report. Stop the dev stack afterwards (`backend/scripts/dev_stack.sh stop`). This step changes no web screen, so there are no Playwright screenshots; the JSON files are the visual proof.

## Acceptance criteria

- [ ] `pytest-before.txt` records the pre-change pass count; `pytest-after.txt` shows the same passes plus the new tests, and no test that passed before fails.
- [ ] The new revision upgrades a database at the previous head, backfills `last_new_chapter_at`, and `test_alembic_head_matches_models` and `test_revision_set_is_exactly_what_we_expect` pass.
- [ ] `GET /home` returns every top-level field of section E for a returning reader, a new profile and a just-onboarded profile, and 422 for a missing or out-of-range `tz_offset_minutes` or an unknown `content_kind`.
- [ ] The cover story follows E1's order; the headline and deck strings match cinematic §9.1.2 and §8.8 exactly, including the time words, spelled numbers, the 60-grapheme overflow and the at-risk override.
- [ ] Sections come in the E3 order, empty ones are omitted, and every item carries the shape of the E3 table; `continue` and `where_were_we` items and the cover carry `recap`; `GET /library/continue-reading` rows carry `recap` and keep every old field.
- [ ] Recap availability follows D (range of at most 12, 60-day gap, 50 % OCR for manga, cached-text-only for novels, cached recaps always available) and never calls the AI.
- [ ] With the AI not configured, over budget or failing, every non-AI section is `ready`, `picked` is "From your shelf" with `state: "unavailable"` and the reason in `note`, and `ai` names the reason; with an editorial older than today, `picked` and `because` are `stale`.
- [ ] The editorial is written at most once per profile, gate, content kind and local day, in the background, on the desk ledger only; `/home` never waits for the AI.
- [ ] A gate change composes a different entry with a valid cover story, and no mature title, cover, key or genre appears anywhere in a closed-gate payload.
- [ ] Profiles never see each other's rows, within an account or across accounts.
- [ ] The new-profile fallback uses the 3 healthiest non-18+ sources of the requested kind, even with the gate open.
- [ ] Per-skin: both skins read this one payload. Cinematic uses `headline`, `deck`, `kicker_title`, `cover`, `also` and every section; Glass uses `cover` and the sections for its spotlight and rails, computes its own greeting, and sends `refresh=1` on pull to refresh. Nothing in the response is skin-specific.
- [ ] UI rules (reduced motion, keyboard access, 44 pt hit targets) belong to the client steps `web/08`, `mobile/08`, `web/31` and `mobile/31`. This step serves them by sending whole strings (the typed headline is typed by the client from `headline`, never streamed) and by never making the page wait on the AI, so a reduced-motion client can render the final state at once.
- [ ] `backend/docs/home-api.md` exists and matches the implementation.
- [ ] `git show --name-only --format= <hash> -- frontend mobile ops backend/connectors` for each of your own commits (never a branch or range diff: parallel sessions commit on the same branch) prints nothing.

## Verification

Run one heavy command at a time. Before each, `free -m`; stop if `available` is under 1024.

```bash
cd /srv/manhwamaniacs/dev/ManhwaManiacs/backend
free -m
.venv/bin/python -m pytest -q --no-header tests/test_home_headline.py tests/test_recap_availability.py tests/test_home_feed.py tests/test_migrations_alembic.py tests/test_update_service_sweep.py tests/test_suggestion_service.py tests/test_world_recs.py tests/test_audit_backup_cache_tables.py
free -m
timeout 1800 .venv/bin/python -m pytest -q --no-header 2>&1 | tail -25 > ../docs/redesign/proof/backend-04/pytest-after.txt
cat ../docs/redesign/proof/backend-04/pytest-after.txt
```

Web and mobile suites are not run in this step because no file under `frontend/` or `mobile/` changes (`git show --name-only --format= <hash> -- frontend mobile` for each of your own commits (never a branch or range diff: parallel sessions commit on the same branch) must print nothing). Their baseline commands (from `00-baseline.md`) are `npm run lint` and `npm run build` in `frontend/`, and `/srv/manhwamaniacs/dev/flutter/bin/flutter analyze` and `/srv/manhwamaniacs/dev/flutter/bin/flutter test` in `mobile/`; if you ever touch those folders, run them, one at a time, with `free -m` before each.

Then the proof of section G.

## RAM guard

Production and five Minecraft bots share this box (7,746 MB total). Check `free -m` before each pytest run and before `dev_stack.sh start`/`reset`. Stop and report if `available` is under 1024 MB. Never run two heavy commands at once; never run `next build` in this step.

## Git

- Branch `feat/vps-slim-source-native`. Commit small and often, one commit per working step, and push after each: `git push origin feat/vps-slim-source-native:master`.
- Suggested commits: (1) `test(home): headline, recap availability and home feed cases` (failing), (2) `feat(backend): ai_result_cache and followed_series.last_new_chapter_at`, (3) `feat(ai): desk ledger, rate-limit error and background runner`, (4) `feat(recap): availability service and continue-reading recap`, (5) `feat(home): GET /home composition and composed cache`, (6) `feat(home): background editorial`, (7) `docs(backend): home API note`, (8) `docs(redesign): backend-04 proof`.
- Stage by explicit path only, for example `git add backend/services/home_service.py backend/routes/home.py backend/tests/test_home_feed.py`.
- No Claude or AI attribution anywhere: no `Co-Authored-By` line, no "generated with" line, no AI author. Never commit secrets, `.env` files, `.claude/`, `backend/.venv/` or anything under `/srv/manhwamaniacs/dev/data/`.
- No frontend file changes, so no `next build` is needed before pushing; if `git status` shows a frontend change you made, stop.

## Never

- Never edit `backend/connectors/`.
- Never touch production containers (`docker` commands against `manhwamaniacs-*`), `/srv/manhwamaniacs/app` or `/srv/manhwamaniacs/data`, and never point the dev stack at them.
- Never send `source_series_cache.description` or any scraped text to the AI, and never call an AI provider except through `deepseek_client.complete_json`.
- Never make `/home` wait for an AI call.

## Report back

Reply with:
1. Done items, by the letters A to G above, each with its commit SHA.
2. The revision id you used and the previous head it follows.
3. Backend test counts: before passed/failed, after passed/failed, and the new test files with their case counts.
4. The proof folder `docs/redesign/proof/backend-04/` and its files (no screenshots in this step), with one line on what `home-aarav-manga.json` shows about the gate.
5. Open issues: anything in cinematic §9.1.7 you could not serve exactly, and the first-compose latency you measured on the dev stack for a profile whose world recs were cold (`time backend/scripts/dev_stack.sh api GET …`).

Next prompt file in the series: `docs/redesign/prompts/web/07-cinematic-auth-profiles-18plus.md`. Next file in the backend track: `docs/redesign/prompts/backend/05-ai-similar-recap-taste-onboarding.md`.
