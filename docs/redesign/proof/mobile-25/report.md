# mobile/25 report

Delivered: dependency commit; `skin_glass.dart` (liquid, frost, solid, twins, group, registry, stacking rule, materialise, dim fold, growth); painters (rim, shadow, glow, sweep, caustic, follow ring, focus ring); light angle; palette and `Lb`; ambient field; physics; motion table (116 rows) with recorder and overlay; `GlassHaptics`; prefs bridge; orientation lock; `mm/platform` additions on Android, iOS and Dart; `/dev/glass` and `/dev/glass/calibration`.

Deviations and notes:
- The generated `tokens.g.dart` already owns `GlassType` and `GlassFinish`; the new type resolver is `GlassTypeStyle` and the finish enum is `GlassFinishKind`. `GlassTier` (generated) is distinct from `GlassTierId`.
- `LiquidGlass.grouped` is not public in liquid_glass_widgets 1.7.2; groups use `AdaptiveGlass.grouped` inside `AdaptiveLiquidGlassLayer`.
- `prepare()` and its boot wiring already existed from mobile/03; the gate page stays (legacy Diagnostics still routes to it until release/00).
- Gate decision line in mobile-03 is still open: `kGateRenderer = liquid`, frost where shaders are unsupported.
- `PageSample` is a local stand-in (TODO mobile/35); no per-profile a11y store existed, so keys `mm.a11y.p<profile>.*` were created.
- No OKLCH or recorder existed outside Cinematic, so both were written new in `core/`.
- glass/DESIGN.md wins over the prompt where they differ; none found beyond the above.
- Cinematic: zero diff under `lib/skins/cinematic`; shared boot untouched, so its captures cannot change (no byte compare run).
- CI gate not run (no push in this lane).

Verification: `flutter analyze` No issues; `flutter test` 2252 passed, 0 failed (floor 2160); `node design/build.mjs --check` passes; frontend/backend untouched.
