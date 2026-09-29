# Web Glass series detail and book page

Track: web · Order 84 · Depends on: `docs/redesign/prompts/web/32-glass-library-hub-downloads.md` · Runs in parallel with: `docs/redesign/prompts/mobile/33-glass-series-and-book.md` · Proof folder: `docs/redesign/proof/web-33/`

## Goal

Build the Glass series page on the web client (`frontend/`): the manga series detail of glass §8.12 and the novel book page of §8.13, one screen for both identities (`/sources/:sourceId/series/:seriesKey` and `/library/:followedId`), presented through the `web/29` sheet host as a phone sheet (`medium` → `large`) with the poster zoom ("the cover lands"), as the 960 px `materialThick` detail window over the recessed page on desktop, and as a full page on a hard load or deep link. It carries the tinted band in the series palette, the header, the split Continue button, follow, favourite and notify, the enrichment (score, format, official sites), the ⋯ menu (reading status, collections, tags with AI suggestions, check for new chapters, move to another source, content rating, open in browser), the download card, the "Previously on" row and the More like this rail as entry points, the chapter list with its download controls, select mode and the download picker, Mark read and Mark unread, and on the book page the plate, the Literata front matter, the windowed Contents with the go-to field and the Book open move. Every state and every key is part of this step. When you finish, the ScreenIds `feature` and `featureByFollow` leave the Glass `PENDING` set. Glass stays behind the debug row; Cinematic must not change by a single pixel.

## Read first

Read these completely before planning. Where this file and `glass/DESIGN.md` disagree, `glass/DESIGN.md` wins; say so in the report.

1. `docs/redesign/inventory/00-decisions.md` (all of it) and `docs/redesign/00-baseline.md`.
2. `docs/redesign/stack-decision.md` §2.2 (web layout and the lint boundary), §2.6.
3. `docs/redesign/glass/DESIGN.md`:
   - The screens: §8.12 Series detail (every bullet, including "Mark read and Mark unread", "Move to another source", the signature moment, transitions, gestures, states, keys, owner-only affordances), §8.13 Book page.
   - Shell and routing: §8.0.3 (rows `feature` and `featureByFollow`; the sheet ids `tags`, `move-source`, `image`, `save-files`, `offer`, `recommend`, `audiobook`, `how-it-works`), §8.0.4 (Zoom, Dive, Book open), §8.0.5, §8.0.6, §8.0.8 (unavailable content, 18+, server capabilities, focus on navigation), §8.0.10 (error copy), §15.2 "Sheet host" (mechanism, closing, a sheet route opened from a sheet, hard load, while a sheet route is open) and "Routes" (`coverTransitionName`).
   - Components: §7.1 buttons (the split button, selected state, lit action), §7.2, §7.5 chips, §7.6 segmented, §7.7 (World title card for More like this), §7.9 rails, §7.10 sheets (detents, the detail window exception: `materialThick` `rgba(19,19,23,0.84)`, blur 36, radius 32, covered page at scale 0.97, blur 8, `rgba(0,0,0,0.50)`), §7.11 alerts, §7.12 toasts, §7.17 chapter rows, §7.19 progress, §7.20 badges, §7.23 menus, §7.24 lens states, §7.29 download control, §7.31 image viewer, §7.32 fast scroll, §7.34 swipe rows, §7.35 bulk selection, §7.38 AI surfaces (machine light, `AiNotice`, the sparkle chips).
   - §9.1.3 (the "Previously on" entries only), §9.1.4 (More like this), §9.1.5 (the one voice for "unavailable").
   - Motion and feedback: §4.2, §4.3, §4.4 (Sheets row), §4.9, §4.10 rows Zoom, Dive, Book open, Sheet present, Sheet snap, Recede, Follow ring, Specular sweep, Letter reveal, Row pulse, Liquid fill, Error shake, Tag flight; §4.11; §2.4.4 (the follow ring and caustic); §5.2 events (`follow.add`, `follow.remove`, `download.start`, `download.done`, `download.fail`, `select`, `threshold.cross`, `sheet.detent`, `longpress.open`, `undo`); §6.
   - Colour: §2.1.7 (`Lb` rows "Series detail band"), §2.1.8 (series field at 28 %), §3.4 (Literata), §2.4.1 rule 2 (two page-level glass controls in scrolling content: the split Continue and the secondary group).
   - §11 rows Sheet drag, Swipe down on a sheet, Swipe a row, Drag across items, Press and hold; §14.1–§14.8, §14.11; §15.7 (phone and desktop rows).
4. `docs/redesign/cinematic/DESIGN.md`, for the behaviour both skins share (never for its look): §8.17 (the one series page for both routes, the repoint flow and the mature_override menu it defined), §8.19 (chapter selection and downloads on series pages), §15.5 (the enrichment, repoint, progress batch and progress delete calls reused as they are).
5. `docs/redesign/inventory/web.md` as the completeness checklist: §7.3 SD1–SD21, §8.3 SS1–SS18, §10.2 NB1–NB19, §12.2 DP1–DP7, §18.4 A28–A33 and A37, §18.8 A87–A88.
6. `docs/redesign/prompts-plan.json`: the `web/00` entry (its TRACK RULE) and this file's entry.
7. Reports: `docs/redesign/proof/web-27/report.md`, `web-28/report.md`, `web-29/report.md` (the `SheetHost` API, the Dive helper, the poster-zoom `ViewTransition`), `web-32/report.md`.
8. Code you build on:
   - Glass: `frontend/src/skins/glass/Shell.tsx` (the `SheetHost`: how a sheet route receives its presentation, the `--sheet-progress` writer, the stack of two), `primitives/Sheet.tsx` (detents, `desktop="detailWindow"`, grabber, `pickDetent` in `sheet-physics.ts`), `primitives/{SplitButton,Button,IconButton,Menu,ContextMenu,Chip,Segmented,Switch,RadioList,TextField,Toast,ImageViewer,FastScroll,LiquidProgress,Rail,HoldToConfirm,Skeleton}.tsx`, the `web/28` list, swipe-row, bulk-selection, download-control, state-lens and AI parts, `glass/{Caustic,AmbientField,useLb}.tsx|ts`, `copy/{errors,ai}.ts`, `motion.ts`, `fonts.ts` (Literata, `preload: false`), `screens/library/` from `web/32`.
   - Shared data layer: `frontend/src/features/sources/{hooks,enrichment,chapter-label,chapter-date,series-progress,cover-transition-name}.ts`, `frontend/src/features/library/{hooks,mark-read,repoint,series-time,followed-index,tags}.ts`, `frontend/src/features/ai/tags.ts`, `frontend/src/features/ocr/coverage.ts` (or `ocr/api.ts`), `frontend/src/features/offline/{use-series-downloads,use-chapter-picker,download-mark,download-queue,chapter-savers,save-request,mature-filter}.ts`, `frontend/src/features/novels/{book,hooks}.ts`, `frontend/src/features/reader/hooks.ts` (chapter manifest prefetch), `frontend/src/features/content-mode/`, `frontend/src/lib/keyboard/`. Find the similar-series hook `web/19` added with `grep -rn "ai/similar" frontend/src/features`, and the source genre list with `grep -rn "/genres" frontend/src/features/sources`.
   - The Cinematic feature screens, for data wiring only (never import them): `frontend/src/skins/cinematic/screens/feature/`.

## Preconditions (stop and report if any fails)

```bash
cd /srv/manhwamaniacs/dev/ManhwaManiacs
git branch --show-current                              # feat/vps-slim-source-native
git log --oneline -40 | grep -i "web-32\|glass.*library"   # web/32 landed
grep -n "\"library\"\|library:" frontend/src/skins/glass/index.ts   # library is no longer PENDING
grep -rn "SheetHost" frontend/src/skins/glass/Shell.tsx | head -3
grep -rn "export function coverTransitionName" frontend/src/features/sources/cover-transition-name.ts
node design/build.mjs --check
cd frontend && free -m && npm run test 2>&1 | tail -5   # record the vitest file and case counts: your floor
```

## Skills to invoke

1. `superpowers:writing-plans` before any code. Save the plan at `docs/redesign/proof/web-33/plan.md`.
2. `superpowers:test-driven-development` for the pure helpers of section A (detent from a throw, the collapse progress mapping, the genre-link rule, the go-to match list, the TOC window, the select-mode planners): vitest first.
3. `superpowers:subagent-driven-development` to run the plan (or `superpowers:executing-plans` inline). At most 5 implementer subagents (presentation and header; actions and ⋯ sheets; chapters, select mode and picker; book page; e2e and proof). Start every subagent prompt with a scope lock, pass `model: "opus"` explicitly, run builds, tests and browsers one at a time, and verify each subagent's work against `git status` and `git diff`, never against its report alone.
4. `frontend-design:frontend-design`, `impeccable:impeccable` and `taste-skill:taste-skill` for the band, the header, the two-column window and the book page (the band is the one place glass sits over the cover's light; the split Continue is the one lit action).
5. `superpowers:verification-before-completion` before you claim anything is done.

## Scope: deliver every item below

Sizes are CSS px. Every named move goes through `play()`; every glass surface is a `GlassSurface` counted by the budget; chapter rows, TOC rows, chips inside rows and per-row buttons are content twins (§2.4.1 rule 1). The one lit action is the split Continue (`glassTinted`); a sheet or alert opened over it carries its own tinted twin and the page's lit object drops to `glassThin` while it is up (§2.4.2 rule 8). Web "hit 44" means the element's own box is at least 44 × 44 at 390 × 844. `document.title` is `{series title} · ManhwaManiacs`; route focus lands on the title `h1` (sheet title for sheet routes) with `preventScroll: true`.

### A. Shared and pure helpers (each with a vitest)

1. `skins/glass/screens/series/detent-from-throw.ts`: `openingDetent({ vy, mediumTop, largeTop })` returns `"large"` when the projected top (`mediumTop + 0.499 × vy`, `vy` in px/s, negative upward, projection capped at one viewport height) is nearer `largeTop` than `mediumTop`, else `"medium"`. Uses `project()` from `skins/glass/physics/project.ts`. Test: no velocity → medium; −1200 px/s on an 844 px viewport → medium; −2400 px/s → large.
2. `skins/glass/screens/series/collapse.ts`: `collapseProgress(sheetTop, mediumTop, largeTop)` clamped 0–1 (1 at `large`); `coverToCapsule(p)` returns the cover's scale and translation from its 112 × 168 header slot to the 24 px thumbnail in the title capsule. Test the ends and the middle.
3. `features/sources/genre-link.ts`: `genreHref(sourceId, genre, sourceGenres)` returns `/sources/{id}?genre={genreId}` only when a `label` in the source's genre list matches the tag case-insensitively, else `null` (render a plain tag). Test a match, a case-only match and no match.
4. `features/novels/toc-window.ts` (or extend `book.ts`): `tocWindow(total, focusIndex, size = 400)` returns `{ start, end, earlier, later }` so the list shows 400 rows around the focus with "Show earlier chapters (212)" and "Show more chapters (400)"; `goToMatches(chapters, query)` returns up to 12 matches plus the remaining count, `"Type a chapter number."` for an empty query and `"No chapter 900 in this book."` when none match (numbers compared as decimals, `inputmode=decimal`). Test the window at both ends and the three messages.
5. Select-mode planners (`features/offline/use-chapter-picker.ts`, extend its test only if missing): "Next 10" (the next ten unread chapters after the reading position, skipping saved ones), "All unread (n)", "All (n)", "None", and for books "Whole book".

### B. Presentation and routing (`screens/series/FeatureScreen.tsx`, `FeatureByFollowScreen.tsx`)

1. **One screen for both identities.** `feature` renders `SeriesDetail` or `BookPage` by the series' `content_kind`. `featureByFollow` (`/library/:followedId`) resolves the follow row (`GET /library/series/{followedId}`) and renders the same screen in place, with the header skeleton meanwhile and no redirect flash; a missing follow shows the `not_found` lens "This isn't here any more" / "It may have been removed on another device." + "Back". `source_not_found`, `series_not_found` and `source_not_browsable` show the §8.0.8 unavailable lens with its line, "Back", and for followed series "Move to another source…" (primary, when the source is `dead` or `source_not_found`) and "Remove from library" (with Undo).
2. **Phone (< 768 px) sheet route** through the `web/29` `SheetHost` (`history.pushState`, the covered page stays mounted): the `web/27` `Sheet` with detents `medium` (52 %) and `large` (viewport − safe-top − 10), the page behind receding by sheet position (scale 0.94, radius 12, blur 8, 60 % brightness at `large`), closing by the close button, Esc, a downward drag, a backdrop tap or browser back (`history.back()`). The opening detent comes from A1 when the poster was thrown (the `web/26` throw passes its velocity), otherwise `medium`.
3. **Tablet (768–1023 px):** the window at the full content width with the phone's one-column anatomy and a 280 px band.
4. **Desktop (≥ 1024 px):** the `detailWindow` form, 960 wide, radius 32, top 24, `height: calc(100dvh - 48px)`, the window itself the scroll container, drawn as the content-layer `materialThick` slab (`rgba(19,19,23,0.84)`, blur 36, no live glass; its text keeps the alpha labels and its state glyphs stay bare). If `Sheet.tsx` has no option for that material, add `material="contentThick"` to its `detailWindow` form (a primitive change: keep the gallery entry and its test green). The covered page recedes to scale 0.97, blur 8 and `rgba(0,0,0,0.50)`, driven by `--sheet-progress` (the `SheetHost` rule for this window only).
   - **Layout (≥ 1024 px):** the band 240 px tall across the window; below it two columns with 32 px padding and a 32 px gutter. **Left column, 320 px,** `position: sticky; top: 24px`: the cover 240 × 360 (radius 14) overlapping the band by 120 px, the title block, the split primary and the secondary buttons stacked full width (44 px each, 8 px apart), then the facts ("412 chapters · Updated 2 d ago", status, source chip, tags) and "Read officially". **Right column** (≈ 544 px) scrolls: description, the download card, Previously on, More like this, then Chapters with its pinned header. The nav row sits inside the band (close × leading, the trailing glass group).
5. **Hard load and deep link:** a reload or a direct visit to either path renders the same layout as a full page through the thin route file (phones: band + one column; desktop: the two-column layout at most 960 wide, centred in the content column); closing becomes the back chevron to the source catalogue (`/sources/:sourceId`) or `/library` for `featureByFollow`. A hard-loaded `?sheet=` parameter opens that sheet over the full page and closing it replaces the URL.
6. **A sheet route opened from this sheet** (the `recap` route from "Previously on") stacks above it per the host's two-entry rule; the lower sheet scales to 0.9165.
7. **Ambient field:** the series cover palette at 28 %, taken when the sheet opens (Light follows the story over `tintShift` 900 ms).

### C. Band and header (§8.12 "Top band", "Header", "Read officially")

1. **Band:** the cover's blurred enlargement (the ambient field at 28 %) fills the top 280 px (desktop 240), fading to black. The nav row inside the sheet: close × at `medium`, a back chevron at `large`; trailing glass group (`glassClear`, `Lb` = the series palette's `lMax`, with `dimClear` `rgba(0,0,0,0.35)` beneath when `Lb > 0.45`): share (copies the series URL; toast "Link copied"), the bookmark list for this series (→ `/library/bookmarks?source=&series=`), ⋯.
2. **Header:** the cover 112 × 168 (radius 14) at the left, overlapping the band; right of it the title `title1` with the letter reveal (§10.1, at most 60 graphemes); "by {author} · art by {artist}" `footnote` `label2`; tags (status tag, first four genres through A3, the 18+ badge when mature; a linked genre tag pushes `/sources/{id}?genre={genreId}` with **Tag flight** on `zoom`, the tag text carrying `view-transition-name: genre-{genreId}`; the catalogue chip that receives it is `web/38`'s); "412 chapters · Updated 2 d ago" `caption1`; "★ 8.4 · Manhwa" from `GET /series/enrichment?source&series` (`score`, `format`) when non-null.
3. **Read officially:** up to 3 site chips from the enrichment's `official`, each opening in a new tab (`rel="noopener"`); on failure the toast "Couldn't open {site}". Enrichment null → the facts addition and this row are omitted.
4. **Collapsing header (phones):** dragging from `medium` to `large` shrinks the cover into the nav row's title capsule (24 px cover thumbnail + title) driven 1:1 by the sheet position through A2; read the position from the `Sheet`'s exported progress (if `Sheet.tsx` exposes none, add a `useSheetProgress()` hook returning its Motion value; keep its test green).
5. **Cover tap or pinch** opens the image viewer (`?sheet=image`, the `web/27` `ImageViewer`, zooming from the cover's rect on `zoom` k 125.9, c 21.09).

### D. Actions (§8.12 "Actions")

1. **Split primary** (`SplitButton`, `glassTinted`): "Continue · Ch 143" (dives into the reader at the saved page), "Start reading", or disabled "All caught up"; the chevron menu (and a long-press on the button) holds Read from the start, **Read all** (only with more than one chapter; `/read-all/:sourceId/:seriesKey?from=`), Pick a chapter (scrolls to Chapters and focuses the go-to field), Download next 10. Hover or focus on Continue prefetches that chapter's manifest (the existing reader prefetch hook).
2. **Secondary glass buttons** (one group): **In library / Add to library** (follow toggle, selected state per §7.1; "Adding…" while pending; toast "Added Solo Leveling to your library. New chapters will notify you." or "Removed Solo Leveling from your library.", both with Undo; `follow.add` / `follow.remove`), **favourite** star (followed only; `PATCH /library/series/{id} {is_favorite}`), **notifications** bell toggle (followed only; `PATCH … {notify}`), **Download** (a progress button for the whole series: the count of unsaved chapters, then the liquid fill while a run goes), ⋯.
3. **Following lights the band:** "Add to library" sends the caustic follow ring across the band (`FollowRing` from `glass/Caustic.tsx`, `followRing` 700 ms `cubic-bezier(0.2, 0, 0, 1)`) with `follow.add`; reduced motion: none.
4. **⋯ menu** (`Menu`): **Reading status** (a `menuitemradio` group: Unread, Reading, Completed, On hold, Plan to read, Dropped → `PATCH {reading_status}`; `invalid_reading_status` → the §8.0.10 toast and the menu reopens), **Add to collection** (the collections as `menuitemcheckbox` rows + "New collection" opening `?sheet=collection-new` from `web/32`), **Tags…** (`shift+t`), **Previously on** (navigates to the `recap` route, `/recap/:sourceId/:seriesKey?to=`; shown only when the profile has progress), **Check for new chapters** (followed only; `POST /updates/followed/{id}/check`; toast "Checked: 2 new chapters" or "No new chapters"), **Move to another source…** (followed only), **Content rating**: Automatic, Always mature, Never mature (`menuitemradio`, writes `mature_override`, followed series only, shown only when the profile's gate is open), **Open source page in browser**.
5. **Tags sheet** (`?sheet=tags`, `medium`; desktop 560 px window): the profile's tags as chips to toggle on this series (name + 10 px colour dot + a check glyph when on; `GET`/`POST /library/tags`, `POST`/`DELETE /library/series-tags`); "New tag" with a name field (max 24 characters, counter from 20) and one of the ten speaker hues (§2.1.5) as its colour; a **Suggested** group from `GET /ai/tags?source&series` (up to 5; omitted when `available: false`): machine-sparkle chips (§7.38), each with ✓ (accept: `POST /library/tags` when no tag of that name exists, then `POST /library/series-tags`) and × (dismiss: `POST /ai/feedback {signal: "tag_rejected", source_id, series_key, tag}`). States: loading (4 chip skeletons), error ("Couldn't load your tags" + Try again), empty ("No tags yet" + the New tag field focused), offline ("Tags need a connection", chips disabled), toggle failed (the chip springs back on `tick` with the toast "Couldn't update tags"), create failed (inline "Couldn't create that tag"), duplicate (inline "You already have a tag called {name}").
6. **Move to another source** (`?sheet=move-source`, `large`; desktop 560 px window): `GET /sources/search?q={title}&tier=1`, then `tier=2` when `next_tier == 2`, listing candidates (logo, title, "412 chapters" from `chapter_count`, the health bead); choosing one shows "You're on chapter 142 here. It becomes chapter 142 on {source}." (or "Your place couldn't be matched; you'll start from chapter 1" when `mapped_chapter_number` is null), a "Keep the old one too" switch (`keep_old`, default off), and the tinted "Move" sending `POST /library/series/{followed_id}/repoint {source_id, series_key, keep_old}` (`features/library/repoint.ts`). States: searching (the tier capsule), no match ("No other source has this series"), failed (toast "Couldn't move it. Try again"), offline ("Moving needs a connection"), success (toast "Moved to {source}" and the sheet zooms into the new series detail).

### E. Below the header (§8.12 "Below")

1. **Description:** `body`, 3 lines with "More" that expands on `snappy`.
2. **Download card** (when anything is queued or saved): "24 of 412 chapters saved on this device" with a liquid bar, "Downloading now · page 18 of 40", "3 waiting · 1 failed", the pause reason; the web shows no "Downloads run while the app is open" note (phones only).
3. **Previously on row** (when the profile has progress; `p`): a row with the machine sparkle that navigates to the `recap` route.
4. **More like this rail** (§9.1.4): up to 10 world title cards (§7.7) from `GET /ai/similar?source&series` through the shared hook, each with its `why` line after the machine sparkle; loading: the rail skeleton with the 28 px thinking orbit; empty: the rail is omitted; AI unavailable: the `AiNotice` with the §9.1.5 short line for the reason (the `fallback=genres` path is `web/41`).
5. **Chapters section** (below).

### F. Chapters, select mode and the download picker (§8.12 "Chapters section", "Select mode", "Mark read and Mark unread"; §7.17, §7.29; DP1–DP7)

1. **Header** (pins with `HardEdge`): "Chapters" `title2`; "24 of 412 downloaded" `footnote` + the Download trigger (enters select mode, DP1); "Dialogue indexed for 34 chapters" `caption1` (`GET /ocr/coverage`, manga only, when any); the Newest/Oldest `Segmented` (persisted per series in the scoped `mm.chapter-sort:{source}:{series}`, `n`); "Select" plain button (`x`); a go-to field (`/`) when the series has more than 50 chapters (Enter scrolls to the first match on `camera` and focuses that row).
2. **Rows** (§7.17 chapter row, 56 tall, 68 with a secondary title): the number in `mono` 15 `label2` in a 44 column (tabular, "·" for null, "12.5" for decimals); title `body` (or "Chapter 12"); meta `caption1` `label3` (date "Today", "Yesterday", "3 d ago" or "12 Sep"; "18/40" in `iris400` when in progress; "40 pages"; "Read"); the trailing §7.29 download control (eight states, 44 hit, 28 visual); read rows drop to `label3` text; the in-progress row has a 2 px `iris500` bar under its number. Lists over 100 rows are virtualised with `@tanstack/react-virtual`; over 200 rows the `FastScroll` thumb shows a chapter-number bubble with a `select` tick per 10 chapters.
3. **Gestures:** tap dives into the reader (Dive: the row's rect clip-reveals to full screen on `zoom`, the page behind scales to 0.94 and darkens, `reader.enter`); swipe right = Mark read / Mark unread, swipe left = Download / Remove download (coarse pointers only; desktop hover icons); long-press or right-click opens the row menu (Mark read, Mark unread, Download, Select; Select enters select mode with the row picked); hover or focus prefetches the manifest.
4. **Mark read and Mark unread** (the one contract; `features/library/mark-read.ts`): Mark read sends `POST /reader/progress/batch` rows `{source_id, series_key, chapter_key, chapter_number, last_page: max(page_count, 1), page_count: max(page_count, 1), scroll_offset_px: 0, is_completed: true, time_spent_seconds: 0, manual: true}` in chunks of 200; Mark unread sends `DELETE /reader/progress {source_id, series_key, chapter_keys[] ≤ 200}`. Never `POST /reader/progress`. Toasts "Marked 42 chapters read · Undo" (Undo deletes only the keys that were not completed before) and "Marked chapter 142 unread · Undo" (Undo re-posts the deleted rows, kept until the toast closes). Offline: disabled with "Needs a connection".
5. **Select mode** (DP2–DP5): row checks spring in from the left on `snappy` and the row slides right 36 px; selected rows get `iris600` at 14 %; already-saved rows are `aria-disabled="true"` with "Already on this device"; Shift-click, touch paint and `shift+x` select ranges; helper chips "Next 10", "All unread (n)", "All (n)", "None" (A5); the floating glass toolbar (phones the accessory slot; desktop fixed `bottom: 24px` centred in the window's right column, max 720) with "{n} selected · {k} already saved", "Download {n}", "Mark read", "Mark unread", "Done"; while running a liquid progress "Downloading 3 of 12" + Stop (`cancel-save` for the run); the summary toast ("12 chapters downloaded", "10 of 12 downloaded, 1 with missing pages, 1 failed", "Out of room: only 380 MB free. Remove some downloads and try again." with "Manage downloads" → `/downloads`). Without a profile the trigger shows the DP6 note "Downloads belong to a reading profile. Choose one to save chapters here." Semantics: `role="group"` `aria-label="Select chapters"`, rows `role="checkbox"`, Space and Enter toggle, a polite live region says "{n} selected".
6. **Chapter states:** chapters loading (8 row skeletons under the live header); chapters offline ("The chapter list needs a connection"; from downloads: downloaded chapters at full strength, the rest dimmed with "Needs a connection" and not activatable); chapters error (+ Try again); chapters unavailable ("Chapters didn't come through" / "This source lists 412 chapters but returned none just now; that is usually the source, not you." + Try again); no chapters ("No chapters yet" + "Back to source"); rate limited (the inline `warning` notice with the countdown).

### G. Signature moment, transitions, states and keys (§8.12)

1. **The cover lands:** the tapped or thrown poster flies into the cover slot on `zoom` carrying its velocity (the `web/29` `ViewTransition` pair on `coverTransitionName(sourceId, seriesKey)`); a hard throw opens at `large` (A1). Dismissing by a downward drag flies the cover back to its origin when the origin is still on screen, otherwise the sheet slides down on `dismiss` (k 385.5, c 39.27).
2. **Transitions:** in by Zoom (posters) or Push (links without a poster); out by the sheet drag; Dive into the reader from a row or Continue. Reduced motion: 200 ms cross-fades; the sheet fades with a 16 px translate over 150 ms and no recession.
3. **Screen states:** loading (skeleton: cover block, three title bars, two button capsules, 8 chapter rows; after 180 ms); offline (from cache and downloads, the "Offline" capsule); error (lens "Couldn't load this series" / "The source didn't answer." + Try again + Back to source); caught up (the disabled "All caught up"); not in library vs in library; follow pending ("Adding…"); follow feedback toasts with Undo; rate limited (inline notice); gate closed on a mature series (the lens "This isn't available on this profile" + "Back home", no title or cover).
4. **Keys:** `c` Continue, `a` Read all, `f` add or remove from library, `*` favourite, `n` newest/oldest, `/` go to chapter, `x` select, `d` downloads the focused chapter row, `shift+d` download next 10, Enter on a row opens it, `m` marks it read, `p` Previously on, `shift+t` Tags…, `shift+s` copies the share link, Esc closes the sheet (after closing any open menu or inner sheet first). `shift+r` (Recommend to…) arrives with `web/43`.

### H. Book page (§8.13; NB1–NB19)

1. **Presentation:** the same sheet, window and full page as §8.12. Desktop: the two-column window with the plate (180 × 260), title, byline, facts and actions in the sticky 320 px left column; the blurb, Previously on, More like this and Contents in the right column. Literata loads on this screen only (`fonts.ts`, `preload: false`).
2. **Header:** the book plate 144 × 208 (desktop 180 × 260, radius 6, a 1 px paper-edge highlight on the right side and a 2 px spine shadow on the left); the title in Literata 30/36, `opsz` 36, `wght` 560; the byline Literata italic 17 "by {author}"; a 56 px rule; the facts row `mono` 13 "412 chapters · ≈ 1.2 M words · ≈ 80 h · Ongoing" (`features/novels/book.ts`); the estimate note `caption1` "Length estimated from 12 chapters read so far"; genre tags up to 24 through A3; the blurb Literata 17/30, max 62 ch.
3. **Actions:** primary "Start reading" / "Continue reading · Ch 12" / "All caught up"; secondary "Add to library" / "In library"; "Download book" with the count of unsaved chapters in `mono` (hidden when all are saved or while a run goes; disabled without a profile); ⋯ (Previously on, Add to collection, Check for new chapters, Move to another source… (followed only)).
4. **Contents:** "Contents" Literata 22; the go-to field (`inputmode="decimal"`, Enter jumps to the first match, Esc clears; A4's match list "and 38 more", "Type a chapter number.", "No chapter 900 in this book."); the order `Segmented` "First → last" / "Last → first" (default first → last); "Pick chapters" (select mode with helpers "Next 10", "All unread", "Whole book"); the A4 window of 400 rows with "Show earlier chapters (212)" and "Show more chapters (400)"; TOC rows: a right-aligned Literata tabular ordinal in a 44 column ("·" when none), the title Literata 16 (read rows in `label3`, never dimmed by opacity), meta `caption1` "3.4k words · 14 min", "42 %" in `iris400` when reading, the §7.29 download control. The focused chapter (`?chapter=` or go-to) scrolls to centre on `camera` and runs **Row pulse** (`iris600` at 14 % fading over 900 ms; `aria-current="location"`).
5. **Signature moment, Book open:** on "Start reading" or "Continue reading", the plate rotates open on its spine (`rotateY` 0 → −78° on `page` k 146.0, c 24.17, `perspective: 900px`, `transform-origin` at the left edge) while a paper-coloured layer expands from the plate's rectangle to full screen, then the app navigates to the novel reader route (`/novels/:sourceId/:seriesKey/:chapterKey?page=`). Reduced motion: a 200 ms cross-fade.
6. **States:** as §8.12 with novel copy ("This book needs a connection to load", "Couldn't load this book", "Contents didn't come through", "No chapters yet: this source hasn't published any chapters for this book.").
7. **Keys:** as §8.12; `/` focuses the go-to field (no bare `g`).

### I. Checks

- Vitest for every section A helper.
- `frontend/e2e/glass/web-33-series.spec.ts` (Playwright against `next dev`, the Glass skin, fixtures under `frontend/e2e/fixtures/series/` reused from `web/11`): clicking a poster on `/library` at 390 × 844 pushes the series URL without a navigation (`performance.getEntriesByType("navigation").length` unchanged), the sheet opens at `medium`, browser back closes it and the library keeps its scroll; at 1440 × 900 the window is 960 wide with the left column sticky while the right column scrolls; a hard load of the series URL renders the full page; `/library/:followedId` renders the same screen with no redirect; the ⋯ menu opens with Enter and closes with Esc returning focus; Reading status writes `reading_status`; the tags sheet toggles a tag and a mocked failure springs the chip back with the toast; Move to another source sends `repoint` with `keep_old`; `x` enters select mode, "Next 10" picks ten unsaved rows, "Download {n}" starts saves, Stop cancels; Mark read sends only `POST /reader/progress/batch` with `manual: true`; `c`, `a`, `f`, `*`, `n`, `/`, `p`, `shift+t`, `shift+s` work; the book page's go-to field shows the three messages and jumps; every interactive element at 390 × 844 is at least 44 × 44; a mature series on a gate-closed profile opens the "This isn't available on this profile" lens.

## Out of scope here (owned by later steps; do not build)

- `web/35` and `web/36`: the readers (Dive and Book open land on whatever those ScreenIds render).
- `web/37`: the Audiobook button and sheet (`?sheet=audiobook`), "Voices for this book", the headphones badges and "Audio saved", the owner-only narration affordances.
- `web/41`: the `recap` screen and the recap offer on Continue (Continue dives directly here), More like this's `fallback=genres` path and the caught-up end card rail.
- `web/43`: the Circle row, Recommend to… (`shift+r`, `?sheet=recommend`), Hide from my Circle.
- Phones-only items: Save to Files (`?sheet=save-files`), Extract text, "Downloads run while the app is open".

## File layout

Follow the naming the earlier Glass screens used (`ls frontend/src/skins/glass/screens/`); if it differs from below, follow it and list the mapping in the report.

```
frontend/src/features/sources/genre-link.ts (+ .test.ts)                     A3
frontend/src/features/novels/toc-window.ts (+ .test.ts)                      A4
frontend/src/features/offline/use-chapter-picker.ts (+ test, only if A5 is missing)
frontend/src/skins/glass/screens/series/
  FeatureScreen.tsx  FeatureByFollowScreen.tsx  SeriesDetail.tsx  SeriesWindowLayout.tsx
  SeriesBand.tsx  SeriesHeader.tsx  OfficialLinks.tsx  SeriesActions.tsx  SeriesMenu.tsx
  TagsSheet.tsx  MoveSourceSheet.tsx  DownloadCard.tsx  PreviouslyOnRow.tsx  MoreLikeThis.tsx
  ChaptersSection.tsx  ChapterRow.tsx  ChapterSelectToolbar.tsx  SeriesStates.tsx
  BookPage.tsx  BookPlate.tsx  BookContents.tsx  TocRow.tsx  book-open.ts
  detent-from-throw.ts (+ test)  collapse.ts (+ test)  use-series-keys.ts
frontend/src/skins/glass/primitives/Sheet.tsx     only if C4 or B4 needs useSheetProgress() or material="contentThick"
frontend/src/skins/glass/index.ts                 remove feature and featureByFollow from PENDING
frontend/e2e/glass/web-33-series.spec.ts
docs/redesign/proof/web-33/                       plan.md, routes.txt, screenshots, report.md
```

The route files `frontend/src/app/(app)/sources/[sourceId]/series/[seriesKey]/page.tsx` and `frontend/src/app/(app)/library/[followedId]/page.tsx` stay thin. No CSS modules.

## Acceptance criteria

- [ ] `feature` and `featureByFollow` render in Glass and are gone from Glass `PENDING`; the completeness and boundary tests pass; nothing under `frontend/src/skins/cinematic/` changed.
- [ ] Phones: a sheet route opening at `medium` (or `large` after a hard throw), dragging to `large` with the collapsing header driven 1:1 by position, the page behind receding, closing by button, Esc, drag, backdrop and browser back; the covered page keeps its scroll.
- [ ] Desktop: the 960 px `materialThick` window with the 240 px band, the sticky 320 px left column and the scrolling right column; the covered page at scale 0.97, blur 8, 50 % brightness. Tablet: one column at full content width with a 280 px band.
- [ ] Hard load and deep link render the full page for both paths; a hard-loaded `?sheet=` opens over it and closes by replacing the URL.
- [ ] Every inventory row SD1–SD21, SS1–SS18, NB1–NB19 and DP1–DP7 has a Glass counterpart or a recorded reason it is absent on the web (list them in the report).
- [ ] The cover lands on `zoom` with the throw's velocity and flies back on dismiss when its origin is on screen; "Add to library" runs the follow ring with `follow.add`; Book open rotates the plate to −78° on `page` with the paper expanding from the plate.
- [ ] The ⋯ menu, the tags sheet with AI suggestions, Move to another source and Content rating behave per §8.12 with every state; Content rating shows only with the gate open.
- [ ] Mark read and Mark unread use only the batch and delete calls (network log); Undo removes only the keys that were not completed before.
- [ ] Select mode, the helpers, the toolbar, the running state, Stop and every summary toast work; saved rows are `aria-disabled` with "Already on this device".
- [ ] Chapters over 100 rows are virtualised; over 200 show the fast-scroll bubble; the book page windows 400 rows with the two "Show …" buttons; the focused chapter pulses once.
- [ ] Every screen and chapter state of sections F, G and H renders and is screenshotted.
- [ ] Keyboard: every key of G4 and H7 works; Esc closes inner layers before the sheet; the Single-key switch off disables the printable keys; focus moves to the sheet title on open and back to the trigger on close.
- [ ] Hit targets: at 390 × 844 every interactive element is at least 44 × 44 with 8 px between hit boxes.
- [ ] Reduced motion: Zoom, Dive and Book open are 200 ms cross-fades; the sheet fades with a 16 px translate and no recession; the letter reveal shows the full title at once; the follow ring and Row pulse motion are off (the pulse fill shows 900 ms, then goes).
- [ ] Solid glass and Increase Contrast render correctly on the band group, sheets, menus and the toolbar (screenshots).
- [ ] Budget: phone with the series sheet, a menu and a toast at 5 or fewer live glass elements; desktop with the window, a menu and a toast at 6 or fewer; no glass on rows, chips in rows or cards; at most the two page-level glass controls (split Continue and the secondary group) in the scrolling sheet.
- [ ] Per-skin difference: the Cinematic skin renders both series routes exactly as before (before and after screenshots).
- [ ] `npm run typecheck`, `npm run lint` (0 errors, 0 warnings), `npm run test` (at or above the floor plus the new tests), `npm run build` (0 errors, 0 warnings) and `node design/build.mjs --check` are green; `web-33-series.spec.ts` and every earlier Glass spec pass.

## Verification

**RAM guard (production shares this box).** Before every heavy command (a build, the vitest suite, `next dev`, a Playwright run) run `free -m` and read the `available` column of the `Mem:` row. If it is under 1024 MB, stop and report instead of running it. Never run two builds at once, and never run `next build` while `next dev` or a Playwright browser is running.

From `frontend/`:

```bash
free -m && npm run typecheck
free -m && npm run lint
free -m && npm run test
free -m && npm run build
cd .. && node design/build.mjs --check && cd frontend
```

Dev stack as `backend/scripts/README-dev-stack.md` says (uvicorn 127.0.0.1:8010, the dev SQLite, never production data); export `MM_PROOF_USER` and `MM_PROOF_PASSWORD` from its demo account; then:

```bash
free -m && NEXT_PUBLIC_API_URL=/api BACKEND_INTERNAL_URL=http://127.0.0.1:8010 npm run dev -- --port 3010
# second shell
free -m && E2E_BASE_URL=http://127.0.0.1:3010 E2E_USERNAME=$MM_PROOF_USER E2E_PASSWORD=$MM_PROOF_PASSWORD npx playwright test e2e/glass/web-33-series.spec.ts --workers=1
free -m && E2E_BASE_URL=http://127.0.0.1:3010 E2E_USERNAME=$MM_PROOF_USER E2E_PASSWORD=$MM_PROOF_PASSWORD npx playwright test e2e/glass --workers=1
```

**Visual proof** with `frontend/scripts/proof.mjs` (run `node scripts/proof.mjs --help` first), headless Chromium, named session `web-33`, at 1440 × 900 and 390 × 844:

```bash
free -m && node scripts/proof.mjs --step web-33 --skin glass --session web-33 --routes docs/redesign/proof/web-33/routes.txt
free -m && node scripts/proof.mjs --step web-33/reduced --skin glass --session web-33 --reduced --routes <manga series path>,<novel series path>
free -m && node scripts/proof.mjs --step web-33/cinematic --skin cinematic --session web-33 --routes <manga series path>,<novel series path>
```

`routes.txt` holds the hard-load forms: a followed manga series (`/library/<id>`), the same series by source path, `?sheet=tags`, `?sheet=move-source`, `?sheet=image`, a manga series with more than 200 chapters, a novel series, a novel series with `?chapter=<key>`, an unknown series key (the unavailable lens). The sheet and window forms need interaction: in a scratch Playwright script under your scratchpad that imports `signIn` from `scripts/proof.mjs`, capture into `docs/redesign/proof/web-33/states/`: `sheet-medium-phone.png`, `sheet-large-collapsed-phone.png`, `sheet-mid-drag-phone.png`, `window-desktop.png`, `window-scrolled-desktop.png` (left column still in place), `tablet-768.png`, `cover-landing-mid-desktop.png`, `follow-ring-desktop.png`, `menu-desktop.png`, `select-mode-phone.png`, `select-running-desktop.png`, `summary-toast-phone.png`, `chapter-context-menu-phone.png`, `swipe-row-phone.png`, `book-page-desktop.png`, `book-page-phone.png`, `book-open-mid-desktop.png`, `toc-pulse-desktop.png`, and every state of G3 and F6 (`<state>-{desktop,phone}.png`), plus `window-solid-desktop.png` and `window-contrast-desktop.png` (init script setting `document.documentElement.dataset.solid = "on"` or `dataset.contrast = "more"` on `DOMContentLoaded`). If you use `playwright-cli`, pass `-s=web-33`. Write `docs/redesign/proof/web-33/report.md` mapping each screenshot to the acceptance item it proves. Stop `next dev` when done.

`00-baseline.md` records lint and build at 0 errors and 0 warnings; keep them there. This step changes nothing in `mobile/` or `backend/`: check each of your commits with `git show --stat --format= <hash>` (the parallel `mobile/NN` session and the backend and shared sessions commit `mobile/` and `backend/` on the same branch, so never judge by the branch diff). If one of your commits touched them, revert that part and prove the baseline with `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter analyze` (No issues found), `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter test` (all 2012 tests pass, or the current higher count) and `cd backend && .venv/bin/python -m pytest -q --no-header`, one at a time after the RAM guard.

## Git

- Branch `feat/vps-slim-source-native`. Commit small and often: the plan; each section A helper with its test; presentation and routing; band and header; actions and the ⋯ sheets; chapters and select mode; the book page; the e2e spec; the proof. Example: `feat(web-glass): series detail sheet with the cover landing and collapsing header`.
- Stage explicit paths only, never `git add -A` or `git add .`: the mobile, backend and shared sessions commit in the same checkout.
- No Claude or AI attribution anywhere: no `Co-Authored-By` line, no "Generated with" line, no AI author. Never commit real credentials or secrets (the dev-stack demo password is committed only in `backend/scripts/README-dev-stack.md` by `backend/00`; never copy it into a spec, script or proof file), `.env*` or `.claude/`.
- Run `npm run build` (after `free -m`, with `next dev` stopped) before every push, then `git push origin feat/vps-slim-source-native` after each working step.
- Never edit `backend/connectors/`. Never touch production containers or `/srv/manhwamaniacs/{app,data}`. Do not deploy: Glass stays behind the debug row until `release/01`.

## Report back

Reply with:

1. Done items by section (A1–A5, B1–B7, C1–C5, D1–D6, E1–E5, F1–F6, G1–G4, H1–H7, I), each with its commit hash; anything not done with the reason and its `glass/DESIGN.md` section.
2. The inventory map: each SD, SS, NB and DP row → the Glass element, or "absent on the web" with the reason.
3. Any primitive you extended (`Sheet.tsx` `useSheetProgress()` or `material="contentThick"`) and why.
4. The screenshot folder `docs/redesign/proof/web-33/` and its file list.
5. Test counts: vitest files and cases before and after; each Playwright spec's result; lint, build and `build.mjs --check` results; the lowest `free -m` available figure.
6. The live glass counts measured on phone and desktop, and the motion-timings figures for Zoom, Sheet present, Sheet snap, Recede, Follow ring, Dive and Book open (any raster-only cost listed for the owner's hardware check).
7. Open issues, each with its `glass/DESIGN.md` section.

Next prompt file: `docs/redesign/prompts/web/34-reader-engine-glass-commands.md` (`docs/redesign/prompts/mobile/33-glass-series-and-book.md` runs in parallel).
