# mobile/27 report

Captures come from `mobile/test/screenshots/glass_overlays_shots_test.dart` (frost path; shader glass does not run under `flutter test`).

| Capture | Proves |
|---|---|
| `<section>-phone.png`, `-tablet.png` (sheets, alerts, toasts, tabs, sliders, toggles, menus, notices, scroll, pull, mode) | every component of A to M with its states in the gallery on phone and tablet |
| `<section>-solid-phone.png` | Solid glass recipes |
| `<section>-reduced-phone.png` | reduced motion |
| `sheet-peek/medium/monolith-phone.png` | sheet detents, inset, material |
| `alert-confirm-phone.png`, `alert-three-phone.png` | alerts bloom, stacked actions |
| `toast-error-phone.png`, `toast-undo-phone.png` | toast host, rim |
| `menu-open-phone.png` | menu bloom |

Notes: fixed a build-phase setState in `GlassLitState` (an alert mounting called suppressLit during build); status capsule text is now Flexible; the gallery mounts `GlassToastHost`; dev route `/dev/glass/primitives/sheet/:id` serves demo sheets. No web-27 captures to compare. Device-only checks in `device-check.md`.

## Fix pass 1: capture map per acceptance item

| Acceptance item | Captures |
|---|---|
| A to M in the gallery on phone and tablet | `<section>-phone.png`, `<section>-tablet.png` for sheets, alerts, toasts, tabs, sliders, toggles, menus, banners, image-viewer, scroll-edges, pull-to-refresh, content-mode |
| Solid glass / Increase contrast / Reduce motion | `<section>-solid-phone.png`, `<section>-contrast-phone.png`, `<section>-reduced-phone.png` |
| Sheets, geometry, recession | `sheet-peek/medium/monolith-phone.png`, `sheet-large-recession-phone.png`, `sheet-stacked-phone.png`, `sheet-rubberband-phone.png` (drag held above the top detent), `sheet-keyboard-phone.png` |
| Tablet and desktop frames | `panel-tablet.png`, `window-tablet.png`, `detail-window-tablet.png`, `offer-popover-tablet.png` |
| Alerts | `alert-confirm-phone.png`, `alert-three-phone.png`, `alert-from-source-phone.png` (mid-bloom), `alert-error-phone.png` |
| Toasts | `toast-error-phone.png`, `toast-undo-phone.png`, `toasts-stacked-phone.png`, `toast-undo-rim-phone.png` |
| Menus | `menu-open-phone.png`, `menu-bloom-phone.png` (mid-bloom), `context-lift-phone.png` |
| Image viewer | `image-viewer-zoomed-phone.png`, `image-viewer-dismiss-drag-phone.png` |
| Pull to refresh | `pull-droplet-60px-phone.png`, `pull-snapped-phone.png` |
| Scrub rail and speed dial | `scrub-lens-phone.png`, `speed-dial-phone.png` |

Section names follow the prompt now (`notices` is `banners`, `scroll` is `scroll-edges`, `pull` is `pull-to-refresh`, `mode` is `content-mode`).

## Measured layers and shapes (glass 15.7 phone case)

Nav-row group 3 shapes plus dock group 2 shapes (registered by hand; the bars belong to mobile/29), plus the real overlay: with a sheet and a toast 3 layers, 6 shapes, 0 scrims; with a menu 3 layers, 6 shapes; a context menu adds its `dimContext` as a scrim, not a layer. The registry constant `kGlassLayerBudget` is 6 while the prompt says 4; the tests assert at most 4 measured. (A defect found here: toast, alert and capsule surfaces sat inside their own `GlassHost` and drew the twin, so they registered no layer; fixed, see plan.md.)

## smooth_sheets 1.2.0 API names used

`ModalSheetRoute`, `Sheet`, `SheetController`, `SheetOffset`, `SheetPhysics` with `SheetPhysicsMixin`, `SheetSnapGrid`, `DragSheetActivity`, `SheetUpdateNotification`, `animateTo`. The plan's `GlassModalSheet` is replaced by `GlassSheetPage`/`GlassSheetRoute` per glass 15.10 G15.

## Web twin differences

No `docs/redesign/proof/web-27/` captures exist yet; nothing to compare. Frost path only under `flutter test`.
