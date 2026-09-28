# Glass DESIGN.md: capabilities and owner-decisions audit

Lens: every backend capability in `inventory/capabilities.md` has a Glass surface with its states and error codes; every binding decision in `inventory/00-decisions.md` is honoured; the four new features are fully specified; the two signature animations match the decisions. Every "missing" claim below was grepped across the whole of `glass/DESIGN.md` first. Where Glass says it reuses an endpoint "as Cinematic defined it", `cinematic/DESIGN.md` §9.3.8 and §15.5 were read to confirm. Where the backend is cited, it was read (read-only) under `backend/`.

Verified as honoured (no finding): dark-only AMOLED, no accent picker, restart on skin switch (§8.25.2), UI sounds off by default (§6), full haptic vocabulary for iOS and Android (§5.2), full desktop web with sidebar, hover, keys and a wide reader with side panels (§7.16, §8.14.11, §8.15.2), reduced motion honoured everywhere, no low-end fallbacks (§15.7), the Webtoon / Apple Books / Netflix reader and home references, the 18+ purge (§8.0.8), every error code listed in capabilities §1 has a row in §8.0.10, and every one of the 111 client endpoints has a surface except those named below.

Severity: **high** = breaks a binding decision, a new feature cannot work as written, or two skins would build incompatible backends; **medium** = an implementer has to invent a call, a field, a state or copy; **low** = an edge or a naming gap.

---

## PRODUCT-1

- **Severity:** high
- **Section:** §7.29, §7.35, §8.12 (chapter rows, select mode), §8.17 (bulk toolbar), §8.19 (Mark finished), §15.5
- **Problem:** Mark read, Mark unread and Mark finished appear on chapter rows, the chapter context menu, the series select toolbar, the Library bulk toolbar and History, but Glass never says which call they make. The only existing write is `POST /reader/progress`, whose merge never rewinds and whose `is_completed` is sticky, so Mark unread cannot work through it. Mark read through it records a reading session, which inflates Statistics and Wrapped and fires Glass's streak flare, because §9.2.2 fires `streak.extend` from the `extended_today` field of `POST /reader/progress` responses. Bulk "Mark read" on 200 chapters would therefore count as reading and could extend a streak.
- **Evidence:** DESIGN §8.17: "the bulk toolbar with Favourite, Unfavourite, Mark read, Mark unread, Add to collection…" (no endpoint anywhere; `grep -n manual` finds no progress flag). capabilities §13: "The merge is furthest-wins and never rewinds." `backend/services/progress_service.py:261`: "``is_completed`` is sticky — once true it stays true". The shared backend Glass says it reuses already has the calls: `cinematic/DESIGN.md` §15.5 "`POST /reader/progress/batch` items accept `manual: true` (saved without `record_session`, so no `ReadingSession`); `DELETE /reader/progress {source_id, series_key, chapter_keys[] ≤ 200}`".
- **Fix:** Add a "Mark read and Mark unread" paragraph to §8.12 and reference it from §7.29, §7.35, §8.17 and §8.19. **Mark read** (one chapter, or a series' every `known_chapters` key in bulk): `POST /reader/progress/batch` rows `{source_id, series_key, chapter_key, chapter_number, last_page: max(page_count, 1), page_count: max(page_count, 1), scroll_offset_px: 0, is_completed: true, time_spent_seconds: 0, manual: true}` in chunks of 200. **Mark unread:** `DELETE /reader/progress {source_id, series_key, chapter_keys[≤ 200]}` → 204. **Mark finished** (History) = Mark read of that chapter. Manual rows never produce `extended_today: true` or add to `today_seconds`, so no flare, goal ring change or statistic moves. Toasts "Marked 42 chapters read · Undo" (Undo deletes only keys that were not completed before) and "Marked chapter 142 unread · Undo" (Undo re-posts the deleted rows, which the client keeps until the toast closes). Offline: all four controls are disabled with "Needs a connection". Add both calls to the §15.5 table as "(Cinematic's)".

## PRODUCT-2

- **Severity:** high
- **Section:** §9 intro, §9.4.3 Data and States, §15.5, §15.10
- **Problem:** Guided view, one of the four required new features, depends on a panel pipeline that contradicts the shared contract Glass says it uses. Glass says panels are computed on the server with Pillow and served by `GET /reader/panels` with `panels_ready` on the manifest, "shared with Cinematic". Cinematic defines the opposite: detection on the client, and the backend only caches client reports. One backend cannot serve both designs. Glass also registers no §15.10 row for the deviation, and its "Finding panels…" and "not ready" states are built on the server model.
- **Evidence:** DESIGN §9.4.3: "`GET /reader/panels?source&series&chapter` (shared with Cinematic) returns … computed server-side from the page proxy (a whitespace and blackspace gutter projection in Pillow) … the manifest carries `panels_ready: bool`." §15.5: "`GET /reader/panels` + `panels_ready` (Cinematic's)". `cinematic/DESIGN.md` §15.5: "`pages[].panels` (optional) in manifests, filled only from client reports: `POST /reader/panels …` the image proxy does no image analysis (S11)"; its S11: "Panel detection runs on the client … the backend only caches client reports".
- **Fix:** Follow S11 (it has the owner sign-off path). In §9.4.3: panels come from the shared engine's client detector (`frontend/src/features/reader/page-panels.worker.ts` and `mobile/lib/features/reader/engine/page_panels.dart`, a gutter projection on a 256 px-wide decode inside the same worker or `compute()` isolate as the page sampler, parity checked by `design/panel-vectors.json` in both test suites). `pages[].panels` from the manifest paints first, and the engine posts detected boxes on chapter exit with `POST /reader/panels`. Delete `GET /reader/panels` and `panels_ready` from §9.4.3 and §15.5, and replace "the backend computes … panel boxes" in the §9 intro. The `panel-focus` button shows once `panelBoxes` is non-null for the current page. "Finding panels…" means the detector is running (at most 300 ms per page). Replace "not ready" with "No panels found on this page" (framed whole). Guided view then works offline on downloaded chapters with no cached data. Add a §15.10 row reusing S11.

## PRODUCT-3

- **Severity:** high
- **Section:** §9.3 (switch table), §9.3.2, §9.3.7, §8.25.15, §15.5, §15.6
- **Problem:** Glass says the Circle privacy switches use "the endpoint Cinematic defined, with Glass's two extra switches", but it renames every field. On one backend, a Glass client sending `share_activity` to a server that expects `activity` would silently fail to turn sharing on or off. The per-profile isolation the owner requires hangs on these switches. Reaction removal also has a different shape in each skin. Glass never names the read call that fills Settings → Circle and privacy.
- **Evidence:** DESIGN §9.3.7: "`PATCH /profiles/{id}/sharing {share_activity, show_reactions, accept_recommendations, allow_shelf_invites, share_mature, show_presence, share_streak, excluded_series}`" and "`DELETE /circle/reactions/{id}`". `cinematic/DESIGN.md` §9.3.8: "`GET /profiles/{id}/sharing` → `{activity, reactions, shelves, recommendations, include_mature, excluded_series: [{source_id, series_key, title}]}` … `PATCH /profiles/{id}/sharing` takes the same shape" and "`DELETE /circle/reactions` takes the body `{source_id, series_key, chapter_key}`".
- **Fix:** Use the shared names and add Glass's two: `{activity, reactions, shelves, recommendations, include_mature, presence, streak, excluded_series}`. Add a mapping line to the §9.3 table (Share what I'm reading = `activity`, Show my reactions = `reactions`, Accept recommendations = `recommendations`, Let others add me to shared shelves = `shelves`, Include 18+ = `include_mature`, Show me in presence = `presence`, Share my streak = `streak`). §8.25.15 loads with `GET /profiles/{id}/sharing`. Reaction removal is `DELETE /circle/reactions {source_id, series_key, chapter_key}`. Put both in the §15.6 register as one row.

## PRODUCT-4

- **Severity:** medium
- **Section:** §9.3.5 (a friend), §9.3.3 (members' view), §8.18 (collection detail), §9.3.1 Letters, §9.3.7, §8.0.10
- **Problem:** Several Circle surfaces have no data source in Glass:
  1. The friend sheet shows the friend's "Reading", "Shelves", "Recent" and "Their reactions", but §9.3.7 lists no per-member endpoint.
  2. "From your Circle" shelves in Collections have no list source.
  3. A friend's shelf's member grid is "joined from the library payload". The viewer does not follow the owner's series, so every poster falls into the orphan state "No longer in your library".
  4. The 20 px "who added it" orb has no field.
  5. The Letters "Sent" filter has no parameter.
  6. "Add to library" and "Not now" do not map to the letter states.
  7. The race where a recipient turns off recommendations has no copy.
- **Evidence:** DESIGN §9.3.5: "sections **Reading** (their shared continue list …), **Shelves**, **Recent**, **Their reactions** … States: not sharing any more". §8.18: "Member grid (as Library; titles joined from the library payload) … orphans (no longer followed) show 'No longer in your library'". §9.3.7 lists only members, feed, reactions, letters, sharing, activity and share. `cinematic/DESIGN.md` §9.3.8 defines `GET /circle/members/{profile_id}` (with `404 circle_member_not_sharing`), `GET /circle/feed?cursor&profile_id=&kind=`, `shared_with_me` on `GET /library/collections`, detail rows that "carry `title`, `cover_url` … because a member's library cannot join the owner's series", `added_by_profile_id`, letter `state: "new" | "read" | "kept" | "dismissed"`, and `409 recipient_unavailable`.
- **Fix:**
  1. Add to §9.3.7: `GET /circle/members/{profile_id}` → `{profile, now, reading: [{source_id, series_key, title, cover_url, chapter_number, position, total}], shelves, recent (first 20 feed items), reactions}`. `404 circle_member_not_sharing` renders "Aarav isn't sharing right now."
  2. `GET /circle/feed?profile_id=&kind=` drives "Recent".
  3. Collections' "From your Circle" section reads `shared_with_me`.
  4. §8.18: a collection with `shared != null` or from `shared_with_me` renders its member rows from their own `title` and `cover_url`, never the library join, and the orphan line applies only to the viewer's own collections.
  5. The adder orb reads `added_by_profile_id`.
  6. Sent letters come from `GET /circle/letters?box=sent`, as a §15.5 addition.
  7. Letter actions: "Add to library" = follow, then `PATCH {state: "kept"}`. "Not now" = `{state: "dismissed"}`. Opening = `{state: "read"}`.
  8. Add two §8.0.10 rows: `recipient_unavailable` (toast "{name} isn't taking recommendations any more.", that orb is deselected) and `circle_member_not_sharing` (the friend sheet's not-sharing state).

## PRODUCT-5

- **Severity:** medium
- **Section:** §9.3.4 (menu path, 18+), §9.3.3 (share sheet)
- **Problem:** The 18+ rules for social surfaces depend on knowing, for each recipient, whether they may see a given series or collection. No endpoint gives the client that answer. `GET /circle/members` carries no gate or eligibility field, and should not expose a member's gate. An implementer must either leak gate state through a new field of their own invention or skip the rule.
- **Evidence:** DESIGN §9.3.4: "a member whose profile would not be allowed to see this series is disabled with 'Not available to {name}'". §9.3.3: "18+ collections list only members whose gate is open". §9.3.7 `GET /circle/members` has only `now`, `last_active_at` and `streak`. The decision requires social features "all respecting per-profile isolation and the 18+ gate".
- **Fix:** Add to §15.5: `GET /circle/members?source_id=&series_key=` and `GET /circle/members?collection_id=` return `eligible: bool` per member. The server computes it as `false` when the series (or any member series) is mature after `mature_override` and the member's gate is closed; it is otherwise `true`, and it returns no reason. `POST /circle/letters` and `POST /library/collections/{id}/share` refuse ineligible ids with `409 recipient_unavailable` (copy as in PRODUCT-4). The recommend and share sheets call the parameterised form when they open. Loading shows 3 orb skeletons.

## PRODUCT-6

- **Severity:** medium
- **Section:** §9.4.2 (Recorded layers), §15.5
- **Problem:** The soundscape recordings are served from a path the backend cannot serve, and it is not the route the shared contract defines. The existing `/app/media/{name}` takes one path segment, strips directories and allows only image suffixes. Cinematic defines a separate allowlisted route for loops.
- **Evidence:** DESIGN §9.4.2 and §15.5: "`/app/media/soundscapes/glass/{scene}-{bed|detail|tone}.{ogg|m4a}` … next to Cinematic's loops". `backend/routes/app_distribution.py:1985-1992`: `safe = Path(name).name` and `_ALLOWED_MEDIA_SUFFIXES = {".png", ".jpg", ".jpeg", ".webp", ".gif"}`. `cinematic/DESIGN.md` §15.5: "`GET /app/soundscapes/{id}.{ext}` (public under `/app/*`) … anything else 404. The existing `/app/media/{name}` route serves screenshots only".
- **Fix:** Serve Glass's 18 layers through Cinematic's route by adding ids to its allowlist: `GET /app/soundscapes/glass-{scene}-{layer}.{ogg|m4a}`, where `scene` ∈ `rain, wind, ocean, hearth, stream, deep` and `layer` ∈ `bed, detail, tone`. Files go in `backend/media/soundscapes/` with the same `Cache-Control: public, max-age=31536000, immutable`. Change §9.4.2, §15.5 and the Cache Storage key (`mm-soundscapes-v1` stays).

## PRODUCT-7

- **Severity:** medium
- **Section:** §8.7 (steps 6 and 7, Storage, Resume), §9.1.6, §15.5, §15.6 (Taste row)
- **Problem:** Onboarding's backend is inconsistent with the shared contract Glass claims to use, and "shown once" is not implementable as written:
  1. Glass invents `POST /library/taste/seed` for step 6, but the shared backend already has an onboarding catalogue endpoint.
  2. Glass sends `onboarding_step` in the taste PUT, where the shared field is `step`.
  3. Resume reads `onboarding_step`, but Glass never says which response carries it.
  4. The trigger is "a profile with no reading history and no follows", so a profile that pressed Skip without following anything re-enters onboarding on every Home visit.
  5. "Each pick pulls up to three similar titles" has no call.
- **Evidence:** DESIGN §8.7: "Shown once, the first time a profile with no reading history and no follows opens Home"; "`PUT /profiles/{id}/taste {…, onboarding_step: n}`"; "the next Home visit re-enters `/welcome?step={onboarding_step}`". §15.5: "new `POST /library/taste/seed {formats, genres, styles}` → `{items: SourceSeries[24]}`". `cinematic/DESIGN.md` §15.5: "`PUT /profiles/{id}/taste` accepts `step`; `GET /profiles` rows carry `onboarding_step` (migration sets `"done"` on existing profiles; new ones `NULL`)" and "`GET /onboarding/catalog?formats=&genres=&styles=` and `GET /ai/similar?anilist_id=`".
- **Fix:**
  1. Step 6 uses `GET /onboarding/catalog?formats=&genres=&styles=` (24 items, 18+ filtered). Delete `POST /library/taste/seed` from §8.7, §9.1.6 and §15.5.
  2. The PUT sends `step: 1…7 | "done"`.
  3. Onboarding shows when the active profile's `GET /profiles` row has `onboarding_step` of `NULL` or 1–7, and never when it is `"done"`. Skip-all and Finish both write `step: "done"`.
  4. Resume goes to `/welcome?step={onboarding_step}`.
  5. The three similar titles per pick come from `GET /ai/similar?source&series&fallback=genres` (limit 3, rendered without `why`).
  6. Update the §15.6 Taste row.

## PRODUCT-8

- **Severity:** medium
- **Section:** §8.0.10, §9.1.2 States, §9.1.5
- **Problem:** The AI endpoints fail with error codes that Glass never maps. Its AI copy is keyed by the availability `reason`, not by the error `code` that `POST /library/suggest` and `POST /library/world/suggest` return. A `429 ai_budget_exhausted` falls through to the generic "Something went wrong" row. If the client keys on HTTP 429, it falls into the `rate_limited` auto-retry instead, and retries a request that cannot succeed until midnight UTC.
- **Evidence:** `backend/services/suggestion_service.py:595` `code="ai_failed", status_code=502`; `:655` `code="ai_budget_exhausted", status_code=429`; `:661` `code="ai_not_configured", status_code=503`. DESIGN §9.1.5: "The copy lives once in `copy/ai.ts` … keyed by the server's `reason`"; §8.0.10 has rows only for `suggest_shelf_empty`, `ai_no_matches` and `rate_limited`.
- **Fix:** Add three §8.0.10 rows, all surfacing inline in For you with §9.1.5 lines and no haptic:
  - `ai_budget_exhausted` (429): the `budget_exhausted` long line and the countdown to 00:00 UTC. No automatic retry. Re-read `GET /library/suggest/availability`, which hides the Ask box.
  - `ai_not_configured` (503): the `not_configured` line.
  - `ai_failed` (502): the "upstream error" line and Try again.

  State in §8.0.10 that only `code == "rate_limited"` triggers the automatic `Retry-After` retry, never the HTTP status alone.

## PRODUCT-9

- **Severity:** medium
- **Section:** §8.0.8 (Content mode), §9.1.2 (Taste as context, States), §8.8 (Home in Novels mode), §15.5
- **Problem:** Glass sends request fields that do not exist, and it omits one the shared backend needs:
  1. The Ask sends `use_taste: false`.
  2. In Novels mode the Ask "uses `POST /library/suggest` limited to novel sources", but the request body has only `prompt` and `limit`.
  3. For you promises "results (up to 12)", while the local suggest caps `limit` at 8, and Glass never says which `limit` it sends.
  4. Home "follows the mode", but `GET /home` is called without the content-mode parameter the shared contract defines.

  None of the three additions is listed in §15.5.
- **Evidence:** `backend/routes/library.py:176-178`: `class SuggestRequest(BaseModel): prompt … limit: int = Field(default=6, ge=1, le=8)`. DESIGN §9.1.2: "sent as `use_taste: false`"; "results (up to 12)". §8.0.8: "in Novels mode the Ask uses `POST /library/suggest` limited to novel sources". `cinematic/DESIGN.md` §15.5: "`GET /home?content_kind=`".
- **Fix:** Add to §15.5: `use_taste: bool = true` and `content_kind: "manga" | "novel" | null` on both `POST /library/suggest` and `POST /library/world/suggest` bodies (with `content_kind: "novel"`, the local catalogue is filtered to sources whose `content_kind` is novel). The Ask sends `limit: 8` with "Only my sources" on and `limit: 12` with it off. Correct the States line to "up to 8 (your sources) or 12 (worldwide)". Home sends `GET /home?content_kind={manga|novel}` whenever novels are enabled.

## PRODUCT-10

- **Severity:** medium
- **Section:** §9.2.1 (Totals)
- **Problem:** The four stat cards show "all time" captions and also "the delta against the previous window". `/library/statistics` returns only `totals` (all time) and `window` (the chosen `days`), with `days` capped at 365. So there is no previous-window data. There is also no way to get a year-over-year delta, and a delta on all-time numbers is meaningless. An implementer must guess which figure the card shows and where the delta comes from.
- **Evidence:** DESIGN §9.2.1: "four stat cards (Time read, Chapters, Pages, Series) with 'all time' captions, the delta against the previous window ('+2 h 10 m')". capabilities §10: "`days (1-365, default 30)` … `window {…}` (for the chosen days)". §15.5 adds no previous-window field.
- **Fix:** Each card shows `window.*` for the selected range, captioned "last 30 days", with the all-time value as a second line "412 h all time" in `caption1` `label3`. The delta = `window(N) − (window(2N) − window(N))`, from one extra `GET /library/statistics?days={2N}` for N = 7, 30 and 90. The Year range shows no delta (the endpoint stops at 365). Alternatively, add `previous_window {sessions, pages_read, chapters_read, series_read, seconds_read}` to the statistics response in §15.5 and drop the second call.

## PRODUCT-11

- **Severity:** medium
- **Section:** §9.2.3 (Data, cards 3, 7 and 12, the year menu), §9.2.1 (Wrapped entry), §15.5
- **Problem:** Wrapped cards print figures the shared annual payload does not carry, and the call is incomplete:
  - Card 3 ("1,204 chapters · 38,410 pages") and card 12 (the "pages" total) need a pages figure, but the annual response has only `seconds_read` and `chapters_read`.
  - Card 7's footnote "From 3 Aug to 2 Sep" needs the streak's start and end dates, but the payload has `longest_streak {days, month}`.
  - `tz_offset_minutes` is required on `GET /library/annual`, but Glass calls `?year=` only, so the request fails validation.
  - The year menu "lists earlier years that have data" with no source.

  Glass's §15.5 row adds only `busiest_day` and `firsts_lasts`.
- **Evidence:** DESIGN §9.2.3: "`GET /library/annual?year=`"; card table rows 3, 7 and 12. `cinematic/DESIGN.md` §9.2: "`GET /library/annual?year=&tz_offset_minutes=` (the offset is required, −720..840)" and the response `{…, seconds_read, chapters_read, chapters_by_month, top_series, genres, by_hour, longest_streak: {days, month}, top_sources, circle, available_years, shareable}`.
- **Fix:** Call `GET /library/annual?year={y}&tz_offset_minutes={local}`. Extend the §15.5 row with `pages_read` (int) and `longest_streak {days, month, start, end}` (ISO dates). Name each card's field: 2 `seconds_read`; 3 `chapters_read`, `pages_read`, `chapters_by_month`; 4 `top_series`; 5 `genres`; 6 `by_hour`; 7 `longest_streak`; 8 `busiest_day`; 9 `firsts_lasts`; 10 `top_sources`; 11 `circle[0].finished_together[0]`; 12 the totals. The year menu (and "5 days recorded so far") reads `available_years` and `recorded_days`.

## PRODUCT-12

- **Severity:** medium
- **Section:** §9.2.4 (Coordinates, the mature rule), §9.2.1 (Share)
- **Problem:** "Mature series and covers are never drawn on a share card, whatever the gate says" cannot be implemented from the data Glass reads. The rows the Statistics share uses (`by_series`, `recent_sessions`) and the Wrapped rows carry no rating, so the client cannot tell which covers and titles are mature. It would either export mature covers into shareable images or invent a rule. The shared backend already computes a filtered set for exactly this purpose, but Glass does not use it.
- **Evidence:** DESIGN §9.2.4: "**Mature series and covers are never drawn on a share card**, whatever the gate says; the next eligible series takes the place." capabilities §10: `by_series [{source_id, series_key, title, cover_url, …}]` (no rating). `cinematic/DESIGN.md` §15.5: "`shareable: {genre_weights, top_series, art_series}` on `GET /library/annual` and on the range payload behind The Numbers' `Share`, computed server-side only from series that are not mature".
- **Fix:** Share sides draw covers, titles and genre words only from `shareable`: Wrapped from `annual.shareable`, and Statistics and streak shares from `shareable` on `GET /library/statistics`. Add the latter to §15.5 if the "range payload" is not already that endpoint. When `shareable.top_series` is empty, the card uses card 2's numeral layout with no cover box. Add a Playwright or widget check that exports the Summary card for a profile whose top series is mature and asserts the mature cover URL is absent.

## PRODUCT-13

- **Severity:** medium
- **Section:** §8.18 (Collections, collection detail), capabilities §26 (Smart collections)
- **Problem:** Capabilities asks for a smart-collection variant. The shared backend stores smart shelves as `rules` and computes their membership only on the device. Glass has no smart variant and no handling of `rules`, so the same profile, switched into Glass, sees every smart shelf it made in Cinematic as "This collection is empty". Add series, Edit and Remove would also then act on a shelf whose membership is computed.
- **Evidence:** `grep -c -i smart glass/DESIGN.md` = 0. capabilities §26: "Design collections with a 'smart' variant (rule chips …) and an auto-generated badge." `cinematic/DESIGN.md` §15.5: "Collections gain `rules: null | {all: [{field: "reading_status" | "is_favorite" | "new_count" | "format" | "content_kind", op: "eq" | "gte" | "in" | "ne", value}]}` … the server only stores them, membership is computed on the device".
- **Fix:** In §8.18, a collection with `rules != null` is **Auto**. Its members are computed on the device over the library rows by the `rules.all` conjunction, with the same evaluator as Cinematic in the shared data layer. The card carries an "Auto" capsule (`caption1`, `iris400` glyph `lightning`). Detail shows the rule chips under the name (read-only) and hides Add series, Remove and reorder. New collection gains a "Smart" segmented option with up to 3 rule rows (field menu, operator menu, value).

  States:
  - "No series match these rules yet."
  - Offline: evaluates over the cached library.

## PRODUCT-14

- **Severity:** medium
- **Section:** §8.0.8 (Unavailable content), §8.12 ⋯ menu, capabilities §26 (Source repoint)
- **Problem:** A followed series on a dead or removed source leaves the reader with only "Remove from library", which loses its place in the list. Capabilities asks for a "move to another source" flow; the columns exist, and the shared backend defines the endpoint. Glass has no surface for it.
- **Evidence:** `grep -c -i repoint glass/DESIGN.md` = 0. DESIGN §8.0.8: "opens the object lens with the specific line … plus 'Back' and, for followed series, 'Remove from library'". capabilities §26: "A 'Source is down, move to another source' flow on a followed series whose source health is `dead`, with a progress-mapping confirmation by chapter number." `cinematic/DESIGN.md` §15.5: "`POST /library/series/{followed_id}/repoint {source_id, series_key, keep_old: bool}` → `{followed, mapped_chapter_key, mapped_chapter_number | null}`".
- **Fix:** Add "Move to another source…" to the series ⋯ menu (followed only) and as the primary action of the §8.0.8 lens when the source is `dead` or `source_not_found`. The `?sheet=move-source` `large` sheet runs `GET /sources/search?q={title}` (tier 1, then tier 2) and lists candidates as rows (logo, title, "412 chapters", health bead). Choosing one shows the confirmation "You're on chapter 142 here. It becomes chapter 142 on Asura Scans." (`mapped_chapter_number`, or "Your place couldn't be matched; you'll start from chapter 1" when it is null) and a "Keep the old one too" switch (`keep_old`, default off). The tinted "Move" button sends the POST.

  States:
  - Searching (tier capsule).
  - No match: "No other source has this series".
  - Failed: toast "Couldn't move it. Try again".
  - Offline: "Moving needs a connection".
  - Success: toast "Moved to Asura Scans", and the sheet zooms into the new series detail.

## PRODUCT-15

- **Severity:** medium
- **Section:** §7.7 (Source row card), §8.10 (Sources), §8.11 (catalogue header)
- **Problem:** Source health reaches only the admin-only System status screen. Capabilities asks for a health dot on the Sources directory, a one-line health summary, and a "demoted" marker in both skins. Non-admin readers get no sign that a source is failing or dead before they open it. `GET /sources/health` and `GET /system/source-health` are never named. The source row also omits the source's `language`.
- **Evidence:** DESIGN §7.7 Source row card: "44 px source logo, name, description, 18+ tag when mature, pin toggle icon" (no health). The only health surface is §8.26 (admin). capabilities §16.1: "`GET /sources` … `health` … health dot"; "`GET /system/source-health` … '84 of 89 sources healthy'"; "Four status colours plus a 'demoted' (skipped by search) marker, in both skins".
- **Fix:**
  1. Source row: a 10 px health bead (the §8.26 bead as a content twin) after the name: `success` ok, `warning` failing, `danger` dead, `g600` unknown, with a 1 px `warning` ring when `demoted`. Its accessible text is "working", "having trouble", "not working", "not checked yet", plus ", skipped by search" when demoted. Add a `language` tag in `caption1` (for example "EN").
  2. Sources header line in `footnote` `label2`: "84 of 89 sources working" from `GET /system/source-health`, with a chip "Having trouble (5)" that lists `GET /sources/health` rows worst-first.
  3. Catalogue header: when `health.status` is failing or dead, an inline notice (`warning` / `danger`): "This source is having trouble; pages may not load." / "This source isn't working right now."

## PRODUCT-16

- **Severity:** medium
- **Section:** §8.4 (Register States), §8.0.10 (first row)
- **Problem:** §8.0.10 says the copy for seven Register errors lives in §8.3 and §8.4. §8.4 lists their names but gives copy only for `username_taken`. It also never says which field each error shakes, although "the shake on the first offending field" depends on it.
- **Evidence:** DESIGN §8.0.10: "`weak_password`, `username_taken`, `invalid_username`, `registration_disabled`, `invite_code_required`, `invite_code_invalid`, `bootstrap_window_expired`, `bootstrap_already_claimed` | inline | §8.3, §8.4". §8.4 States: "errors (`invite_code_required`, `invite_code_invalid`, `registration_disabled`, `username_taken` 'That username is taken.', `invalid_username`, `weak_password`, … `bootstrap_window_expired`, `bootstrap_already_claimed`)". No other occurrence carries copy.
- **Fix:** Add to §8.4:

  | Code | Field | Copy | Recovery |
  |---|---|---|---|
  | `invalid_username` | Username | "Use 3 to 64 letters, numbers, dots, dashes or underscores, starting with a letter or number." (the server rule, `backend/services/auth_service.py:49` `^[A-Za-z0-9][A-Za-z0-9_.\-]{2,63}$`) | none |
  | `weak_password` | Password | the server's `message` when present, else "Use at least 8 characters." | none |
  | `invite_code_required` | Invite code | "This server needs an invite code." | reveal the Invite code field if it was hidden |
  | `invite_code_invalid` | Invite code | "That invite code didn't work. Check it with whoever invited you." | none |
  | `registration_disabled` | form | "This server isn't accepting new accounts." | switch the screen to the Closed variant |
  | `bootstrap_window_expired` | form | "The time to claim this server has run out. Restart the server to claim it." | none |
  | `bootstrap_already_claimed` | form | "Someone already claimed this server. Sign in instead." | primary becomes "Sign in" |

## PRODUCT-17

- **Severity:** medium
- **Section:** §8.25.7 (Security, Change password), §8.0.10
- **Problem:** A wrong current password on Change password returns `401 invalid_credentials`. §8.0.10 routes that code to the Login copy ("That username and password don't match."), which is wrong in this sheet. §8.25.7 lists only client-side validation errors. The change-password rate limit (5/min and 20/h) has no state here.
- **Evidence:** `backend/services/auth_service.py:470-475`: "Current password is incorrect." `code="invalid_credentials", status_code=401`. capabilities §1: "change-password 5/min + 20/h". DESIGN §8.25.7 errors: "'Enter your current password', 'Enter a new password', 'At least 8 characters', 'Password is too long', 'The new passwords don't match', 'Your new password must be different'".
- **Fix:** Add two Security rows to §8.0.10:
  - `invalid_credentials` on `/auth/change-password`: inline on the Current field, "That isn't your current password.", `error` + shake. The 401 does **not** start the §8.0.9 signed-out flow, which keys only on `not_authenticated`.
  - `rate_limited`: the button counts down "Try again in 42 s" in `mono`, as on Login.

## PRODUCT-18

- **Severity:** medium
- **Section:** §8.18 (collection detail "reorder by drag", Collections sort menu), §7.35, §15.5
- **Problem:** Collection members are drag-reorderable "by the collection's member `sort_order`", but no endpoint writes member order. The backend has only add and remove, and neither Glass nor the shared §15.5 adds one. Separately, the Collections sort "Recently created" needs a creation date, and the list rows do not carry one.
- **Evidence:** `backend/routes/library.py:334-356`: only `POST` and `DELETE /library/collections/{collection_id}/series` (body `{source_id, series_key}`). capabilities §11: "`GET /library/collections` … `[{id, name, description, sort_order, series_count}]`". DESIGN §8.18: "reorder by drag (the collection's member `sort_order`)"; "sort menu (Name A–Z, Most series, Recently created, Custom order with drag)".
- **Fix:** Add to §15.5 `PUT /library/collections/{id}/series/order {items: [{source_id, series_key}]}` → 204 (the full ordered list, owner only, `403 forbidden` for members). Add `created_at` on `GET /library/collections` rows. Otherwise, drop member reorder and "Recently created" from §8.18, §7.35 and §11.

## PRODUCT-19

- **Severity:** medium
- **Section:** §10.1 (Heading reveal: parameter table, web CSS, Flutter code)
- **Problem:** The owner's heading reveal includes a "smooth color transition on hover/state". The §10.1 table promises it (`colorShift` 240 ms), but neither reference implementation does it: the web CSS has no `transition`, and the Flutter letters use a fixed `TextStyle`. The Flutter sample also breaks the table's "wrapped per word so lines break at spaces": it puts every character directly in one `Wrap`, so a two-line title breaks mid-word. It cannot change text either (placement 3, the hero title that "replaces old text"). The controllers are sized once in `initState` for the first string, so a longer new title reads past the list.
- **Evidence:** 00-decisions: "Heading reveal: … smooth color transition on hover/state." DESIGN §10.1 table: "Colour on hover and state | `colorShift` 240 ms"; the CSS block has no `transition`; Flutter: `Wrap(children: [for (var i = 0; i < chars.length; i++) AnimatedBuilder(… Text(chars[i], style: widget.style))])`; `_move = List.generate(n, …)` in `initState` only, and no `didUpdateWidget`.
- **Fix:**
  - Web: `.letter-reveal { transition: color var(--mm-dur-colorShift, 240ms) cubic-bezier(0.2, 0, 0, 1); }` (the letters inherit the animated colour).
  - Flutter: wrap the letters in `AnimatedDefaultTextStyle(style: widget.style, duration: const Duration(milliseconds: 240), curve: const Cubic(0.2, 0, 0, 1))`, and have each letter use `DefaultTextStyle.of(context)`. Build `Wrap(children: words.map((w) => Row(mainAxisSize: MainAxisSize.min, children: letters(w))))`, with a trailing space per word, so breaks fall only at spaces. Add `didUpdateWidget` so that when `oldWidget.text != widget.text` it disposes and rebuilds the controllers and restarts the wave (the old letters leave together over `fadeOut`).
  - Add a widget test that a 40-grapheme title at 200 px width wraps between words.

## PRODUCT-20

- **Severity:** low
- **Section:** §10.2 (web `TypedHeadline` and CSS)
- **Problem:** The graphemes start their CSS `animation-delay: calc(var(--i) * 50ms)` at first paint, which is server-rendered, while the caret's `setInterval` starts only after hydration. With hydration at 300 ms, six characters are already visible when the caret starts at position 0, and it trails the typing for the rest of the line. The 50 ms rhythm the owner specified stays right, but the caret, the element that makes it read as typing, is out of step with it.
- **Evidence:** DESIGN §10.2 CSS: "`.typed > [data-g] { … animation: ty-land …; animation-delay: calc(var(--i) * 50ms); }`"; code: "`place(0); const id = window.setInterval(…, 50)`" inside `useEffect`.
- **Fix:** Render the graphemes with `animation-play-state: paused` until the effect sets `data-typing="run"` on the heading, in the same tick that starts the interval (`.typed[data-typing="run"] > [data-g] { animation-play-state: running; }`), so letters and caret share one start time. The CSS fail-safe (`is-done` after 1,500 ms without hydration) shows the full text.

## PRODUCT-21

- **Severity:** low
- **Section:** §7.7 (Continue stack), §8.8 (Continue rail and spotlight "Continue Ch 143")
- **Problem:** When a finished chapter has auto-advanced, continue-reading returns the next chapter with `last_page: 1, page_count: 0`. The continue stack prints "Ch 142 · p. 18 of 40" and draws a ring from position / total, so this case renders "p. 1 of 0" and divides by zero.
- **Evidence:** capabilities §8: "when that chapter is finished it moves forward to the next one (`last_page: 1, page_count: 0`)". DESIGN §7.7: "'Ch 142 · p. 18 of 40' `footnote` `label2`, progress ring (24 px …) around the chapter number".
- **Fix:** When `page_count == 0`, the card reads "Up next · Ch 143". The ring is empty (the track only), and the button reads "Start" instead of "Continue"; the spotlight's primary reads "Start Ch 143".

## PRODUCT-22

- **Severity:** low
- **Section:** §8.16.4 (Cast sheet), §8.16.5 (render toasts and job rows)
- **Problem:** The cast rows show neither a character's gender nor a way to correct it, yet `POST /novels/cast` takes `gender` and a tapped row opens "the orbit filtered to that character's gender". An owner cannot fix a misgendered character, and the filtered orbit then hides the right voices. The narration render skip reasons `chapter_unreadable` and `already_queued` have no toast wording. The failed-job line "{reason} is the short line for its `error_code`" has no table (the server emits `lease_expired`, for example).
- **Evidence:** capabilities §19.4: "`POST /novels/cast` (owner) | `{…, name, gender? (male|female|unknown), voice_id?}` | … **Cast sheet**: every character, gender, assigned voice". `backend/services/novel_render_queue.py`: skip reasons `already_rendered`, `chapter_not_cached`, `chapter_unreadable`, `already_queued`; `error_code = "lease_expired"`.
- **Fix:**
  - Each cast row shows a gender capsule (Male · Female · Unknown). For owners, tapping it opens a 3-item menu that writes `POST /novels/cast {gender}` and sets the lock glyph.
  - Toast skip wording: "{n} already narrated", "{n} not on the server yet", "{n} couldn't be read", "{n} already waiting".
  - Job failure lines: `lease_expired` "The narration PC stopped responding"; `audio_convert_failed` as written; any other code "Rendering failed ({code})".

## PRODUCT-23

- **Severity:** low
- **Section:** §8.6 (Profile form), §8.0.8, §8.25.1
- **Problem:** Two sections name a skin choice on the profile form: "the profile form's skin row" and "the profile form of the active profile". The §8.6 Content list has no Skin row, so the implementer has to guess whether a new profile can pick its skin, and which skin a new profile gets when none is picked.
- **Evidence:** DESIGN §8.0.8: "the skin picker, onboarding step 2, the profile form's skin row and the command palette's skin action show Glass only once `flags.glass_available`…". §8.25.1: "(this row's skin cards, onboarding step 2, the profile form of the active profile)". §8.6 Content: orb preview, Name, Avatar, Mood, Mature (18+), buttons (no skin).
- **Fix:** Add to §8.6 Content, after Mood, a **Skin** segmented control Glass · Cinematic with 32 px mini previews. It writes `skin` in `POST /profiles` and `PATCH /profiles/{id}`. A new profile defaults to the skin of the device it is created on. For the active profile, a change runs the §8.25.2 alert and restart. The row is hidden until `flags.glass_available`.

## PRODUCT-24

- **Severity:** low
- **Section:** §7.26 (Avatar presets)
- **Problem:** capabilities §5 requires that old `avatar_key` values still map to something. Glass lists the 12 presets by display name only. Three of today's keys, `lunar`, `star` and `reader`, do not obviously match "Lunar Moon", "Starlight" and "Bookworm", and there is no fallback for an unknown key.
- **Evidence:** capabilities §5: "`avatar_key` is a free string … Old keys must still map to something." `frontend/src/features/profiles/avatars.ts:32-43`: keys `violet, cyan, rose, amber, emerald, ember, blade, phantom, arcane, lunar, star, reader`. DESIGN §7.26 gives names only.
- **Fix:** Add the key column: Violet Spark `violet`, Cyan Rocket `cyan`, Rose Heart `rose`, Amber Coffee `amber`, Emerald Cat `emerald`, Ember Flame `ember`, Steel Blade `blade`, Phantom `phantom`, Arcane Wand `arcane`, Lunar Moon `lunar`, Starlight `star`, Bookworm `reader`. An unknown key renders Violet Spark with the profile's initial instead of the glyph.

## PRODUCT-25

- **Severity:** low
- **Section:** §8.15.7 (novel states), §8.0.10 (`db_busy`), §8.14 / §8.15 (progress outbox), §8.25.10 (Export)
- **Problem:** Four capability details have no surface:
  1. A novel chapter the server returns from a stale cache (`cache.stale: true`, served while the source is down) looks exactly like a fresh one. Only downloaded copies get "Saved copy".
  2. The `db_busy` capsule would appear in the reader for a silent progress keep-alive, which capabilities says should back off quietly.
  3. `POST /reader/progress/batch` `rejected` items and the optional "Synced N reads" have no treatment.
  4. Backup export's `include_cache` option ("a warm clone with caches") is absent.
- **Evidence:** capabilities §1: "Browse pages and novel chapters carry a `cache` block … a quiet 'offline copy from <time>' badge"; §13: "`503 db_busy` with `Retry-After` should back off quietly"; `POST /reader/progress/batch` → "`{saved, advanced, items, rejected}` … a 'Synced N reads' confirmation is possible"; §22: "`GET /backup/export` (admin) | `include_cache?`". DESIGN §8.0.10 `db_busy`: "capsule | 'The server is busy. Trying again in {n} s'".
- **Fix:**
  1. Novel reader: when `cache.stale`, show a `warning` capsule "Saved copy · 2 h" (from `fetched_at`) in the top-left group, as the catalogue does.
  2. §8.0.10: `db_busy` on background writes (progress keep-alive, outbox flushes) retries after `Retry-After` with no UI; the capsule is only for user-initiated actions.
  3. Outbox flush: `rejected` rows are dropped after one retry and logged to Diagnostics. When `saved ≥ 5` after an offline period, show a toast "Synced 12 reads".
  4. Export: a switch "Include caches (larger, restores faster)", default off, which sends `include_cache=true`.

## PRODUCT-26

- **Severity:** low
- **Section:** §8.12, §8.13 (series detail facts, Tags sheet), capabilities §26 (Search improvements, tag generation, metadata enrichment)
- **Problem:** Capabilities asks to reserve space on the series page for enriched metadata (rating, format, official links, alternate titles) and AI-suggested tags with accept and reject. The shared backend serves both (`GET /series/enrichment`, `GET /ai/tags`). Glass's series page has no slot for them, so a Glass series page shows less than the same series in Cinematic, from the same backend.
- **Evidence:** `grep -c 'alt titles\|official\|enrichment' glass/DESIGN.md` = 0. capabilities §26: "Reserve space on the series page for enriched metadata (rating, format, official links, alt titles) and AI-suggested tags with accept/reject." `cinematic/DESIGN.md` §15.5: "`GET /series/enrichment?source&series` → `{anilist_id, format, score, official: [{site, url}]} | null`" and "`GET /ai/tags`".
- **Fix:**
  - §8.12 facts line gains "★ 8.4 · Manhwa" from `enrichment.score` and `format` when non-null. Add a "Read officially" row of up to 3 site chips from `official`; each opens externally, with the §8.0.10 "Couldn't open {site}" toast on failure.
  - The Tags sheet gains a "Suggested" group from `GET /ai/tags`: chips with the machine sparkle, each with ✓ (accept = create or assign the tag) and × (dismiss).
  - States: enrichment null means the row is omitted; AI unavailable means the Suggested group is omitted.

## PRODUCT-27

- **Severity:** low
- **Section:** §8.17 (Filters sheet, Manage tags), §8.0.3 (Library query names), §15.5
- **Problem:** Tag data does not match the shared contract Glass cites:
  1. Glass lists "`tag_ids` on `FollowedSeries` list rows (both Cinematic's)", but Cinematic names the row field `tags` and adds `tag_ids=` as the filter parameter.
  2. Manage tags renames inline, which needs `PATCH /library/tags/{id}`. That endpoint exists only in the shared additions, and Glass never names it.
  3. Each Manage-tags row shows "12 series", but no call returns a per-tag count, and the library list is capped at 200 rows per page.
- **Evidence:** DESIGN §15.5: "`tag_ids` on `FollowedSeries` list rows (both Cinematic's)"; §8.17 Manage tags: "each row the colour dot, the name and '12 series'; tap renames inline". `cinematic/DESIGN.md` §15.5: "`tags` on `FollowedSeries` list rows; `GET /library/series` gains `tag_ids=` (any-of); `PATCH /library/tags/{id} {name?, color?}`". capabilities §12: no rename, no count.
- **Fix:** Name the row field `tags` (as `[{id, name, color}]`) and keep `tag_ids=` as the filter parameter. Add `PATCH /library/tags/{id} {name?, color?}` to the §8.17 rename and to §15.5 as Cinematic's. Add `series_count` to `GET /library/tags` rows in §15.5, or drop the "12 series" count.

## PRODUCT-28

- **Severity:** low
- **Section:** §9.3.4 (Recommend states), §9.1.4 (More like this), §8.11 (genre chip), §8.12 (genre tag links)
- **Problem:** Several gaps in states and links:
  1. The recommend sheet has no loading state for its member orbs and no offline state. Letters need the server, and the §9.3.4 state list is "no one accepting, sending, sent, failed".
  2. More like this has no offline state.
  3. The catalogue's genre chip is always drawn, but capabilities says the genre filter exists only when `GET /sources/{id}/genres` is non-empty, which is 22 of 89 sources.
  4. Series detail links "the first four genres … to the source catalogue with `?genre=`". The catalogue's `genre` parameter takes a genre `id` from that list, not the free genre string on `SourceSeries`, so most links would filter nothing.
- **Evidence:** DESIGN §9.3.4 States; §9.1.4 (Loading, Empty and AI-unavailable only); §8.11: "a genre chip ('All genres' / the chosen genre) that blooms into a searchable menu"; §8.12: "first four genres as links to the source catalogue with `?genre=`". capabilities §16.2: "`GET /sources/{id}/genres` … `[{id, label}]` (22 sources have any) | Genre filter sheet, only when non-empty"; "`GET /sources/{id}/series` | `page, query?, sort? (mode id), genre?`".
- **Fix:**
  1. Recommend sheet: while loading, 3 orb skeletons; offline, "Recommending needs a connection" with Send disabled.
  2. More like this offline: the rail is omitted.
  3. Catalogue: draw the genre chip only when the genres list is non-empty.
  4. Genre tags link to `?genre={id}` only when a `label` in that source's genre list matches the tag case-insensitively. Otherwise the tag opens Search with `?q={genre}&scope=sources`.
