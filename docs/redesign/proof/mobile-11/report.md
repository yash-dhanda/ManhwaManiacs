# mobile-11 report (lane L25): PARTIAL

The Cinematic primitives (mobile/04-10) are not integrated, so the series page is built on local stand-ins marked `TODO(mobile/NN)`.

## Done
- A: skipped. `web/11` (owner of the backend fix) has not finished; `mature_override: null` still does not clear on the server.
- B1 enrichment, B2 suggested tags (new `features/ai/`), B4 repoint + `mappingSentence`, B5 `timeHere`, B6 `chaptersUpTo` / `undoMarkReadKeys`, B7 download mark state/label/tooltip, B8 `describeRun`, B9 `seriesDownloadSummaryProvider` (the legacy widget is NOT rewired), B10 chapter sort store, B11 `clearMatureOverride`, B12 `tocWindowAround` / `extendTocWindow`, B13 `isNovelSource(scope, id)`; each with tests. B3 reuses `ocrCoverageProvider`.
- C: `FeatureScreen`, `FeatureByFollowScreen`, `FeatureView` (one page for both routes); `feature` and `featureByFollow` are out of Cinematic `PENDING`.
- D (partial): phone hero and tablet spread, follow / favourite / notify, split primary, Read all, CHAPTERS (rows, order, go-to, select, row menu with Mark read / up to here / Download), DETAILS (At a glance, drop cap, genres, enrichment credits, suggested tags, OCR coverage), overflow with the `mature_override` radio, Move to another source, Lightbox, states (galley, CORRECTION, NOT IN THIS ISSUE).
- E (partial): Book front matter, actions, windowed contents, contents search sheet, picking chapters.
- F (partial): selection bar with quick picks, running line, summary line, series download card, all through `enqueueChapters`.

## Not done
See open issues in the lane summary: Mark unread and Undo (need mobile/08 `manualReadRows` / `deleteProgress`), tags add / remove, shelves, Bookmark start, ambient wash, SetHeading, Column wipe, match cut, rating card, prefetch, haptics and sounds, hardware keys, screenshots, motion timings, device checklist.

## Tests
- New: 11 data-layer tests, 7 widget/logic tests in `test/skins/cinematic/feature/`.
- `import_boundary_test` now lets a skin import its own `screens/` and `widgets/` folders (its own layout requires it).
