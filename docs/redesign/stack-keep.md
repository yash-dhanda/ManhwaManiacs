# Keep the stacks: Next.js 16 + Tailwind 4 + Motion on the web, Flutter on the phones

Position paper for the ManhwaManiacs two-skin redesign (Cinematic / Glass). Written 2026-09-29.

Inputs: `inventory/00-decisions.md`, `inventory/{web,mobile,capabilities}.md`, and every file in `research/`. I also measured the app source read-only at `/srv/manhwamaniacs/dev/ManhwaManiacs` (HEAD `130d6fd3`, 2026-09-28). All line counts below come from `wc -l` on that checkout. Package versions come from the npm registry and pub.dev on 2026-09-29.

This document argues one side. Section 8 lists the three weakest points of that side as plainly as I can put them.

---

## 0. The case in six lines

1. **The redesign replaces the UI layer, and the UI layer is about half of each client.** The Flutter client is 65,272 lines: 33,880 of UI and about 27,100 of non-visual code that survives untouched. The web client has about 25,000 lines of non-component TypeScript and **159 test files, none of which tests a component**. Keeping the stacks means none of that is rewritten.
2. **Both clients already run a skin engine, one level down.** Web: `data-theme` × `data-preset` attributes stamped before first paint, with tests for orthogonality and contrast. Flutter: `AppPalette` × `AppMetrics` `ThemeExtension`s, with a test for orthogonality. A skin is the same mechanism with one more axis: screens.
3. **Flutter is the only phone stack that renders the Glass skin the same way on iOS and Android.** In React Native, both Liquid Glass packages (`expo-glass-effect` 57.0.4 and `@callstack/liquid-glass` 0.8.2) are iOS 26+ only and fall back to a plain `View` on Android. On the web, refraction works only in Chromium.
4. **The reader is the product, and its engine is already tuned.** The prefetch budget, decode caps, extent compensation, restore loop, 120 Hz and the offline store are all tested. With the stacks kept, the redesign touches only the reader's chrome.
5. **Cost:** about **161 Claude-Code-days** for both skins on all three platforms, including the four new feature areas. Cinematic can be complete everywhere after about **95**. Every alternative spends **27–55 days** getting back to today's feature set before the first new pixel.
6. **Weakest point:** four UIs to maintain forever. A single-codebase stack is cheaper on paper, by roughly 10–45 days on this scope depending on which one. Section 8.1 does the arithmetic.

---

## 1. What "keep" means, concretely

The research files have already specified the architecture: `discovery-ux.md` §10, `web-motion-libs.md` §4, `flutter-motion-libs.md`, `gestures-nav.md` §0 and `glass-language.md` §5–6. This section records only what the keep position commits to, plus the pieces the research leaves open.

### 1.1 One shared contract, two stacks, two skins each

```
design/tokens/{cinematic,glass}.json   ← single source: colour, type scale, radii, spacing,
                                          blur, motion (duration+curve | duration+bounce),
                                          haptic event names, sound event names
tools/gen-tokens.mjs  (~100 lines, no dependency)
   ├─► frontend/src/skins/<skin>/tokens.css     ([data-skin=…] custom properties → @theme inline)
   └─► mobile/lib/skins/<skin>/tokens.g.dart   (const SkinTokens … extends ThemeExtension)
ScreenId list (same ids both sides) + route paths (the contract; discovery-ux §10.1 rule 4)
```

- **Springs port 1:1 between the stacks.** Motion's `{ type: "spring", visualDuration, bounce }` and Flutter's `SpringDescription.withDurationAndBounce(duration:, bounce:)` (SDK 3.32+) take the same two parameters as SwiftUI's `.spring(duration:bounce:)`. A token such as `"sheet": { "ms": 500, "bounce": 0.1 }` therefore generates both sides exactly. Cinematic's eased curves (`cubic-bezier(0.16, 1, 0.3, 1)` ≡ `Cubic(0.16, 1, 0.3, 1)`) port the same way.
- **Generator choice.** Hand-roll the generator. `style-dictionary` 5.5.5 (Apache-2.0) is the upgrade path if the script ever passes about 200 lines.

### 1.2 Web: `data-skin` + CSS tokens + per-skin screen modules

- The structure is `src/core/` (the existing feature logic, moved but not rewritten), `src/skins/{cinematic,glass}/{tokens.css, fonts.ts, Shell.tsx, screens/*, motion.ts, haptics.ts}`, and thin `app/**/page.tsx` files that call `skins[await getSkin()].screens.X`.
- **No flash on first paint.** The boot script already stamps `data-theme`/`data-preset` from localStorage before paint (`features/preferences/appearance-boot-source.ts`). The skin also changes *which components render*, so it additionally goes into an `mm-skin` cookie that server components read (`discovery-ux.md` §10.3).
- **Free code-splitting.** RSC ships only the client chunks of the tree it rendered, so the inactive skin's code and fonts never reach the browser.
- **Completeness is a type error.** `satisfies Record<ScreenId, Screen>` on each skin makes a missing screen fail the build.
- **Dependency changes:** `framer-motion` 12.42.2 → `motion` 13.4.4 (a find-and-replace of the import path in 4 files), plus `@base-ui/react` 1.8.0, `tw-animate-css` 1.4.0, `embla-carousel-react` 8.6.0, `sonner` 2.0.8, and `lenis` 1.3.26 for Cinematic only. Everything else is copied source or native CSS, per `web-motion-libs.md`.

### 1.3 Flutter: `ThemeExtension` + Riverpod skin provider + per-skin feature folders

- The structure is `lib/core/` (today's providers, repositories, models, services, the download store and queue, and the native channels), `lib/skins/{cinematic,glass}/{tokens.g.dart, shell.dart, router.dart, screens/…}`, and `lib/skins/skin.dart` (the `Skin` interface, `SkinId`, `ScreenId`).
- **Boot and switch.** `main()` reads `SkinId` from SharedPreferences and passes it in as `ProviderScope(overrides: [skinIdProvider.overrideWithValue(id)])`. An `AppRestart` widget of about 15 lines swaps a `UniqueKey` above the scope to perform the restart the owner asked for.
- **Transitions come from the skin's router.** Each skin builds its own `GoRouter` from the shared path constants, so transitions, shell and sheet-versus-page presentation belong to the skin.
- **Existing pattern reused.** `AppMetrics`/`AppPalette` already ride on `ThemeData.extensions` with a `lerp`, and `test/app/theme/preset_metrics_test.dart` already enforces the boundary ("no preset field is a Color, at any depth"). `SkinTokens` replaces both with the same pattern, so there is nothing new to invent.
- **Completeness is a test.** One test loops over `ScreenId.values` for both skins.
- **Dependency changes:** the package list in `flutter-motion-libs.md` ("Recommended pubspec additions"). It is pinned to what resolves on the CI-pinned Flutter 3.44.6, with `haptic_feedback` held at 0.6.5 and `go_router` at ≤17.5.
- **Reader split: the one real refactor.** `features/reader/widgets/reader_content.dart` (2,065 lines) fuses the engine (feed reconcile, restore, extents, prefetch, progress, auto-scroll, tap handling) with `_ReaderControlsLayer`. Extract the engine behind a `chromeBuilder` slot in a commit that changes no pixels, before any skin work. Both entry points (`ReaderScreen` and `SourceReaderScreen`) have to move together.

---

## 2. What survives: the migration cost we avoid

| Asset | Size | Kept as-is under this position |
|---|---|---|
| Flutter non-UI code (providers 6.8k, models 5.9k, utils 4.6k, repositories 2.5k, services 1.7k, core 1.6k, download store + queue 3.8k) | ≈27,100 lines of 31,392 non-UI (theme 3,493 and router 812 are rebuilt) | yes |
| Flutter logic tests | 136 files, ≈25,600 lines | yes |
| Flutter widget tests | 76 files, 24,089 lines | no: they die with the old screens under **every** option, including keep |
| Native channels | `OcrChannel.kt` 217 (ML Kit text recognition), `MainActivity.kt` 207 (volume-key paging, display mode, RAM, free disk), `AppDelegate.swift` 221 (Vision OCR, free disk) | yes |
| Web non-component TypeScript (feature logic 22.2k, `lib/` 2.9k) incl. reader strip/preload/scrub/keymap, keyboard registry, url-state | ≈25,000 lines | yes |
| Web tests | 159 `*.test.ts`, 0 `*.test.tsx`; 2,304 vitest cases (`tests.yml`) | **100 %**: not one web test touches a component |
| Web offline downloads | `public/sw.js` 1,176 lines + `features/offline` (queue, isolation, policy contract, SW integration tests) | yes |
| CI / release | `tests.yml` (≈2,600 pytest, 2,304 vitest, 1,611 flutter), `ios-build.yml` (macOS runner, Flutter 3.44.6), `codemagic.yaml` (unsigned IPA → SideStore), APK channel via `/app/*`, CocoaPods-only offline pod graph | yes |
| Toolchains on the dev machines | Flutter 3.44.6 already in `~/flutter` (2.3 GB), Node 22.14 | yes: nothing new to download over the hostel Wi-Fi |

The reader engine deserves its own list, because it is the part a rewrite would most likely damage:

- **Flutter reader.** Image cache at 8 % of device RAM, clamped to 384–768 MB. Prefetch of 2–16 pages ahead within a 64 MB decoded budget, which learns real sizes as pages decode. Decode width is viewport × DPR, capped at 2,880 px. Page heights start from declared sizes and are corrected with scroll-offset compensation. Restore re-jumps for up to 30 frames. The continuous feed keeps a 3-chapter window with 2–30 s back-off. Progress and bookmark outboxes work offline. There are a 96 px chapter seam, timestamp-based double tap (no 300 ms single-tap delay), ProMotion unlocked (`CADisableMinimumFrameDurationOnPhone`), and Android refresh pinning. All of this is in `inventory/mobile.md` §6a and is exercised by the reader tests.
- **Web reader.** `strip.ts`, `preload.ts`, `page-metrics.ts`, `scroll-preparation.ts`, `wheel-zoom-arming.ts`, `chrome-autohide.ts` and more, each with its own `.test.ts`.

### 2.1 What each alternative spends to get back to today's feature set

A Claude-Code-day (CCD) is one Claude Code session working one slice for a day, with the owner reviewing and verifying on a device or in the browser. These are parity costs only, before any redesign work. Ranges are ±30 %.

| Alternative | Rebuild before the first new pixel | CCD | What it buys |
|---|---|---|---|
| **A. Expo SDK 57.0.25 / RN 0.87.1 replaces Flutter; Next stays** | Port about 27k lines of Dart logic to TS (14–18; some API types and query hooks can come from the web). Re-bridge ML Kit/Vision OCR, volume keys, display mode, free disk and the audio session as Expo modules (3–4). Port 136 logic test files (5–7). Build a new unsigned-IPA + SideStore path and the APK channel (2–3). Re-tune the webtoon strip on FlashList 2.3.2 + expo-image (3–5). | **27–37** | One language (TS) across clients. Real iOS 26 glass on iPhone. **Still 4 UIs**: Next stays, so both skins are still written twice. |
| **B. Expo universal (RN + react-native-web 0.21.3 + expo-router 57.0.23) for all three** | Everything in A, plus replacing Next: RSC per-skin splitting, `<ViewTransition>`, the service-worker downloads, the keyboard registry and command palette, and the cookie-auth boot path (+13–18). | **40–55** | 2 UIs instead of 4. Desktop web built on react-native-web primitives. |
| **C. Flutter everywhere (Flutter web replaces Next)** | Mobile logic is reused. The web-only pieces (SW downloads rebuilt on the Cache API or IndexedDB, httpOnly-cookie session, keyboard registry, command palette, URL state, desktop reader) are rebuilt and re-tested (20–30). | **20–30** | 2 UIs instead of 4. Premium glass relies on Impeller-only APIs (`ImageFilter.shader`), and Flutter web renders with CanvasKit/Skwasm, so web Glass is still degraded. Novel text is painted on a canvas: no browser find-in-page, weaker selection and screen-reader support, and a multi-MB engine download on first load. |
| **D. Capacitor 8.5.2 wraps the Next app for the phones** | Replace the SW downloads with native file and SQLite plugins, re-bridge OCR, rebuild the webtoon reader inside WKWebView's memory limits (20–30). | **20–30** | 2 UIs. Haptics through `@capacitor/haptics` 8.0.2. But on iPhone the Glass skin loses refraction (WebKit ignores SVG filters in `backdrop-filter`), and swipe-back and sheet physics become emulated in JS. |
| **E. SwiftUI + Jetpack Compose** | Everything, three times. | n/a | Real Liquid Glass. Not viable: there is no Mac in the loop (iOS is built only in CI), and it would mean 6 UIs. |

The keep position spends **0** here, and 4–5 days per platform on the skin-engine foundation (§6), which every option needs in some form anyway.

---

## 3. What Flutter does better for this brief

Each claim is measured against the two realistic competitors for the phones: React Native/Expo, and the web app in a wrapper or PWA.

### 3.1 Glass: identical on both phones

- **One engine for both phones.** `liquid_glass_widgets` 1.7.2 (MIT, github.com/sdegenaar/liquid_glass_widgets, 160/160 pub points) renders refraction, specular rim and chromatic aberration with its own fragment shaders on Impeller, and **the same shader runs on iOS and Android**. Its engine primitives are what the Glass skin's own components are built on: `LiquidGlassLayer`, `LiquidGlass`, `LiquidGlassBlendGroup`, and `GlassMaterializeScope`, which fades glass without an `Opacity` layer so Impeller's backdrop does not pop during route transitions. The fork also carries a Vulkan compositing fix that matters on Android.
- **React Native has no Android glass.** `expo-glass-effect` 57.0.4: "GlassView is only available on iOS 26 and above. It will fallback to regular View on unsupported platforms" (docs.expo.dev). `@callstack/liquid-glass` 0.8.2 is iOS-only by its own README. On an Android flagship the Glass skin would be a flat panel unless someone writes the refraction again on `@shopify/react-native-skia` 2.13.0, which is exactly the engine Flutter already has.
- **The web cannot match it on iPhone.** Only Chromium applies SVG displacement inside `backdrop-filter` (`web-motion-libs.md` §3.3). The owner's iPhone PWA gets frost and a rim, not refraction.
- **The SDK covers the cheap half of Glass.** `BackdropGroup` + `BackdropFilter.grouped` (3.29+) share one backdrop read across every frosted surface on a screen. `RoundedSuperellipseBorder` / `ClipRSuperellipse` (3.32+) give true continuous corners with no package. `ImageFilter.shader` (3.29+) gives progressive blur behind `isShaderFilterSupported`.

### 3.2 Gestures: one gesture arena, owned by the app

- **Back gestures.**
  - iOS: `swipeable_page_route` 0.4.8 (MIT) gives full-width swipe-back like iOS 26, with `canOnlySwipeFromEdge` per route for the horizontally paged reader. The SDK is stuck at a 20 px edge (flutter#180309).
  - Android: predictive back comes from `PageTransitionsTheme` per skin. Cinematic drives its own visuals through the `PredictiveBackRoute` hooks (`handleStartBackGesture`, `handleUpdateBackGestureProgress`, …), which is a first-party API.
- **Sheets.** `stupid_simple_sheet` 0.9.1+1 hands scroll over to drag in the middle of a gesture, the hardest sheet behaviour to fake. `smooth_sheets` 1.2.0 provides persistent sheets with detents at 0.4 and 1.0, plus `PagedSheet` for filter flows.
- **Reader gestures.** Pinch goes on the existing zoom level through `ScaleGestureRecognizer`. The double tap stays timestamp-based, and its 280 ms window is already tuned. The five-tap unlock and the tap-thirds sit in the same arena as scroll, with no JS-thread and UI-thread handoff to synchronise.
- **Against React Native (it is close).** RN 0.87 with Gesture Handler 3.3.0 and Reanimated 4.7.0 worklets is capable. The difference is that in Flutter a gesture, its spring and the widget it moves all live in one Dart isolate and one frame pipeline, so interruptible, velocity-preserving retargets are plain code: `controller.animateWith(SpringSimulation(spring, value, target, controller.velocity))`.
- **Against the web (the gap is large).** A standalone iOS PWA has no reliable custom edge swipe: WebKit's history swipe is flaky and root `overscroll-behavior` can disable it (`gestures-nav.md` §1–2). The app cannot own that gesture.

### 3.3 Haptics: a real vocabulary on both OSes

- **Every tap in the vocabulary.** `haptic_feedback` 0.6.5 (BSD-3) covers all 9 iOS types. On Android API 30+ it builds `VibrationEffect.Composition` primitives tuned to match iOS (success = CLICK ×2 rising, heavy = THUD, soft = SPIN), so the per-skin vocabulary table means the same thing on both phones.
- **Signature patterns.** `gaimon` 1.5.0 (MIT) plays one Core Haptics AHAP file on iOS and converts the same file to an amplitude waveform on Android. The Cinematic "rise" and "flame" patterns are each written once.
- **SDK notification haptics.** Since Flutter 3.41 the SDK itself has `successNotification` / `warningNotification` / `errorNotification`.
- **The web has almost nothing on iPhone.** iOS Safari has no Vibration API. The only trick is toggling a hidden `<input type="checkbox" switch>`, which gives one fixed tick. The owner asked for "rich, per skin, on iOS and Android", and a web-based phone client cannot deliver that on the iPhone.
- **React Native is at rough parity** for standard types. AHAP needs an extra native module there, too.

### 3.4 Reader performance: already tuned, stays tuned

- **The engine does not move.** The skin supplies only chrome through the `chromeBuilder` slot, so the tuned numbers in §2 carry over unchanged. On every other stack they are re-derived on devices.
- **Control that a WebView does not give.** Flutter controls decode size per image (`ResizeImage` / decode width), the global image-cache budget, the prefetch budget and frame pacing (120 Hz on ProMotion and on flagship Android through `flutter_displaymode`). A WKWebView decides decode and eviction itself, and its memory ceiling is the classic failure on long webtoon strips of 2,880 px wide images.
- **Glass and the reader stay apart.** Glass never sits inside a fast-scrolling list; it floats on chrome over it (`flutter-motion-libs.md` §3). Impeller rasterises the strip on the raster thread while the glass bar is a separate layer, so the Glass skin costs roughly one layer. The vendor figure is about 1.2 ms GPU for a full-screen sheet at 60 Hz on an iPhone 15 Pro (to be re-measured). It does not tax every page.

### 3.5 Motion: both signature animations are small

- **Heading reveal** (per letter: fade, slide up, un-blur). About 20 lines on `flutter_animate` 4.5.2 (BSD-3, Flutter Favorite); the code is in `flutter-motion-libs.md` §1. The web version is a CSS server component of about 15 lines (`web-motion-libs.md` §3.1). Both split with grapheme-safe APIs (`characters`, `Intl.Segmenter`).
- **Typing reveal at 50 ms per character.** One `.animate().custom()` on Flutter. The web version uses CSS `steps(1)` spans with a per-character delay, zero JS.
- **Springs and hero transitions.** `motor` 1.1.0 supplies `CupertinoMotion` presets (smooth 500 ms / bounce 0, snappy 500 / 0.15, interactive 150 / 0.14). `heroine` 0.7.2 does spring-driven cover-to-detail transitions with `DragDismissable` (pull down to shrink back into the card), which is the App Store feel the Glass brief describes.

### 3.6 Verification without a Mac

- **What the owner has.** No Mac. iOS is built by `ios-build.yml` on `macos-latest` and by Codemagic (`mac_mini_m2`, 60 min cap), then sideloaded through SideStore.
- **Why Flutter fits that loop.** Flutter draws the same pixels on iOS and Android with one engine. What Claude and the owner check on an Android phone, or in the headless screenshot harness, is what the iPhone shows. The only exceptions are the deliberate platform branches: back gesture and haptic mapping.
- **The harness is already there.** `test/screenshots/marketing_screenshots_test.dart` already renders real screens with provider overrides to PNG under `flutter test`. Extended to loop over both skins, it becomes the per-cluster visual check a Claude session can read. Impeller-only glass shaders will not render there, so glass still needs a device pass.
- **In React Native the Glass skin cannot be seen before a build.** Its iOS glass is native UIKit, so it is invisible until a cloud Mac build lands on the phone.

---

## 4. What Next 16 + Tailwind 4 + Motion does better for the web half

The owner's decisions ask for a **full desktop design**: sidebars, hover states, keyboard-first navigation, and a wide reader with side panels. That is home ground for the web platform.

- **Per-skin screens chosen on the server.** A route file is a server component that picks `skins[skin].screens.X`. The inactive skin costs zero bytes, with no dynamic-import registry to maintain.
- **Route and shared-element transitions with no client JS of our own.** React `<ViewTransition>` ships in Next 16.2.9's bundled React. `next/link` `transitionTypes` (16.2+) makes transitions directional, and `name` pairs let a cover morph into the series hero. Each skin writes its own CSS for `::view-transition-*`. Unsupported browsers swap instantly and nothing breaks.
- **Tokens are native CSS.** Tailwind 4 `@theme inline` reads `[data-skin=…]` custom properties, and `@custom-variant cinematic` / `glass` covers the few shared primitives. Glass springs are exported once as CSS `linear()` easings (`spring(0.5, 0.1)` from Motion), so skeletons and hovers get real spring curves without hydrating.
- **Text stays real DOM text.** The novel reader gets selection, find-in-page, browser zoom, screen readers and the `lib/keyboard` registry (34 bindings, chords like `g l`, a command palette on `mod+k`). Flutter web would paint all of that on a canvas.
- **Offline downloads already work.** The service worker plus its isolation and policy tests survive as they are.

---

## 5. Honest limits that apply to keep and to most alternatives

- **Glass on the iPhone PWA is blur plus rim, not refraction.** That is true under keep (Next), B (react-native-web) and D (Capacitor). Only a native phone client fixes it for the phone, and keep has one: owner-grade Glass lives in the Flutter app, and the web is the desktop client.
- **The phones stay on Flutter 3.44.6 until the ecosystem's 3.47 / `material_ui` split is dealt with separately.** That holds `go_router` ≤17.5, `animations` ≤2.2.0 and `haptic_feedback` at 0.6.5. Stay on Riverpod 2.6.1 (3.4.3 is out) until the redesign ships. None of these limits a design decision.

---

## 6. Effort estimate in Claude-Code-days, per platform, per skin

**How the numbers were built.** Take the inventory's scope (web: 32 screens, 503 element rows, 118 actions; mobile: 34 screens, 496 elements, 157 actions), add the four new feature areas from `00-decisions.md`, and group the work into clusters that one session can finish together with their loading, empty, error and offline states. Cinematic is built first on both platforms. The second skin's *screen* rows are discounted to 0.85, because data wiring, states and information architecture per screen are already solved. Primitives, shell and polish are not discounted.

| Work (per skin unless marked) | Web Cinematic | Web Glass | Flutter Cinematic | Flutter Glass |
|---|---:|---:|---:|---:|
| Primitives kit, about 25 components incl. both signature reveals, download ring, skeletons, empty/error/offline | 4.0 | 4.5 | 3.5 | 4.0 |
| Shell, navigation, transitions, haptic and sound maps (web: desktop sidebar + mobile-web tab bar; Glass: dock, tab-bar minimize, accessory) | 2.5 | 3.0 | 2.0 | 2.5 |
| Brand in the app: wordmark, splash, logo reveal, icons | 1.0 | 1.0 | 1.5 | 1.5 |
| Auth, setup, splash, profiles (7 screens) | 1.5 | 1.3 | 1.5 | 1.3 |
| Home and library cluster (home, browse, collections ×2, history, bookmarks) | 3.5 | 3.0 | 3.0 | 2.6 |
| Series detail, manga + novel, chapter list, download picker | 2.5 | 2.1 | 2.5 | 2.1 |
| Sources, source browser, federated search | 2.0 | 1.7 | 2.0 | 1.7 |
| Manga reader chrome on the shared engine (web adds wide side panels) | 2.5 | 2.1 | 2.0 | 1.7 |
| Novel reader chrome, 4 sheets, listen mode | 2.5 | 2.1 | 2.5 | 2.1 |
| Updates, downloads, OCR, stats, recommendations | 3.0 | 2.6 | 3.0 | 2.6 |
| Settings (incl. the skin switcher with live previews), security, members, backup, storage, diagnostics, status | 2.0 | 1.7 | 2.0 | 1.7 |
| 404, route error, root error, offline fallback | 0.5 | 0.4 | 0.5 | 0.4 |
| Verification and polish (devices, reduced motion, a11y, profiling; Flutter includes CI iOS round trips) | 1.5 | 1.5 | 2.5 | 2.5 |
| **Existing scope, per skin** | **29.0** | **27.0** | **28.5** | **26.6** |
| New: AI home + "previously on" recap (1.5), stats/streaks/Wrapped/share cards (2.5), social for 2–3 users (2.0), ambient reader extras chrome (1.5) | 7.5 | 6.4 | 7.5 | 6.4 |
| **Per skin total** | **36.5** | **33.4** | **36.0** | **33.0** |

Work that is done once per platform, not per skin:

| Once-per-platform work | Web | Flutter |
|---|---:|---:|
| Foundation. **Web:** core/skins split, `mm-skin` cookie, `getSkin()`, `ScreenId` + `satisfies`, Motion 13, Base UI, token generator. **Flutter:** `Skin`, `AppRestart`, per-skin `GoRouter`, `SkinTokens`, `SkinHaptics` + `mm/haptics` channel, pubspec batch + CI dry run, predictive-back manifest flag, reader engine extraction, completeness test, screenshot harness per skin | 4.0 | 5.0 |
| Engines for the new features. **Web:** share-card export, soundscape on Web Audio. **Flutter:** `RepaintBoundary.toImage` export + share sheet, soundscape on `just_audio`, palette extraction in an isolate, the panel-guided view | 2.0 | 3.0 |
| **Platform total (both skins)** | **75.9** | **77.0** |

- **Backend** for the new features (social tables and endpoints, AI recap, Wrapped aggregates, per-cover palette, panel boxes): about 8 CCD. This cost is the same under every stack.
- **Grand total: about 161 CCD.**
- **First milestone: Cinematic complete on web, Android and iOS**, including the new features: 4 + 5 (foundations) + 2 + 3 (engines) + 36.5 + 36.0 + 8 = **94.5 CCD**. Glass then adds about 66.
- **Calendar.** Run one web session and one Flutter session on the *same cluster at the same time*, with a third session on the backend when needed. Throughput is then limited by owner review, not by Claude. Plan for about 50 working sittings to the Cinematic switch-over and about 85 for everything.
- **Re-estimate after the first two clusters** (primitives + the library cluster), which calibrate every row.

### 6.1 How this ships under "web + Android + iOS always release together"

- **Build the skins beside the current UI.** `SkinId` gets a third, hidden value `legacy`, which is the default. The new skins live behind it (a debug-only row in Settings), so every sitting can still commit, push and release all three platforms together without shipping a half-built skin. This follows the "commit small and often" and "always deploy" rules.
- **Flip Cinematic** when its `ScreenId` completeness check passes on both platforms, then delete `legacy` (its 33,880 Flutter UI lines and the web components) in the same release.
- **Build Glass the same way, then flip it on.**

---

## 7. Risk list (keep position)

| # | Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| R1 | **The same skin drifts between web and phone**: Cinematic's hero, rails or springs feel different in the two implementations | High | Medium | One token JSON generates both sides. Build each cluster on both platforms in the same sitting. Review side by side (Flutter screenshot harness + Playwright screenshots). |
| R2 | **`liquid_glass_widgets` breaks or stalls.** It is a young fork with near-daily releases (1.7.2, 2026-09-22); upstream `liquid_glass_renderer` is marked "EXPERIMENTAL" | Medium | High for Glass | Pin exactly. Build the Glass components on our own thin `SkinGlass` wrapper so the engine can be swapped for `BackdropFilter` + `BackdropGroup` in one file. The code is MIT, so vendor it if upstream dies. |
| R3 | **Glass costs GPU and memory on Android Vulkan.** Known issues: memory spike while glass animates (flutter#138627), blur and shader cannot share one `BackdropFilter` (flutter#170820), Impeller blur is costlier than Skia's (flutter#161297) | Medium | Medium | At most 2 stacked glass layers. Glass on chrome only, `GlassQuality.premium` only on static chrome. Animate `visibility`, not geometry. Profile on the owner's Android flagship with Diagnostics (S34 already shows FPS and jank). |
| R4 | **The iOS loop is remote-only** (`ios-build.yml` / Codemagic → SideStore), so tuning haptics and glass on the iPhone is slow | High | Medium | Tune on Android first; the pixels are identical. Batch iOS checks per cluster. Add every new native plugin (`haptic_feedback`, `gaimon`, `sensors_plus`, share) in one isolated commit with a CI dry run. Defer Rive (its build-time binary download and NDK 27 conflict with the offline pinned pod graph). |
| R5 | **Reader engine extraction regresses the most-tuned code** | Medium | High | Extract first as a commit that changes no pixels, gated by the existing reader tests. Move both entry points (`ReaderScreen` and `SourceReaderScreen`) together. |
| R6 | **Flutter 3.44 is locked while packages move to 3.47 / `material_ui`** | Medium (grows) | Low now, Medium later | Pin list from `flutter-motion-libs.md`. Do the 3.47 + `material_ui` + Riverpod 3 upgrade as a separate change after Glass ships, not during it. |
| R7 | **Widget-test churn**: 76 files / 24k lines stop compiling as screens are replaced | Certain | Low | Delete them with `legacy`. Replace them with the completeness test plus one smoke test per cluster per skin. The 136 logic test files and all 159 web test files are untouched. |
| R8 | **Web transition APIs move** (`<ViewTransition>` came through canary React; Motion 13 is a major version) | Low | Medium | Keep Next pinned (16.2.9 today) and upgrade deliberately. `<ViewTransition>` degrades to an instant swap. Motion 12→13 changes only the import path here. |
| R9 | **Four UIs slow every future feature** | Certain | Medium | See §8.1. Keep skins complete-or-absent (no per-component fallback), so the cost is visible and never half-paid. |
| R10 | **Dev host constraints.** The owner wants Claude Code on the VPS because of bad network. That box (3.8 GB RAM, 2 cores) also runs production, recall and five bots | High | High if ignored | On the VPS, run only edits, `tsc`, `eslint`, `vitest`, `flutter analyze`, `flutter test` and the headless screenshot harness, and measure memory first. `next build` and Gradle/Xcode builds stay in CI (`tests.yml`, `ios-build.yml`, Codemagic) or on the laptop. Keep the "next build before push" rule: `tsc` and `eslint` miss Turbopack CSS-module purity errors. |
| R11 | **The owner's review bandwidth**: about 161 CCD through one reviewer | High | Medium | Cinematic first, then the new features on Cinematic, then Glass. Each flip is a shippable end state. |

---

## 8. The three weakest points of this position

### 8.1 Four UIs, permanently

Two skins × two codebases means every screen, now and in every later feature, is written four times. On this document's own numbers, skin-specific UI work is about 139 of the 161 CCD. A single-codebase stack builds each skin once plus desktop layouts. Rough comparison on the current scope:

| Option | Parity cost | Skin + feature UI | Once-only work | Total (approx.) |
|---|---:|---:|---:|---:|
| Keep (this paper) | 0 | ≈139 | ≈22 | **≈161** |
| C. Flutter everywhere | 20–30 | ≈69 (Flutter skins) + ≈10 (desktop layouts) | ≈16 | **≈115–125** |
| B. Expo universal | 40–55 | ≈69 + ≈10 | ≈16 | **≈135–150** |

On paper, Flutter-everywhere is 35–45 CCD cheaper on this scope, and the gap *widens* with every future feature. My counter:

- It is only cheaper if Flutter web is good enough for a keyboard-first desktop client with a novel reader and a webtoon strip. That means canvas text, no find-in-page, a multi-MB first load, CanvasKit image memory on long strips, and premium glass degraded on web anyway.
- Its savings arrive only after 20–30 days of rebuilding working, tested systems.

That is a judgement call, not a proof. Over a multi-year horizon this is the strongest argument against keeping.

### 8.2 Glass is an imitation, on young dependencies

- **What Flutter's Glass actually is.** It is a shader re-implementation of Apple's material. It is not UIKit's Liquid Glass, which adapts system-wide, tracks accessibility settings and costs Apple's GPU budget rather than ours.
- **Its dependencies are young.** The engine behind it is a single-maintainer fork (324 pub likes) of an upstream still marked experimental, with three open engine bugs that touch exactly this workload (R2, R3).
- **React Native gets the real thing on iPhone.** It does so through `expo-glass-effect`, but only on iPhone; it has nothing on Android.
- **The web copy of Glass is weakest on the owner's own phone.** The iPhone PWA gets no refraction.

So under keep, Glass is "very close" on both phones and a "graceful fallback" on the iPhone web. It is never pixel-exact Apple.

### 8.3 One skin, two hand-written implementations

- **What can and cannot be shared.** Tokens, spring parameters, haptic event names and route contracts can be shared. Choreography, gesture feel, component behaviour and layout cannot. Cinematic-on-web and Cinematic-on-phone are two separate pieces of craft that have to be kept in step by hand, and each has to be checked on its own (browser pass plus device pass).
- **Where the drift will show.** The owner switches between web and phone daily and will notice when a rail's snap or a sheet's spring differs.
- **The mitigations are process, not structure.** Same-sitting pairing, side-by-side screenshots and generated tokens reduce the drift but do not remove it. A single-codebase stack does not have this problem at all.

---

## 9. Sources

- App source (read-only): `/srv/manhwamaniacs/dev/ManhwaManiacs` at `130d6fd3`. Measured files: `mobile/lib/**`, `mobile/test/**`, `mobile/pubspec.yaml`, `mobile/android/app/src/main/kotlin/com/manhwamaniacs/reader/{MainActivity,OcrChannel}.kt`, `mobile/ios/Runner/AppDelegate.swift`, `frontend/src/**`, `frontend/package.json`, `frontend/public/sw.js`, `.github/workflows/{tests,ios-build}.yml`, `codemagic.yaml`.
- Research inputs: `research/flutter-motion-libs.md`, `research/web-motion-libs.md`, `research/gestures-nav.md`, `research/glass-language.md`, `research/discovery-ux.md` §10, `research/reader-ux.md`, `inventory/*.md`.
- Expo GlassView platform note: https://docs.expo.dev/versions/latest/sdk/glass-effect/
- `@callstack/liquid-glass` (MIT, iOS 26 only): https://github.com/callstack/liquid-glass
- `liquid_glass_widgets` (MIT): https://github.com/sdegenaar/liquid_glass_widgets · https://pub.dev/packages/liquid_glass_widgets
- `haptic_feedback` (BSD-3): https://pub.dev/packages/haptic_feedback · `gaimon` (MIT): https://pub.dev/packages/gaimon
- `swipeable_page_route` (MIT): https://pub.dev/packages/swipeable_page_route · `stupid_simple_sheet` / `motor` / `heroine` (MIT): https://github.com/whynotmake-it/rivership · `smooth_sheets` (MIT): https://github.com/fujidaiti/smooth_sheets · `flutter_animate` (BSD-3): https://github.com/gskinner/flutter_animate
- Flutter issues: https://github.com/flutter/flutter/issues/180309 (full-width back swipe), /138627 (glass memory spike), /170820 (blur + shader filter), /161297 (Impeller blur cost)
- npm registry, 2026-09-29: `expo` 57.0.25, `expo-glass-effect` 57.0.4, `expo-router` 57.0.23, `react-native` 0.87.1, `react-native-reanimated` 4.7.0, `react-native-gesture-handler` 3.3.0, `react-native-web` 0.21.3, `@shopify/flash-list` 2.3.2, `@shopify/react-native-skia` 2.13.0, `@capacitor/core` 8.5.2, `@capacitor/haptics` 8.0.2, `motion` 13.4.4, `@base-ui/react` 1.8.0, `next` 16.3.6, `style-dictionary` 5.5.5 (all MIT except style-dictionary, Apache-2.0).
- React `<ViewTransition>`: https://react.dev/reference/react/ViewTransition · Next.js view transitions guide: https://nextjs.org/docs/app/guides/view-transitions
