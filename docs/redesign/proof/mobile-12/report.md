# mobile/12 report (partial)

Status: partial. Engine work (A), preferences, Up next, route registration, system-bar decision, chrome and most strip pieces are in; several acceptance items are unproven or unbuilt (see Open issues).

## Done by scope letter
- A: `pinchZoom`, `zoomAt`, `jumpToPage`, `scrollByViewport`, `seekToChapter`, `setAutoScrollSpeedX`, `chapterCompleted`, `furtherElsewhere` state + `reportServerProgress`, `endPull` / `topPull`, `ReaderEngineOptions` (ground, gap, column, side margin, colour filter, tap window/slop, tap handler, auto-hide thresholds, pinch + pan, page state / band / credits / page semantics slots, footer, top band, offline, page layer), `TapClassifier`, `zoom_math`, `autoScrollPxPerSecondX`, `PaceTracker`, `NextChapterAutoQueue(saveNextEnabled)`, reader preferences record + one-time migration (`readerPrefsProvider`, `readerSeriesPrefsProvider`, `readerPrefsMigrationProvider`), `upNextProvider`, `AiRepository.similar`. A10 was already on the branch.
- B: `reader` registered (manifest and source aliases), `readerLanding` redirects to `/library`, both out of PENDING; `CineReaderRoute.manifest/source` over `skins/reader_entries.dart`; skin-neutral `readerFramesProvider` seam.
- C: mobile/06's route page is reused (durations, blades, Dip, snap); `leaveReaderByDip`, `PopScope`, iOS `canSwipe` narrowing.
- D: `readerSystemUi` decision + applier, tested.
- E-N: running head, folio bar, ruler, counter field, micro progress, zoom chip, edge HUD zones, dimmer / warmth / colour, seam / top / next-loading / rate-limited bands, broken page, credits (compact + full, Coming up card, pull to continue), caught up / the end notices, next failed, offline end, Contents sheet + tablet panel, keys (Reader group), lock mode, auto-hide, cinema, chapter swipe recogniser, toasts.

## Sign-off
`docs/redesign/signoffs.md` lines 3 (S1) and 4 (S11), by backend/06.

## Engine API (Dart names)
`ReaderEngine.pinchZoom(focal, scale, velocity, {min, max, snapStep, rubberBand, released})`, `zoomAt(point, scale, {duration, curve, spring})`, `chapterCompleted`, `reportServerProgress(...)`, `ReaderEngineState.furtherElsewhere`, `ReaderEngineOptions.{pageStateBuilder, bandBuilder, creditsBuilder, pageSemantics, pageLayerBuilder}`, `autoScrollPxPerSecondX`. Preferences: `readerPrefsProvider(seriesRef)`, `readerSeriesPrefsProvider`, `readerSettingsProvider`.

## Deviations
- Pinch reads raw pointers in a `Listener` (recorded in the prompt), no `ScaleGestureRecognizer`.
- Strip column is capped at 768 px by the page geometry (stripWidth 769-860 is clamped).
- The page gap is drawn over the foot of each page so extents stay exact.
- The 250 ms pull fade is the reader route's 440 ms Dip.
- Compact credits live inside the 96 px seam band.

## Tests
Reader engine and skin suites pass; full `flutter test` last run: 4234 passed, 1 failed (`lifecycle_test` over a reader, fixed after). `flutter analyze`: No issues found. Screenshots: `reader-chrome-{phone,tablet}.png` only (page art did not load in the harness).

## Open issues
- `furtherElsewhere` is not fed by the outbox (the batch answer carries counts, not the server row); the toast path is built and the engine API tested.
- Rate-limited band has no live source (the limiter exposes no Retry-After).
- Screenshots for the other states, widget tests for wipe/system-bar/reduced-motion/screen-reader rows and the Contents tests are not written.
- Guided view, paged layouts, read-all and the Reading setup sheet are mobile/13 and mobile/23.
