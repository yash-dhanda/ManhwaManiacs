# Dependency resolution gate (mobile/25 A)

Resolved locally on Flutter 3.44.6 by `flutter pub get` (commit ab48531):

- motor 1.1.0 (direct main)
- heroine 0.7.2 (direct main)
- smooth_sheets 1.2.0 (direct main)
- material_color_utilities (any) -> 0.13.0 (SDK pin)
- flutter_soloud 4.1.7 and share_plus 12.0.2 unchanged; no dependency_overrides. `tests.yml` already prints `flutter pub deps --style=compact` after "Resolve packages".

CI run URLs: NOT AVAILABLE. This lane may not push; the integrator must push commit ab48531 alone, watch `tests` and `Build iOS`, and paste both run URLs here. No ledger fallback was needed locally.
