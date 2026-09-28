# Move to Expo: one implementation per skin, on web, iOS and Android

Position paper for the ManhwaManiacs two-skin redesign (Cinematic / Glass). Written 2026-09-28.

Inputs: `inventory/00-decisions.md`, `inventory/{web,mobile,capabilities}.md`, every file in `research/`, `00-baseline.md`, and the opposing paper `stack-keep.md`, which this document answers point by point (§3). The app source was measured read-only at `/srv/manhwamaniacs/dev/ManhwaManiacs` (HEAD `130d6fd`). Line counts come from `wc -l` and `grep` on that checkout. Package versions come from `npm view` on 2026-09-28.

This document argues one side. Section 10 lists the three weakest points of that side as plainly as I can put them.

---

## 0. The case in seven lines

1. **The redesign already throws away every UI line in both clients.** The owner's decision is "0 to 100, every element redesigned, two near-separate apps". A stack change is never cheaper than when the UI is being rewritten anyway. That moment is now, and it will not come again.
2. **Keep means four UIs forever: 2 skins × 2 codebases.** Expo universal means two: each skin is written once and runs on iOS, Android and web. `stack-keep.md` §8.1 concedes this is its strongest counter-argument, and its own table puts Expo universal at ≈135–150 CCD against keep's ≈161.
3. **Most of the shared data layer already exists, in TypeScript.** 11,712 lines in 142 files of `frontend/src/features` + `lib` touch no DOM and no Next API. They move into a shared `core` package unchanged, together with their tests. The 27k lines of Dart logic that `stack-keep.md` prices at 14–18 CCD to port are mostly a *second copy* of that layer; the genuinely mobile-only part is about 6k lines (downloads store and queue, outboxes, native bridges).
4. **On the owner's own phone (an iPhone), Expo gets the real Liquid Glass**, not a shader imitation: `expo-glass-effect` 57.0.4 `GlassView`/`GlassContainer`, native iOS 26 tabs that minimise on scroll, native form sheets with detents, and the system full-width back swipe. `stack-keep.md` §8.2 concedes Flutter's Glass "is never pixel-exact Apple".
5. **The iOS loop gets shorter, not longer.** `expo-updates` ships JS-only changes to the sideloaded app over the air, so a Mac build is needed only when a native dependency changes. Today every change costs a macOS CI round trip plus a SideStore update.
6. **Cost:** about **131 CCD** for both skins on all three platforms, with the four new feature areas (range ±30 %). Cinematic complete everywhere after about **88**, roughly the same as keep's 94.5; the saving arrives with Glass and then repeats on every future feature, because each one is built twice instead of four times.
7. **Weakest point:** Glass on Android and on the web is frost + rim, not refraction; the tuned reader engine is re-built on a new list; and Expo web is a weaker desktop web than Next. Section 10.

---

## 1. What "move to Expo" means, concretely

### 1.1 Repository shape

```
packages/core/          ← moved from frontend/src/{features,lib,services,types,config}: every file with no DOM
                          and no Next import (142 files, 11,712 lines) + their *.test.ts
  src/platform/         ← 3 small adapters: storage (MMKV | localStorage), auth (bearer | cookie), files
design/tokens/{cinematic,glass}.json   ← imported directly by TS on every target; no generator needed
app/                    ← Expo app: iOS, Android and web from one tree
  app/                  ← expo-router routes (thin: `export default skins[skin].screens.Home`)
  src/skins/cinematic/  ← Shell, screens/*, primitives/*, motion.ts, haptics.ts, sounds.ts
  src/skins/glass/      ← same shape; completeness enforced by `satisfies Record<ScreenId, Screen>`
  src/web/              ← web-only: sw registration, keyboard registry + command palette, view transitions
  modules/mm-native/    ← one local Expo module: OCR, volume-key paging, display mode, AHAP haptics
frontend/  mobile/      ← legacy clients, still released until the Cinematic flip (§8), then deleted
```

Platform differences are resolved by file suffix (`Foo.ios.tsx`, `Foo.android.tsx`, `Foo.web.tsx`), never by `if (Platform.OS)` inside a shared screen. This follows `discovery-ux.md` §10 rule 1: screens belong to the skin, data belongs to the host.

### 1.2 Package set (pinned, npm 2026-09-28)

| Concern | Package | Version | Notes |
|---|---|---|---|
| Runtime | `expo` / `react-native` | 57.0.25 / 0.87.1 | New Architecture only; React 19 like the web today |
| Routing | `expo-router` | 57.0.23 | Typed routes; native stack (`react-native-screens` 4.28.0) and native tabs on iOS/Android, URL routing on web |
| Styling | `nativewind` | 4.2.7 (5.0.0-rc.0 tracks Tailwind 4 via `react-native-css` 3.0.7) | Tokens as CSS variables in both skins; `hover:`/`focus-visible:` variants work on web |
| Motion | `react-native-reanimated` + `react-native-worklets` | 4.7.0 + 0.13.0 | Worklet springs on the UI thread; Reanimated 4 CSS-style `animationName`/`transitionProperty` for declarative keyframes |
| Gestures | `react-native-gesture-handler` | 3.3.0 | Pan/pinch/fling composed with native scroll |
| Glass (iOS 26) | `expo-glass-effect` | 57.0.4 | `GlassView`, `GlassContainer` (merging/morphing), `isLiquidGlassAvailable()` |
| Native UI (iOS) | `@expo/ui` | 57.0.20 | SwiftUI hosts for the few controls that must be system-real (menus, pickers, segmented control) in Glass |
| Blur (Android, web) | `expo-blur` | 57.0.3 | Android real blur via the `dimezisBlurView` method; web uses CSS `backdrop-filter` |
| Shaders | `@shopify/react-native-skia` | 2.13.0 | Glass rim/specular on Android, per-letter blur on iOS (§3.5), streak flame, genre radar |
| Sheets | native `formSheet` presentation (expo-router) + `@gorhom/bottom-sheet` 5.2.14 | | Native detents on iOS/Android; gorhom where the sheet must hand scroll over to drag mid-gesture |
| Lists | `@shopify/flash-list` | 2.3.2 | Rails, grids, the webtoon strip |
| Images | `expo-image` | 57.0.5 | Disk + memory cache, `recyclingKey`, `Image.prefetch`, decode downscaling |
| Haptics | `expo-haptics` | 57.0.3 | iOS impact/notification/selection; Android `performAndroidHapticsAsync` exposes the API 30/34 constants (`Confirm`, `Reject`, `Gesture_Start`, `Segment_Tick`, `Toggle_On`/`Off`) that `gestures-nav.md` says Flutter needs a hand-written channel for |
| Audio (TTS listen mode, soundscape, UI sounds) | `expo-audio` | 57.0.5 | Source `{ uri, headers }` carries the bearer token, so Range seeking works as today; lock-screen controls |
| Downloads | `expo-sqlite` 57.0.3, `expo-file-system` 57.0.7, `expo-crypto` 57.0.3 | | Same schema as today's `downloads_db.dart`; content-addressed blobs |
| Storage | `react-native-mmkv` 4.3.2, `expo-secure-store` 57.0.4 | | Per-profile scoped storage backs the existing `lib/scoped-storage.ts` API |
| Data | `@tanstack/react-query` 5.104.0, `zustand` 5.0.15 | | Already what the web uses; the hooks move as they are |
| Share cards | `react-native-view-shot` 6.0.1 + `expo-sharing` 57.0.22 | | Wrapped cards to PNG and the share sheet |
| Misc | `expo-keep-awake` 57.0.2, `expo-screen-orientation` 57.0.2, `expo-dev-client` 57.0.19, `expo-build-properties` 57.0.22 | | |

All MIT.

---

## 2. What is shared: measured, not hoped

### 2.1 The web feature layer is already platform-neutral

Every `.ts` file (tests and `.testing.ts` harnesses excluded) in `frontend/src/features` and `frontend/src/lib`, classified by grep:

| Class | Files | Lines | What happens |
|---|---:|---:|---|
| No DOM global, no `next/*` import | **142** | **11,712** | Moves to `packages/core` verbatim. Includes all API types, query hooks (1,868 lines import React or TanStack, both of which run on RN), `reading-stats.ts` (740), `history-continue.ts`, `novels/book.ts`, `bookmarks/anchor.ts`, `sources/global-search.ts`, the download queue and policy logic |
| Touches `window` / `document` / `localStorage` / `navigator` / service worker | 72 | 12,270 | Split. Most hits are `localStorage` reads behind small stores (`preferences/theme-store.ts` 13 hits, `preset-store.ts` 9, `novels/settings.ts` 8, `library/density.ts` 8); those switch to the storage adapter in `core/platform` (a 1-line change each). The real DOM code (`offline/client.ts`, `reader/strip-source.ts`, `use-fullscreen.ts`, `lib/keyboard/*`) stays in `app/src/web/` and keeps serving the web target |
| Imports `next/*` | a handful | 62 | Router and link calls; replaced by `expo-router` equivalents |

Plus `services/http.ts` (209 lines), `stores/`, `types/`, `config/`. `http.ts` gains one option, `auth: "cookie" | "bearer"`: the web keeps the httpOnly `mm_session` cookie, the phones send the bearer token the backend already accepts from the Flutter client.

**None of the 159 web test files is thrown away.** Logic tests move with their module into `packages/core`; DOM tests (service-worker harness, strip, keymap) stay with the web-only files they cover. Vitest keeps running them.

### 2.2 The Dart logic is mostly a duplicate

`stack-keep.md` §2.1 prices "port about 27k lines of Dart logic to TS" at 14–18 CCD. Split by what it does:

| Dart logic | Lines (approx.) | Already exists in TS? |
|---|---:|---|
| API models, repositories, providers for library, sources, novels, updates, auth, profiles, collections, bookmarks, settings | ≈17k | **Yes.** `features/*/types.ts`, `hooks.ts`, `store.ts` cover the same endpoints (`capabilities.md` lists one API for both clients) |
| Downloads: store + queue + services + models + providers (`features/downloads/*` minus screens and widgets) | ≈6.3k | Partly. The queue *policy* and formatting exist (`offline/download-queue.ts`, `format.ts`), the SQLite store and blob store do not |
| Progress and bookmark outboxes, offline readers | inside the above | Partly (`novels/pending-progress.ts`) |
| Native bridges: `OcrChannel.kt` 217, `MainActivity.kt` 207, `AppDelegate.swift` 221 | 645 (Kotlin/Swift) | Not TS, but **reused as native code**, see §6.2 |
| Reader engine (prefetch budget, decode caps, extent compensation, restore loop, seam, double tap) | ≈3k of `features/reader` | The web has its own tested equivalents (`strip.ts` 407, `preload.ts`, `page-metrics.ts`, `scroll-preparation.ts`, `chrome-autohide.ts` 459, `chrome-controller.ts` 219). The *numbers* (64 MB decode budget, 2,880 px cap, 30-frame restore, 280 ms double tap) are documented in `inventory/mobile.md` §6a and are carried over as constants |

So the real port is the downloads store and queue (~6k lines), the reader engine's native half, and the bridges. That is what §4 prices.

### 2.3 One skin, one implementation

The shared unit is no longer "tokens plus route contracts" (`stack-keep.md` §8.3) but the whole screen: the same `HomeScreen.tsx` renders the Cinematic hero, rails and continue-reading row on an iPhone, an Android flagship and a desktop browser. Differences are layout (breakpoints, a desktop sidebar shell in `Shell.web.tsx`) and a few platform files. Drift between web and phone, the keep paper's risk R1 (High likelihood), stops being a process problem because there is nothing to drift.

---

## 3. Answering `stack-keep.md`, point by point

### 3.1 "Flutter is the only phone stack that renders Glass the same way on iOS and Android" (keep §0.3, §3.1)

True, and the wrong target. The owner's brief is *Apple Liquid Glass / visionOS*. On iOS 26 Expo renders the system material itself:

- `GlassView` with `glassEffectStyle="regular" | "clear"`, `tintColor`, `isInteractive` (the press-to-flex response), and `GlassContainer spacing={…}` so neighbouring glass shapes merge and morph as they approach, which is the signature liquid behaviour. It adapts to Reduce Transparency and Increase Contrast by itself, which `liquid_glass_widgets` re-implements by hand.
- Native tabs in expo-router on iOS 26 are real `UITabBarController` glass tabs, with minimise-on-scroll-down and the bottom accessory the Glass brief calls for (`glass-language.md`), with no custom code.
- `presentation: "formSheet"` with `sheetAllowedDetents: [0.4, 1.0]` is a real `UISheetPresentationController`: glass background, detents, rubber-band and the scroll-to-drag handoff are Apple's.
- The native stack gets iOS 26's full-width interactive back swipe from `UINavigationController`. Flutter's SDK is stuck at a 20 px edge (flutter#180309, cited by keep) and needs `swipeable_page_route` to imitate it.

Android has no system Liquid Glass at all, so every stack imitates it there. Expo's Android Glass is `expo-blur` (real blur, `dimezisBlurView`) plus a Skia rim and specular highlight: frost-grade, without refraction. That is a real loss against Flutter on Android, and it is in §10.1. It is the right trade for this household: the owner's daily phone is the iPhone that SideStore updates, and there Expo's Glass is the genuine article while Flutter's is, in keep's own words, "very close".

On the web both stacks are identical: CSS `backdrop-filter`, SVG displacement refraction in Chromium only (`web-motion-libs.md` §3.3).

### 3.2 "One gesture arena, owned by the app" (keep §3.2)

Keep itself calls RN "close". Reanimated 4 worklets and Gesture Handler 3 run gesture, spring and transform on the UI thread; a velocity-preserving retarget is `offset.value = withSpring(target, { ...spring, velocity: e.velocityY })` inside `onEnd`. Where keep needs three Flutter packages to reach system behaviour (full-width back, sheet handoff, predictive back hooks), the native stack and native sheets *are* system behaviour. The reader's tap-thirds, double tap (280 ms timestamp window, kept) and five-tap unlock compose with the FlashList scroll through `Gesture.Exclusive` / `simultaneousWithExternalGesture`.

### 3.3 Haptics (keep §3.3)

Keep: "React Native is at rough parity". Better than parity on Android: `expo-haptics` 57 exposes `performAndroidHapticsAsync(AndroidHaptics.Segment_Tick | Gesture_Start | Confirm | Reject | Toggle_On …)`, the API 30/34 constants `gestures-nav.md` §1 says Flutter must reach through a hand-written `MethodChannel`. The two AHAP signature patterns (Cinematic "rise" and "flame") go into `modules/mm-native` as ~80 lines of Swift (`CHHapticEngine` + `CHHapticPattern(contentsOf:)`) and ~60 lines of Kotlin (`VibrationEffect.Composition` / `createWaveform`), which is what `gaimon` does. One shared `haptics.ts` table per skin maps event names to calls on both OSes; on web it maps to nothing.

### 3.4 Reader performance (keep §3.4)

This is keep's strongest practical point, and the honest answer is: yes, the native reader engine is rebuilt. What makes it tractable:

- **The web engine is already TS and already tested.** `strip.ts`, `preload.ts`, `page-metrics.ts`, `scroll-preparation.ts` hold the windowing, height estimation and prefetch logic. The native strip reuses their pure parts and adds only the native bindings.
- **The Flutter numbers transfer as constants**, not as code: prefetch 2–16 pages ahead within a 64 MB decoded budget, decode width = viewport × DPR capped at 2,880 px, 3-chapter feed window with 2–30 s back-off, 96 px seam, 30-frame restore.
- **The primitives exist.** FlashList 2 (no size estimates needed, `maintainVisibleContentPosition` for extent correction, `onViewableItemsChanged` for progress), `expo-image` with `recyclingKey`, `cachePolicy="memory-disk"`, `Image.prefetch(urls, { cachePolicy: "memory-disk", headers })`, and decode downscaling to the displayed size. ProMotion: `CADisableMinimumFrameDurationOnPhone` goes into `app.json` `ios.infoPlist`; Android refresh pinning is a 20-line method in `mm-native` copied from `MainActivity.kt`.
- **Glass and the reader stay apart** exactly as keep describes: glass floats on chrome, never inside the strip.

Priced at 5 CCD in §4 and gated by the device spike in §8.

### 3.5 Motion (keep §3.5)

- **Typing reveal (50 ms per char):** a `useTyped` hook, identical to the one already written for the web in `cinematic-language.md`, runs unchanged on all three targets.
- **Heading reveal (fade, slide up, un-blur, staggered):** fade and slide are Reanimated 4 keyframes per grapheme (`Intl.Segmenter` is available in Hermes on RN 0.87), `animationDelay: i * 28ms`, 420 ms, `cubic-bezier(0.16, 1, 0.3, 1)`. The un-blur is the one wrinkle: RN's `filter: blur()` is Android-only, so on iOS the H3/hero headline renders through a Skia `<Text>` with an animated `<Blur blur={…}/>` (12 px → 0). On web it is CSS `filter: blur()`. One component, `LetterReveal`, with a `LetterReveal.ios.tsx` body.
- **Springs:** Reanimated's `withSpring({ duration, dampingRatio })` takes the SwiftUI pair directly (`dampingRatio = 1 − bounce` for bounce ≥ 0). The token `"sheet": { "ms": 500, "bounce": 0.1 }` is read from JSON by the same TS on every target: no generator, no Dart output, no drift.
- **Shared-element cover → detail:** Reanimated's shared transitions (`sharedTransitionTag`) on native, `document.startViewTransition` in a web-only navigation hook.

### 3.6 "Verification without a Mac: in React Native the Glass skin cannot be seen before a build" (keep §3.6)

It can, after one build. The owner installs one `expo-dev-client` build (a normal unsigned IPA through SideStore) containing every native module. From then on, Glass JS changes appear on the iPhone in seconds through Metro over a Cloudflare tunnel, and `GlassView` is the real UIKit view. A new Mac build is needed only when `modules/mm-native` or the dependency list changes. Release builds get JS-only fixes through `expo-updates` (§5.3). Under keep, *every* iOS change is a macOS CI build plus a SideStore update, which keep's own risk R4 rates High likelihood.

Keep's screenshot harness has an equivalent: Playwright against the Expo web export renders both skins' screens headlessly on the VPS, which Claude can read. It does not show native glass (neither does keep's harness show Impeller shaders).

### 3.7 The keep paper's cost table (keep §2.1, §8.1)

Keep prices option B at 40–55 CCD of parity. It double-counts the Dart logic port (§2.2 above: ~17k of the 27k lines already exist in TS) and prices the web replacement (+13–18) as if the service worker, keyboard registry and cookie boot had to be rewritten. They do not: `public/sw.js` (1,176 lines) is plain JS that Expo web serves from `public/` unchanged, and `lib/keyboard/*` is DOM TypeScript that becomes a web-only module. §4 prices it at about 30.

---

## 4. Effort in Claude-Code-days

Same unit as `stack-keep.md` (one session, one slice, one day, owner verifying), same scope (inventory + four new feature areas), same ±30 % band. To keep the comparison honest I start from keep's own per-skin Flutter screen numbers: writing an RN screen with states is the same work as writing a Flutter screen with states.

### 4.1 Once: parity and foundation

| Work | CCD |
|---|---:|
| `packages/core`: move 142 files, storage/auth/file adapters, move their tests, workspace + TS project refs | 3.0 |
| Downloads on native: `expo-sqlite` store with today's schema (`saved_chapters`, `saved_pages`, `blobs`, `progress_outbox`, `bookmarks`, `bookmark_outbox`), content-addressed blob store on `expo-file-system`, queue controller, request gate, retention, storage floor, zip export, offline manga + novel readers | 6.0 |
| `modules/mm-native` (Expo Modules API, Swift + Kotlin): OCR from `OcrChannel.kt` and `AppDelegate.swift` Vision code, volume-key paging, display mode, free disk, AHAP haptics | 2.5 |
| Listen mode on `expo-audio` (bearer header, Range seeks, speech audio session, lock screen), voice previews | 1.0 |
| Native reader engine on FlashList 2 + `expo-image`, porting the pure web strip logic and the Flutter constants; both entry points (library reader and source reader) from day one | 5.0 |
| CI and release: unsigned IPA on `macos-latest`, APK with the existing keystore, OTA channel, version scheme, `tests.yml` jobs | 3.0 |
| Tests: port the ~40 mobile-only logic test files (downloads 25, outboxes, OCR payload, reader constants); installed-data migration from sqflite | 3.0 |
| Web target replaces Next: SW registration and Downloads on the existing `sw.js`, cookie session boot, static export behind Caddy with `/api` proxied (same origin), keyboard registry + `mod+k` palette, per-skin lazy bundles, view-transition hook, wide reader | 6.0 |
| **Parity subtotal** | **29.5** |
| Skin engine: `SkinId`, root remount on switch (a keyed `<Root key={skin}>`, the same 15-line trick as keep's `AppRestart`), token JSON → NativeWind CSS variables, `ScreenId` completeness via `satisfies`, haptic + sound maps, Playwright screenshot loop per skin | 4.0 |
| New-feature engines: share-card export (view-shot / canvas on web), soundscape on `expo-audio` / Web Audio, palette extraction (Skia `readPixels` natively, `colorthief` 3.5.0 on web), panel-guided view | 3.5 |

### 4.2 Per skin (built once, runs on three targets)

| Work | Cinematic | Glass |
|---|---:|---:|
| Keep's per-skin Flutter total (existing scope + four new features) | 36.0 | 33.0 |
| Desktop web variants: sidebar shell, hover and focus states across primitives, wide reader side panels, desktop grids | 5.0 | 5.0 |
| Three-target verification (browser + Android + iPhone per cluster) | 2.0 | 2.0 |
| Android glass material (`expo-blur` + Skia rim/specular), iOS `GlassContainer` morph groups and `@expo/ui` controls | – | 3.0 |
| **Per skin** | **43.0** | **43.0** |

### 4.3 Totals

| | Expo universal | Keep (`stack-keep.md`) |
|---|---:|---:|
| Parity + foundation + engines | 37.0 | 22 (foundations + engines, no parity) |
| Cinematic UI | 43.0 | 72.5 (web 36.5 + Flutter 36.0) |
| Glass UI | 43.0 | 66.4 |
| Backend for new features | 8.0 | 8.0 |
| **Total** | **≈131** (≈115–150) | **≈161** |
| **Cinematic complete everywhere** | **≈88** | **≈94.5** |
| Each future screen | built **2×** | built **4×** |

The first milestone is a wash. The saving is ≈30 CCD by the end of Glass, and after that roughly half the UI cost of every feature for the life of the app.

Calendar: keep plans two paired sessions per cluster (web + Flutter) and names owner review as the bottleneck. Under Expo one session builds a cluster once and the owner reviews one implementation on three screens. The bottleneck shrinks with it.

---

## 5. Build pipeline and the SideStore path

### 5.1 iOS: stay on GitHub Actions, not EAS Build

EAS Build's iOS path expects Apple credentials; there is no supported "unsigned IPA for sideload" profile, and `eas build --local` needs a Mac. So the IPA keeps coming from the workflow that already works, with three steps changed in `ios-build.yml`:

```yaml
- uses: actions/setup-node@v4        # node 22, npm cache
- run: npm ci && npx expo prebuild --platform ios --no-install
- run: cd ios && pod install
- run: xcodebuild -workspace ios/ManhwaManiacs.xcworkspace -scheme ManhwaManiacs \
         -configuration Release -sdk iphoneos -destination 'generic/platform=iOS' \
         CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO -derivedDataPath build
# then the existing "Payload/ + zip" packaging, release asset, and mm-fetch-ios / source.json publishing, unchanged
```

- Bundle id stays `com.manhwamaniacs.reader`, so SideStore treats the Expo IPA as an update of the installed app.
- The build number keeps its `1000 + run_number` scheme: `app.config.ts` reads `process.env.BUILD_NUMBER` into `ios.buildNumber` and `android.versionCode`.
- `codemagic.yaml` has a React Native workflow type; the same four script lines replace `flutter build ios`. It stays the backup builder, as today.
- `tests.yml` swaps the Flutter job for `tsc --noEmit`, `vitest run` (core + web) and `jest-expo` for the native-only modules.

### 5.2 Android

`npx expo prebuild --platform android` + `./gradlew assembleRelease` on `ubuntu-latest` (no Mac needed). A 30-line config plugin injects the signing block that `android/app/build.gradle.kts` has today, reading the same `key.properties` / keystore from CI secrets. **The APK must be signed with the existing keystore**, or Android refuses it as an update. `/app/download` serves it exactly as now.

### 5.3 Over-the-air JS updates

`expo-updates` with `runtimeVersion: { policy: "fingerprint" }`. Two ways to host it:

- **EAS Update** (free tier covers far more than 3 users). It works with builds not made by EAS: `eas update --branch production` runs in CI after the tests pass.
- **Self-hosted** on the FastAPI backend, which already serves `/app/*`: the expo-updates protocol is an open manifest + asset format that `expo export` produces. About 1 CCD more, and nothing leaves the VPS.

Effect: a JS-only fix reaches all three platforms from one commit. The fingerprint changes only when native code changes, and only then does CI build a new IPA and APK. This also makes "web + Android + iOS always release together" structural: one bundle, one version in `package.json`.

SideStore's 7-day re-sign with a free Apple ID is unchanged by any of this.

---

## 6. Rewrite risks and how each is contained

### 6.1 On-device downloads and the sqflite data

- **Schema is kept, not redesigned.** The six tables in `downloads_db.dart` are recreated with the same DDL in `expo-sqlite`, and the blob layout (content-addressed by sha256, `expo-crypto`) is kept.
- **Installed data.** On first launch the Expo app looks for the sqflite database where sqflite put it (Android `/data/data/com.manhwamaniacs.reader/databases/`; the iOS app-container path sqflite uses) and opens it in place through `expo-sqlite`'s directory option, then re-points blob paths. If the spike shows that is fragile, the fallback is honest and cheap for 2–3 users: the progress and bookmark outboxes are flushed by the last Flutter release, and downloads are re-fetched.
- **iOS background.** Downloads run in the foreground on iOS today (`capabilities.md` §24); same under Expo. No regression, no new promise.
- The 25 Flutter download test files are the specification for the ported store; they are ported first, against `better-sqlite3` behind the same store interface in Node (the role `sqflite_common_ffi` plays today).

### 6.2 OCR

The recognisers stay native. The Kotlin ML Kit code in `OcrChannel.kt` (217 lines) and the Vision code in `AppDelegate.swift` move into `modules/mm-native` as Expo module functions (`AsyncFunction("recognize") { path: String -> … }`). The code inside is copied; only the channel plumbing changes. The upload payload (`POST /ocr/chapter`, pages with boxes) is already typed in `features/ocr`. `@react-native-ml-kit/text-recognition` 2.0.0 exists as a fallback, but reusing our own tuned code is less risk.

### 6.3 TTS

Narration is synthesised on the server (31 voices, `GET /novels/audio`); the client plays audio and follows `segments` timings. The follow-along highlight logic is already TS (web listen mode). The native side is `expo-audio` with a header-carrying source, so it keeps what the `pubspec.yaml` comment values: seeks pull only the Range they need. This is the smallest port on the list.

### 6.4 The 2,012 Flutter tests

- 76 widget-test files (24,089 lines) die under **every** option, keep included (keep R7).
- Of the 136 logic files, most test API/state logic whose TS twin already has vitest coverage among the 2,304 web cases. About 40 are mobile-only (downloads, outboxes, OCR payload, reader constants) and are ported as a spec first.
- What is genuinely lost is the Dart-level coverage of engine timing (restore loop, extent compensation). It is replaced by device-verified behaviour plus unit tests on the pure strip math, and it is named as risk in §10.2.

### 6.5 The reader engine

See §3.4. Mitigation: the reader is the *first* native cluster after the spike, both entry points together (library `ReaderScreen` and source `SourceReaderScreen`, per the two-entry-points rule), benchmarked on a 120-page webtoon chapter at 2,880 px against the Flutter build on the same phone before any skin work starts.

### 6.6 Dev-box load

Metro in dev mode uses roughly 1–1.5 GB. On the VPS, run it only with the `free -m` watchdog, never beside `next build` or `flutter test`. Release bundling (`expo export`, prebuild, Gradle, Xcode) runs in CI only. `expo export --platform web` before push replaces "`next build` before push".

---

## 7. Expo web versus Next.js: the quality gaps, honestly

| Area | Next 16 today | Expo web (react-native-web 0.21.3) | Gap |
|---|---|---|---|
| Per-skin code splitting | RSC ships only the rendered skin, zero config | Per-skin lazy bundles (`React.lazy` per skin root); the inactive skin is never fetched, but it is client-side splitting, not server | Small |
| First paint without skin flash | Server reads `mm-skin` cookie | Static export + boot script stamps `data-skin` from localStorage before hydration, as `appearance-boot-source.ts` does today | Small |
| Route / shared-element transitions | React `<ViewTransition>` integrated with the router | Manual `document.startViewTransition` in a web navigation hook; same CSS `::view-transition-*` per skin | Medium: our code, not the framework's |
| Text | DOM | **DOM too**: RNW renders `<div>`/`<span>`, so selection, find-in-page, browser zoom and screen readers keep working (unlike Flutter web, keep option C) | None |
| Keyboard-first desktop | `lib/keyboard` registry, 34 bindings, `mod+k` palette | Same modules, now under `src/web/` | None |
| Offline downloads | `sw.js` + Cache Storage | Same `sw.js`, served from `public/` | None |
| Styling power | Tailwind 4 with full CSS: `backdrop-filter`, `mask-image`, container queries, `linear()` springs | NativeWind 4 (Tailwind 3 semantics; 5.0 rc targets Tailwind 4). Web-only CSS goes in `.web.tsx` files or CSS modules, which Expo web imports | **Medium**: Cinematic's scrims, masks and grain lean on CSS that RN styles cannot express |
| Hover | Native `:hover` | NativeWind `hover:` and Pressable `hovered` state | Small |
| Bundle | Next + React + Motion | + react-native-web and Reanimated web: roughly +150–250 KB gzip | Small for 2–3 users, cached by the SW |
| SEO, server routes, ISR | Available | Not needed: the app is private | None in practice |

The web target is good enough for a private desktop client with a keyboard registry and a DOM-text novel reader. It is not as good as Next at CSS-heavy cinematic effects, and every `.web.tsx` escape hatch eats into "one implementation". That is §10.3.

---

## 8. Migration plan and release-together

1. **Spike, 3 CCD, before anything is committed to.** An `expo-dev-client` build installed next to the current app under a second bundle id (`com.manhwamaniacs.reader.next`, so SideStore keeps both). Pass/fail gates:
   - Webtoon strip: 120 pages at 2,880 px, no blank page over 1 frame at 120 Hz on the iPhone and the Android flagship, peak memory within the Flutter build's +15 %.
   - `GlassContainer` morph + native tabs + form sheet on the iPhone; `expo-blur` + Skia rim on Android at 120 Hz.
   - The unsigned IPA from `ios-build.yml` installs and updates through SideStore; an OTA update lands.
   - The existing sqflite database opens in place.
   - Expo web static export: the Cinematic hero, one rail and the keyboard registry, served behind Caddy with the cookie session.
   If the strip or the IPA path fails, stop: keep wins and the spike cost 3 days.
   If only the web gate fails, fall back to **Expo for the phones + Next for the web, both importing `packages/core`**. That is still four UIs (keep's option A), but one language and one data layer; decide knowing that.
2. **Parity (§4.1) in the new `app/`**, dogfooded under the `.next` bundle id. The Flutter and Next clients keep releasing together, untouched, so every sitting can still commit, push and ship.
3. **Cinematic on all three targets**, cluster by cluster, same order as keep.
4. **Flip**: the release that ships the Expo app under `com.manhwamaniacs.reader` also ships the Expo web build, and deletes `mobile/` and `frontend/` in the same commit series. Web, Android and iOS move together, as the rule requires.
5. **Glass**, built in the same tree, flipped on when its `ScreenId` completeness check passes.

---

## 9. Risk list (Expo position)

| # | Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| X1 | Native reader underperforms the tuned Flutter strip | Medium | High | Spike gate 1; reader is the first cluster; constants carried over from `mobile.md` §6a |
| X2 | Android Glass looks flat next to iOS | High | Medium | Skia rim + specular + `expo-blur`; Glass design treats Android as "frosted glass" in `glass/DESIGN.md`, stated, not hidden |
| X3 | Expo SDK yearly majors / RN New Architecture churn | Medium | Medium | Pin SDK 57; upgrade after Glass ships, like keep's Flutter 3.47 deferral (R6) |
| X4 | NativeWind 4 vs Tailwind 4 mismatch | Medium | Low | Tokens as CSS variables, which both support; move to NativeWind 5 when it leaves rc |
| X5 | Installed downloads lost at the flip | Low | Low | In-place open; outbox flush in the last Flutter release; 2–3 users can re-download |
| X6 | Metro memory on the shared VPS | Medium | High if ignored | Watchdog, one heavy process at a time, release builds in CI |
| X7 | APK signed with a different key | Low | High | Signing plugin reads the existing keystore; spike verifies an in-place upgrade |
| X8 | A native module (`mm-native`) breaks the iOS CI build with no Mac to debug | Medium | Medium | Native changes in isolated commits; the fingerprint shows exactly when native code changed |

---

## 10. The three weakest points of this position

### 10.1 Glass is best on one platform, not all of them

Expo's Glass is the real thing on iOS 26 and an imitation everywhere else: frost, rim and specular on Android, CSS backdrop on the web, refraction only in Chromium. Flutter with `liquid_glass_widgets` puts the same refracting shader on both phones. If Android users matter as much as the owner's iPhone, keep wins this outright, and closing the gap in RN means writing a refraction shader in Skia whose backdrop only sees content drawn in the same Skia canvas, not the native view tree under it. Also, `GlassView` requires iOS 26; an iPhone that has not updated sees a fallback `View`.

### 10.2 The most-tuned code is rewritten, and green tests are traded for a promise

The Flutter reader's numbers transfer, but its behaviour (restore loop, extent compensation, decode budgeting against a real image cache) is re-implemented on FlashList and `expo-image` and re-verified on devices. About 29.5 CCD go to reaching today's features before the first new pixel ships, and 136 Dart logic test files that pass today are replaced by ~40 ported files plus existing web tests. Keep's first milestone is 6 CCD later than Expo's on paper, but keep's early days produce redesign, not parity; if parity slips by 30 %, the Cinematic flip lands later than under keep.

### 10.3 Expo web is a weaker desktop client than Next

The owner asked for a full desktop design: sidebars, hover, keyboard-first, a wide reader with side panels. Next gives RSC per-skin splitting, router-integrated `<ViewTransition>`, and Tailwind 4 with all of CSS. Expo web gives client-side splitting, a hand-wired view-transition hook, and NativeWind on a styling model that cannot express the scrims, masks and blur-heavy Cinematic surfaces without `.web.tsx` files. Each escape hatch is a second implementation of that component, so the true figure is "one implementation per skin, plus a web-only layer", and if that layer grows past ~20 % of a skin's UI the arithmetic in §4 drifts back toward keep's.

---

## 11. Sources

- App source (read-only): `/srv/manhwamaniacs/dev/ManhwaManiacs` at `130d6fd`. Measured: `frontend/src/{features,lib,services,stores,types,config}/**/*.ts`, `frontend/public/sw.js`, `frontend/package.json`, `mobile/pubspec.yaml`, `mobile/lib/**`, `mobile/test/**`, `mobile/lib/features/downloads/store/downloads_db.dart`, `mobile/android/app/build.gradle.kts`, `mobile/android/app/src/main/kotlin/com/manhwamaniacs/reader/{MainActivity,OcrChannel}.kt`, `mobile/ios/Runner/{AppDelegate.swift,Info.plist}`, `.github/workflows/{tests,ios-build}.yml`, `codemagic.yaml`.
- Design inputs: `inventory/00-decisions.md`, `inventory/capabilities.md` §19–20, §24, `inventory/mobile.md` §6a, `research/glass-language.md`, `research/gestures-nav.md`, `research/cinematic-language.md`, `research/web-motion-libs.md`, `research/discovery-ux.md` §10, `stack-keep.md`.
- npm registry, 2026-09-28: `expo` 57.0.25, `react-native` 0.87.1, `expo-router` 57.0.23, `nativewind` 4.2.7 (5.0.0-rc.0), `react-native-css` 3.0.7, `react-native-reanimated` 4.7.0, `react-native-worklets` 0.13.0, `react-native-gesture-handler` 3.3.0, `react-native-screens` 4.28.0, `expo-glass-effect` 57.0.4, `@callstack/liquid-glass` 0.8.2, `@expo/ui` 57.0.20, `expo-blur` 57.0.3, `expo-haptics` 57.0.3, `expo-audio` 57.0.5, `expo-image` 57.0.5, `expo-sqlite` 57.0.3, `expo-file-system` 57.0.7, `expo-crypto` 57.0.3, `expo-secure-store` 57.0.4, `expo-sharing` 57.0.22, `expo-keep-awake` 57.0.2, `expo-screen-orientation` 57.0.2, `expo-dev-client` 57.0.19, `expo-build-properties` 57.0.22, `@shopify/flash-list` 2.3.2, `@shopify/react-native-skia` 2.13.0, `@gorhom/bottom-sheet` 5.2.14, `react-native-mmkv` 4.3.2, `react-native-view-shot` 6.0.1, `react-native-web` 0.21.3, `@react-native-ml-kit/text-recognition` 2.0.0, `@tanstack/react-query` 5.104.0, `zustand` 5.0.15.
- Expo docs: GlassEffect https://docs.expo.dev/versions/latest/sdk/glass-effect/ · Haptics https://docs.expo.dev/versions/latest/sdk/haptics/ · Native tabs https://docs.expo.dev/router/advanced/native-tabs/ · Modules API https://docs.expo.dev/modules/overview/ · Updates https://docs.expo.dev/versions/latest/sdk/updates/ · Custom updates server https://github.com/expo/custom-expo-updates-server
- To verify in the spike rather than trusted from docs: native-tab minimise behaviour and bottom accessory on iOS 26, `expo-sqlite` opening a database outside its default directory, in-app predictive-back animation on Android 14+, EAS Update with a non-EAS unsigned build.
