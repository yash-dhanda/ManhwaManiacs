# Backend 03: statistics, streaks, the Annual and listen sessions (new feature 2)

## Goal

New feature 2 of the redesign is reading stats and streaks: a streak flame that knows whether today is done or at risk, milestone cards that show once per profile across devices, a Wrapped-style year recap (Cinematic calls it The Annual, Glass calls it Wrapped), and shareable stat cards that never print an 18+ title, cover or genre. The owner rule behind stack-decision §2.6 is that logic both clients must agree on lives on the server, so this step makes the backend the single source of every streak and year figure: one streak object shared by `GET /library/statistics` (and later `GET /home`), the milestone "seen" call, streak and today's reading time on every progress save (so Glass's flare and goal ring never guess), `GET /library/annual` with every field both skins read, the `shareable` block on the Annual and on the statistics range, and `POST /novels/listen-sessions` so the colophon can credit the narration voices. The Annual is cached per profile, per gate state, per year, per offset, per day.

## Read first

1. `docs/redesign/cinematic/DESIGN.md` §9.2 in full, especially §9.2.2 (tiers and states of the flame: **Read today** means `streak.last_active_date == local today`; **At risk** is after 20:00 local and not yet today; milestone cards at 7, 30, 100 and 365 days, shown once per profile through `POST /library/statistics/milestones/{days}/seen`), §9.2.4 (the eleven pages; calendar year in the profile's local time; states: fewer than 7 recorded days), §9.2.5 (**Privacy rules**: every card draws only on `shareable`), §9.2.7 (the whole **Backend** subsection including the response shape by field name, the cache key and the listen-session batching rules). Then §15.5 rows: the streak object, milestones, `GET /library/annual`, `shareable`, the per-profile composed caches, `available_years`, `POST /novels/listen-sessions` and `top_voices`.
2. `docs/redesign/glass/DESIGN.md` §9.2.1 (Statistics data: the streak object carries `current_days`, `longest_days`, `at_risk`, `milestones_seen`), §9.2.2 (**What triggers it (no local inference)**: `POST /reader/progress` answers with `streak {current_days, extended_today}` and `today_seconds`; offline saves are answered when the queued save is answered), §9.2.3 (**Data**: each Wrapped card's source field, including `pages_read`, `longest_streak {days, month, start, end}`, `busiest_day`, `firsts_lasts`, `recorded_days`, `partial`, `available_years`), §9.2.4 (the share side: mature series, covers, sources and genre words Adult, Ecchi, Hentai, Mature, Smut are never drawn), §15.5 rows `daily_goal_minutes`, the statistics streak object, `GET /library/annual` additions, `shareable` on `GET /library/annual` and `GET /library/statistics`, `POST /reader/progress` answers; §15.6 row **Statistics and Wrapped fields**; §15.10 G12.
3. `docs/redesign/stack-decision.md` §2.6 (stats aggregates, streaks and Wrapped totals run on the backend).
4. `docs/redesign/inventory/00-decisions.md` (new feature 2), `docs/redesign/inventory/capabilities.md` §10 (Reading statistics and streaks), §13 (progress), §19.3 and §19.4 (audio and voices).
5. `docs/redesign/00-baseline.md` and the latest backend pass count in `docs/redesign/proof/backend-02/pytest-after.txt`.
6. Code: `backend/services/reading_stats_service.py` (the module docstring's **Scope**, **The 18+ gate**, **Time** and **The roll-up** rules; `ReadingStatsService.__init__`, `_sessions`, `_day`, `_hour`, `_aggregates`, `_roll`, `_bounds`, `_window`, `_active_days`, `_streak`, `_by_source`, `_by_series`, `_fill_cached_titles`, `build`, `SESSION_SECONDS_CAP`), `backend/services/followed_series_service.py` (`statistics`), `backend/routes/library.py` (`statistics`), `backend/routes/reader.py` (`save_progress`, `save_progress_batch`, `_busy`), `backend/services/progress_service.py` (`save_one`, `save_batch`, `_gate_open`, `_require_profile`), `backend/routes/novels.py` (router, `require_novels_enabled`, `OWNER_ONLY`), `backend/services/voice_pack.py` (`load_voices`, `is_known_voice`, `Voice.name`), `backend/core/content_rating.py` (`mature_tracker_case`, `MATURE_CONTENT_RATINGS`), `backend/core/connector_directory.py` (`descriptors_by_source`, `is_mature_source`), `backend/core/time_utils.py` (`clamp_client_clock`, `utcnow`), `backend/services/cover_colour.py` (`attach_cover_colours`), `backend/tests/test_reading_statistics.py`, `backend/tests/test_audit_stats_rollup.py`, `backend/tests/test_novels_flag.py`, `backend/tests/test_audit_isolation_profile_delete_cascade.py`, `backend/tests/test_audit_integrity_scope_fk.py`, `backend/tests/conftest.py` (`seed_session`, `seed_follow`, `as_user`).

## Track rule (every `backend/*` prompt)

- Work only in `backend/` (never `backend/connectors/`) plus `docs/redesign/proof/backend-03/`.
- Stage only the paths you changed, by name; never `git add -A`.
- Alembic revisions continue; this step's revision is `0021_streaks_listen_sessions`.
- Every endpoint is profile-scoped and applies the 18+ gate when serving, never when storing. Writes (milestones, listen sessions) stay ungated, like progress.
- Additive only: `streak` gains fields, payloads gain keys; nothing is renamed or removed.
- Tests: `backend/.venv/bin/python -m pytest -q --no-header` from `backend/`.

## Preconditions

1. Branch `feat/vps-slim-source-native`.
2. backend/00 has landed (`backend/.venv` and `0018_profile_redesign_cols.py` exist), and so has backend/01 (`backend/services/cover_colour.py` exists): it runs at plan order 14, before this file's 22, and `top_series` and `art_series` carry its `ambient` and `palette`. The newest revision file must be `0020_collection_rules.py` (backend/02, plan order 19, runs before this file). If it is anything else, stop and report: taking `0020`'s parent here would fork the Alembic history when backend/02 runs.
3. `free -m` shows at least 1024 MB available.

## Skills

- `superpowers:writing-plans` first; plan in `docs/redesign/proof/backend-03/plan.md`.
- `superpowers:executing-plans` inline (the items share `reading_stats_service.py` and one migration; do not split them across subagents).
- `superpowers:test-driven-development`: every rule below starts as a failing test.
- `superpowers:verification-before-completion` before reporting.
- Not `impeccable`, `taste-skill:taste-skill` or `frontend-design`: no UI.

## Decisions this file makes (so nothing is left open)

- **Day.** A day is the caller's fixed `tz_offset_minutes` day, exactly as `ReadingStatsService` already buckets (no DST, echoed back). A day counts toward the streak when the profile has at least one `reading_sessions` row in it that the caller's gate lets through: a few pages count, not only a finished chapter (cinematic §9.2.2). Mark-read saves (`manual: true`, backend/02) create no session and therefore never extend a streak.
- **`current_days`** keeps today's rule in `_streak`: alive while the last active day is today or yesterday, 0 once a whole day is missed.
- **`at_risk`** is true exactly when `current_days >= 1`, `last_active_date` is yesterday (local), and the local time is 20:00 or later. Cinematic shows the at-risk state from 1 day up; Glass draws it only from 2 days up (glass §9.2.2) and applies that `current_days >= 2` check itself on top of this flag.
- **`extended_today`** is `last_active_date == local today` after the save has been applied.
- **`today_seconds`** is the capped (`SESSION_SECONDS_CAP`) reading seconds of the local day so far, gate-filtered, the same arithmetic as `window.seconds_read`.
- **Milestones** are 7, 30, 100 and 365 days; any other value is 422.
- **Mature, for `shareable`**, is the stats module's own rule, `mature_tracker_case(ReadingSession.source_id) == 1` over the outer-joined follow row (explicit override, then the rating captured at follow time, then the source's maturity), applied **whatever the gate says**. Mature genre words are the lower-cased members of `MATURE_CONTENT_RATINGS` plus `"ecchi"` (glass §9.2.4 lists Adult, Ecchi, Hentai, Mature, Smut); they never appear in any `shareable` genre list, even on a non-mature series.
- **Genre weights** are shares of reading seconds: each series' capped seconds in the window are credited to every genre in its `source_series_cache.genres` (compared case-insensitively, printed with the first spelling seen), divided by the window's total credited seconds, rounded to 3 decimals, top 8.
- **Shares** (`top_sources[].share`) are fractions of the window's seconds, rounded to 3 decimals.
- **Voices.** A listen session credits its full `seconds` to each of its (at most 3) `voice_ids`; `name` comes from `voice_pack.load_voices()`, falling back to the id when the pack no longer has it.
- **The Circle.** `circle` is always `null` in this step; backend/08 computes it (and the colophon's `WITH`) from the shareable activity set.

## Scope, item by item

### A. Migration `0021_streaks_listen_sessions`

`backend/alembic/versions/0021_streaks_listen_sessions.py`, `down_revision = "0020_collection_rules"`. Two per-profile user-data tables (never cache: never in `CACHE_TABLES`), both scoped like `chapter_progress`: a composite `ForeignKeyConstraint(["user_id", "profile_id"], ["reading_profiles.user_id", "reading_profiles.id"], ondelete="CASCADE")` and a single-column `profile_id` index for the profile-delete cascade.

`streak_milestones`:

| Column | Type | Notes |
|---|---|---|
| `user_id` | Integer, FK `users.id` | PK part |
| `profile_id` | Integer, FK `reading_profiles.id` ON DELETE CASCADE | PK part |
| `days` | Integer | PK part; 7, 30, 100 or 365 |
| `seen_at` | DateTime, not null | |

Constraint name `fk_streak_milestones_scope`; index `ix_streak_milestones_profile_id`.

`listen_sessions`:

| Column | Type | Notes |
|---|---|---|
| `id` | Integer PK | |
| `user_id`, `profile_id` | as above | |
| `source_id` | String(64), not null | |
| `series_key`, `chapter_key` | String(512), not null | stored `fully_unquote`d |
| `seconds` | Integer, not null | 10 to 14,400 |
| `voice_ids` | Text, not null, server default `'[]'` | JSON array, at most 3 |
| `started_at` | DateTime, not null | client clock, clamped |
| `created_at` | DateTime, not null | |

Constraints: `fk_listen_sessions_scope`; `UniqueConstraint("user_id", "profile_id", "source_id", "series_key", "chapter_key", "started_at", name="uq_listen_sessions_push")` (an outbox replay of the same session inserts nothing); indexes `ix_listen_sessions_started_at (user_id, profile_id, started_at)` and `ix_listen_sessions_profile_id`.

Models `StreakMilestone` and `ListenSession` in `backend/database/models.py`, matching exactly. Update `test_migrations_alembic.py` (`_HEAD`, `_REVISIONS`, `_EXPECTED_TABLES`) and any test that enumerates profile-scoped tables (`test_audit_isolation_profile_delete_cascade.py`, `test_audit_integrity_scope_fk.py`) so both new tables are covered.

### B. The one streak object

In `ReadingStatsService` add public methods (backend/04 reuses them for `GET /home`):

- `streak() -> {"current_days": int, "longest_days": int, "at_risk": bool, "last_active_date": "YYYY-MM-DD" | null, "milestones_seen": [int]}`: today's `_streak(self._active_days())` plus `at_risk` (rule above) and `milestones_seen` (the profile's `streak_milestones.days`, ascending). `build()` uses it for its `"streak"` key.
- `today_seconds() -> int`.

`GET /library/statistics` therefore returns the full object under `streak`, unchanged otherwise, plus the `shareable` block of item E computed over the requested window. Its `tz_offset_minutes` query parameter already exists (−720 to 840).

`POST /library/statistics/milestones/{days}/seen` in `backend/routes/library.py`, `require_profile_context`, 204: `days` not in {7, 30, 100, 365} → 422 `invalid_milestone`; otherwise an idempotent insert (`sqlite` `insert(...).on_conflict_do_nothing()`), so a second call and a call from another device are both 204 and leave one row.

### C. Streak and today's time on progress saves

`POST /reader/progress` and `POST /reader/progress/batch` gain the query parameter `tz_offset_minutes: int = Query(0, ge=-720, le=840)` (a query parameter so the batch's array body is unchanged). After the save commits, the response gains:

```json
"streak": {"current_days": 12, "extended_today": true},
"today_seconds": 480
```

beside the existing `advanced` (single save) or at the top level of `{saved, advanced, items, rejected}` (batch; glass §9.2.2: the outbox flushes through the batch, and its flare and goal ring update when the queued save is answered). Compute it with `ReadingStatsService(db, user_id, profile_id, gate_open=<the service's _gate_open()>, tz_offset_minutes=tz).streak()` and `.today_seconds()` in a `ProgressService.streak_snapshot(tz)` method. It runs after the save's commit and outside the `_write` retry: if it raises `OperationalError`, log it and return `"streak": null, "today_seconds": null`, because a statistics hiccup must never fail a save. The 503 `db_busy` path returns what it returns today.

### D. `GET /library/annual`

Route in `backend/routes/library.py`: `year: int | None = Query(None, ge=2000, le=2100)`, `tz_offset_minutes: int = Query(..., ge=-720, le=840)` (required, cinematic §9.2.7). `year` defaults to the current local year; a year after the current local year → 422 `invalid_year`. Service `backend/services/annual_service.py`: `class AnnualService(ReadingStatsService)` with `build(year) -> dict`, reusing the parent's scope, gate, day, hour and aggregate helpers with a `[since, until)` window: `since = datetime(year, 1, 1) − offset`, `until = min(datetime(year + 1, 1, 1) − offset, now)`.

Response (cinematic §9.2.7 plus glass §15.5 additions), every figure gate-filtered on serve for this profile except where `shareable` says otherwise:

```text
{
  year, partial (year == current local year), since, until (ISO UTC),
  recorded_days,                       distinct local days with a session in the window
  seconds_read, chapters_read, pages_read,
  chapters_by_month: [12 ints],        distinct chapters per local month
  top_series: [{source_id, series_key, title, cover_url, ambient, palette, seconds_read, chapters_read}] (≤ 5, by seconds),
  genres: [{genre, weight}] (≤ 8),
  by_hour: [24 × {hour, seconds_read}],
  longest_streak: {days, month (1–12, the month the run started), start, end (ISO dates)}   (inside the year; days 0 and nulls when empty),
  top_sources: [{source_id, name, share}] (≤ 3),
  busiest_day: {date, chapters, series: [{source_id, series_key, title, cover_url}] (≤ 5, non-mature only)} | null,
  firsts_lasts: {first: {series: {source_id, series_key, title, cover_url}, read_at}, last: {…}} | null   (non-mature only),
  circle: null,
  top_voices: [{voice_id, name, seconds}] (≤ 3),
  available_years: [int],              years with ≥ 7 recorded days, newest first
  shareable: {genre_weights, top_series, art_series, top_sources}
}
```

- Titles and covers of unfollowed series come from the series cache through `_fill_cached_titles`, as `_by_series` does. `ambient` and `palette` come from `attach_cover_colours`.
- `busiest_day` is the local day with the most distinct chapters (ties: the earlier date); its `series` lists that day's non-mature series by seconds.
- `firsts_lasts` uses the earliest and the latest session of the year among non-mature series; `null` when there is none.
- `top_voices` reads `listen_sessions` in the window, gate-filtered with the same outer join and `mature_tracker_case(ListenSession.source_id)` rule as reading sessions.
- **Cache** (cinematic §9.2.7): a module-level `collections.OrderedDict` of at most 64 composed payloads keyed `(user_id, profile_id, gate_open, year, tz_offset_minutes, local_date)`; a hit is returned as is; a gate change, another year, another offset or a new local day reads a different key and composes afresh (no purge hook). `reset_annual_cache()` clears it, and `backend/tests/conftest.py` gets an autouse fixture that calls it around every test, because test databases reuse profile ids. Mark the ceiling in code: `# ponytail: per-process cache; the backend runs one process (python main.py), move to a table if it ever runs several.`

### E. `shareable`, never mature

`shareable` is computed from sessions whose series is **not mature** (the rule above, whatever the gate), on both `GET /library/annual` (the year) and `GET /library/statistics` (the requested window, "the range payload behind The Numbers' Share", glass §9.2.4):

```text
shareable: {
  genre_weights: [{genre, weight}] (≤ 8, mature genre words removed, weights re-normalised over what remains),
  top_series:    [{source_id, series_key, title, cover_url, ambient, palette, seconds_read, chapters_read}] (≤ 5),
  art_series:    [{source_id, series_key, cover_url, ambient, palette}] (≤ 9; the Annual's cover mosaic and every card's art band),
  top_sources:   [{source_id, name, share}] (≤ 3, sources that are not mature, shares over the non-mature seconds)
}
```

`top_sources` is an addition to Cinematic's three keys so Glass's card 10 can take "the next eligible source" without a client rule (glass §9.2.4). Every list may be empty; the clients omit a template whose shareable data is empty.

### F. `POST /novels/listen-sessions`

In `backend/routes/novels.py` (so it exists only while `novels_enabled` is on, like the rest of Listen), `require_profile_context`. The body is an array of at most 200 items (more → 413 `batch_too_large` with `details: {max_items: 200, received}`, the progress batch's rule), validated item by item like `save_progress_batch` so one bad item never blocks an outbox:

```python
class ListenSessionRequest(BaseModel):
    source_id: str = Field(min_length=1, max_length=64)
    series_key: str = Field(min_length=1, max_length=512)
    chapter_key: str = Field(min_length=1, max_length=512)
    seconds: int = Field(ge=10, le=14_400)
    voice_ids: list[str] = Field(default_factory=list, max_length=3)
    started_at: datetime
```

`started_at` goes through `clamp_client_clock`; `voice_ids` are de-duplicated in order and filtered with `is_known_voice` (an unknown id is dropped, never rejected: a pack change must not jam the outbox); keys are stored `fully_unquote`d. Rows are inserted with `on_conflict_do_nothing` against `uq_listen_sessions_push`. Response 200: `{"saved": int, "duplicates": int, "rejected": [{"index", "errors"}]}`. The clients send only sessions of 10 s or more, batched on pause, at chapter end and when the app goes to the background (cinematic §9.2.7); the server does not rely on that and enforces `seconds >= 10` itself.

### G. Tests (write them first)

`backend/tests/test_streaks_annual.py` and `backend/tests/test_listen_sessions.py`. Freeze time by monkeypatching `services.reading_stats_service.utcnow` (and `services.annual_service.utcnow` if imported there): `freezegun` is not installed and must not be added.

1. **Streaks across timezone midnights**: sessions at 2026-09-20 00:30 UTC and 2026-09-21 23:30 UTC. At `tz_offset_minutes=0` they are consecutive days (`longest_days == 2`); at `+330` they fall on 20 and 22 September (`longest_days == 1`); at `-300` on 19 and 21 September (`longest_days == 1`). With "now" at 2026-09-22 10:00 UTC, `current_days` is 2 at offset 0 (yesterday was active) and matches the local rule at the other offsets.
2. **`at_risk`**: last active yesterday, local time 20:30 → `true`; 19:59 → `false`; read today → `false`; streak 0 → `false`; the same UTC instant gives different answers at `+330` and `-300` where it lands either side of 20:00.
3. **Milestone once per profile**: two `POST …/milestones/7/seen` calls → both 204, one row, `milestones_seen == [7]` on statistics; a sibling profile's list stays `[]`; `/milestones/8/seen` → 422; another account cannot write into this profile (the header check).
4. **Progress answers**: a first save of the local day returns `extended_today: true` and `today_seconds` equal to the credited seconds; a save on a day with no earlier session after a gap returns `current_days: 1`; a `manual: true` save (backend/02) on a day with no reading leaves `extended_today: false`; the batch response carries the same two keys at the top level; a forced `OperationalError` in `streak_snapshot` still returns 200 with `streak: null`.
5. **Annual shape**: every key of D present with the right types, `chapters_by_month` has 12 ints, `by_hour` 24 entries, `partial` true only for the current local year, `available_years` lists only years with at least 7 recorded days, `invalid_year` 422 for next year, and the missing `tz_offset_minutes` → 422.
6. **Shareable never contains a mature title, cover or genre**: with the gate **open**, read a series whose source is mature, one whose follow has `content_rating "adult"`, one with `mature_override = 1`, and one safe series tagged with genres `["Action", "Smut", "Ecchi"]`. `top_series` (gated data) contains the mature ones; `shareable.top_series`, `art_series`, `busiest_day.series` and `firsts_lasts` contain none of their titles or cover URLs; `shareable.genre_weights` contains no mature genre word; `shareable.top_sources` has no mature source. The same holds on `GET /library/statistics?days=365`.
7. **Gate on serve**: with the gate closed, the Annual's totals, `top_series`, `genres`, `top_voices` and `available_years` exclude the mature series' sessions entirely.
8. **Cache**: a second call with the same key does not recompose (count compositions via monkeypatch); flipping the profile's gate, changing `year`, changing `tz_offset_minutes` or advancing the frozen clock to the next local day each recompose.
9. **Listen sessions**: 3 items save; the same array again gives `saved 0, duplicates 3`; 201 items → 413; an item with `seconds: 5` lands in `rejected` while the others save; an unknown voice id is dropped; the route is 404 with novels disabled; `top_voices` sums seconds per voice across sessions and names them from the pack; another profile's sessions never count.
10. **Isolation**: every new read is scoped to `(user_id, profile_id)`: two profiles on one account and two accounts each see only their own streak, milestones, Annual and voices.

### H. Proof

`backend/scripts/dev_stack.sh restart`, then into `docs/redesign/proof/backend-03/` with `backend/scripts/dev_stack.sh api …`:

- `statistics.json`: `GET /library/statistics?days=30&tz_offset_minutes=330` (Riya's seeded six-day streak with `at_risk`, `milestones_seen` and `shareable`)
- `annual.json`: `GET /library/annual?year=2026&tz_offset_minutes=330`
- `progress-answer.json`: one `POST /reader/progress?tz_offset_minutes=330` for a seeded chapter, showing `streak` and `today_seconds`
- `listen.json`: `POST /novels/listen-sessions` with two sessions on the seeded novel follow, then the Annual's `top_voices` (empty if the dev box has no voice pack: say so)
- `pytest-after.txt`: the last 25 lines of the full suite.

## File layout

Created: `backend/alembic/versions/0021_streaks_listen_sessions.py`, `backend/services/annual_service.py`, `backend/tests/test_streaks_annual.py`, `backend/tests/test_listen_sessions.py`, `docs/redesign/proof/backend-03/*`.

Changed: `backend/database/models.py` (`StreakMilestone`, `ListenSession`), `backend/services/reading_stats_service.py` (`streak`, `today_seconds`, the `shareable` helper shared with the Annual), `backend/services/followed_series_service.py` (`statistics` adds `shareable`), `backend/services/progress_service.py` (`streak_snapshot`), `backend/routes/library.py`, `backend/routes/reader.py`, `backend/routes/novels.py`, `backend/tests/conftest.py` (the annual-cache reset fixture), `backend/tests/test_migrations_alembic.py`, and the table-enumerating audit tests named in A.

## Acceptance criteria

- [ ] `GET /library/statistics` returns `streak {current_days, longest_days, at_risk, last_active_date, milestones_seen}` and `shareable`; `ReadingStatsService.streak()` is public for `/home`.
- [ ] `POST /library/statistics/milestones/{days}/seen` is idempotent, profile-scoped, 204, and 422 for days outside 7, 30, 100, 365.
- [ ] `POST /reader/progress` and `/reader/progress/batch` answer `streak {current_days, extended_today}` and `today_seconds` in the `tz_offset_minutes` day, and a failure computing them never fails the save.
- [ ] `GET /library/annual?year=&tz_offset_minutes=` returns every field of section D, `available_years` included, with the Circle left `null` for backend/08.
- [ ] `shareable` (Annual and statistics) never contains a mature title, cover, source or genre word, whatever the gate; the rest of both payloads is gate-filtered on serve.
- [ ] The Annual is cached per `(user_id, profile_id, gate, year, tz, local date)` and recomposes on any change of those.
- [ ] `POST /novels/listen-sessions` stores up to 200 sessions per call, deduplicates replays, and feeds `top_voices`.
- [ ] Revision `0021_streaks_listen_sessions` is the head and matches the models; both new tables cascade on profile delete.
- [ ] Per-skin difference: Cinematic reads the streak object (flame tiers and states, milestone title cards), The Annual's eleven pages and `shareable` for the press run; Glass reads the same object (applying its own `current_days >= 2` on `at_risk`), `extended_today` and `today_seconds` for the flare and the daily goal ring, Wrapped's twelve cards (including `pages_read`, `busiest_day`, `firsts_lasts`, `longest_streak.start/end`) and `shareable` (including `top_sources`) for the share side.
- [ ] No UI changes: `git diff --stat -- frontend mobile` is empty, so reduced-motion, keyboard access and 44 pt hit targets are unaffected by construction.
- [ ] The full backend suite passes with the previous step's pass count plus the new tests; nothing that passed before fails.

## Verification

```bash
cd /srv/manhwamaniacs/dev/ManhwaManiacs/backend
free -m
.venv/bin/python -m pytest -q --no-header tests/test_streaks_annual.py tests/test_listen_sessions.py tests/test_reading_statistics.py tests/test_audit_stats_rollup.py tests/test_audit_stats_recent_sittings.py tests/test_progress_db.py tests/test_novels_flag.py tests/test_migrations_alembic.py tests/test_audit_isolation_profile_delete_cascade.py tests/test_audit_integrity_scope_fk.py
free -m
timeout 1800 .venv/bin/python -m pytest -q --no-header
```

Web and mobile suites are not run: `git diff --stat -- frontend mobile` must print nothing. Their baseline commands, for the record: `npm run lint` and `npm run build` in `frontend/`; `/srv/manhwamaniacs/dev/flutter/bin/flutter analyze` and `/srv/manhwamaniacs/dev/flutter/bin/flutter test` in `mobile/`.

## RAM guard

`free -m` before every pytest run and before `dev_stack.sh restart`; stop and report under 1024 MB available. One heavy command at a time.

## Git

- Branch `feat/vps-slim-source-native`; one commit per working step, pushed after each: `git push origin feat/vps-slim-source-native`.
- Suggested subjects: `feat(backend): streak milestones and listen sessions tables`, `feat(backend): one streak object with at_risk and milestones`, `feat(backend): streak and today's time on progress saves`, `feat(backend): the Annual with shareable blocks and a per-day cache`, `feat(backend): listen sessions for the colophon's voices`, `docs(redesign): backend-03 proof`.
- Stage explicit paths only. No Claude or AI attribution (no `Co-Authored-By`, no "generated with" line). Never commit secrets, `.claude/`, `backend/.venv/` or dev data.

## Never

- Never edit `backend/connectors/`.
- Never touch production containers, `/srv/manhwamaniacs/app` or `/srv/manhwamaniacs/data`.
- Never add `freezegun` or any other dependency for this step.

## Report back

1. Done items A to H with commit SHAs.
2. Backend test counts before and after, and the new test names.
3. Proof path `docs/redesign/proof/backend-03/` and its files (no screenshots: no screen changes).
4. Open issues, and two hand-offs: for backend/04, `GET /home` reuses `ReadingStatsService.streak()` for its `numbers` item; for backend/08, the Annual's `circle` and the colophon's `WITH` are still `null` and must be computed from the shareable activity set S(member, viewer).

Next prompt file in the series: `docs/redesign/prompts/web/06-cinematic-shell-navigation-transitions.md`. Next file in the backend track: `docs/redesign/prompts/backend/04-ai-home-composition.md`.
