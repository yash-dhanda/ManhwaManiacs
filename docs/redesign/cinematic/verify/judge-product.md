# Cinematic DESIGN.md: verdicts on the capabilities and owner-decisions audit

Judge of `cinematic/verify/find-product.md` (30 findings). For each finding I tried to refute it. I searched `cinematic/DESIGN.md` for the missing behaviour, read the backend and client code the finding cites, and checked the proposed fix against `inventory/00-decisions.md`, `stack-decision.md` and the rest of DESIGN.md. Where a fix was wrong, vague, heavier than needed or inconsistent, I rewrote it. The final wording of every fix is in **Confirmed** below.

Result: **28 confirmed** (3 of them narrowed), **2 refuted**.

---

## Verdicts

| ID | Verdict | Severity | Reason |
|---|---|---|---|
| PRODUCT-1 | Confirmed, fix tightened | high | §9.1.5 l.2903 auto-opens the recap on `ALWAYS` and `AFTER N DAYS AWAY` with no availability condition. l.1768, l.1795 and l.2831 depend on "a recap is possible", but no endpoint or field says so. The only call is the streamed `GET /ai/recap` (l.2934). For manga, OCR text exists only for scanned chapters (capabilities §20, §26), so the default setting sends most manga to the `NO RECAP FOR THIS ONE` slate. The range rule and the SSE framing are undefined. The finding's fix is sound. I made the series page and reader call the availability endpoint directly, since no existing series payload can carry it cleanly. I also added that the web must read the stream with `fetch`, because `EventSource` cannot send `X-Profile-Id`. |
| PRODUCT-2 | Confirmed, fix extended | high | Pins are per profile (`SourcePin` is unique on `user_id, profile_id, source_id`, `backend/database/models.py:151-160`), so a new profile has none. `world_recs.py:450-451` returns an empty `for_you` with no seeds. No endpoint serves "world recommendations by genre", and `GET /ai/similar` takes only `source&series`. So onboarding steps 3 and 5 and the new-profile Tonight sections (`Popular on your sources`, `Sources`, `Genres`, l.1820–1821) all come back empty. `onboarding_step` (l.1755) has no default for profiles that already exist. The fix left the new-profile `Sources` and `Genres` sections empty, so I added fallbacks for both. |
| PRODUCT-3 | Confirmed, fix extended | high | The §9.3.8 endpoint list (l.3146) has no member endpoint, no member filter on the feed, no "clear my activity" call, no per-series circle state for the feature page `CIRCLE` tab (l.2392) or the reader panel (l.2178), no body for the reaction `DELETE`, and no calls for `SHARED WITH YOU` or `Leave shelf` (l.3132–3134). One more gap: collection members carry no title or cover (capabilities §11), and a member's own library does not contain the owner's series, so shared-shelf detail cannot render. I added that. |
| PRODUCT-4 | Confirmed, fix rewritten | high | §2.1.5 (l.147) and §15.6 (l.3867) move page tint to the client because "the shared VPS image proxy must not decode and analyse every page". §9.4.3 (l.3175) then has the VPS decode every page with Pillow to find panels. `stack-decision.md` §2.6 does list panel boxes as server-side, so the change must be a sign-off amendment like S1, not a silent swap. States are missing for loading, errors and offline (downloaded chapters have no panels). One of the finding's claims is wrong: a backend background job does not pass through the per-client slowapi 60/min bucket. The rest stands. My rewrite adds the S11 amendment, fixes the detection rule (an 8 % area floor breaks on tall webtoon strip images) and names the parity fixtures concretely. |
| PRODUCT-5 | Confirmed, fix adjusted | high | `auth_service.py:470-474` answers a wrong current password with 401 `invalid_credentials`, while l.1648 signs the user out on "any 401". §8.30.4 (l.2711) has no copy for server errors. An allowlist of codes would sign nobody out on a future 401 code, so I used an exclusion instead: every 401 signs out except `invalid_credentials`. `weak_password` is only too short or too long (`core/auth.py:52-58`), so the fix shows the server's message. |
| PRODUCT-6 | Confirmed | medium | The Pass it on filter plus its caption (l.3125) shows the sender which profiles on other accounts have 18+ switched on. The ring rule in §7.25 (l.1383) lists its conditions without the member's own `Include 18+ titles in my activity` switch, which contradicts §9.3.1 (l.3078). The fix is correct. |
| PRODUCT-7 | Confirmed, fix rewritten | medium | No endpoint implements Mark read or Mark unread (l.2403, l.2409, l.2433, the Cutting menu at l.1047 and Library select mode at l.1856). Progress never rewinds. `progress_service.py:996-1035` writes a `ReadingSession` whenever a save advances the position, so a bulk mark-read would inflate statistics and extend streaks. The finding's "mark read" marked every chapter up to the tapped one, even for a single swipe. I split it into `Mark read` for one chapter and `Mark read up to here`, following the reader-app convention, and covered Library select mode. |
| PRODUCT-8 | Confirmed, priority corrected | medium | Nothing triggers the re-render that `RE-VOICING` waits for (l.2341). The sheet never says narrated chapters can be selected or that `force` is sent (l.2354). The fix had the priorities backwards: the queue runs `order_by(priority.desc())` (`novel_render_queue.py:188`), so the opener's `Narrate this chapter` (l.2366) must send the higher value. |
| PRODUCT-9 | Confirmed | medium | `suggestion_service.py` raises `suggest_shelf_empty` 409 (l.556), `ai_budget_exhausted` **429** (l.655), `ai_not_configured` 503 (l.661) and `ai_failed` 502 (l.595/680/734). The Picks states (l.2866–2878) map only by availability reason and by 429 → `SLOW DOWN`. `/library/suggest` items are `{kind:"source", …}` with no format, status or rating, yet l.2855 draws them as World cards, whose kicker needs those fields (§7.6). |
| PRODUCT-10 | Confirmed, one field added | medium | `GET /home` (l.2932) returns a composed `headline` whose time word follows the local hour (l.2835), plus an `at_risk` flag that means "after 20:00 local". The endpoint takes no timezone and is cached for 10 minutes. The client-side recompute in the fix needs `last_active_date`, which the `/home` streak object does not have, so I added it. |
| PRODUCT-11 | Confirmed | medium | `app_distribution.py:1985-1990` serves `/app/media/{name}` from the screenshots folder, takes one path segment and allows image suffixes only. The backend has no `StaticFiles` mount. So `/app/media/soundscapes/{id}.ogg` (l.3167, l.3857) and the install page's "static folder" fonts (l.2803) return 404. Starlette 1.6.0 `FileResponse` serves Range requests, so the fix works as written. |
| PRODUCT-12 | Confirmed, web signal rewritten | medium | There are four defects. (1) The §15.6 60-grapheme cap and word-level fallback appear nowhere in §10.1 or its code, and the decisions ask for a per-letter reveal with maximum effects. (2) The trigger table (l.3218) requires cover and feature titles to replay on every mount after the match cut, but both code samples only handle in-view plus the seen-set. (3) `AnimatedDefaultTextStyle` has no delay parameter, and the Flutter widget has no `MouseRegion`. (4) The web passes `graphemes(text).length` with spaces while Flutter excludes them, so `step` differs above 24 letters ("Because you read Solo Leveling": 19.3 ms against 22.4 ms). React `<ViewTransition>` exposes no `finished` promise, so I tied the web signal to the 480 ms match-cut token and the Flutter signal to the route animation. |
| PRODUCT-13 | Confirmed | medium | "The profile's measured reading pace" (l.3157, l.2244) is defined nowhere: nothing says how it is measured, over what window, within what bounds, where it is stored or how it converts to px/s. The fix's formula has consistent units (words/s × px/line ÷ words/line). |
| PRODUCT-14 | Confirmed, fix adjusted | medium | The design adds hover prefetch of the manifest plus two pages (l.1978), "first five" manifests on load (l.2387), a manifest plus a crop for each of 20 dialogue results (l.2577) and novel prefetch, all against the 60/min per-IP sources bucket, which also covers covers and page images (capabilities §1). DESIGN.md never paces them. I changed two things. The limiter belongs in the shared data layer so Glass inherits it. Reader pages (P0) and user lists (P1) never wait on the local bucket, only consume from it, because the server already enforces the real limit and prefetch is what must yield. On the web, covers can only be gated by assigning `src` late. |
| PRODUCT-15 | Confirmed, narrowed | medium | Valid: `view-transition-name: cover-<sourceId>-<seriesKey>` (l.1499) builds a CSS identifier from raw keys, which is invalid for keys with `/`, `%` or spaces. `routes.dart`, which percent-encodes today, is replaced by the generated `contract.g.dart` (stack-decision §3), so the generator must emit encoding builders. Refuted part: follow state by `series_identity` already lives in the kept data layer (`frontend/src/features/library/followed-index.ts` `identities` / `followedIdFor`, `mobile/lib/features/library/utils/series_identity.dart`), and skins must use that layer (stack-decision §2.6). The fix's SHA-1 needs async `crypto.subtle` during render, so I replaced it with a synchronous FNV-1a. |
| PRODUCT-16 | Confirmed | medium | Circle's write paths have no failure or offline copy. The table says only "Offline / error: Notices" (l.3108), Pass it on has only its success toast (l.3125), and `Clear my shared activity` has no dialog text (l.3138). The decisions require full states for every new feature. The fix's copy follows §12.5 and the 1000 ms destructive arm (§15.7). |
| PRODUCT-17 | Confirmed, iOS note added | medium | Android's system share sheet has no guaranteed save-to-gallery target, so "Save image through the share sheet" (l.3056) leaves Android with no way to save. The minimum SDK is 24 (`android/app/build.gradle.kts:83`), so the pre-API-29 fallback is needed. Separately, iOS "Save Image" from `UIActivityViewController` needs `NSPhotoLibraryAddUsageDescription`, and `ios/Runner/Info.plist` has only `NSPhotoLibraryUsageDescription`, so the iOS path as written would be terminated by the system. |
| PRODUCT-18 | Confirmed | low | `NARRATED BY` needs "the top 3 narration voices by listening time" (l.3039, l.3067). Nothing records listening: the audio endpoints are reads only, and progress rows carry no voice. The fix is the smallest one that makes the line true. |
| PRODUCT-19 | Confirmed | low | The `CAUGHT UP` deck (l.2051) promises "You'll get a notice when 143 lands" even for a Completed series, and neither reader has an end-of-series state, although capabilities §26 reserves an "Up next" slot. The fix uses existing data (`SourceSeries.status`, `PATCH /library/series/{id}`). |
| PRODUCT-20 | Confirmed, merged with PRODUCT-9 | low | The same states have different copy in different places. Budget reads "Today's asks are used up…" at l.2871 but "The picks desk is closed tonight." at l.2948. Rate limit is a `SLOW DOWN` countdown at l.2873 but "Try again in a minute." at l.2948. §7.8 (l.1098) and §9.1.6 (l.2924) hard-code the budget line for every reason. Budget reset at midnight UTC is correct (`suggestion_service.py:653`). |
| PRODUCT-21 | Confirmed, fix rewritten | low | `(v * 6).floor()` over a 3340 ms controller gives 556.7 ms halves, not the 530 ms `dur.caret`. The fix's tail `1 - (ms - 3180) / 160` would flash the caret back on, because the sixth half ends off. That also means the specified 160 ms "fade" fades from 0 on both clients, so I dropped it. |
| PRODUCT-22 | Confirmed | low | "One hundred and twenty-three days and counting. One chapter keeps it alive." is 75 graphemes. Every spelled count of 101 or more breaks the ≤ 60 limit for typed headlines (l.3399), e.g. "One hundred and four…" at 67. |
| PRODUCT-23 | Confirmed | low | `reading_stats_service.py:690-711` counts any day with a `ReadingSession`, a few pages included. DESIGN.md ties the streak to a completed chapter: "first completed chapter of the day" (l.3004), "no chapter read today" (l.1822). |
| PRODUCT-24 | Confirmed, narrowed | low | Valid: the "rolling windows … until a calendar-year aggregate exists" paragraph (l.3042) contradicts the new per-year `GET /library/annual?year=` (l.3067), which is that aggregate. Refuted part: the ≥ 30-day banner threshold against the ≥ 7-day availability is not a contradiction. They serve different purposes, and l.2963 already reads "Your year so far" before December. |
| PRODUCT-25 | Confirmed | low | §8.15.9 (l.2288) has no "further on another device" toast, although novel progress uses the same rows (capabilities §13). It also has no badge for `cache.stale` novel chapters; its "Stale text" state is about attribution fingerprints, not the cache. The manga reader has the toast (l.2053). |
| PRODUCT-26 | Confirmed | low | The current mobile app opens `/backup/export` in the external browser (`backup_screen.dart:29-31`). The route requires an admin session (`routes/backup.py:63`), and the browser holds no Bearer token, so the download fails. l.2727 keeps that behaviour. `NightlyBackup.ok = false` with `phase` has no presentation (l.2726). `share_plus` 13.3.0 is already added in §15.11. |
| PRODUCT-27 | Confirmed | low | §12.4 (l.3570) fires "haptic `impress`", which is a pattern name, not an event. §6 (l.891) and S8 (l.3913) declare `splash.reveal` sound-only, and haptics dispatch by event name through `contract.json`. |
| PRODUCT-28 | Confirmed, fix rewritten | low | On Android, Save to Files writes to `getApplicationDocumentsDirectory()` (`mobile/lib/features/downloads/services/chapter_export.dart:74-95`), which is app-private and invisible in any file manager. The "path" in the result dialog (l.2549) is useless there. The fix's `file_picker.getDirectoryPath()` returns a path that `dart:io` often cannot write under scoped storage. The reliable route with no permission is MediaStore `Downloads` on API 29+, through the same native channel as PRODUCT-17. |
| PRODUCT-29 | **Refuted** | — | The seven capability flags are constants: `backend/routes/settings.py:65-73` returns `True` for every one, and no setting or environment variable turns them off. Rules for `online_sources`, `continue_reading` and `reading_progress` would never run, so this is speculative (YAGNI). |
| PRODUCT-30 | **Refuted** | — | The contract is not contradictory. "Each milestone shows once per profile" (l.3010) answers the rebuilt-streak question: a later run's 7 and 30 show no card. The alternative deck "Your longest is 41." has a real case too. Milestone cards are new, but reading sessions have been recorded since 27 July 2026, so a profile whose longest run predates the feature (41 days, before `milestones_seen` existed) reaches 30 for the first time on the new streak and gets that deck. The flat `milestones_seen` array is enough. |

---

## Confirmed

Final fixes, ready to apply to `cinematic/DESIGN.md`. Every backend addition also goes into §15.5. None touches `backend/connectors/`. All of them gate 18+ on serve and scope by profile.

### PRODUCT-1 · high · "Previously on" availability, range, auto-open and stream

- **New endpoint.** `GET /ai/recap/availability?source&series&to` returns `{available, reason: "ok" | "no_dialogue" | "first_chapter" | "not_configured" | "budget_exhausted", range: {from_key, to_key, from_number, to_number}, est_seconds, cached}`. `GET /home` carries the same object as `recap` on `cover` and on each `continue` item. The feature page, the book page and the reader call the endpoint directly: once on load, and once on the reader's first page.
- **Range.** The chapters this profile completed before `to`, newest first, at most 12. The walk stops at the first gap of more than 60 days between consecutive `last_read_at` values.
- **Available when:**
  - manga: `GET /ocr/coverage` indexes at least 50 % of the range's chapters;
  - novels: always, except on the first chapter;
  - both: the AI desk is configured and the budget allows it (a cached recap is always available).
- **Rendering.** Every `Previously on…` button (l.1768, l.1795, l.1804, the feature and book pages, Quick look) and the reader chip render only when `available`. `ALWAYS` and `AFTER N DAYS AWAY` auto-open the recap only when `available`. Otherwise `Continue` goes straight to the reader with no slate. The `NO RECAP FOR THIS ONE` slate appears only after an explicit tap on a button whose availability went stale. Cover-story case 3 (l.2831) uses `available`.
- **Chip.** `PREVIOUSLY ON · {ceil(est_seconds / 60)} MIN`.
- **SSE framing** for `GET /ai/recap`:
  - `event: meta`, sent first, with data `{range, cast, sourced_from}`;
  - `event: delta` with data `{text}`;
  - `event: done`;
  - `event: error` with data `{code, message}`.
- **Clients.** The web reads the stream with `fetch` and a `ReadableStream` reader, not `EventSource`, which cannot send `X-Profile-Id`. Flutter uses the installed `dio` 5 with `ResponseType.stream` and a `LineSplitter`, with no new package.
- **Budget.** A recap counts as one ask against the caller's daily ceiling (60 for the owner, 10 for other accounts, the same ledger as `/library/suggest`), and only on a cache miss.

### PRODUCT-2 · high · Onboarding and the new-profile Tonight have no data source

- **New endpoint.** `GET /onboarding/catalog?formats=&genres=&styles=` returns:
  - `formats: [{format, covers: [cover_url × 3]}]`: AniList trending per format;
  - `genres: [{name, weight}]`: 30–40 entries, the union of every browsable source's `GET /sources/{id}/genres` labels, de-duplicated case-insensitively, with mature sources' genres excluded for a gated profile;
  - `seeds: WorldItem[]`: 24 items from AniList trending, filtered by the liked and loved genres, `available` items first, `is_adult` excluded unless the gate is open.

  It is cached for 24 h per (gate, formats, genres). Step 3's paragraph and step 5's wall read from it, not from pins or `for_you`.
- **Similar picks.** `GET /ai/similar` also accepts `anilist_id` and returns 3 WorldItems for the step-5 "insert 3 similar" (budget-free, cached for 7 days).
- **New profiles with 0 pins.** They get the 3 healthiest non-18+ sources of the current content kind (`health.status == "ok"`, fewest `consecutive_failures`):
  - the `popular` section and cover-story case 5 use their `popular` browse mode, first 12 titles;
  - the `sources` section shows these 3 as hubs, captioned `SUGGESTED SOURCES`;
  - the `genres` section uses the taste genres from onboarding (loved first) and is not rendered when there are none.
- **Migration.** When the `onboarding_step` column is added, set it to `"done"` for every existing profile. New profiles default to `NULL`, which means step 1.

### PRODUCT-3 · high · Circle backend calls the screens need

Add to §9.3.8:

- `GET /circle/members/{profile_id}` → `{profile, sharing: {activity, reactions}, now, reading: [series], finished: [series], reactions: [...], shelves: [...]}`. `404 circle_member_not_sharing` renders "Riya isn't sharing right now."
- `GET /circle/feed?cursor&profile_id=&kind=reading|reaction|letter`.
- `DELETE /circle/activity` → 204. It implements `Clear my shared activity`.
- `GET /circle/series?source&series` → `{followers: [profile], readers: [{profile, chapter_key, chapter_number, last_read_at}]}`. It applies each member's sharing switches, exclusions and Include-18+ switch, and the viewer's gate. It feeds the feature page `CIRCLE` tab and the reader `CIRCLE` panel ("Riya is on Ch. 150").
- `DELETE /circle/reactions` with the body `{source_id, series_key, chapter_key}`.
- Shared shelves:
  - `GET /library/collections` rows gain `shared: {owner_profile_id, mode, member_profile_ids} | null`, and the response gains `shared_with_me: [...]`;
  - `GET /library/collections/{id}` answers members too, and its `series` rows carry `title`, `cover_url` and `ambient`, because a member's library cannot join the owner's series;
  - `POST /library/collections/{id}/series` is allowed for `can_add` members (`403 forbidden` otherwise);
  - `DELETE /library/collections/{id}/share/me` implements `Leave shelf`.
- **Polling.** Poll `GET /circle/members` every 60 s while Circle, Tonight's circle sections, a member page or a reader `CIRCLE` panel is visible, and pause in the background. The ring colour updates on each poll.
- **Race.** `409 recipient_unavailable` when a recipient turned `Receive recommendations` off after the sheet opened. The toast reads "Riya isn't taking recommendations any more.", and that recipient is deselected.

### PRODUCT-4 · high · Guided view: detect panels on the client (sign-off amendment) and complete its states

- **§15.10 gains S11 (sign-off before the reader cluster).** `stack-decision.md` §2.6 item 2 lists "panel boxes for the guided view" as backend work. This contract moves panel detection to the client for the same reason as S1: the shared VPS image proxy must not decode and analyse every page. It also lets downloaded chapters use guided view offline.
- **Detection.** It is a reader-engine duty in §15.4, beside page tint.
  - Web: the page-tint Web Worker also receives the page's `ImageBitmap` scaled to 360 px wide on an `OffscreenCanvas`.
  - Flutter: a `compute()` isolate on `ResizeImage(provider, width: 360)` raw RGBA.
  - Analysis runs one page ahead of the reading position.
- **Rule** (identical on both clients):
  1. Compute luminance per pixel.
  2. A row or column is a **gutter line** when at least 98 % of its pixels have L > 0.92, or at least 98 % have L < 0.06.
  3. A **gutter** is a run of at least 12 gutter lines (at 360 px width).
  4. Split the page into horizontal bands at the gutters, then split each band once at vertical gutters.
  5. Drop rects under 48 px on either side.
  6. Pages with height/width > 2 (webtoon strip images) split on horizontal gutters only.
  7. Reading order is top to bottom, then left to right, or right to left when the series direction is RTL.
- **Parity.** 24 small greyscale PNG fixtures in `design/panel-vectors/` with their expected rects in `design/panel-vectors.json`, run by `panels.test.ts` and `panels_test.dart`. A rule change that does not update the vectors fails both suites.
- **Cache.**
  - On chapter exit, the client posts `POST /reader/panels {source_id, series_key, chapter_key, pages: [{page, panels}]}`, fire and forget and skipped offline, stored per page ETag.
  - Later manifests carry `pages[].panels`. The proxy does no image work.
  - Downloaded chapters store their panels in the local manifest copy.
  - Remove `GET /reader/panels` and `panels_ready` from §9.4.3 and §15.5.
- **Entry.** The `panel-focus` button shows once the current page has panels, from the manifest or from analysis.
- **States:**
  - analysing the current page: the page shows whole with the folio `PAGE 18 · FINDING PANELS`;
  - no panels found, or analysis failed on a page: `PAGE 18 · WHOLE PAGE`, and next moves to the next page;
  - offline: works from the saved copy, analysing local blobs when no panels were stored;
  - reduced motion: cuts instead of dollies (unchanged);
  - drop the "not ready, the backend computes it in the background" state.

### PRODUCT-5 · high · A wrong current password must not sign the user out

- **l.1648 becomes:** "Signed out mid-session (any 401 except `invalid_credentials`)". The global handler ignores 401 `invalid_credentials` and lets the calling form handle it.
- **Change password maps:**
  - `invalid_credentials` → a field error under Current, "That isn't your current password." (`proof`), with focus back in the field;
  - `weak_password` (422) → the server's `message` under New ("Password must be at least 8 characters." or "Password is too long.");
  - `rate_limited` (5/min + 20/h) → a `SLOW DOWN` line with the `Retry-After` countdown, and `Change password` disabled until it reaches 0.

### PRODUCT-6 · medium · Circle must not disclose other profiles' 18+ settings

- **Pass it on for an 18+ series.** Eligible recipients have `Receive recommendations` on **and** their gate open **and** their own `Include 18+ titles in my activity` on, so only profiles that chose to disclose 18+ appear. The caption reads "Only readers who share 18+ titles are listed."
- **`now` on `GET /circle/members` (and `GET /circle/series` readers).** For an 18+ series it is `null` unless the member's Include-18+ switch is on **and** the viewer's gate is open. This is enforced server-side. Add the member's switch to the ring conditions in §7.25 (l.1383) and restate the rule in §9.3.8.

### PRODUCT-7 · medium · Mark read and Mark unread need backend calls that do not touch statistics

- **Mark read (one chapter).** Swipe-left, desktop hover, the long-press menus (l.2409, l.2433) and the Cutting Quick look (l.1047) send `POST /reader/progress/batch` with one row `{source_id, series_key, chapter_key, chapter_number, last_page: max(page_count, 1), page_count: max(page_count, 1), scroll_offset_px: 0, is_completed: true, time_spent_seconds: 0, manual: true}`.
- **Mark read up to here.** It is added to the long-press menu and sends the same rows for every chapter numbered at or below the tapped one that is not completed yet, in chunks of 200.
- **Mark unread (one chapter).** It replaces "Mark unread up to here" and sends `DELETE /reader/progress {source_id, series_key, chapter_keys[] (≤ 200)}`, profile-scoped, 204. Continue-reading then resolves to the furthest remaining row.
- **Library select mode** (l.1856). `Mark read` / `Mark unread` apply the same calls to every chapter in each selected series' `known_chapters` (concurrency 4, as already specified).
- **Backend.** A progress item with `manual: true` is saved without `record_session`, so it writes no `ReadingSession` and does not move statistics or streaks. Add both behaviours to §15.5.
- **Toasts.** "Marked 42 chapters read." with `Undo`, which deletes only the keys that were not completed before. "Marked chapter 142 unread." with `Undo`, which re-posts the deleted rows (the client keeps them until the toast closes).
- **Offline.** All four controls are disabled with the tooltip "Needs a connection."

### PRODUCT-8 · medium · Make re-narration reachable

- **Selection.** In the Audiobook sheet's NARRATE segment, narrated chapters are selectable and captioned `ALREADY NARRATED · WILL BE RE-VOICED` when selected.
- **Quick pick.** Add `RE-VOICE ⁽ⁿ⁾`: narrated chapters whose `rendered_at` is older than the book's `cast_changed_at`. `GET /novels/audio/series` gains `chapters[].rendered_at` and `cast_changed_at`, the latest `POST /novels/cast`, `/novels/cast/alias` or `/novels/narrator` for the book.
- **Submitting.** The sheet sends `force: true` for already-narrated keys and `priority: 0`. The opener's `Narrate this chapter` (l.2366) sends `priority: 9`, because the render queue runs highest priority first (`novel_render_queue.py:188`), so the chapter being read jumps the queue.
- **Owner prompt.** After any cast or narrator change, the cast sheet footer shows the owner a quiet `Re-narrate 38 chapters`, which opens the Audiobook sheet with `RE-VOICE` selected. `RE-VOICING` clears when those renders finish.

### PRODUCT-9 · medium · Picks: branch on `code`, and give source results their own card

- **Branch on `code`, never on status:**
  - `suggest_shelf_empty` (409) → notice `NOTHING TO PICK FROM YET`, "There isn't enough in the catalogue cache yet. Browse a few sources, then ask again." with `Browse sources`, plus a quiet `Ask everywhere instead` that switches the toggle to `FROM EVERYWHERE`;
  - `ai_budget_exhausted` (429) → the Budget exhausted state: the field is disabled and the quota folio reads `0 ASKS LEFT TODAY`;
  - `ai_not_configured` (503) → the not-configured state;
  - `ai_failed` (502) → "The editors couldn't answer that one. Try describing it differently." with `Try again`, and the text is kept;
  - `rate_limited` (429 with `Retry-After`) → `SLOW DOWN` as today.
- **Shelf variant of the World card (§7.6)** for `kind: "source"` items from `/library/suggest`:
  - a full-colour 2:3 poster from the relative `cover_url`, proxied at the snapped width;
  - kicker `{SOURCE NAME} · {chapter_count} CHAPTERS`;
  - byline "by {author}" when present;
  - the `why` as the pull quote.

  The whole card opens `/sources/{source}/series/{series_id}`. It has no rating, no status and no information-only state.

### PRODUCT-10 · medium · Home and Annual need the client's time zone

- `GET /home?content_kind=&tz_offset_minutes=` and `GET /library/annual?year=&tz_offset_minutes=` both require the parameter, range −720..840.
- Web sends `-new Date().getTimezoneOffset()`. Flutter sends `DateTime.now().timeZoneOffset.inMinutes`.
- The `/home` cache key is (profile, content_kind, tz_offset_minutes, local hour).
- The `/home` streak object becomes `{current, at_risk, last_active_date}`.
- On every Tonight visit the client recomputes `at_risk` from `current`, `last_active_date` and the device clock (after 20:00 local, `current ≥ 2`, `last_active_date` before today). The local value overrides the cached flag and swaps the headline and deck to the at-risk lines.

### PRODUCT-11 · medium · Real routes for soundscapes and install-page fonts

- **`GET /app/soundscapes/{id}.{ext}`** (public under `/app/*`):
  - `id` is one of `projector-room, rain-on-glass, night-city, cafe, night-wind, low-drone, afternoon-park, temple-bells`;
  - `ext` is `ogg` or `m4a`;
  - it reads from `backend/media/soundscapes/` (env `MM_SOUNDSCAPES_DIR`) through `FileResponse` (Range supported by Starlette 1.6.0);
  - it sends `Cache-Control: public, max-age=31536000, immutable`;
  - anything else returns 404.
- **`GET /app/fonts/{file}.woff2`** serves an allowlist of the Bodoni Moda and Archivo subsets from `backend/media/fonts/`, with the same caching.
- Replace the "static folder" wording in §8.34, §9.4.2 and §15.5 with these two routes.

### PRODUCT-12 · medium · Heading reveal: one rule for every length, real triggers, real hover, one count

- **No cap.** Delete the §15.6 60-grapheme cap and word fallback. The reveal is per letter at every length: stagger is already capped at 560 ms, and blur layers drop below 0.05 σ.
- **`trigger` prop** on `SetHeading`:
  - `"inView"` for H3s: 50 % in view, seen-set;
  - `"mount"` for mastheads: once per session, seen-set;
  - `"signal"` for cover, feature and takeover titles: no seen-set, starts when `play` turns true.
- **Where `play` comes from.**
  - Web: `animate={play ? "show" : "hidden"}`. `play` turns true 480 ms (the match cut's duration) after the route commits when the navigation carried a match cut, otherwise 160 ms after first paint.
  - Flutter: `SetHeading(trigger: SetTrigger.signal)` listens to `ModalRoute.of(context)!.animation` and plays on `AnimationStatus.completed`, or 160 ms after the first frame when there is no route animation.
- **Flutter hover.** A `MouseRegion` drives one `AnimationController` of `200 + 10 × (n − 1)` ms. Letter `i` lerps `ink.100` → `spot` over `Interval(10i / total, (10i + 200) / total, curve: CineCurves.set)`. On exit, all letters return together over 160 ms. Replace the `AnimatedDefaultTextStyle` sentence in §10.1.4.
- **One count.** Both clients use `n` = graphemes excluding spaces. The web passes `custom={graphemes(text.replaceAll(" ", "")).length}`.

### PRODUCT-13 · medium · Define the novel reading pace

- **Pace.** The median, over this profile's last 10 completed novel chapters, of `word_count / (time_spent_seconds / 60)`. Only chapters with 60 ≤ `time_spent_seconds` ≤ 7200 and a pace of 80–900 wpm count. The pace stays at 250 wpm until 3 samples exist.
- **Storage.** Per profile on the client: web scoped `localStorage` `mm.novel-pace`, Flutter `mm.novel-pace.u{user}p{profile}`. It is recomputed on each chapter completion.
- **Scroll speed.** `px/s = (pace_wpm × speed / 60) × lineHeightPx / avgWordsPerLine`, where `avgWordsPerLine` = the laid-out chapter's word count ÷ its rendered line count. Recompute after any Type sheet change.

### PRODUCT-14 · medium · One request limiter for the sources bucket

- **Placement.** One limiter per client in the shared data layer (`frontend/src/features/sources/`, `mobile/lib/core/network/`), so both skins inherit it.
- **Bucket.** A token bucket of 50 tokens per minute (refill 1 every 1.2 s), burst 8, floor 0.
- **Priorities:**
  - P0: the visible reader page and the next one;
  - P1: user-initiated lists (browse, search, series, chapters);
  - P2: covers in view;
  - P3: prefetch (hover or focus manifests and pages, first rows, the next chapter's manifest, novel chapters, dialogue crops, preview slates).
- **Rules:**
  - P0 and P1 never wait on the local bucket; they only consume from it, because the server enforces the real limit and prefetch is what must yield;
  - P2 waits for a token;
  - P3 runs only while at least 20 tokens remain, with at most 2 requests in flight;
  - hover prefetch starts after a 150 ms dwell, and "first five on load" (l.2387) becomes the first 2;
  - on the web, gated images get their `src` assigned only when a token is granted;
  - responses served from a local cache (HTTP cache, Cache Storage, image cache, sqflite) cost nothing;
  - on any 429, P2 and P3 pause for `Retry-After`, and P0 retries after it.

### PRODUCT-15 · medium (narrowed) · Valid match-cut names and encoded route builders

- **Match-cut name.** `view-transition-name` = `cover-` + the 8-hex-digit 32-bit FNV-1a of `sourceId + "\u0000" + seriesKey`. It is synchronous, about 6 lines in `features/`, and computed once per card. `crypto.subtle` is async and cannot run during render. Flutter `Hero` tags take the tuple itself.
- **Route builders.** `design/build.mjs` emits typed route builders into `contract.generated.ts` and `contract.g.dart` that percent-encode each path segment (`encodeURIComponent` / `Uri.encodeComponent`), because `routes.dart`, which encodes today, is deleted at the flip. Routers decode exactly once.
- **Dropped.** The `series_identity` part: the kept data layer already answers follow state by identity (`followed-index.ts` `followedIdFor`, `series_identity.dart`).

### PRODUCT-16 · medium · Circle failure and offline states

- **Circle offline.** The last cached feed shows read-only with the `OFFLINE EDITION` badge. Letter actions are disabled with the tooltip "Needs a connection." Reactions keep their queued behaviour.
- **Circle error.** `CORRECTION` "The circle didn't load." with `Try again`.
- **Pass it on.**
  - Offline: `Send` is disabled, captioned "Sending needs a connection."
  - Failure: the toast "Couldn't send to Riya. Try again." The sheet stays open and the note is kept.
- **Share sheet failure.** An inline `CORRECTION` "Couldn't update who can see this shelf." with `Try again`.
- **Letter action failure.** The toast "Couldn't update the letter.", and the card restores.
- **Clear dialog.** "Clear everything you've shared? Others stop seeing your past activity. Your library isn't touched." `Clear` is destructive with the 1000 ms arm. Failure toast: "Couldn't clear your activity."
- **Member page offline.** Notice `OFFLINE EDITION`, "The circle needs a connection."

### PRODUCT-17 · medium · "Save image" that works on both phones

- **iOS.** The share sheet's Save Image stays. Add `NSPhotoLibraryAddUsageDescription` ("Save share cards to your photo library.") to `ios/Runner/Info.plist`, which today has only `NSPhotoLibraryUsageDescription`.
- **Android, API 29 and up.** A native `MethodChannel("mm/media_store")` in `MainActivity.kt` (about 30 lines) inserts the PNG through `MediaStore.Images.Media.EXTERNAL_CONTENT_URI` with `RELATIVE_PATH = "Pictures/ManhwaManiacs"`. It needs no permission and no plugin. Toast: "Card saved to Pictures/ManhwaManiacs."
- **Android, API 24–28.** Fall back to the share sheet with the toast "Pick an app to save the card."

### PRODUCT-18 · low · Record listening so the colophon can credit voices

- **New endpoint.** `POST /novels/listen-sessions` takes an array (≤ 200) of `{source_id, series_key, chapter_key, seconds, voice_ids[≤ 3], started_at}`.
- **Clients.** They batch on pause, at chapter end and when the app goes to the background, only when `seconds ≥ 10`, and queue offline in the progress outbox.
- **Annual.** `GET /library/annual` returns `top_voices: [{voice_id, name, seconds}]` for the colophon's `NARRATED BY` line (still omitted when empty).

### PRODUCT-19 · low · An end state for a finished series

When the series `status` is Completed (case-insensitive) and its last chapter completes:

- the manga credits' caught-up notice becomes kicker `THE END`, headline "You finished {title}.", deck "{n} chapters, {h} hours." (hours from the feature page's `YOUR TIME HERE` source);
- an `Up next` rail follows: Similar (§9.1.4), else Because you read, else From your shelf;
- a quiet `Mark as completed` sends `PATCH /library/series/{id} {reading_status: "completed"}` and is hidden when the status is already completed;
- the `Notify me` switch and "You'll get a notice…" deck are not shown for a Completed series.

The novel end matter gets the same block in stock colours. Tonight's `continue` never lists a finished Completed series.

### PRODUCT-20 · low · One AI state-copy table keyed by `code` / `reason`

§9.1.8's unavailable row becomes a table referenced from §7.8, §9.1.3 and §9.1.6. The surfaces drop their own copies and may only append their non-AI path (§7.8 appends "Here is your shelf instead.").

| Key | Copy |
|---|---|
| `budget_exhausted` / `ai_budget_exhausted` | "The picks desk is closed tonight. Asks reset at midnight UTC." |
| `not_configured` / `ai_not_configured` | "The editors' desk isn't set up on this server." |
| `rate_limited` | `SLOW DOWN`: "Too many asks at once. Try again in {n} s.", with the live `Retry-After` countdown |
| `ai_failed` | "The editors couldn't answer that one. Try describing it differently." |

### PRODUCT-21 · low · Caret blink that matches `dur.caret`

The sixth half ends off, so the specified 160 ms "fade" fades from 0 on both clients. Drop it:

- §10.2.1: "…blinks 530 ms on / 530 ms off three times (3180 ms) and is then gone".
- Web: `caret-out` becomes a 3180 ms `steps(1)` keyframe of six 530 ms halves.
- Flutter: `AnimationController(duration: 3180.ms)` with `final ms = v * 3180; final o = (ms ~/ 530).isEven ? 1.0 : 0.0;` (530 = `dur.caret`).

### PRODUCT-22 · low · At-risk headline within 60 graphemes

When the spelled at-risk line exceeds 60 graphemes (every count ≥ 101 that is spelled with "and"), Tonight's headline becomes "Your {n}-day streak ends at midnight.". The count no longer opens the sentence, so it is a numeral under §12.5 ("Your 123-day streak ends at midnight.", 37 graphemes). The deck is unchanged.

### PRODUCT-23 · low · The streak counts any reading, not a finished chapter

- **Rule.** "Read today" means `streak.last_active_date == local today`, from statistics or `/home` called with `tz_offset_minutes`.
- **Ignite.** The flame ignites when a refetch after leaving a reader shows `last_active_date` flip to today. This replaces "first completed chapter of the day" (l.3004).
- **Copy.** At-risk deck: "Open any chapter before midnight to keep your streak." Tonight's at-risk condition (l.1822): "nothing read today". The not-yet-today caption is unchanged ("Read today to keep your 12-day streak.").

### PRODUCT-24 · low (narrowed) · The Annual is a calendar year

- Delete the "Rolling windows" paragraph (l.3042). The Annual covers 1 January to 31 December in the profile's local time (via `tz_offset_minutes`).
- The current year's cover reads "Your year so far" until 31 December.
- The banner thresholds in l.2963 stay as written.

### PRODUCT-25 · low · Novel reader parity for cross-device progress and stale copies

- **Toast.** When a novel progress save returns `advanced: false`, show the toast in stock colours "You're further ahead on another device (CH 214, 38%). Jump there?" with `Jump`.
- **Badge.** When the chapter's `cache.stale` is true, show a `SAVED COPY · 3 H` micro badge in the running head (1 px stock-muted outline, stock-muted text), with the tooltip "The source is down; this is the last copy we saved."
- Add both to §8.15.9.

### PRODUCT-26 · low · Mobile backup export and a failed nightly

- **Mobile download.** The app downloads with its own `dio` client (Bearer), `dio.download` streaming to a temp file `manhwamaniacs-backup-{yyyyMMdd-HHmm}.db`, with a determinate rule showing bytes. It then opens the share sheet (`share_plus` 13.3.0, already in §15.11) so the file can be saved (Save to Files on iOS). Error toast: "Couldn't download the backup."
- **Failed nightly.** `nightly.ok == false` renders `LAST NIGHTLY · FAILED AT {PHASE} · 28 SEP 03:00` in `proof`.

### PRODUCT-27 · low · `splash.reveal` is a haptic event too

- Add `splash.reveal` to the §5 event table: iOS `impress`, Android `impress`, web —, fired at t = 1180 ms of the logo reveal, cold start only.
- §12.4 l.3570 says "haptic `splash.reveal`".
- Remove "sound-only" from its §6 rows (l.891, l.912) and from S8 in §15.10.

### PRODUCT-28 · low · Android exports land where the user can find them

- **Android, API 29 and up.** Save to Files writes through MediaStore `Downloads` with `RELATIVE_PATH = "Download/ManhwaManiacs/Exports/{series}/"`. It needs no permission and uses the same `mm/media_store` channel as PRODUCT-17, with a second method, `saveDownload(relativePath, name, mime, path)`. The result dialog's path reads "Files › Downloads › ManhwaManiacs › Exports › {series}".
- **Android, API 24–28.** Keep the app-documents export and offer `Share` (`share_plus`) on the result dialog.
- The STORAGE tab needs no folder picker.
