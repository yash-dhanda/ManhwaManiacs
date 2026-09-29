# Dependency gate (mobile/02, lane L01)

| Package | Pin | flutter pub get | Fallback |
|---|---|---|---|
| haptic_feedback | 0.6.5 | resolved | none |
| gaimon | 1.5.0 | resolved | none |
| flutter_soloud | 4.1.7 | resolved | none |
| share_plus | 12.0.2 | resolved | none |
| audio_service | 0.18.19 | resolved | none |
| sensors_plus | 7.1.0 | resolved | none |
| flutter_dynamic_icon_plus | 1.4.1 | resolved | none |
| flutter_animate | 4.5.2 | resolved | none |
| swipeable_page_route | 0.4.8 | resolved | none |
| custom_refresh_indicator | 4.0.2 | resolved | none |
| flutter_reorderable_grid_view | 5.7.0 | resolved | none |

`meta` 1.18.0, `win32` 5.15.0, `go_router` 14.8.1 unchanged. `phosphor_flutter` and `dependency_overrides` absent.

CI jobs (`android-apk`, `build-ios`, tests): NOT RUN by this lane (lane rule: no push, integrator pushes). Run ids: PENDING at the integrator. Native build never run on this box. If a native job fails, apply that package's ledger fallback in a new commit.
