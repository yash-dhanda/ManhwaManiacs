# mobile/26 plan: Glass primitives 1

Built on the `mobile/25` foundation (`SkinGlass`, `GlassMotion`, `GlassHaptics`, physics, prefs, registry).

1. Pure logic first, each with a test: `hold.dart` (hold machine), `poster_throw.dart` (lift and throw decision),
   `wave.dart` (delays), `segmented_math.dart`, `rail_columns.dart`, `poster_grid_math.dart`, `reveal_slots.dart`.
2. `press.dart` (`GlassPressable`, `GlassWidgetStates`, `GlassPressRecognizer`), `lit.dart` (one lit object), `tooltip.dart`, `keycap.dart`,
   `progress.dart` and `liquid_progress.dart`, `glyphs.dart` (the Phosphor names the generated file does not carry).
3. Controls: buttons (+ split, progress, hold), icon buttons and group, text field and area, search, chips, segmented, badges.
4. Content: posters, rails and the rail group, skeletons and the wave, cards, profile orbs and the goal ring.
5. The two reveals: `letter_reveal.dart` and `typed_headline.dart`, with the slot queue and the session set.
6. The gallery at `/dev/glass/primitives`, the tests of item S, the captures, `report.md` and `device-check.md`.

Executed inline by one session: the Agent tool was not available in this lane, so nothing was split across subagents.
