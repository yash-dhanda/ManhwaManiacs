# Web Cinematic manga reader 1: strip, chrome, ruler, credits

Track: web · Order 41 · Depends on: `docs/redesign/prompts/web/11-cinematic-feature-and-book-pages.md` · Proof folder: `docs/redesign/proof/web-12/`

## Goal

Build the Cinematic manga reader's first half on the web client: the Reader frame, the Column wipe and Dip entries, the running head and folio bar over their scrims, the ruler scrubber, the webtoon strip (the default layout) with its seams, bands, zoom and gestures, the chapter-end credits with the Coming up card and pull to continue, the end-of-series notices, every reader state, the left "Contents" panel and sheet, the reader keys and escape order, and the `/reader` landing notice. Everything is chrome built on the shared reader engine that `web/03` extracted (`useReaderEngine()` and its `renderChrome(state)` slot in `frontend/src/features/reader/`); the engine keeps owning the page layer, restore, extents, prefetch, progress and the next-chapter auto-queue. This step also adds two skin-neutral engine commands that both skins need, `pinchZoom` and `zoomAt` (glass §15.4 commit order step 2), and a skin-neutral reader-preferences record with read-time migration of the legacy keys. When you finish, the ScreenIds `reader` and `readerLanding` leave the Cinematic `PENDING` set, and both ways into the chapter reader (the followed-series page and the source series page) are proven with screenshots. The paged layouts, read-all, the Reading setup sheet, the right "Margins" panel and page actions are the next step (`web/13`); the ambient extras (guided view, page tint, soundscape, the auto-scroll chip) are `web/23`.

## Read first

Read these completely before planning. Where this file and `cinematic/DESIGN.md` disagree, `cinematic/DESIGN.md` wins; say so in the report.

1. `docs/redesign/inventory/00-decisions.md` (all of it: binding owner decisions, dark AMOLED only, "Manhwa: Webtoon app (vertical scroll, auto-hide chrome, next-chapter card)").
2. `docs/redesign/stack-decision.md` §2.2 (web folder layout and the lint boundary), §2.6 (one data layer), §4 risks 6 and 11 (reader regression, dev-box memory).
3. `docs/redesign/cinematic/DESIGN.md`:
   - §1 Manifesto; §2.1.1 (the raised-stock scope `data-stock="raised"`), §2.1.4 (scrims and the over-art rule), §2.1.6 (manga reader grounds), §2.2.2 (horizontal safe areas), §2.4 (z layers), §2.7 (icons), §2.8.3 (`scrim-head`, `scrim-sole` utilities and `--scrim-base`), §2.8.4 (motion tokens), §3.2 (type roles).
   - §4.1–§4.8 (motion principles, durations, curves, springs, the motion table rows Dip, Column wipe, Rise, Panel, Folio flip, Credits, Rule slide; stagger; interruptibility; reduced motion).
   - §5 (haptic events `reader.enter`, `page.turn`, `scrub.tick`, `scrub.boundary`, `chapter.complete`, `chapter.next`, `autoscroll.toggle`, `autoscroll.step`, `autoscroll.end`, `zoom.snap`, `bookmark.add`, `longpress.open`; the web maps only five events to `navigator.vibrate`) and §6 (cues `wipe`, `done`, `turn`, `tick`, `set`).
   - §7 intro (hit areas, heights are minimums, focus ring, cursors including the reader cursor rules), §7.1, §7.2, §7.9, §7.10 (arm delay), §7.11 (the "Reader and Page frames" row), §7.13, §7.16 (schedule rows), §7.17, §7.18 (micro progress, leader dial, download mark, folio counter), §7.19, §7.20, §7.23, §7.24 (rating card), §7.29 (`folioLabel()`).
   - §8.0.1 (Reader frame), §8.0.3 (rows `reader` and `readerLanding`, encoded route builders), §8.0.4, §8.0.5 (web columns: long-press on images, edge swipes, scroll physics), §8.0.6 (`g` sequence disabled inside readers), §8.0.10.
   - §8.14 intro, §8.14.1 to §8.14.6, §8.14.9, §8.14.10, §8.14.11, §8.14.12 (the left "Contents" panel, the panel motion and the narrow-desktop rule).
   - §8.32 (the Reader landing row), §9.1.4 and §9.1.6 (Up next and its fallbacks), §10.1.2 (the credits end title is a Letter set), §10.2.2 (the pull-to-continue caption is typed).
   - §11 (every row whose Screens column says Reader, strip or manga strip, and the precedence rules above the table).
   - §14.1, §14.4, §14.5, §14.6, §14.10; §15.4 (engine seam), §15.6 (performance guards and the sources request limiter), §15.7, §15.9 (motion-timings overlay), §15.10 rows S1 and S11 and "Owner calls".
4. `docs/redesign/glass/DESIGN.md` §15.4 (the command table rows `pinchZoom` / `zoomAt` and `jumpToPage`, and the commit order; both commands land in this step for both skins).
5. `docs/redesign/inventory/web.md` §1 (routes R18, R19), §2.9 (the 19 reader bindings), §9 (RD1–RD42 and the notes under the tables: local position memory, gestures today), §18.6 (A65–A73), §19.3 (K29–K39, K46, K47).
6. `docs/redesign/inventory/capabilities.md` §1 (rate limits and the 60/min sources bucket, 18+ absence, identity and percent-encoding), §13 (manifest and progress, `advanced: false`), §15 (bookmarks), §24, §25.
7. `docs/redesign/00-baseline.md` (the green baseline you must keep).
8. Code you build on: `frontend/src/features/reader/` (the engine hook `web/03` created: find it with `grep -rn "export function useReaderEngine" frontend/src/features/reader`, then read it and its tests in full), `frontend/src/skins/types.ts`, `frontend/src/skins/cinematic/index.ts` (the `PENDING` map), `frontend/src/skins/cinematic/primitives/`, `frontend/src/skins/cinematic/motion.ts` (`play()`, `ColumnWipe`, `SetHeading`, `TypedHeadline`), `frontend/src/skins/cinematic/Shell.tsx`, `frontend/src/skins/cinematic/screens/` (the file naming `web/08`–`web/11` used), `frontend/src/features/bookmarks/hooks.ts`, `frontend/src/features/offline/`, `frontend/src/features/sources/` (the request limiter), `frontend/src/lib/keyboard/`, `frontend/scripts/proof.mjs`.

## Preconditions (check before writing the plan)

- `git log --oneline -15` shows the `web/11` work; `npm run test` in `frontend/` is green before you touch anything (record the file and case counts; they are your floor).
- `frontend/src/skins/cinematic/index.ts` still lists `reader` and `readerLanding` in `PENDING`.
- **Record the S1 and S11 sign-off first.** `cinematic/DESIGN.md` §15.10 marks S1 (per-page tint on the client) and S11 (panel detection on the client) "sign-off before the reader cluster", and its "Owner calls" paragraph decides both. Run `grep -n "^S1 \|^S11 " docs/redesign/signoffs.md` (the one record, owned by `backend/06`, which runs first and writes the `S1 …`, `S11 …`, `G6 …` and `G14 …` lines; a grep over all of `docs/redesign` would also match the prompt files). If no file records the sign-off yet, create `docs/redesign/signoffs.md` with one line each: `S1 — per-page tint computed on the client, backend caches client reports (cinematic §15.10 owner call) — recorded 2026-MM-DD by web/12` and the same for S11 (panel detection), and commit it as its own commit before any code. If a record exists (for example from `backend/06`), cite it in the report and change nothing.

## Skills to invoke

1. `superpowers:writing-plans` before any code: write the plan to `docs/redesign/proof/web-12/plan.md` (it is a working file for this step; commit it with the proof).
2. `superpowers:test-driven-development` for every engine and preference change in `features/reader/` (write the vitest first).
3. `superpowers:subagent-driven-development` to run the plan (or `superpowers:executing-plans` if you execute inline). At most 6 implementer subagents, one at a time for anything that runs a build or a test suite; verify each subagent's work against `git status` and `git diff`, never against its report alone.
4. `frontend-design:frontend-design`, `impeccable:impeccable` and `taste-skill:taste-skill` while building and reviewing the chrome (the reader is where Programme "gets out of the way": two thin bands of type over scrims, no serif on screen while reading, no rounded corners, no shadows).
5. `superpowers:verification-before-completion` before you claim anything is done.

## Scope: deliver every item below

Values are copied from `cinematic/DESIGN.md`; the section is cited so you can check the context. Tokens are written as token names; use the generated custom properties and utilities (`--mm-…`, `type-…`, `duration-(--mm-dur-…)`, `ease-settle`), never literals, except where a value below is a behaviour timing that §4.2 keeps literal.

### A. Skin-neutral engine and data work (`frontend/src/features/reader/`, no pixels)

A1. **`pinchZoom(focal, scale, velocity, opts)` and `zoomAt(point, scale, transition)`** on the engine (glass §15.4; cinematic §8.14.5). `focal` and `point` are viewport coordinates; `opts = { min, max, snapStep | null, rubberBand: boolean }`; `transition` is a Motion transition object (`{ duration, ease }` or `{ type: "spring", visualDuration, bounce }`) so Glass can pass springs and Cinematic passes `{ duration: 0.24, ease: [0.16, 1, 0.3, 1] }` (`dur.line`, `ease.settle`). The focal content point stays under the finger or pointer while the strip width scales (the scroll offset is corrected in the same frame, horizontal overflow pans). Past the limits the scale rubber-bands with `d·(1 − 1/(x·0.35/d + 1))` (§4.4) and settles back on release. Put the pure math in `frontend/src/features/reader/zoom.ts` (`focalScroll(scrollTop, focalY, oldScale, newScale)`, the horizontal equivalent, `clampZoom`, `snapZoom(value, 0.1)`, `rubberBand(x, d, 0.35)`) with `zoom.test.ts` covering: the focal point stays fixed within 0.5 px for scale 1 → 2 and 2 → 0.5, snapping 1.26 → 1.3, clamping to 0.5–3.0, the rubber band at x = 0 and x = d.
A2. **`onChapterCompleted(listener)`** (cinematic §15.4 "completion events"): fires once per chapter per open, at the moment the engine marks the chapter complete (last page scrolled up past 60 % of the viewport, or the ruler dragged to the end). If `web/03` already exposes it, reuse it.
A3. **`furtherElsewhere`** in engine state: when a `POST /reader/progress` answer has `advanced: false`, the server's progress row (`chapter_key`, `chapter_number`, `last_page`) so the skin can offer the jump toast (§8.14.6). Cleared on the next advancing save.
A4. **Page-level render slots: extend `web/03`'s `ReaderSurfaceSlots`, never add a parallel slot set.** `web/03` (A2) made every in-strip decoration a slot on one `slots` object in `features/reader/engine/`: `loading()`, `error(message, retry)`, `empty()`, `chapterDivider(chapter)`, `head(edge, loadPrevious)`, `tail(edge, retryNext)`, `pagePlaceholder(page)` and `brokenPage(page, retry)`. The Cinematic skin fills them as follows: the seam band (I2) is `chapterDivider`; the top band (I3) is `head`; the next-chapter band (I12), the next-failed notice (K4) and the offline end ("Next chapter isn't saved on this device") are `tail`, whose `StripEdge` argument you extend with `state: "loading" | "failed" | "offline" | "rateLimited"` and `retryInMs` where it lacks them; the page placeholder and broken page (section L) are `pagePlaceholder` and `brokenPage`, the latter extended with an optional `reason`. Add only these, each optional, skin-neutral and typed in the same interface: `rateLimited(retryInMs)` (the `SLOW DOWN` band above the unloaded pages), `credits({ chapter, next, mode: "compact" | "full" })` placed after a chapter's last page, and the presentation props `ground` (hex), `gapPx` (0 or 8), `columnWidth` (CSS length), `sideMarginPct` (0–25), `pageFilter` (`none | sepia | grey`). The legacy slot object keeps rendering today's markup for every slot it already had and returns `null` for the new ones. Each new slot argument or prop gets a vitest proving the engine passes the right values (pure-logic tests; the vitest environment is `node` and only `src/**/*.test.ts` runs).
A5. **Reader preferences record** in `frontend/src/features/reader/reader-prefs.ts` (+ `reader-prefs.test.ts`). Extend, do not replace, the stored records the DESIGN names (§8.14.8): per series the profile-scoped `mm.reader-preferences[{source}:{series}]`, per profile the scoped `mm.reader-settings`, per device plain `localStorage` keys prefixed `mm.reader.device.`. Add optional fields; make `normalizeReaderPreferences` and the settings normaliser keep unknown fields so the legacy skin never strips them; legacy fields keep their meaning so the legacy reader still works. New fields and their read-time fallbacks from the legacy keys (formulas from §8.14.8):
   - `layout` (`STRIP | SINGLE | DOUBLE | GUIDED`) ← `readingMode` (`continuous` → `STRIP`, `single` → `SINGLE`, `double` → `DOUBLE`); `direction` and `fitMode` and `zoom` unchanged (web K36–K38).
   - `autoScrollSpeedX` 0.50–3.00 step 0.05 ← web K39 level: `px = 20 + (level − 1) × 200 / 9`, `speed = clamp(px / 60, 0.50, 3.00)` rounded to 0.05 (level 1 → 0.50×, 5 → 1.80×, 10 → 3.00×).
   - `brightness` −75…0 ← web K31: `v = −round(min(dimmer, 0.75) × 100)`; `warmthPct` 0–100 ← web K32: `v = round(warmth / 0.7 × 100)`.
   - `pageTurn` (`CUT | SLIDE | FADE`) ← web K33 (`false` → `CUT`, `true` → `SLIDE`); `tapZones` unchanged (web K34; `retreat`/`toggle`/`advance` are PREVIOUS/MENU/NEXT).
   - New with defaults: `sideMarginPct` 0 (per profile), `stripWidthPx` null = `clamp(480px, 46vw, 860px)` (per device, 480–860 step 20), `colour` `NORMAL`, `ground` `BLACK`, `stripTaps` `MENU`, `swipeChapter` true (phones), `autoNextChapter` true, `resumeAfterRelease` true, `panels` `{ left: false, right: false, lastOpened: null }` (per profile).
   - Tests: every formula above at its end points and one middle value, unknown-field preservation through a legacy write, and per-profile isolation through `scoped-storage.ts`.
A6. **Auto-scroll speed in engine units** (§8.14.8 AMBIENT, §9.4.1 "Speed"): `pxPerSecond = 60 × speed × viewportHeight / 1080`. Add `autoScrollPxPerSecondX(speed, viewportHeight)` beside today's `autoScrollPxPerSecond` in `auto-scroll.ts` with a test (844 px viewport at 1.00× = 46.9 px/s). The engine's auto-scroll uses it when the Cinematic skin passes `speedX`; the legacy path is unchanged.
A7. **Time left** `frontend/src/features/reader/time-left.ts` (+ test): minutes left = remaining pages ÷ pages per minute measured by `reading-clock.ts`, returned as `null` until 2 minutes of pace samples exist (§8.14.3 "shown only after 2 minutes of pace samples").
A8. **Chapter download state.** If the per-chapter download logic still lives in `features/offline/components/DownloadChapterControl.tsx`, move it first into `frontend/src/features/offline/use-chapter-download.ts` in a no-pixel commit (stack-decision §2.3 "logic that lives in a widget moves first"); the legacy control then calls the hook. If `web/11` already extracted it, reuse it.

### B. Routes and screens

B1. ScreenId `reader`: `/reader/:sourceId/:seriesKey/:chapterKey` with `?page&at&all` (§8.0.3; the existing web route folder is `app/(app)/reader/[sourceId]/[seriesKey]/[...chapterKey]/`, keep the catch-all because keys may contain `/`). Decode each segment exactly once; build every reader, series and chapter link with the generated encoded route builders from `contract.generated.ts`, never by concatenation.
B2. ScreenId `readerLanding`: `/reader` with no params (§8.32): the §7.23 notice, kicker `READER`, typed headline "Open a series to start reading.", primary `Go to library` → `/library`.
B3. Frame (§8.0.1): no app chrome (the Shell hides the sidebar, running head, thumb index, first-run note and stop-press banner on reader routes); the reader's own running head and folio bar; toasts use the reader-frame placement of §7.11 (bottom-centre, max 560, 16 px above the highest bottom element that is showing, 24 px above the bottom edge when the chrome is hidden, never over the ruler).

### C. Frame and layout (§8.14.1)

C1. Desktop (≥ 1024): canvas in the chosen ground (Black `#000000` default, Ink `#0B0B0A`, Slate `#1A1A18`, §2.1.6); strip column `clamp(480px, 46vw, 860px)` centred, or the per-device `stripWidthPx`; page images requested at the snapped width ≥ column × DPR (800 px sources pass through) through `page-url.ts`.
C2. Tablet (768–1023): strip column 100 % up to 720 px, centred; the Contents panel opens as a column panel over the page (it does not push the strip).
C3. Phone (< 768): strip edge to edge; side margin preset 0 / 5 / 10 / 15 / 20 / 25 % (default 0) from `sideMarginPct`.
C4. Landscape phone (height < 500 px): strip column 70 % of the width, centred inside the safe rectangle (§2.2.2: side margin max(grid margin, `env(safe-area-inset-left)` + 8 px), no chrome control inside an inset); running head and folio bar hidden at rest and shown together on a centre tap; the running head keeps its portrait height (44 + the top inset) with back plus the trailing buttons.
C5. Mood gutters: outside the strip on desktop the gutters take the ground colour (the page-tint gutters are `web/23`); the profile's mood grade never reaches the reader.
C6. When the ground is Ink or Slate, every band painted on it (seam, top band, next-loading band) carries `data-stock="raised"` so `ink.45` roles render `ink.60` (§2.1.1).
C7. No grain, blur, drift or backdrop effects over pages (§15.6); the chrome is gradients and text only.

### D. Entry and exit (§8.14.2, §8.0.4)

D1. **Column wipe** when the reader is entered from Tonight (the cover story's `Continue`, a cutting, a rail's Quick look `Continue`), from a feature or book page (`Read`, `Continue`, `Read all`, a chapter row, `Listen`), or from a recap opened from those two places. Use the `ColumnWipe` overlay from `motion.ts` (`web/06`); if the entry controls built in `web/08` and `web/11` do not yet route through it, wire them now through `web/06`'s one helper `enterReader(href, { entry: "wipe" | "dip", prefetch })` (`frontend/src/skins/cinematic/shell/reader-entry.ts`, re-exported by `motion.ts`). Never add a second entry helper (no `openReader`).
   - Close: the viewport is divided into the current grid's columns including gutters and margins, 4 blades on phones, 8 on tablets, 12 on desktop, blade edges on column edges; each blade is a `#000` strip scaling `scaleY 0 → 1` from the top edge, 200 ms (`dur.wipe.close`) `ease.settle`, staggered 16 ms left → right (desktop 376 ms, tablet 312 ms, phone 248 ms).
   - Hold on black 40 ms (`dur.hold.dip`); the route swaps underneath; sound `wipe` if UI sounds are on; the web maps `reader.enter` to no vibration.
   - Open: blades retract `scaleY 1 → 0` toward the bottom edge, 280 ms (`dur.wipe.open`) `ease.settle`, staggered 16 ms (desktop 456, tablet 392, phone 328 ms). Totals 872 / 744 / 616 ms.
   - The running head and folio bar are visible for the first 800 ms, then follow auto-hide. For a series whose resolved `rating` is `mature` the rating card (§7.24, host from `web/07`) appears at the start.
   - A tap, click or key during the wipe jumps to the open state in 120 ms (`dur.snap`). If the first page is not decoded after the hold, the blades still open onto its galley plate.
   - Blades animate `transform` only, in a fixed overlay at `z.shutter` (80), through `play("column-wipe")` so the motion-timings overlay logs it.
   - Reduced motion: a 200 ms (`dur.clip`) cross-fade through black.
D2. **Dip** (out 160 ms `ease.lift`, hold 40 ms, in 240 ms `ease.settle`, 440 ms total) for entries from History, Bookmarks, Updates, Downloads, Library cuttings, dialogue results, Circle, the command palette and deep links, for a chapter picked in Contents, and for every exit. Reduced motion: 150 ms (`dur.reduced`) opacity cross-fade.
D3. Never a wipe between chapters inside the reader (seam, pull-to-continue fade, or Dip for a Contents pick).
D4. **Back target** (§8.14.2, web form): the running-head back button, `Esc` at the end of the escape order and `s` all leave by Dip. When the previous history entry is inside the app (track an in-app navigation depth in the shell's state, because `history.length` includes other sites), go back; otherwise `router.push` the series page (`/sources/:sourceId/series/:seriesKey`) with the Dip. Browser back (popstate) carries no transition type and gets none (§8.0.4).
D5. Prefetch on entry is the entry controls' job (150 ms dwell, P3 in the limiter, `web/08`/`web/11`); verify it still happens and that the manifest and first two pages are usually decoded during the hold.

### E. Running head (§8.14.3, §7.13)

E1. Positioned over `scrim-head` (`before:scrim-head` on the bar with `isolation: isolate`, `--scrim-fade` 44 px on the phone frame and 64 px from 768 px); height 56 px desktop; phones min 44 px + `env(safe-area-inset-top)`, growing to the title line + 2 × 12 px at large text.
E2. Leading: back, `arrow-left` 24 Light, `bare` icon button, tooltip and `aria-label` "Back to the series".
E3. Title group, two separate targets: the series title in `type-nav` `ink.60` (a link to the feature page, hover `ink.100`), then ` · `, then the chapter folio `CH 142` in `type-folio` `spot` followed by a 12 px `caret-down`. The folio is its own hit area (44 px on coarse pointers, 32 px on fine), tooltip "Contents", and opens Contents (G below). Spoken labels through `folioLabel()` ("Chapter 142").
E4. Trailing, in this order: the chapter download mark (§7.18 states; tap cycles `Download` → saving `12/40 · 30%` with cancel → `SAVED`; tapping `SAVED` asks inline "Remove from this device?" with the 1000 ms arm of §7.10 and reverts after 4 s untouched; warn states `Save again` (stale) and `Resume 12/40` (incomplete)); bookmark (`bookmark-simple`; Fill plus the 2 px `spot` rule 4 px under the square when the current page is bookmarked); on tablets and desktop `sidebar-simple` (toggles the Contents panel, the only trigger on tablets). The settings button (`sliders-horizontal`), the `note-pencil` Margins toggle, the page-actions `dots-three` and the guided-view `panel-focus` button are added by `web/13` and `web/23`; leave the trailing buttons as an ordered array so those steps insert theirs without restructuring. The final order (§8.14.3) is: download, bookmark, guided view (`web/23`), `sidebar-simple` (tablets and desktop), `note-pencil` (tablets and desktop, `web/13`), settings (`web/13`), `dots-three` (tablets and desktop, `web/13`). The soundscape `waveform` is not a trailing button: `web/23` puts it in the title group after the folio's `caret-down`. At most four trailing buttons on phones: download, bookmark, guided view when ready, settings.
E5. `OFFLINE EDITION` micro badge (`type-micro`, 1 px outline, `#000000` fill) beside the title when the chapter is read from disk.
E6. `LOADING CH 142` replaces the folio while the chapter manifest loads.

### F. Folio bar, ruler and micro progress (§8.14.3, §8.14.4)

F1. Folio bar over `scrim-sole` (`--scrim-fade` 64 px), min 64 px + `env(safe-area-inset-bottom)`, positioned `absolute` inside the chrome overlay so its `::before` sizes against the bar; at text scale ≥ 1.5 (browser font size) the time-left caption moves to a second line and the bar grows.
F2. Left: previous chapter, `skip-back` + folio `141`; disabled at the first chapter (`aria-disabled`, tooltip "This is the first chapter"); in the strip it scrolls to the loaded previous chapter instead of navigating.
F3. Centre: the ruler, full width between the chapter buttons:
   - track 2 px `rule.2`; played part `ink.100`;
   - page ticks 1 × 4 px `ink.30` under the track per page, dropped above 120 pages;
   - bookmarks: 2 × 8 px `spot` marks standing above the track at their positions (from the engine's bookmark list);
   - thumb: a 2 × 16 px `ink.100` tick, 3 × 24 while dragging, with a folio flag above it reading `p. 18` (the folio-flag ground: `#000000` box, 1 px `ink.100` border, 4 × 8 px padding);
   - desktop hover: a 120 px-wide page preview above the pointer from the cached page image, captioned `p. 18 / 40`;
   - hit area 44 px tall on coarse pointers; dragging seeks live through the engine; release settles the thumb with `spring.scrub` (`{ type: "spring", visualDuration: 0.24, bounce: 0 }`); direction mirrors for RTL series;
   - a native `input type="range"` underneath carries focus and keys: `aria-valuetext="Page 18 of 40"`, arrows step one page, `Shift`+arrow ten; disabled for single-page chapters;
   - cursor `pointer` on the track, `grabbing` while scrubbing (§7 intro).
F4. Under the ruler, one line: `07 / 40` (`type-folio-lg`, a button: click or `g` turns it into a number field; Enter jumps through `jumpToPage`, Esc cancels and returns focus) · `6 MIN LEFT` (`type-caption` `ink.60`, from A7, absent until available) · the chapter title in `type-caption` (desktop only).
F5. Right: next chapter (`143` + `skip-forward`); auto-scroll (`play` with the `strip-scroll` custom glyph, strip only; Fill plus the `spot` rule and the speed folio `1.0×` while running); desktop fullscreen (`corners-out`, `corners-in` while fullscreen, rendered only when `document.fullscreenEnabled`).
F6. Micro progress: a 2 px `spot` rule at the very bottom of the screen showing chapter progress while the chrome is hidden; absent in cinema mode.
F7. Toasts and bands never sit under the ruler.

### G. Contents (§8.14.3 title group, §8.14.12 left panel)

G1. One `ContentsList` component: the chapter list as schedule rows (§7.16: number in `type-folio-lg` right-aligned in a 56 px column, `·` for a null number, decimals as-is; title in `type-title`; caption with release date and page count; `14/27` in `spot` when in progress, `READ` micro with the row dimmed to `ink.45` when complete; the §7.18 download mark), the current chapter on a `spot.wash` band with the 2 px `spot` left bar and `aria-current="location"`, pre-scrolled to centre, the `NEWEST │ OLDEST` segmented toggle (Rule slide), and a go-to field ("Chapter number", decimal keyboard, Enter jumps to the first match).
G2. Phones: a `[0.5, 0.92]` sheet (§7.9 Rise, the `Done` quiet button, drag to dismiss) opened by the chapter folio; a tap on a chapter jumps by Dip.
G3. Tablets and desktop: the left side panel "Contents", 3 columns (min 320 px), `paper.0` with a 1 px `rule.1` inner edge, slides in 320 ms `ease.settle` (the Panel move; out 224 ms `ease.lift`), and on desktop the strip recentres in the remaining columns in 320 ms `ease.turn` (never overlapping); on tablets it opens over the page. Toggled by the chapter folio, `sidebar-simple` and `[`; its open state is remembered per profile (`panels.left`). Build the panel slot layout (`SidePanelLayout`) with a right slot that `web/13` fills, and the narrow-desktop rule: if the viewport minus 2 × the grid margin minus the open panels would leave the strip under 480 px, opening a panel closes the other one (last opened wins).
G4. Reduced motion: the panel fades in place in 150 ms (`dur.reduced`) and the strip recentres at once.

### H. Auto-hide, cinema and focus (§8.14.3, §14.4, §14.5)

H1. Hide after a cumulative downward scroll ≥ 24 px since the last direction change; show after a cumulative upward scroll ≥ 56 px, at chapter end, on a centre tap, on pointer movement into the top 72 px or bottom 96 px (desktop), on `g`, `[`, `?`, or on focus entering the chrome (`Tab`/`Shift+Tab`). Every other reader key never reveals the chrome. Reuse the engine's thresholds (`chrome-autohide.ts`), do not re-implement them.
H2. While focus is inside the chrome (`:focus-within` on the chrome container) auto-hide is suspended (no scroll hide and no idle hide). When `m`, `c` or a click on the page hides the chrome while it holds focus, focus moves first to the reading region.
H3. After a tap or hover opened the chrome, hide after 3000 ms idle (paused while a sheet, menu or the ruler is in use). Never hide during the first 800 ms of a chapter.
H4. Motion: in 240 ms (`dur.line`) `ease.settle` as a fade plus an 8 px slide from its edge; out 160 ms (`dur.beat`) `ease.lift`. Hidden chrome is `visibility: hidden` so it leaves the tab order. Reduced motion: fade only, same durations.
H5. Cinema mode (`c`, and the setting `cinema` from A5): the chrome hides after 3000 ms idle (never while focus is inside it) and the micro progress disappears; a tap, pointer move or `c` brings the chrome back; `Esc` leaves cinema before leaving the reader.
H6. The cursor hides (`cursor: none`) after 3000 ms without pointer movement while the chrome is hidden, and returns on the next move.
H7. The reading region is a focusable `role="region"` with `tabIndex={-1}` and `aria-label="Chapter 143, page 1 of 40"` that receives focus on entry; a polite live region announces "Chapter 143, The Return · Solo Leveling" on entry and on every chapter change (drop the middle part when the chapter has no title), never page changes. Each page image has `alt="Page 18 of 40"`. OCR page descriptions are not fetched on the web, because a screen reader cannot be detected there (§14.5).

### I. Strip mode (§8.14.5)

I1. Pages seamless, no gap (the `gapPx` 8 px of ground when "Gap between pages" is on), no radius, no shadow; each page reserves its exact box from the manifest `width`/`height` before the image lands (fallback 2:3 until decoded), with the engine's scroll compensation so the page under the reader never jumps.
I2. **Chapter seam** (continuous feed): a 96 px band of ground with 1 px `rule.1` rules either side of `CH 143 · THE RETURN` in `type-kicker` `ink.45`; crossing it fires `scrub.boundary` (sound `tick` if on).
I3. **Top band** when a previous chapter exists: a slim band `↑ CH 141 · keep scrolling up`; loading state `Loading CH 141…` with a 16 px leader dial; over-scrolling up 140 px loads it (wheel and touch).
I4. **Zoom**: pinch clamps to 0.5–3.0× and snaps to 0.1 steps on release through `pinchZoom` (`@use-gesture/react` 10.3.1 `usePinch` on the strip, which sets `touch-action: pan-y`; Safari's `GestureEvent` on desktop); double tap goes from the series' resting zoom (`zoom`, the stepper `web/13` builds) to min(2 × resting, 3.0)× at the tap point, and from any other zoom back to the resting zoom, through `zoomAt` in 240 ms `ease.settle` (haptic `zoom.snap`, a no-op on the web); `Ctrl`/`⌘` + wheel zooms around the pointer (keep `wheel-zoom-arming.ts`); `=` `+` / `-` / `0` zoom in, out and reset by 0.1. Plain wheel always scrolls. The zoom level shows as a folio chip `200%` (`type-folio` `ink.100` on the folio-flag ground) top-centre for 1200 ms (`dur.hold.chip`). Above 1.0× a horizontal drag pans the page.
I5. **Tap behaviour**: the whole screen toggles the chrome (default). With `stripTaps = TAP_TO_SCROLL`: top third plus left-middle scroll back, bottom third plus right-middle scroll forward 75 % of the viewport in 300 ms (`dur.tapscroll`) `ease.scroll` (`cubic-bezier(0.5, 1, 0.89, 1)`), centre toggles the chrome; reduced motion jumps. A tap pauses auto-scroll.
I6. **Desktop clicks**: the chrome-toggle click commits after 250 ms unless a second click lands within 250 ms and 24 px, which zooms instead. Mobile web double tap: ≤ 300 ms and ≤ 24 px apart; tap slop 8 px.
I7. **Horizontal chapter swipe** (phones, on by default, `swipeChapter`): ≥ 72 px or 600 px/s commits; the page follows the finger with the rubber band (c = 0.35) and a `CH 143 →` folio slides in from the edge; release past the threshold commits with a Dip to the neighbour. Live only at zoom ≤ 1.0, for touches that start at least 24 px from both screen edges, and for drags within 30° of horizontal (§11 precedence). Put the classifier in `gestures.ts` with tests (edge, angle, zoom, threshold, velocity).
I8. **Brightness HUD** (coarse pointers only; desktop uses the setup sheet's Brightness row from `web/13`): a vertical swipe along the left 12 % edge changes `brightness` (−75 to 0); a 6 × 140 px HUD (1 px `ink.100` outline, `ink.100` fill from the bottom, `sun-dim` glyph and the folio value on the folio-flag ground; below 0 it reads `NIGHT −40`) fades 600 ms after release. The edge zone decides after 8 px of slop: vertical drag adjusts brightness, a tap passes through to the tap rules. The dimmer is a `#000000` overlay over the pages at alpha `|v|/100`, pointer-transparent, under the chrome.
I9. **Warmth layer**: a `color.warmth` (`#FF8A00`) fixed, pointer-transparent layer over the pages at alpha `v/100 × 0.36` with `mix-blend-mode: multiply` (blacks stay black). **Colour**: `SEPIA` and `GREY` apply `filter: sepia(1)` and `filter: grayscale(1)` to the page layer through `pageFilter`.
I10. **Auto-scroll** (the existing engine auto-scroll with A6's speed): `p` and the folio-bar button toggle (`autoscroll.toggle`); `<` / `>` step 0.25× (`autoscroll.step`), clamped 0.50–3.00; while it runs, the right 12 % edge vertical swipe (coarse pointers only) adjusts speed with the same HUD reading `1.5×`; a tap or any manual scroll pauses; it pauses at a next chapter that has not loaded (the I12 band) and resumes when the pages land; at the series' end it stops and the chrome returns (`autoscroll.end`); it never auto-starts under reduced motion.
I11. **Middle-click autoscroll anchor** (desktop): 12 px dead zone, 10 px/s per px of distance, max 4000 px/s; any click or `Esc` ends it.
I12. **Next chapter loading** band below the seam: 96 px of ground reading `CH 143 IS ON ITS WAY` in `type-kicker` `ink.45`, a 16 px leader dial after 400 ms; after 8 s it adds "This source can take a while." (`type-caption`); the band keeps 128 px of bottom padding so the folio bar never covers it.
I13. On mobile web the pages set `-webkit-touch-callout: none; user-select: none; -webkit-user-drag: none` and the phone frame calls `preventDefault()` on `contextmenu` over pages (§8.0.5); the strip uses `overscroll-behavior-y: contain`; no smooth-scroll library in the reader.

### J. Chapter end: the credits (§8.14.6)

J1. When the last page of a chapter scrolls up past 60 % of the viewport, the credits follow: `chapter.complete` (sound `done` if on), the engine marks the chapter complete (A2).
J2. Full credits (used when `autoNextChapter` is off or the next chapter is not stitched below): 96 px of ground; `End of chapter 142` in `type-section` (Bodoni Moda Italic) through `SetHeading` (the Letter set: 640 ms per grapheme, blur 8 → 0 over 440 ms, 24 ms stagger capped at 560 ms, rule drawn 120 ms before the letters); a credits block `SERIES  Omniscient Reader · SOURCE  MangaDex · READ IN  11 MIN · PAGES  40` (`type-credit-label` labels, `type-credit` values).
J3. Reactions (§9.3.3) belong to `web/22`: the credits component takes an optional `reactions` node rendered between the credits block and the Coming up card; this step passes nothing.
J4. **Coming up** card (a next chapter exists and the strip is not continuing seamlessly): a 16:9 panel of the next chapter's first page blurred 24 px (`blur.card`) and duotoned to `ambient.duo` (the `duotone.tsx` filter; the fallback duo `#B8B2A4` when `ambient` is null), the sharp page as an inset 3:4 thumbnail on the left; the text block on a `#000000` band at 0.84 (over-art rule); kicker `COMING UP`; headline `Chapter 143` (`type-headline`); deck = the chapter title; folio `38 PAGES · ~6 MIN` (and `SAVED` once the auto-queue has saved it); primary `Read chapter 143` (48 px). The blur and duotone apply to this card only, never to pages in the strip.
J5. **Pull to continue** below the card: a 150 px (phone) / 300 px (desktop, wheel) region with a 2 px `spot` rule that fills from the left as the reader pulls; at full it commits (`chapter.next`), a 250 ms (`dur.fade.cut`) fade through black follows, and the new chapter's title is typed at 50 ms per character (`TypedHeadline`) as a caption top-left, `CH 143 — The Return`, on the folio-flag ground, fading after 2000 ms (`dur.hold.brief`).
J6. Continuous strip (default, `autoNextChapter` on): the next chapter is already stitched below, so J4–J5 are replaced by the seam and the credits are compact: the end title on one line plus the reactions slot; reading simply continues.
J7. Paged-mode credits page is `web/13`.

### K. End states and toasts (§8.14.6, §8.14.11)

K1. **Caught up**: a §7.23 notice, kicker `CAUGHT UP`, typed headline "That's everything so far.", deck "MangaDex has published 142 chapters. You'll get a notice when 143 lands." plus a `Notify me` switch (the follow's notify bell through the existing library hook: turning it on follows the series first when it is not followed, then sets `notify: true`; off sets `notify: false`) plus a `More like this` rail plus `Back to the series`.
K2. **The end** (the series `status` is Completed, case-insensitive, and its last chapter completes): kicker `THE END`, headline "You finished {title}.", deck "{n} chapters, {h} hours." (hours from the feature page's `YOUR TIME HERE` source), an `Up next` rail, and a quiet `Mark as done` sending `PATCH /library/series/{id} {reading_status: "completed"}` (hidden when already completed). Never `Notify me` or the "You'll get a notice…" deck for a Completed series.
K3. The rail (`UpNextRail`, §7.8 poster rail) is fed by `useUpNext(sourceId, seriesKey, mode)` in `frontend/src/features/library/up-next.ts` (`mode` is `"caught-up" | "the-end"`), calling `GET /ai/similar` directly (web/19 later moves the call onto its `features/ai/similar.ts` client without changing the chain):
   - **Similar** (§9.1.4): `GET /ai/similar?source&series` when it answers with items (World cards with their `why` line); when the AI desk is closed, `GET /ai/similar?source&series&fallback=genres` (series sharing two or more genres on the profile's sources, captioned `SAME GENRES` instead of a `why`) under a `NOTE` line with the §9.1.8 reason. A 404 from `/ai/similar` (the endpoint not deployed yet) counts as "no items", silently.
   - `mode: "caught-up"`: H3 `More like this`, Similar only; the rail is absent when Similar has no items.
   - `mode: "the-end"` (§8.14.6): H3 `Up next`, Similar, else the first `sections[]` entry of `useWorldRecommendations()` (`GET /library/world/recommendations`, the source of every Because-you-read rail, §9.1.6), else **From your shelf** (§9.1.6: followed series of this profile that are favourites (`is_favorite`) or `plan_to_read`, excluding this series, at most 12). Test the chain order and each fallback in `up-next.test.ts`.
K4. **Next failed**: a `CORRECTION` notice "Chapter 143 didn't load." + `Try again` + `Open it on its own →`; automatic retries back off from 2 s to 30 s meanwhile.
K5. **Further on another device** (A3): toast "You're further ahead on another device (CH 145, p.3). Jump there?" with `Jump`, held 8000 ms (`dur.hold.toast.action`).
K6. Bookmark saved or failed (`b` or the button, `POST /reader/bookmark` through the existing bookmark capture, `bookmark.add`, sound `set`): toast "Marked page 7 — 42% of the chapter." / "Couldn't save that spot." (`proof` edge, 6000 ms). Stale bookmark opened by `?page=&at=`: toast "That page moved. Opened at the nearest one." (3600 ms).

### L. States (§8.14.11) — every row

| State | Presentation |
|---|---|
| Loading chapter | Three galley page plates at the manifest's (or 2:3) aspect in the strip column (Flicker, §7.17), the running head visible with `LOADING CH 142`, a 24 px leader dial after 400 ms |
| Page placeholder | The page's reserved box in the ground colour, no spinner |
| Next chapter loading | I12 |
| Broken page | Inside the page box: kicker `PAGE 18 DIDN'T LOAD`, `quiet` `Retry` (refetches that image only), the reason in `type-caption` when known |
| No pages | Notice "This chapter has no pages." + `Back to the series` |
| Error | `CORRECTION` notice with the API message + `Try again` + `Go to the series` |
| Offline | Reads from disk silently; `OFFLINE EDITION` badge; no neighbour loading; the seam reads "Next chapter isn't saved on this device" with `Back to Downloads` |
| Rate limited | A band at the top of the unloaded pages: `SLOW DOWN — the source asked us to wait. Retrying in 12 s.` with a live folio countdown from the limiter's `Retry-After` |
| Stale bookmark, bookmark saved / failed, further on another device | K5, K6 |
| 18+ series | Rating card at the start (§7.24: 20 px certificate + `18+` in `type-kicker` + genre descriptors in `type-caption` `ink.60` inside a `paper.0` box with 8 × 12 px padding; in 480 ms, hold 3000 ms, out 240 ms) |
| No longer available (removed, dead source, or hidden by the gate) | The §8.0.10 `NOT IN THIS ISSUE` notice, identical for every cause |

### M. Keys (§8.14.9) registered in the "Reader" group of `lib/keyboard` so the `?` sheet lists them

| Key | Action |
|---|---|
| `→` / `d`, `←` / `a` | Turn page by reading direction (in the strip: one page) |
| `j` / `k` | Next / previous page |
| `Space` / `Shift+Space` | Forward / back one screen |
| `Home` / `End` | First / last page |
| `h` / `l`, `Ctrl+Shift+←/→` | Previous / next chapter |
| `g` | Go to page (opens the folio field) |
| `f` | Fullscreen |
| `c` | Cinema mode |
| `m` | Show or hide the chrome |
| `p` | Auto-scroll play / pause |
| `<` / `>` | Auto-scroll slower / faster by 0.25× |
| `b` | Bookmark this spot |
| `s` | Series page |
| `[` | Toggle the Contents panel |
| `=` `+` / `-` / `0` | Zoom in / out / reset |
| `?` | Keyboard sheet |
| `Esc` | Close sheet or panel → leave fullscreen → leave cinema → exit to the series page |

`,`, `]`, `w`, `v`, `r` are `web/13`; `u` is `web/23`. The "Single-key shortcuts" setting disables every binding without a modifier. The global `g`-then-number sequence is disabled inside the reader, so `g` means only "go to page" (§8.0.6). Put the escape order in a pure reducer (`keys.ts`) with a test.

### N. Gestures (§8.14.10, §11) — every reader row for mobile web and desktop

Scroll (native, `overscroll-behavior-y: contain`); tap and click zones (I5, I6); double tap / double-click (I4, I6); pinch and `Ctrl`+wheel (I4); long-press 450 ms on a page and right-click (the page actions are `web/13`; in this step long-press and right-click do nothing and the native callout stays suppressed); horizontal swipe (I7); left-edge vertical swipe (I8); right-edge vertical swipe while auto-scroll runs (I10); middle-click (I11); browser back (D4). Every gesture keeps its non-gesture alternative from the §11 last column.

## Out of scope here (owned by later steps; do not build)

- `web/13`: paged single and double, read-all, the Reading setup sheet and the settings button and `,`, the right "Margins" panel and `note-pencil`, `]`, `w`/`v`/`r`, page actions (long-press, right-click), the paged credits page.
- `web/19`: the reader's `PREVIOUSLY ON · 2 MIN` chip and recap entries.
- `web/22`: reactions in the credits and their unseal.
- `web/23`: guided view and `u`, page-tinted chrome (`--scrim-base`, `--page-tint`, `--page-light`, the tinted gutters), the soundscape and its `waveform` indicator, the auto-scroll chip, pace by dialogue, resume after release.
- Mobile-only rows: Lock controls, Keep screen awake, Volume keys, Refresh rate, the iOS edge swipe and Android back (the mobile track).

## File layout

Follow the screen-file naming `web/08`–`web/11` used in `frontend/src/skins/cinematic/screens/`; the files for this step:

```
frontend/src/skins/cinematic/screens/reader.tsx               ScreenId reader (parses params, renders <MangaReader kind="chapter">)
frontend/src/skins/cinematic/screens/reader-landing.tsx       ScreenId readerLanding
frontend/src/skins/cinematic/screens/reader/
  MangaReader.tsx        engine + chrome + overlays + keys; the kind prop leaves room for "readAll" (web/13)
  ReaderChrome.tsx       the renderChrome(state) root (auto-hide, focus rules, cinema, cursor hide)
  RunningHead.tsx        E1–E6
  FolioBar.tsx           F1, F2, F4, F5
  Ruler.tsx              F3 (+ ruler-math.ts, ruler-math.test.ts: value↔x, RTL mirror, tick drop above 120 pages, bookmark positions)
  MicroProgress.tsx      F6
  JumpToPage.tsx         F4 number field
  PageStates.tsx         placeholder, broken page, loading plates
  StripBands.tsx         seam, top band, next loading, offline end, rate limited
  Credits.tsx            J1–J6 (compact and full, Coming up card, pull to continue)
  EndStates.tsx          K1, K2, K4
  UpNextRail.tsx         K3
  ContentsList.tsx, ContentsSheet.tsx, ContentsPanel.tsx     G1–G4
  SidePanelLayout.tsx    left and right slots, recentring, the narrow-desktop rule
  ImageLayers.tsx        dimmer, warmth
  EdgeHud.tsx            brightness and auto-scroll speed HUD
  ZoomChip.tsx           I4 chip
  entry.ts               back target only (entry goes through web/06's enterReader)
  gestures.ts            tap/double-tap/double-click classifiers, chapter-swipe eligibility, edge zones (+ gestures.test.ts)
  keys.ts                reader bindings and the escape reducer (+ keys.test.ts)
frontend/src/features/reader/zoom.ts (+ zoom.test.ts)                    A1
frontend/src/features/reader/reader-prefs.ts (+ reader-prefs.test.ts)    A5
frontend/src/features/reader/time-left.ts (+ time-left.test.ts)          A7
frontend/src/features/reader/auto-scroll.ts (extended, + test)           A6
frontend/src/features/reader/<engine hook from web/03>                   A1–A4 (commands, events, slots)
frontend/src/features/library/up-next.ts (+ up-next.test.ts for the chain order)   K3
frontend/src/features/offline/use-chapter-download.ts                    A8 (only if not extracted yet)
frontend/src/skins/cinematic/index.ts        remove reader and readerLanding from PENDING
docs/redesign/signoffs.md                    precondition (only if no record exists)
docs/redesign/proof/web-12/                  plan.md, screenshots, report.md
```

Skin files import only `@/features/**` (never `@/features/*/components/**`), `@/lib/**`, `@/services/**`, `@/stores/**`, `@/types/**`, and their own `skins/cinematic/**`; the lint rule from `web/00` enforces it.

## Acceptance criteria

- [ ] `reader` and `readerLanding` are removed from the Cinematic `PENDING` set and the completeness test passes.
- [ ] Entering from the followed-series page (`/library/:followedId`, Read and Continue) and from the source series page (`/sources/:sourceId/series/:seriesKey`, a chapter row) both play the Column wipe (12 blades at 1440 × 900, 4 at 390 × 844) and land on the saved page; entering from History and from the command palette plays the Dip; leaving by back, `Esc` and `s` plays the Dip; no wipe between chapters.
- [ ] The motion-timings overlay (`mod+shift+m`, dev build) logs `COLUMN WIPE` at 872 ms planned on desktop and 616 ms on a phone viewport, each within one frame and with 0 dropped frames, and `DIP` at 440 ms.
- [ ] Running head and folio bar match E and F: two separate title targets, the folio opens Contents (sheet on 390 × 844, left panel on 1440 × 900), trailing buttons in order, the download mark cycles through every state with the 1000 ms arm on "Remove from this device?", `OFFLINE EDITION` shows when read from disk.
- [ ] Auto-hide: hides after 24 px down, shows after 56 px up, shows on the listed keys and pointer bands only, never hides during the first 800 ms or while focus is inside the chrome, idle-hides after 3000 ms; hidden chrome is out of the tab order; the micro progress shows while hidden and not in cinema mode.
- [ ] The ruler seeks live, shows page ticks (none above 120 pages), bookmark marks, the `p. 18` flag, the desktop hover preview, and is operable by keyboard with `aria-valuetext="Page 18 of 40"`; `07 / 40` becomes a number field on click and on `g`.
- [ ] Strip: exact page boxes before images land, no layout jump on decode, the seam band and top band render with their copy, over-scroll up 140 px loads the previous chapter, the next-chapter band appears with its 8 s caption.
- [ ] Zoom: pinch (mobile web) clamps 0.5–3.0× and snaps to 0.1, double tap toggles resting ⇄ min(2 × resting, 3.0)× at the tap point in 240 ms, `Ctrl`+wheel zooms at the pointer, `=` `-` `0` work, the `200%` chip shows for 1200 ms; `zoom.test.ts` proves the focal point stays fixed.
- [ ] Chapter swipe commits at 72 px or 600 px/s only at zoom ≤ 1.0, from ≥ 24 px off both edges and within 30°; the brightness HUD dims to `NIGHT −40`; warmth and colour layers apply to pages only.
- [ ] Credits: compact in the continuous strip; full credits, Coming up card and pull to continue when `autoNextChapter` is off; the end title runs the Letter set; the pull caption types at 50 ms per character and fades after 2000 ms.
- [ ] Caught up, The end (with `Mark as done` hidden when already completed), next failed with back-off, and further-on-another-device all render with their exact copy; the Up next rail falls back silently when `/ai/similar` is absent.
- [ ] Every row of the §8.14.11 states table renders (screenshots below), including rate limited with a live countdown and the `NOT IN THIS ISSUE` notice with identical wording for a removed and a gated series.
- [ ] Keyboard: every key in section M works from a cold load with no mouse; the escape order is exact; the `?` sheet lists the reader group; focus lands on the reading region on entry and the live region announces the chapter.
- [ ] Hit targets: every control in the chrome is ≥ 44 × 44 px on a coarse pointer (390 × 844 touch emulation) and ≥ 32 × 32 px on desktop, with ≥ 8 px between adjacent coarse targets; checked with a Playwright script that reads `getBoundingClientRect()` for every button in the chrome.
- [ ] Reduced motion (`page.emulateMedia({ reducedMotion: "reduce" })` and the app setting): the wipe is a 200 ms cross-fade, Dip a 150 ms fade, chrome fades without the slide, panels fade in place, the letter set is a 200 ms fade, the typed caption appears whole, tap-to-scroll and programmatic scrolls jump, auto-scroll never auto-starts; the leader dials keep running.
- [ ] Over-art contrast: the running head and folio bar text sits on the flat part of its scrim at text scale 1.0 and at browser font size 200 %; the computed `background-image` of the running head's and folio bar's `::before` is not `none` (asserted in the Playwright proof script).
- [ ] Per-skin difference: with the `mm-skin-debug` cookie set to `legacy` the legacy reader still works unchanged at the same URLs (screenshot), and the legacy reader tests still pass; no file under `frontend/src/features/*/components/` gained Cinematic code.
- [ ] `npm run typecheck`, `npm run lint`, `npm run test` and `npm run build` in `frontend/` are green, with the vitest file and case counts at or above the precondition floor plus the new tests.

## Verification

**RAM guard (production shares this box).** Before every heavy command run `free -m` and read the `available` column of the `Mem:` row. If it is under 1024 MB, stop and report instead of running it. Never run two builds at once, never run `next build` while `next dev` is running (stop the dev server first), and run the heavy commands below one at a time.

From `frontend/`:

```bash
free -m && npm run typecheck
free -m && npm run lint
free -m && npm run test
free -m && npm run build
npm run verify:reader    # prints that it is superseded by e2e/; the reader behaviour is covered by the vitests and the proof run
```

`npm run lint` and `npm run build` must stay at 0 errors and 0 warnings as in `00-baseline.md`. This step changes nothing under `mobile/` or `backend/`. Prove it on your own commits, not on a range (the mobile, backend and shared sessions push to the same branch in parallel, so a range diff shows their work too): `for c in <each commit SHA you made in this step>; do git show --name-only --format= "$c"; done | grep -E '^(mobile|backend)/'` must print nothing. The other suites are therefore not re-run here; their sessions run them and keep the baseline: `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter analyze` (No issues found), `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter test` (all 2012 passed) and `cd backend && .venv/bin/python -m pytest -q --no-header`.

**Visual proof.** Start the dev stack with `free -m && backend/scripts/dev_stack.sh start` (the dev stack of `backend/scripts/README-dev-stack.md`: uvicorn on 127.0.0.1:8010 against the dev SQLite under `/srv/manhwamaniacs/dev/data/`, never production data; the script already sets `MM_NOVELS_ENABLED=true`, turns rate limits off and leaves the AI key unset; run `backend/scripts/dev_stack.sh seed` once if the `demo` account does not exist yet), then the web client with `cd frontend && free -m && NEXT_PUBLIC_API_URL=/api BACKEND_INTERNAL_URL=http://127.0.0.1:8010 npx next dev -p 3010` (both variables are required: without `NEXT_PUBLIC_API_URL=/api` the browser calls `http://127.0.0.1:8000` directly (`src/config/env.ts`), and without `BACKEND_INTERNAL_URL` the `/api` rewrite in `next.config.ts` targets port 8000). Capture with the harness from `web/03` (run `node scripts/proof.mjs --help` first; its flags are authoritative, the routes, sizes and folder below are not negotiable), with the skin set to `cinematic` through the `mm-skin-debug` cookie, headless Chromium in a named session `web-12`, at 1440 × 900 and 390 × 844 (touch emulation on the phone size), into `docs/redesign/proof/web-12/`:

- `reader-chrome-{desktop,phone}.png` (chrome shown), `reader-hidden-{desktop,phone}.png` (chrome hidden, micro progress), `reader-wipe-hold-{desktop,phone}.png` (captured during the 40 ms hold after pressing Continue on the feature page), `reader-contents-{desktop,phone}.png`, `reader-jump-field-desktop.png`, `reader-zoom-chip-phone.png`, `reader-brightness-hud-phone.png`, `reader-seam-desktop.png`, `reader-top-band-desktop.png`, `reader-credits-compact-desktop.png`, `reader-credits-full-{desktop,phone}.png` (with `autoNextChapter` off), `reader-caught-up-desktop.png`, `reader-loading-desktop.png` (throttle the manifest with a Playwright route delay), `reader-broken-page-desktop.png` (route one page image to a 500), `reader-rate-limited-desktop.png` (route one page image to a 429 with `Retry-After: 12`), `reader-not-available-desktop.png` (an unknown series key), `reader-landing-{desktop,phone}.png`, `reader-reduced-motion-desktop.png`, `reader-legacy-desktop.png` (legacy skin), `motion-timings-wipe-desktop.png` (the overlay after a wipe).
- Use a chapter from a healthy source followed by the seeded demo profile; open it once from `/library/:followedId` and once from `/sources/:sourceId/series/:seriesKey` and keep both screenshots (`entry-follow-desktop.png`, `entry-source-desktop.png`).
- Write `docs/redesign/proof/web-12/report.md` listing each screenshot with the acceptance item it proves.

Stop `next dev` and the dev stack when the captures are done.

## Git

- Branch `feat/vps-slim-source-native`. Commit small and often: the sign-off record, then each engine change with its test, then the preferences record, then each chrome part, then the proof. Stage your paths explicitly (`git add frontend/src/features/reader/zoom.ts …`, `git add docs/redesign/proof/web-12`), never `git add -A` or `git add .`, because mobile, backend and shared sessions commit in the same checkout.
- Commit messages in the conventional style (`feat(web-cinematic): reader ruler with bookmarks`). No Claude or AI attribution anywhere: no `Co-Authored-By` line, no "Generated with" line, no AI author. Never commit secrets or `.claude/`.
- Run `npm run build` (after `free -m`) before every push, then `git push origin feat/vps-slim-source-native` after each working step.
- Never edit `backend/connectors/`. Never touch production containers or `/srv/manhwamaniacs/{app,data}`. Do not deploy: until `release/00` the Cinematic skin is reachable only through the debug row.

## Report back

Reply with:

1. Done items, grouped by the scope letters A–N, with anything not done and why.
2. The S1/S11 sign-off: the file and line that records it.
3. The screenshot folder `docs/redesign/proof/web-12/` and the list of files.
4. Test counts: vitest files and cases before and after, lint and build results, and the `free -m` available figure before each build.
5. The motion-timings figures for `COLUMN WIPE` (desktop and phone) and `DIP`.
6. Engine API added (exact exported names of `pinchZoom`, `zoomAt`, `onChapterCompleted`, `furtherElsewhere`, the render slots) so `web/13`, `web/23` and the Glass reader can call them.
7. Open issues and any place where you followed `cinematic/DESIGN.md` over this file.

Next prompt: `docs/redesign/prompts/web/13-cinematic-manga-reader-paged-readall-panels.md`.
