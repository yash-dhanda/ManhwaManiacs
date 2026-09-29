# backend-00 plan: profile redesign columns + dev stack

Lane worktree `/srv/manhwamaniacs/dev/wt/backend` (branch `redesign/backend`), API port 8012,
data dir `/srv/manhwamaniacs/dev/data-backend/` (lane override of the prompt's 8010 and
`/srv/manhwamaniacs/dev/data`; the scripts default to the prompt's values and take
`MM_DEV_PORT` / `MM_DEV_DATA_DIR` to override).

1. **A. venv**: `apt-get install python3.14-venv`, `python3 -m venv backend/.venv`, install
   `requirements.txt` + `pytest==9.1.1`. Record `pytest-baseline.txt` before any code change.
2. **E. tests first**: `backend/tests/test_profile_redesign_columns.py` (8 cases from the
   prompt) and the `0018` migration test in `test_migrations_alembic.py` (`_HEAD`,
   `_REVISIONS`). Run them, see them fail. Commit.
3. **B. migration + model**: `0018_profile_redesign_cols.py` adds `skin`, `notify_enabled`
   (server default 1), `onboarding_step`, `daily_goal_minutes`; backfills
   `onboarding_step='done'`; lossy downgrade drops them. `ReadingProfile` mirrors it.
4. **C. route + service**: `ProfileUpdate` gains the four fields (Pydantic Literal/range
   validation => 422). The route passes `model_dump(exclude_unset=True)` so explicit `null`
   differs from "not sent". `serialize` emits all four; `onboarding_step` round-trips as int,
   `"done"` or null.
5. **D. sweep**: `_check_one` adds `profile.notify_enabled` to the notification condition;
   the snapshot still advances.
6. Run the targeted tests, then the full suite. Commit (feat).
7. **F. dev stack**: `backend/scripts/dev_stack.sh` (start/stop/restart/status/seed/reset/api
   with the production-path, RAM, port and venv guards), `seed_demo.py` (HTTP only, loopback
   and dev port only, refuses a seeded DB), `README-dev-stack.md`. Commit (chore).
8. **G. proof**: `dev_stack.sh reset`, save `seed.txt`, `profiles.json`, `patch-skin.json`
   (restores `skin: null`), `pytest-after.txt`. Commit (docs). Stop the lane's dev server at
   the end (lane rule 6 overrides "leave it running").
