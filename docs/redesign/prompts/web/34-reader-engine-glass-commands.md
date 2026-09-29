# Web reader engine: the commands Glass needs

Track: web · Order 86 · Depends on: `docs/redesign/prompts/web/33-glass-series-and-book.md` · Runs in parallel with: `docs/redesign/prompts/mobile/34-reader-engine-glass-commands.md` · Proof folder: `docs/redesign/proof/web-34/`

## Goal

Add the skin-neutral reader-engine state and commands that the Glass manga reader needs, in `frontend/src/features/reader/engine/`, before any Glass reader chrome exists. This is glass §15.4 commit order steps 1, 3, 4 and 5 (step 2, `pinchZoom`/`zoomAt` and paged layouts, landed with Cinematic in `web/12` and `web/13`; `paginateNovel` landed in `web/14`; `pageToViewport` and `setCamera` landed in `web/23`): the five state fields `currentPageSample`, `scrollVelocity`, `seamProgress`, `overscrollExtent` and `panelBoxes`; the one-at-a-time chapter-end commands `armNeighbour` (48 px), `commitNeighbour` (72 px) and `continueFling`; `swipeNeighbour` with the stiffer rubber band (`c` 0.35); `pageLayerTransform` for the 1.12 × hit lens; and `autoScroll.engageFromVelocity`. Each lands with vitest coverage, `npm run verify:reader` exits 0, the Cinematic reader's e2e specs stay green, and a 120-page, 2,880 px strip is scrolled end to end under the motion-timings recorder. This step adds **no chrome and no pixels**: the Cinematic reader must look and behave exactly as before, and no Glass reader screen is built (that is `web/35`).

## Read first

Read these completely before planning. Where this file and `glass/DESIGN.md` disagree, `glass/DESIGN.md` wins; say so in the report.

1. `docs/redesign/inventory/00-decisions.md` and `docs/redesign/00-baseline.md`.
2. `docs/redesign/stack-decision.md` §2.2 (the data layer stays in `features/`), §2.3 (the engine seam), §4 risk 6 (engine work never changes pixels) and risk 11 (memory).
3. `docs/redesign/glass/DESIGN.md`:
   - §15.4 (the whole section: the state-field table, the command table, the commit order and the 120-page, 2,880 px device check), §15.7 (page samples at most every 600 ms off the main thread; the reader's image pipeline belongs to the engine), §15.8 (the motion-timings overlay), §15.10 rows G6, G11 and G14.
   - §2.1.7 (`dimLegibility` and where `Lb` comes from: the reader rows use `pTop`, `pBottom` and the maximum of the bands a surface overlaps; `Lb = 1.0` until a sample lands; updates held during flings faster than 3000 px/s), §2.1.8 step 3 (the `PageSample` shape and rules, the 16 × 16 `OffscreenCanvas` in a Web Worker, LRU of 500, the reading line at 38 %, greyscale fallback after 6 pages, `pages[].tint` first paint), step 4 (OKLCH clamping, for reference only).
   - §4.4 (projection `position + 0.499 × velocity`, capped at one screen), §4.5 (rubber band `d × (1 − 1 / (x × c / d + 1))`; the row "Chapter end and series start in the reader": commits at 72 displayed px), §4.6 (the row "Reader chapter-end pull": arm 48, commit 72), §4.10 rows Chapter card rise, Seam chip, Hit lens, Cruise ramp.
   - §8.14.1 (strip, seams 96 px, read-all seams 48 px, the reading line), §8.14.3 rows Horizontal swipe, Pull past the end / top, Mouse wheel (140 px arms, 210 px commits, 400 ms reset), Middle-click, §8.14.4 (continuous vs one at a time; momentum carries through), §8.14.9 (the hit lens and `pageLayerTransform`), §9.4.1 (cruise speeds 0.25×–4× of 60 px/s, flick to cruise, the 400 ms ramp), §9.4.3 "Data" (`panelBoxes`), §9.4.4 (what the chrome will do with the sample).
4. `docs/redesign/cinematic/DESIGN.md` §15.4 (the base state fields and the five engine duties Cinematic added: page tint, words on screen, panel detection, words per panel, completion events).
5. `docs/redesign/inventory/web.md` §9 (the reader today: RD1–RD42, the 140 px over-scroll) and §18.6 (A65–A73).
6. `docs/redesign/prompts-plan.json`: the `web/00` entry (TRACK RULE) and this file's entry; the reports `docs/redesign/proof/web-03/report.md`, `web-12/report.md`, `web-13/report.md`, `web-14/report.md`, `web-23/report.md` (their "Engine API" sections name what exists).
7. Code (read in full before planning): everything in `frontend/src/features/reader/engine/` (`types.ts`, `use-reader-engine.ts`, `ReaderEngineView.tsx`, `ContinuousStrip.tsx`, `PagedView.tsx`, `PageImage.tsx`, `auto-queue.ts` and whatever `web/12`–`web/23` added), `frontend/src/features/reader/{zoom,page-turn,read-all,auto-scroll,chrome-autohide,preload,scrub,strip,strip-progress,reader-prefs}.ts`, the page-tint worker (`grep -rln "OffscreenCanvas" frontend/src/features/reader`), the panel detection (`grep -rln "panels" frontend/src/features/reader`), `frontend/src/lib/motion-timings.ts` (`startGesture`), `frontend/src/lib/color/` (OKLCH helpers from `web/25`, if present), `frontend/eslint.config.mjs` (the engine boundary block), `frontend/vitest.config.ts` (the environment is `node` and only `src/**/*.test.ts` runs: every test here is pure logic), `frontend/scripts/proof.mjs`, and the Cinematic reader e2e specs (`ls frontend/e2e/cinematic | grep -i reader`).

## Preconditions (stop and report if any fails)

```bash
cd /srv/manhwamaniacs/dev/ManhwaManiacs
git branch --show-current                                      # feat/vps-slim-source-native
git log --oneline -40 | grep -i "web-33\|series detail"         # web/33 landed
grep -rn "pinchZoom\|zoomAt" frontend/src/features/reader | head -3          # web/12
grep -rn "setLayout\|dragTurn" frontend/src/features/reader | head -3        # web/13
grep -rn "pageToViewport\|setCamera" frontend/src/features/reader | head -3  # web/23
grep -n "^S1 \|^S11 \|^G6 \|^G14 " docs/redesign/signoffs.md            # the page-sample and panel sign-offs are recorded
cd frontend && free -m && npm run test 2>&1 | tail -5           # record the vitest file and case counts: your floor
mkdir -p ../docs/redesign/proof/web-34 && npx vitest run src/features/reader --reporter=verbose > ../docs/redesign/proof/web-34/reader-tests-before.txt; tail -3 ../docs/redesign/proof/web-34/reader-tests-before.txt
```

If a grep above is empty, the Cinematic step that owns it has not landed: stop and report which one. The `signoffs.md` grep passes on any one id, so read its output: it must show all four lines `S1 …`, `S11 …`, `G6 …` and `G14 …` (written by `backend/06`; `web/12` or `mobile/12` add S1 and S11 only if they were missing). If any of the four is missing, stop and report: the owner must sign off client-side page samples and panel detection first.

## Skills to invoke

1. `superpowers:writing-plans` before any code. Save the plan at `docs/redesign/proof/web-34/plan.md`, listing the commits of sections A to I one by one, each with the tests that gate it.
2. `superpowers:test-driven-development` for every section: write the vitest first (pure functions only; the environment is `node`).
3. `superpowers:executing-plans` inline. The engine is one shared hook: do not split it across parallel subagents. One subagent may write the e2e spec and the dev probe page (section J) after sections A to I are committed; start its prompt with a scope lock, pass `model: "opus"`, and check its work against `git diff`.
4. `superpowers:systematic-debugging` if any existing reader test or Cinematic reader spec turns red.
5. `superpowers:verification-before-completion` before you claim anything is done.
6. `impeccable`, `taste-skill:taste-skill` and `frontend-design` are not needed: this step changes no pixels.

## Scope: deliver every item below

All code lives in `frontend/src/features/reader/engine/` (pure helpers may sit beside the hook as `engine/<name>.ts` with `engine/<name>.test.ts`). The engine keeps its lint boundary: no import from `@/skins/**`, `@/components/**`, `@/features/*/components/**` or `../components`. The engine owns thresholds; skins only read state and call commands. Every new field and command is optional to use: Cinematic ignores them and keeps working unchanged.

### A. The live channel for per-frame values (`engine/live.ts` + test)

Three of the new fields change every frame. Putting them in React state would re-render the whole reader at 120 Hz. So:

- `createLiveStore<T extends Record<string, unknown>>(initial)` with `get(key)`, `set(key, value)` (notifies only when the value changed) and `subscribe(key, listener)` returning an unsubscribe; the engine exposes one instance as `engine.live` with the keys `scrollVelocity`, `seamProgress`, `overscrollExtent`.
- `useEngineLive(engine, key)` (in `use-reader-engine.ts`): `useSyncExternalStore` over one key, for components that need a render.
- `ReaderEngineState` also carries the three fields, but the engine writes them into React state only on threshold changes: `scrollVelocity` when `|v|` crosses 3000 px/s either way or reaches 0; `seamProgress` when a seam enters (`null` → number) or leaves (number → `null`); `overscrollExtent` when it crosses 0, ±48 or ±72. Chrome that animates per frame subscribes through `engine.live` and drives Motion values directly.
- Test: `set` notifies once per change and never for an equal value; unsubscribe stops notifications.

### B. `currentPageSample` (step 1; §2.1.8 step 3)

1. `engine/page-sample.ts` + test: `samplePage(rgba: Uint8ClampedArray, width = 16, height = 16): PageSample` where

   ```ts
   export interface PageSample {
     tint: string | null;              // "#rrggbb"
     top: string; bottom: string;      // mean sRGB of the top and bottom quarter
     lTop: number; lMid: number; lBottom: number;   // mean relative luminance: top quarter, middle half, bottom quarter
     pTop: number; pMid: number; pBottom: number;   // 95th-percentile relative luminance of the same bands
     source: "manifest" | "decode";
   }
   ```

   Relative luminance is WCAG's (`c ≤ 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ^ 2.4`, then `0.2126 R + 0.7152 G + 0.0722 B`). On a 16-row sample the bands are rows 0–3, 4–11 and 12–15. The 95th percentile is nearest-rank (`sorted[ceil(0.95 × n) − 1]`). `tint` is the mean colour of the most populous 5-bit-per-channel bucket whose OKLCH `L ≥ 0.18` and `C ≥ 0.035`, else `null` (greyscale). Use the shared OKLCH helper in `frontend/src/lib/color/` (from `web/25`; the engine lint block allows `@/lib/**`); if none exists there, add `frontend/src/lib/color/oklch.ts` with `srgbToOklch(hex)` and its test (reference: `oklch(62.8% 0.2577 29.23)` for `#ff0000`). Test vectors: all `#FFFFFF` (tint null, every `l*` and `p*` 1.0); all `#000000` (tint null, 0); a page whose top quarter is white and the rest black (lTop 1, lMid 0, pTop 1); a dark page with one white bubble covering 2 × 2 pixels of the top quarter (lTop ≤ 0.13, pTop 1.0: the bubble counts); a flat `#E53935` page (tint `#e53935` within ±1 per channel); a grey ramp (tint null).
2. **The worker.** Extend the page-tint worker that `web/23` built (it already draws each decoded page into a 16 × 16 `OffscreenCanvas` from a transferred `ImageBitmap`) to also return `samplePage(...)` in the same message. Cinematic's `pageTint` output must stay byte-identical: its `design/tint-vectors.json` parity test keeps passing.
3. **The engine duty.** Sample the page under the reading line (38 % of the viewport height from the top in the strip; the visible page in paged layouts; the current page in guided view), at most every 600 ms while scrolling and once on settle (150 ms without a scroll event); cache per page URL in an LRU of 500 entries (`engine/lru.ts` + test if no LRU exists in `features/reader`). Rules, in the engine (pure `resolveSample(prev, next, greyRun, coverPalette)` + test): a greyscale sample keeps the previous `tint`; after 6 greyscale pages in a row the `tint` becomes the series cover palette's `a[0]` (new optional engine input `coverPalette?: { a: string[] }`); a manifest `pages[].tint` paints first as `{ tint, top: tint, bottom: tint, l* and p* all 1, source: "manifest" }` (unknown luminance means dim 0.64 until the decode lands); the decoded sample replaces it with `source: "decode"`. While `|scrollVelocity| > 3000` px/s the engine holds `currentPageSample` and publishes the latest sample when the speed falls below 3000. Posting samples on chapter exit (`POST /reader/page-tints`) stays as `web/23` built it.

### C. `scrollVelocity` (step 1)

`engine/velocity.ts` + test: a tracker over a 100 ms window of `(timeMs, position)` samples returning signed px/s (positive = forward: down in the strip, the reading direction in paged layouts), 0 after 100 ms without a sample. The engine feeds it from its scroll handler and exposes it through `engine.live` and the thresholded state (A). Test: constant 1,200 px/s motion reads 1,200 ± 1; a reversal flips the sign within one window; a stop reads 0 after 100 ms.

### D. `seamProgress` and seam events (step 1; §8.14.1)

`engine/seam.ts` + test:

- `seamProgress(seamTop, seamHeight, viewportHeight)`: `(viewportHeight − seamTop) / (viewportHeight + seamHeight)` clamped 0–1 while the seam overlaps the viewport, else `null`. The engine measures the seam element that the skin's divider slot renders (mark it with `data-engine-seam="{chapterKey}"` inside the slot wrapper the engine owns; continuous seams are 96 px, read-all seams 48 px, both drawn by the skin).
- `engine.onSeam(listener)` fires `{ kind: "reading-line", chapter, direction }` when the seam's centre crosses 38 % of the viewport height (forward or back), and `{ kind: "top", chapter }` when the seam's bottom edge passes the viewport top going forward (the Glass seam chip and `chapter.seam` hang on these in `web/35`). Test both crossings, both directions, and that a seam wobbling ±2 px around the line fires once (a 4 px hysteresis).

### E. One at a time: `overscrollExtent`, `armNeighbour`, `commitNeighbour`, `continueFling` (step 3; §8.14.4)

1. **Chapter mode.** If the engine has no one-at-a-time mode yet (`grep -n "chapterMode\|stitch" frontend/src/features/reader/engine/*.ts`), add the option `chapterMode: "continuous" | "single"` (default `"continuous"`, today's behaviour). In `"single"` the strip renders only the current chapter; the neighbours' manifests and the next chapter's first 3 pages still preload at 70 % of the chapter (the existing preload), but nothing is appended.
2. `engine/neighbour.ts` + test, the pure rules: `ARM_PX = 48`, `COMMIT_PX = 72`; touch: `displayedFromRaw(raw, viewportHeight) = rubberband(raw, viewportHeight, 0.55)`; wheel: accumulated `deltaY` past the end, reset after 400 ms without wheel input, mapped so that 140 px of wheel = 48 displayed and 210 px = 72 displayed (`acc ≤ 140 ? acc × 48 / 140 : 48 + (acc − 140) × 24 / 70`); `phase(displayed)` returns `"idle" | "armed" | "locked"` (armed at ≥ 48, locked at ≥ 72; the same with negative values at the start of the chapter). Test: 47 vs 48 vs 72 displayed, 139 / 140 / 210 wheel px, the 400 ms reset, the rubber band at 0 and at the viewport height.
3. **Measuring on the web.** In `"single"` mode the scroller gets `overscroll-behavior-y: none` (no browser bounce or glow). A touch that keeps pulling forward after `scrollTop + clientHeight >= scrollHeight − 1` accumulates raw overscroll from that point; the same at `scrollTop <= 0` backward. The engine applies `transform: translateY(−displayed px)` to the strip content wrapper it owns, publishes `overscrollExtent` (positive past the end, negative past the start), and fires `engine.onNeighbour({ phase, direction })` on each phase change. On release below 72 it springs the wrapper back with the transition object the skin passes (`options.overscrollReturn`, default `{ type: "spring", stiffness: 322.3, damping: 35.9 }`, the `settle` spring); on release at or beyond 72 it keeps the offset and waits for `commitNeighbour`. A wheel has no release: at 210 px the engine fires `onNeighbour({ phase: "locked", direction, via: "wheel" })` and the skin commits at once with `commitNeighbour({ direction, velocity: 0 })`; touch events carry `via: "touch"`.
4. **Commands.** `armNeighbour(direction)` makes sure the neighbour is ready (its manifest, its first page decoded) and resolves `{ chapter: ChapterRef, pageCount, firstPageUrl, minutes }` (`minutes` from the page count at 0.15 min per page; the skin shows "42 pages · about 6 min"); it is idempotent. `commitNeighbour({ direction, velocity })` switches to the neighbour in place (replaces the reader URL with the neighbour chapter's route, keeps the engine instance, resets the overscroll without animation) and stores `velocity`. `continueFling(velocity)` runs a ballistic scroll on the new chapter after its first layout: per frame `v ← v × 0.998^dt`, `y ← y + v × dt / 1000`, stopping below 20 px/s or at the chapter's end, cancelled by any touch, wheel or key (a catch). Pure `flingDistance(v0)` and `flingStep(v, dtMs)` + tests: the total distance from `v0` is `0.499 × v0` within 1 %, and one 8.33 ms step decays the speed by `0.998^8.33`.
5. Reduced motion is the skin's business (it passes a zero-velocity commit); the engine never starts a fling with velocity 0.

### F. `swipeNeighbour` (step 3; §8.14.3 "Horizontal swipe")

`engine/swipe-neighbour.ts` + test and two commands:

- `lockAxis(dx, dy)`: `"x"` once `|dx| > 2 × |dy|` after 10 px of travel, `"y"` once `|dy| > 2 × |dx|`, else `null`.
- `swipeNeighbour(dx)` returns `{ displayed, direction }`: `displayed = sign(dx) × rubberband(|dx|, viewportWidth, 0.35)`; `direction` is `"next"` for a leftward swipe in left-to-right series and `"previous"` for a rightward one, mirrored for right-to-left.
- `releaseSwipeNeighbour(vx)` returns `"committed"` when the projected raw travel `|dx + 0.499 × vx|` (capped at one viewport width) is past 96 px and a neighbour exists (it then calls `commitNeighbour` with `velocity: 0`), otherwise `"cancelled"`.
- Test: the lock at 10 px, the 0.35 band at 0, 100 and 400 px on a 390 px viewport, commit at 97 projected and not at 95, RTL mirroring, no commit without a neighbour.

### G. `pageLayerTransform` (step 4; §8.14.9)

`pageLayerTransform(t: { scale: number; originX: number; originY: number } | null, clip: { x: number; y: number; w: number; h: number; radius: number } | null)` (viewport coordinates). The engine renders one layer it owns (`<div data-engine="page-lens">`, `position: fixed`, at the clip rect, `overflow: hidden`, `border-radius: radius`, `pointer-events: none`) holding copies of the page `<img>` elements that intersect the clip (same `src`, so the decoded images are reused), positioned so that at scale 1 they line up with the pages beneath to the pixel, then scaled by `t.scale` around `(originX, originY)`. The strip never re-lays out. `null` removes the layer. Pure `lensLayout(pageRects, clip, t)` + test: at scale 1 every copy's rect equals its page rect relative to the clip; at 1.12 the origin point maps to itself; pages outside the clip are left out. The copies follow scrolling (re-positioned on the scroll handler's frame).

### H. `autoScroll.engageFromVelocity` and the auto-scroll units (step 5; §9.4.1)

1. If `autoScroll` has no pixel-based API yet, add `autoScroll.start(pxPerSecond, { rampMs = 0 })` and `autoScroll.setSpeed(pxPerSecond)` beside the existing level and `speedX` paths (unchanged for Cinematic). The value may be negative (scrolls backward): `web/35`'s middle-click autoscroll anchor uses that. `rampMs` ramps linearly from 0 to the target (`web/44` passes 400).
2. `engine/cruise-engage.ts` + test: `engageSpeed(v)` returns the multiplier `round(v / 60 / 0.05) × 0.05` clamped to 0.25–4 when the forward velocity `v` is within 15–240 px/s, else `null` (backward velocities never engage).
3. `autoScroll.engageFromVelocity(v)` and the engine duty: while cruise is on and the reader flings the strip forward, the engine watches `scrollVelocity` as the native momentum decays; the first time the speed enters 15–240 px/s it starts auto-scroll at that exact speed and fires `engine.onCruiseEngaged({ multiplier })`. A touch during the coast cancels the watch. Test `engageSpeed` at 14, 15, 60, 240 and 241 px/s and for −100 px/s.

### I. `panelBoxes` (step 1; §9.4.3 "Data")

A getter on the engine state over the `panels` entry `web/23` added for the current page: `panelBoxes: { x: number; y: number; w: number; h: number }[] | null` in page fractions; `null` while the page is being analysed or has no result. It is not a second detector output. Test the mapping from `panels` to `panelBoxes` for a page with panels, a page without, and a page not analysed yet.

### J. Dev probe, e2e and the 120-page check

1. **Dev probe page** `frontend/src/app/(preview)/dev/reader-engine/page.tsx` (a server component calling `notFound()` when `process.env.NODE_ENV === "production"`) rendering a client component `frontend/src/app/(preview)/dev/reader-engine/EngineProbe.tsx`: `useReaderEngine()` for `?source=&series=&chapter=&mode=continuous|single`, `ReaderEngineView` with plain inline slots (grey boxes, a 96 px seam box with `data-engine-seam`), no skin, and a fixed `<pre data-testid="engine-readout">` showing the five fields and the last `onSeam`, `onNeighbour` and `onCruiseEngaged` events as JSON (updated from `engine.live`). With `?timings=1` it calls `setRecording(true)` from `@/lib/motion-timings` and exposes `window.__mmTimings = { entries }` in development.
2. **Fixture.** `frontend/e2e/fixtures/reader/long-strip.ts` builds a 120-page manifest in the shape `GET /reader/chapter/manifest` returns (read `features/reader/api.ts` and `types.ts` for it), each page 720 × 2,880 px, and a route handler that answers every page image with an SVG of that size (a vertical gradient whose hue is `page × 3°`, with a white 200 × 120 bubble every third page) so the sampler has real bands. Next and previous chapters are 3-page manifests.
3. **`frontend/e2e/engine/web-34-engine.spec.ts`** (Playwright against `next dev`, routes intercepted with `page.route`): the readout shows `scrollVelocity` > 0 while scrolling and 0 after stopping; `seamProgress` goes from `null` to a number and back as a seam passes; the `reading-line` and `top` seam events fire once each; in `mode=single` at 390 × 844 with touch emulation a drag past the end reports `overscrollExtent` rising through `armed` at 48 and `locked` at 72, and a release below 72 returns it to 0; ten wheel events of 21 px past the end at 1440 × 900 reach `locked` via the wheel; `commitNeighbour` after a fling starts the next chapter scrolling (the readout's velocity is > 0 on the new chapter); `currentPageSample.source` goes from `manifest` to `decode` and its `pTop` is 1.0 on a page with a top bubble.
4. **The 120-page, 2,880 px check** (glass §15.4, §15.8): the spec opens the probe with the long strip and `?timings=1`, wraps one end-to-end scroll in `startGesture("STRIP SCROLL 120")` from `@/lib/motion-timings` (a `requestAnimationFrame` loop advancing the scroller by 6,000 px/s, about 58 s for 345,600 px), and reads back frames, planned frames and dropped frames; it asserts that no `longtask` entry (`PerformanceObserver`) exceeds 50 ms during the run and that at most 12 page `<img>` elements are mounted at any sampled moment (the virtualisation holds), and it writes the figures to `docs/redesign/proof/web-34/strip-120.json`. Headless Chromium on this VPS renders in software, so the dropped-frame figure is recorded, not asserted; the 120 Hz device run is listed for the owner's hardware check in the report.

## Out of scope here (owned by later steps; do not build)

- Every pixel: the Glass reader chrome, capsules, cards, seam chip, lens and HUDs (`web/35`), cruise's pill and ramp use (`web/44`), guided view (`web/44`, on `setCamera` from `web/23`).
- Any change to Cinematic's reader chrome or behaviour. If a Cinematic reader test fails, the engine change is wrong.

## File layout

```
frontend/src/features/reader/engine/
  live.ts (+ live.test.ts)                         A
  page-sample.ts (+ page-sample.test.ts)           B1
  lru.ts (+ lru.test.ts)                           B3 (only if no LRU exists in features/reader)
  resolve-sample.ts (+ resolve-sample.test.ts)     B3
  velocity.ts (+ velocity.test.ts)                 C
  seam.ts (+ seam.test.ts)                         D
  neighbour.ts (+ neighbour.test.ts)               E2, E4 (flingDistance, flingStep)
  swipe-neighbour.ts (+ swipe-neighbour.test.ts)   F
  lens-layout.ts (+ lens-layout.test.ts)           G
  cruise-engage.ts (+ cruise-engage.test.ts)       H
  panel-boxes.ts (+ panel-boxes.test.ts)           I
  types.ts, use-reader-engine.ts, ReaderEngineView.tsx, ContinuousStrip.tsx, PagedView.tsx   extended
frontend/src/features/reader/<page-tint worker from web/23>          B2 (extended)
frontend/src/app/(preview)/dev/reader-engine/{page.tsx,EngineProbe.tsx}   J1
frontend/e2e/fixtures/reader/long-strip.ts                            J2
frontend/e2e/engine/web-34-engine.spec.ts                             J3, J4
docs/redesign/proof/web-34/                                           plan.md, strip-120.json, screenshots, report.md
```

Nothing under `frontend/src/skins/` changes, and no ScreenId leaves any `PENDING` set.

## Acceptance criteria

- [ ] `ReaderEngineState` gains `currentPageSample`, `scrollVelocity`, `seamProgress`, `overscrollExtent` and `panelBoxes`; `engine.live` carries the three per-frame values; the commands `armNeighbour`, `commitNeighbour`, `continueFling`, `swipeNeighbour`, `releaseSwipeNeighbour`, `pageLayerTransform` and `autoScroll.engageFromVelocity` (plus `autoScroll.start(pxPerSecond, { rampMs })` and `setSpeed(pxPerSecond)` if they were missing) exist with the signatures above; the events `onSeam`, `onNeighbour` and `onCruiseEngaged` exist.
- [ ] Every vitest file of sections A to I passes with the exact vectors and boundaries listed; every reader test that passed before (the list in `docs/redesign/proof/web-34/reader-tests-before.txt`) still passes, and the vitest counts are at or above the floor plus the new tests.
- [ ] Cinematic's `pageTint` output is unchanged (`tint-vectors.json` parity passes) and the worker still runs off the main thread with a transferred `ImageBitmap`.
- [ ] Thresholds match the DESIGN exactly: arm 48 and commit 72 displayed px, wheel 140 and 210 px with the 400 ms reset, swipe `c` 0.35 with a 96 px projected commit, the 1.12 lens scale supported, cruise engaging only within 15–240 px/s, samples at most every 600 ms and held above 3000 px/s.
- [ ] `npm run verify:reader` exits 0 (it prints that it is superseded by `e2e/`), `web-34-engine.spec.ts` passes, and every Cinematic reader spec under `frontend/e2e/cinematic/` passes unchanged.
- [ ] The 120-page, 2,880 px check ran end to end: no long task over 50 ms, at most 12 mounted page images at any sample, figures written to `strip-120.json`.
- [ ] No pixel change: before and after screenshots of the Cinematic reader (`/reader/…` and `/read-all/…`, chrome shown and hidden, at 1440 × 900 and 390 × 844) are identical apart from live data.
- [ ] Keyboard, hit targets and reduced motion: unchanged (no control is added); the engine never starts a fling or an engage under a zero-velocity commit.
- [ ] Boundary: `grep -rn "skins/\|components/" frontend/src/features/reader/engine` is empty and the engine lint block rejects a probe import of `@/skins/glass/motion` (delete the probe; do not commit it).
- [ ] `npm run typecheck`, `npm run lint` (0 errors, 0 warnings), `npm run test`, `npm run build` (0 errors, 0 warnings) and `node design/build.mjs --check` are green.

## Verification

**RAM guard (production shares this box).** Before every heavy command (a build, the vitest suite, `next dev`, a Playwright run) run `free -m` and read the `available` column of the `Mem:` row. If it is under 1024 MB, stop and report instead of running it. Never run two builds at once, and never run `next build` while `next dev` or a Playwright browser is running.

From `frontend/`:

```bash
free -m && npm run typecheck
free -m && npm run lint
free -m && npm run test
free -m && npx vitest run src/features/reader --reporter=verbose    # compare with docs/redesign/proof/web-34/reader-tests-before.txt
free -m && npm run build
npm run verify:reader
cd .. && node design/build.mjs --check && cd frontend
```

Dev stack as `backend/scripts/README-dev-stack.md` says (uvicorn 127.0.0.1:8010, the dev SQLite, never production data); export `MM_PROOF_USER` and `MM_PROOF_PASSWORD` from its demo account; then:

```bash
free -m && NEXT_PUBLIC_API_URL=/api BACKEND_INTERNAL_URL=http://127.0.0.1:8010 npm run dev -- --port 3010
# second shell
free -m && E2E_BASE_URL=http://127.0.0.1:3010 E2E_USERNAME=$MM_PROOF_USER E2E_PASSWORD=$MM_PROOF_PASSWORD npx playwright test e2e/engine/web-34-engine.spec.ts --workers=1
free -m && E2E_BASE_URL=http://127.0.0.1:3010 E2E_USERNAME=$MM_PROOF_USER E2E_PASSWORD=$MM_PROOF_PASSWORD npx playwright test e2e/cinematic --grep -i reader --workers=1
```

**Visual proof (no-pixel parity)** with `frontend/scripts/proof.mjs`, named session `web-34`, at 1440 × 900 and 390 × 844. Before section A starts: `free -m && node scripts/proof.mjs --step web-34/before --skin cinematic --session web-34 --routes <reader URL>,<read-all URL>`; after section I: the same with `--step web-34/after`. Compare the pairs (a pixel diff with Playwright's `toHaveScreenshot` in a scratch script under your scratchpad, or `compare` if ImageMagick is installed) and record the result. Capture the probe page too: `node scripts/proof.mjs --step web-34/probe --session web-34 --routes "/dev/reader-engine?source=<s>&series=<k>&chapter=<c>&mode=single"`. If you use `playwright-cli`, pass `-s=web-34`. Write `docs/redesign/proof/web-34/report.md`. Stop `next dev` when done.

`00-baseline.md` records lint and build at 0 errors and 0 warnings; keep them there. This step changes nothing in `mobile/` or `backend/`: check each of your commits with `git show --stat --format= <hash>` (the parallel `mobile/NN` session and the backend and shared sessions commit `mobile/` and `backend/` on the same branch, so never judge by the branch diff). If one of your commits touched them, revert that part and prove the baseline with `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter analyze` (No issues found), `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter test` (all 2012 tests pass, or the current higher count) and `cd backend && .venv/bin/python -m pytest -q --no-header`, one at a time after the RAM guard.

## Git

- Branch `feat/vps-slim-source-native`. One commit per section (A to I), each with its test and the full `npm run test` green, then the probe page, the fixture and spec, and the proof. Example: `feat(reader-engine): overscroll extent with arm and commit for one-at-a-time chapters`.
- Stage explicit paths only, never `git add -A` or `git add .`: the mobile, backend and shared sessions commit in the same checkout.
- No Claude or AI attribution anywhere: no `Co-Authored-By` line, no "Generated with" line, no AI author. Never commit real credentials or secrets (the dev-stack demo password is committed only in `backend/scripts/README-dev-stack.md` by `backend/00`; never copy it into a spec, script or proof file), `.env*` or `.claude/`.
- Run `npm run build` (after `free -m`, with `next dev` stopped) before every push, then `git push origin feat/vps-slim-source-native` after each working step.
- Never edit `backend/connectors/`. Never touch production containers or `/srv/manhwamaniacs/{app,data}`. Do not deploy.

## Report back

Reply with:

1. Done items A to J, each with its commit hash.
2. The final engine API: paste the added parts of `ReaderEngineState` and `ReaderEngineCommands`, the `engine.live` keys, and the event signatures (`onSeam`, `onNeighbour`, `onCruiseEngaged`), so `web/35` and `web/44` can call them by name.
3. The reader test list (every file under `src/features/reader/` with its case count) before and after.
4. The 120-page figures from `strip-120.json` (frames, planned frames, dropped frames, the longest task, the most mounted images) and the line "120 Hz device run pending on the owner's hardware".
5. The no-pixel parity result for each before/after pair and the folder `docs/redesign/proof/web-34/`.
6. Test counts, lint, build and `build.mjs --check` results, the lowest `free -m` available figure.
7. Open issues, each with its `glass/DESIGN.md` section.

Next prompt file: `docs/redesign/prompts/web/35-glass-manga-reader.md` (`docs/redesign/prompts/mobile/34-reader-engine-glass-commands.md` runs in parallel).
