# mobile/03 plan

Slices, one commit each, in this order:

1. Plan (this file).
2. Font files (16 TTFs from google/fonts 23e54b5), OFL texts, MIT Phosphor text, `SOURCES.md`.
3. `tool/fonts/subset_google_sans_flex.sh` and the built `GoogleSansFlexMM.ttf` (axes wght, opsz, ROND, GRAD; Latin Extended-A kept).
4. `pubspec.yaml` fonts and licences, `font_licenses.dart`, `main()` call, `loadAppFonts()` map, `fonts_test`.
5. `CineIcon`, `GlassIcon`, `PhosphorDuotoneIcon`, `icons_test`, phosphor import assertion.
6. Screenshot harness: `skin_shots.dart`, the `skins` group, the widget-capture naming test.
7. Sources limiter and its tests, then the Dio wiring.
8. Glass gate, gated by CI in the original prompt:
   a. `liquid_glass_widgets: 1.7.2` pin alone (pubspec, lock, pin test, `pub-deps.txt`).
   b. CI gate (tests incl. android-apk, build-ios). In this lane the integrator pushes, so the gate is left to the integrator and recorded in the report.
   c. `glass_engine.dart`, `GlassSkin.prepare()`, gate screen, Diagnostics row, tests.
9. `glass-gate.md` checklist and proof PNGs.

Verification: `flutter analyze`, `flutter test`, then the proof run with `MM_PROOF_DIR` and `MM_PROOF_SCREENS=tonight,library,settings`.
