# Flutter motion, glass and effects libraries for the redesign

Research date: 2026-09-29. Every version, date, like count and point score below comes from the pub.dev JSON API (`/api/packages/<name>` and `/api/packages/<name>/score`) on that day. "Likes" and "pts" are pub.dev likes and pub points (out of 160).

## 0. Real baseline first: this app is on Flutter 3.44.6, not 3.22

The brief says "Flutter 3.22+", but that is only the stale floor in `mobile/pubspec.yaml`. What actually builds the app:

- `.github/workflows/ios-build.yml:48` and `tests.yml:104` pin **Flutter 3.44.6 stable**. `pubspec.lock` already resolves `sdks: dart >=3.12.0, flutter >=3.44.0`.
- **Impeller** is the only renderer on iOS. On Android it is the default on API 29+ (Vulkan). Older or non-Vulkan devices fall back to the legacy OpenGL path ([docs.flutter.dev/perf/impeller](https://docs.flutter.dev/perf/impeller)). Because the redesign is flagship-only, every design can assume Impeller. Gate the one Impeller-only API anyway: `ui.ImageFilter.isShaderFilterSupported`.
- **iOS is CocoaPods-only**, set with `flutter: config: enable-swift-package-manager: false` in the pubspec. Every native plugin added below has to ship a podspec. All of the recommended ones do.
- **Flutter 3.44 froze Material and Cupertino inside the SDK.** They are moving to the standalone `material_ui` and `cupertino_ui` packages. The newest majors of some Flutter-team packages already depend on those packages: `go_router 18.x` and `animations 3.x`. The newest versions of `material_ui` (1.4+) and `cupertino_ui` (1.1.1) need Flutter 3.47. **Rule: stay on the pre-`material_ui` major of those packages** unless the redesign moves to `material_ui` in the same change.
- Several libraries have *already* moved to Flutter 3.47, including `haptic_feedback 0.7+`, `flutter_scene 0.21+`, and `cupertino_ui 1.1.1`. Where that happens, the table at the end pins the last version that supports 3.44.
- ProMotion is already unlocked (`CADisableMinimumFrameDurationOnPhone = true` in `ios/Runner/Info.plist`). Android high refresh is already requested through `flutter_displaymode`. Motion will run at 120 Hz on flagships, so tune the curves on a 120 Hz device.
- **Action:** raise `environment.flutter` in the pubspec to `>=3.44.0`. Half the picks below need at least 3.41.

Things the SDK already ships in 3.44.6 that make a package unnecessary (these are rungs to check before adding a dependency):

| Need | Built-in API (3.44) | Since |
|---|---|---|
| Spring from designer terms | `SpringDescription.withDurationAndBounce(duration:, bounce:)` | 3.32 |
| Squircle / continuous corners | `RoundedSuperellipseBorder`, `RSuperellipse`, `ClipRSuperellipse` | 3.32 |
| Many blurs, one pass | `BackdropGroup` + `BackdropFilter.grouped(...)` (shares one `BackdropKey`) | 3.29 |
| Shader as an image filter | `ui.ImageFilter.shader(FragmentShader)`, Impeller-only, check `ImageFilter.isShaderFilterSupported` | 3.29 |
| Set shader uniforms by name | `shader.getUniformFloat('uTime').set(t)` | 3.44 |
| iOS notification haptics | `HapticFeedback.successNotification() / warningNotification() / errorNotification()` (Android: `CONFIRM` / `KEYBOARD_TAP`(API 30+) / `REJECT`) | 3.41 (PR #177721, merged 2025-11-07) |
| Android predictive back | `PredictiveBackPageTransitionsBuilder` is the **default Android transition** (`FadeForwardsPageTransitionsBuilder`, 450 ms, when no gesture is in progress) | 3.38 |
| Custom predictive back | `PredictiveBackRoute` (`handleStartBackGesture`, `handleUpdateBackGestureProgress`, `handleCommitBackGesture`, `handleCancelBackGesture`) plus `WidgetsBindingObserver.handleStartBackGesture(PredictiveBackEvent)` | 3.22+ |
| iOS stacked sheet | `showCupertinoSheet` / `CupertinoSheetRoute` with the new `scrollableBuilder` (3.44 deprecates `builder` / `pageBuilder`) | 3.29 / 3.44 |
| Carousel | `CarouselView`, `CarouselView.weighted(flexWeights:)`, **infinite scrolling + `onIndexChanged` new in 3.44** | 3.24 / 3.44 |
| Reduced motion | `MediaQuery.disableAnimationsOf(context)`; 3.44 adds iOS auto-play flags to `AccessibilityFeatures` | — |

---

## 1. Staggered choreography and per-letter text reveals

| Package | Latest (published) | Likes / pts | Platforms | License | Notes |
|---|---|---|---|---|---|
| **flutter_animate** | 4.5.2 (2024-11-25) | 4248 / 150 | all 6 | BSD-3 | Flutter Favorite, gskinner. 1.03 M downloads/30 d. Effects: fade, slide, move, scale, blur (via `ImageFiltered`), shimmer, shader, tint, saturate, flip, custom, and others. `AnimateList(interval:)` for staggers. Only dependency is `flutter_shaders`. Loose SDK constraints, so it resolves on 3.44 without trouble. |
| pretty_animated_text | 3.2.0 (2026-08-04) | 137 / 150 | android, ios, macos, web | MIT | Ready-made `BlurText`, `OffsetText`, `SpringText`, `ScrambleText`, `GlitchText`, `RevealText` with `AnimationType.letter` / `.word`. Owns its own layout, and `GravityText` pulls in forge2d. |
| animated_text_kit | 4.3.0 (2025-10-04) | 5685 / 160 | all 6 | MIT | Flutter Favorite. Typewriter, fade, and scale presets. The effects are the familiar web-2019 kind. |

**Pick: `flutter_animate ^4.5.2`.** Use it for all choreography in both skins. The last release is old, but the API is stable, it is a Flutter Favorite, and nothing in it touches the frozen Material/Cupertino code. Skip the text-effect packages. Both required signature animations take about 20 lines on top of flutter_animate:

**Heading reveal** (each letter fades in, slides up and un-blurs, staggered). The unit of wrapping is a word, so line breaks still fall at spaces. `characters` is re-exported by `package:flutter/widgets.dart`, so emoji and combined graphemes stay intact.

```dart
class LetterReveal extends StatelessWidget {
  const LetterReveal(this.text, {super.key, required this.style,
      this.stagger = const Duration(milliseconds: 24)});
  final String text;
  final TextStyle style;
  final Duration stagger;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return Text(text, style: style);
    final words = text.split(' ');
    var i = 0;
    return Semantics(
      label: text,
      child: ExcludeSemantics(
        child: Wrap(children: [
          for (final (w, word) in words.indexed)
            Row(mainAxisSize: MainAxisSize.min, children: [
              for (final ch in (w < words.length - 1 ? '$word\u00A0' : word).characters)
                Text(ch, style: style)
                    .animate(delay: stagger * i++)
                    .fadeIn(duration: 380.ms, curve: Curves.easeOut)
                    .slideY(begin: 0.45, end: 0, duration: 560.ms,
                        curve: const Cubic(0.16, 1, 0.3, 1))
                    .blur(begin: const Offset(10, 10), end: Offset.zero,
                        duration: 560.ms, curve: const Cubic(0.16, 1, 0.3, 1)),
            ]),
        ]),
      ),
    );
  }
}
```

Known limits of this approach:
- Splitting per glyph drops **kerning pairs** ("AV", "To"). Tight `letterSpacing` still works because it is applied per glyph. The kerning-safe upgrade: lay the string out once with `TextPainter`, then for each grapheme `i`, clip to `getBoxesForSelection(TextSelection(baseOffset: i, extentOffset: i + 1))` and repaint the same paragraph with that glyph's opacity, offset and `saveLayer(Paint()..imageFilter = ImageFilter.blur(...))`. That is one `CustomPainter` of about 40 lines. Build it only if the display face kerns visibly.
- Every blurred glyph is its own `saveLayer`. That is fine for H3 headers and hero titles of 30 letters or fewer on a flagship. Do not use it on body text or list rows.
- For color changes on hover or state, wrap the result in `AnimatedDefaultTextStyle(duration: 220.ms, curve: Curves.easeOut)`. No package needed.

**Typing reveal at 50 ms per character.** The whole string is laid out from frame 0, with the untyped tail drawn transparent, so the line never reflows while it types:

```dart
final chars = text.characters;
Text(text, style: style).animate().custom(
  duration: 50.ms * chars.length,
  builder: (context, v, _) {
    final n = (v * chars.length).floor();
    return Text.rich(TextSpan(style: style, children: [
      TextSpan(text: chars.take(n).string),
      TextSpan(text: chars.skip(n).string,
          style: const TextStyle(color: Color(0x00000000))),
    ]));
  },
);
```

Add a caret as a 2 px wide `Container` next to the text, using `.animate(onPlay: (c) => c.repeat(reverse: true)).fade(duration: 530.ms)`.

**Stagger lists** (rails, grids, settings rows): `Column(children: rows.animate(interval: 40.ms).fadeIn(duration: 320.ms).slideY(begin: .08))`. Cap each stagger group at about 8 items. After that, reveal the rest together so the tail of the list never waits more than 320 ms.

Reduced motion: check `MediaQuery.disableAnimationsOf(context)` once in each skin's reveal widgets and render the final state. flutter_animate has no global switch.

---

## 2. Spring physics

| Package | Latest | Likes / pts | License | Notes |
|---|---|---|---|---|
| **motor** (whynotmake.it) | 1.1.0 (2025-12-02) | 249 / 150 | MIT | One `Motion` type covers springs and curves. `CupertinoMotion` presets mirror SwiftUI, and `MaterialSpringMotion` provides M3 tokens. `SingleMotionBuilder` and `MotionBuilder` take converters for Offset, Size and Rect, plus `MotionDraggable`. 111 k downloads/30 d, because heroine and stupid_simple_sheet depend on it. The repo is starting "motor 2.0" (commit f1818c1, 2026-09-25), so expect a major bump. |
| flutter_physics | 0.2.3 (2026-09-12) | 63 / 160 | MIT | `PhysicsController` is a drop-in replacement for `AnimationController`. Implicit `AContainer` / `ASize` / `ASwitcher` preserve velocity when retargeted mid-flight. Presets include `Spring.elegant`, `.swift`, `.buoyant` and `.gentle`. |
| sprung | 3.0.1 (2022-07-27) | 288 / 160 | MIT | Curve-only, not maintained. Skip. |
| springster | 1.0.2 (2025-12-02) | 81 | MIT | Motor's predecessor. Skip. |
| SDK | `SpringSimulation`, `SpringDescription.withDurationAndBounce` | — | BSD-3 | Enough for a single controller-driven spring. |

**Pick: `motor ^1.1.0`.** heroine and stupid_simple_sheet already bring it in, so it costs nothing extra. It is also the only package whose presets use the vocabulary the Glass skin is specified in. Preset values, from `motor/lib/src/motion.dart` at f1818c1:

| Preset | duration | bounce | Glass use |
|---|---|---|---|
| `CupertinoMotion()` | 550 ms | 0 | default layout / position |
| `CupertinoMotion.smooth()` | 500 ms | 0 | sheets, glass morphs, page settle |
| `CupertinoMotion.snappy()` | 500 ms | 0.15 | tabs, toggles, segmented controls |
| `CupertinoMotion.bouncy()` | 500 ms | 0.30 | confirmations, "added to library" pop |
| `CupertinoMotion.interactive()` | 150 ms | 0.14 | anything tracking a finger |

Motor's M3 tokens (`MaterialSpringMotion`): spatial fast/default/slow have damping 0.9 and stiffness 1400/700/300. Expressive spatial has damping 0.6/0.8/0.8 and stiffness 800/380/200. Effects has damping 1 and stiffness 3800/1600/800.

Cinematic should stay mostly duration-based. Suggested starting tokens: entrances use `Cubic(0.16, 1, 0.3, 1)` (expo-out), crossfades use `Cubic(0.65, 0, 0.35, 1)`, exits use `Cubic(0.7, 0, 0.84, 0)`, with durations of 120 / 220 / 360 / 520 / 700 ms for micro through hero. Motor's `Motion.curved(duration, curve)` keeps both skins on one API.

---

## 3. Liquid glass, blur and glass surfaces

| Package | Latest | Likes / pts | Platforms | License | Notes |
|---|---|---|---|---|---|
| **liquid_glass_widgets** (sdegenaar) | 1.7.2 (2026-09-22) | 324 / **160** | all 6 | MIT | A maintained **fork of liquid_glass_renderer's engine**. Baseline v0.2.0-dev.4, forked 2026-03-28 (see `lib/src/engine/ATTRIBUTION.md`), with fixes including a Vulkan compositing-bits race and frost passes. **Exports the raw engine**: `LiquidGlass`, `LiquidGlassLayer`, `LiquidGlassBlendGroup`, `GlassGlow`, all shapes, and `GlassMaterializeScope` (fades glass without an `Opacity` layer, which avoids Impeller backdrop pop during route transitions). Also exports 60+ iOS-26 widgets (`GlassScaffold`, `GlassTabBar`, `GlassSheet`, and others), `GlassQuality`, adaptive quality, and a Reduce Motion / Increase Contrast scope. Needs Flutter ≥3.41. Shaders include `liquid_glass_render.frag`, `liquid_glass_geometry_blended.frag`, `progressive_blur.frag` and `lightweight_glass.frag`. Released almost daily in September 2026. |
| liquid_glass_renderer (whynotmake.it) | 0.2.0-dev.4 (2025-11-13) | **887** / 150 | android, ios, macos | MIT | The original engine. README says "EXPERIMENTAL" and "Impeller only". `LiquidRoundedSuperellipse`, blend groups (max **16 shapes**), `LiquidStretch`, `GlassGlow`, `FakeGlass`. No pub release in 10 months (repo HEAD ad3bcff, 2026-04-28, has unreleased breaking shadow work). |
| liquid_glass_easy | 4.3.4 (2026-09-28) | 269 / 160 | all 6 | MIT | Lens-style refraction (distortion, magnification, chromatic aberration). `LiquidGlassBlender` batches many lenses into one backdrop read. Uses a RepaintBoundary capture on Skia. |
| oc_liquid_glass | 0.3.0 (2026-06-25) | 80 / 160 | android, ios, macos | MIT | Smaller alternative, Impeller-only. |
| cupertino_native (serverpod) | 0.1.1 (2025-09-08) | 345 | **ios, macos only** | BSD-3 | Real UIKit iOS 26 glass through platform views. No Android support, so ruled out. |
| glassmorphism / glass_kit | 4.0.0 / 4.0.2 | 535 / 535 | all | Apache-2 / MIT | Thin `BackdropFilter` + gradient wrappers. Writing your own is 20 lines, so skip. |

**Pick: `liquid_glass_widgets ^1.7.2`**, used mainly for its **engine primitives** (`LiquidGlassLayer` / `LiquidGlass` / `LiquidGlassBlendGroup` / `GlassMaterializeScope`). The Glass skin's own components are built on top of those, because every element is being redesigned. Its prebuilt `GlassScaffold` / `GlassTabBar` can serve as a reference or a prototype shortcut. Choose it over upstream liquid_glass_renderer because the fork is where the engine is still maintained, and the Vulkan fix matters on Android.

Cinematic needs no glass library. Its frosted chrome (top bar over the hero, reader controls) is plain `BackdropFilter` inside `BackdropGroup`:

```dart
BackdropGroup(child: Stack(children: [
  content,
  ClipRSuperellipse(
    borderRadius: BorderRadius.circular(22),
    child: BackdropFilter.grouped(
      filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24, tileMode: TileMode.clamp),
      child: const ColoredBox(color: Color(0x99000000)), // AMOLED scrim, 60 %
    ),
  ),
]))
```

Performance rules for both skins. Sources: liquid_glass_renderer README, the linked Flutter issues, and vendor measurements.
- **Glass that does not move is nearly free. Glass that moves re-renders every frame.** In a blend group, moving one shape re-renders all of them. Animate `LiquidGlassSettings.visibility` or `GlassMaterializeScope` rather than the geometry wherever possible.
- **Keep each `LiquidGlassLayer` / `LiquidGlassBlendGroup` as small as possible.** Each one allocates a texture over its whole area. Split large, sparsely populated regions into separate layers.
- **Stack at most two glass surfaces** in any one spot. Third-party measurements put a full-screen glass sheet at about 1.2 ms GPU on an iPhone 15 Pro at 60 Hz and about 2.4 ms at 120 Hz, and each stacked layer adds the same again ([theflutterk.it guide](https://theflutterk.it.com/blog/flutter-liquid-glass-ios-26-cupertino-guide), a vendor figure; re-measure).
- Known engine bugs: temporary **memory spike when animating glass** ([flutter#138627](https://github.com/flutter/flutter/issues/138627)); **`ImageFilter.blur` combined with `ImageFilter.shader` in one `BackdropFilter` breaks** ([flutter#170820](https://github.com/flutter/flutter/issues/170820)); Impeller backdrop blur costs more raster time than Skia did ([flutter#161297](https://github.com/flutter/flutter/issues/161297)), which is why `BackdropGroup` is mandatory for lists of frosted cells.
- Never put glass inside a fast-scrolling list cell. Put it on chrome that floats over the list.

---

## 4. Sheets

| Package | Latest | Likes / pts | License | Notes |
|---|---|---|---|---|
| **smooth_sheets** (fujidaiti) | 1.2.0 (2026-09-07) | 655 / 150 | MIT | Stable 1.x (1.0 was 2026-04-08). Modal **and persistent** sheets, `PagedSheet` (multi-page with transitions, works with go_router), `SheetSnapGrid` detents, `SheetPhysics`, `SheetOffsetDrivenAnimation`, `SheetContentScaffold` (keyboard and bottom bar), `CupertinoModalSheetRoute` + `CupertinoStackedTransition`, and `ModalSheetRouteMixin.sheetVisibility` (1.1.0). Needs Flutter ≥3.41. |
| **stupid_simple_sheet** (whynotmake.it) | 0.9.1+1 (2026-03-12); 1.0.0-dev.4 (2026-09-15) | 106 / 150 | MIT | `StupidSimpleGlassSheetRoute` (iOS 26 glass, added in 0.9.0; the route behind blurs from 0.9.1) and `StupidSimpleCupertinoSheetRoute`. Motor spring physics. **Scroll-to-drag handoff in the middle of a gesture.** 1.0.0-dev adds `DismissalMode.shrink` (persistent footer) and `dragHandoff`. Sheet content must not set a custom `ScrollConfiguration`. |
| Flutter `CupertinoSheetRoute` | SDK | — | BSD-3 | iOS stacked sheet with push-back. 3.44 adds `scrollableBuilder`. Full height only (no detents), linear-feeling drag. |
| wolt_modal_sheet | 0.11.0 (2025-02-02) | 1481 / 150 | MIT | Multi-page, turns into a dialog on large screens. 19 months without a release. Skip. |
| modal_bottom_sheet | 3.0.0 (2024-03-12) | 3593 / 150 | MIT | Stale. Skip. |
| sheet | 1.0.1 (2026-07-21) | 117 / 140 | MIT | Same author as modal_bottom_sheet. Fine, but superseded by the two above. |

**Picks:**
- **Glass:** `stupid_simple_sheet ^0.9.1+1`. The glass route plus motor springs is exactly the visionOS/iOS 26 feel the brief asks for. If `DismissalMode.shrink` turns out to be needed, pin exactly `1.0.0-dev.4`, because the dev line has breaking changes between releases.
- **Cinematic:** `smooth_sheets ^1.2.0`. Use it for the reader's persistent panels (chapter list, reader settings, TTS voice picker) with snap detents at 0.4 and 1.0, and `PagedSheet` for flows like filters → source → sort. Glass can also use it for persistent sheets.

---

## 5. Page transitions and swipe-back everywhere

Current state in the app: `app_router.dart` builds the reader with `CustomTransitionPage` (fade: 280 ms in, 220 ms out). That bypasses `PageTransitionsTheme`, so there is no system back swipe inside a chapter. `reader_edge_back_gesture.dart` hand-rolls a 20 px edge strip with a fling threshold of 1.0 screen widths per second, which is Cupertino's own constant. Only the vertical (webtoon) mode enables it, because horizontal paging competes for the same drag.

| Option | Latest | Likes / pts | License | Notes |
|---|---|---|---|---|
| `CupertinoPageRoute` / `CupertinoPageTransitionsBuilder` (SDK) | — | — | BSD-3 | Back swipe starts only in a **20 px edge** (`_kBackGestureWidth`). Full-width back swipe like iOS 26 is **still open** ([flutter#180309](https://github.com/flutter/flutter/issues/180309), opened 2025-12-26, no PR). |
| **swipeable_page_route** (JonasWanke) | 0.4.8 (2026-01-02) | 318 / 160 | MIT | **Full-screen** swipe back. `canOnlySwipeFromEdge: true` per route handles the horizontally paged reader. `SwipeablePage` drops into go_router's `pageBuilder`. `SwipeablePageTransitionsBuilder` for the theme. `MorphingAppBar` / `MorphingSliverAppBar` (uses `Hero`). Needs Flutter ≥3.35. No web support, which does not matter for the mobile client. |
| full_swipe_back_gesture | 0.1.2 (2025-09-11) | 14 | MIT | Too small to rely on. |
| cupertino_back_gesture | 0.1.0 (2021) | 69 | BSD-3 | Dead. |
| `animations` (flutter.dev) | 3.0.0 (2026-08-19) → **pin 2.2.0** (2026-04-23) | 6881 / 160 | BSD-3 | `SharedAxisTransition`, `FadeThroughTransition`, `OpenContainer` (container transform). 3.0.0 depends on `material_ui`. |
| go_router | 18.0.2 (2026-09-28) → **keep ^14** (lock 14.8.1), or at most 17.5.0 | 5785 | BSD-3 | 18.0.0 "migrates to material_ui and cupertino_ui". Pages built with `CustomTransitionPage` ignore the theme. Pages built with `MaterialPage` or `builder:` use the skin's `PageTransitionsTheme`. |

**Recommended architecture (per skin, all first-party apart from one package):**

1. Each skin supplies its own `PageTransitionsTheme` in its `ThemeData`. Routes use go_router's plain `builder:` (which produces `MaterialPage`), so the transition comes from the theme. That way, swapping the skin swaps every transition in the app without any router changes.
2. **iOS:** both skins use `swipeable_page_route ^0.4.8`. Register `SwipeablePageTransitionsBuilder` for `TargetPlatform.iOS`, and use `SwipeablePage(canOnlySwipeFromEdge: true)` for the reader in LTR and RTL modes. That also retires `ReaderEdgeBackGesture` for those modes. Glass keeps swipeable's parallax push; Cinematic overrides the visuals in its own builder.
3. **Android:** the system back gesture owns both screen edges, so there is no in-app edge swipe. Use **predictive back** instead:
   - Add `android:enableOnBackInvokedCallback="true"` to `<application>`. It is **missing** from `AndroidManifest.xml` today. Android 16 with targetSdk 36 turns predictive back on by default, but Android 13–15 need the flag. Watch [flutter#185257](https://github.com/flutter/flutter/issues/185257) (the flag breaks predictive back on some OnePlus Android 14 builds).
   - Glass: keep the stock `PredictiveBackPageTransitionsBuilder` (M3 shrink-and-peek, which matches "depth").
   - Cinematic: write a custom `PageTransitionsBuilder`. Copy the pattern of the SDK's private `_PredictiveBackGestureDetector`, which is a `WidgetsBindingObserver` forwarding `PredictiveBackEvent.progress` to `route.handleStartBackGesture(progress: 1 - e.progress)`, `handleUpdateBackGestureProgress`, `handleCommitBackGesture` and `handleCancelBackGesture`. Then drive the Cinematic visuals from `animation`: outgoing page scales 1.0→0.92, dims to 40 %, and leans toward `e.swipeEdge`. `PopScope(onPopInvokedWithResult:)` keeps working.
4. Suggested push tokens. Cinematic: 480 ms, the incoming page fades in over the first 60 % while scaling 1.04→1.0 on `Cubic(0.16,1,0.3,1)`, and the outgoing page scales 1→0.96 and fades to 0.35. Glass: spring `CupertinoMotion.smooth()` (500 ms, bounce 0), with the incoming page sliding 100 %→0 and the outgoing page moving −30 % under a 20 % black scrim. This is the iOS geometry but spring-driven.

---

## 6. Shared element / hero transitions

| Package | Latest | Likes / pts | License | Notes |
|---|---|---|---|---|
| **heroine** (whynotmake.it) | 0.7.2 (2026-03-31) | 337 / 150 | MIT | Spring-driven hero (`motion:` accepts any motor `Motion`). **`DragDismissable`** (drag-to-dismiss with velocity), shuttle builders (`FadeShuttleBuilder`, `FlipShuttleBuilder`, `FadeThroughShuttleBuilder`, `.chain()`), `shouldTransition` route filtering (0.7.2), `DuplicateHeroinePolicy` (0.7.1). Setup: `HeroineController()` in `GoRouter(observers: [...])`, and in each `ShellRoute`/`StatefulShellBranch` navigator as well. |
| Flutter `Hero` | SDK | — | BSD-3 | Tween-driven, no gesture, `RectTween` only. |
| animations `OpenContainer` | 2.2.0 | — | BSD-3 | Container transform (card → page). Good Cinematic fallback. |

**Pick: `heroine ^0.7.2`.** Cover → series detail in both skins. In Glass, add `DragDismissable` on the detail page (pull down, the page shrinks back into its card, App Store style) with `CupertinoMotion.smooth()`. In Cinematic, use `FadeThroughShuttleBuilder(fadeColor: Color(0xFF000000))` with a 560 ms curve so the cover "dips to black" as it grows into the hero backdrop.

---

## 7. Haptics vocabulary

| Package | Latest | Likes / pts | Platforms | License | Notes |
|---|---|---|---|---|---|
| SDK `HapticFeedback` | 3.41+ | — | android, ios | BSD-3 | `lightImpact`, `mediumImpact`, `heavyImpact`, `selectionClick`, `vibrate`, and now `successNotification` / `warningNotification` / `errorNotification`. The app uses 3 calls today. Android goes through `View.performHapticFeedback` constants. No `rigid` / `soft`. |
| **haptic_feedback** (nohli) | 0.8.0 (2026-09-26) **needs Flutter 3.47 + AGP 9** → **pin 0.6.5** (2026-07-10) | 136 / 160 | android, ios | BSD-3 | All 9 iOS types (success, warning, error, light, medium, heavy, rigid, soft, selection). On Android API 30+, uses **`VibrationEffect.Composition` primitives tuned to match iOS** (success = CLICK×2 rising, error = CLICK×4, heavy = THUD, soft = SPIN). `usage: HapticsUsage.*` hint. 0.8.0 adds `Haptics.prepare()`. |
| **gaimon** (istornz) | 1.5.0 (2026-08-30) | 138 / 160 | android, ios | MIT | Standard set plus **`Gaimon.pattern(ahapJson)`**: Core Haptics AHAP on iOS 13+ (iPhone 8+). On Android the AHAP is converted to an amplitude waveform (one source file per pattern for both OSes). Its Android basic types are plain one-shots (for example selection = 5 ms `DEFAULT_AMPLITUDE`), which are cruder than haptic_feedback. Declares `VIBRATE` in the plugin manifest. |
| vibration | 3.2.1 (2026-09-02) | 940 / 160 | android, ios | BSD-2 | Raw pattern / intensities / iOS `sharpness`, 20 `VibrationPreset`s. Buzz-oriented. Not needed if gaimon is present. |
| flutter_vibrate | 1.4.0 (2026-01-14) | 202 / 140 | android, ios | Apache-2 | Superseded. |

**Picks: `haptic_feedback ^0.6.5`** (every standard tap, with the best Android fidelity) **plus `gaimon ^1.5.0`** for the few signature AHAP patterns. Bump to `haptic_feedback ^0.8.0` when CI moves to 3.47, and call `Haptics.prepare(type)` on pointer-down.

API mapping for the vocabulary table the concepts owe (starting values; the owner asked for a full per-skin table in the concept docs):

| Event | Cinematic | Glass | Call |
|---|---|---|---|
| Tab / segmented change | selection | selection | `Haptics.vibrate(HapticsType.selection)` |
| Primary button press | medium | soft | `HapticsType.medium` / `.soft` |
| Toggle flip | rigid | light | `.rigid` / `.light` |
| Sheet detent snap / scrubber tick (every 10 ch) | light | selection | `.light` / `.selection` |
| Pull-to-refresh armed | rigid | medium | `.rigid` / `.medium` |
| Long-press context menu opens | heavy | medium | `.heavy` / `.medium` |
| Swipe-back / predictive-back commit | light | soft | `.light` / `.soft` |
| Added to library / download finished | success | success | `.success` |
| 18+ gate blocked, source degraded | warning | warning | `.warning` |
| Source failed, network error | error | error | `.error` |
| Chapter finished → next-chapter card commits | AHAP "rise" | AHAP "rise" (softer) | `Gaimon.pattern(await rootBundle.loadString('assets/haptics/<skin>/rise.ahap'))` |
| Streak increments | AHAP "flame" | AHAP "flame" | same |
| Card swipe accept / reject (rec deck) | rigid / soft | light / soft | `.rigid` etc. |

Example AHAP for "rise": three transients at 0, 90 and 180 ms, intensity 0.45 → 0.7 → 1.0, sharpness 0.35 → 0.5 → 0.8:

```json
{"Version":1,"Pattern":[
 {"Event":{"Time":0.0,"EventType":"HapticTransient","EventParameters":[{"ParameterID":"HapticIntensity","ParameterValue":0.45},{"ParameterID":"HapticSharpness","ParameterValue":0.35}]}},
 {"Event":{"Time":0.09,"EventType":"HapticTransient","EventParameters":[{"ParameterID":"HapticIntensity","ParameterValue":0.7},{"ParameterID":"HapticSharpness","ParameterValue":0.5}]}},
 {"Event":{"Time":0.18,"EventType":"HapticTransient","EventParameters":[{"ParameterID":"HapticIntensity","ParameterValue":1.0},{"ParameterID":"HapticSharpness","ParameterValue":0.8}]}}]}
```

Route every haptic through one `SkinHaptics` class so the Settings haptics toggle and the skin's table live in one place.

---

## 8. Shaders: grain, vignette, progressive blur

| Package | Latest | Likes / pts | License | Notes |
|---|---|---|---|---|
| flutter_shaders (jonahwilliams) | 0.1.3 (2024-09-26) | 131 / 150 | BSD-3 | `ShaderBuilder` (loads a `FragmentProgram` once), `AnimatedSampler` (captures a child as a `ui.Image` each frame for sampling), `SetUniforms`. 1.13 M downloads/30 d because flutter_animate depends on it, so it is **already coming in transitively**. Old but tiny and stable. |
| shader_buffers | 1.1.4 (2026-02-26) | 60 / 160 | Apache-2 | ShaderToy-style multipass. Not needed. |

Recommendations, cheapest option first:
- **Vignette:** no shader. Use a `DecoratedBox` with `RadialGradient(colors: [Color(0x00000000), Color(0xCC000000)], stops: [0.55, 1.0], radius: 1.1)` over hero art.
- **Film grain (Cinematic):** try a tiled 256×256 noise PNG first (`DecorationImage(repeat: ImageRepeat.repeat, opacity: 0.05)`), with its alignment offset jumped at 24 fps to fake animation. It needs no shader. Move to a shader only if the tile repeat is visible. Keep grain **off pure-black chrome**: grain lights pixels that would otherwise be off on AMOLED, which defeats the true-black base. Restrict it to imagery (hero backdrops, the detail header).
- **Grain shader** (if needed): a generator, not an image filter, so it runs on any backend. Declare it under `flutter: shaders:`, draw it with a `CustomPainter` `Paint()..shader = program.fragmentShader()`, and set uniforms by name (3.44):

```glsl
#version 460 core
#include <flutter/runtime_effect.glsl>
uniform vec2 uSize;
uniform float uTime;    // advance in 1/24 s steps
uniform float uAmount;  // 0.04–0.07
out vec4 fragColor;
float hash(vec2 p){ p = fract(p * vec2(443.897, 441.423)); p += dot(p, p.yx + 19.19); return fract((p.x + p.y) * p.x); }
void main() {
  float n = hash(floor(FlutterFragCoord().xy) + floor(uTime * 24.0) * 17.0);
  fragColor = vec4(vec3(1.0), 1.0) * (n * uAmount);  // premultiplied white, additive-looking
}
```

- **Progressive (variable) blur** for Glass bar edges or the top of the detail header: reuse `liquid_glass_widgets`' `progressive_blur.frag` (already in the recommended dependency), or `ImageFilter.shader` behind `ImageFilter.isShaderFilterSupported`. Do not combine it with `ImageFilter.blur` in the same `BackdropFilter` ([flutter#170820](https://github.com/flutter/flutter/issues/170820)).
- Precompile or warm shaders at startup (`FragmentProgram.fromAsset` in `main()`). liquid_glass_widgets does this through `LiquidGlassWidgets.initialize()`.

---

## 9. Palette extraction from covers (dynamic tint for the reader chrome)

| Package | Latest | Notes |
|---|---|---|
| palette_generator | 0.3.3+7 (2025-05-06) | **Discontinued** by flutter.dev, with no named replacement. |
| **material_color_utilities** | 0.13.1 (2026-08-10), **SDK-pinned 0.13.0** (already in `pubspec.lock`) | `QuantizerCelebi().quantize(pixels, maxColors)` → `Future<QuantizerResult>` (`colorToCount`). `Score.score(colorToCount, desired: 1, filter: true)` → `List<int>` ARGB. `SchemeContent` / `SchemeFidelity` for dark tonal palettes. Pure Dart, so it runs in an isolate. Apache-2.0. |
| SDK `ColorScheme.fromImageProvider(provider:, brightness: Brightness.dark, dynamicSchemeVariant: DynamicSchemeVariant.content)` | — | Same algorithm, but it runs on the **UI isolate**. Fine for one cover on the detail page, not for every page turn. |

**Pick: promote `material_color_utilities` to a direct dependency with `^0.13.0`.** The Flutter SDK pins it exactly, so a caret constraint resolves to the SDK's version. For "reader chrome tinted by the current page": decode a 64 px thumbnail with `ResizeImage(provider, width: 64, policy: ResizeImagePolicy.fit)`, `toByteData(format: ui.ImageByteFormat.rawRgba)`, convert RGBA to ARGB ints (`a<<24 | r<<16 | g<<8 | b`), then `compute()` the quantize and score step with `maxColors: 32`. Cache the result per page URL. Tween the chrome color over 400 ms so page turns never flash. A cheaper alternative is to compute the seed on the backend once per cover or page and ship it with the metadata.

---

## 10. Skeleton loaders

| Package | Latest | Likes / pts | License | Notes |
|---|---|---|---|---|
| **skeletonizer** | 3.0.0 (2026-09-11) | 2356 / 160 | MIT | Turns the real layout into bones (annotations: `Skeleton.ignore/keep/leaf/shade/replace/unite`, manual `Bone.text/circle/icon`). Effects: `ShimmerEffect`, `PulseEffect`, `SolidColorEffect`. `enableSwitchAnimation` (not for slivers). **3.0 breaking:** config moves from `ThemeExtension` to `SkeletonizerConfig(data:, child:)`, and `Bone.button` no longer reads Material. Both suit a custom design system. |
| shimmer | 4.0.0 (2026-08-21) | 5450 / 160 | BSD-3 | Gradient mask only. Needs 3.44 / Dart 3.12. |

**Pick: `skeletonizer ^3.0.0`.** Set `SkeletonizerConfig(data: SkeletonizerConfigData(brightness: Brightness.dark, effectResolver: (_) => ...))` per skin; `brightness` must be explicit, because the default follows platform brightness. Suggested starting values: Cinematic `ShimmerEffect(baseColor: Color(0xFF0E0E10), highlightColor: Color(0xFF1C1C21), duration: Duration(milliseconds: 1400))`; Glass `PulseEffect(from: Color(0x14FFFFFF), to: Color(0x24FFFFFF), duration: Duration(milliseconds: 1100))` so bones read as frosted glass rather than grey slabs.

---

## 11. Carousels and card swipers

| Package | Latest | Likes / pts | License | Notes |
|---|---|---|---|---|
| SDK `PageView` / `CarouselView` | 3.44 | — | BSD-3 | `CarouselView` is Material (frozen) and adds infinite scrolling and `onIndexChanged` in 3.44. `PageView(controller: PageController(viewportFraction: 1))` with a `Timer` handles the hero spotlight. |
| carousel_slider | 5.1.2 (2026-02-05) | 6060 / 160 | MIT | autoPlay, enlargeCenterPage. Everything it does is covered by `PageView` plus about 20 lines. |
| **flutter_card_swiper** | 7.2.0 (2025-11-02) | 709 / 160 | MIT | Tinder-style deck: `maxAngle` 30°, `threshold` 50 px, `scale` 0.9, `numberOfCardsDisplayed`, `allowedSwipeDirection`, `controller.swipe/undo/moveTo`, `onSwipe` returns bool. |
| appinio_swiper / card_swiper / infinite_carousel | 2024 / 2023 / 2024 | — | MIT | Stale. |

**Picks:** no carousel package. The Cinematic hero spotlight is a `PageView` with per-page parallax: read `controller.page` in an `AnimatedBuilder`, translate the backdrop by `(page - index) * 0.35 * width`, and auto-advance every 7 s, pausing while touched. Rails are horizontal `ListView`s with snap physics (section 13). Add **`flutter_card_swiper ^7.2.0`** only if the AI-recommendations concept includes a swipe deck. The haptics for it come from section 7.

---

## 12. Rive and Lottie

| Package | Latest | Likes / pts | License | Notes |
|---|---|---|---|---|
| **lottie** | 3.6.1 (2026-09-18) | 4576 / 160 | MIT | Pure Dart, draws through the Flutter canvas, so it works on Impeller with **no native code**. 3.6.1 needs Flutter ≥3.41. |
| rive | 0.14.11 (2026-08-03); 0.15.0-dev.3 (2026-09-28) | 1947 / 140 | MIT | Depends on `rive_native 0.1.11` (C++ through FFI). iOS is statically linked through CocoaPods. Android builds with CMake and wants **NDK 27.2.12479018**. The README says the native libraries are **"automatically downloaded during the build step"**. Choice of `Factory.rive` (Rive renderer) or `Factory.flutter`. State machines and data binding are its real advantage. |

**Pick: `lottie ^3.6.1`** for loaders, empty states, the success tick and the streak flame. **Defer Rive.** The iOS build runs on a throwaway cloud Mac and the pubspec deliberately keeps that build offline and pinned (the SwiftPM-off comment explains why). A build-time binary download and a new NDK requirement go against that. Adopt Rive only if a concept needs an **interactive** state-machine asset, and do a CI dry run first.

---

## 13. Scroll physics and snapping

All built-in; no package recommended (`scroll_snap_list` 0.9.1 was last published 2022-05-29):
- One `ScrollConfiguration` per skin at the root. **Cinematic:** `BouncingScrollPhysics(decelerationRate: ScrollDecelerationRate.fast)` everywhere, including on Android, which reads as "premium streaming app". **Glass:** `BouncingScrollPhysics()` normal rate.
- Rails snapping to cards: subclass `ScrollPhysics` and override `createBallisticSimulation` so it rounds `position.pixels + velocity * 0.3` to a multiple of `itemExtent + gap`, returning `ScrollSpringSimulation(spring, pixels, target, velocity)` with `SpringDescription.withDurationAndBounce(duration: 350.ms, bounce: 0)`. About 20 lines; add one widget test for it.
- Hero spotlight: `PageScrollPhysics()`. Pickers: `FixedExtentScrollPhysics` with `ListWheelScrollView`.
- Reader: keep the current reader physics. That scroll path was tuned separately and is out of scope for the skins.

---

## 14. Other things checked

| Package | Verdict |
|---|---|
| sensors_plus 7.1.0 (2026-06-26, BSD-3, Flutter Favorite) | Optional. Gyroscope parallax for Glass depth (tilt the cover and spotlight about 6 px). Throttle to 60 Hz and honor reduced motion. |
| motion 2.0.2 | **Avoid: GPL-3.0.** |
| figma_squircle 0.6.3, smooth_corner 1.1.1 | Skip; the SDK has `RoundedSuperellipseBorder` (3.32+). |
| flutter_blurhash 0.9.1 | Skip unless the backend starts emitting blurhashes; a palette-seed color fill does the same job for free. |
| flutter_scene 0.23.0 / flutter_gpu | Skip: needs Flutter 3.47 and is experimental. |
| super_context_menu 0.9.1, pull_down_button (discontinued → `cupertino_ui`) | Skip; build menus per skin on `RawMenuAnchor` (3.44 `CupertinoMenuAnchor` builds on it). |
| flutter_staggered_animations 1.1.1 (2022), auto_animated 3.2.0 (2023) | Stale; flutter_animate covers them. |

---

## 15. Reference repos

The four shallow clones in `/srv/manhwamaniacs/dev/design-ref/flutter/` (from `git clone --depth 1`, clean, verified 2026-09-29), plus a link to the liquid_glass_widgets clone that already existed:

| Path | Repo | HEAD | License | Why |
|---|---|---|---|---|
| `flutter/rivership` | https://github.com/whynotmake-it/rivership | f1818c1 (2026-09-25) | MIT | `packages/motor`, `packages/heroine`, `packages/stupid_simple_sheet`, `packages/scroll_drag_detector`: springs, hero and glass sheet in one monorepo, with examples. |
| `flutter/flutter_animate` | https://github.com/gskinner/flutter_animate | 62c1204 (2024-11-25, = 4.5.2) | BSD-3 | Effect sources (`lib/src/effects/*`), and `AnimateList` for staggers. |
| `flutter/smooth_sheets` | https://github.com/fujidaiti/smooth_sheets | 84688c1 (2026-09-24) | MIT | `example/lib/showcase` (Safari stacked sheets, Airbnb map sheet, paged sheet). |
| `flutter/flutter_liquid_glass` | https://github.com/whynotmake-it/flutter_liquid_glass | ad3bcff (2026-04-28) | MIT | Upstream `liquid_glass_renderer` engine and shaders. Read it to understand what the fork changed. |
| `flutter/liquid_glass_widgets` → `../liquid_glass_widgets` (symlink) | https://github.com/sdegenaar/liquid_glass_widgets | ab865a8 (2026-09-25) | MIT | The recommended glass dependency: `lib/src/engine/ATTRIBUTION.md`, `docs/ARCHITECTURE.md`, `shaders/`. |

---

## Recommended pubspec additions

Every entry resolves on the pinned **Flutter 3.44.6 / Dart 3.12**. Pub respects Flutter SDK constraints, so caret ranges will not pull in 3.47-only releases, but the explicit pins protect against surprises.

| Package | Constraint | Latest on pub (date) | Why this version | Skin | Native code | License |
|---|---|---|---|---|---|---|
| `flutter_animate` | `^4.5.2` | 4.5.2 (2024-11-25) | only line | both | none | BSD-3 |
| `motor` | `^1.1.0` | 1.1.0 (2025-12-02) | stable; 2.0 in progress | both (Glass-led) | none | MIT |
| `heroine` | `^0.7.2` | 0.7.2 (2026-03-31) | `shouldTransition`, duplicate policy | both | none | MIT |
| `liquid_glass_widgets` | `^1.7.2` | 1.7.2 (2026-09-22) | maintained engine fork, needs ≥3.41 | Glass | shaders only | MIT |
| `stupid_simple_sheet` | `^0.9.1+1` (or exact `1.0.0-dev.4` for `DismissalMode.shrink`) | 1.0.0-dev.4 (2026-09-15) | stable glass sheet route | Glass | none | MIT |
| `smooth_sheets` | `^1.2.0` | 1.2.0 (2026-09-07) | stable 1.x, persistent + paged | Cinematic (+ Glass persistent) | none | MIT |
| `swipeable_page_route` | `^0.4.8` | 0.4.8 (2026-01-02) | full-screen iOS swipe-back, go_router `SwipeablePage` | both (iOS) | none | MIT |
| `haptic_feedback` | `^0.6.5` | 0.8.0 (2026-09-26) | **0.7+ needs Flutter 3.47 + AGP 9** | both | iOS pod + Android plugin | BSD-3 |
| `gaimon` | `^1.5.0` | 1.5.0 (2026-08-30) | AHAP signature patterns | both | iOS pod + Android plugin (adds `VIBRATE`) | MIT |
| `skeletonizer` | `^3.0.0` | 3.0.0 (2026-09-11) | design-system-agnostic 3.0 API | both | none | MIT |
| `lottie` | `^3.6.1` | 3.6.1 (2026-09-18) | pure Dart, needs ≥3.41 | both | none | MIT |
| `material_color_utilities` | `^0.13.0` | 0.13.1 (2026-08-10) | promote transitive; SDK pins 0.13.0 | both | none | Apache-2.0 |
| `flutter_shaders` | `^0.1.3` | 0.1.3 (2024-09-26) | promote transitive (via flutter_animate), only if `AnimatedSampler` / `ShaderBuilder` is used directly | both | none | BSD-3 |
| `flutter_card_swiper` | `^7.2.0` | 7.2.0 (2025-11-02) | **optional**: only if the AI-recs concept has a swipe deck | both | none | MIT |
| `sensors_plus` | `^7.1.0` | 7.1.0 (2026-06-26) | **optional**: Glass gyro parallax | Glass | iOS pod + Android plugin | BSD-3 |

Pins and deliberate non-additions:

| Package | Decision |
|---|---|
| `go_router` | keep `^14.0.0` (lock 14.8.1). If bumping, stop at `17.5.0`; 18.x pulls in `material_ui` / `cupertino_ui`. |
| `animations` | not added. If `OpenContainer` is wanted: `^2.2.0`. 3.0.0 pulls in `material_ui`. |
| `rive` | deferred: build-time native download plus NDK 27 conflict with the offline iOS build. |
| `palette_generator` | discontinued. Use `material_color_utilities`. |
| `liquid_glass_renderer` | superseded by the liquid_glass_widgets fork for this app. |
| `carousel_slider`, `scroll_snap_list`, `figma_squircle`, `glassmorphism`, `vibration`, `motion` (GPL-3.0) | not needed or not acceptable; see sections 11, 13, 14. |

Also needed, outside pubspec:
- `mobile/pubspec.yaml`: `environment.flutter: '>=3.44.0'`.
- `android/app/src/main/AndroidManifest.xml`: `android:enableOnBackInvokedCallback="true"` on `<application>`.
