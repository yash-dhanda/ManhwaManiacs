# mobile-09 plan

1. Shared data layer (`features/library`): ShelfQuery + persisted provider with K15/K16 migration, list params (tag_ids, new_only, sorts), renameTag, shelfProvider / shelfCountsProvider / shelfContinueProvider, TagsController create/rename/delete, manual_order, bulk_runner, offline_shelf, shelf_labels. Tests first for each.
2. Parts: LibraryPoster, BookListRow, TagSheet; bulk AddToShelf sheet.
3. Hub: HubSlideSliver (paint and hit-test shift, neighbour proof), LibraryHub (masthead, pinned tab row, finger-tracked swipe, spring release).
4. Shelf screen: toolbar (phone and >= 768), Filters sheet, Continue cuttings, wall/list/books, manual order, select mode and bulk actions, Quick look, states, shortcuts.
5. featureByFollow resolves through the series detail; stand-ins from earlier steps replaced (tag sheet, shelf sheet, catalogue book row).
6. Tests, gallery section, screenshots, report.
