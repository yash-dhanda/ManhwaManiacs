# Mobile reader engine: the commands Glass needs

Track: mobile · Order 87 · Depends on: `docs/redesign/prompts/mobile/33-glass-series-and-book.md` · Web twin: `docs/redesign/prompts/web/34-reader-engine-glass-commands.md` · Proof folder: `docs/redesign/proof/mobile-34/`

## Goal

Add the skin-neutral reader-engine state and commands that the Glass manga reader needs, in `mobile/lib/features/reader/engine/`, before any Glass reader chrome exists. This is glass §15.4 commit order steps 1, 3, 4 and 5 on Flutter (step 2, `pinchZoom` / `zoomAt` and the paged `setLayout` with its `PageView`, landed with Cinematic in `mobile/12` and `mobile/13`; `pageToViewport`, `setCamera`, the page tint and panel detection landed in `mobile/23`): the five state fields `currentPageSample`, `scrollVelocity`, `seamProgress`, `overscrollExtent` and `panelBoxes`, with the three per-frame values on a live channel; page samples on a **64 px decode with `material_color_utilities` `QuantizerCelebi` in `compute()`**; the one-at-a-time chapter mode with `armNeighbour` (48 px), `commitNeighbour` (72 px) and `continueFling`; `swipeNeighbour` with the stiffer rubber band (`c` 0.35); `pageLayerTransform` for the 1.12 × hit lens; and `engageFromVelocity` with a pixel-based cruise start. Each command lands in its own commit gated by the existing reader tests, and the whole step is proven by a 120-page, 2,880 px strip scrolled end to end (a widget test here, and the 120 Hz device check on the owner's iPhone and Android flagship through a development probe page). This step adds **no chrome and no pixels**: the Cinematic reader must look and behave exactly as before, and no Glass reader screen is built (that is `mobile/35`).

## Read first

Read these completely before planning. Where this file and `docs/redesign/glass/DESIGN.md` disagree, `glass/DESIGN.md` wins; say so in the report.

1. `docs/redesign/inventory/00-decisions.md` and `docs/redesign/00-baseline.md`.
2. `docs/redesign/stack-decision.md` §2.3 (the engine seam: `ReaderEngine`, `ReaderEngineState`, the `chromeBuilder` slot; the engine never imports skins), §4 risk 6 (engine work never changes pixels; the 120-page, 2,880 px device check) and risk 11 (memory).
3. `docs/redesign/glass/DESIGN.md`:
   - §15.4 (the whole section: the state-field table, the command table, the commit order, the device check), §15.7 (page samples at most every 600 ms off the main thread, "a `compute()` isolate on a 64 px decode"; the reader's image pipeline belongs to the engine), §15.8 (the motion-timings overlay), §15.10 rows G6, G11 and G14, §15.11 (the `material_color_utilities: any` ledger row and its fallback).
   - §2.1.7 (`dimLegibility` and the reader rows of the `Lb` table: `pTop`, `pBottom`, the band maximum; `Lb = 1.0` until a sample lands; updates held during flings faster than 3000 px/s), §2.1.8 step 2 (the Flutter cover fallback: `QuantizerCelebi().quantize(pixels, 16)` and the discard rule, never `Score.score`) and step 3 (the `PageSample` shape and rules: `mobile/lib/features/reader/engine/page_tint.dart`, the LRU of 500, the reading line at 38 %, the greyscale fallback after 6 pages, the manifest `pages[].tint` first paint), step 4 (OKLCH clamping, for reference only).
   - §4.3 (Flutter hand-off), §4.4 (projection `position + 0.499 × velocity`, capped at one screen), §4.5 (rubber band `d × (1 − 1 / (x × c / d + 1))`; the row "Chapter end and series start in the reader": commits at 72 displayed px), §4.6 (the row "Reader chapter-end pull": arm 48, commit 72), §4.10 rows Chapter card rise, Seam chip, Hit lens, Cruise ramp.
   - §8.14.1 (strip, seams 96 px, read-all seams 48 px, the reading line), §8.14.3 rows Horizontal swipe, Pull past the end / top, Mouse wheel (140 px arms, 210 px commits, 400 ms reset; for iPad trackpads and Android mice), §8.14.4 (continuous vs one at a time; momentum carries through), §8.14.9 (the hit lens and `pageLayerTransform`), §9.4.1 (cruise speeds 0.25×–4× of 60 px/s, flick to cruise, the 400 ms ramp), §9.4.3 "Data" (`panelBoxes`), §9.4.4 (what the chrome will do with the sample).
   - **One reading to keep both clients identical:** the vertical chapter-end pull uses Apple's `c` 0.55 (`physicsRubberBandC`, §4.5), and the sideways chapter swipe uses the stiffer `physicsRubberBandChapterC` 0.35 (§8.14.3 calls it "stiffer", that is, stiffer than the vertical pull). §2.8.5's description of `physicsRubberBandChapterC` says "the reader's chapter-end pull"; `web/34` implements the reading above, so this file does the same. Name it in the report.
4. `docs/redesign/cinematic/DESIGN.md` §15.4 (the base state fields and the engine duties Cinematic added: page tint, words on screen, panel detection, completion events).
5. `docs/redesign/inventory/mobile.md` §6a (the Flutter reader today: the 6,000 px cache extent, the 64 MB decode budget, the 2,880 px decode cap, extent compensation, the 30-frame restore, auto-scroll at 30 / 60 / 120 px/s, the 900 ms auto-next, the edge prompts, feed windows of current ± 1 loaded within 4 pages of an edge) and S15 / S19.
6. `docs/redesign/prompts-plan.json`: the `mobile/00` entry (TRACK RULE) and this file's entry. The web twin `docs/redesign/prompts/web/34-reader-engine-glass-commands.md` (the same thresholds and vectors; keep names aligned where Dart allows).
7. Reports that name the engine API you extend: `docs/redesign/proof/mobile-00/report.md` (`ReaderEngine`, `ReaderEngineState`, `ReaderEngineCommands`, `ReaderSurfaceSlots`, `ReaderEngineView`), `mobile-12/report.md` (`pinchZoom`, `zoomAt`, `chapterCompleted`, `furtherElsewhere`, the builder slots, `autoScrollPxPerSecondX`), `mobile-13/report.md` (`setLayout`, `turnTo`, `pageAtReadingLine`, `ReadAllState`), `mobile-23/report.md` (`page_tint.dart`, `pageTint`, `panels`, `pageToViewport`, `setCamera`), `mobile-25/report.md` (`core/color/oklch.dart`, the motion recorder core, `/dev/glass`).
8. Code (read in full before planning): everything in `mobile/lib/features/reader/engine/`, `mobile/lib/features/reader/utils/{page_extents,page_layout,reader_scroll_controller,reader_feed_controller,reader_image_cache,reading_clock,scroll_storage}.dart`, `mobile/lib/features/reader/models/{reader_feed,reader_page,chapter_manifest}.dart`, `mobile/lib/features/downloads/services/offline_reader.dart` (how saved pages point at blob files), `mobile/lib/core/color/oklch.dart`, `mobile/lib/core/diagnostics/motion_recorder.dart` (or wherever `mobile/25` put the recorder core), the reader tests (`ls mobile/test/features/reader mobile/test/features/reader/engine`), `mobile/test/features/reader/engine/engine_boundary_test.dart`, and `~/.pub-cache/hosted/pub.dev/material_color_utilities-0.13.0/lib/quantize/{quantizer_celebi,quantizer}.dart` (`Future<QuantizerResult> quantize(List<int> pixels, int maxColors)`, `QuantizerResult.colorToCount`, ARGB ints).

## Preconditions (stop and report if any fails)

```bash
cd /srv/manhwamaniacs/dev/ManhwaManiacs
git branch --show-current                                          # feat/vps-slim-source-native
git log --oneline -40 | grep -i "mobile-33\|series sheet"           # mobile/33 landed
grep -rn "pinchZoom\|zoomAt" mobile/lib/features/reader/engine | head -3        # mobile/12
grep -rn "setLayout\|turnTo" mobile/lib/features/reader/engine | head -3        # mobile/13
grep -rn "pageToViewport\|setCamera\|pageTint" mobile/lib/features/reader/engine | head -5   # mobile/23
grep -n "^S1 \|^S11 \|^G6 \|^G14 " docs/redesign/signoffs.md     # the four sign-off lines backend/06 records
grep -n "material_color_utilities" mobile/pubspec.yaml             # 'any', from mobile/25
cd mobile && free -m && /srv/manhwamaniacs/dev/flutter/bin/flutter test 2>&1 | tail -3   # your floor
mkdir -p ../docs/redesign/proof/mobile-34 && free -m && /srv/manhwamaniacs/dev/flutter/bin/flutter test test/features/reader --reporter expanded > ../docs/redesign/proof/mobile-34/reader-tests-before.txt; tail -3 ../docs/redesign/proof/mobile-34/reader-tests-before.txt
```

If a grep above is empty, the step that owns it has not landed: stop and report which one. If `signoffs.md` has no G6 / G14 (or S1 / S11) record, stop and report: the owner must sign off client-side page samples and panel detection first. If `material_color_utilities` is absent and `mobile/25` recorded the ledger fallback, use the vendored `QuantizerCelebi` under `mobile/lib/features/reader/engine/quantizer/` instead.

## Skills to invoke

1. `superpowers:writing-plans` before any code. Save the plan at `docs/redesign/proof/mobile-34/plan.md`, listing the commits of sections A to I one by one, each with the tests that gate it.
2. `superpowers:test-driven-development` for every section: write the failing Dart test first (pure functions as plain `test`, engine behaviour as `testWidgets`).
3. `superpowers:executing-plans` inline. The engine is one controller and one view: do not split it across parallel subagents. One subagent may write the probe page and the fixture generator (section J) after sections A to I are committed; start its prompt with a scope lock, pass `model: "opus"`, and check its work against `git diff`.
4. `superpowers:systematic-debugging` if any existing reader test or Cinematic reader capture changes.
5. `superpowers:verification-before-completion` before you claim anything is done.
6. `impeccable:impeccable`, `taste-skill:taste-skill` and `frontend-design:frontend-design` are not needed: this step changes no pixels.

## Scope: deliver every item below

All code lives in `mobile/lib/features/reader/engine/` (pure helpers as `engine/<name>.dart` with `mobile/test/features/reader/engine/<name>_test.dart`). The engine keeps its boundary (`engine_boundary_test.dart`: no import of `/widgets/`, `/screens/`, `app/theme/`, `app/router/`, `features/reader/theme/` or `skins/`; it may import `core/`, including `core/color/oklch.dart`). The engine owns thresholds; skins only read state and call commands. Every new field, event and command is optional to use: Cinematic ignores them and keeps working unchanged. New events are `Stream`s on `ReaderEngine` (broadcast controllers closed in `dispose`), not new subclasses of the sealed `ReaderEngineEvent`, so no exhaustive `switch` in Cinematic's code has to change.

### A. The live channel for per-frame values (`engine/engine_live.dart` + test)

Three of the new values change every frame; notifying `ReaderEngineState` at 120 Hz would rebuild every chrome listener. So:

- `class EngineLive { final ValueNotifier<double> scrollVelocity; final ValueNotifier<double?> seamProgress; final ValueNotifier<double> overscrollExtent; }`, exposed as `ReaderEngine.live`; a `ValueNotifier` notifies only when the value changed.
- `ReaderEngineState` also carries the three fields, but the engine copies them into the state only on threshold changes: `scrollVelocity` when `|v|` crosses 3000 px/s either way or reaches 0; `seamProgress` when a seam enters (`null` → number) or leaves (number → `null`); `overscrollExtent` when it crosses 0, ±48 or ±72. Chrome that animates per frame listens to `engine.live` (`ValueListenableBuilder` or an `AnimatedBuilder`), never to the state.
- Test: the state changes only at the listed crossings for a synthetic sequence of 200 values; a listener of `live.scrollVelocity` is called once per changed value and never for an equal one.

### B. `currentPageSample` (step 1; §2.1.8 step 3)

1. `engine/page_sample.dart` + test:

   ```dart
   @immutable
   class PageSample {
     final Color? tint;                 // null for a greyscale page
     final Color top, bottom;           // mean sRGB of the top and bottom quarter
     final double lTop, lMid, lBottom;  // mean relative luminance: top quarter, middle half, bottom quarter
     final double pTop, pMid, pBottom;  // 95th-percentile relative luminance of the same bands
     final PageSampleSource source;     // manifest | decode
   }
   Future<PageSample> samplePageRgba(Uint8List rgba, int width, int height);   // pure, runs inside compute()
   ```

   Relative luminance is WCAG's (`c ≤ 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ^ 2.4`, then `0.2126 R + 0.7152 G + 0.0722 B`). Bands are rows `[0, h/4)`, `[h/4, 3h/4)` and `[3h/4, h)`. The 95th percentile is nearest-rank (`sorted[ceil(0.95 × n) − 1]`). `tint`: `await QuantizerCelebi().quantize(argbPixels, 16)`, entries of `colorToCount` sorted by count descending, the first whose OKLCH (`core/color/oklch.dart`) has `L ≥ 0.18` and `C ≥ 0.035`, else `null`; never `Score.score`. Equal `==` / `hashCode` over every field. Test vectors on 64 × 64 inputs: all `#FFFFFF` (tint null, every `l*` and `p*` 1.0); all `#000000` (tint null, all 0); top quarter white and the rest black (lTop 1, lMid 0, pTop 1); black with one 8 × 8 white square in the top quarter (lTop ≤ 0.07, pTop 1.0: the bubble counts); a flat `#E53935` page (tint `#E53935` within ±1 per channel); a horizontal grey ramp (tint null).
2. **The decode.** Extend `engine/page_tint.dart` (from `mobile/23`): for the page on the reading line, decode a `ResizeImage(provider, width: 64, height: 256, policy: ResizeImagePolicy.fit)` (at most 64 wide and 256 tall, aspect kept), read it with `toByteData(format: ui.ImageByteFormat.rawRgba)` on the main isolate, and run `samplePageRgba` in `compute()`. Cinematic's 16 × 16 `pageTint` path stays exactly as it is (its own decode, its own output): the tint vector parity test from `mobile/23` must keep passing byte for byte.
3. **The engine duty.** Sample the page under the reading line (38 % of the viewport height from the top in the strip; the visible page in paged layouts; the current page in guided view), at most every 600 ms while scrolling and once on settle (150 ms without a scroll notification); cache per page URL in an LRU of 500 entries (`engine/lru.dart` + test, only if no LRU exists under `features/reader/`). Rules, in the pure `resolveSample(PageSample? previous, PageSample next, int greyRun, List<Color>? coverPalette)` + test: a greyscale sample keeps the previous `tint`; after 6 greyscale pages in a row the `tint` becomes the cover palette's first colour (new optional engine input `coverPalette`, passed through `ReaderEngineView`); a manifest page `tint` (the field `mobile/23` added to the page model) paints first as `PageSample(tint: t, top: t, bottom: t, every l* and p* 1.0, source: manifest)` (unknown luminance means dim 0.64 until the decode lands); the decoded sample replaces it with `source: decode`. While `|scrollVelocity| > 3000` px/s the engine holds `currentPageSample` and publishes the latest sample when the speed falls below 3000. Posting samples on chapter exit (`POST /reader/page-tints`) stays as `mobile/23` built it.

### C. `scrollVelocity` (step 1; `engine/velocity.dart` + test)

A tracker over a 100 ms window of `(Duration timestamp, double position)` samples returning signed px/s (positive = forward: down in the strip, the reading direction in paged layouts), 0 after 100 ms without a sample; the engine feeds it from its `ScrollNotification` handler with the frame timestamp (`SchedulerBinding.instance.currentFrameTimeStamp`) and publishes through A. Test: constant 1,200 px/s motion reads 1,200 ± 1; a reversal flips the sign within one window; a stop reads 0 after 100 ms.

### D. `seamProgress` and seam events (step 1; §8.14.1; `engine/seam.dart` + test)

- `double? seamProgress(double seamTop, double seamHeight, double viewportHeight)`: `(viewportHeight − seamTop) / (viewportHeight + seamHeight)` clamped 0–1 while the seam overlaps the viewport, else `null`. The engine takes `seamTop` from its own extent table (it lays out the seam the `chapterSeam` slot draws: 96 px in continuous mode, 48 px in read-all), so nothing is measured from the skin's widget.
- `Stream<SeamEvent> get seamEvents` with `SeamEvent.readingLine(chapterId, direction)` when the seam's centre crosses 38 % of the viewport height (forward or back) and `SeamEvent.top(chapterId)` when the seam's bottom edge passes the viewport top going forward (the Glass seam chip and `chapter.seam` hang on these in `mobile/35`). Test both crossings, both directions, and that a seam wobbling ±2 px around the line fires once (a 4 px hysteresis).

### E. One at a time: `overscrollExtent`, `armNeighbour`, `commitNeighbour`, `continueFling` (step 3; §8.14.4)

1. **Chapter mode.** If the engine has no one-at-a-time mode yet (`grep -n "chapterMode\|ReaderChapterMode" mobile/lib/features/reader/engine/*.dart`), add the `ReaderEngineView` input `chapterMode: ReaderChapterMode.continuous | single` (default `continuous`, today's behaviour, untouched). In `single` the feed never appends a neighbour to the strip; the neighbours' manifests still load within 4 pages of an edge and the next chapter's first 3 pages are still decoded at 70 % of the chapter (the existing preload), so `armNeighbour` is instant.
2. `engine/neighbour.dart` + test, the pure rules: `const armPx = 48.0`, `const commitPx = 72.0` (from `thresholdChapterArm` / `thresholdChapterCommit` semantics; the engine holds its own constants because it may not import skin tokens); `double displayedFromRaw(double raw, double viewportHeight) => rubberband(raw, viewportHeight, 0.55)` and its inverse `rawFromDisplayed(y, d) = d / 0.55 × (1 / (1 − y / d) − 1)` (sign-preserving); the wheel mapping for hardware mice and trackpads, `wheelDisplayed(acc) = acc ≤ 140 ? acc × 48 / 140 : 48 + (acc − 140) × 24 / 70` with the accumulator reset after 400 ms without wheel input; `NeighbourPhase phase(double displayed)` returning `idle | armed | locked` (armed at ≥ 48, locked at ≥ 72; the same with negative values at the start of the chapter). Put the rubber band in `engine/rubber_band.dart` (the engine cannot import `skins/glass/physics/`; reuse `mobile/12`'s `rubberBand` in `zoom_math.dart` if it takes `c`). Test: 47 vs 48 vs 72 displayed; 139 / 140 / 210 wheel px; the 400 ms reset; `rawFromDisplayed(displayedFromRaw(x))` ≈ x within 0.01 px for x in 0, 50, 143, 800 on an 844 px viewport; the band at 0 and at the viewport height.
3. **Physics** (`engine/chapter_end_physics.dart` + test): in `single` mode the strip uses `ChapterEndPhysics extends ScrollPhysics` with the skin's own physics as `parent` (Glass's `BouncingScrollPhysics`), so everything inside the chapter scrolls exactly as before. Past `maxScrollExtent` (or before `minScrollExtent`) `applyPhysicsToUserOffset` maps the finger stateless through the inverse: `y0 = overshoot`, `x1 = rawFromDisplayed(y0) + delta`, `return displayedFromRaw(x1) − y0`, so the displayed overscroll follows §4.5 exactly. `createBallisticSimulation`: overscrolled below 72 displayed px → `ScrollSpringSimulation(overscrollReturn, pixels, extentEdge, velocity)` with the engine input `overscrollReturn` (default `SpringDescription(mass: 1, stiffness: 322.3, damping: 35.9)`, the `settle` spring); at or beyond 72 → `null` (the position holds and waits for `commitNeighbour`); inside the extent → the parent's. The engine publishes `overscrollExtent` (positive past the end, negative past the start) on every scroll notification and emits `Stream<NeighbourEvent> get neighbourEvents` with `NeighbourEvent(phase, direction, via: touch | wheel)` on each phase change. A wheel or trackpad scroll past the end (`PointerScrollEvent` / `PointerPanZoomUpdateEvent` while at the edge) drives the wheel mapping instead; at 210 px it emits `locked` with `via: wheel` and the skin commits at once with zero velocity. Test with `testWidgets`: on an 844 px viewport a drag of 93 raw px past the end reads 48.2 displayed and emits `armed`; 144 raw px reads 72.4 and emits `locked`; a release below 72 springs back to 0; a release at 72 holds.
4. **Commands** (on `ReaderEngineCommands` and `ReaderEngine`):
   - `Future<NeighbourInfo> armNeighbour(NeighbourDirection direction)`: makes sure the neighbour is ready (its manifest, its first page decoded) and resolves `NeighbourInfo {ChapterRef chapter, int pageCount, String firstPageUrl, int minutes}` (`minutes = (pageCount × 0.15).ceil()`; the skin shows "42 pages · about 6 min"); idempotent.
   - `void commitNeighbour(NeighbourDirection direction, {double velocity = 0})`: switches to the neighbour in place: the engine makes the neighbour (whose manifest is already loaded) its current chapter itself, resets the overscroll without animation, stores `velocity`, and then calls the new optional `ReaderEngineView` input `onReplaceChapter(ChapterRef chapter)`, which the Glass reader (`mobile/35`) answers with `GoRouter.of(context).replace(<the neighbour's reader path>)` under a constant page key, so its `State` and the engine survive and the location, the return route and progress saves follow the new chapter. Cinematic passes no `onReplaceChapter` and keeps its existing `onNextChapter` / `onPreviousChapter` paths untouched.
   - `void continueFling(double velocity)`: after the new chapter's first layout, starts `position.beginActivity(BallisticScrollActivity(position, FrictionSimulation(pow(0.998, 1000), position.pixels, velocity, tolerance: const Tolerance(velocity: 20)), vsync, false))` (or the equivalent `goBallistic` path with that simulation), which is `v ← v × 0.998^dt` per millisecond: it stops below 20 px/s or at the chapter's end, and any touch, wheel or key cancels it (a new activity replaces it). Pure `flingDistance(v0)` and `flingStep(v, dtMs)` + tests: the total distance from `v0` is `0.499 × v0` within 1 %, and one 8.33 ms step decays the speed by `0.998^8.33`.
   - Reduced motion is the skin's business (it commits with zero velocity); the engine never starts a fling with velocity 0.

### F. `swipeNeighbour` (step 3; §8.14.3 "Horizontal swipe"; `engine/swipe_neighbour.dart` + test)

- `Axis? lockAxis(double dx, double dy)`: `Axis.horizontal` once `|dx| > 2 × |dy|` after 10 px of travel, `Axis.vertical` once `|dy| > 2 × |dx|`, else `null`.
- `SwipeNeighbourState swipeNeighbour(double dx, {required double viewportWidth, required ReadingDirection direction})`: `displayed = dx.sign × rubberband(|dx|, viewportWidth, 0.35)`; `direction` is `next` for a leftward swipe in left-to-right series and `previous` for a rightward one, mirrored for right-to-left.
- `SwipeRelease releaseSwipeNeighbour(double dx, double vx, {required double viewportWidth, required bool hasNeighbour})`: `committed` when the projected raw travel `|dx + 0.499 × vx|` (capped at one viewport width) is past 96 px and a neighbour exists (the engine then calls `commitNeighbour(direction, velocity: 0)`), otherwise `cancelled`.
- Test: the lock at 10 px; the 0.35 band at 0, 100 and 400 px on a 390 px viewport; commit at 97 projected and not at 95; RTL mirroring; no commit without a neighbour.

### G. `pageLayerTransform` (step 4; §8.14.9)

`void pageLayerTransform(LensTransform? t, LensClip? clip)` with `LensTransform {double scale; Offset origin}` and `LensClip {Rect rect; double radius}` in viewport coordinates. The engine renders one layer it owns in its `Stack`, above the page list and below the chrome: an `IgnorePointer` → `Positioned.fromRect(clip.rect)` → `ClipRRect(borderRadius: clip.radius)` → `Transform(transform: scale t.scale about t.origin)` → a `Stack` of copies of the `ReaderPageImage` widgets whose pages intersect the clip (the same `ImageProvider`s, so the decoded images come from the image cache), positioned so that at scale 1 they line up with the pages beneath to the pixel. The strip never re-lays out; `null` removes the layer; the copies are re-positioned on the scroll handler's frame. Pure `List<LensPage> lensLayout(List<Rect> pageRects, LensClip clip, LensTransform t)` + test: at scale 1 every copy's rect equals its page rect relative to the clip; at 1.12 the origin point maps to itself; pages outside the clip are left out.

### H. `engageFromVelocity` and pixel-based cruise (step 5; §9.4.1)

1. If the engine has no pixel-based start, add `startAutoScroll(double pxPerSecond, {Duration ramp = Duration.zero})` and `setAutoScrollPxPerSecond(double pxPerSecond)` beside the existing `toggleAutoScroll()`, `setAutoScrollSpeed()` and `mobile/12`'s `autoScrollPxPerSecondX` path (all unchanged for Cinematic). `ramp` goes linearly from 0 to the target (`mobile/44` passes 400 ms). Positive values only (phones have no middle-click autoscroll).
2. `engine/cruise_engage.dart` + test: `double? engageSpeed(double v)` returns the multiplier `round(v / 60 / 0.05) × 0.05` clamped to 0.25–4 when the forward velocity `v` is within 15–240 px/s, else `null` (backward velocities never engage).
3. `void engageFromVelocity()` arms the duty: while cruise is on and the strip is coasting in a ballistic activity (a fling), the engine watches `scrollVelocity`; the first time the speed enters 15–240 px/s it ends the ballistic activity (`position.jumpTo(position.pixels)`), starts auto-scroll at that exact speed and emits `Stream<CruiseEngaged> get cruiseEngagedEvents` with the multiplier. A touch during the coast cancels the watch. Test `engageSpeed` at 14, 15, 60, 240 and 241 px/s and at −100 px/s, and one `testWidgets` fling that engages at ≤ 240 px/s.

### I. `panelBoxes` (step 1; §9.4.3 "Data")

A getter on `ReaderEngineState` over the `panels` entry `mobile/23` added for the current page: `List<Rect>? panelBoxes` in page fractions (`Rect.fromLTWH(x, y, w, h)`), `null` while the page is being analysed or has no result. It is not a second detector output. Test the mapping for a page with panels, a page without, and a page not analysed yet.

### J. The probe page, the 120-page check and the no-pixel proof

1. **Development probe** (`mobile/lib/skins/glass/dev/engine_probe_page.dart`, registered as `/dev/glass/reader-engine` beside `mobile/25`'s `/dev/glass` routes, outside the `ScreenId` map; a row "Reader engine probe" on the `/dev/glass` index): `?source=&series=&chapter=&mode=continuous|single` opens a real chapter; `?fixture=long-strip` opens the fixture of J2. It renders `ReaderEngineView` with plain slots (grey boxes, a 96 px seam box), no chrome, and a readout (`mono` 11/16 on a black band at the bottom) showing the five fields and the last seam, neighbour and cruise events, updated from `engine.live` and the streams. A "Run 120-page scroll" button drives `position.animateTo(maxScrollExtent, duration: maxScrollExtent / 6000 px/s, curve: Curves.linear)` inside a recorder entry named `STRIP SCROLL 120` in the motion recorder core, so the Glass motion-timings overlay (`mobile/25`) lists its frames, planned frames and dropped frames, and "Copy log" exports them.
2. **Fixture** (`mobile/lib/skins/glass/dev/long_strip_fixture.dart`): on first use it writes 120 PNGs of 720 × 2,880 into `getTemporaryDirectory()/mm-long-strip/` (a vertical gradient whose hue is `page × 3°`, a white 200 × 120 rounded rectangle at y 200 on every third page, drawn with `PictureRecorder` and encoded four at a time) and builds a 120-page `ReaderFeed` whose pages point at those files the same way `offline_reader.dart` points saved pages at blob files; the previous and next chapters are 3-page fixtures. Debug builds only (`assert` plus `kReleaseMode` guard).
3. **Widget test** `mobile/test/features/reader/engine/strip_120_test.dart`: pumps `ReaderEngineView` with a 120-page feed of declared 720 × 2,880 pages (the image stubs the existing reader tests use) at 390 × 844, scrolls from the top to the end in 8.33 ms frames at 6,000 px/s, and asserts: at most 12 `ReaderPageImage` widgets are mounted at any sampled frame (the virtualisation holds); `scrollVelocity` reads 6,000 ± 60 during the run and 0 after it; `currentPageSample` was requested at most once per 600 ms of scrolling; no exception. It writes the sampled figures to `<MM_PROOF_DIR>/strip-120.json` when `MM_PROOF_DIR` is set (the verification run sets it to `../docs/redesign/proof/mobile-34`) and writes nothing otherwise.
4. **Cinematic no-pixel proof:** capture the Cinematic reader harness groups (`mobile-12` and `mobile-13` in `mobile/test/screenshots/marketing_screenshots_test.dart`: chrome shown and hidden, strip and paged, at `kSkinShotSizes`, phone 390 × 844 and tablet 834 × 1194) before section A starts into `docs/redesign/proof/mobile-34/parity/before/` and after section I into `parity/after/` (the two `MM_PROOF_DIR` runs under Verification), and byte-compare every pair (`cmp`); every pair must be identical.

## Out of scope here (owned by later steps; do not build)

- Every pixel: the Glass reader chrome, capsules, cards, the seam chip, the lens and HUDs (`mobile/35`); cruise's pill and ramp use (`mobile/44`); guided view (`mobile/44`, on `setCamera` from `mobile/23`).
- Any change to Cinematic's reader chrome or behaviour. If a Cinematic reader test fails or a capture differs, the engine change is wrong.

## File layout

```
mobile/lib/features/reader/engine/
  engine_live.dart                                         A
  page_sample.dart  page_tint.dart (extended)  lru.dart (only if missing)  resolve_sample.dart   B
  velocity.dart                                            C
  seam.dart                                                D
  neighbour.dart  rubber_band.dart (only if zoom_math lacks a c parameter)  chapter_end_physics.dart   E
  swipe_neighbour.dart                                     F
  lens_layout.dart                                         G
  cruise_engage.dart                                       H
  panel_boxes.dart                                         I
  reader_engine.dart  reader_engine_state.dart  reader_engine_view.dart   extended
mobile/lib/skins/glass/dev/{engine_probe_page,long_strip_fixture}.dart   J1, J2
mobile/lib/skins/glass/router.dart                         the /dev/glass/reader-engine route only
mobile/test/features/reader/engine/{engine_live,page_sample,resolve_sample,lru,velocity,seam,neighbour,chapter_end_physics,swipe_neighbour,lens_layout,cruise_engage,panel_boxes,strip_120}_test.dart
docs/redesign/proof/mobile-34/                             plan.md, reader-tests-before.txt, reader-tests-after.txt, strip-120.json, parity/, device-check.md, report.md
```

No `ScreenId` leaves any `PENDING` map, and nothing under `mobile/lib/skins/cinematic/` changes.

## Acceptance criteria

- [ ] `ReaderEngineState` gains `currentPageSample`, `scrollVelocity`, `seamProgress`, `overscrollExtent` and `panelBoxes`; `ReaderEngine.live` carries the three per-frame values; `armNeighbour`, `commitNeighbour`, `continueFling`, `swipeNeighbour`, `releaseSwipeNeighbour`, `pageLayerTransform`, `engageFromVelocity` (and `startAutoScroll` / `setAutoScrollPxPerSecond` if they were missing) exist with the signatures above; `seamEvents`, `neighbourEvents` and `cruiseEngagedEvents` exist as streams; the `chapterMode`, `coverPalette`, `overscrollReturn` and `onReplaceChapter` inputs exist with the defaults above (Cinematic passes none of them).
- [ ] Page samples come from a 64 px (at most 64 × 256) decode with `QuantizerCelebi` in `compute()`, cached in an LRU of 500, taken at most every 600 ms and held above 3000 px/s; the greyscale and manifest rules hold; Cinematic's `pageTint` output and its parity test are unchanged.
- [ ] Thresholds match the DESIGN exactly: arm 48 and commit 72 displayed px on the 0.55 band, wheel 140 and 210 px with the 400 ms reset, the sideways swipe on the 0.35 band with a 96 px projected commit, the momentum carried by a 0.998-per-ms friction, the 1.12 lens scale supported, cruise engaging only within 15–240 px/s.
- [ ] Every unit and widget test of sections A to J passes with the exact vectors and boundaries listed; every reader test in `reader-tests-before.txt` still passes (`reader-tests-after.txt` beside it), and the full suite is at or above the floor plus the new tests (never below the 2012 passed of `00-baseline.md`: every test that passed there must still pass).
- [ ] The 120-page test passes (at most 12 mounted page images, the velocity readout, the sample cadence) and `strip-120.json` is written; the probe page runs on the owner's devices (device check).
- [ ] No pixel change: every Cinematic reader capture pair in `docs/redesign/proof/mobile-34/parity/` is byte-identical.
- [ ] Keyboard, hit targets and reduced motion: unchanged (no control is added); the engine never starts a fling or an engage from a zero-velocity commit.
- [ ] Boundary: `engine_boundary_test.dart` passes and `grep -rn "skins/\|/widgets/\|/screens/" mobile/lib/features/reader/engine` is empty.
- [ ] `flutter analyze` reports "No issues found"; `flutter test` passes at or above the floor plus the new tests (never below the 2012 passed of `00-baseline.md`: every test that passed there must still pass); `node design/build.mjs --check` passes.

## Verification

**RAM guard (production shares this box).** Before every heavy command run `free -m` and read the `available` column of the `Mem:` row. If it is under 1024 MB, stop and report instead of running it. Never run two heavy commands at once, never run `flutter test` while a `next build` runs (`pgrep -fa "next build"` prints nothing first), and no Gradle or Xcode on this box.

After each section's commit, from `mobile/`:

```bash
free -m && /srv/manhwamaniacs/dev/flutter/bin/flutter analyze
free -m && /srv/manhwamaniacs/dev/flutter/bin/flutter test test/features/reader
```

At the end:

```bash
free -m && /srv/manhwamaniacs/dev/flutter/bin/flutter test test/features/reader --reporter expanded > ../docs/redesign/proof/mobile-34/reader-tests-after.txt; tail -3 ../docs/redesign/proof/mobile-34/reader-tests-after.txt
free -m && MM_PROOF_DIR=../docs/redesign/proof/mobile-34 /srv/manhwamaniacs/dev/flutter/bin/flutter test test/features/reader/engine/strip_120_test.dart
free -m && MM_PROOF_DIR=../docs/redesign/proof/mobile-34/parity/after /srv/manhwamaniacs/dev/flutter/bin/flutter test test/screenshots/marketing_screenshots_test.dart --plain-name "mobile-12"
free -m && MM_PROOF_DIR=../docs/redesign/proof/mobile-34/parity/after /srv/manhwamaniacs/dev/flutter/bin/flutter test test/screenshots/marketing_screenshots_test.dart --plain-name "mobile-13"
free -m && /srv/manhwamaniacs/dev/flutter/bin/flutter test
cd .. && node design/build.mjs --check
```

**Proof output location.** The `mobile/03` harness (`mobile/test/screenshots/support/skin_shots.dart`) writes a capture only when `MM_PROOF_DIR` is set, so every proof command in this file sets `MM_PROOF_DIR` to `../docs/redesign/proof/mobile-34` or its `parity/before` and `parity/after` folders (relative to `mobile/`) and never `MM_WRITE_SHOTS`, which makes the legacy marketing tests overwrite `mobile/docs/screenshots/`, the install page's public screenshots. Capture routes with `captureSkinScreen` and everything that is not a route (a gallery section, a sheet or menu held open, a state pumped with fixture providers, a mid-animation frame) with `captureSkinWidget`, which writes `<name>-<size.name>.png`; the capture names in this file are those final file names. The only proof sizes are the harness constants: `kSkinShotSizes` (phone 390 × 844 at 3×, tablet 834 × 1194 at 2×), `kSkinShotTabletWide` (1024 × 1366; on Glass the desktop frame with the collapsed 76 px sidebar, on Cinematic the ≥ 900 px rows of §8.0.9) and `kSkinShotLandscape` (landscape phone 844 × 390). After every capture run, `git status --short mobile/docs/screenshots` must print nothing.

The before captures come from the same two commands with `MM_PROOF_DIR=../docs/redesign/proof/mobile-34/parity/before`, run before the section A commit; compare each pair with `for f in ../docs/redesign/proof/mobile-34/parity/before/*.png; do cmp "$f" "../docs/redesign/proof/mobile-34/parity/after/$(basename "$f")"; done` (no output means identical). `00-baseline.md` records `flutter analyze` with no issues and every test passing; keep both. This step changes nothing in `frontend/` or `backend/` (`git diff --stat origin/feat/vps-slim-source-native -- frontend backend` is empty), so `npm run lint`, `npm run build` and the backend pytest (`backend/.venv/bin/python -m pytest -q --no-header`) are not rerun except under the push rule.

**Device checks for the owner** (`docs/redesign/proof/mobile-34/device-check.md`, one line per check with an empty result box; iPhone through SideStore after CI builds the IPA, the Android flagship with a signed release APK built where the signing key lives): Settings → Diagnostics → Edition (debug) → GLASS, then Glass development → Reader engine probe → `fixture=long-strip`: "Run 120-page scroll" shows 0 dropped frames at 120 Hz in the Glass motion-timings overlay; a real 120-page chapter scrolled by hand end to end at 120 Hz with 0 dropped frames; `mode=single`: a pull past the end reads `armed` at 48 and `locked` at 72 in the readout and a fling-commit keeps scrolling the next chapter; `currentPageSample.source` turns `decode` within 600 ms of settling and `pTop` reads 1.0 on a page with a top bubble; the Cinematic reader looks and feels unchanged.

## Git

- Branch `feat/vps-slim-source-native`. One commit per section (A to I), each with its tests and `flutter test test/features/reader` green, then the probe and fixture, the 120-page test, and the proof. Conventional messages, for example `feat(reader-engine): overscroll extent with arm and commit for one-at-a-time chapters`.
- Stage explicit paths only, never `git add -A` or `git add .`: the web, backend and shared sessions commit in the same checkout.
- No Claude or AI attribution anywhere: no `Co-Authored-By` line, no "Generated with" line, no AI author. Never commit secrets or `.claude/`.
- Before every push: `git fetch origin` and `git diff --stat origin/feat/vps-slim-source-native...HEAD -- frontend`. If it lists files, run `free -m && npm run build` in `frontend/` first (never while `flutter test` runs) and push only if it passes; then `git push origin feat/vps-slim-source-native` after each working step.
- Never edit `backend/connectors/`. Never touch production containers or `/srv/manhwamaniacs/{app,data}`. Do not deploy.

## Report back

Reply with:

1. Done items A to J, each with its commit hash.
2. The final engine API: paste the added parts of `ReaderEngineState`, `ReaderEngineCommands` and the `ReaderEngineView` inputs, the `EngineLive` fields, and the stream and event types (`SeamEvent`, `NeighbourEvent`, `CruiseEngaged`, `NeighbourInfo`), so `mobile/35` and `mobile/44` can call them by name; and how `onReplaceChapter` is called during `commitNeighbour`.
3. The reader test list before and after (file and case counts) and the full-suite counts (passed, failed, skipped) before and after.
4. The `strip-120.json` figures and the line "120 Hz device run pending on the owner's hardware".
5. The no-pixel parity result for every capture pair and the folder `docs/redesign/proof/mobile-34/`.
6. `flutter analyze` and `build.mjs --check` results, the rubber-band reading of Read first item 3, and the lowest `free -m` available figure.
7. Open issues, each with its `glass/DESIGN.md` section.

Next prompt file: `docs/redesign/prompts/mobile/35-glass-manga-reader.md` (`docs/redesign/prompts/web/35-glass-manga-reader.md` is its web twin).
