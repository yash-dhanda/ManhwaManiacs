# backend/06 plan

1. Baseline pytest -> pytest-before.txt.
2. Failing tests: test_reader_page_annotations.py, test_novel_audio_series_fields.py, migration test.
3. Migration 0024_reader_page_annotations + ReaderPageAnnotation model + CACHE_TABLES.
4. services/page_annotations.py (page_etag, store_tints, store_panels, annotations_for, attach).
5. POST /reader/page-tints, POST /reader/panels (resolve pages via ReaderService.manifest, gate first).
6. Manifests attach tint/panels/panels_ready (single + bulk, one query).
7. GET /reader/panels (stored rows only, gated via ProgressService.series_visible).
8. novels: rendered_chapters(with_mtime), rendered_at, cast_changed_at, 18+ gate on /audio/series.
9. backend/docs/reader-reports-api.md, proof captures, pytest-after.txt.

Notes: no other writer of novel_series_cast_state (bump_cast_version and set_narrator_voice only), so no new column.
SourceCacheService._series_key_hides does not exist; the series gate is ProgressService._series_visible (follow-rating based), exposed as series_visible.
