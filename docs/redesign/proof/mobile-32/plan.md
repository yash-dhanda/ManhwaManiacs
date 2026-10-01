# mobile/32 plan: Glass Library hub, Updates, Downloads

Glass Library hub (shelf, collections, history, bookmarks), Updates and Downloads under
`mobile/lib/skins/glass/screens/{library,updates,downloads}`; skin-neutral helpers under
`mobile/lib/features/{library,updates,downloads,collections}`. Glass stays behind the debug Edition row.

## Section A commits (shared data layer, each with its unit test, test first)

1. A1 `shelf_query.dart`: `readingStatus`, `tab`, `search`/`is_favorite` aliases, precedence, Cinematic params unchanged (`shelf_query_test.dart`).
2. A2 `glass_density.dart`: steps, `gridMin`, `gridColumns`, `pinchSteps`, `wheelSteps` (`glass_density_test.dart`).
3. A3 `glass_density_provider.dart`: per-profile key and the K15/K16 migration (`glass_density_provider_test.dart`).
4. A4 range paint: reused from `mobile/28` (`primitives/select/select_paint.dart` `rangeBetween`), no new file.
5. A5 `updates_repository.dart`: `checkNow()` outcomes, `checkSeries`, `getRun`, `listUpdateSources` (`check_now_test.dart`).
6. A6 downloads: `glassStorageMeter`, `activeDownloadCount` + `badgeText`, `moveInQueue` + queue order key, `QueueSummary.pacedUntil` / `signedOut` (four tests).
7. A7 Remove-from-library Undo: verified with `library_series_actions_undo_test.dart`.

## Screen-family commits

1. Hub and shelf: `library_hub.dart` (one page key, pager, `replace` on settle, `?tab=` alias), `library_section.dart`, shelf page, toolbar, grid, list rows, filters / manage tags / density sheets, select mode and bulk bar, manual order, keys.
2. Density: `density_pinch.dart`, `flip_grid.dart`, the column slider sheet, the tablet segmented control.
3. Collections: list, card with fanned stack, detail with header fan, form sheet, Add series sheet with Cover arc.
4. History and bookmarks: tiles, segments, Load more, outbox sync, filter chip, note sheet.
5. Updates: page, notification list, followed list, recent checks, run sheet.
6. Downloads, badge and accessory: page with Chapters / Queue / Storage, meter capsule, series cards with Drain, OCR banner, queue tab with reorder, storage tab, Save to Files global sheet, dock badge and Downloading accessory feed.
7. Router: the seven ScreenIds out of `PENDING`, `/downloads` inside the Library branch.

## Tests and proof

1. Widget tests under `test/skins/glass/{library,updates,downloads}/` (hub, shelf interactions, sections, a11y guidelines, downloads, updates).
2. Harness: `test/screenshots/glass/mobile_32_library_hub_shots_test.dart` into this folder.
3. Cinematic byte-compare: the `mobile-24 screens` group of `cinematic_qa_shots_test.dart` on the base tree and on this branch, `cmp` per PNG of library, collections, updates and downloads.
4. `report.md` and `device-check.md`.
