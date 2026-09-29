# backend/02 plan: library, collections, tags, series enrichment, OCR boxes

One task per scope item of `docs/redesign/prompts/backend/02-library-series-ocr-extensions.md`.
Tests first in every task; `backend/.venv/bin/python -m pytest -q --no-header` from `backend/`.

| Task | Files | Tests | Done |
|---|---|---|---|
| A. `manual: true` progress, `DELETE /reader/progress` | `routes/reader.py`, `services/progress_service.py` | `test_library_extensions.py` (A) | yes |
| B. `POST /library/series/{id}/repoint` | `services/followed_series_service.py` (`repoint`, `_carry_shelves`, `_check_follow_limit`, `_known_chapters`), `routes/library.py`, `services/source_cache_service.py` (`series_hidden`) | `test_library_extensions.py` (B) | yes |
| C. collection `rules`/`smart`/`created_at`, `preview_covers`, `preview_ambient_duo`, `PUT .../series/order`, revision `0020_collection_rules` | `alembic/versions/0020_collection_rules.py`, `database/models.py`, `services/followed_series_service.py`, `routes/library.py`, `tests/test_migrations_alembic.py` | `test_library_extensions.py` (C) | yes |
| D. row `tags`, `tag_ids=`, `sort=last_read_at\|-last_read_at\|-new_count`, `new_only`, `PATCH /library/tags/{id}`, gate-aware `series_count` | `services/followed_series_service.py`, `routes/library.py` | `test_library_extensions.py` (D) | yes |
| E. `GET /series/enrichment` | `routes/series.py`, `api/router.py`, `services/world_recs.py` (`enrichment_payload`; `_write` prunes before merging) | `test_series_enrichment.py` | yes |
| F. `/ocr/search` `page` and `box` | `services/ocr_search.py` (`locate`, `box_fractions`) | `test_ocr_search_query.py` | yes |
| G. tests incl. profile isolation (two profiles, two accounts) and gate-closed absence | the three test files | | yes |
| H. proof | this folder | | yes |

Items C and D share `followed_series_service.py` and were done in one pass.

## Decisions

- Repoint copies only the rows stored under the follow's own key; rows under another key of a
  drifting (Asura) series are not carried (`ponytail:` note in `repoint`).
- `sort=last_read_at` reads the follow's own key the same way.
- Tags on rows are ordered by `Tag.name` (binary), the order `GET /library/tags` already uses.
- `already_followed` for a target the gate hides answers 404 `series_not_found`, never 409 with
  its id.
- `WorldCatalog._write` now prunes before it merges: refreshing a key older than 30 days
  (exactly the enrichment TTL) otherwise raised `StaleDataError`.
- For backend/09: the member order `PUT` must answer 403 `forbidden` to shared-shelf members once
  shelves are shared.
- The full suite caught two older guards the new surfaces tripped: the gate walk
  (`test_mature_gate_cross_surface.py`) now walks `/series/enrichment` and asserts the tag
  `series_count` through a shut gate, and the lossy-downgrade audit's head is `0020`.
- Suite: 3376 passed (backend-01) -> 3449 passed, 2 skipped, 7 deselected.
