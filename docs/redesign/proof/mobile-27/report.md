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
