# mobile-05 report

Items 1-14 delivered (see commits on redesign/L01). Screens: `*-phone.png` / `*-tablet.png` in this folder (sheets open/live half/full/loading/error, dialog arming/armed/heavy, toasts two/banner, menu, Quick look mid-Rise, Lightbox 1x/2.5x, certificate dialog/stamp, reduced variants, static sections).

Deviations and notes
- Sheet siblings in `CineReorderableList` shift in ReorderableListView's own 200 ms for a finger drag; programmatic moves use 240 ms easeSet (FLIP).
- Lightbox Hero flight uses Flutter's own curve with a straight RectTween; button close 320 ms, drag release 504 ms.
- Quick look puts the 96 px cover in the sheet body beside the credits (CineSheet's header is the fixed kicker/title row).
- Overlay routes capture the trigger's themes (`InheritedTheme.capture`) so tokens resolve when the navigator's own theme has none (gallery under Legacy).
- `import_boundary_test` now exempts third-party packages from the `/widgets/` ban (flutter_reorderable_grid_view).
- `hit_targets_test` skips adjacency for list rows and the select bar, and the 44 px minimum for display-only credits rows (`g-static-*`).
- Not fixed, not mine: mobile-11 tests `feature_screen_test` (title letters) and `target_spacing_test` (2) fail on `rootPipelineOwner.semanticsOwner` / timing in this Flutter.
- Web twin comparison and the impeccable/taste critiques were not run in this session.
