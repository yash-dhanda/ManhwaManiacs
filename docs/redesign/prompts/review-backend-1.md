# Review: backend track, slice 1 (backend/00 to backend/09)

Reviewed 2026-09-29 against `prompts-plan.json` (binding), `cinematic/DESIGN.md` §15.5 and the sections each row cites, `glass/DESIGN.md` §15.5 and §15.6 and the sections each row cites, `stack-decision.md`, `inventory/00-decisions.md`, `inventory/capabilities.md`, `00-baseline.md`, the neighbouring prompt files that consume or produce what this slice serves (`shared/03`, `shared/04`, `web/12`, `mobile/12`, `web/22`, `mobile/22`, `web/42`, `mobile/42`, `web/43`, `mobile/43`, `web/44`, `mobile/44`, `release/00`), and the backend code the prompts name. Every class, function, constant, route and environment variable the ten prompts cite was grepped in `backend/` and exists (about 90 symbols; none missing).

All ten files exist. No file was missing, so none was created. Fixes were made in place in `backend/02`, `04`, `06`, `07`, `08` and `09`.

## 1. Per-file checklist

| File | Goal | Read first (DESIGN × 2, decisions, stack, inventory, baseline) | Skills | File layout | Acceptance (incl. reduced motion, keyboard, 44 pt, per-skin) | Verification (exact pytest; web and mobile commands cited) | RAM guard | Git (no attribution, explicit staging) | Never | Report back + next file | Plan scope |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 00 profile columns + dev stack | yes | yes | yes | yes | yes (no-UI statement) | yes | yes | yes | yes | yes; next `shared/01` (plan order 3) | matches |
| 01 cover ambient + palette | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes; next `shared/04` (order 15) | matches; adds `lMax` (see 4.1) |
| 02 library, series, OCR | yes | **stack-decision and the plan entry were missing: fixed** | yes | yes | yes | yes | yes | yes | yes | yes; next `web/05` (order 20) | matches, plus the Glass library rows of glass §15.5 |
| 03 stats, streaks, Annual, listen | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes; next `web/06` (order 23) | matches (see 4.3 on its dependencies) |
| 04 `GET /home` | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes; next `web/07` (order 26) | matches; **at-risk rule fixed** |
| 05 similar, recaps, taste, onboarding | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes; next `web/08` (order 29) | matches, plus Glass's `use_taste`, `content_kind`, `undo` |
| 06 tints, panels, novel audio | yes | **00-decisions was missing: fixed** | yes | yes | yes | yes | yes | yes | yes | yes; next `web/09` (order 32) | matches; **sign-off precondition fixed** |
| 07 media routes + install page | yes | **00-decisions was missing: fixed** | yes (frontend-design, impeccable, taste-skill for the page) | yes | yes (skip link, focus ring, 48 px targets, reduced motion) | yes, plus Playwright at 1440 × 900 and 390 × 844 | yes | yes | yes | yes; next `web/10` (order 35) | matches; **brand, font and Front pages paths fixed** |
| 08 Circle core | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes; next `web/11` (order 38) | matches; **tied to the `/home` hook** |
| 09 reactions, letters, shelves | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes; next `web/12` (order 41) | matches; **conflicting order fallback removed** |

Common to all ten: tests run with `backend/.venv/bin/python -m pytest -q --no-header` from `backend/` (the plan's track rule; CI pins `pytest==9.1.1` on Python 3.14, which `.github/workflows/tests.yml` confirms); `free -m` before every heavy command with the 1,024 MB stop; one heavy command at a time; stage by explicit path; no Claude or AI attribution; never `backend/connectors/`, production containers or `/srv/manhwamaniacs/{app,data}`. The web and mobile baseline commands (`npm run lint`, `npm run build`, `flutter analyze`, `flutter test` with Flutter at `/srv/manhwamaniacs/dev/flutter/bin`) are cited in every file and correctly not run, because no step in this slice changes `frontend/` or `mobile/`; each file proves that with `git diff --stat -- frontend mobile`. Only `backend/07` has a web screen (the install page), and it takes headless Playwright screenshots at 1440 × 900 and 390 × 844 into `docs/redesign/proof/backend-07/`. The other nine save JSON captures from the dev stack as their proof. No file contains TBD, "etc." or "as appropriate".

Alembic chain as the plan order runs it: `0018_profile_redesign_cols` (00) → `0019_cover_palette` (01) → `0020_collection_rules` (02) → `0021_streaks_listen_sessions` (03) → `0022_home_feed` (04) → `0023_ai_taste_feedback` (05) → `0024_reader_page_annotations` (06) → `0025_circle_core` (08) → `0026_circle_social` (09). Every id is 32 characters or fewer, and each step checks the head before it writes. `backend/07` has no migration.

## 2. Fixes made

| # | File | Problem | Fix |
|---|---|---|---|
| F1 | `backend/04` | The at-risk headline override fired on `streak.at_risk` alone, and the file described backend/03's rule as "`current_days >= 2`". But backend/03 sets `at_risk` from **1** day up, because Cinematic's flame shows its at-risk state from 1 day (cinematic §9.2.2). The headline override needs 2 days or more (cinematic §9.1.2, §8.8). As written, a 1-day streak would print "One days and counting…". | The override now requires `at_risk and current_days >= 2`, and the text says why. The headline table test gains the case `at_risk: true, current_days: 1` keeps the normal headline. |
| F2 | `backend/06` | The precondition asked the owner a yes/no question and blocked the session. `web/12` and `mobile/12` record the same sign-off from cinematic §15.10's **Owner calls** paragraph, which decides S1 and S11, without asking, in the line format `S1 — … — recorded <date> by web/12`. backend/06 runs first (plan order 31, against 41 and 42), so it would have been the only step to stop and ask, and its line format (`- 2026-MM-DD S1, S11, G6, G14 approved …`) would not match what the later steps and `web/34`, `mobile/34` and `web/35` grep for. | backend/06 now records the four lines `S1 …`, `S11 …`, `G6 …` and `G14 …` in the format those steps expect, citing the owner call. It commits them alone before any code, or cites them when they are already there. The acceptance criterion, commit list and report item follow. |
| F3 | `backend/07` | The brand routes pointed at files `shared/04` never writes there. `shared/04` puts `apple-touch-icon.png` and `icon-192.png` in `frontend/public/icons/`, and `favicon.ico` in `frontend/src/app/`, which is outside the planned `frontend/public` mount. The precondition `ls` would have failed. | `BRAND_FILES` is now a literal name-to-path map (`og.png` → `og.png`; `apple-touch-icon.png` and `icon-192.png` → `icons/…`), and no request text is ever joined into a path. The favicon is `icon-192.png` (`<link rel="icon" type="image/png" sizes="192x192">`), so no `.ico` or SVG is served under `/app/*`. The precondition, route table, compose comment, tests E3 and E5, and acceptance are updated to match. |
| F4 | `backend/07` | The font allowlist guessed three names (`bodoni-moda-roman-latin.woff2`, …) with a "use what you find" fallback. `shared/04` section 7 writes six fixed names (`bodoni-moda-{,italic-}latin{,-ext}.woff2`, `archivo-latin{,-ext}.woff2`) plus `fonts.json`, and says backend/07 builds its `@font-face` rules from that file. The file also gave Archivo `font-weight: 100 900`, but the subset `shared/04` fetches is `wght 400..800` with a `wdth 62..100` axis, and the page's 62 % and 90 % widths need that axis declared. | `FONT_FILES` is the literal set of the six names, and the session stops if the disk disagrees. `@font-face` rules are built from `fonts.json` (`family`, `style`, `unicode-range`). Archivo is declared `font-weight: 400 800; font-stretch: 62% 100%`, Bodoni Moda `400 900`. The preload is `bodoni-moda-latin.woff2`. `fonts.json` itself is never served (a test says so). The Playwright capture is renamed `fonts-loaded.json` so it cannot be confused with the font manifest. |
| F5 | `backend/07` | "Take the SVG whose file name contains `mark` or `monogram`" was ambiguous: `shared/04` writes `monogram.svg`, `monogram-small.svg` and `monogram-mono.svg`. | The file is named exactly: `brand/cinematic/monogram.svg`. |
| F6 | `backend/07` | It said `web/24` captures the Front pages into `mobile/docs/screenshots/`. In fact `web/24` writes them to `docs/redesign/proof/web-24/front-pages/`, and `release/00` copies them into `mobile/docs/screenshots/` under the `_SHOWCASE` names. | The text and the report hand-off now describe the real flow, and name `_SHOWCASE` as the file-name contract (see 4.4 for `shared/04`'s differing spellings). |
| F7 | `backend/09` | It told the session to create `PUT /library/collections/{id}/series/order` and `created_at` "if absent", with a partial-list rule (unlisted rows keep their order after the listed ones). backend/02 item C.4 already owns that call, with the opposite exact-set rule (`422 order_mismatch` unless the body equals the visible membership). backend/09 always runs after backend/02, so the fallback could never run, yet it wrote a second, conflicting rule for the same call. | The precondition now checks that backend/02's call and `created_at` exist. backend/09 only routes the call through `_shelf_access`, which returns 403 to members. The fallback and its report item are removed. |
| F8 | `backend/08`, `backend/09` | backend/04 leaves one hook for per-request `/home` sections, `home_service.LIVE_SECTION_BUILDERS`. backend/08 and backend/09 said only "splice after the cache read", which invites a second mechanism. | Both now append builders to `LIVE_SECTION_BUILDERS`: backend/08 for `circle` and `circle_top`, backend/09 for `sent_to_you`. backend/09 re-selects `also[]` after the builders run, as it already specified. |
| F9 | `backend/02`, `06`, `07` | The Read first lists lacked `stack-decision.md` (02) and `inventory/00-decisions.md` (06, 07), which the rules require. | Added, each with the section that matters. backend/02 also gains its plan entry. |

## 3. Coverage: every backend row of both DESIGN files has exactly one owner

Cinematic §15.5:

| Row | Owner |
|---|---|
| `ambient` on series payloads, computed in the cover proxy, WorldItem colours at 20 per minute; `backend/tests/test_ambient.py` | 01 |
| `pages[].tint` + `POST /reader/page-tints`; `pages[].panels` + `POST /reader/panels` | 06 |
| `manual: true` on progress; `DELETE /reader/progress` | 02 |
| `GET /home` (sections, `generated_at`, `tz_offset_minutes`, the streak object, `recap` on cover, continue and where_were_we items and on `GET /library/continue-reading`) | 04 |
| `GET /ai/similar`, `GET /ai/recap/availability`, `GET /ai/recap` (SSE), `GET /ai/tags`, `POST /ai/feedback`, `PUT /profiles/{id}/taste` | 05 (availability service in 04) |
| Streak milestones seen | 03 |
| `/ocr/search` `page` and `box` | 02 |
| `POST /library/series/{followed_id}/repoint` | 02 |
| `GET /library/annual` (top voices, `available_years`), `shareable` on the Annual and on the range payload | 03 |
| Per-profile composed caches: `/home` 04, `/library/annual` 03; per-series caches gated on serve: `/ai/similar` and `/ai/tags` 05, `/series/enrichment` 02 (proved again in 05) | 03, 04, 05, 02 |
| Every Circle-derived figure from S(member, viewer) | 08 (reactions, letters, shelves reuse it in 09) |
| Circle tables and endpoints, `now`, member page, feed filters, sharing, `DELETE /circle/activity`, `GET /circle/series` | 08 |
| `DELETE /circle/reactions` body, `409 recipient_unavailable`, shared-shelf fields and calls | 09 |
| `reading_profiles.skin` | 00 |
| Collection `rules` / `smart`; `preview_covers` + `preview_ambient_duo`; `tags` + `tag_ids=` + `PATCH /library/tags/{id}`; library sorts and `new_only` | 02 |
| `reading_profiles.notify_enabled` | 00 |
| `GET /series/enrichment` | 02 |
| `GET /home?content_kind=` and `also[]` | 04 (the `letter` candidate in 09) |
| `step` on taste; `onboarding_step` on `GET /profiles` | 05; 00 |
| `GET /onboarding/catalog`, `GET /ai/similar?anilist_id=`; the 3-healthiest-sources fallback | 05; 04 |
| `POST /novels/listen-sessions`, `top_voices` | 03 |
| `chapters[].rendered_at`, `cast_changed_at`, `force` on narrate | 06 |
| `PATCH /circle/letters/{id}` | 09 |
| `GET /app/soundscapes/{id}.{ext}`; `/app/media/{name}` stays screenshots only | 07 |
| `GET /app/fonts/{file}.woff2` | 07 |

Glass §15.5 (and the §15.6 rows that bind the backend):

| Row | Owner |
|---|---|
| `reading_profiles.skin`, `daily_goal_minutes` | 00 |
| `palette {a, l, lMax}` on `SourceSeries`, `FollowedSeries`, continue items, `/home` items, `WorldItem`; `cover_palette` 30-day TTL | 01 (`/home` items attached in 04) |
| `pages[].tint` + `POST /reader/page-tints` | 06 |
| `GET /home` + `refresh=1` | 04 |
| `/ai/similar` + `fallback=genres`; `POST /ai/feedback` + `clear` and `undo` | 05 |
| `GET /ai/recap` `shape=deck`, `scope`, the `section`, `delta`, `phase` and `done` events | 05 |
| Taste `step` 1 to 7, `styles` union of 11 | 05 (`onboarding_step` column in 00) |
| Streak object + milestones; `streak {current_days, extended_today}` and `today_seconds` on `POST /reader/progress` | 03 |
| Annual `pages_read`, `longest_streak {days, month, start, end}`, `busiest_day`, `firsts_lasts`; `shareable` on the Annual and on `GET /library/statistics` | 03 |
| Circle `show_presence`, `share_streak`, `now` null unless `show_presence`, `streak {current_days, alive_today}` | 08 |
| `can_receive` on `GET /circle/members?source_id=&series_key=`; `GET /circle/letters?box=sent`; reaction kinds `hype`, `wrecked` | 09 |
| Glass soundscape layers | 07 (both `glass-{scene}-{layer}` and `glass/{scene}-{layer}` spellings) |
| First four member covers, tag objects, `tag_ids=`, `PATCH /library/tags/{id}`; `series_count` on tags; `PUT …/series/order` + `created_at` | 02 (member 403 in 09) |
| `/library/world/recommendations?genre=`; `use_taste` on both suggest calls; `content_kind` on `POST /library/suggest` | 05 |

Nothing in either table is unowned, and after F7 nothing is owned twice with conflicting rules. The remaining shared responsibilities are handed off explicitly: 01 → 04 (`palette` on `/home` items), 03 → 04 (the streak object), 03 → 08 (Annual `circle`), 04 → 05 (`_excluded`, taste genres, editorial taste block), 04 → 08 and 09 (`LIVE_SECTION_BUILDERS`, the `also[]` letter slot), 02 → 09 (the member 403 on the order call). Each hand-off is named in both files.

## 4. Findings left as they are (accepted, or for other reviewers)

1. **Plan entry of backend/01 is behind glass.** It says `palette {a, l}`; glass §15.5 and §2.1.8 say `{a, l, lMax}`, and `lMax` feeds `dimFor` (glass §15.8). The prompt follows glass, which is correct.
2. **Plan entry of backend/07 cites an old Glass path** (`/app/media/soundscapes/glass`). Glass §15.5 now names ids `glass-{scene}-{layer}` under `/app/soundscapes/`, while `shared/03`, `web/44` and `mobile/44` use `/app/soundscapes/glass/{scene}-{layer}`. backend/07 serves both spellings from one allowlist, so either client works. Accepted.
3. **backend/03's plan `depends_on` lists only backend/00**, but the prompt needs backend/01 (`attach_cover_colours` for `top_series` and `art_series`) and backend/02 (its revision parent `0020_collection_rules`). Plan order (14, 19, 22) makes this safe, and the file's preconditions check both. If the plan is ever reordered, add both to `depends_on`.
4. **For the shared reviewer:** `shared/04` section 8 (`brand/cinematic/sidestore.md`) spells two Front pages files `front-03-read-aloud.png` and `front-04-your-year.png`. `_SHOWCASE` (backend/07) and `release/00` use `front-03-novels-read-aloud.png` and `front-04-year-in-chapters.png`. `release/00` builds the SideStore URLs from `_SHOWCASE`, so nothing breaks, but `shared/04` should take the `_SHOWCASE` spellings.
5. **For the web and mobile reviewers:** backend/03 adds `tz_offset_minutes` to `POST /reader/progress` and `/reader/progress/batch` as a query parameter, defaulting to 0 so today's clients keep working. Glass's flare and goal ring (`web/42`, `mobile/42`) and every client progress path (the reader engines and the outbox flush) must send the device offset. Otherwise `extended_today` and `today_seconds` are computed on UTC days, which is wrong for the owner's +330.
6. **For the web reviewer:** `web/12` decides whether a sign-off exists with `grep -rln "S11" docs/redesign --include=*.md | grep -v DESIGN.md`. That grep also matches the prompt files themselves, so it always finds something. It should grep `docs/redesign/signoffs.md`, as `mobile/12` and `web/34` do. After F2, backend/06 writes the lines first, so the outcome is right today either way.
7. **For the web reviewer:** `web/03` says never to commit "the demo password", but backend/00 commits `demo` / `maniacs-demo-2026` in `backend/scripts/README-dev-stack.md` and `seed_demo.py` on purpose. The dev stack binds `127.0.0.1:8010` only, uses its own SQLite under `/srv/manhwamaniacs/dev/data/`, and `seed_demo.py` refuses any other base URL, so this is not a production credential. `web/03` should say "real credentials".
8. **Deliberate additions beyond the DESIGN shapes, all additive and each documented by its step's API note:**
   - 03 `shareable.top_sources`.
   - 04 `kicker_title`, `section.fallback`, `section.seed` and `sources[].suggested`.
   - 05 `GET /profiles/{id}/taste`, the `tag_rejected` `ai_feedback` rows, and the `run_and_wait` 25 s budget for `why` lines.
   - 06 `GET /reader/panels` and a page identity of `sha256(pages[].url)` (the server cannot know a byte ETag without decoding pages, which S1 and S11 forbid).
   - 07 a third install step, "Or read in your browser", which keeps today's web link. Cinematic §8.34 names two steps.
   - 08 `palette`, `content_kind`, `followed_by_viewer`, `last_active_at`, `streak`, `since` and Annual `circle.both`.
   - 09 seven-key `counts`, `sealed`, and `GET /library/collections?include_shared=true` for `shared_with_me`. The DESIGN adds it to a bare array, which would break today's clients. `web/22` and `mobile/22` already call `include_shared`.
9. **Glass's switch table says "follows" appear in feeds**, but the shared event kinds (cinematic §9.3.8) are `started`, `finished_chapter`, `finished_series` and `reacted`. backend/08 records those four, and follows appear only through `GET /circle/series` `followers`. That matches the shared contract, so nothing changed.
10. **The Glass tag rename is capped at 24 characters by the client** (glass §8.17). backend/02 accepts 1 to 255 on the server. That is compatible: the server never rejects a Glass name.

## 5. Files changed by this review

- `docs/redesign/prompts/backend/02-library-series-ocr-extensions.md` (F9)
- `docs/redesign/prompts/backend/04-ai-home-composition.md` (F1)
- `docs/redesign/prompts/backend/06-reader-tints-panels-novel-audio.md` (F2, F9)
- `docs/redesign/prompts/backend/07-media-routes-and-install-page.md` (F3, F4, F5, F6, F9)
- `docs/redesign/prompts/backend/08-circle-core-sharing-presence.md` (F8)
- `docs/redesign/prompts/backend/09-circle-reactions-letters-shelves.md` (F7, F8)
- `docs/redesign/prompts/review-backend-1.md` (this file)

Unchanged after review: `backend/00`, `backend/01`, `backend/03`, `backend/05`.
