# Backend 08: Circle core, sharing, feed and presence (new feature 3, part 1)

**Goal.** Build the server half of the Circle that both skins render: per-profile sharing switches (`GET` and `PATCH /profiles/{id}/sharing`, with every Cinematic switch plus Glass's `show_presence` and `share_streak`), the Circle activity record, and the one rule every Circle figure is computed from, the shareable activity set S(member, viewer). On top of S you ship `GET /circle/members` (with `now`, `last_active_at` and a shared streak), `GET /circle/members/{profile_id}`, `GET /circle/feed` with its `reading` and `reaction` filters, `GET /circle/series`, `DELETE /circle/activity`, the `circle` and `circle_top` sections of `GET /home`, and the Circle block of The Annual (`GET /library/annual`). Everything is profile-scoped, applies the 18+ gate when serving (never when storing), and is additive, so today's web and mobile clients keep working unchanged. Reactions, letters and shared shelves are the next step (`backend/09`), which builds on the tables and the S rule you write here, so write S once, in one place, and make every surface call it.

---

## Read first

Read these before planning. They are binding; where this file quotes a value, the quote is the one to build.

1. `docs/redesign/cinematic/DESIGN.md`
   - §9.3.1 Model and privacy (the switches, isolation, gate on serve, the definition of S)
   - §9.3.2 Circle screen (what the feed sentences need, `NOW` within 15 minutes, the reading-now ring, the states)
   - §9.3.6 Settings → Circle & privacy (the rows your `/sharing` endpoints feed, `Clear my shared activity`)
   - §9.3.7 Member page (`/circle/:profileId`, "Reading 4 series", the not-sharing state)
   - §9.3.8 Backend (every endpoint and response shape; polling every 60 s)
   - §9.1.7 the `GET /home` contract table and the "`GET /home` section items" table (row `circle`, `circle_top`)
   - §8.8 row table for `From the Circle` (`circle`) and `Most read in the circle` (`circle_top`)
   - §9.2.4 The Annual, page 9 "The circle" and page 10 colophon `WITH` line; §9.2.7 Backend
   - §15.5 Backend additions (the Circle rows) and §15.10 Owner calls (Circle reciprocity)
2. `docs/redesign/glass/DESIGN.md`
   - §9.3 Social for 2–3 users (the switch table with defaults, isolation rules, the spoiler guard paragraph)
   - §9.3.1 Circle (presence arc: reading now, active today, away; shared streak on the orb)
   - §9.3.5 A friend (`GET /circle/members/{profile_id}`: `reading` without progress, `404 circle_member_not_sharing`)
   - §9.3.7 Backend used (the `now`, `last_active_at` and `streak` fields)
   - §8.25.15 Circle and privacy (the rows and their defaults)
   - §9.2.3 Wrapped, the **Data** line (card 11 reads `circle`) and card 11 "Together"
   - §15.5 Backend additions (the Circle row) and §15.6 Cross-skin contract alignment (rows **Presence**, **Sharing switches**, **Activity**)
3. `docs/redesign/inventory/00-decisions.md` (new feature 3: social for 2–3 users, respecting per-profile isolation and the 18+ gate)
4. `docs/redesign/stack-decision.md` §2.6 item 2 (the social feed and its per-profile and 18+ filtering run on the backend; shared caches apply the 18+ gate when serving)
5. `docs/redesign/inventory/capabilities.md` §1 (auth transport, `X-Profile-Id`, the error envelope `{code, message, details}`, "the 18+ gate is absence, never a lock"), §5 Profiles, §6 the 18+ gate, §26 row "Social for 2-3 users"
6. `docs/redesign/00-baseline.md` (toolchain, memory figures; this step touches no web or mobile code)
7. `docs/redesign/prompts-plan.json`, the entry whose `path` is this file (the scope you deliver)
8. The code you extend (read each fully before changing it):
   - `backend/core/profile_context.py` (`require_profile_context`, `ProfileContext`)
   - `backend/core/content_rating.py` (`resolve_mature_gate`, `resolve_series_rating`, `resolve_tracker_rating`, `hidden_by_gate`, `TRACKER_RATING_MATURE`)
   - `backend/core/connector_directory.py` (`descriptor_for_source`, `is_mature_source`; `descriptor.content_kind` is `"novel"` for novel sources)
   - `backend/database/models.py` (`ReadingProfile`, `FollowedSeries`, `ChapterProgress`, `SourceSeriesCache`, the composite `(user_id, profile_id)` foreign-key pattern on `ChapterProgress`)
   - `backend/services/progress_service.py` (`_apply_one`, `save_one`, `save_batch`, `ProgressInput`, including the `manual` flag `backend/02` added)
   - `backend/services/followed_series_service.py` (`patch_series`, `READING_STATUSES`)
   - `backend/services/profile_service.py` and `backend/routes/profiles.py`
   - `backend/services/reading_stats_service.py` (the streak object `backend/03` built, and The Annual composer `backend/03` added)
   - the `GET /home` composer `backend/04` added (find it with `grep -rn '"circle_top"\|"because"' backend/services backend/routes`)
   - `backend/services/cover_colour.py` from `backend/01`, specifically `attach_cover_colours(db, items, key=lambda item: (item["source_id"], item["series_key"]))`, which sets `ambient` and `palette` on every item from the `cover_palette` table (null on a miss) and never fetches; Circle rows call it once per response and never compute a palette themselves
   - `backend/scripts/README-dev-stack.md` and `docs/redesign/proof/backend-00/pytest-baseline.txt` from `backend/00` (the dev stack, its `api` subcommand, and the backend pass count every step keeps)
   - `backend/tests/conftest.py` (`client`, `as_user`, `make_user`, `make_profile`, `seed_follow`), `backend/tests/test_profile_isolation.py`, `backend/tests/test_migrations_alembic.py`, `backend/tests/test_audit_isolation_profile_delete_cascade.py`, `backend/tests/test_audit_migrations_autogenerate_fts.py`

## Preconditions (check first; stop and report if one fails)

- `git -C /srv/manhwamaniacs/dev/ManhwaManiacs branch --show-current` prints `feat/vps-slim-source-native`, and `git status --short` shows no uncommitted changes under `backend/`. Record the starting commit: `BASE=$(git -C /srv/manhwamaniacs/dev/ManhwaManiacs rev-parse HEAD)` (write the hash into your plan; the final checks diff against it).
- `backend/.venv/bin/python` exists (created by `backend/00`).
- `backend/03` has landed: `grep -rn '/annual' backend/routes` finds `GET /library/annual`, and `grep -rn 'milestones_seen' backend/services` finds the streak object.
- `backend/04` has landed: `grep -rn '"/home"\|prefix="/home"' backend/routes backend/api` finds `GET /home`.
- `backend/01` has landed: `grep -n 'def attach_cover_colours' backend/services/cover_colour.py` matches.
- `backend/02` has landed: `grep -n 'manual' backend/services/progress_service.py` finds the `manual` flag.
- `cd backend && .venv/bin/alembic heads` prints exactly one head.

If any check fails, do not improvise the missing step: report which one failed and stop.

## Skills to invoke

- `superpowers:writing-plans` before touching code: write the plan to `docs/redesign/proof/backend-08/plan.md` (one task per numbered scope item below).
- `superpowers:test-driven-development` for every endpoint and for S: the failing test first.
- `superpowers:subagent-driven-development` to run the plan (one subagent per task, sequential, never two pytest runs at once); use `superpowers:executing-plans` instead if subagents are unavailable.
- `superpowers:verification-before-completion` before you claim anything is done.
- `impeccable`, `taste-skill:taste-skill` and `frontend-design` are **not** invoked: this step ships no UI. The clients that render this API are `web/22`, `mobile/22` (Cinematic) and `web/43`, `mobile/43` (Glass).

## Session rules

- **Scope lock.** Work only in `backend/` (never `backend/connectors/`) plus `docs/redesign/proof/backend-08/` (plan and proof). Do not edit `frontend/`, `mobile/`, `ops/`, or anything under `/srv/manhwamaniacs/{app,data}`. Never restart, rebuild or exec into production containers.
- **RAM guard.** Production shares this box. Run `free -m` before every full pytest run and before starting the dev stack; if the `available` column is under 1024 MB, stop and report. Never run two pytest runs, or pytest and the dev stack's seed, at the same time.
- **Git.** Commit small and often on `feat/vps-slim-source-native`, one commit per working step (migration + models; sharing endpoints; event recording; S and the feed; members and presence; member page and series; delete; home sections; annual block; docs), and `git push` after each commit. Stage paths explicitly (`git add backend/<path> …`), never `git add -A`. Commit messages are Conventional Commits (`feat(circle): …`, `test(circle): …`). **No Claude or AI attribution anywhere**: no `Co-Authored-By`, no "Generated with" line, no AI author. Never commit secrets, `.env` files or `.claude/`.
- **Additive only.** No existing response field changes type or meaning; no existing endpoint changes shape.
- Changes to shared code (`progress_service.py`, `followed_series_service.py`, the `/home` and Annual composers) are the smallest hook that works; existing tests for those files must stay green untouched.

---

## Scope (deliver every item)

### 1. Migration and models

One Alembic revision, file `backend/alembic/versions/NNNN_circle_core.py`, where `NNNN` is the highest four-digit prefix in `backend/alembic/versions/` plus one (zero-padded), `revision = "NNNN_circle_core"` (revision ids stay at or under 32 characters: `alembic_version.version_num` is `VARCHAR(32)`), `down_revision` = the single id `alembic heads` printed, with a module docstring in the house style of `0017_world_catalog_cache.py`. It does exactly this, and `backend/database/models.py` declares the same schema so autogenerate reports no diff:

- **`reading_profiles` gains eight columns** (`op.add_column`, no table rebuild):

  | Column | Type | Default | API field |
  |---|---|---|---|
  | `share_activity` | Integer (bool), NOT NULL | `server_default="0"` | `activity` (the master, Cinematic "Share what I'm reading", Glass "Share what I'm reading") |
  | `share_reactions` | Integer (bool), NOT NULL | `"1"` | `reactions` |
  | `share_shelves` | Integer (bool), NOT NULL | `"1"` | `shelves` |
  | `share_recommendations` | Integer (bool), NOT NULL | `"1"` | `recommendations` |
  | `share_include_mature` | Integer (bool), NOT NULL | `"0"` | `include_mature` |
  | `share_presence` | Integer (bool), NOT NULL | `"0"` | `show_presence` (Glass §9.3 table: default off, enforced by the server for both skins) |
  | `share_streak` | Integer (bool), NOT NULL | `"0"` | `share_streak` (Glass addition, default off) |
  | `share_activity_since` | DateTime, NULL | none | not exposed; set to `utcnow()` when `share_activity` turns on, set to NULL when it turns off |

  The defaults are glass §9.3's switch table and cinematic §9.3.1 ("nothing is visible to anyone until a profile turns sharing on").
- **`circle_hidden_series`** (Cinematic "Hide this series from my activity", Glass "Hidden from my Circle", `excluded_series`): `user_id` Integer FK `users.id`; `profile_id` Integer FK `reading_profiles.id` `ondelete="CASCADE"`; `source_id` String(64); `series_key` String(512); `title` String(512) NOT NULL; `created_at` DateTime default `utcnow`. Primary key `(profile_id, source_id, series_key)`. A composite `ForeignKeyConstraint(["user_id", "profile_id"], ["reading_profiles.user_id", "reading_profiles.id"], ondelete="CASCADE", name="fk_circle_hidden_series_scope")`, copied from the `ChapterProgress` pattern.
- **`circle_events`** (the Circle activity record): `id` Integer PK; `user_id` FK `users.id`; `profile_id` FK `reading_profiles.id` `ondelete="CASCADE"`; composite FK `fk_circle_events_scope` as above; `kind` String(24) NOT NULL, one of `started`, `finished_chapter`, `finished_series`, `reacted`; `source_id` String(64) NOT NULL; `series_key` String(512) NOT NULL; `chapter_key` String(512) NULL; `chapter_number` Float NULL; `reaction` String(16) NULL (only for `reacted`, written by `backend/09`); `title` String(512) NOT NULL; `cover_url` String(1024) NULL; `created_at` DateTime NOT NULL. Indexes: `ix_circle_events_profile_created (profile_id, created_at, id)`, `ix_circle_events_created (created_at, id)`, `ix_circle_events_series (source_id, series_key)`.
- `downgrade()` drops the two tables and the eight columns (use `op.batch_alter_table("reading_profiles")` for the column drops).
- Neither table goes in `core/cache_tables.CACHE_TABLES`: they are user data and belong in backups.
- Update `backend/tests/test_migrations_alembic.py`: `_HEAD`, `_REVISIONS` (append the new file name) and `_EXPECTED_TABLES` (add `circle_hidden_series`, `circle_events`).

### 2. Sharing endpoints (`backend/routes/profiles.py`, logic in `backend/services/circle_service.py`)

- `GET /profiles/{profile_id}/sharing` → 200
  ```json
  {"activity": false, "reactions": true, "shelves": true, "recommendations": true,
   "include_mature": false, "show_presence": false, "share_streak": false,
   "excluded_series": [{"source_id": "…", "series_key": "…", "title": "…"}]}
  ```
  `excluded_series` ordered by `created_at` descending.
- `PATCH /profiles/{profile_id}/sharing` with a partial body of the same fields (every field optional; Pydantic `model_config = ConfigDict(extra="forbid")`, so an unknown field is `422`). Booleans update their column. `excluded_series`, when present, **replaces** the whole list (at most 500 entries, each `{source_id (1–64), series_key (1–512), title? (≤512)}`, `series_key` percent-decoded with `connectors.ids.fully_unquote`; a missing `title` is filled from the profile's follow row, else `source_series_cache.title`, else the `series_key`). Turning `activity` from off to on sets `share_activity_since = utcnow()`; turning it off sets it to NULL. Returns the full GET shape.
- Both endpoints accept only a profile the session's account owns (reuse `ProfileService._get_owned`): another account's profile or an unknown id is `404` with the existing not-found code, exactly like `PATCH /profiles/{id}`. `X-Profile-Id` is not required to match (household model, as the rest of `/profiles`).
- **Effective 18+ sharing** everywhere below: `include_mature` counts only when the member's own gate is open, i.e. `effective_include_mature = share_include_mature AND mature_content_enabled`. A profile that closes its own gate stops sharing 18+ at once, without a write.

### 3. Recording Circle activity (`services/progress_service.py`, `services/followed_series_service.py`)

Events are recorded **only while the acting profile's `share_activity` is on**, with `created_at` = the push's believable instant (`merged.read_at or merged.last_read_at` in `_apply_one`; `utcnow()` in `patch_series`), and only when that instant is at or after `share_activity_since`. The 18+ rating is **not** checked when storing. `title` and `cover_url` are snapshotted from the actor's follow row, else `source_series_cache`, else `title = series_key` and `cover_url = NULL`. One helper `CircleService.record(...)` (or a module function in `circle_service.py`) does the write inside the caller's transaction (no commit of its own), so a rolled-back progress write rolls the event back too.

| Event | Trigger | Fields |
|---|---|---|
| `started` | `_apply_one` creates the profile's **first** `chapter_progress` row for that `(source_id, series_key)` | `chapter_key`, `chapter_number` of that row |
| `finished_chapter` | `_apply_one` flips `is_completed` from false (or no row) to true | `chapter_key`, `chapter_number` |
| `finished_series` | `patch_series` changes `reading_status` to `"completed"` from any other value | no chapter |

- A push with `manual: true` (`backend/02`'s "mark read" path) records **nothing**, so "Mark read up to here" never floods the feed.
- Re-reading a completed chapter records nothing (completion is sticky).
- The batch path (`save_batch`) records per item, inside its single transaction.
- `ponytail:` comment on the table: no retention sweep; add one if `circle_events` passes 100,000 rows.

### 4. The shareable activity set S(member, viewer): one rule, one place

Put it in `backend/services/circle_service.py` as `CircleService(db, user_id, profile_id)` with the viewer resolved from `require_profile_context`. If the context has no profile (an account with no profiles), every `/circle/*` endpoint answers `400 profile_required`. Every Circle figure in this step and in `backend/09` goes through these methods; no route or composer re-implements any part of them.

A **member** is a `reading_profiles` row that is not the viewer, whose account `users.is_active` is true, and whose `share_activity` is on. Members come from **every account** on the server and from the viewer's own account (cinematic §9.3.1 "a viewer sees profiles, not accounts"; glass §9.3 "the other accounts' profiles and the other profiles on the same account").

An event or a live reading position of member M is **in S(M, viewer)** when all of these hold:

1. M is a member (above), evaluated now, not when the event was written.
2. The timestamp (`circle_events.created_at`, or `chapter_progress.last_read_at` for presence and readers) is at or after `M.share_activity_since` (cinematic §9.3.1: "reading done before sharing was turned on never counts"; glass §9.3: "nothing is shared retroactively").
3. `(source_id, series_key)` is not in M's `circle_hidden_series`.
4. For `kind = reacted`: `M.share_reactions` is on.
5. **The both-sided 18+ rule**: if the series is mature, then M's effective `include_mature` is on **and** the viewer's gate is open (`resolve_mature_gate(db, viewer_profile_id, viewer_user_id)`). A mature item that fails is **absent**: no placeholder, no count, no "hidden" row (capabilities §1, glass §9.3 isolation rules).

**Maturity of a series for this pair**, method `series_mature(member, viewer, source_id, series_key) -> bool` (memoised per request):
- member side: M's `followed_series` row for the pair → `resolve_tracker_rating(row, descriptor_for_source(source_id))`; with no follow row, the `source_series_cache` row → `resolve_series_rating(content_rating, genres parsed from its JSON text, source_mature=is_mature_source(source_id))`; with neither, `is_mature_source(source_id)`;
- viewer side: the viewer's own `followed_series` row for the pair, if any, through `resolve_tracker_rating`;
- mature when **either** side resolves to `TRACKER_RATING_MATURE` (err towards hiding, as `core/content_rating.py` does). `unknown` is not mature (the codebase rule in `resolve_series_rating`).

Implementation shape: a SQL prefilter for rules 1–4 (join `reading_profiles` and `users`, `NOT EXISTS` on `circle_hidden_series`), then rule 5 in Python per distinct `(member, source_id, series_key)` through the memoised method. Paged reads fetch 200 rows at a time and keep filtering until they have `limit + 1` kept rows or the table is exhausted. Add a `ponytail:` comment: Python-side 18+ filter, fine for a 2–3 user server; move it into SQL with aliased `followed_series` joins if the feed ever exceeds 50 ms.

**Shared shapes** used by every response below:
- `ProfileRef`: `{"profile_id": int, "name": str, "avatar_key": str, "username": str}` (`username` is the account's `users.username`; cinematic §9.3.2 prints it as `@username` when two members share a name).
- `CircleSeries`: `{"source_id", "series_key", "title", "cover_url", "ambient", "palette", "content_kind"}` where `ambient` and `palette` are set by `attach_cover_colours` keyed on `(source_id, series_key)` (null until the cover has been served once; never computed here) and `content_kind` is `"novel"` when `descriptor_for_source(source_id).content_kind == "novel"`, else `"manga"`.
- Timestamps are ISO 8601 strings from naive UTC (`value.isoformat()`, the `_iso` convention of `progress_service.py`).

**Reciprocity** (cinematic §15.10 owner call, cinematic §9.3.2 state "This profile doesn't share"): the viewer does **not** need `share_activity` on to read anything in this step. Write the check as one clearly named constant `CIRCLE_REQUIRES_VIEWER_SHARING = False` in `circle_service.py`; when true, every `/circle/*` read answers as if there were no members. This is the "one server check" §15.10 names; leave it `False`.

### 5. `GET /circle/members` (`backend/routes/circle.py`)

New router: `APIRouter(prefix="/circle", tags=["circle"], dependencies=[Depends(require_profile_context)])`, included in `backend/api/router.py` beside the others.

Query: `tz_offset_minutes` (optional int, −720..840, default 0; `422` outside). Response 200, a JSON array ordered by `last_active_at` descending (nulls last), then `name`:

```json
[{"profile_id": 7, "name": "Riya", "avatar_key": "…", "username": "riya",
  "shares": {"activity": true, "reactions": true, "shelves": true, "recommendations": true},
  "now": {"source_id": "…", "series_key": "…", "chapter_key": "…", "chapter_number": 212.0,
          "title": "Omniscient Reader", "ambient": {…}, "palette": {…}, "since": "2026-09-29T20:41:03"},
  "last_active_at": "2026-09-29T20:41:03",
  "streak": {"current_days": 12, "alive_today": true}}]
```

- **`now`** (cinematic §9.3.8 shape plus Glass's `since`; glass §15.6 row **Presence**): take M's single most recent `chapter_progress` row. `now` is that row's position (`title`, `ambient` and `palette` resolved exactly as for `CircleSeries`: the member's follow row, else `source_series_cache`, else `title = series_key`) when **all** hold: `M.share_presence` is on; its `last_read_at` is within the last **15 minutes** (`PRESENCE_WINDOW = timedelta(minutes=15)`, cinematic §9.3.2 `NOW` badge and ring); the row passes S (rules 2, 3 and 5). Otherwise `now` is `null`. Do not fall back to an older row. `since` is that row's `last_read_at` (the time of the last page; the Cinematic ring fades 15 minutes after it). The spoiler guard for the chapter number is the client's (cinematic §9.3.2 hover line); the server sends the number.
- **`last_active_at`**: the latest `last_read_at` among M's `chapter_progress` rows (scan newest first, at most 50 rows) that pass S rules 2, 3 and 5; `null` when none. Sent whether or not `show_presence` is on (glass §15.6: "`last_active_at` still drives 'active today'").
- **`streak`**: present only when `M.share_streak` is on, else `null`. Build it with the streak function `backend/03` uses for `GET /library/statistics`, run for M's `(user_id, profile_id)` with the request's `tz_offset_minutes`: `current_days` is that object's `current_days`, `alive_today` is `last_active_date == today` in that offset (glass §9.3.7).
- `shares` mirrors M's four switches `activity`, `reactions`, `shelves`, `recommendations` (`backend/09` reads `shelves` and `recommendations`; `backend/09` also adds `can_receive` under `?source_id=&series_key=`).
- Clients poll this every 60 s while a Circle surface is visible (cinematic §9.3.8 **Polling**). Keep it one indexed query per member at most; no N+1 over events.

### 6. `GET /circle/members/{profile_id}`

`404` with code `circle_member_not_sharing` when the id is not a member for this viewer (unknown, the viewer itself, an inactive account, or `share_activity` off). Otherwise 200:

```json
{"profile": ProfileRef, "shares": {…same four…}, "now": …, "last_active_at": …, "streak": …,
 "reading":  [CircleSeries + {"last_activity_at": "…"}],
 "finished": [CircleSeries + {"finished_at": "…"}],
 "reactions": [CircleSeries + {"chapter_key", "chapter_number", "reaction", "created_at"}],
 "shelves": []}
```

- `now`, `last_active_at`, `streak`: exactly as in `GET /circle/members`.
- `reading`: distinct series with a `started` or `finished_chapter` event in S and no later `finished_series` event in S, newest activity first, no limit. **No progress field** (glass §9.3.5: posters only, no progress lines).
- `finished`: distinct series with a `finished_series` event in S, newest first, no limit.
- `reactions`: M's `reacted` events in S, newest first, at most 30 (they exist once `backend/09` writes them; the spoiler-guard `sealed` flag is added by `backend/09`).
- `shelves`: always `[]` in this step; `backend/09` fills it with M's shelves shared with the viewer.
- The Cinematic deck "Reading 4 series · shares activity and reactions" is `len(reading)` plus `shares`, computed after filtering (cinematic §9.3.1 "counts are computed after filtering").

### 7. `GET /circle/feed`

Query: `cursor` (optional string), `limit` (1–100, default 50), `profile_id` (optional int: one member's feed, glass §9.3.5 **Recent**; a non-member id returns `{"items": [], "next_cursor": null}`), `kind` (optional `reading` | `reaction`; anything else `422`). `reading` = `started`, `finished_chapter`, `finished_series`; `reaction` = `reacted` (cinematic §9.3.8). Letters are not feed items.

Response 200 (cinematic §9.3.8 shape, plus three additive fields):

```json
{"items": [{"id": 381, "kind": "finished_chapter", "actor": ProfileRef,
            "source_id": "…", "series_key": "…", "title": "…", "cover_url": "…",
            "ambient": {…}, "palette": {…}, "content_kind": "manga",
            "chapter_key": "…", "chapter_number": 88.0, "reaction": null,
            "followed_by_viewer": false, "created_at": "…"}],
 "next_cursor": "20260929204103123456-381"}
```

- Ordered by `(created_at DESC, id DESC)`. The cursor is the last item's `f"{created_at:%Y%m%d%H%M%S%f}-{id}"`; the next page is `WHERE (created_at, id) < (:c_at, :c_id)` (SQLite row values via `sqlalchemy.tuple_`). A malformed cursor is `422` code `invalid_cursor`. `next_cursor` is `null` on the last page.
- Only items in S. `followed_by_viewer` drives Cinematic's `Read it too` and Glass's "Read it too" (shown when false). `content_kind` drives Glass's `strip-scroll` / `book-open` mode glyph. `chapter_key`, `chapter_number`, `reaction` are `null` where the kind has none.
- Glass collapses consecutive chapter reads client-side (glass §9.3.1); the server sends every event.

### 8. `GET /circle/series?source=&series=`

Response 200 (cinematic §9.3.8): `{"followers": [ProfileRef], "readers": [{"profile": ProfileRef, "chapter_key": "…", "chapter_number": 150.0, "last_read_at": "…"}]}`.
- `followers`: members with a `followed_series` row for the pair whose `created_at` is at or after their `share_activity_since`, passing S rules 3 and 5.
- `readers`: members whose most recent `chapter_progress` row for the pair has `last_read_at` at or after their `share_activity_since`, passing S rules 3 and 5; that row's chapter, newest first. It feeds the feature page `CIRCLE` tab and the reader `CIRCLE` panel ("Riya is on Ch. 150").
- `source` and `series` are required (`422` when missing); `series` is percent-decoded with `connectors.ids.fully_unquote`, as the library routes do.

### 9. `DELETE /circle/activity` → 204

Deletes every `circle_events` row of the viewer profile (all kinds, including `reacted` rows `backend/09` writes), and when the viewer's `share_activity` is on, resets `share_activity_since` to `utcnow()` so nothing older can reappear. The library, progress and statistics are untouched (cinematic §9.3.6 dialog: "Your library isn't touched."). Idempotent.

### 10. `circle` and `circle_top` on `GET /home` (cinematic §9.1.7, §8.8; glass §9.1.1 "From your Circle")

Both sections are computed **fresh on every request, after the composed-cache read**, through the hook `backend/04` left for exactly this: append one builder `(ctx, payload) -> list[section]` to `home_service.LIVE_SECTION_BUILDERS` (never a second splice mechanism), and `compose()` inserts what it returns at the fixed places in the section order of cinematic §9.1.7 (`… because, circle, circle_top, popular, sources …`). They are never written into the composed cache, so a member who turns sharing off, hides a series or closes their 18+ sharing disappears from the next `/home` even inside the 10-minute cache window. Items follow `content_kind` of the request (`descriptor.content_kind`; a source with no installed descriptor is skipped).

- `circle` (title `"From the Circle"`): from S events of kinds `started`, `finished_chapter`, `finished_series` in the last 14 days, one item per `(member, series)` keeping the newest, newest first, at most 20. Item: `{"member": ProfileRef, "series": CircleSeries}`.
- `circle_top` (title `"Most read in the circle"`): over S events of those kinds in the last 7 days, group by series; rank by distinct members descending, then event count descending, then newest event; top 10. Item: `{"member": ProfileRef of the most recent actor, "series": CircleSeries, "rank": 1..10}`.
- Each section object carries `type`, `title`, `items`, `state` (`"ready"` with items, `"empty"` without; never `unavailable`, these are not AI sections) and `generated_at` (serve time), matching the section shape `backend/04` emits.

### 11. The Circle block of The Annual (`GET /library/annual`)

Add one top-level field `circle`, computed fresh per request **outside** the per-day composed cache of `backend/03` (the cached body never contains it):

```json
"circle": {"overlaps": [{"member": ProfileRef, "series": CircleSeries, "both": "finished" | "read"}],
           "with": [ProfileRef]}
```

- `circle` is `null` unless the viewer's own `share_activity` is on (cinematic §9.2.4 page 9 and colophon `WITH`: "only with Circle sharing on for both"; glass §9.2.3 card 11 "only when this profile shares").
- An **overlap** is a series the viewer read during the requested year (its `reading_sessions` inside the year window in `tz_offset_minutes`, the window `backend/03` already computes) for which S(member, viewer) holds at least one event dated inside the same window. Rule 5 applies, so a gated viewer never gets a mature overlap.
- `both` is `"finished"` when S holds a `finished_series` event for that member and series in the window **and** the viewer's own follow row has `reading_status == "completed"`; otherwise `"read"`.
- `overlaps`: `finished` first, then by the viewer's seconds on that series descending, at most 5. `with`: every member appearing in any overlap (not only the top 5), ordered by number of overlapping series descending.
- `shareable` (the share-card block) never contains Circle data; do not touch it.

### 12. API note for the client steps

Write `backend/docs/circle-api.md`: one section per endpoint of this step with its query, body, response shape, error codes (`profile_required`, `circle_member_not_sharing`, `invalid_cursor`, `422` validation) and the S rule in five lines. List the additive fields beyond the DESIGN shapes (`palette`, `content_kind`, `followed_by_viewer`, `last_active_at`, `streak`, `since`, Annual `circle.both`). `backend/09` appends its own sections to this file.

---

## File layout

| Path | Change |
|---|---|
| `backend/alembic/versions/NNNN_circle_core.py` | new migration (§1) |
| `backend/database/models.py` | eight `ReadingProfile` columns, `CircleHiddenSeries`, `CircleEvent` |
| `backend/services/circle_service.py` | new: `CircleService` (sharing read/write, `record`, `series_mature`, S prefilter and filter, members, member page, feed, series, clear, home sections, annual block), constants `PRESENCE_WINDOW`, `CIRCLE_REQUIRES_VIEWER_SHARING`, `get_circle_service` dependency |
| `backend/routes/circle.py` | new router (§5–§9) |
| `backend/routes/profiles.py` | `GET` and `PATCH /profiles/{profile_id}/sharing` (§2) |
| `backend/api/router.py` | include the circle router |
| `backend/services/progress_service.py` | event hooks in `_apply_one` (§3) |
| `backend/services/followed_series_service.py` | `finished_series` hook in `patch_series` (§3) |
| the `/home` composer from `backend/04` | splice `circle`, `circle_top` after the cache read (§10) |
| the Annual composer from `backend/03` | add `circle` after the cache read (§11) |
| `backend/tests/test_circle_core.py` | new (tests below) |
| `backend/tests/test_circle_mature_gate.py` | new (the 18+ matrix below) |
| `backend/tests/test_migrations_alembic.py` | `_HEAD`, `_REVISIONS`, `_EXPECTED_TABLES` |
| `backend/docs/circle-api.md` | new (§12) |
| `docs/redesign/proof/backend-08/plan.md` | the plan |
| `docs/redesign/proof/backend-08/*.json`, `pytest-before.txt`, `pytest-after.txt` | proof captures (Verification) |

## Tests (write them first; HTTP-level through `client` and `as_user(uid, pid)` unless noted)

World fixture: account 1 with profiles A and B, account 2 with profile C, account 3 with profile D (inactive account for one test). Reading happens through `POST /reader/progress` so the real hooks fire.

`test_circle_core.py`:
1. Sharing defaults: a new profile's `GET /profiles/{id}/sharing` equals the default JSON in §2.
2. `PATCH` is partial; an unknown field is `422`; another account's profile is `404` on GET and PATCH; `excluded_series` replaces the list and fills a missing title.
3. No retroactive sharing: C reads chapter 1 (completes it) with sharing off, turns `activity` on, completes chapter 2; A's feed shows only chapter 2. C turns sharing off: A's feed has no C items; C turns it on again: the earlier items stay hidden.
4. Isolation across accounts and profiles: with B and C sharing and A not sharing, A's `GET /circle/members` lists B and C (same account and other account), never A itself; with B not sharing, B is absent and none of B's events appear anywhere; C's bookmarks, history and statistics never appear in any `/circle/*` payload (assert on the JSON text).
5. Reciprocity: A shares nothing and still reads C's feed, members and series readers.
6. Hidden series: C hides series X; X vanishes from A's feed, members `now`, member page, `/circle/series` and the `/home` sections, and returns when unhidden.
7. Presence privacy: C sharing with `show_presence` off reads within 15 minutes → `now` is `null`; with it on → `now` set with `since`; last read 16 minutes ago → `null`; reading a hidden series → `null`; `last_active_at` is present in all three cases except the hidden one.
8. Streak only when shared: `streak` is `null` with `share_streak` off and an object with `current_days` and `alive_today` with it on.
9. Member page: `404 circle_member_not_sharing` for a non-sharing profile, for the viewer's own id and for the inactive account's profile; `reading` excludes a series with a later `finished_series`; `reading` items have no progress field.
10. Feed paging and filters: 120 events page as 50 + 50 + 20 with stable order and no duplicates; `kind=reading` excludes `reacted` rows (insert one directly), `kind=reaction` returns only it; `profile_id` narrows to one member; a malformed cursor is `422 invalid_cursor`.
11. `manual: true` progress records no event; re-completing a completed chapter records none; `reading_status → completed` records one `finished_series`.
12. `DELETE /circle/activity` removes C's events from A's view immediately and returns 204 twice in a row.
13. `/home` sections: `circle` and `circle_top` present and ranked per §10; after C turns sharing off, the very next `/home` for A (inside the cache window) has both sections `empty`.
14. Annual block: `circle` is `null` for a viewer with sharing off; with A and C sharing and both reading series X in the year, `overlaps` has X with `both: "read"`, and `"finished"` after both finish; `with` lists C.
15. Profile deletion cascades: deleting C removes its `circle_events` and `circle_hidden_series` rows (the existing `test_every_profile_id_fk_cascades_in_the_orm_schema` must also pass).

`test_circle_mature_gate.py` (parametrised over the four combinations of C's effective `include_mature` on/off × A's gate open/closed, with series M mature by source and series N mature only by C's `mature_override`): M and N appear in A's feed, members `now`, member page, `/circle/series`, `/home` sections and Annual overlaps **only** in the (on, open) cell; in every other cell they are absent and every count excludes them. Plus: C with `include_mature` stored true but C's own gate closed counts as off; A's own `mature_override = true` on a series C shares as safe hides it from A when A's gate is closed.

## Acceptance criteria

- [ ] One migration `NNNN_circle_core.py` upgrades and downgrades cleanly; `test_alembic_head_matches_models` and `test_autogenerate_against_head_reports_no_diff` pass.
- [ ] `GET /profiles/{id}/sharing` returns the §2 defaults (activity off, reactions on, shelves on, recommendations on, include_mature off, show_presence off, share_streak off); `PATCH` is partial, validates, and 404s for another account's profile.
- [ ] Events are written only while sharing is on, never for `manual: true`, and nothing read before sharing turned on ever reaches another profile.
- [ ] S lives in `services/circle_service.py` only; every endpoint, the `/home` sections and the Annual block call it (grep shows no second copy of the 18+ rule for Circle data).
- [ ] The both-sided 18+ rule holds on every surface in the matrix test; absent means absent (no placeholder, no count).
- [ ] `now` is `null` unless the member's `show_presence` is on and they read within 15 minutes a series the viewer may see; `last_active_at` and `streak` behave as §5.
- [ ] `GET /circle/members/{id}` returns `404 circle_member_not_sharing` for non-members; `reading` carries no progress.
- [ ] `GET /circle/feed` pages with `cursor` and `limit` (default 50), filters by `kind` and `profile_id`, and carries `followed_by_viewer` and `content_kind`.
- [ ] `GET /circle/series` returns followers and readers under S.
- [ ] `DELETE /circle/activity` is 204 and idempotent and leaves the library untouched.
- [ ] `/home` carries `circle` and `circle_top` computed per request, never cached; the Annual carries `circle` computed per request, never cached, `null` when the viewer does not share.
- [ ] A profile that shares nothing still sees sharers (`CIRCLE_REQUIRES_VIEWER_SHARING = False`).
- [ ] Per-skin differences are all served by one API: Cinematic reads `now.title`, `now.ambient`, `now.chapter_number` and ignores `streak`; Glass reads `now.since`, `last_active_at`, `streak` and `palette`; `show_presence` gates `now` for **both** skins (glass §15.6); no endpoint takes a skin parameter.
- [ ] Reduced motion, web keyboard access and 44 pt hit targets: not applicable to this backend step (no UI); the payloads carry no animation, layout or hit-target values. The client steps `web/22`, `mobile/22`, `web/43`, `mobile/43` own them.
- [ ] `git show --name-only --format= <hash> -- frontend mobile backend/connectors ops` for each of your own commits (never a branch or range diff: parallel sessions commit on the same branch) prints nothing.
- [ ] Every test that passed before your first change still passes; the new tests pass; 0 failed.
- [ ] `backend/docs/circle-api.md` documents every endpoint of this step.
- [ ] Proof JSON files exist under `docs/redesign/proof/backend-08/`.

## Verification (exact commands)

```bash
cd /srv/manhwamaniacs/dev/ManhwaManiacs/backend
free -m                                   # stop if "available" < 1024
timeout 1800 .venv/bin/python -m pytest -q --no-header 2>&1 | tail -25 > ../docs/redesign/proof/backend-08/pytest-before.txt   # BEFORE any change; compare with docs/redesign/proof/backend-00/pytest-baseline.txt (pre-existing failures listed there stay out of scope)
# … work …
.venv/bin/alembic heads                   # exactly one head: NNNN_circle_core
.venv/bin/python -m pytest -q --no-header tests/test_circle_core.py tests/test_circle_mature_gate.py tests/test_migrations_alembic.py tests/test_audit_migrations_autogenerate_fts.py tests/test_audit_isolation_profile_delete_cascade.py tests/test_profile_isolation.py tests/test_profiles.py
free -m
timeout 1800 .venv/bin/python -m pytest -q --no-header 2>&1 | tail -25 > ../docs/redesign/proof/backend-08/pytest-after.txt   # before count + new tests, 0 new failures
```

This step changes no web or mobile file, so the baseline's `npm run lint`, `npm run build` (in `frontend/`), `flutter analyze` and `flutter test` (in `mobile/`, Flutter at `/srv/manhwamaniacs/dev/flutter/bin`) are not re-run; prove it with `git show --name-only --format= <hash> -- frontend mobile` for each of your own commits (never a branch or range diff: parallel sessions commit on the same branch) printing nothing.

**Proof** (the backend has no screens, so the proof is captured JSON from the dev stack of `backend/00`; there are no Playwright screenshots in this step). The dev stack runs on `127.0.0.1:8010` against a dev SQLite file under `/srv/manhwamaniacs/dev/data/`, never production data; its seeded account `demo` has profiles **Riya** (18+ open) and **Aarav** (18+ closed), and Aarav follows three of Riya's series. `dev_stack.sh api METHOD PATH [JSON]` signs in and sends `X-Profile-Id` for the profile named by `MM_DEV_PROFILE` (default `Riya`).

```bash
cd /srv/manhwamaniacs/dev/ManhwaManiacs
free -m                                                     # stop if "available" < 1024
backend/scripts/dev_stack.sh reset                          # restart on the new code, fresh seed
P=docs/redesign/proof/backend-08
backend/scripts/dev_stack.sh api GET /profiles > $P/profiles.json      # note both ids
backend/scripts/dev_stack.sh api GET /profiles/<Riya id>/sharing > $P/sharing-get.json
backend/scripts/dev_stack.sh api PATCH /profiles/<Riya id>/sharing '{"activity": true, "show_presence": true}' > $P/sharing-patch.json
backend/scripts/dev_stack.sh api GET /library/series > $P/riya-library.json            # pick one of Riya's follows that Aarav also follows
backend/scripts/dev_stack.sh api POST /reader/progress '{"source_id": "<id>", "series_key": "<key>", "chapter_key": "<a chapter key from GET /sources/<id>/series/<key>/chapters>", "last_page": 20, "page_count": 20, "is_completed": true}'
MM_DEV_PROFILE=Aarav backend/scripts/dev_stack.sh api GET /circle/members > $P/members.json            # Riya with "now"
MM_DEV_PROFILE=Aarav backend/scripts/dev_stack.sh api GET /circle/members/<Riya id> > $P/member-page.json
MM_DEV_PROFILE=Aarav backend/scripts/dev_stack.sh api GET '/circle/feed' > $P/feed.json
MM_DEV_PROFILE=Aarav backend/scripts/dev_stack.sh api GET '/circle/feed?kind=reading' > $P/feed-reading.json
MM_DEV_PROFILE=Aarav backend/scripts/dev_stack.sh api GET '/circle/series?source=<id>&series=<url-encoded key>' > $P/series.json
MM_DEV_PROFILE=Aarav backend/scripts/dev_stack.sh api GET '/home?content_kind=manga&tz_offset_minutes=330' | python3 -c 'import json,sys; d=json.load(sys.stdin); print(json.dumps([s for s in d["sections"] if s["type"] in ("circle","circle_top")], indent=2))' > $P/home-circle-sections.json
backend/scripts/dev_stack.sh api GET '/library/annual?year=2026&tz_offset_minutes=330' | python3 -c 'import json,sys; print(json.dumps(json.load(sys.stdin).get("circle"), indent=2))' > $P/annual-circle.json
backend/scripts/dev_stack.sh stop
```

Aarav's gate is closed, so these captures also show the 18+ rule from the gated side. Do not commit the dev stack's cookie file or database; only the files under `docs/redesign/proof/backend-08/`.

## Report back

Reply with:
1. Done items, numbered as the Scope sections 1–12, each with its commit hash.
2. The migration file name and revision id.
3. Test counts: full-suite passed before your first change, passed after, failed after (must be 0), and the number of new tests.
4. The proof path `docs/redesign/proof/backend-08/` and its file list.
5. Open issues, including any deviation from the DESIGN shapes (there should be none beyond the additive fields listed in §12).

**Next prompt file:** `docs/redesign/prompts/backend/09-circle-reactions-letters-shelves.md` (the next backend step, which builds reactions, letters and shared shelves on this step's S rule). In the global plan order the next file is `docs/redesign/prompts/web/11-cinematic-feature-and-book-pages.md`.
