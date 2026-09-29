# mobile/25 plan (Glass foundation)

1. Dependency commit: motor 1.1.0, heroine 0.7.2, smooth_sheets 1.2.0, material_color_utilities any (one commit, pubspec + lock).
2. mm/platform: a11y.reduceTransparency, a11y.contrastLevel, audio.isMusicActive, gestures.setExclusionRects (haptics.systemEnabled already existed); Dart wrapper `core/platform/mm_platform.dart`.
3. Pure core (TDD): physics, OKLCH, tier math (foldDim, lerpTier), registry, palette, Lb.
4. SkinGlass (liquid + frost + solid + twins), rim, glow, sweep, caustic, follow ring, focus ring, light angle.
5. Ambient field, motion table + recorder + overlay, haptics service, orientation lock, prefs bridge.
6. Dev surfaces: /dev/glass, /dev/glass/calibration, "Glass development" button on pending screens.
7. Tests, captures, device-check.
