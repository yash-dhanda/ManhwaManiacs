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
- Cinematic: zero diff under `lib/skins/cinematic`; shared boot untouched, so its captures cannot change (byte compare below).
- CI gate not run (no push in this lane).

Verification: `flutter analyze` No issues; `flutter test` 2252 passed, 0 failed (floor 2160); `node design/build.mjs --check` passes; frontend/backend untouched.

## Cinematic byte compare
Tonight and Library, 390x844 and 834x1194, captured with MM_PROOF_DIR on base 59c65cef and on HEAD: all four PNGs are byte-identical (`cmp`).

## Importer rule
`glass_engine.dart` shader init now lives in `glass/liquid.dart`; the device-gate page moved to `glass/gate_demo.dart` (still routed from diagnostics until release/00 deletes it). Only `skin_glass.dart` and `glass/` import liquid_glass_widgets.

## Open issues (fix pass 2)

- CI gate: the integrator must push ab485312 alone and paste the `tests` and `Build iOS` run URLs into resolution.md.
- Renderer decision: `kGateRenderer` stays `GlassRenderer.liquid` until the owner's device pass sets the Decision line in mobile-03/glass-gate.md; frost fallback is in place.
