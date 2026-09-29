# backend/05 plan

1. Migration `0023_ai_taste_feedback` (reading_profiles.taste, ai_feedback) and ORM classes.
2. `series_gate.require_series_visible` (no backend/02 helper existed; the enrichment route keeps its inline gate).
3. `ai_desk.run_and_wait` (single-flight registry now holds one Event per key).
4. `ai_feedback` (not-interested and liked-pick reads), `ai_series_service` (similar, genre fallback, tags, feedback), `routes/ai.py`.
5. `recap_service`: stream, cache, per-account limiter, validation; routes for availability and stream.
6. `taste_service` (taste JSON, catalogue, sources-only seed), `routes/onboarding.py`, taste routes on `/profiles`, `POST /library/taste/seed`.
7. `world_recs`: trending queries, `genre`, not-interested; `suggestion_service`: `use_taste`, `content_kind`; `home_service`: exclusions, taste genres, taste in the editorial input.
8. Tests (four new files, suggestion_service additions), docs in `backend/docs/home-api.md`, proof captures from the dev stack.
