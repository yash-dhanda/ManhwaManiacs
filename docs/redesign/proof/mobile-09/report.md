# mobile-09 report: Cinematic Library shelf and browse

Tests: flutter test 4273 passed, 0 failed (floor 4140). flutter analyze: No issues found. `node design/build.mjs --check` passes.

## Done
A1-A9 (ShelfQuery, shelfQueryProvider with K15/K16 migration, listSeries tagIds/newOnly + renameTag, shelfProvider, tagsProvider/TagsController, manual_order, bulk_runner, offline_shelf, shelfContinueProvider), B1-B5 (LibraryHub, HubSlideSliver, tab row, swipe, back order), C1-C15, D (featureByFollow via the series detail), E (LibraryPoster, BookListRow), G (TagSheet).

## Screenshots by acceptance item
- Density/columns: library-wall, -compact, -list, -grid (phone, tablet)
- Browse sheet once: library-browse-sheet-phone; filters/tokens: library-filters-active
- Hub swipe: library-hub-mid-swipe-phone; hover: library-hover-tablet
- Select/bulk/unfollow: library-select, library-bulk-running-phone, library-unfollow-dialog-phone
- Manual order: library-manual-order-phone; novels: library-books; tags: library-tag-sheet-phone; Quick look: library-quick-look-phone
- States: library-loading, -empty, -filtered-empty, -search-empty, -offline, -error; text 2.0 and reduced motion; feature-by-follow-notfound-phone
- Web twin (web-09) proof did not exist; no comparison made.
- Covers show as title plates: the shot host does not serve the fixture cover bytes to CineImage in this group.

## Shared API
ShelfQuery, shelfQueryProvider, shelfProvider, shelfCountsProvider, shelfContinueProvider, tagsProvider, TagsController, runBulk, summarizeBulkOutcome, changedSortOrders, offlineShelf, HubShellScope, LibraryHub, HubSlideSliver, LibraryPoster, BookListRow, showTagSheet, showAddSeriesToShelfSheet.

## Choices and conflicts
- shelfProvider/counts/continue are not in profileScopedInvalidators (they depend on the profile, so invalidating them from the switcher is a CircularDependencyError); they are in the 18+ list, reading the gate instead of watching it.
- CineShell's back press now runs the active modal state's handler (CineBackOrder.handleBack), so select mode exits first.
- Fixed primitives: CineReorderableWall keys (String), CineSegmentedControl hit height, CineRowShell `tight`, QuickLookAction `disabled`, CineQuickLookTarget semantics.
- ReadState gained optional lastReadAt; the server does not send it yet, so the LIST last-read column shows a dash.
- Sort menu shows the "Clear filters to reorder." caption as a semantics hint, not visible text.
- Reduced-motion release fades the content over 150 ms; sort icon is arrow-line-down (no arrows-down-up glyph in the set).
