# Cinematic DESIGN.md: stack-feasibility audit

Lens: every package exists at the stated version and resolves against `frontend/package.json` (Next 16.2.9, React 19.2.4, Tailwind 4) and `mobile/pubspec.yaml` on Flutter 3.44.6 (Dart 3.12.2); every effect is implementable at 60/120 fps in Safari, Chrome and on flagship phones; folder layout, skin engine, token pipeline and restart flow match `stack-decision.md`; every backend endpoint either exists in `inventory/capabilities.md` or is marked new with its request and response shape.

How it was checked (2026-09-28): npm registry metadata for every web package; pub.dev metadata and archives for every Flutter package; a `flutter pub get --dry-run` in a scratch copy of `mobile/pubspec.yaml` with every ledger package added (metadata only, nothing built); the local Flutter 3.44.6 SDK source; `frontend/node_modules` (next 16.2.9, motion-dom 12.42.2) plus the motion-dom 13.4.4 and framer-motion 13.4.4 tarballs; the backend routes. Every "missing" claim below was grepped across the whole of DESIGN.md first.

Result: 39 findings, of which 4 high, 20 medium, 15 low. Two ledger packages do not resolve on this stack at the stated versions; both have a verified drop-in version.

---

## STACK-1 · high · §15.11, §15.3, §9.2.5, §8.0.5: `share_plus` 13.3.0 cannot resolve against the existing pubspec

**Problem.** `share_plus` 13.x requires `win32 ^6`, and three packages already in `mobile/pubspec.yaml` pin `win32` to 5.x, so `flutter pub get` fails. The ledger's fallback ("Save to the app's documents folder with a toast") would drop the image export the owner asked for (`00-decisions.md`: "shareable stat cards (image export)").

**Evidence.**
- DESIGN §15.11: "| `share_plus` | 13.3.0 | BSD-3-Clause | native | Share cards (§9.2.5) | added here | Save to the app's documents folder with a toast |".
- pub.dev: `share_plus` 13.3.0 depends on `win32: ^6.0.1`. `package_info_plus` 8.x (pubspec `^8.0.0`) depends on `win32 ^5.5.3`. `file_picker` 8.3.7 (pubspec `^8.1.2`) depends on `win32 ^5.9.0`. `flutter_secure_storage_windows` 3.1.2 (via pubspec `flutter_secure_storage: ^9.0.0`) depends on `win32 ^5.0.0`. The lockfile has `win32 5.15.0`.
- `flutter pub get --dry-run` with the ledger added: "Because package_info_plus >=8.0.3 <10.0.0 depends on win32 ^5.5.3 … share_plus >=13.1.0 depends on win32 ^6.0.1 … version solving failed. … Consider downgrading your constraint on share_plus: flutter pub add share_plus:^12.0.2".

**Fix.** Pin `share_plus: 12.0.2` (published 2026-03-30; `win32 ^5.5.3`; Flutter ≥ 3.22). It has the same API DESIGN uses: `SharePlus.instance.share(ShareParams(files: [XFile.fromData(bytes, mimeType: 'image/png', name: 'manhwamaniacs-{template}-{format}.png')]))`. The dry run resolves cleanly with 12.0.2 plus every other ledger package (with STACK-2 applied). Replace 13.3.0 with 12.0.2 in §8.0.5, §9.2.5, §15.3 and §15.11. Move to 13.x only when `package_info_plus`, `file_picker` and `flutter_secure_storage` move to their win32-6 majors.

## STACK-2 · high · §15.11, §15.3, §6, §8.16.5: `flutter_soloud` 5.1.4 cannot resolve on Flutter 3.44.6, and the API DESIGN calls was removed in 5.0

**Problem.** Every `flutter_soloud` 5.x version depends on `native_toolchain_c ^0.19.4`, which needs `meta ^1.19.0`, but the Flutter SDK pins `meta` 1.18.0. Version 5.0.0 also removed the `AudioData` class that §8.16.5 uses. Separately, SoLoud has no AAC decoder, so a voice sample fetched as `m4a` (the format capabilities §19.3 requires for iOS narration) cannot be decoded.

**Evidence.**
- DESIGN §15.11: "`flutter_soloud` | 5.1.4 | MIT | native (C++ FFI) | UI sounds and voice-sample RMS". §8.16.5: "`SoLoud.instance.setVisualizationEnabled(true)`, RMS computed each `Ticker` frame from `AudioData(GetSamplesKind.wave)` (256 samples)".
- Dry run: "Because every version of flutter from sdk depends on meta 1.18.0 and native_toolchain_c >=0.19.3 depends on meta ^1.19.0 … flutter_soloud >=5.0.0-pre.2 depends on native_toolchain_c ^0.19.4 … version solving failed."
- flutter_soloud 5.0.0 CHANGELOG: "breaking change: audio visualization overhaul: Replaced the legacy `AudioData` polling class with a reactive stream: `SoLoud.instance.audioVisualizationEvents`".
- flutter_soloud README: "Support for MP3, WAV, OGG, and FLAC". There is no AAC or m4a decoder.

**Fix.** Pin `flutter_soloud: 4.1.7` (published 2026-08-08; Flutter ≥ 3.41; no build-hook dependencies; ships a podspec). Its API matches what DESIGN already writes: `AudioData(GetSamplesKind.wave)` with `updateSamples()` and `getAudioData()`, `setVisualizationEnabled(bool)`, and `loadMem(String path, Uint8List bytes)`. The dry run resolves with 4.1.7. In §8.16.5, add: "the app always requests `GET /novels/voices/sample?voice={id}&format=ogg`, on iOS as well, because SoLoud decodes Ogg itself and cannot decode m4a." Revisit 5.x only with the Flutter upgrade (stack risk 10).

## STACK-3 · high · §15.2, §3.1: `next/font/google` calls without `subsets` fail `next build`

**Problem.** In Next 16.2.9, a Google font with `preload` left at its default (`true`) and no `subsets` raises a build error. §15.2 writes Archivo, Newsreader and IBM Plex Mono that way, and §3.1 also writes Bodoni Moda without `subsets`. The two sections disagree with each other as well: §15.2's Bodoni call has `subsets`, §3.1's does not.

**Evidence.**
- DESIGN §15.2: "`Archivo({ axes: ["wdth"], display: "swap", variable: "--mm-font-grotesk" })`, `Newsreader({ axes: ["opsz"], style: ["normal","italic"], display: "swap", variable: "--mm-font-text" })`, `IBM_Plex_Mono({ weight: ["400","500","600"], display: "swap", variable: "--mm-font-folio" })`". §3.1: "`Bodoni_Moda({ axes: ["opsz"], style: ["normal","italic"], display: "block", preload: true, variable: "--mm-font-display" })`".
- `next/dist/compiled/@next/font/dist/google/validate-google-font-function-call.js` lines 12 and 28–29: `preload = true` by default, and `if (!subsets) { nextFontError("Preload is enabled but no subsets were specified for font …") }`.

**Fix.** Add `subsets: ["latin", "latin-ext"]` to `Bodoni_Moda`, `Archivo`, `Newsreader` and `IBM_Plex_Mono`. `font-data.json` confirms both subsets exist for all four. Make §3.1's calls identical to §15.2's. The three reading faces (`preload: false`) and the Noto fallbacks (`preload: false`) are fine as written.

## STACK-4 · high · §8.30.3, §8.30.1 (restart flow vs stack §2.4, §2.5): the skin switch does not wait for the profile `PATCH`, so the boot check can switch it back

**Problem.** Stop the press sends `PATCH /profiles/{id} {skin}` at t = 0 and restarts at t = 500 without waiting for the response.
- **Web.** `location.replace` unloads the document, which aborts a fetch that is still in flight. On a slow link the new skin is never stored.
- **Mobile.** The PATCH goes through the offline outbox, and §8.30.1 explicitly allows switching offline. After the restart, the first `GET /profiles` can return the old `skin` before the outbox flushes.

In both cases the boot resolution (stack §2.4 steps 2–4: "compare `profile.skin ?? default` with the mirror … If they differ, write the mirror … and restart") sees a mismatch and restarts back into the old edition, silently undoing the user's choice.

**Evidence.**
- §8.30.3: "| 0 | The profile `PATCH` is sent; the cookie / SharedPreferences mirror, the return route and the start timestamp … are written |" and "| 500 | Restart: web `location.replace(returnPath)` …; Flutter `AppRestart.restart()` |".
- §8.30.1: "On mobile, the one change that goes through the offline outbox (the profile's `skin` `PATCH` …) stays enabled offline".
- Neither DESIGN nor the stack says the PATCH is awaited. `keepalive` appears 0 times in DESIGN.

**Fix.**
- **Web.** At t = 0, send `fetch("/api/profiles/{id}", { method: "PATCH", keepalive: true, headers, body: JSON.stringify({ skin }) })`. At t = 500, wait for it (at most 1,000 ms more, inside the 1.5 s budget) before posting `skin-changed` and calling `location.replace`. If it fails or times out, cancel the switch: reverse the blades (200 ms), show the toast "Couldn't switch editions. Try again.", and leave the mirror unchanged. The web Edition control is disabled offline, like the other server-backed rows.
- **Mobile.** In boot resolution step 2, a queued outbox `PATCH /profiles/{id}` carrying `skin` wins over the server payload: skip the mismatch restart while it is queued, and flush the outbox before comparing.
- Record both rules in §8.30.3 and as a §15.10 row.

## STACK-5 · medium · §2.8.4, §4.4, §15.1: the same spring token is about 20 % faster on Flutter than in Motion

**Problem.** Motion turns `visualDuration` into stiffness using a 1.2 factor that Flutter's `withDurationAndBounce` does not use. The same `{ms, bounce}` token therefore produces a stiffer spring on Flutter. That breaks §2.8's claim of "identical values" and stack risk 1 ("the same skin feels different on web and phone").

**Evidence.**
- DESIGN §2.8.4: "`{ type: "spring", visualDuration: 0.42, bounce: 0 }` / `springRelease` = `SpringToken(ms: 420, bounce: 0)` → `SpringDescription.withDurationAndBounce(duration: Duration(milliseconds: 420), bounce: 0)`".
- motion-dom 12.42.2 and 13.4.4, `getSpringOptions`: `const root = (2 * Math.PI) / (visualDuration * 1.2); const stiffness = root * root;`.
- Flutter 3.44.6 `spring_simulation.dart` line 77: `stiffness = (4 * math.pi * math.pi * mass) / math.pow(durationInSeconds, 2)`.
- Time to 95 % of travel:

| Token | Motion | Flutter |
|---|---|---|
| `spring.release` (420 ms) | 381 ms | 318 ms |
| `spring.sheet` (480 ms) | 435 ms | 363 ms |
| `spring.scrub` (240 ms) | 218 ms | 182 ms |

**Fix.** The generator maps `{ms, bounce}` to `SpringDescription.withDurationAndBounce(duration: Duration(milliseconds: (ms * 1.2).round()), bounce: bounce)`. That gives release 504 ms, sheet 576 ms and scrub 288 ms. Stiffness then matches Motion exactly, and damping matches for 0 ≤ bounce < 0.95. State the rule in §2.8 and §15.1, and add a §15.10 row that corrects the mapping line in stack §2.1.

## STACK-6 · medium · §2.8.4, §15.1 (token pipeline vs stack §2.1): the CSS spring duration is wrong, and `build.mjs` cannot import `motion`

**Problem.**
1. Motion's `spring(d, b).toString()` samples the curve over the spring's full settle time, which is much longer than the visual duration. DESIGN pairs that `linear()` curve with the visual duration (420 ms), so the CSS spring runs about 1.9× faster than both the Motion JS spring and the Flutter spring.
2. Stack §2.1 defines `design/build.mjs` as "Node 22 stdlib only". Pre-sampling "from `motion` at build time" needs a dependency that `design/` does not have. The frontend Docker build context is `./frontend`, so `design/` cannot reach it there either.

**Evidence.**
- DESIGN §2.8.4: "`--mm-spring-release: linear(…)` pre-sampled by `spring(0.42, 0)` from `motion` at build time, plus `--mm-spring-release-ms: 420ms`".
- `node -e "require('motion-dom').spring(0.42,0).toString()"` (motion-dom 12.42.2): "800ms linear(0, 0.0572, 0.1795, 0.3195, …". `spring(0.48,0)` gives "850ms …" and `spring(0.24,0)` gives "500ms …".
- Stack §2.1: "`build.mjs` ~150 lines, Node 22 stdlib only".

**Fix.**
- `build.mjs` implements the spring itself, in about 25 lines:
  - Critically damped: x(t) = 1 − (1 + ωt)·e^(−ωt), with ω = 2π / (1.2 · s).
  - Underdamped: the standard branch (needed for Glass).
- Integrate in 50 ms steps until |1 − x| ≤ 0.005 and |v| ≤ 0.01. These are Motion's "granular" rest thresholds.
- Emit a `linear()` string with at least 30 points, and set `--mm-spring-*-ms` to that settle time: release 800 ms, sheet 850 ms, scrub 500 ms for the current tokens.
- Add a Vitest case in `frontend/` asserting that the emitted string equals `spring(d, b).toString()` from the installed `motion`.

## STACK-7 · medium · §7.9, §15.3: the Flutter widgets named for sheets cannot produce the sheet behaviour the spec requires

**Problem.** `showModalBottomSheet` with `DraggableScrollableSheet(snap: true)` has no spring release, no rubber band past the top detent, and fixed dismissal thresholds different from the spec's. §15.3 also rules out the pinned sheet package the stack already approved.

**Evidence.**
- DESIGN §15.3: "`CineSheet` over `showModalBottomSheet` + `DraggableScrollableSheet(snap: true, snapSizes: [0.5, 0.92])`" and "Cinematic uses the built-in Hero, SpringSimulation and sheets; it does not use … `smooth_sheets`".
- §7.9: "Settles to the nearest detent with `spring.sheet`; dismisses when dragged below 30 % of its height or flung down faster than 800 px/s" and "past the top detent rubber-bands with c = 0.35".
- Flutter 3.44.6:
  - `draggable_scrollable_sheet.dart` line 1128: `_SnappingSimulation` moves at a constant `velocity` (not a spring), and the sheet clamps at `maxChildSize` (no overscroll).
  - `bottom_sheet.dart` lines 30–31: `const double _kMinFlingVelocity = 700.0; const double _kCloseProgressThreshold = 0.5;`. These are private and cannot be configured.

**Fix.** Either option works:
- **Custom route.** `CineSheetRoute<T> extends PopupRoute<T>` with its own `VerticalDragGestureRecognizer` driving a pixel-offset `AnimationController`:
  - Detents at content height or [0.5, 0.92] of the screen.
  - Release: `controller.animateWith(SpringSimulation(CineSprings.sheet, offset, target, velocity))`.
  - Dismiss when the offset exceeds 0.3 × height, or on a downward fling faster than 800 px/s.
  - Rubber band above the top detent: `d · (1 − 1 / (x · 0.35 / d + 1))`.
- **Pinned package.** Allow `smooth_sheets` 1.2.0 (already in stack §3's pinned list) for `CineSheet` and remove it from §15.3's "does not use" list.

## STACK-8 · medium · §8.0.3, §12.3: `/` (Tonight) is unreachable because of the 307 redirect already in `next.config.ts`

**Problem.** The route contract puts `tonight` at `/`, but `next.config.ts` answers `/` with a 307 to `/library` before any React runs. DESIGN never says to remove the redirect.

**Evidence.**
- DESIGN §8.0.3: "| `tonight` | `/` | Home |". §12.3: "`start_url` "/" (Tonight; it was `/library` before this redesign, web R0)".
- `frontend/next.config.ts`: `async redirects() { return [{ source: "/", destination: "/library", permanent: false }]; }` ("This answers 307 before any React runs").
- `inventory/web.md` R0: "307 redirect to `/library` (next.config)".
- In DESIGN, "next.config" occurs 0 times and "redirects()" 0 times.

**Fix.**
- In the cluster that ships Tonight, delete the `redirects()` entry.
- Add a thin `frontend/src/app/page.tsx` that renders `skins[await getSkin()].screens.tonight`.
- The `legacy` skin's map is `Partial` and has no `tonight`, so while legacy is the default, the route file falls back to `redirect("/library")`.
- Say this in §8.0.3.

## STACK-9 · medium · §8.0.4, §15.2: View Transitions are not enabled, `transitionTypes` is on the wrong component, and the match-cut name is not a valid CSS identifier

**Problem.**
1. Next 16 runs route-navigation view transitions only when `experimental.viewTransition: true` is set. DESIGN never sets it.
2. `transitionTypes` is a prop of `<Link>` (and an option of `router.push`), not of `<ViewTransition>`.
3. `view-transition-name: cover-<sourceId>-<seriesKey>` is built from raw series keys. These can contain `/` and `%`, which makes the name an invalid `<custom-ident>`. Browsers drop invalid names, so the match cut silently never plays.

**Evidence.**
- DESIGN §8.0.4: "React `<ViewTransition>` with `transitionTypes={['nav-forward' | 'nav-back']}` and `default: "none"` … `view-transition-name: cover-<sourceId>-<seriesKey>`". The string "viewTransition" occurs 0 times in DESIGN.
- `next/dist/docs/…/next-config-js/viewTransition.md`: "To enable this feature, you need to set the `viewTransition` property to `true` … The `experimental.viewTransition` flag enables Next.js integration, such as triggering transitions during route navigations."
- `next/dist/client/link.d.ts` line 102: `transitionTypes?: string[]` on `LinkProps`, passed to `React.addTransitionType`.
- capabilities §1: "Keys are opaque strings that may contain `/` and `%`".

**Fix.**
- `next.config.ts`: `experimental: { proxyTimeout: 120_000, viewTransition: true }`.
- Navigation: `<Link transitionTypes={["nav-forward"]}>` and `router.push(href, { transitionTypes: ["nav-back"] })`.
- Page wrapper: `<ViewTransition default="none" enter={{ "nav-forward": "mm-page-in", "nav-back": "mm-page-back-in" }} exit={{ "nav-forward": "mm-page-out", "nav-back": "mm-page-back-out" }}>`.
- Shared cover: `<ViewTransition name={`cover-${sourceId}-${fnv1a32(seriesKey)}`} share="mm-match-cut">`, where the key is hashed with FNV-1a 32-bit to 8 hex digits.

## STACK-10 · medium · §6, §9.4.2, §8.16.10, §14.9: the iOS audio session is specified three contradictory ways

**Problem.** An iOS app has exactly one `AVAudioSession`, but DESIGN specifies three different categories for it:
- UI cues: `.ambient`.
- Soundscape: "the same `audio_session` (ambient category)".
- Narration: "category stays speech", with the soundscape ducking to 30 % under it at the same time.

On top of that, the app already sets the session to speech at startup, and `flutter_soloud` never sets a category itself. As written, cues and soundscapes ignore the silent switch and duck the user's music, which contradicts §6 and §14.9.

**Evidence.**
- §6: "iOS uses the `.ambient` session category so the ring/silent switch mutes cues".
- §9.4.2: "a second `just_audio` player … under the same `audio_session` (ambient category on iOS …; it never ducks the user's music …)".
- §8.16.10: "the `audio_session` category stays speech".
- `mobile/lib/features/novels/utils/novel_audio_session.dart`: `const AudioSessionConfiguration novelAudioSessionConfiguration = AudioSessionConfiguration.speech();`, applied from `main.dart` line 53.
- flutter_soloud 4.1.7 and 5.1.4, `soloud_miniaudio.cpp`: `contextConfig.coreaudio.sessionCategory = ma_ios_session_category_none;` (the plugin leaves the category to the app).

**Fix.** Put one session controller in the shared layer (`features/novels/utils/audio_session_controller.dart`):
- When nothing, UI cues only, or a soundscape alone is playing: `AudioSessionConfiguration(avAudioSessionCategory: AVAudioSessionCategory.ambient, avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers)`.
- When narration starts: `AudioSessionConfiguration.speech()` (playback, spokenAudio). The soundscape ducks to 30 % through its own gain.
- When narration stops: back to ambient.
- Remove the unconditional startup `configureNovelAudioSession()` call.
- State this once in §6 and reference it from §9.4.2 and §8.16.10.

## STACK-11 · medium · §8.16.10, §15.3 (vs stack §3 "native channels … kept in place" and §2.5): `audio_service` needs native changes and a single init that DESIGN does not specify

**Problem.**
- On Android, `audio_service` needs the activity to extend `AudioServiceActivity` (or reimplement its engine-caching hooks) and needs manifest service and receiver entries. Today `MainActivity` extends `FlutterActivity`.
- `AudioService.init` may run only once per engine. Every skin switch restarts the widget tree in the same engine and disposes all providers, so an init that lives in a provider or a skin runs a second time.

**Evidence.**
- `MainActivity.kt` line 33: `class MainActivity : FlutterActivity()`.
- audio_service README: "class MainActivity extends AudioServiceActivity", plus the `<service>` and `MediaButtonReceiver` manifest entries.
- `audio_service.dart` `AudioService.init`: `assert(_cacheManager == null)`.
- stack §2.5 step 4: "`AppRestart.of(context).restart()` swaps the `UniqueKey`, which disposes every provider".
- iOS is already covered: `ios/Runner/Info.plist` lines 78–81 have `UIBackgroundModes: audio`.

**Fix.**
- Change `MainActivity` to extend `com.ryanheise.audioservice.AudioServiceActivity`. The `OcrChannel` override of `configureFlutterEngine` is kept.
- In the manifest, add `<service android:name="com.ryanheise.audioservice.AudioService" android:foregroundServiceType="mediaPlayback" android:exported="true">`, the `com.ryanheise.audioservice.MediaButtonReceiver`, and the `FOREGROUND_SERVICE` and `FOREGROUND_SERVICE_MEDIA_PLAYBACK` permissions.
- Call `AudioService.init(...)` once in `main()`, before `runApp(AppRestart(...))`, and pass the handler into the tree through a `ProviderScope` override.
- Record this as a §15.10 row, since it changes a file the stack keeps "in place".

## STACK-12 · medium · §8.30.3 (vs stack §2.3, §2.5 step 5): `AppRestart` as written restarts into the old skin

**Problem.** The stack's `main.dart` builds `AppRestart(child: ProviderScope(overrides: [skinIdProvider.overrideWithValue(id)], …))` and says "`main`'s logic runs again, reads the new SkinId". Swapping a `UniqueKey` does not re-run `main()`. It remounts the same `child` instance, whose override still holds the old id, and the return route never reaches `initialLocation`. DESIGN only says "Flutter `AppRestart.restart()`" and does not close the gap.

**Evidence.**
- Stack §2.3: "main.dart reads SkinId from SharedPreferences, runApp(AppRestart(child: ProviderScope(overrides: [skinIdProvider.overrideWithValue(id)], child: SkinApp())))". Stack §2.5: "`main`'s logic runs again".
- DESIGN §8.30.3: "Flutter `AppRestart.restart()`". "initialLocation" occurs 0 times in DESIGN.

**Fix.** Give `AppRestart` a loader instead of a fixed child: `AppRestart(load: SkinBoot.read, builder: (boot) => ProviderScope(overrides: [skinIdProvider.overrideWithValue(boot.skin), returnRouteProvider.overrideWithValue(boot.returnRoute)], child: const SkinApp()))`. `restart()` re-runs `SkinBoot.read()`, which reads `mm.skin.active` and `mm.skin.return` from SharedPreferences and then clears `mm.skin.return`, and rebuilds under a new `UniqueKey`. The skin's `buildRouter` passes `initialLocation: ref.read(returnRouteProvider) ?? Routes.tonight`. Specify this in §15.3.

## STACK-13 · medium · §2.1.5, §9.4.4, §15.4: the two clients sample page tint from different inputs, so "identical results" cannot hold

**Problem.**
- **Different inputs.** The web picks the seed from 256 pixels (a 16 × 16 downscale); Flutter picks it from 64 × h near-raw pixels. The picker takes the single most saturated pixel, so different inputs give different seeds for the same page. `tint-vectors.json` only tests the picker on fixed 16 × 16 input, never the downscale.
- **Shared cache.** `POST /reader/page-tints` fills `pages[].tint` "for any profile", so the server cache ends up depending on which client read the chapter first.
- **Aliasing.** `drawImage(bitmap, 0, 0, 16, 16)` with default smoothing samples only a handful of source pixels.
- **Memory.** `createImageBitmap(img)` on an 800 × 12,000 strip page allocates about 38 MB on every sample.
- **Two sampling rules.** §2.1.5 samples the page "under the reading line"; §9.4.4 samples "the page occupying ≥ 50 % of the viewport". On webtoon strips with short pages, the second rule can match no page at all.

**Evidence.**
- §2.1.5: "draws it into a 16 × 16 `OffscreenCanvas` (`drawImage(bitmap, 0, 0, 16, 16)`; the engine makes the bitmap with `createImageBitmap(img)` …)", "Flutter … `ResizeImage(provider, width: 64)`", "each of the 256 (web) or 64 × h (Flutter) pixels", "must return identical results", and "When the page under the reading line changes".
- §9.4.4: "Sampling: the page occupying ≥ 50 % of the viewport".

**Fix.**
- Both clients reduce the page to the same 16 × 16 grid before picking:
  - Web: `createImageBitmap(img, { resizeWidth: 16, resizeHeight: 16, resizeQuality: "high" })`, transferred to the worker. Where `resizeWidth` is unsupported, box-downsample in the worker (256 → 64 → 16) with `imageSmoothingQuality = "high"`.
  - Flutter: `ResizeImage(provider, width: 16, height: 16, policy: ResizeImagePolicy.exact)`.
- The picker's input is always 256 RGBA pixels.
- Add 8 vectors of real pages already reduced to 16 × 16.
- Use one sampling rule: the page that intersects the reading line (38 % from the top in strip mode; the current page in paged and guided modes). Replace §9.4.4's rule with it.

## STACK-14 · medium · §4.5, §7.7, §15.6: Rack focus puts an animated blur on every cover, against the skin's own blur budget

**Problem.** Rack focus animates a 14 px blur on the first decode of every cover. A desktop Library wall (6–8 per row) or a Discover results page decodes 24–48 covers at once, which means dozens of simultaneous blur animations. On the web those are `filter: blur()` layers; in Flutter each one is an `ImageFiltered` save-layer, re-blurred every frame at 120 Hz. §15.6 allows at most one animated blur layer per screen, so the two sections contradict each other and the 120 Hz device check in §15.8 is at risk.

**Evidence.**
- §4.5: "**Rack focus** | 520 ms | … Image from blur 14 px, brightness 0.6, scale 1.03 → sharp … on first decode | Every cover and page image except inside the reader strip".
- §15.6: "At most one animated blur layer per screen outside letter reveals".

**Fix.**
- Keep Rack focus, with blur, only for the one hero or spread art, the Lightbox image and the dialogue-search stills, one at a time.
- Posters, cuttings, plates and rows get a new blur-free move called "Develop": opacity 0 → 1, brightness 0.6 → 1, scale 1.03 → 1, 520 ms `ease.settle`.
- Update §4.5, §7.7 and the §4.8 reduced-motion row to match.

## STACK-15 · medium · §9.4.2, §8.34, §15.5, §8.16: the backend route named for soundscapes and install-page fonts cannot serve them, and the web audio format is unspecified

**Problem.**
- **Soundscapes.** `/app/media/{name}` matches a single path segment, serves only image suffixes, and reads from the screenshots folder, so `/app/media/soundscapes/{id}.ogg` returns 404.
- **Fonts.** No route serves the install page's self-hosted fonts at all.
- **Web format.** No rule says which format the web requests. "(m4a/AAC on iOS)" covers only the iOS app, and Safari on the web cannot rely on Ogg for the soundscape loop, the `<audio>` voice sample or narration.

**Evidence.**
- §9.4.2: "fetched on first use from the backend's static folder (`/app/media/soundscapes/{id}.{ogg|m4a}`)" and "`backend/media/soundscapes/SOURCES.md`". §15.5: "Soundscape files under `/app/media/soundscapes/`". §8.34: "fonts self-hosted from the backend's static folder (Bodoni Moda, Archivo subsets)".
- `backend/routes/app_distribution.py` line 1985: `@router.get("/app/media/{name}")`, with `safe = Path(name).name` under `SCREENSHOTS_DIR` (`mobile/docs/screenshots`) and `_ALLOWED_MEDIA_SUFFIXES = {".png", ".jpg", ".jpeg", ".webp", ".gif"}`.

**Fix.** Add two new public routes (under `/app/*`) to §15.5:
- `GET /app/media/soundscapes/{file}`
  - Allowed names: `^[a-z-]+\.(ogg|m4a)$`.
  - Folder: `backend/media/soundscapes/`, overridable with `MM_SOUNDSCAPES_DIR`.
  - Content types `audio/ogg` and `audio/mp4`.
  - Range requests (206).
  - `Cache-Control: public, max-age=31536000, immutable`.
- `GET /app/fonts/{file}`: `.woff2` files only, `font/woff2`, the same caching.

On the web, request `ogg` when `new Audio().canPlayType('audio/ogg; codecs="vorbis"')` is non-empty and `m4a` otherwise, for soundscapes, voice samples and narration. The app keeps m4a for narration on iOS and ogg for SoLoud (STACK-2).

## STACK-16 · medium · §9.3.8, §9.3.6, §8.11: the Circle backend lists requests but no responses, and several endpoints the screens need are missing

**Problem.**
- **No response shapes.** `GET /circle/members`, `/circle/feed`, `/circle/reactions` and `/circle/letters` have no response shape, and `DELETE /circle/reactions` has no body.
- **Missing endpoints.**
  - Nothing implements §9.3.6's "`Clear my shared activity`".
  - No endpoint returns the current sharing switches that the settings rows display.
- **Unspecified changes to the existing collection endpoints.** §8.11's shared-shelf permission table ("enforced by the server from the share `mode`") needs:
  - `CAN ADD` members to add through `POST /library/collections/{id}/series`, which is profile-owned today.
  - "Remove … only series they added", which needs an adder id on each member row.
  - A `SHARED WITH YOU` section, which needs shared collections returned by `GET /library/collections`.
  - Leaving a shelf.

**Evidence.** §9.3.8: "`GET /circle/members` (each member carries `now: …`), `GET /circle/feed?cursor`, `POST /circle/reactions {…}` / `DELETE`, `GET /circle/reactions?source&series` (per-chapter counts and who), `POST /circle/letters {…}`, `GET /circle/letters`, …, `PATCH /profiles/{id}/sharing {…switches, excluded_series}`, `POST /library/collections/{id}/share {profile_ids, mode}`, `DELETE /library/collections/{id}/share/{profile_id}`". capabilities §11: collection members are `{source_id, series_key, sort_order}` and profile-scoped.

**Fix.** Write these shapes into §9.3.8:
- `GET /circle/members` → `[{profile_id, name, avatar_key, username, shares: {activity, reactions, shelves, recommendations}, now: {source_id, series_key, chapter_key, chapter_number, title, ambient, since} | null}]`
- `GET /circle/feed?cursor&limit=50` → `{items: [{id, kind: "started"|"finished_chapter"|"finished_series"|"reacted", actor: {profile_id, name, avatar_key, username}, source_id, series_key, title, cover_url, ambient, chapter_key?, chapter_number?, reaction?, created_at}], next_cursor}`
- `GET /circle/reactions?source&series` → `{chapters: [{chapter_key, counts: {loved, shook, laughed, tears, chefs_kiss}, by: [{profile_id, avatar_key, kind}]}]}`
- `DELETE /circle/reactions` with body `{source_id, series_key, chapter_key}` → 204
- `GET /circle/letters` → `[{id, from: {…}, source_id, series_key, title, cover_url, ambient, note, state: "new"|"read"|"kept"|"dismissed", created_at}]`
- `GET /profiles/{id}/sharing` → `{activity, reactions, shelves, recommendations, include_mature, excluded_series: [{source_id, series_key}]}`
- `DELETE /circle/activity` → 204 (clears this profile's shared activity)
- `GET /library/collections` rows gain `{owner_profile_id, role: "owner"|"can_add"|"view_only", members: [{profile_id, avatar_key}]}`, and shared shelves are included.
- `GET /library/collections/{id}` members gain `added_by_profile_id`.
- The server authorises `POST` and `DELETE /library/collections/{id}/series` by role.
- Leaving a shelf is `DELETE /library/collections/{id}/share/{own profile_id}`.

## STACK-17 · medium · §9.1.7, §9.1.5: the recap stream cannot carry the profile header in a browser, and its framing is unspecified

**Problem.** The browser's `EventSource` cannot set request headers, so it cannot send `X-Profile-Id`. Without that header the server resolves reads to the unscoped bucket with 18+ closed, so an 18+ series would get no recap. The event names, the way metadata is delivered, and the non-stream (unavailable) answers are all unspecified. The stream also passes through the Next `/api` rewrite and Caddy, which can buffer it.

**Evidence.**
- §9.1.7: "`GET /ai/recap?source&series&to` | Streamed text (SSE) + `{range, cast, sourced_from: "ocr" | "text", available, reason}`".
- capabilities §1: "Clients send `X-Profile-Id: <id>` on every request. Reads resolve it leniently (missing or foreign id means the unscoped bucket, 18+ closed)".

**Fix.** Both clients read the stream with `fetch` (web: `response.body.getReader()` plus an SSE line parser) or dio `ResponseType.stream`, always with the normal headers; never `EventSource`.

Framing:
1. `event: meta` `data: {"range":[131,142],"cast":[{"name":"Kim Dokja","role":"the reader"}],"sourced_from":"ocr","generated_at":"…"}`
2. Then n × `event: delta` `data: {"text":"…"}`
3. Then `event: done` `data: {}`, or `event: error` `data: {"code","message"}`.

When no recap is possible, answer plain JSON 200 before any stream: `{"available": false, "reason": "not_configured"|"budget_exhausted"|"rate_limited"|"no_text"}`. Stream headers: `Content-Type: text/event-stream`, `Cache-Control: no-cache, no-transform`, `X-Accel-Buffering: no`.

## STACK-18 · medium · §9.1.7, §9.1.2, §9.1.8: `GET /home` item shapes, the time zone, and the `GET /ai/similar` envelope are missing

**Problem.**
- **Item shapes.** `GET /home` has 14 section types, each with different `items`, and none of the item shapes is given.
- **Time zone.** The server composes headlines that depend on the local hour ("This morning" / "Tonight"), the at-risk state "after 20:00 local", `new_this_week` ("last 7 days") and "cached 10 min per profile", but the endpoint takes no time-zone parameter. `/library/statistics` already takes one.
- **Similar.** `GET /ai/similar` returns only "World items with `why`", but §9.1.8's unavailable and stale states need `available`, `reason` and `generated_at`.

**Evidence.**
- §9.1.7: "`sections: [{type, title, seed?, note?, items, why?, state, generated_at}]`" and "`GET /ai/similar?source&series` | World items with `why`".
- capabilities §10: `tz_offset_minutes (-720..840)` on statistics.

**Fix.** Add `&tz_offset_minutes=-720..840` to `GET /home` and include it in the cache key. Item shapes by section type:

| Section type | `items` shape |
|---|---|
| `continue` | continue-reading rows + `ambient`, `nudge: "new"|"almost_done"|"paused"|null`, `new_count`, `paused_days` |
| `new_this_week`, `almost_there` (+ `chapters_left`), `where_were_we` | FollowedSeries list rows + `ambient` |
| `sent_to_you` | Letter (STACK-16) |
| `picked`, `because`, `first_picks`, `popular` | `{kind: "world", item: WorldItem}` or `{kind: "source", item: SourceSeries}` |
| `circle`, `circle_top` | `{member, series, rank?}` |
| `sources` | pin rows + `latest_covers: [url × 3]` |
| `genres` | `[{genre, weight}]` |
| `numbers` | `{streak: {current_days, longest_days, alive_today}, chapters_week, seconds_week}` |

`GET /ai/similar` → `{items: WorldItem[], available, reason: "ok"|"not_configured"|"budget_exhausted"|"rate_limited", generated_at}`.

## STACK-19 · medium · §9.4.3, §2.1.5, §15.5: server-side panel detection contradicts DESIGN's own rule for the image proxy, and the not-ready contract is missing

**Problem.**
- **Contradiction.** DESIGN keeps page tint on the client because the shared VPS proxy "must not decode and analyse every page". Yet it has the server run Pillow panel detection over every page of a chapter, which is heavier than a 16 × 16 tint. Stack §2.6 does place panels on the backend, so the placement conforms, but the two rules in DESIGN contradict each other.
- **Missing contract.** There is no response for "not ready", no trigger for the background job, and no bound on how much it decodes.

**Evidence.**
- §9.4.3: "computed server-side from the page proxy with a whitespace/blackspace gutter projection in Pillow; cached per page ETag", and "the backend computes it in the background and the button appears when done".
- §2.1.5: "because the shared VPS image proxy must not decode and analyse every page". §15.5: "the image proxy does no image analysis".

**Fix.** Keep panels on the server (stack §2.6) and bound the work:
- Enqueue only when a profile first opens guided view on a chapter: `POST /reader/panels/request {source_id, series_key, chapter_key}` → 202.
- Run one job at a time, decode at the proxy's 480 px width, and skip chapters over 200 pages.
- Responses from `GET /reader/panels?source&series&chapter`:
  - `200 {status: "ready", pages: [{number, panels: [{x, y, w, h}]}]}`
  - `200 {status: "pending", retry_after_s: 10}`
  - `200 {status: "failed"}`
- Manifests carry `panels_ready: bool`, and the client polls every 10 s while guided view waits.
- Reword §2.1.5's rationale to "page tint must exist on the first read; panels are computed once per chapter, on request".

## STACK-20 · medium · §9.2.7, §9.2.4, §9.2.1: `GET /library/annual` is prose only, contradicts itself on calendar years versus a rolling window, and has no time zone

**Problem.**
- **No shape.** The endpoint's output is described in prose, with no field names.
- **Contradiction.** A `year` parameter and an `available_years` list imply calendar-year aggregates, but §9.2.4 says there is no calendar-year aggregate and the Annual is a rolling 365 days.
- **Time zone.** The clock page and the "longest streak, in March" line need the profile's time zone, which the endpoint does not take.

**Evidence.**
- §9.2.7: "`GET /library/annual?year=` returning the eleven pages' aggregates (time, chapters per month, top series, …) … plus `available_years`".
- §9.2.4: "Rolling windows: the backend statistics window is rolling 365 days; until a calendar-year aggregate exists, the cover reads "Your last twelve months" and the URL year is the current year."

**Fix.** Make the Annual a calendar year in the profile's time zone, and replace the "Rolling windows" paragraph with a `partial` flag ("Your year so far").

`GET /library/annual?year=2026&tz_offset_minutes=330` →

```
{
  year, partial, since, until, recorded_days, seconds_read, chapters_read,
  chapters_by_month: [12 ints],
  top_series: [{source_id, series_key, title, cover_url, ambient, seconds_read, chapters_read}] (≤ 5),
  genres: [{genre, weight}] (≤ 8),
  by_hour: [24 × {hour, seconds_read}],
  longest_streak: {days, month},
  top_sources: [{source_id, name, share}] (≤ 3),
  circle: [{profile_id, name, avatar_key, finished_together: [title]}] | null,
  voices: [{voice_id, name, seconds}] (≤ 3),
  available_years: [int]
}
```

## STACK-21 · medium · §8.7 step 5: onboarding seeds need endpoints that do not exist

**Problem.** Step 5 builds a poster wall from "world recommendations by genre" and inserts 3 similar posters after each pick. No endpoint returns world items by genre, format or style:
- `/library/world/recommendations` takes the profile's followed series as seeds, and returns an empty `for_you` for a new profile.
- `GET /ai/similar` takes a source series, while the wall holds WorldItems (an `anilist_id`, possibly with no available sources).

**Evidence.**
- §8.7: "A poster wall seeded from steps 2–4 (world recommendations by genre). Each pick inserts 3 similar posters right after it".
- capabilities §9: `/library/world/recommendations` inputs are `seeds (1-8), per_seed`. §26: "world recs return empty `for_you` then".

**Fix.** Add two endpoints to §15.5 and §8.7's Backend line:
- `GET /library/world/discover?genres=Action,Romance&exclude_genres=Ecchi&formats=Manhwa,Manga&limit=24` → `{items: WorldItem[], unavailable_reason}`. It is an AniList genre query, gated for 18+ on serve, and uses no AI budget.
- `GET /ai/similar?anilist_id=…`, in addition to `?source&series`, returning the STACK-18 envelope.

## STACK-22 · medium · §8.11: smart shelf rules are never stored anywhere

**Problem.** Smart shelves have rule chips, a `SMART` badge and a `SMART RULES` credit, but the collections API stores only a name and a description, and §15.5 adds no rules field. A smart shelf made on the phone would appear as an empty manual shelf on the desktop.

**Evidence.**
- §8.11: "a switch `Smart shelf` which reveals rule chips (client-side rules over library rows …)", "credits (`SMART RULES: READING · 3+ NEW` …)", and "A smart shelf's members are computed from the owner's own library on the device".
- capabilities §11: `POST /library/collections {name, description?}`, `PATCH … name?, description?, sort_order?`.

**Fix.** Collections gain `rules: null | {all: [{field: "reading_status"|"is_favorite"|"new_count"|"format"|"content_kind", op: "eq"|"gte"|"in", value}]}` on POST, PATCH and GET (list and detail), with `smart = rules != null`. Membership is still computed on the client from `/library/series`. Add this to §15.5.

## STACK-23 · medium · §8.30.3, §15.2: the edition-preview route renders inside the wrong skin, has no way to receive its fixture, and reads files the Docker build cannot see

**Problem.**
1. **Wrong skin.** `app/skin-preview/[skin]/page.tsx` sits under the root layout, which stamps `<html data-skin>` from the `mm-skin` cookie and mounts that skin's Shell and fonts. The Glass preview therefore renders under `data-skin="cinematic"`, and Glass's `[data-skin="glass"]` tokens never apply.
2. **No fixture path.** Tonight reads its data through the shared hooks, and nothing says how the fixture replaces them.
3. **Outside the build context.** `design/previews/*` lies outside the frontend Docker build context, so `next build` in the image cannot import the JSON or serve the covers.

**Evidence.**
- §8.30.3: "`frontend/src/app/skin-preview/[skin]/page.tsx` … renders `skins[skin].screens.tonight` with the static fixture `design/previews/demo-feed.json` … the covers are `design/previews/covers/01.webp`–`06.webp`".
- Stack §2.5 step 6: "The server reads the cookie in `getSkin()`, stamps `<html data-skin="glass">`".
- `docker-compose.yml` line 91: `context: ./frontend`.

**Fix.**
- **Separate root layouts.** Split the app into route groups, each with its own root layout:
  - `app/(app)/layout.tsx`: today's root.
  - `app/(preview)/skin-preview/[skin]/layout.tsx`: renders `<html data-skin={params.skin}>` with that skin's fonts and no Shell.
- **Fixture.** Seed the React Query cache from the fixture (`<HydrationBoundary state={fixtureState}>`, using the same query keys as `useHomeFeed()`).
- **Build context.** `design/build.mjs` copies `design/previews/demo-feed.json` to `frontend/src/skins/preview-feed.generated.json` and the covers to `frontend/public/skin-preview/covers/`.

## STACK-24 · medium · §2.1.5, §15.5: `ambient` "on every series payload" never says when it may be null, and computing it inline would load the shared VPS

**Problem.**
- **Inline cost.** Browse, search and list payloads (`GET /sources/search` tier 2 across about 89 sources; 40 per page on catalogues) would have to fetch and decode every cover upstream before answering. That is the same shared-VPS cost §2.1.5 uses to reject server-side page tint, and it also eats the 60/min sources bucket.
- **No proxy for AniList.** AniList covers are absolute CDN URLs, and no proxy route exists for them.
- **No null state.** DESIGN never says whether `ambient` can be null, or when it appears.

**Evidence.**
- §2.1.5: "computed once from its cover on the backend, next to cover resizing … served as `ambient: {duo, tint, ink}` on every series payload" and "AniList cover (world recommendations) | Backend, same extractor on the proxied cover".
- capabilities §9: "`cover_url` (AniList CDN, absolute)".

**Fix.**
- Compute `ambient` only inside the cover proxy's resize path (the first time a cover is served at any width), plus a background job for followed series.
- Payloads carry `ambient: {duo, tint, ink} | null`, where null means "not computed yet". Never compute it inline in list or search endpoints.
- Clients render `color.ambient.fallback.*` for null and dissolve over 800 ms when a later payload carries the value.
- WorldItem `ambient` comes from a background fetch of the AniList image, capped at 20 per minute.

## STACK-25 · low · §2.1.5: the web duotone runs in linear RGB, so it does not match Flutter

**Problem.** SVG filter primitives default to `color-interpolation-filters: linearRGB`. The same 20-number matrix therefore runs on linearised values on the web, but on sRGB-encoded values in Flutter's `ColorFilter.matrix` and in the Canvas 2D share-card renderer. Web midtones come out visibly different.

**Evidence.** §2.1.5: "Duotone implementation (one matrix, both clients) … Web: an SVG `<filter>` with `feColorMatrix type="matrix"` … Flutter: `ColorFiltered(colorFilter: ColorFilter.matrix([...same 20 numbers...]))`". "color-interpolation-filters" occurs 0 times in DESIGN.

**Fix.** Use `<filter id="duo-{id}" color-interpolation-filters="sRGB">`.

## STACK-26 · low · §2.1.5, §15.6: registered-property colour transitions are not "compositor-friendly"

**Problem.** Transitions of `@property` custom properties run on the main thread in Chrome and Safari, with a style recalculation and repaint on every frame. With `inherits: true` set on the nearest provider element, the whole reader subtree (hundreds of page boxes) is recalculated every frame for 800 ms while the user scrolls, at up to one change every 600 ms. That puts §15.8's "reader at 120 Hz with page tint on" check at risk.

**Evidence.**
- §2.1.5: "Web registers `@property --amb-duo`, … (`syntax: "<color>"`, `inherits: true`) and transitions them 800 ms".
- §15.6: "ambient colour transitions are CSS registered properties (compositor-friendly)".

**Fix.** Register them with `inherits: false` and set and transition them only on the few elements that paint them (scrim bands, ruler fill, gutters). Alternatively, cross-fade two stacked gradient layers by `opacity`, which the compositor handles. Correct §15.6's wording either way.

## STACK-27 · low · §15.2: the grain jitter repaints a blended full-bleed layer 12 times a second

**Problem.** Animating `background-position` is not composited, so every step repaints the hero-sized `mix-blend-mode: overlay` layer.

**Evidence.** §15.2: "`background: url(grain.png) repeat; mix-blend-mode: overlay; opacity: 0.06` … animated by a `background-position` jitter of `steps(4)` over 333 ms".

**Fix.** Put the PNG on an oversized pseudo-element (`inset: -128px`) and animate `transform: translate()` through the same four offsets with `steps(1)` keyframes at 0/25/50/75 % over 333 ms, with `will-change: transform`.

## STACK-28 · low · §8.0.5, §7.22: two Flutter motions cannot be built with the named mechanisms

**Problem.**
- **Back swipe.** `swipeable_page_route` 0.4.8 releases the back swipe with a fixed curve, not `spring.release`, and the curve is not configurable.
- **Quick look.** The poster-to-header match cut cannot use `Hero`, because Hero flies only between `PageRoute`s and `ModalBottomSheetRoute` is a `PopupRoute`.

**Evidence.**
- §8.0.5: "release `spring.release`".
- swipeable_page_route 0.4.8 `page_route.dart`: `const Curve animationCurve = Curves.fastLinearToSlowEaseIn;` and a private `_kMaxDroppedSwipePageForwardAnimationTime = 800`.
- §7.22: "a sheet rises whose header match-cuts the poster … Flutter builds it on `onLongPress` + `showModalBottomSheet`".
- Flutter `heroes.dart` lines 917–918: `toRoute is! PageRoute<dynamic> || fromRoute is! PageRoute<dynamic>` ends the flight. `bottom_sheet.dart` line 870: `class ModalBottomSheetRoute<T> extends PopupRoute<T>`.

**Fix.**
- **Back swipe.** State that the iOS back release uses the package's curve (or fork `dragEnd` to `controller.animateWith(SpringSimulation(CineSprings.release, …))`).
- **Quick look.** Build it as a `PageRouteBuilder(opaque: false, barrierColor: Color(0xC7000000))` so `Hero` can fly the poster into the 96 px header.

## STACK-29 · low · §2.8.3: the Flutter vignette is a circle; the CSS vignette is an ellipse

**Problem.** CSS `radial-gradient(120% 90% …)` is an ellipse with radii of 1.2 × width and 0.9 × height. Flutter's `RadialGradient.radius` is a fraction of the shortest side, so `radius: 1.2` draws a circle of 1.2 × width on a phone (about 0.55 × height). The top and bottom darken much earlier than on the web, which contradicts §2.8's "identical values".

**Evidence.** §2.8.3: "`radial-gradient(120% 90% at 50% 40%, rgb(0 0 0/0) 60%, rgb(0 0 0/.45) 100%)`" versus "`RadialGradient(center: Alignment(0, -0.2), radius: 1.2, stops: [.6, 1], …)`".

**Fix.** Emit `RadialGradient(center: Alignment(0, -0.2), radius: 1.0, stops: [.6, 1], colors: […], transform: CineEllipse(sx: 1.2, sy: 0.9))`. `CineEllipse` is a `GradientTransform` that scales about the centre point by `(sx × width / shortestSide, sy × height / shortestSide)`.

## STACK-30 · low · §10.1.5, §10.1.6, §10.1.1: the letter-reveal stagger counts spaces on the web but not in Flutter

**Problem.** Past the 560 ms cap, the two clients compute different steps. For "Because you read Solo Leveling" (30 graphemes, 26 letters), the web steps 19.3 ms and its last letter starts at 483 ms; Flutter steps 22 ms and its last letter starts at 550 ms.

**Evidence.**
- Web: `custom={graphemes(text).length}` with `stagger(Math.min(0.024, 0.56 / Math.max(1, n - 1)))`.
- Flutter: `_n = widget.text.characters.where((c) => c != ' ').length` and `_step = min(24, 560 ~/ (_n - 1))`.

**Fix.** Use n = the number of non-space graphemes on both clients. On the web: `custom={graphemes(text.replace(/\s/g, "")).length}`. State the rule in §10.1.1.

## STACK-31 · low · §2.8 (`design/lint-utilities.mjs`): the lint as specified fails the contract's own reference code

**Problem.** The lint allows only the token names listed in §2.8, but DESIGN's own reference code uses many other Tailwind utilities. As written, CI rejects the reference implementation, or the implementer has to guess the lint's real scope.

**Evidence.**
- §2.8: "a Cinematic screen uses only the names in this table (checked by `design/lint-utilities.mjs` … which greps `src/skins/cinematic/**` for utilities outside this list".
- §10.1.5 and §10.2.3 use `inline-block`, `whitespace-nowrap`, `relative`, `absolute`, `w-0`, `h-[0.86em]`, `bottom-[0.06em]`, `text-transparent` and `animate-caret-out`, none of which are in §2.8.

**Fix.** The lint checks only token namespaces against §2.8 and §3.5:
- Colour prefixes (`bg-`, `text-`, `border-`, `outline-`, `fill-`, `stroke-`) with colour names.
- `rounded-*`, `blur-*`, `ease-*`, `type-*` and `text-<role>`, `font-<family>`, `z-*`.

It bans arbitrary colour, radius and duration values (`bg-[#…]`, `rounded-[…]`, `duration-[…]`), and allows structural utilities and arbitrary lengths. Add `--animate-caret-out` to the generated `@theme`.

## STACK-32 · low · §2.8, §15.2, §15.3, §15.10 (vs stack §2.1, §2.3): generator and layout departures from the stack are not recorded

**Problem.** The generator gains an output file the stack does not list, and the Dart token classes change from the stack's single shared `SkinTokens` type to per-skin `ThemeExtension` classes. None of this is in §15.10, which covers only the scalar kind, haptic sequences and flags. Because one generator serves both skins, its author has to know which form to emit. §15.3 and §8.30.3 also give two different folders for the preview frames.

**Evidence.**
- DESIGN §2.8: "emitted into `frontend/src/skins/theme.generated.css`" and "`CineTokens extends ThemeExtension<CineTokens>` … also … `CineColors`, `CineSpace`, `CineDur`, `CineCurves` and `CineSprings`".
- Stack §2.1 output table: no `theme.generated.css`, and "`const cinematicTokens = SkinTokens(bg: Color(0xFF000000), radiusCard: 6, …)`".
- §15.3 lists `assets/skin_previews/{cinematic,glass}/000–035.png` under `mobile/lib/skins/cinematic/`, while §8.30.3 says `mobile/assets/skin_previews/…`.

**Fix.** Add a §15.10 row S11:
- Outputs are the stack's plus `frontend/src/skins/theme.generated.css`.
- Dart output per skin is a `CineTokens` (or `GlassTokens`) `ThemeExtension` plus the static const classes; the stack's `SkinTokens` name is retired.
- Preview frames live at `mobile/assets/skin_previews/`, declared under `flutter: assets:`.

## STACK-33 · low · §15.11, §12.7, §6: build tools are unpinned or missing from the ledger, and the dependency gate never builds Android

**Problem.**
- **Tools.** `fantasticon` has no version, and `resvg` and `sox` are not in the ledger at all.
- **Gate.** The resolution gate checks `pub get`, `analyze` and the iOS dry run only, yet several new plugins change the Android build: `flutter_soloud` compiles C++ with the NDK (4.1.7 via its CMake script), and `audio_service` and `flutter_dynamic_icon_plus` edit `AndroidManifest.xml`.

**Evidence.**
- §15.11: "`fantasticon` (npm) | build time | …" (the latest is 4.1.0, which requires `node >= 22.0`).
- §12.7: "one export script (`resvg`) renders PNGs".
- §6: "original syntheses (`sox -n … synth`)".
- Gate: "`flutter pub get` and `flutter analyze` on Flutter 3.44.6 … plus the iOS dry-run build".

**Fix.**
- Pin `fantasticon@4.1.0` and `@resvg/resvg-js@2.6.2`, both run with `npx` from `brand/` scripts.
- Record `sox` 14.4.2 as an authoring-only system tool whose outputs are committed.
- Add `flutter build apk --release` (in CI, not on the dev box) to the native-dependency gate.

## STACK-34 · low · §12.3: the Android icon does not change "at the restart"

**Problem.** `flutter_dynamic_icon_plus` applies the activity-alias swap from its service's `onTaskRemoved` and `onDestroy`, with `DONT_KILL_APP`. `AppRestart` is an in-process widget-key swap, so the task is never replaced, and the icon only changes after the user removes the task from recent apps or the process dies.

**Evidence.**
- §12.3: "On Android the switch is an `activity-alias` swap applied at the restart (the task is being replaced anyway)".
- `FlutterDynamicIconPlusService.kt` lines 12 and 21 (`onTaskRemoved`, `onDestroy`); `ComponentUtil.kt` line 24 (`PackageManager.DONT_KILL_APP`); the README requires `android:stopWithTask="false"`.

**Fix.** Change the confirm copy to "The app icon changes the next time you close ManhwaManiacs from recent apps." and list the required manifest changes: the launcher aliases, and the `FlutterDynamicIconPlusService` with `stopWithTask="false"`. This is Glass-era work, since no alternate icon is registered while `glass_available` is false.

## STACK-35 · low · §8.32, §15.2: the service worker cannot read the `mm-skin` cookie the way DESIGN assumes

**Problem.** A service worker has no `document.cookie`, and `Cookie` is a forbidden request header, so `event.request.headers.get("cookie")` returns null for navigations. Only the Cookie Store API could read the cookie, and not every engine the app supports exposes it to workers.

**Evidence.**
- §8.32: "(and a Glass version chosen by the `mm-skin` cookie at fetch time by the worker)".
- §15.2: "the Cinematic `offline-fallback.html` variant chosen by the `mm-skin` cookie".

**Fix.**
- Send the skin to the worker in its messages: `postMessage({ type: "skin-changed", skin })`, plus `{ type: "skin", skin }` on every boot.
- The worker stores it as a `/__skin` response in a `mm-sw-meta` cache and serves `offline-fallback-{skin}.html`.
- Use `self.cookieStore?.get("mm-skin")` first where it exists.

## STACK-36 · low · §8.2, §12.4 (vs stack §2.5 web step 6): on the web, the skin-switch restart counts as a warm start, so the full splash never plays

**Problem.** After Stop the press, `location.replace` is a navigation within the same session. By §8.2's rule that makes it a warm start (a 200 ms fade), which contradicts §12.4 ("The skin-switch restart plays the full reveal"). The stack keys the splash on a flag that DESIGN never uses.

**Evidence.**
- §8.2: "**Warm start** (resumed within 4 h, or any web navigation after the first in a session): the masthead fades in 200 ms and out 200 ms; no letters".
- §12.4: "The skin-switch restart plays the full reveal".
- Stack §2.5: "Glass's `Splash` plays once, keyed on a `mm.skin.splash` sessionStorage flag". "mm.skin.splash" occurs 0 times in DESIGN.

**Fix.** The web splash plays the full reveal when `sessionStorage['mm.skin.splash']` is missing or differs from the current skin, and then sets it to the current skin. Otherwise it plays the warm fade.

## STACK-37 · low · §7.11: sonner cannot hold the stop-press banner in the bottom slot

**Problem.** Sonner orders toasts by creation time, with the newest in front, and has no API to pin one toast to a slot. A banner created after a toast lands in front of it, not under it.

**Evidence.** §7.11: "The stop-press banner … is a member of the same stack, always its oldest entry: a new toast rises above it and the banner keeps its bottom slot. With the banner showing, at most one toast is visible above it"; "Web uses `sonner` 2.0.8 in unstyled mode".

**Fix.** Render the banner outside sonner, in the same fixed container. While the banner shows, use `<Toaster offset={{ bottom: bannerHeight + 8 }} visibleToasts={1} />` (sonner 2.0.8 types `offset` as `{top, right, bottom, left} | string | number`); otherwise use `visibleToasts={2}`.

## STACK-38 · low · §8.0.3: in go_router, `/library/:followedId` swallows the static `/library/*` routes unless it is declared last

**Problem.** go_router returns the first route that matches. If `featureByFollow` is declared in the table's order, `/library/history` resolves to the feature page with `followedId = "history"`. Next.js resolves static segments first, so the web is unaffected.

**Evidence.** §8.0.3 lists `featureByFollow` `/library/:followedId` before `/library/collections`, `/library/history`, `/library/bookmarks`, `/library/recommendations`, `/library/statistics` and `/library/browse`.

**Fix.** In `router.dart`, declare `featureByFollow` after every static `/library/…` route. The completeness test also asserts that `Routes.history` resolves to `ScreenId.history`.

## STACK-39 · low · §15.5, §8.17, §8.7, §2.1.5, §9.2.2: small request and response gaps on new endpoints

**Problem.**
- **Repoint.** §8.17 offers a "Keep following it on MangaDex too" checkbox, but `POST /library/{followed_id}/repoint {source_id, series_key}` has no field for it and no response shape. Its path also departs from the existing `/library/series/{followed_id}` family.
- **AI feedback.** `POST /ai/feedback` lists only `not_interested` and `liked_pick`, while §8.17 sends `{signal: "tag_rejected"}` without saying which tag.
- **No responses.** `POST /reader/page-tints` and `POST /library/statistics/milestones/{days}/seen` have none.
- **Unnamed field.** "First four member covers on `GET /library/collections`" does not name the field.
- **Taste.** The shape of `PUT /profiles/{id}/taste`'s `seeds[]` is not given.

**Evidence.**
- §15.5: "`POST /library/{followed_id}/repoint {source_id, series_key}`" and "First four member covers on `GET /library/collections`".
- §9.1.7: "`POST /ai/feedback` | 204 | `not_interested`, `liked_pick`".
- §8.17: "`x` to reject (`POST /ai/feedback {signal: "tag_rejected"}`)".
- §8.7: "`PUT /profiles/{id}/taste {step, formats, genres, styles, seeds}`".

**Fix.**
- `POST /library/series/{followed_id}/repoint {source_id, series_key, keep_old: bool}` → `{followed: FollowedSeries, mapped_chapter_key, mapped_chapter_number | null}`.
- `POST /ai/feedback {signal: "not_interested"|"liked_pick"|"tag_rejected", anilist_id?, source_id?, series_key?, tag?}` → 204.
- `POST /reader/page-tints` → 204 (unknown pages are ignored).
- `POST /library/statistics/milestones/{days}/seen` → 204.
- Collection list rows gain `preview_covers: [cover_url] (≤ 4)` and `preview_ambient_duo`.
- Taste fields:
  - `seeds: [{anilist_id} | {source_id, series_key}]`
  - `formats: ["Manhwa"|"Manga"|"Manhua"|"Novel"]`
  - `genres: {name: 1|2|-1}`
  - `styles: ["painted"|"cel"|"screentone"|"manhua-3d"|"sketch"|"retro"|"pastel"|"noir"|"chibi"]`
