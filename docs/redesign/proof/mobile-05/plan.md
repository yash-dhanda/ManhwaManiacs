# mobile-05 plan

Order (each commit small, analyze + tests before the next):
1. network: `ApiError.retryAfter`, `busy_retry_interceptor`, `dbBusyExhaustedProvider` (reuses `parseRetryAfter` from `request_limiter.dart`, re-exported by `retry_after.dart`).
2. motion additions: `CineFolioFlip`, `CineHighlightSweep`, MotionName wiring for Insert/Rise/Arm/Lightbox.
3. sheets (`sheet_physics`, `CineSheetRoute`, `CineSheet`), test first.
4. dialogs: `arm.dart` pure machine, `CineDialogRoute`, `CineDialog`, `CineConfirmDialog`, inline confirm, commit-with-undo.
5. toasts and host.
6. contents tabs, rows, swipe row, reorder list and wall.
7. slider, scrubber, switch, checkbox, radio, stepper.
8. menu, select field, quick look.
9. notice, content mode, pull to reprint, select bar, banner strip.
10. certificate, lightbox.
11. gallery sections, widget tests, screenshot harness group, proof.

Packages: `custom_refresh_indicator` 4.0.2 (`CustomRefreshIndicator(onRefresh, trigger: ..., builder: (context, child, controller))`, `IndicatorController` value/state/isArmed), `flutter_reorderable_grid_view` 5.7.0 (`ReorderableBuilder(children, onReorder: (ReorderedListFunction), builder: (children) => GridView(...))`).
