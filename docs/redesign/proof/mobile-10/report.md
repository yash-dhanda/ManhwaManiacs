# mobile-10 report: Cinematic Updates, Collections, History, Bookmarks

Tests: full `flutter test` 4408 passed; 2 failed in that run (the Glass completeness test, fixed to be skin-aware, and a flaky `image-viewer-zoomed` Glass shot that passed on rerun with the fixed test and all hub tests: 161 passed). Floor 4273 (mobile/09). `flutter analyze`: No issues found. `node design/build.mjs --check` passes.

## Done
A1-A8 data layer (collection rules/previews/createdAt and member-order PUT; `smart_shelf.dart`; `collection_order.dart` and recently created sort; `history_continue.dart` moved in its own no-pixel commit; `history_pages_provider.dart`; `notification_grouping.dart`; `getRun`, `listUpdateSources`, settings, seen ids; bookmark note upsert, `BookmarkDeletedElsewhere`, restore), each with tests. B1-B12 Updates. C1-C9 Collections. D1-D7 shelf page. E1-E7 History. F1-F8 Bookmarks. G wiring (five ids out of PENDING). H estimate: PROCEED, Flutter 5 CCD.

## Screenshots (proof folder)
updates-*, collections-*, collection-*, history-*, bookmarks-*, hub-reduced-motion-phone, hub-text-2.0-phone; wide shots for the admin aside and two-column Bookmarks. Each state of B10, C8, D6, E6, F7 has a phone and (where listed) tablet frame. Covers render as title plates (the shot host does not serve fixture bytes for these paths). Web twin proof (web-10) did not exist: no comparison.

## Choices and conflicts
- Smart shelves: `format` and `content_kind` are not on a follow; the evaluator takes callbacks (source kind from the content-mode index) and ignores a rule whose value it cannot get.
- Bookmark Undo restores under a fresh client id (a tombstone is terminal on both sides).
- `CineCollectionPlate` now draws four vertical strips (prompt) instead of 2x2; added `CineCollectionMosaic`, tint, Hero, handle and menu.
- Compact `CineSearchField` text node now has a 44/48 hit height (a11y guideline failed in the Add series sheet).
- Stop-press banner: it sat above the Navigator with no Overlay, so its Dismiss tooltip threw; wrapped in `Overlay.wrap`. Landing on Updates by `go` and hiding on Updates verified by test.
- Phone Custom order uses `CineReorderableList` with a delayed drag listener and the handle, not `SliverReorderableList`.
- `sound impress` does not exist; `follow.add` sound used.
- The iOS edge-swipe reversal of the match cut is the shared `SwipeablePage` path (mobile/06 tests); here the header Hero has `transitionOnUserGestures` on iOS and the route timings are 480/336 ms (tested). Finger-tracked drag is in the device checklist.
- `mature_invalidators_test` was failing on the merged tree because `circle_service` (backend) now filters on the 18+ gate; it is listed as having no client cache until mobile/22.
- Owner-only device checks: device-checklist.md and docs/redesign/owner-todo.md.
