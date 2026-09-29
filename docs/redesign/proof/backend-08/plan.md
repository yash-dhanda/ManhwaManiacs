# backend/08 plan

One task per scope item; each was written test-first in `backend/tests/test_circle_core.py` and
`test_circle_mature_gate.py`.

1. Migration `0025_circle_core` and models (8 profile columns, `circle_hidden_series`, `circle_events`).
2. Sharing GET/PATCH in `routes/profiles.py`, logic in `services/circle_service.py`.
3. Event recording hooks (`progress_service._record_circle`, `followed_series_service.patch`).
4. S rule (`CircleService.members/passes/_events/series_mature`) in one place.
5. `GET /circle/members` (presence, last_active_at, streak).
6. `GET /circle/members/{id}`.
7. `GET /circle/feed`.
8. `GET /circle/series`.
9. `DELETE /circle/activity`.
10. `circle` and `circle_top` via `LIVE_SECTION_BUILDERS`.
11. Annual `circle` block outside the per-day cache.
12. `backend/docs/circle-api.md`.
