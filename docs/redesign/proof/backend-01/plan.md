# backend-01 plan: cover ambient colours and palettes

Prompt: `docs/redesign/prompts/backend/01-cover-ambient-and-palette.md`. Inline execution
(no subagents available in this lane), TDD order.

1. `backend/tests/test_ambient.py`: cases F1-F11 first; they fail on import.
2. `backend/services/cover_colour.py`: `_decode`, `relative_luminance`, `contrast`,
   `derive_ambient`, `ambient_from`, `palette_from`, `extract`; then `ensure_cover_colours`,
   `attach_cover_colours`; then the AniList worker (`enqueue_anilist_colours`,
   `drain_anilist_colours`, `attach_world_colours`, `reset_anilist_colour_worker`,
   `ANILIST_WORKER_ENABLED`).
3. Table: `CoverPalette` model, `alembic/versions/0019_cover_palette.py`, `CACHE_TABLES`,
   `CACHE_RETENTION_RULES` (30 days), migration test pins (`test_migrations_alembic.py`,
   `test_audit_migrations_lossy_downgrade.py`).
4. Cover proxy: `ensure_cover_colours` on both branches of `get_source_series_cover`;
   the page-image route untouched.
5. Payloads: `attach_cover_colours` in `routes/sources.py` (listing, federated search, detail),
   `routes/library.py` (series list/detail/search/follow/patch, continue-reading, suggest),
   `routes/reader.py` (history, bookmarks), `routes/updates.py` (notifications).
6. WorldItems: `WorldRecs._items` reads `al:colour:{id}` from `world_catalog_cache`, enqueues
   misses on `https://s4.anilist.co` only; worker limited to 20 fetch starts per 60 s.
7. `conftest.py`: autouse fixture disabling the worker thread.
8. Verify: targeted pytest set, full suite (baseline 3344 passed, 2 skipped).
9. Proof: dev stack on 8012 / `data-backend`, library before/after, swatches.png,
   timing.txt, pytest-after.txt.
