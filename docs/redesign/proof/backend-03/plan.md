# backend/03 plan: streaks, the Annual, listen sessions

| Task | Files | Tests | Done |
|---|---|---|---|
| A. revision `0021_streaks_listen_sessions`, `StreakMilestone`, `ListenSession` | `alembic/versions/0021_*`, `database/models.py` | `test_migrations_alembic.py`, both audit scope tests | yes |
| B. `ReadingStatsService.streak()/today_seconds()`, milestones route | `services/reading_stats_service.py`, `services/followed_series_service.py`, `routes/library.py` | `test_streaks_annual.py` (1-3, 10) | yes |
| C. streak + `today_seconds` on `/reader/progress` and `/batch` | `services/progress_service.py` (`streak_snapshot`), `routes/reader.py` | `test_streaks_annual.py` (4) | yes |
| D. `GET /library/annual` and its per-day cache | `services/annual_service.py`, `routes/library.py`, `tests/conftest.py` | `test_streaks_annual.py` (5, 7, 8) | yes |
| E. `shareable` on Annual and statistics | `services/reading_stats_service.py` (`shareable`) | `test_streaks_annual.py` (6) | yes |
| F. `POST /novels/listen-sessions`, `top_voices` | `routes/novels.py`, `services/annual_service.py` | `test_listen_sessions.py` | yes |
| G/H. tests, proof | this folder | | yes |

Decisions: `shareable` joins the follow row outer and drops every mature session whatever the gate,
and also drops sources for which `is_mature_source` holds (an explicit "safe" override on an 18+
source stays out of cards). Gated `genres` keep mature words when the gate is open; only
`shareable.genre_weights` strips them. Listen batches take `list[Any]` so one non-object item lands in
`rejected` instead of 422-ing the flush.
