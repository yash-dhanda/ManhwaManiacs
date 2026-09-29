# Backend 00: per-profile skin and profile columns, plus the dev stack

## Goal

The redesign ships two skins, Cinematic and Glass, and the skin follows the **profile**, not the device (stack-decision §2.4). This step gives the backend what every later step and both clients stand on: a Python virtualenv on this box (none exists yet), one Alembic revision that adds four columns to `reading_profiles` (`skin`, `notify_enabled`, `onboarding_step`, `daily_goal_minutes`), `PATCH /profiles/{id}` and `GET /profiles` carrying all four, the update checker honouring `notify_enabled`, and a **dev stack**: a throwaway backend on `127.0.0.1:8010` with its own SQLite file under `/srv/manhwamaniacs/dev/data/`, seeded with a demo account, so every later web and mobile step can take proof screenshots without ever touching production data. Everything is additive: today's web and Flutter clients must keep working unchanged against the new server.

## Read first

Read these before planning. Do not skim the backend files: trace the real flow.

1. `docs/redesign/stack-decision.md` §2.4 (where the skin choice is stored: the profile column is the source of truth) and §2.5 (the restart flow: `PATCH /profiles/{id} { skin }` is step 1 on both clients).
2. `docs/redesign/cinematic/DESIGN.md` §15.5 (rows `reading_profiles.skin`, `reading_profiles.notify_enabled`, and `PUT /profiles/{id}/taste accepts step; GET /profiles rows carry onboarding_step`), §8.7 (the paragraph headed **Backend.**: `onboarding_step` is set to `"done"` for every existing profile by the migration and is `NULL` for new ones), §8.30.2 row 11 (Settings → Notifications per-profile master), §8.30.3 and §15.10 S12 (the skin `PATCH` is awaited before the restart with a 1,000 ms timeout, so it must be fast and must never do slow work).
3. `docs/redesign/glass/DESIGN.md` §15.5 (rows `reading_profiles.skin`, `reading_profiles.daily_goal_minutes`, and the paragraph "Nothing else is stored on the server for Glass"), §9.2.1 (the **Daily goal** menu: Off · 5 · 10 · 15 · 20 · 30 · 45 · 60 min), §8.7 (onboarding runs while `onboarding_step` is `NULL` or 1 to 7, never when it is `"done"`), §15.6 row **Taste** (the step range is 1 to 7).
4. `docs/redesign/inventory/00-decisions.md` (binding owner decisions; the skin is picked in Settings and the app restarts).
5. `docs/redesign/inventory/capabilities.md` §1 (cross-cutting contract), §5 (Profiles), §21 (Updates and notifications).
6. `docs/redesign/00-baseline.md` (health baseline; it records no backend run, so this step records the backend baseline itself, below).
7. Code: `backend/routes/profiles.py`, `backend/services/profile_service.py`, `backend/database/models.py` (`ReadingProfile`, `UpdateSettings`, `UpdateNotification`), `backend/services/update_service.py` (`UpdateService._check_one`, the `notify` gate near the `UpdateNotification(` insert), `backend/alembic/versions/0014_narrator_voice.py` and `0017_world_catalog_cache.py` (the migration style), `backend/tests/test_migrations_alembic.py` (`_HEAD`, `_REVISIONS`), `backend/tests/conftest.py` (`as_user`, `make_user`, `make_profile`, `seed_follow`), `backend/tests/test_profiles.py`, `backend/tests/test_update_service_sweep.py` and `backend/tests/_fakes.py` (how the sweep is driven with a fake connector), `backend/core/config.py` (the `MM_*` environment variables), `backend/main.py` (`create_app`, the lifespan, `init_db`), `frontend/next.config.ts` (`BACKEND_INTERNAL_URL` and the `/api/*` rewrite).

## Track rule (applies to every `backend/*` prompt)

- Work only in `backend/` (never `backend/connectors/`) plus `docs/redesign/proof/backend-00/`. This step touches no `ops/` file.
- Stage only the paths you changed, by name. Never `git add -A` or `git add .`: web, mobile and shared sessions commit in the same checkout.
- Alembic revisions continue after `0017_world_catalog_cache`. Revision ids stay at or under 32 characters (the `alembic_version.version_num` column is `VARCHAR(32)`).
- Every endpoint is profile-scoped. The 18+ gate is applied when **serving**, never when storing (shared caches too).
- Changes are additive: no field is renamed or removed, no existing response changes shape except by gaining fields.
- Tests run with `backend/.venv/bin/python -m pytest -q --no-header` from `backend/` (CI pins `pytest==9.1.1` on Python 3.14; this box has Python 3.14.4).

## Preconditions (check before any edit)

1. `git -C /srv/manhwamaniacs/dev/ManhwaManiacs branch --show-current` prints `feat/vps-slim-source-native`. If not, stop and report.
2. `ls /srv/manhwamaniacs/dev/ManhwaManiacs/backend/alembic/versions | sort | tail -1` prints `0017_world_catalog_cache.py`. If a later revision already exists, stop and report: another step ran first and the numbering below would collide.
3. `free -m`: the `available` column must read 1024 or more. If not, stop and report.

## Skills

- `superpowers:writing-plans` before touching code: write the plan to `docs/redesign/proof/backend-00/plan.md`.
- `superpowers:executing-plans` to run it inline (the steps are sequential and share one migration, so do not fan out to subagents).
- `superpowers:test-driven-development` for every endpoint change: write the failing test first.
- `superpowers:verification-before-completion` before claiming anything is done.
- Do **not** invoke `impeccable`, `taste-skill:taste-skill` or `frontend-design`: this step has no UI.

## Scope, item by item

### A. The virtualenv (none exists on this box)

1. `python3 -m venv` fails here because `ensurepip` is missing. Install the venv package once: `sudo apt-get install -y python3.14-venv` (the `ubuntu` user has passwordless sudo). If that command prompts for a password or fails, fall back to `python3 -m venv --without-pip backend/.venv` followed by `curl -sSfL https://bootstrap.pypa.io/get-pip.py | backend/.venv/bin/python`.
2. `cd backend && python3 -m venv .venv && .venv/bin/python -m pip install --upgrade pip && .venv/bin/pip install -r requirements.txt pytest==9.1.1`. Check `free -m` first. `backend/.venv/` is already ignored by the root `.gitignore` (`.venv/`); never commit it.
3. **Record the backend baseline before any code change:** `cd backend && free -m && timeout 1800 .venv/bin/python -m pytest -q --no-header 2>&1 | tail -25 > ../docs/redesign/proof/backend-00/pytest-baseline.txt`. The pass count in that file is the number every later backend step must keep. If any test fails before your change, list it in the same file under a line `PRE-EXISTING FAILURES:` and treat it as out of scope (do not fix it, do not count it against this step).

### B. Migration `0018_profile_redesign_cols`

File `backend/alembic/versions/0018_profile_redesign_cols.py`, `revision = "0018_profile_redesign_cols"`, `down_revision = "0017_world_catalog_cache"`, with a module docstring in the house style (what and why, as in `0017`). `upgrade()`:

| Column | Type | Null | Server default | Values |
|---|---|---|---|---|
| `skin` | `sa.String(length=16)` | yes | none | `'cinematic'`, `'glass'`, or `NULL` (NULL means "the default skin": `cinematic`, `legacy` until the flip, stack-decision §2.4) |
| `notify_enabled` | `sa.Integer()` | no | `"1"` | 0 or 1 |
| `onboarding_step` | `sa.String(length=8)` | yes | none | `NULL`, `'1'` … `'7'`, `'done'` |
| `daily_goal_minutes` | `sa.Integer()` | yes | none | `NULL` (Off) or one of 5, 10, 15, 20, 30, 45, 60 |

After adding the columns, `op.execute("UPDATE reading_profiles SET onboarding_step = 'done'")` so every existing profile never sees onboarding (cinematic §8.7 **Backend.**). New rows get `NULL` because the ORM sets no default. `downgrade()` drops the four columns with `op.drop_column` (lossy on purpose: say so in a comment, as `0014` does).

Model (`backend/database/models.py`, class `ReadingProfile`), matching the migration exactly so `test_alembic_head_matches_models` stays green:

```python
skin: Mapped[str | None] = mapped_column(String(16))
notify_enabled: Mapped[bool] = mapped_column(
    Integer, nullable=False, default=True, server_default="1"
)
onboarding_step: Mapped[str | None] = mapped_column(String(8))
daily_goal_minutes: Mapped[int | None] = mapped_column(Integer)
```

Update `backend/tests/test_migrations_alembic.py`: `_HEAD = "0018_profile_redesign_cols"` and append `"0018_profile_redesign_cols.py"` to `_REVISIONS`. Add one migration test there (drive Alembic to a specific revision the way `test_tags_migration_splits_a_shared_tag_per_profile` does): build a database at `0017_world_catalog_cache` with one profile row, upgrade to head, assert that row reads `onboarding_step == "done"` and `notify_enabled == 1`, then insert a new profile through the ORM and assert its `onboarding_step is None`.

### C. `PATCH /profiles/{id}` and the serializer

In `backend/routes/profiles.py`, `ProfileUpdate` gains four optional fields. Unknown values are rejected by Pydantic, which the app's error handler turns into a 422 in its standard envelope:

```python
skin: Literal["cinematic", "glass"] | None = None
notify_enabled: bool | None = None
onboarding_step: Literal["done"] | Annotated[int, Field(ge=1, le=7)] | None = None
daily_goal_minutes: Literal[5, 10, 15, 20, 30, 45, 60] | None = None
```

- Explicit `null` must be distinguishable from "not sent" for `skin`, `onboarding_step` and `daily_goal_minutes` (null resets the skin to the default, restarts onboarding, turns the goal Off). Pass `body.model_dump(exclude_unset=True)` to the service and apply each new key only when it is present in that dict. `notify_enabled: null` is treated as "not sent" (the column is not nullable).
- Keep the existing fields' behaviour exactly as it is (their `is not None` checks stay).
- `onboarding_step` is stored as text (`"3"` or `"done"`) and serialized back as `3` (int) or `"done"` (string) or `null`, because cinematic §8.7 defines `step` as `1`–`5` or `"done"` and glass §8.7 reads "1 to 7".
- `ProfileService.serialize` (`backend/services/profile_service.py`) adds `skin`, `notify_enabled` (bool), `onboarding_step` and `daily_goal_minutes` to every profile payload, so `GET /profiles` rows, `POST /profiles` and `PATCH /profiles/{id}` all carry the four fields.
- The skin `PATCH` must stay a single-row update with no extra queries (cinematic §15.10 S12 awaits it with a 1,000 ms timeout before restarting).
- `ProfileCreate` does **not** gain the fields: a new profile starts with `skin NULL`, `notify_enabled 1`, `onboarding_step NULL`, `daily_goal_minutes NULL`.
- A profile id owned by another account keeps answering 404 `profile_not_found` (the existing `_get_owned` rule), never 403.

### D. The update checker honours `notify_enabled`

In `UpdateService._check_one` (`backend/services/update_service.py`) the notification condition gains the owning profile's switch, beside the existing `row.notify` and global `settings.notify_enabled` checks:

```python
profile = self._db.get(ReadingProfile, row.profile_id)
... and (profile is None or _bool(profile.notify_enabled))
```

Everything else in `_check_one` still runs for that follow: `known_chapters`, `last_checked_at` and the source-health bookkeeping advance, so turning the switch back on never backfills a notification storm (the same semantics the per-follow `notify` flag already has; keep the comment near it accurate). Existing notifications are neither deleted nor hidden.

### E. Tests (write them first)

New file `backend/tests/test_profile_redesign_columns.py`, using `as_user`, `make_user` and `make_profile` from `conftest.py`:

1. `PATCH /profiles/{id} {"skin": "glass"}` → 200, body `skin == "glass"`; `GET /profiles` row carries `skin == "glass"`.
2. `PATCH {"skin": "neon"}` → 422, and the stored skin is unchanged.
3. `PATCH {"skin": null}` → 200, `skin is None`; `PATCH {}` leaves an existing `skin` untouched.
4. `PATCH` on another account's profile id (two users via `as_user`) → 404 `profile_not_found`, and the other profile's row is unchanged.
5. `onboarding_step`: `PATCH {"onboarding_step": 3}` → serialized `3`; `{"onboarding_step": "done"}` → `"done"`; `{"onboarding_step": 8}` → 422; `{"onboarding_step": "skip"}` → 422; a profile created through `POST /profiles` reads `onboarding_step is None`.
6. `daily_goal_minutes`: `15` → 200; `null` → Off; `12` → 422.
7. `notify_enabled`: default `true` on a new profile; `PATCH {"notify_enabled": false}` → `false` in `GET /profiles`.
8. **notify_enabled honoured by the sweep**: two profiles on one account follow the same series; drive `_check_one` with the fake connector pattern of `test_update_service_sweep.py` so that one new chapter appears; the profile with `notify_enabled = 0` gets **no** `UpdateNotification` row and its follow's `known_chapters` still includes the new chapter; the profile with `notify_enabled = 1` gets exactly one row.

### F. The dev stack (for proof screenshots; never production data)

Three new files. All paths below are absolute on this box.

**`backend/scripts/dev_stack.sh`** (bash, `set -euo pipefail`, executable, `chmod 755`). Constants:

```bash
BACKEND="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV="$BACKEND/.venv"
DATA_DIR=/srv/manhwamaniacs/dev/data
DB="$DATA_DIR/dev.db"
PORT=8010
PID_FILE="$DATA_DIR/dev-backend.pid"
LOG_FILE="$DATA_DIR/dev-backend.log"
COOKIES="$DATA_DIR/cookies.txt"
BASE="http://127.0.0.1:$PORT"
```

Guards, run before every subcommand that starts anything:

- Refuse (exit 2 with a message) if `readlink -f "$DATA_DIR"` starts with `/srv/manhwamaniacs/data` or `/srv/manhwamaniacs/app`, or if `MM_DB_PATH` resolves anywhere outside `$DATA_DIR`.
- Refuse to start if `free -m` shows less than 1024 MB available.
- Refuse to start if another process already listens on 8010 (`ss -ltnH "sport = :$PORT"` is non-empty and `$PID_FILE` does not name it).
- Refuse if `$VENV/bin/python` is missing, printing the section A commands.

Environment for the server process (and nothing else inherited that matters): `MM_DB_PATH=$DB`, `MM_SETTINGS_PATH=$DATA_DIR/settings.json`, `MM_COOKIE_SECURE=false` (http on localhost), `MM_NOVELS_ENABLED=true`, `MM_RATE_LIMIT_ENABLED=false` (Playwright grids would trip the 60/min bucket), `MM_REGISTRATION_ENABLED=true`, `MM_BOOTSTRAP_WINDOW_MINUTES=1440`. Run it under `env -u DEEPSEEK_API_KEY -u MM_RENDER_WORKER_TOKEN` so the dev stack never spends the owner's AI allowance or books the render box; when `MM_DEV_AI=1` is set in the caller's shell, pass `DEEPSEEK_API_KEY` through instead (for later AI screenshot steps).

Subcommands:

| Subcommand | Behaviour |
|---|---|
| `start` | `mkdir -p "$DATA_DIR"`; start `"$VENV/bin/python" -m uvicorn main:app --host 127.0.0.1 --port 8010` from `cd "$BACKEND"` under `nohup`, log to `$LOG_FILE`, pid to `$PID_FILE`; poll `curl -sf "$BASE/health"` every 1 s for up to 60 s; print `dev backend up on 127.0.0.1:8010 (db $DB)` or print the last 40 log lines and exit 1. Migrations run on boot through `init_db()`. Idempotent: an already-running stack prints its status and exits 0. |
| `stop` | `kill` the pid in `$PID_FILE`, wait up to 10 s, `kill -9` when the process is still alive after that, remove the pid file. Idempotent. |
| `restart` | `stop` then `start` (needed after every backend code change: there is no auto-reload). |
| `status` | Running or not, pid, port, db path and size, `free -m` available. |
| `seed` | `start` when the stack is not running, then `"$VENV/bin/python" "$BACKEND/scripts/seed_demo.py" --base "$BASE"`. |
| `reset` | `stop`; `rm -f "$DB" "$DB-wal" "$DB-shm" "$DATA_DIR/settings.json" "$COOKIES"`; `start`; `seed`. |
| `api METHOD PATH [JSON]` | Signs in as the demo account if `$COOKIES` holds no valid session (`POST /auth/login`), resolves the profile named by `MM_DEV_PROFILE` (default `Riya`) through `GET /profiles`, sends the request with `X-Profile-Id`, and pretty-prints the JSON with `python3 -m json.tool`. Example: `backend/scripts/dev_stack.sh api GET /library/series`. Later backend steps save proof with it. |

**`backend/scripts/seed_demo.py`** (stdlib + `httpx`, already installed; talks to the running dev stack over HTTP only, so it exercises the real API and imports nothing from the app):

- Refuses any `--base` whose host is not `127.0.0.1` or `localhost` or whose port is not `8010`.
- Refuses to run on a non-empty database: if `GET /auth/bootstrap-status` answers `needs_bootstrap: false` (an account already exists), exit 1 with "already seeded; run dev_stack.sh reset".
- Account: `POST /auth/register {"username": "demo", "password": "maniacs-demo-2026"}` (the first account becomes the owner/admin through the bootstrap claim). Then `PUT /updates/settings {"enabled": false, "check_on_startup": false}` so the dev stack never sweeps live sources on a schedule.
- Profiles: `Riya` (mood `fantasy`, `mature_content_enabled: true`, sort 0) and `Aarav` (mood `action`, gate closed, sort 1). One gate open, one closed.
- Follows (non-18+ only, from healthy sources): walk the manga sources in the order `mangadex`, `weebcentral`, `mangapill`, `webtoons`; for each, `GET /sources/{id}/series?page=1` with Riya's `X-Profile-Id`; skip items whose `content_rating`, or any entry of `genres`, lower-cased and stripped, is in `core.content_rating.MATURE_CONTENT_RATINGS` (copy that frozenset's values into the script as a constant, since the script must not import app code); follow the first 3 remaining items with `POST /library/follow`. Stop after two sources succeed (6 manga follows). Then walk the novel sources `standardebooks`, `gutenberg`, `royalroad` and follow 2 items from the first that answers. A source that errors or times out (15 s per request) is skipped with a logged line. If fewer than 4 manga follows succeed, exit 1 listing each source's error. Aarav follows the first 3 manga series Riya followed plus nothing else.
- Progress (drives Continue reading, History and a streak): for Riya's first 4 manga follows, `GET /sources/{id}/series/{key}/chapters`, take the first 3 chapters in reading order, and `POST /reader/progress` one chapter per day on each of the last 6 days (UTC dates, `last_read_at` at 21:00 UTC on that date, `time_spent_seconds` 300 + 120 × index, `is_completed: true` except the newest push, which stops at page 4 of its `page_count`). Aarav gets 2 completed chapters on one series 3 days ago (a broken streak).
- Bookmarks: 2 manga page bookmarks for Riya (`POST /reader/bookmark`, `media_type: "manga"`, pages 3 and 7 of her first series' first chapter) and 1 novel paragraph bookmark on her first novel follow (`media_type: "novel"`, `anchor_index: 5`).
- Collection: `POST /library/collections {"name": "Weekend binge", "description": "Seeded for screenshots"}` for Riya, then add her first 3 manga follows.
- Prints a summary table (profile, follows, progress rows, bookmarks, collections) and exits 0.

**`backend/scripts/README-dev-stack.md`**: what the dev stack is for (proof screenshots and API proof for the redesign, never production), the credentials (`demo` / `maniacs-demo-2026`, profiles Riya with 18+ open and Aarav with 18+ closed), every subcommand from the table above with one example each, the safety guards, the data location, the RAM note (check `free -m`, never run two `next build`s at once, the dev backend itself costs about 150 MB), and how to pair it with the web client:

```bash
cd /srv/manhwamaniacs/dev/ManhwaManiacs/frontend
NEXT_PUBLIC_API_URL=/api BACKEND_INTERNAL_URL=http://127.0.0.1:8010 npx next dev -p 3010
# open http://localhost:3010 and sign in as demo
```

plus the Flutter note: the app's server address field takes `http://127.0.0.1:8010` only from a device that can reach this box's loopback (an SSH port-forward: `ssh -L 8010:127.0.0.1:8010 ubuntu@135.148.43.147`).

### G. Proof

With the code in place: `backend/scripts/dev_stack.sh reset`, then save:

- `docs/redesign/proof/backend-00/seed.txt`: the seed summary output.
- `docs/redesign/proof/backend-00/profiles.json`: `backend/scripts/dev_stack.sh api GET /profiles` (shows the four new fields, `onboarding_step: null` on the two new profiles).
- `docs/redesign/proof/backend-00/patch-skin.json`: `backend/scripts/dev_stack.sh api PATCH /profiles/<Riya id> '{"skin":"glass","daily_goal_minutes":15}'`, followed in the same file by the answer to `backend/scripts/dev_stack.sh api PATCH /profiles/<Riya id> '{"skin":null,"daily_goal_minutes":null}'`, which restores the seed. The seeded profiles must end with `skin: null`: once the skin engine exists, a profile whose `skin` differs from the device mirror restarts the client into that skin (stack-decision §2.4 step 4), which would derail later Cinematic screenshots.
- `docs/redesign/proof/backend-00/pytest-after.txt`: the last 25 lines of the full suite run after the change.

No web screenshots are taken in this step: no screen changes. Leave the dev stack running at the end (`status` shows it) so the next session can use it; say so in the report.

## File layout

Created:
- `backend/alembic/versions/0018_profile_redesign_cols.py`
- `backend/tests/test_profile_redesign_columns.py`
- `backend/scripts/dev_stack.sh`
- `backend/scripts/seed_demo.py`
- `backend/scripts/README-dev-stack.md`
- `docs/redesign/proof/backend-00/{plan.md,pytest-baseline.txt,pytest-after.txt,seed.txt,profiles.json,patch-skin.json}`

Changed:
- `backend/database/models.py` (`ReadingProfile` only)
- `backend/routes/profiles.py` (`ProfileUpdate`, the PATCH handler)
- `backend/services/profile_service.py` (`serialize`, `update_profile`)
- `backend/services/update_service.py` (`_check_one` condition only)
- `backend/tests/test_migrations_alembic.py` (`_HEAD`, `_REVISIONS`, one new test)

Nothing under `frontend/`, `mobile/`, `ops/`, `backend/connectors/` or `/srv/manhwamaniacs/{app,data}` changes.

## Acceptance criteria

- [ ] `backend/.venv` exists, `backend/.venv/bin/python -m pytest --version` prints `pytest 9.1.1`, and `git status` does not list it.
- [ ] `docs/redesign/proof/backend-00/pytest-baseline.txt` records the pre-change pass count (and any pre-existing failures by name).
- [ ] Revision `0018_profile_redesign_cols` upgrades a `0017` database: existing profiles read `onboarding_step = 'done'`, `notify_enabled = 1`; new profiles read `onboarding_step NULL`.
- [ ] `test_alembic_head_matches_models` and `test_revision_set_is_exactly_what_we_expect` pass with the new head.
- [ ] `PATCH /profiles/{id}` accepts and returns `skin`, `notify_enabled`, `onboarding_step`, `daily_goal_minutes`; unknown skin → 422; out-of-range step or goal → 422; another account's profile → 404.
- [ ] Explicit `null` resets `skin`, `onboarding_step` and `daily_goal_minutes`; an omitted field changes nothing.
- [ ] `GET /profiles` rows include all four fields, `onboarding_step` as int, `"done"` or null.
- [ ] A profile with `notify_enabled = false` receives no new `UpdateNotification` rows while its follows' `known_chapters` still advance.
- [ ] `backend/scripts/dev_stack.sh reset` brings up 127.0.0.1:8010 on `/srv/manhwamaniacs/dev/data/dev.db`, seeds `demo` with Riya (18+ open) and Aarav (18+ closed), at least 4 non-18+ manga follows and 2 novel follows, progress on 6 consecutive days, 3 bookmarks and the "Weekend binge" collection.
- [ ] `dev_stack.sh` refuses to start against any path under `/srv/manhwamaniacs/data` or `/srv/manhwamaniacs/app`, and `seed_demo.py` refuses any base URL other than `127.0.0.1:8010` or `localhost:8010`.
- [ ] Per-skin difference: none on the server side. Cinematic and Glass read the same `skin` column; Glass alone reads `daily_goal_minutes` (the goal ring, glass §9.2.2); both read `onboarding_step` (Cinematic steps 1–5, Glass 1–7) and `notify_enabled`.
- [ ] No UI changes: no file under `frontend/` or `mobile/` changed (`git show --name-only --format= <hash> -- frontend mobile` for each of your own commits (never a branch or range diff: parallel sessions commit on the same branch) is empty), so reduced-motion, keyboard access and 44 pt hit targets are unaffected by construction.
- [ ] The full backend suite passes with at least the baseline's pass count plus the new tests; no test that passed in the baseline fails.

## Verification

Run one heavy command at a time. Before each, `free -m`; stop if `available` is under 1024.

```bash
cd /srv/manhwamaniacs/dev/ManhwaManiacs/backend
free -m
.venv/bin/python -m pytest -q --no-header tests/test_profile_redesign_columns.py tests/test_migrations_alembic.py tests/test_profiles.py tests/test_update_service_sweep.py
free -m
timeout 1800 .venv/bin/python -m pytest -q --no-header
```

Web and mobile suites are not run in this step because no file under `frontend/` or `mobile/` changes (check with `git show --name-only --format= <hash> -- frontend mobile` for each of your own commits (never a branch or range diff: parallel sessions commit on the same branch), which must print nothing). For the record, their baseline commands (from `00-baseline.md`) are `npm run lint` and `npm run build` in `frontend/`, and `/srv/manhwamaniacs/dev/flutter/bin/flutter analyze` and `/srv/manhwamaniacs/dev/flutter/bin/flutter test` in `mobile/`.

Then the dev stack proof of section G.

## RAM guard

Production and five Minecraft bots share this box (7,746 MB total). Check `free -m` before the pip install, before each pytest run and before `dev_stack.sh start`. Stop and report if `available` is under 1024 MB. Never run two heavy commands at once; never run `next build`.

## Git

- Branch `feat/vps-slim-source-native`. Commit small and often, one commit per working step, and push after each: `git push origin feat/vps-slim-source-native:master`.
- Suggested commits: (1) `test(backend): profile redesign columns and notify switch` with the failing tests, (2) `feat(backend): reading_profiles skin, notify_enabled, onboarding_step, daily goal` (migration, model, route, service, sweep), (3) `chore(backend): dev stack on 127.0.0.1:8010 with demo seed`, (4) `docs(redesign): backend-00 proof`.
- Stage by explicit path only, for example `git add backend/alembic/versions/0018_profile_redesign_cols.py backend/database/models.py ...`.
- No Claude or AI attribution anywhere: no `Co-Authored-By` line, no "generated with" line, no AI author. Never commit secrets, `.claude/`, `backend/.venv/` or anything under `/srv/manhwamaniacs/dev/data/`.
- No frontend file changes, so no `next build` is needed before pushing; if `git status` shows a frontend change, stop.

## Never

- Never edit `backend/connectors/`.
- Never touch production containers (`docker` commands against `manhwamaniacs-*`), `/srv/manhwamaniacs/app` or `/srv/manhwamaniacs/data`, and never point the dev stack at them.

## Report back

Reply with:
1. Done items, by the letters A to G above, each with its commit SHA.
2. Backend test counts: baseline passed/failed, after passed/failed, and the new test names.
3. The proof folder path `docs/redesign/proof/backend-00/` and what is in it (no screenshots in this step).
4. Dev stack state: running or stopped, the seeded follow count per source, and any source the seed had to skip.
5. Open issues, including whether the venv came from `python3.14-venv` or the `get-pip.py` fallback.

Next prompt file in the series: `docs/redesign/prompts/shared/01-glass-tokens-haptics-motion-names-contrast.md`. Next file in the backend track: `docs/redesign/prompts/backend/01-cover-ambient-and-palette.md`.
