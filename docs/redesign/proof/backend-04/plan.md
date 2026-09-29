# backend-04 plan

1. Migration `0022_home_feed` (`followed_series.last_new_chapter_at` + `ai_result_cache`), models, cache table entry, `update_service` records the timestamp before notify checks.
2. `ai_desk` (desk ledger, `DeskUnavailable`, `run_in_background`, cache helpers), `LLMRateLimited`.
3. `recap_service` availability (bounded queries) and `recap` on continue-reading rows.
4. `home_service` (pure copy helpers, cover rules, sections, also, composed cache, editorial job) and `GET /home`.
5. Tests first for each; `backend/docs/home-api.md`; dev-stack JSON proof.
