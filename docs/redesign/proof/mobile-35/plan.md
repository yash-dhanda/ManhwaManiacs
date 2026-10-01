# mobile/35 plan: Glass manga reader

Floor (before any change, merged base 3b5dac7b): `flutter test` 7676 passed, 9 failed (sqflite migration audits, glass shell shots, shell budget; all pre-existing).

Order (one commit per step):

1. Section A: `glass_reader_values.dart` read-time values over mobile/39's `glass` object (legacy K05/K07/K09/K10/K11 fallbacks, writes only to `glass.*`, per-series `cruiseSpeed`) + test.
2. Engine options (skin-neutral, defaults = legacy): `pinchMin`/`pinchMax`, `rubberBandMax`, `legacyWakeAndLock`. Tap bands, `pageBy(fraction)` and `doubleTapWindow/Slop` are already covered by `tapHandler`, `scrollByViewport` and the existing options.
3. Native `display.stableInsets` (MmPlatformChannel.kt, where the `mm/platform` channel lives) + Dart wrapper + mocked-channel test. CI check is the integrator's (no push from a lane).
4. Pure helpers with tests first: page tint (clampTint, rimTint, deltaE, gate), bandLb, brightness band math, reader gestures, panel fit, reader keys. Swap lb.dart's PageSample stand-in for the engine's. `SkinGlass.tint`.
5. Reader screen: routes (both entry points, constant page key), system UI, orientation, insets, light layers, band, chrome (top groups, bottom capsule, pill, rail, popover), cinema, locked, keep-awake, seams and boundaries, paged, settings sheet, chapter list, dialogue overlay, hit lens, landscape, desktop panels and gutters, states, keys.
6. Widget tests, then the harness captures into this folder, then the report.
