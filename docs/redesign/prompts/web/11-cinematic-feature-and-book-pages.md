# Web 11: Cinematic Feature page, Book page and chapter downloads

## Goal

Build the Cinematic series pages on the web client (`frontend/`), per `docs/redesign/cinematic/DESIGN.md` §8.17, §8.18 and §8.19: the manga **Feature** page (the spread with the series' issue colour, credits enriched through `GET /series/enrichment`, follow, favourite, notify, the rating card, the `mature_override` radio menu, Mark read / Mark read up to here / Mark unread, Move to another source through repoint, the contents tabs, the At a glance aside and the Lightbox), the novel **Book** page (typographic front matter and the windowed contents), and **chapter selection and downloads** on both (picker, quick ranges, per-chapter download marks, the series download card), with the match cut in and out, one series page for both the source route `/sources/:sourceId/series/:seriesKey` and the follow route `/library/:followedId`, the "no longer available" notice, keys `1`–`n` for the tabs, and every state, for desktop web and mobile web. The `03 MORE LIKE THIS` tab, every `Previously on…` entry point and More like this in menus are added by web/19; the `04 CIRCLE` tab, `Recommend to…` and "In the circle" are added by web/22; the Audiobook button is added by web/15. When you finish, `feature` leaves the Cinematic `PENDING` set. `docs/redesign/prompts/mobile/11-cinematic-feature-and-book-pages.md` runs the same cluster on Flutter in parallel; do not touch `mobile/`.

## Read first

DESIGN.md is binding; conflicts are reported and DESIGN.md wins.

- `docs/redesign/cinematic/DESIGN.md`:
  - §2.1.1, §2.1.3 (health marks), §2.1.4 (scrims; the over-art rule), §2.1.5 (ambient `duo`, `tint`, `ink`; the duotone matrix; animating colour), §2.2, §2.4 (the art light), §2.5 (`blur.bleed` 56 px), §2.7 (icons, including `strip-scroll` and `certificate-18`), §2.8, §3.2 (long titles step down a role), §3.5 (`type.dropcap`).
  - §4 (match cut 480 / 336 ms, Set, Rule draw, Letter set, Dissolve, Drift, Column wipe, Lightbox, Arm; reduced motion §4.8), §5, §6.
  - §7 intro and the semantics table, §7.1, §7.2, §7.3, §7.4 `compact`, §7.5 (slug lines, segmented control), §7.6 (Stat block), §7.7, §7.9 (sheets; column panels), §7.10 (arm delay), §7.11, §7.12, §7.16 (chapter "schedule" rows, contents rows, credits rows, swipe slabs), §7.17, §7.18 (download marks, rules, leader dial), §7.19, §7.21, §7.22, §7.23, §7.24 (rating card, `mature_override`, local copies), §7.26, §7.28 (`Spread`, `Credits`), §7.29 (select-mode bar, spoken folios), §7.30 (Lightbox).
  - §8.0.2–§8.0.5 (one series page per series; match-cut routes; the Column wipe entries), §8.0.8, §8.0.9 (feature and book tablet rows), §8.0.10, §8.14.2 (the Column wipe entry and prefetch-on-press).
  - **§8.17, §8.18 and §8.19, entire.**
  - §9.1.8 (the AI state vocabulary, for the suggested tags line), §10.1 (`trigger="signal"`), §11 (feature, book, chapter-row and Lightbox rows), §13 moment 20, §14, §15.5 (the backend rows this page reads), §15.6 (the sources limiter and prefetch), §15.7.
- `docs/redesign/inventory/web.md` §7.3 (SD1–SD21), §8.3 (SS1–SS18), §10.2 (NB1–NB19), §12.2 (DP1–DP7), §18.4, §18.8, §19.3 (K45 chapter sort).
- `docs/redesign/inventory/capabilities.md` §7, §13, §16.3, §20, §24.
- `docs/redesign/inventory/00-decisions.md`, `docs/redesign/stack-decision.md` §2.2 and §2.6, `docs/redesign/00-baseline.md`.

## Before you start

1. Work in `/srv/manhwamaniacs/dev/ManhwaManiacs` on branch `feat/vps-slim-source-native`; `git status --porcelain` and note other sessions' modified files (never stage them).
2. Dependencies: `docs/redesign/prompts/web/10-cinematic-updates-collections-history-bookmarks.md` and `docs/redesign/prompts/backend/02-library-series-ocr-extensions.md`. Check: `updates` is out of `PENDING` in `frontend/src/skins/cinematic/index.ts`; `ls frontend/src/skins/cinematic/screens/feature/FeatureView.tsx frontend/src/skins/cinematic/parts/TagSheet.tsx frontend/src/features/library/mark-read.ts` (web/09); `grep -n "repoint\|enrichment" backend/routes/*.py` finds `POST /library/series/{followed_id}/repoint` and `GET /series/enrichment`; `grep -n "def .*progress" backend/routes/reader.py` shows the `DELETE /reader/progress` route. If a check fails, stop and report it.
3. Inventory and reuse (never re-implement a primitive inside a screen): `ls frontend/src/skins/cinematic/primitives frontend/src/skins/cinematic/parts`; `grep -n "^export" frontend/src/features/sources/hooks.ts frontend/src/features/sources/series-progress.ts frontend/src/features/sources/chapter-label.ts frontend/src/features/sources/chapter-date.ts frontend/src/features/reader/hooks.ts frontend/src/features/offline/use-chapter-picker.ts frontend/src/features/offline/use-series-downloads.ts frontend/src/features/offline/download-queue.ts frontend/src/features/novels/book.ts frontend/src/features/novels/hooks.ts frontend/src/features/library/followed-index.ts frontend/src/features/ocr/api.ts`. The data layer you will use: `useSourceSeriesDetail`, `useSourceChapters`, `resolveChapterListState`, `useSeriesProgress`, `resolveSeriesProgress`, `prefetchChapterManifest`, `useFollowedIndex` / `followedIdFor`, `useSeries`, `useFollow`, `useUnfollow`, `usePatchSeries`, `useToggleFavorite`, `useChapterPicker` (`NEXT_BATCH_SIZE = 10`), `useSeriesDownloads`, `describeRun`, `nextChapters` / `unreadChapters` / `everyChapter`, `useIsNovelSource`, `estimateSeriesLength`, `formatEstimatedWords`, `formatEstimatedTotal`, `goToChapterMatches`, `tocWindowAround`, `extendTocWindow`, `splitDropCap`, `prefetchNovelChapterWindow`, the tag hooks from `features/library/tags.ts` and `markChaptersRead` / `markChaptersUnread` from `features/library/mark-read.ts` (web/09), `sendAiFeedback` from `features/ai/feedback.ts` (web/08), the §15.6 sources limiter in `features/sources/`. Reuse `parts/AddToShelfSheet.tsx`, `parts/TagSheet.tsx`, `parts/SourcePickerSheet.tsx` and the reader-entry helper (Column wipe / Dip) from earlier steps. If a primitive lacks a variant, add it to the primitive file and the gallery under `frontend/src/app/(preview)/`.
4. Record the Vitest baseline (RAM guard below): `cd frontend && npm run test 2>&1 | tail -5`.

## Skills to invoke

1. `superpowers:writing-plans` before any code; save as `docs/redesign/proof/web-11/plan.md`.
2. `superpowers:subagent-driven-development` (or `superpowers:executing-plans`). Scope-lock subagent prompts to named files; verify with `git status` and `git diff`, never with an agent's report.
3. `frontend-design:frontend-design`, `impeccable:impeccable`, `taste-skill:taste-skill` for design review against DESIGN.md (they never change fixed values or copy).
4. `superpowers:verification-before-completion` before claiming done.

## Scope

Cinematic only (Glass's series pages are web/33). Section numbers refer to `docs/redesign/cinematic/DESIGN.md`.

### A. Backend exception: clearing `mature_override`

"Use the source's rating" (§7.24, §8.17 overflow) needs `PATCH /library/series/{id} {"mature_override": null}` to clear the override, and today the service ignores `null` (`if "mature_override" in changes and changes["mature_override"] is not None` in `backend/services/followed_series_service.py`). No backend step owns this.

- First check whether it was already fixed (by mobile/11 or a backend session): `grep -n "mature_override" backend/services/followed_series_service.py`. If the patch path already assigns `None` for an explicit null, skip this section.
- If `git status --porcelain -- backend/` shows uncommitted changes you did not make, another session is editing the backend: do not touch it; build the radio menu as specified and list "mature_override null does not clear" under open issues.
- Otherwise, in one backend commit staged by explicit path: when `"mature_override"` is present in the patch, set `row.mature_override = None if value is None else bool(value)` (the route already uses `model_dump(exclude_unset=True)`, so an absent key stays untouched), re-stamp nothing else; add a test to `backend/tests/test_library_endpoints.py` (true, false, then null clears it, and an absent key leaves it); run `cd backend && .venv/bin/python -m pytest -q --no-header` (RAM guard first). Never edit `backend/connectors/`.

### B. Shared data layer additions (skin-neutral, `frontend/src/features/`)

No JSX, no import from `src/skins/**`, a Vitest `*.test.ts` beside each logic file.

1. `features/sources/enrichment.ts`: `useSeriesEnrichment(sourceId, seriesKey)` → `GET /series/enrichment?source=&series=` → `{anilist_id, format, score, official: [{site, url}]} | null` (`staleTime` 1 hour).
2. `features/ai/tags.ts`: `useSuggestedTags(sourceId, seriesKey)` → `GET /ai/tags?source=&series=` → `{tags, available, reason}`; any failure (including a 404 before backend/05 exists) resolves to `{tags: [], available: false}` so the line is simply absent; `rejectSuggestedTag(ref, tag)` = `sendAiFeedback({signal: "tag_rejected", source_id, series_key, tag})`.
3. `features/ocr/coverage.ts`: `useOcrCoverage(sourceId, seriesKey)` → `GET /ocr/coverage?source=&series=` (use `ocrApi` if it already has the call; otherwise add it there).
4. `features/library/repoint.ts`: `useRepoint(followedId)` → `POST /library/series/{followedId}/repoint {source_id, series_key, keep_old}` → `{followed, mapped_chapter_key, mapped_chapter_number | null}`; `mappingSentence({ currentNumber, candidateRange, sourceName })` → the §8.17 step-2 sentence ("Your place moves by chapter number. You're on chapter 142; Asura has chapters 1–150, so chapter 142 there becomes your place." or "Chapter numbers don't line up, so you'll start at chapter 1 on Asura."). Test for both sentences and the out-of-range case.
5. `features/library/series-time.ts`: `timeHere(progressRows)` → the sum of `time_spent_seconds`, formatted `11 H 20 M` (`45 M` under an hour; `—` for none). Test included.
6. `features/library/mark-read.ts` (extend web/09's file): `chaptersUpTo(chapters, chapterNumber)` → every chapter numbered at or below the tapped one that is not completed yet (nulls excluded), and `undoMarkRead(previouslyCompleted, marked)` → the keys the Undo deletes (only those not completed before). Tests added.
7. `features/offline/download-mark.ts`: `downloadMarkState(entry)` → `none | queued | downloading(progress) | saved | failed | paused | stale`, and `downloadMarkLabel(state)` with the DP7 wording and the §7 semantics names ("Saved", "Queued", "Downloading, 30 percent", "Failed, tap to retry"). Test included.

### C. The series page shell: `FeatureScreen` and `FeatureView`

1. `frontend/src/skins/cinematic/screens/feature/FeatureScreen.tsx` (ScreenId `feature`, `/sources/:sourceId/series/:seriesKey`): decodes the params once, finds the follow row with `followedIdFor()` (by `series_identity`), and renders `<FeatureView sourceId seriesKey followedId />`. Wire `screens.feature` and remove `feature` from `PENDING`. `featureByFollow` (web/09) already renders the same `FeatureView` in place, so there is exactly one series page for both routes.
2. `frontend/src/skins/cinematic/screens/feature/FeatureView.tsx` (replace web/09's pending body, keep the props): chooses the manga **Feature** (D) or the novel **Book** (E) by `useIsNovelSource(sourceId)` (the source's `content_kind`); while that is `undefined` it shows the Feature galley. `document.title` is "{Title} · ManhwaManiacs".
3. Shared behaviour for both renderings:
   - **Match cut in** from any poster, cutting, plate or cover (`<ViewTransition name={coverTransitionName(sourceId, seriesKey)} share="mm-match-cut">` on the page's cover, 480 ms `ease.turn`, everything else dissolving over 240 ms); **Page** in (x +24 px → 0 and fade, 320 ms `ease.settle`) from lists without a cover; **reverse match cut** on back (336 ms `dur.match.back` `ease.turn`) into the originating poster when it is still in the tree, otherwise Page out (224 ms `ease.lift`).
   - The title is a `SetHeading` with `trigger="signal"` and `as="h1"`: it plays 480 ms after the route commits when the navigation carried a match cut, otherwise 160 ms after first paint (`useTitleSignal`); it never reads or writes the seen set. Long titles step down one role past 24 graphemes and two past 40 (§3.1).
   - The **ambient wash** (the signature moment): the spread element holds `--amb-duo`, `--amb-tint`, `--amb-ink` (registered `@property` colours), starting from `#B8B2A4` / `#0E0D0B` / `#F3F0E8` and dissolving to the series' `ambient` over 800 ms `ease.turn`; the 30 vh under the spread fades from `ambient.tint` to `#000000` (the page spill). The kicker and the chapter folios on this page use the series' issue colour `ambient.ink`; interactive marks (tabs, progress, focus) stay `spot`.
   - The **rating card** (§7.24) appears on open for a series whose resolved `rating` is `mature` (after `mature_override`): the 20 px certificate + `18+` in `type.kicker` + descriptors from genres in `type.caption` `ink.60` ("Violence · Sexual content") inside a `paper.0` box with 8 × 12 px padding, top-left under the running head; in 480 ms `ease.settle`, held 3000 ms, out 240 ms `ease.lift`; informational only. Use the host web/07 built.
   - The **Lightbox** (§7.30) on the cover: long-press 450 ms on phones, double-click on desktop, the key `v`, and the overflow `View cover`; the match cut from the cover's frame to a contain fit on `rgba(0,0,0,0.96)` in 480 ms `ease.turn`; haptic `longpress.open`.
   - The **no longer available** notice (§8.0.10) replaces the page for `series_not_found`, `source_not_found` or a gate-hidden series (the server answers these alike): kicker `NOT IN THIS ISSUE`, typed `h1` "This series isn't available here any more.", deck "It may have been removed from its source.", primary `Back to Tonight`, quiet `Search for it` (Discover with the title prefilled when it is known). The wording never reveals 18+.
   - **Out**: `Read`, `Continue`, `Read all`, `Listen` and every chapter or contents row enter the reader by the **Column wipe** (§8.14.2: 12 blades on desktop, 376 + 40 + 456 = 872 ms; 8 at 768–1023 px, 744 ms; 4 on phones, 616 ms; blades close top-down `ease.settle` 200 ms each, 16 ms stagger, hold 40 ms on black, open bottom-down 280 ms each; reduced motion: a 200 ms cross-fade through black) through the reader-entry helper; the chapter manifest and first two pages are prefetched on a 150 ms hover or focus dwell (P3) and on press.

### D. The manga Feature page (§8.17)

Data: `useSourceSeriesDetail`, `useSourceChapters`, `useSeriesProgress` merged by `resolveSeriesProgress`, the follow row through `useSeries(followedId)` when followed (favourite, reading status, notify, `mature_override`, `rating`, tags), the source list for the health mark, `ambient` from the series payload.

1. **Desktop spread** (`Spread` primitive, height `clamp(520px, 64vh, 760px)`):
   - Columns 1–5: kicker in `ambient.ink` (`MANHWA · ONGOING · 201 CHAPTERS`, `type.kicker`); the title in `type.headline` (Bodoni Moda Roman opsz 72 wght 700, fluid `clamp(2rem, 1.39rem + 2.61vw, 4rem)`, tracking −0.030em) with the letter reveal; the deck = the synopsis's first sentence in `type.deck` italic (`ink.60`, max 62ch); **credits** (§7.28: `STORY` author, `ART` artist, `SOURCE` name with its 6 × 6 px health mark and label, `STATUS`, `UPDATED 2 D AGO` from the newest chapter's release date, and the 20 px rating certificate when the series is mature and the gate is open), appearing in reading order (Set: 320 ms `ease.settle`, 24 ms per row, cap 360 ms) after the title lands.
   - Actions row: `split` primary lg (56 px): `Read │ CH 1` (nothing started), `Continue │ CH 143 · p.12` (resume point), or the disabled `All caught up` (a disabled primary with a `check` glyph; `paper.3` fill, `ink.30` text); `secondary` `Read all` with the `strip-scroll` glyph (manga with more than 1 chapter; tooltip "Every chapter in one continuous scroll"; `/read-all/:sourceId/:seriesKey?from=`); then `bare` icon buttons (24 Light, 44 px hit, tooltips with keycaps): **Follow** (`plus` → `check` with the label "Following" in its tooltip; `POST /library/follow` / `DELETE /library/follow/{id}`; haptic `follow.add` (Android Chrome `[12]`), sound `impress`; toast "Following {title}. New chapters will notify you."; unfollow commits at once with "Removed {title}." + `Undo` 8000 ms), **Favourite** (`star`, followed only; selected: Fill + 2 px `spot` rule under the square; haptic `favorite`), **Notify** (`bell-ringing`, only when followed; `PATCH {notify}`), **Download** (opens §F select mode), and the overflow `dots-three`.
   - Columns 6–12: the cover at the full spread height against the right edge (proxy width 720, never upscaled), the `blur.bleed` duotone fill to its left (duotoned to `ambient.duo`, `color-interpolation-filters="sRGB"`), `scrim.gutter` over columns 6–7, grain 0.06 (overlay, art only), **Drift** (26 s, scale 1.00 → 1.06, translate −1 %, −1.5 %, `ease.drift`, paused off screen), and the reading progress rule (2 px `spot`) along the bottom of the art.
   - Page spill: the 30 vh under the spread fades from `ambient.tint` to `#000`.
2. **Contents tabs** (§7.12, sticky under the running head at `z.sticky`, 48 px, 1 px `rule.1` under the row): this step renders `01 CHAPTERS²⁰¹ · 02 DETAILS`. The tab list is data-driven (an ordered array of `{id, folio, label, count?, panel}`), so web/19 appends `03 MORE LIKE THIS` and web/22 appends `04 CIRCLE` without renumbering; the keys `1`–`n` and `[` `]` follow the array. Phones: panels swipe (a scroll-snap pager like web/09's hub pager, the tab rule following the finger); `touch-action: pan-y` on chapter rows keeps their swipe actions.
3. **CHAPTERS** (columns 1–8) + **At a glance** aside (columns 9–12) from 1024 px, the aside `position: sticky; top: calc(56px + 48px + 16px)`; below 1024 px At a glance moves to the top of DETAILS (§8.0.9).
   - Toolbar: `NEWEST │ OLDEST` segmented control (40 px, `rule.2` frame, sliding `spot` underline 320 ms), persisted per series in the existing scoped key `mm.chapter-sort:{source}:{series}` (K45); a `compact` go-to field ("Chapter number", `inputMode="decimal"`; `Enter` jumps to the first match and centres it with the `spot.wash` band fading in over 240 ms; "Type a chapter number." / "No chapter 212 in this series." captions); `Select` (quiet); the download summary `12 OF 201 SAVED` + `Download` (secondary sm, 32 px visual).
   - **Schedule rows** (§7.16 chapter row, 56 px): the chapter number in `type.folio.lg` right-aligned in a 56 px column (`·` when the number is null, decimals printed as-is) in the issue colour `ambient.ink`; the title (`type.title`, de-duplicated so "Chapter 12" is not repeated when the source title repeats the number) with the caption (release date `TODAY`, `YESTERDAY`, `3 D AGO`, `12 SEP 2026`; page count `27 PAGES`); progress `14/27` in `spot` Plex Mono when in progress, `READ` micro in `ink.45` when complete (the row text dims to `ink.45`), nothing when unread; the download mark (§7.18, G). The current chapter has the `spot.wash` band behind it and a `READING` badge. States: hover a 2 px `ink.100` bar on the left edge and text `ink.100` (120 ms); pressed `paper.3`; focus ring inset 2 px; selected (select mode) `paper.3` + 2 px `spot` left bar and a leading 20 px checkbox; disabled `ink.30`; loading greeked rows; row error (a failed download) the caption in `proof` with a trailing `quiet` `Retry`.
   - Rows prefetch the chapter manifest after a 150 ms hover or focus dwell (and the first 2 rows on load) as P3 requests of the sources limiter (§15.6: P3 runs only while at least 20 of the 50 slots are free, at most 2 in flight). The list is windowed with `@tanstack/react-virtual` `useWindowVirtualizer` when it holds more than 60 rows (overscan 8).
   - Row interactions: tap or click opens the reader at that chapter (Column wipe). Desktop hover reveals row actions at the right end (download `cloud-arrow-down`, mark read `check`, as `bare` icon buttons 32 px hit on the fine pointer). Right-click on desktop, long-press 450 ms on phones, and a trailing `dots-three` (the non-gesture path) open the row menu: `Mark read`, `Mark read up to here`, `Mark unread`, `Download`, `Bookmark start` (a bookmark at page 1 of that chapter through the existing bookmarks API; haptic `bookmark.add`). Phones: swipe a row left to `Mark read` (a 72 px `ink.100` slab with a `#000` label; release past 50 % commits with `spring.release` 420 ms bounce 0; the row springs back and dims).
   - **Mark read and Mark unread** (§8.17 calls through `features/library/mark-read.ts`): one chapter → one `manual: true` row `{source_id, series_key, chapter_key, chapter_number, last_page: max(page_count, 1), page_count: max(page_count, 1), scroll_offset_px: 0, is_completed: true, time_spent_seconds: 0, manual: true}` via `POST /reader/progress/batch`; up to here → the same rows for every chapter at or below it that is not completed, in chunks of 200; Mark unread → `DELETE /reader/progress {source_id, series_key, chapter_keys}` (≤ 200). Toasts "Marked 42 chapters read." with `Undo` (deletes only the keys that were not completed before) and "Marked chapter 142 unread." with `Undo` (re-posts the deleted rows, kept until the toast closes); haptic `select`. `manual` rows never move statistics or streaks. Offline: every mark control is disabled with the tooltip "Needs a connection."
   - The **series download card** (F4) sits between the toolbar and the rows when anything is saved or queued.
   - **At a glance** aside: a Stat block (§7.6: 3 px `rule.heavy`, kicker `CHAPTERS READ`, the numeral `142 / 201` in `type.headline` with lining tabular figures, since `type.numeral` does not fit four columns); the reading status as a single-select slug line `READING · PLAN TO READ · ON HOLD · DONE · DROPPED · NOT STARTED` (followed only; `PATCH {reading_status}`; haptic `select`); the credit `YOUR TIME HERE 11 H 20 M` (`timeHere()` over the progress rows); **tags**: own tags as removable tokens (`x` removes through `useUntagSeries()`) + a `quiet` `Add tag` opening a menu of the profile's tags (checked when applied) with a footer `New tag…` that opens `parts/TagSheet.tsx`; when `useSuggestedTags()` answers `available` with tags, a `SUGGESTED` kicker line follows with up to 5 dashed-outline tokens (1 px dashed `rule.2`, `type.micro`), each with `+` to accept (it becomes an own tag, haptic `select`) and `x` to reject (`rejectSuggestedTag()`); the line is absent when the desk is closed or nothing is suggested (§9.1.8: never an error); **shelves** containing the series as links (`/library/collections/:id`) + `quiet` `Add to shelf` (`parts/AddToShelfSheet.tsx`); **OCR coverage** "Dialogue indexed for 34 of 201 chapters" with a 2 px determinate rule (`spot` on `rule.1`).
4. **DETAILS**: the full synopsis in `type.body` at 17/28 on desktop, max 62ch, opening with a Bodoni drop cap (`type.dropcap`: Bodoni Moda Roman wght 800 at 3 × the line height, 84 px on 28 px leading, opsz = min(size, 96), tracking −0.02em, `float: left; initial-letter: 3` where supported; use `splitDropCap()`; no drop cap under 80 characters); alternate titles when the payload carries them (CJK in the Noto Serif fallbacks, no italic, wght 700 one size down); genres as a slug line of links (each opens the source catalogue filtered to that genre, `/sources/{sourceId}?genre={genre}`); enriched credits from `useSeriesEnrichment()` (`FORMAT`, `ANILIST ★ 8.4`, and official platforms as `Read on {site} ↗` links in `link` style), simply absent while loading or when the answer is `null`; the source credit (`SOURCE` with its health mark) and `Open on {source}` when the payload carries the series URL. Below 1024 px At a glance opens this panel.
5. **Overflow menu** (§7.22: `paper.2`, 1 px `rule.2`, min width 224, items 40 px (48 on phones), clip reveal 200 ms `dur.clip` `ease.settle`, exit fade 120 ms; arrows, `Home`/`End`, type-ahead): `View cover`, `Add to shelf`, `Set reading status ▸` (radio submenu; followed only), `Tags…` (the tag sheet scoped to this series, with a `Manage` link to the full tag sheet), a radio group `Treat as 18+` / `Treat as not 18+` / `Use the source's rating` (followed only; `PATCH {mature_override: true | false | null}`; toast "Treating {title} as 18+." / "…as not 18+." / "Using the source's rating."; on a change, every locally stored row of the series is re-stamped through web/07's mature filter and gated queries are invalidated), `Check for new chapters` (followed only; `POST /updates/followed/{id}/check`; toast "Checking {title}."), `Open the source's page ↗` (only when the series URL is present), `Find it on another source` (Discover with the title prefilled), `Move to another source…` (followed only; D6), `Share link` (copies the absolute URL of this page from the typed route builder; toast "Link copied."), `Unfollow` (`proof`; followed only).
6. **Move to another source** (the repoint flow; `m` opens it; shown first under a `NOTE` banner strip "This source is down. Move the series to another source to keep reading." when the source's health is `dead`). A sheet on phones, a column panel on desktop (4 columns, min 400 px, from the right, `Esc` closes), kicker `MOVE TO ANOTHER SOURCE`:
   1. *Candidates*: the title searched across every other visible source (the federated search hook, tier order, the Discover status line per source); each candidate row: the source logo 24, the source's title, `CHAPTERS 150 · LATEST 3 D AGO`, the health mark, the 40 × 60 cover. States: searching (3 greeked rows), none ("No other source has this series."), a source that didn't answer (a `CORRECTION` caption with `Retry` for that source).
   2. *Mapping*: after a candidate is picked, `mappingSentence()`; a checkbox "Keep following it on {old source} too" (off); actions `Move` (primary) and `Back` (quiet).
   3. *Moving*: `Move` shows its loading state; `useRepoint()`; done → the page match-cuts to the new source's feature page and a toast says "Moved to Asura. You're on chapter 142."; error → "Couldn't move this series." + `Try again`; offline → the menu item is disabled with the tooltip "Moving needs a connection."
7. **Phone layout** (below 768 px): no thumb index on this screen; the running head is transparent with back and the overflow (`on-art` icon buttons over the art); the cover full-bleed 4:5 with `scrim.foot` into `ambient.tint` (solid 24 px above the title block's first line box), Drift; the title block overlaps its lower quarter (kicker, `type.headline` 32/36, deck 2 lines); then the actions: the `split` primary full width (48 px), `Read all` (secondary, full width in this step; web/19 puts `Previously on` beside it), then a row of icon buttons with labels under them `FOLLOW · FAVOURITE · NOTIFY · DOWNLOAD` (labels in `type.nav` `wdth` 62, capped at text scale 1.3 with `maxLines` 1 and a shrink-to-fit guard never below 10 px; `SEND` is added by web/22); the credits in a single column; then the contents tabs, sticky under the running head; At a glance at the top of DETAILS.
8. **Tablet** (768–1023 px): the desktop spread on 8 columns (text 4, art 4); tabs below; At a glance at the top of DETAILS.
9. **Platform deltas**: mobile web long-press on chapter rows opens the row menu (the phone frame calls `preventDefault()` on `contextmenu` for those rows and sets `-webkit-touch-callout: none` on the cover); desktop hover reveals row actions.
10. **Keys (web)** (group "Series"; single-key setting respected; never while typing): `Enter` or `c` continue (Column wipe); `a` read all; `v` view cover; `f` favourite; `n` notify; `+` follow / unfollow toggle (asks nothing; toast with Undo); `d` download (select mode); `1`–`n` tabs and `[` `]`; `j`/`k` chapters; `x` select mode; `/` the go-to field; `o` newest/oldest; `m` move to another source. All appear in the `?` sheet.
11. **States**: loading (the galley spread: title bars at `type.headline` height, credit lines, the cover plate flickering; 8 greeked chapter rows); chapters offline ("The chapter list needs a connection."); chapters unavailable ("MangaDex lists 201 chapters but returned none just now — usually the source, not you." + `Try again`); no chapters ("No chapters yet. The source hasn't published any." + `Back to the source`); series error (kicker `CORRECTION`, typed headline "Couldn't load this series.", deck "The source did not answer.", `Try again` + quiet `Back to the source`); offline with saved chapters (the page renders from the local store under the `OFFLINE EDITION` badge; only saved chapters are enabled; every mark and follow control is disabled with "Needs a connection."); follow limit reached (`follow_limit_reached`: an error line under the Follow button "You're following 1,000 series, the limit for a profile."); stale catalogue (the `SAVED COPY · 3 H` badge beside the kicker when the payload's `cache.stale` is true); not available (the §8.0.10 notice). Every notice headline types at 50 ms per character.

### E. The novel Book page (§8.18)

The book is typographic: no spread art.

1. **Desktop front matter**:
   - Columns 1–7: kicker `NOVEL · ONGOING · NOVELARCHIVE` (in `ambient.ink`); the title in Bodoni Moda Roman `type.masthead` (`SetHeading` `trigger="signal"` `as="h1"`); the byline "by {author}" in Newsreader Italic 22; a 56 px wide, 1 px `ink.100` rule that draws after the byline (Rule draw 480 ms `ease.settle`); facts as credits `CHAPTERS 1,204 · ≈ 2.1M WORDS · ≈ 140 H · ONGOING` (`estimateSeriesLength()`, `formatEstimatedWords()`, `formatEstimatedTotal()`); the estimate note "Length estimated from 12 chapters read so far." (`type.caption`); the blurb in `type.body` 17/28 with a Bodoni drop cap, max 62ch, setting last (the signature moment: title letters, byline, the rule drawing, then the drop cap); genres as a slug line of links (`/sources/{sourceId}?genre=`).
   - Actions: `split` primary `Start reading │ CH 1` / `Continue │ CH 212 · 42%` / the disabled `All caught up`; `secondary` `Listen` when narrated chapters exist (from `GET /novels/audio/series?source=&series=`; add `useSeriesAudio()` to `features/novels/` if it is missing; it opens the novel reader at the resume point with `?listen=1`, Column wipe); `bare` icon buttons: **Add to library** (`plus` / `check` with the tooltip "In your library"; toast "Added {title}. New chapters will notify you."; removing: "Removed {title}." + `Undo`), **Download book** (`cloud-arrow-down` with a folio of the unsaved chapter count; hidden when all are saved or while running; disabled without a profile), and the overflow (the Feature page's menu of D5, including `Move to another source…` for followed books, shown first under the `NOTE` banner when the source is `dead`).
   - Columns 9–12: the cover plate 168 × 248 (square-cornered, 1 px `rule.2`), with a duotone copy of the cover filling columns 9–12 behind the plate (cover fit, `blur.bleed` 56 px, duotoned to `ambient.duo`, grain 0.06 and Drift on the field only). Long-press (phones), double-click (desktop) and `v` open the Lightbox on the plate.
2. **Contents** (the full 12 columns under a 1 px `rule.1` section rule): the toolbar `FIRST → LAST │ LAST → FIRST` (segmented; default first → last; persisted in `mm.chapter-sort:{source}:{series}` as `oldest` / `newest`), the go-to field (`goToChapterMatches()`: a match list of up to 12 buttons "{title}" + "row {n}" and "and {n} more"; "Type a chapter number."; "No chapter {n} in this book."; `Enter` jumps to the first match, `Esc` clears), `Pick chapters` (F select mode), and a `Narrated only` toggle (`aria-pressed`). **Contents rows** (§7.16, 48 px): the ordinal in `type.folio` right-aligned in a 40 px column (`·` when none) → the title in Newsreader 16 (read rows dimmed to `ink.45`) → dot leaders (`·` at 0.5em intervals in `ink.30`) → the length `12 MIN` (`type.folio`) → the state mark (`42%` in `spot`, `READ`, a `headphones` glyph when narrated, the download mark). The list is windowed around the focus (400 rows at a time, `tocWindowAround()` / `extendTocWindow()`) with `Show earlier chapters (n)` (`quiet`) above and `Show more chapters (n)` (secondary) below; the focused chapter (`?chapter=` or go-to) scrolls to the centre with the `spot.wash` band and a 2 px `spot` left bar, `aria-current="location"`. The first three chapters are prefetched silently (`prefetchNovelChapterWindow`, P3).
3. **Row interactions**: tap opens the novel reader at that chapter (Column wipe); long-press (phones), right-click (desktop) and a trailing `dots-three` open `Mark read`, `Mark read up to here`, `Mark unread`, `Download`, `Bookmark start` (the D3 calls); phones: swipe left to `Mark read`.
4. **Phone layout**: the plate 96 × 144 floats right of the title block; the facts wrap into two lines; the blurb collapses to 5 lines with `More` (a `quiet` button that expands it in place); the actions stack as on the Feature page; the contents run full width; the go-to field is behind a search icon button that expands it in place above the contents.
5. **Tablet** (768–1023 px): the front matter in columns 1–5, the 168 × 248 plate in columns 6–8; the contents full width.
6. **Keys (web)**: `Enter` or `c` start or continue; `l` listen; `v` view cover; `+` library toggle; `d` download book; `/` go-to; `o` order. All in the `?` sheet.
7. **States**: front matter loading (galley); offline ("This book needs a connection to load."); error (kicker `CORRECTION`, headline "Couldn't load this book.", `Back to the source`); not available (the §8.0.10 notice); contents loading (10 greeked rows); contents offline ("The contents need a connection to load."); contents error ("Couldn't load the contents" + `Try again`); contents unavailable ("Contents didn't come through."); contents empty ("No chapters yet."); narration unavailable (a `type.caption` line under `Listen`'s slot: "Narration isn't available for this book."). Every notice headline types at 50 ms per character.

### F. Chapter selection and downloads (§8.19, DP1–DP7)

Shared by both pages: `frontend/src/skins/cinematic/screens/feature/downloads/`.

1. **Trigger**: `Download` (manga) or `Pick chapters` (novels) enters select mode on the chapter list. Rows gain a leading 20 px checkbox (§7.21: 1 px `ink.45` outline; checked fill `ink.100` with a `#000` 2 px square-capped check path; fill 120 ms `dur.snap`); saved chapters are disabled (checked and dimmed); Shift-click selects a range; long-press starts selection on phones. `useChapterPicker()` holds the state.
2. **Selection bar** (§7.29; `paper.2`, 1 px `rule.2` top, `data-stock="raised"`; bottom of the screen on phones above the safe area, under the running head on desktop, `z.sticky`): `12 SELECTED · 3 ALREADY SAVED` (folio); the quick picks as a slug line with counts `NEXT 10 · ALL UNREAD ⁴² · WHOLE BOOK` (novels only) `· ALL ²⁰¹ · NONE` (`nextChapters`, `unreadChapters`, `everyChapter`); `Done` (quiet) and `Download 12` (primary). With nothing selected the primary is disabled and the count reads "Select chapters to download".
3. **Running**: `DOWNLOADING 4 OF 12` + a determinate 2 px rule (`spot` on `rule.1`, width changes 240 ms `ease.set`) + `Stop`; the per-row marks animate as the queue works. Haptic `download.start` when the queue accepts, `download.done` once when the batch finishes, `download.fail` on a failed chapter (Android Chrome `[20,40,20]`).
4. **Summary line** after a run (`describeRun()`), with `Dismiss`: "12 chapters saved." / "Nothing to download — those are already saved." / "10 of 12 saved, 1 with missing pages, 1 failed." / "Out of room: only 380 MB free. Remove some downloads and run it again." with `Manage downloads` (→ `/downloads`) / "Stopped: 4 saved."; problems use the `NOTE` tone (the `NOTE` kicker in `spot`).
5. **Series download card** (Feature page, when anything is saved or queued; `useSeriesDownloads()`): kicker `ON THIS DEVICE`, `12 OF 201 CHAPTERS SAVED` with a determinate rule (`set` when complete), `DOWNLOADING NOW · PAGE 7 OF 40`, `3 WAITING · 1 FAILED`, and the pause reason line when blocked (`NOTE`: "Paused: this browser is out of room." with `Storage settings` → `/downloads?tab=storage`). The app-only foreground note is not shown on the web.
6. **No profile**: "Downloads belong to a reading profile. Choose one to save chapters." + `Choose a profile` (→ `/profiles`).
7. **Novels**: `Whole book` pages the text through `POST /novels/chapters` 20 at a time; the bar shows `SAVING THE TEXT…`.
8. **Download marks** (§7.18, per chapter, 16 px square with a 1 px outline, `downloadMarkState()`): not downloaded `cloud-arrow-down` 16 Regular `ink.45` ("Download"); queued a dashed `ink.45` outline ("Queued to download"); downloading the square fills bottom-up in `spot` with progress ("Downloading, 30 percent"); saved `check-square` Fill in `set` ("Downloaded — opens with no connection"); failed a `proof` outline with `!` ("Failed, tap to retry"; tapping retries); paused two 2 px `spot` bars ("Paused — this browser is out of room"); stale `cloud-arrow-down` in `spot` ("The source changed these pages — download it again"). Each is a button with the tooltip and the §7 semantics name.
9. **18+**: when the gate closes, queued or running downloads of a now-hidden series pause silently and resume when it reopens (web/07's filter); nothing on this page says files are hidden.

### G. Inventory coverage (every row lands somewhere)

| Rows | Where it lands |
|---|---|
| SD1, SS2 | The spread art (cover, `blur.bleed` duotone, scrims, grain, Drift) |
| SD2, SS1, NB1 | The running head's back (phones) and breadcrumb (desktop) |
| SD3 | The cover in the spread; the Lightbox for the whole cover |
| SD4, SS3, NB3 | The letter-revealed title |
| SD5 | The Favourite icon button |
| SD6, SS4, NB4 | Credits `STORY` / `ART`; the novel byline |
| SD7 | At a glance reading-status slug line and the overflow `Set reading status ▸` |
| SD8 | The Notify icon button |
| SD9, SS5, NB6 | The kicker and credits (`STATUS`, chapter count); the book facts |
| SD10, SS8, NB10 | The `split` primary (`Read │ CH 1` / `Continue │ …` / `Start reading │ CH 1`) |
| SD11, SS9 | The disabled `All caught up` |
| SD12, SS10 | `Read all` |
| SD13, SS7, NB9 | The deck and the DETAILS synopsis with the drop cap; the book blurb |
| SS6, NB8 | Genre slug-line links to the catalogue |
| SS11, SS12, NB11 | Follow / Add to library with the toasts |
| SD14, SS13, NB13 | The CHAPTERS toolbar (sort, go-to, Select, the download summary); the book contents toolbar |
| SD15, SS14, NB16 | Schedule rows; contents rows |
| SD16, SS15, NB17 | Rows in select mode |
| SD17, SS16, NB18 | The selection bar and the series download card |
| SD18 | The galley rows while the content mode resolves |
| SD19, SS17, NB19 (contents) | Chapter and contents list states |
| SD20, SD21, SS18, NB19 (front matter) | Page loading, error, offline and not-available states |
| NB2 | The 168 × 248 plate (96 × 144 on phones) |
| NB5 | The 56 px rule |
| NB7 | The estimate note |
| NB12 | Download book with the unsaved count |
| NB14 | The go-to field and match list |
| NB15 | The 400-row window with Show earlier / Show more and the focused row |
| DP1–DP7 | F1–F8 |

## File layout

```
backend/services/followed_series_service.py, backend/tests/test_library_endpoints.py   (section A only, when needed)
frontend/src/features/sources/enrichment.ts
frontend/src/features/ai/tags.ts
frontend/src/features/ocr/coverage.ts                       (or the call added to ocr/api.ts)
frontend/src/features/library/{repoint,series-time}.ts (+ tests), mark-read.ts (extended, + tests)
frontend/src/features/offline/download-mark.ts (+ test)
frontend/src/features/novels/…                              (useSeriesAudio only if missing)
frontend/src/skins/cinematic/index.ts                       (feature out of PENDING)
frontend/src/skins/cinematic/screens/feature/FeatureScreen.tsx
frontend/src/skins/cinematic/screens/feature/FeatureView.tsx
frontend/src/skins/cinematic/screens/feature/manga/{FeatureSpread,FeatureTabs,ChaptersPanel,ScheduleRow,AtAGlance,DetailsPanel,FeatureOverflow,RepointPanel,FeaturePhoneHero,FeatureStates}.tsx
frontend/src/skins/cinematic/screens/feature/book/{BookFrontMatter,BookContents,ContentsRow,BookStates}.tsx
frontend/src/skins/cinematic/screens/feature/downloads/{SelectionBar,SeriesDownloadCard,DownloadMark,RunSummary}.tsx
frontend/src/skins/cinematic/screens/feature/use-feature-keys.ts
frontend/src/app/(preview)/…                                 (gallery entries for the download marks and new variants)
frontend/e2e/cinematic/web-11-series.spec.ts
frontend/e2e/fixtures/series/*.json
docs/redesign/proof/web-11/…
```

Skin code imports only `@/features/**` data files (never barrels that re-export components), `@/lib/**`, `@/skins/contract.generated` and its own folder; utilities only from §2.8 and §3.5 (`node design/lint-utilities.mjs`).

## Acceptance criteria

- [ ] `feature` is out of `PENDING`; the completeness test passes; `/sources/:s/series/:k` and `/library/:followedId` render the same `FeatureView` (the e2e spec compares the rendered title and chapter count on both routes), with no redirect.
- [ ] A poster click lands on the spread by a 480 ms match cut, the title letters set after it lands, the credits appear in reading order, and the ambient wash dissolves over 800 ms; back reverses the match cut in 336 ms (motion-timings overlay rows, no `proof`).
- [ ] Desktop spread geometry: text in columns 1–5, art in 6–12, `scrim.gutter` over 6–7, height `clamp(520px, 64vh, 760px)` (grid-overlay screenshot); tablet 4 + 4 on 8 columns; phone 4:5 hero with the title block overlapping its lower quarter.
- [ ] Tabs: `01 CHAPTERS²⁰¹ · 02 DETAILS`, sticky; `1`, `2`, `[`, `]` switch them; the tab list is an array web/19 and web/22 can extend.
- [ ] Chapter rows: 56 px, numbers in a 56 px right-aligned column in the issue colour, `·` for null numbers, de-duplicated titles, the current chapter's `spot.wash` band and `READING` badge; rows are virtualised above 60; hover prefetch fires one P3 manifest request after 150 ms and none for a shorter hover.
- [ ] Mark read, Mark read up to here and Mark unread send the §8.17 requests (asserted in the e2e spec) with Undo toasts; they are disabled offline with "Needs a connection."
- [ ] The `mature_override` radio menu sends `true`, `false` and `null` and shows the matching toast; with section A applied, `null` clears the override (backend test).
- [ ] Repoint: candidates, mapping sentence, `Keep following it on … too`, `Move` → match cut to the new source's page and the toast "Moved to …. You're on chapter N."
- [ ] At a glance: `142 / 201`, the status slug line, `YOUR TIME HERE`, tags with add, remove and the `SUGGESTED` line (absent when `/ai/tags` is unavailable), shelves with `Add to shelf`, OCR coverage with its rule.
- [ ] DETAILS: the drop cap (84 px on 28 px leading), genre links, the enrichment credits (absent for a `null` answer).
- [ ] The Book page renders the typographic front matter, the 56 px rule, the facts, the estimate note and the plate; the contents window shows 400 rows with Show earlier / Show more; `?chapter=` centres the focused row with the band.
- [ ] Downloads: select mode with Shift-click range, the quick picks with counts, `Download N`, the running state with `Stop`, every summary line (fixtures), the series download card, and each of the seven download marks with its tooltip.
- [ ] The rating card appears for a mature series (gate open) for 3000 ms and never blocks; with the gate closed, a mature series route shows the `NOT IN THIS ISSUE` notice with the same wording as a removed series.
- [ ] The Lightbox opens from long-press, double-click, `v` and `View cover`, and closes with `x`, `Esc`, browser back (`?view=cover`) and a drag down past 120 px.
- [ ] Reduced motion: the match cut and the Column wipe become 200 ms cross-fades, letters fade in 200 ms, Drift stops at scale 1.03, the ambient wash swaps instantly, the Lightbox fades 150 ms, the rule draws show at rest, swipe releases finish with a 150 ms fade.
- [ ] Keyboard (desktop): every control reachable in reading order with the double focus ring, never clipped (sticky tabs set `scroll-padding-block`); the D10 and E6 keys work and appear in the `?` sheet.
- [ ] Hit targets: at least 44 × 44 px on the phone frame (8 px apart) and at least 32 × 32 px on the desktop fine pointer (measured by the e2e spec).
- [ ] Every state of D11 and E7 renders at both sizes (screenshots).
- [ ] Per skin: the data-layer additions under `frontend/src/features/` import nothing from `src/skins/**`, so Glass's series page (web/33) reuses them; the Glass skin's `feature` entry stays in Glass's own `PENDING` set; the legacy series pages are unchanged.
- [ ] Lint, typecheck, Vitest, build and the `design/` checks are green; Vitest totals at least the start-of-step totals with 0 failed; the backend pytest passes if section A ran.

## Verification

From `/srv/manhwamaniacs/dev/ManhwaManiacs`, one at a time, each after the RAM guard:

```
node design/build.mjs --check
node design/lint-utilities.mjs
cd frontend && npm run typecheck
cd frontend && npm run lint          # baseline: exit 0, 0 errors, 0 warnings
cd frontend && npm run test          # passed >= start-of-step count, 0 failed
cd frontend && npm run build         # baseline: exit 0
cd backend && .venv/bin/python -m pytest -q --no-header    # only if section A changed the backend
```

Nothing under `mobile/` changes (`git show --stat --format= <hash>` of each of your commits lists no `mobile/` path); `flutter analyze` and `flutter test` are the mobile session's.

If any commit you made touches `mobile/` (check each of your commits with `git show --stat --format= <hash>`; other sessions commit `mobile/` on the same branch, so never judge by the branch diff), revert that part, then prove the baseline still holds with the baseline's own commands, one at a time after the RAM guard and never while a `next build` runs: `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter analyze` (baseline: No issues found) and `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter test` (baseline: all 2012 tests passed).

Visual proof against the backend/00 dev stack (uvicorn 127.0.0.1:8010, `next dev` on port 3010; `backend/scripts/README-dev-stack.md`):

1. `frontend/scripts/proof.mjs` at 1440 × 900 and 390 × 844 into `docs/redesign/proof/web-11/` (for example `node scripts/proof.mjs --step web-11 --routes "/library/<id>,/sources/<source>/series/<key>" --grid`, with a followed manga series and a novel from the seeded demo data; `--help` if the flags differ). Required files:
   - `feature-{1440x900,390x844}.png`, `feature-grid-1440x900.png`, `feature-tablet-900x1200.png`
   - `feature-details-{1440x900,390x844}.png`, `feature-at-a-glance-1440x900.png`, `feature-overflow-1440x900.png`, `feature-mature-override-1440x900.png`
   - `feature-rating-card-1440x900.png` (gate open, mature fixture), `feature-lightbox-{1440x900,390x844}.png`
   - `feature-repoint-{candidates,mapping}-1440x900.png`, `feature-repoint-390x844.png`
   - `feature-select-{1440x900,390x844}.png`, `feature-downloading-1440x900.png`, `feature-download-card-1440x900.png`, `feature-download-summary-{saved,out-of-room}-1440x900.png`
   - `feature-{loading,chapters-offline,chapters-unavailable,no-chapters,error,offline-saved,notavailable}-{1440x900,390x844}.png`
   - `book-{1440x900,390x844}.png`, `book-contents-window-1440x900.png`, `book-goto-1440x900.png`, `book-pick-chapters-1440x900.png`, `book-{loading,error,contents-empty}-1440x900.png`
   - `download-marks-gallery-1440x900.png` (the seven marks from the primitives gallery)
2. `frontend/e2e/cinematic/web-11-series.spec.ts` drives the states with `page.route` fixtures from `frontend/e2e/fixtures/series/` (series detail, chapters, progress, enrichment, `/ai/tags`, repoint, a `series_not_found` 404), asserts the progress-batch and delete requests, the prefetch dwell, the hit sizes and the two routes rendering the same page. Run: `cd frontend && E2E_BASE_URL=http://127.0.0.1:3010 E2E_USERNAME=<demo user> E2E_PASSWORD=<demo password> npx playwright test e2e/cinematic/web-11-series.spec.ts` (credentials from the dev-stack README, never committed). With `playwright-cli`, pass `-s=web-11`.
3. Motion-timings overlay (`mod+shift+m`): poster → feature → back, and `Continue` into the reader; screenshot `feature-motion-timings-1440x900.png` with no `proof` rows (the reader screen may still be the pending screen until web/12; the wipe itself is what is measured).

## RAM guard

- Before every `npm run test`, `npm run build`, pytest, Playwright run or dev-stack start: `free -m`; if `available` on `Mem:` is under 1024, stop and report "RAM guard: N MB available".
- `pgrep -af "next build|vitest|flutter_tester|pytest"` first; never run two builds at once; wait for other sessions' builds and tests to finish.
- One heavy command at a time; no Gradle, Xcode or `flutter build`; no `npm install` (every package was pinned in web/01; if `npm ls @use-gesture/react @tanstack/react-virtual motion` reports one missing, stop).

## Git

- Branch `feat/vps-slim-source-native`; small commits, one per working step (the backend override fix; enrichment, tags, coverage and repoint hooks; the feature shell and match cut; the spread; tabs and chapters; At a glance; DETAILS; the overflow and `mature_override`; repoint; the Book page; downloads; states; e2e and proof), messages starting `web-11:`.
- Stage only your paths with explicit `git add <path>`; the backend commit stages only `backend/services/followed_series_service.py` and `backend/tests/test_library_endpoints.py`. Never `git add -A` or `git add .`; never commit secrets, demo credentials, `.claude/` or `.env` files.
- **No Claude or AI attribution anywhere** (no `Co-Authored-By`, no "Generated with" line, no AI author), even if your harness asks for it; the owner's `~/.claude/CLAUDE.md` forbids it.
- `npm run build` (after the RAM guard) before any push with frontend code; `git push origin feat/vps-slim-source-native` after each working step.

## Guardrails

- Never edit `backend/connectors/`. Never touch production containers or `/srv/manhwamaniacs/{app,data}`.
- Backend changes are limited to section A. No changes under `mobile/` or `design/`.
- Skin code never imports `frontend/src/components/**` or `frontend/src/features/*/components/**`, and never reproduces the legacy look.
- Do not build what later steps own: `03 MORE LIKE THIS`, `Previously on…` buttons and the `p` key (web/19); `04 CIRCLE`, `Recommend to…`, `SEND`, "In the circle" and reaction counts on rows (web/22); the Audiobook button and sheet (web/15); the reader screens (web/12–web/15).

## Report back

1. **Done**: A (ran, skipped because present, or skipped because another session held the backend), B1–B7, C1–C3, D1–D11, E1–E7, F1–F9, with a one-line status each.
2. **Screenshots**: `docs/redesign/proof/web-11/` and the file list.
3. **Tests**: Vitest totals before and after; lint, typecheck and build; the e2e spec result; backend pytest totals if section A ran.
4. **Motion**: the motion-timings rows for the match cut in and out and the Column wipe.
5. **Open issues**: ambiguities and the choices made (for example payload fields that were absent, such as alternate titles or the series URL), blocked items, conflicts with DESIGN.md.
6. **Commits**: the hashes pushed.

Next prompt file: `docs/redesign/prompts/web/12-cinematic-manga-reader-strip.md`.
