# Mobile foundation 02: isolated native-plugin commit, haptics channel and sound layer

## Goal

Land every native plugin both skins need in one isolated dependency commit, prove it builds in CI on both platforms before any code uses it, and then build the two skin-neutral feedback services the skins will call: `skins/skin_haptics.dart` (every `HapticEvent` through its skin's pattern to `haptic_feedback` 0.6.5, a `gaimon` 1.5.0 AHAP pattern, or the one `mm/platform` method channel) and `skins/skin_audio.dart` (the UI sound layer on `flutter_soloud` 4.1.7, off by default, plus the single owner of the app's audio session). You also wire `audio_service` 0.18.19 natively (Android `MainActivity` becomes an `AudioServiceActivity`, the service, the media button receiver, the foreground-service permissions, one `AudioService.init` in `main`) with an idle handler that mobile/15 connects to narration, and you add a `flutter build apk --release` job to CI next to the iOS build. Legacy users see and hear nothing new: the legacy skin keeps its old haptics helper, UI sounds stay off, and narration keeps its spoken-word audio session. The only visible addition is a debug "Feedback lab" in Settings → Diagnostics so the owner can feel and hear both skins' vocabularies on his devices.

## Read first

Read these before you plan. Section numbers are binding.

1. `docs/redesign/stack-decision.md` §2.1 (haptics map events to pattern names; each platform maps names to calls), §2.3 (`skins/skin_haptics.dart`), §3 "Dependency changes" (native plugins in one isolated commit with a CI iOS dry run), §4 risk 9 (the remote-only iOS loop), risk 10 (Flutter pinned at 3.44.6), risk 11 (dev-box memory).
2. `docs/redesign/cinematic/DESIGN.md`:
   - §5 (Cinematic haptics: letterpress character, named impacts through `haptic_feedback`, AHAP signatures `impress`, `stamp`, `wipe`, `ignite`, `pressrun`, `pass`, the full event table, "never haptic", the per-device "Haptic feedback" switch, "Feel it"),
   - §6 (the Press Room cues, off by default, **per profile**, volume 0–100 % default 60 %, the full event → cue map, playback through `flutter_soloud` 4.1.7, suppressed during narration or a soundscape, the audio session and focus policy table: State A, State B, Voice sample; `configureNovelAudioSession()` replaced by State A; re-apply State A after `SoLoud.instance.init()`),
   - §8.16.10 (`audio_service` wiring: `MainActivity : AudioServiceActivity()`, the manifest service and receiver, the permissions, `AudioService.init` once in `main()` before `runApp(AppRestart(…))`, `audioHandlerProvider.overrideWithValue(handler)`, `AudioServiceConfig(androidNotificationIcon: 'drawable/ic_stat_mm', notificationColor: Color(0xFFF4D03F), androidNotificationChannelName: 'Listen')`),
   - §15.3 (packages and the isolated native commit), §15.8 (the iPhone checks `AVAudioSession.sharedInstance().category` right after init), §15.10 S14, §15.11 (the ledger rows, their fallbacks, and the resolution check: CI `flutter pub get`, `flutter analyze`, the iOS dry run and a `flutter build apk --release` job in `.github/workflows/tests.yml`; a failing package is replaced by its fallback, never force-resolved).
3. `docs/redesign/glass/DESIGN.md`:
   - §5 intro (one service per client, the per-device Haptics switch, rate limits), §5.1 (primitives and the Android table with API levels, velocity-scaled impacts `i = clamp(0.3 + |v| / 4000, 0.3, 1.0)`, the one Android haptic rule, `VIBRATE`, `haptics.systemEnabled`), §5.2 (Glass event patterns), §5.3 (AHAP signatures),
   - §6 (Meniscus cues, **per device**, volume −24 to 0 dB default −6 dB, depth-pitched `push-1` … `push-4`; "One audio session, one owner": `skin_audio.dart` owns the states `idle`, `soundscape`, `narration`; background rules),
   - §15.3 "Native" bullet (the one `mm/platform` channel, `haptics.impact {style, intensity}` in `AppDelegate.swift`, `performHapticFeedback` constants behind SDK checks in `MainActivity.kt`, `haptics.oneShot`), §15.6 rows "Phosphor on Flutter" and "Audio session", §15.10 G16, §15.11 (rows `flutter_soloud`, `share_plus`, `phosphor_flutter` "not used").
4. `docs/redesign/inventory/00-decisions.md` ("Haptics: yes, rich, per skin, on iOS and Android"; "Sound: … OFF by default").
5. `docs/redesign/inventory/mobile.md` G12 (today's haptics vocabulary), §5a K13 (the haptic feedback switch), S26 and N3 (narration today), S34 (Diagnostics).
6. `docs/redesign/00-baseline.md`.
7. `docs/redesign/prompts/shared/00-design-contract-and-token-generator.md` §2 "haptics" (the pattern grammar: a primitive `selection | light | medium | heavy | rigid | soft | success | warning | error | toggleOn | toggleOff | dragStart | rigidBack`, optionally `:<0..1>`, `:velocity` or `:velocity<=<0..1>`; `ahap:<name>` or `ahap:<name>{depth}`; `none`; sequences and repeats) and `docs/redesign/prompts/shared/01-glass-tokens-haptics-motion-names-contrast.md` (the Glass maps and the AHAP JSON files), `docs/redesign/prompts/shared/02-icon-sets-and-custom-glyphs.md` "Open issues and hand-offs" (**do not add `phosphor_flutter`**).
8. Upstream outputs (read, never hand-edit): `mobile/lib/skins/contract.g.dart` (`HapticEvent`, `SoundEvent`), `mobile/lib/skins/token_types.g.dart` (`HapticStep` with `pattern`, `afterMs`, `repeatEveryMs`, `maxRepeats`), `mobile/lib/skins/{cinematic,glass}/tokens.g.dart` (`cinematicHaptics`, `glassHaptics`, `cinematicSoundCues`, `glassSoundCues`, `cinematicSoundEvents`, `glassSoundEvents`), `mobile/assets/haptics/{cinematic,glass}/*.ahap.json`, `mobile/assets/sounds/{cinematic,glass}/*.wav`; mobile/01's `mobile/lib/skins/{skin,skins}.dart`, `mobile/lib/app/{skin_app,switch_skin}.dart`, `mobile/lib/main.dart`.
9. Today's code you change: `mobile/pubspec.yaml`, `mobile/pubspec.lock`, `.github/workflows/tests.yml`, `.github/workflows/ios-build.yml` (read only; it calls `tests.yml`), `mobile/android/app/src/main/AndroidManifest.xml`, `mobile/android/app/src/main/kotlin/com/manhwamaniacs/reader/{MainActivity,OcrChannel}.kt`, `mobile/android/app/build.gradle.kts`, `mobile/ios/Runner/{AppDelegate.swift,Info.plist}`, `mobile/lib/core/utils/haptics.dart`, `mobile/lib/features/settings/providers/settings_provider.dart` (`hapticFeedbackProvider`), `mobile/lib/features/novels/utils/novel_audio_session.dart`, `mobile/lib/features/novels/widgets/novel_audio_player.dart`, `mobile/lib/features/settings/screens/diagnostics_screen.dart`, `mobile/test/android/*.dart`.

## Preconditions (stop and report if any fails)

```bash
cd /srv/manhwamaniacs/dev/ManhwaManiacs
git branch --show-current                                        # feat/vps-slim-source-native
ls mobile/lib/app/app_restart.dart mobile/lib/skins/skins.dart   # mobile/01 done
ls mobile/lib/skins/glass/tokens.g.dart                          # shared/01 done
ls mobile/assets/haptics/cinematic/impress.ahap.json mobile/assets/haptics/glass/droplet.ahap.json   # shared/01 AHAP files
ls mobile/assets/sounds/cinematic mobile/assets/sounds/glass | head   # shared/03 done
grep -n "phosphor_flutter\|dependency_overrides" mobile/pubspec.yaml # must print nothing
```

## Skills to invoke

- `superpowers:writing-plans` first. Save the plan at `docs/redesign/plans/mobile-02.md`. The plan must show the CI gate between the dependency commit and every commit that uses a plugin.
- `superpowers:executing-plans` for A and B (they wait on CI between commits); `superpowers:subagent-driven-development` is allowed for C and D once B is green. Verify every slice against `git status` and `git diff`, never against a report.
- `superpowers:test-driven-development` for the pattern parser, the platform routing table, the sequence timing, the audio-state machine and the sound preferences.
- `impeccable` and `taste-skill:taste-skill` for the Feedback lab only (a plain, legible debug list in the legacy Diagnostics style).
- `superpowers:verification-before-completion` before you claim anything is done.

## Track rules (every mobile step)

- Work in `mobile/` plus `.github/workflows/tests.yml` (this step's CI job), `docs/redesign/plans/` and `docs/redesign/proof/mobile-02/`. Never touch `frontend/`, `backend/` (never `backend/connectors/`), `design/` sources or generated files.
- Stage explicit paths only; never `git add -A`, `git add .` or `git commit -a`.
- Flutter is `/srv/manhwamaniacs/dev/flutter/bin/flutter`. `flutter pub get`, `flutter analyze` and `flutter test` only after `free -m`, one at a time, never while a `next build` runs. **Never `flutter build` on this box**: the APK and the iOS app are built by CI runners.
- Device checks are a checklist for the owner (iPhone through SideStore, the Android flagship).

## Scope, item by item

### A. The isolated dependency commit (`build(mobile): redesign native plugins and motion packages`)

1. `mobile/pubspec.yaml` `dependencies:`, exact pins (no caret), in one commented block:

   | Package | Pin | Kind | Used by | Fallback if CI fails (never `dependency_overrides`) |
   |---|---|---|---|---|
   | `haptic_feedback` | `0.6.5` | native | both skins' named impacts | `HapticFeedback` from `package:flutter/services.dart` |
   | `gaimon` | `1.5.0` | native | AHAP signatures | named impacts only |
   | `flutter_soloud` | `4.1.7` | native (C++ FFI) | UI sounds, voice-sample RMS, Glass soundscape | `just_audio` (installed) for cues |
   | `share_plus` | `12.0.2` | native | share cards | save to the documents folder with a toast |
   | `audio_service` | `0.18.19` | native | Listen lock screen | foreground-only narration (today) |
   | `sensors_plus` | `7.1.0` | native | shake to extend; Glass tilt | drop shake and tilt (switches stay) |
   | `flutter_dynamic_icon_plus` | `1.4.1` | native | per-skin app icon | one icon for both skins |
   | `flutter_animate` | `4.5.2` | pure Dart | rack focus, flicker, flame, entrances | plain `AnimationController`s |
   | `swipeable_page_route` | `0.4.8` | pure Dart | iOS back swipe | `CupertinoPageRoute` |
   | `custom_refresh_indicator` | `4.0.2` | pure Dart | pull to reprint | `RefreshIndicator` with a painter |
   | `flutter_reorderable_grid_view` | `5.7.0` | pure Dart | manual order in walls | list-mode reordering only |

   Comments on the two version holds, copied from the ledgers: `flutter_soloud` 4.1.7 for **both** skins, because glass §15.11's 5.1.4 needs `native_toolchain_c ^0.19.4`, which needs `meta ^1.19.0`, and Flutter 3.44.6 pins `meta` 1.18.0 (revisit with the Flutter upgrade, stack risk 10); `share_plus` 12.0.2 for both skins, because 13.x needs `win32 ^6` while `package_info_plus` 8.x, `file_picker` 8.x and `flutter_secure_storage` 9.x pin `win32 ^5`.
   **Not added:** `phosphor_flutter`. The plan entry names it, but `IconData` is a `final class` in this SDK (`/srv/manhwamaniacs/dev/flutter/packages/flutter/lib/src/widgets/icon_data.dart` line 23) and 2.1.0 subclasses it, so it cannot compile; both skins use the bundled Phosphor TTFs and generated constants of shared/02 (glass §2.7, §15.6, §15.11). `liquid_glass_widgets` is **not** added here either: it gets its own isolated commit in mobile/03 (the Glass device gate).
2. `cd mobile && flutter pub get` (after `free -m`), then save `flutter pub deps --style=compact` to `docs/redesign/proof/mobile-02/pub-deps.txt`. Confirm `meta 1.18.0`, `win32 5.x` and `go_router 14.8.1` are unchanged in `pubspec.lock`. If resolution fails, replace the failing package with its fallback from the table (drop the pin, note it), never force it.
3. `.github/workflows/tests.yml`: a new job after `mobile`, so both the standalone run and the copy `ios-build.yml` calls through `workflow_call` build it:

   ```yaml
     android-apk:
       # The Android half of the native-plugin gate (cinematic §15.11): an NDK,
       # manifest or Gradle break in flutter_soloud, audio_service or
       # flutter_dynamic_icon_plus must surface here, not at release time in
       # ops/vps/push.sh. Unsigned keys: build.gradle.kts falls back to the
       # debug signing config when key.properties is absent, which is enough.
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v4
         - uses: actions/setup-java@v4
           with:
             distribution: temurin
             java-version: '17'
         - uses: subosito/flutter-action@v2
           with:
             flutter-version: '3.44.6'
             channel: stable
             cache: true
         - name: Resolve packages
           working-directory: mobile
           run: flutter pub get && flutter pub deps --style=compact
         - name: Release APK (check build)
           working-directory: mobile
           run: flutter build apk --release
   ```

   Update the header comment's job list to mention it. Do not change `ios-build.yml`: its `build-ios` job is the iOS dry run and already runs `pod install` and `flutter build ios --release --no-codesign` on every push.
4. Commit `mobile/pubspec.yaml`, `mobile/pubspec.lock`, `.github/workflows/tests.yml` and `docs/redesign/proof/mobile-02/pub-deps.txt` alone, push, and **wait for CI**: the `tests` workflow (jobs `backend`, `frontend`, `mobile`, `android-apk`) and the `Build iOS (unsigned, for sideload)` workflow's `build-ios` job must all be green for this commit before section B starts. Record the run ids and conclusions in `docs/redesign/proof/mobile-02/dependency-gate.md` (package, pin, `flutter pub get` result, APK job result, iOS job result, any fallback taken). If a native job fails, read its annotations (see Verification), apply that package's fallback in a new commit, and repeat until green.

### B. `audio_service` wiring (cinematic §8.16.10, §15.10 S14), after A is green

5. `mobile/android/app/src/main/kotlin/com/manhwamaniacs/reader/MainActivity.kt`: `import com.ryanheise.audioservice.AudioServiceActivity` and `class MainActivity : AudioServiceActivity()`. Everything else stays: `configureFlutterEngine` (the native channel, `OcrChannel`), `onCreate`, `onResume`, `onDestroy`, `dispatchKeyEvent`, the display-mode code. `AudioServiceActivity` provides a cached engine; `configureFlutterEngine` still runs on every attach, and `onDestroy` already clears the handlers, so re-attaching re-registers them. Keep the class comment and add one line about why it extends `AudioServiceActivity`.
6. `mobile/android/app/src/main/AndroidManifest.xml`: add `xmlns:tools="http://schemas.android.com/tools"` on `<manifest>`; the permissions `android.permission.WAKE_LOCK`, `android.permission.FOREGROUND_SERVICE`, `android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK` and `android.permission.VIBRATE` (glass §5.1); inside `<application>`:

   ```xml
   <service android:name="com.ryanheise.audioservice.AudioService"
       android:foregroundServiceType="mediaPlayback"
       android:exported="true" tools:ignore="Instantiatable">
     <intent-filter><action android:name="android.media.browse.MediaBrowserService" /></intent-filter>
   </service>
   <receiver android:name="com.ryanheise.audioservice.MediaButtonReceiver"
       android:exported="true" tools:ignore="Instantiatable">
     <intent-filter><action android:name="android.intent.action.MEDIA_BUTTON" /></intent-filter>
   </receiver>
   ```

   (`WAKE_LOCK` is in `audio_service` 0.18.19's own setup instructions beside the two foreground-service permissions of §8.16.10.) iOS already declares `UIBackgroundModes: audio` in `Info.plist`; nothing changes there.
7. `mobile/lib/features/novels/services/narration_audio_handler.dart`: `class NarrationAudioHandler extends BaseAudioHandler with SeekHandler {}` with no player attached yet (its playback state stays idle, so no notification ever appears). mobile/15 moves narration onto it. `mobile/lib/features/novels/providers/narration_audio_handler_provider.dart`: `final audioHandlerProvider = Provider<NarrationAudioHandler>((ref) => throw StateError('audioHandlerProvider is overridden in main()'));`.
8. `mobile/lib/main.dart`, before `runApp(AppRestart(…))` and never inside its builder (it asserts it runs once per engine, and a skin switch restarts inside the same engine): `final handler = await AudioService.init(builder: NarrationAudioHandler.new, config: AudioServiceConfig(androidNotificationChannelId: 'com.manhwamaniacs.reader.listen', androidNotificationChannelName: 'Listen', androidNotificationIcon: <icon>, notificationColor: Color(0xFFF4D03F)));` where `<icon>` is `'drawable/ic_stat_mm'` if `ls mobile/android/app/src/main/res/drawable*/ic_stat_mm*` finds the file (shared/04 creates it), otherwise `'mipmap/ic_launcher'` with the comment `// mobile/15 switches to drawable/ic_stat_mm (shared/04).`. Add `audioHandlerProvider.overrideWithValue(handler)` to the `ProviderScope` overrides inside the builder.
9. Commit (`feat(mobile): audio_service wiring with an idle narration handler`), push, and wait for `android-apk` and `build-ios` to be green again before C.

### C. `mm/platform` and `skins/skin_haptics.dart`

10. **Android** `mobile/android/app/src/main/kotlin/com/manhwamaniacs/reader/MmPlatformChannel.kt` (a new file beside `OcrChannel.kt`, created and disposed from `MainActivity` exactly like `OcrChannel`), channel `mm/platform`:
    - `haptics.perform {pattern}` → `window.decorView.performHapticFeedback(constant)` with glass §5.1's table and SDK guards: `selection` → `SEGMENT_TICK` on API ≥ 34, else `CLOCK_TICK`; `soft`, `light` → `VIRTUAL_KEY`; `medium` → `LONG_PRESS`; `heavy` → `CONTEXT_CLICK`; `rigid` → `GESTURE_THRESHOLD_ACTIVATE` on ≥ 34, else `CONTEXT_CLICK`; `rigidBack` → `GESTURE_THRESHOLD_DEACTIVATE` on ≥ 34, else `VIRTUAL_KEY`; `toggleOn` → `TOGGLE_ON` on ≥ 34, else `VIRTUAL_KEY`; `toggleOff` → `TOGGLE_OFF` on ≥ 34, else nothing; `dragStart` → `DRAG_START` on ≥ 34, else `VIRTUAL_KEY`; `success` → `CONFIRM` on ≥ 30, else `VIRTUAL_KEY`; `warning` → `KEYBOARD_TAP`; `error` → `REJECT` on ≥ 30, else `LONG_PRESS`. Returns `true` when performed.
    - `haptics.oneShot {ms, amplitude}` → on API ≥ 26 `VibrationEffect.createOneShot(ms, amplitude)` through `VibratorManager` (API ≥ 31) or `Vibrator`; below 26, `false`.
    - `haptics.systemEnabled` → `Settings.System.getInt(contentResolver, Settings.System.HAPTIC_FEEDBACK_ENABLED, 1) == 1`.
    - anything else → `notImplemented()`. (mobile/25 adds `a11y.*`, `audio.isMusicActive` and `gestures.setExclusionRects` to this same channel.)
11. **iOS** `mobile/ios/Runner/AppDelegate.swift` (in this file, never a new Swift file: adding one means editing `project.pbxproj`, which nobody here can dry-run; the file's header explains this): a third channel `mm/platform` registered in `didInitializeImplicitFlutterEngine` like `mm/ocr`, with `import AVFoundation`:
    - `haptics.impact {style: "soft"|"light"|"medium"|"heavy"|"rigid", intensity: 0…1}` → `let g = UIImpactFeedbackGenerator(style: …); g.prepare(); g.impactOccurred(intensity: CGFloat(intensity))`;
    - `haptics.systemEnabled` → `true`;
    - `audio.category` → `AVAudioSession.sharedInstance().category.rawValue` (for the §15.8 device pass);
    - anything else → `FlutterMethodNotImplemented`.
12. `mobile/lib/skins/skin_haptics.dart`:
    - `HapticPattern.parse(String)` for the shared/00 grammar: primitive name; `:0.4` literal intensity; `:velocity`; `:velocity<=0.5`; `ahap:<name>`; `ahap:<name>{depth}`; `none`. Invalid strings throw `FormatException` (the generator validated them, so this is a bug trap).
    - `abstract interface class HapticsDriver { Future<void> named(HapticsType type); Future<void> ahap(String json); Future<void> impact(String style, double intensity); Future<bool> perform(String pattern); Future<bool> oneShot(int ms, int amplitude); Future<bool> systemEnabled(); }` with `PlatformHapticsDriver` (the packages and `mm/platform`) and a recording fake for tests.
    - `class SkinHaptics { SkinHaptics({required SkinId skin, required Map<HapticEvent, List<HapticStep>> map, required bool enabled, HapticsDriver? driver, AssetBundle? bundle}); Future<void> fire(HapticEvent event, {double velocity = 0, int depth = 1}); }`.
    - **Gate:** nothing fires when `enabled` is false. `enabled` is today's device-wide `hapticFeedbackProvider` (`settings_haptic_feedback`, default on). The plan entry says "per-profile", but cinematic §5 ("Scope: the Haptic feedback switch is per device … because it describes the hardware in the hand") and glass §5 ("per device, default on") both make it per device, so keep the existing device key; say so in the report.
    - **Steps:** the first step fires at once; each later `HapticStep` fires `afterMs` after the previous one through a `Timer` (`chapter.complete`: `medium`, then `light` 120 ms later; Cinematic `streak.milestone`: `ahap:ignite`, then `ahap:stamp` 520 ms later); a repeat step fires `maxRepeats` times `repeatEveryMs` apart (Glass `nav.root`, 40 ms, at most 4). A new `fire` does not cancel a running sequence.
    - **Velocity:** `:velocity` → `i = clamp(0.3 + |v| / 4000, 0.3, 1.0)`; `:velocity<=c` → `min(i, c)` (glass §5.1). **Depth:** `ahap:rise{depth}` → `rise<depth>` with depth clamped 1–4.
    - **AHAP:** loads `assets/haptics/<skin>/<name>.ahap.json` with `rootBundle.loadString` once per name (cached) and plays it with `Gaimon.patternFromData(json)` on both OSes.
    - **Routing** (per skin and platform):

      | Pattern | iOS, both skins | Android, Cinematic | Android, Glass |
      |---|---|---|---|
      | plain `selection light medium heavy rigid soft success warning error` | `Haptics.vibrate(HapticsType.<name>)` | `Haptics.vibrate(HapticsType.<name>)` (Vibrator effects, cinematic §5) | `mm/platform haptics.perform` |
      | with a literal intensity (`soft:0.4`, `rigid:0.6`) | `mm/platform haptics.impact {style, intensity}` | `Haptics.vibrate(HapticsType.<name>)` | `haptics.perform` (the constant, glass §5.1 "literal intensity") |
      | `:velocity` forms | `haptics.impact` with the computed intensity | `Haptics.vibrate(HapticsType.<name>)` | `haptics.oneShot {ms: 12, amplitude: round(i × 255)}`, falling back to `haptics.perform` when it returns false (API < 26) |
      | `toggleOn` / `toggleOff` / `rigidBack` | `haptics.impact` rigid 0.5 / soft 0.4 / soft 0.3 | `HapticsType.medium` / `light` / `light` | `haptics.perform` |
      | `dragStart` | `HapticsType.light` | `HapticsType.light` | `haptics.perform` |
      | `ahap:*` | `Gaimon.patternFromData` | same | same |

    - **Android system setting:** read `haptics.systemEnabled` once per `SkinHaptics` instance; when it is false, skip every vibrator-path call (`Gaimon`, `oneShot`, and `haptic_feedback` on Android). `performHapticFeedback` honours the setting on its own (glass §5.1 "Permission and system setting").
    - Glass's rate limits (ticks one per 40 ms, impacts one per 120 ms, keep the strongest of a burst) and texture thinning belong to `skins/glass/haptics.dart`, built with the Glass shell (mobile/29); do not add them here.
    - `final skinHapticsProvider = Provider<SkinHaptics>((ref) => SkinHaptics(skin: ref.watch(skinIdProvider), map: ref.watch(skinProvider).haptics, enabled: ref.watch(hapticFeedbackProvider)));`. The legacy skin's map is empty, so legacy keeps calling its old `core/utils/haptics.dart` helper exactly as today.
13. Commit the Kotlin, Swift and Dart parts (`feat(mobile): mm/platform channel and skin haptics`), push, and wait for `android-apk` and `build-ios` to be green.

### D. `skins/skin_audio.dart`, the sound layer and the audio session owner

14. `mobile/pubspec.yaml` `flutter: assets:` gains `assets/haptics/cinematic/`, `assets/haptics/glass/`, `assets/sounds/cinematic/` and `assets/sounds/glass/` (shared/01 and shared/03 created the files).
15. `mobile/lib/skins/skin_audio.dart`:
    - `enum AudioSessionState { idle, narration, voiceSample, soundscape }` with exactly these configurations (cinematic §6 table; glass §6 table): `idle` (State A) = `AudioSessionConfiguration(avAudioSessionCategory: AVAudioSessionCategory.ambient, avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers)`; `narration` (State B) = `AudioSessionConfiguration.speech()` (the constant in `features/novels/utils/novel_audio_session.dart`, reused); `voiceSample` = `.playback` with `.duckOthers`, Android usage media, content type speech, `androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck`, activated with `setActive(true)` and returned to the previous state (and `setActive(false)`) when the sample ends; `soundscape` (Glass only) = `.playback` with `.mixWithOthers` and no focus request.
    - `class SkinAudio` with an injectable `SessionConfigurator` (defaults to `AudioSession.instance` → `configure`) and an injectable `CueEngine` interface (defaults to `flutter_soloud`: `init`, `loadAsset`, `play(source, volume:)`, `setRelativePlaySpeed`), so tests never touch a platform channel:
      - `Future<void> start()` from `main()` (unawaited, never delaying the first frame): configure `idle`. This **replaces** the `unawaited(configureNovelAudioSession())` call in `main.dart` (cinematic §6: "The app's startup call to `configureNovelAudioSession()` … is replaced by State A"); delete that call and keep the file's constant.
      - `Future<void> request(AudioSessionState state)`; `beginVoiceSample()` / `endVoiceSample()`; `void setSoundscapeActive(bool)` (Cinematic's soundscape plays in State A, so it only suppresses cues); `bool get cuesSuppressed` = state is `narration` or `soundscape`, or a soundscape is active, or the app is not resumed.
      - Sound preferences: **Cinematic per profile** in SharedPreferences key `mm.sounds.u{userId}p{profileId}` = `{"on": false, "volume": 60}` (0–100 %, default 60); **Glass per device** in `mm.sounds.glass` = `{"on": false, "volumeDb": -6}` (−24 to 0 dB, default −6). Gain for the engine: Cinematic `volume / 100`; Glass `pow(10, volumeDb / 20)`. `readSoundPrefs(skin)` and `writeSoundPrefs(skin, …)`; nothing is loaded and `flutter_soloud` is never initialised while sounds are off.
      - First enable (or launch with sounds on): `await engine.init()`, then **re-apply the current session configuration** (State A when idle), because `SoLoud.instance.init()` sets no category but the §15.8 device pass must read `.ambient` right after it; then load every cue of the running skin from `<skin>SoundCues` (13 Cinematic files, ≤ 384 KB; Glass's set ≤ 320 KB).
      - `void play(SoundEvent event, {int depth = 1, double rate = 1.0})`: no-op when off, when `cuesSuppressed`, or when the event maps to an empty list; otherwise play the cue (`nav.push` takes entry `depth − 1` of its four, glass §6; everything else the first entry) at the skin's gain, with `setRelativePlaySpeed(handle, rate)` when `rate != 1.0` (Glass's velocity and scrub pitch, mobile/29).
    - Ownership: the audio session is process-wide and a skin restart must not reset it, so `SkinAudio.instance` is one process-wide object (tests build `SkinAudio.forTest(configurator, engine)`). `main` calls `SkinAudio.instance.start()` once, before `runApp`, unawaited. `final skinAudioProvider = Provider<SkinAudio>((ref) => SkinAudio.instance..bind(skin: ref.watch(skinIdProvider), userId: ref.watch(authControllerProvider.select((a) => a is AuthAuthenticated ? a.user.id : null)), profileId: ref.watch(activeProfileProvider.select((p) => p?.id)), prefs: ref.watch(sharedPrefsProvider)))`: `bind` sets the running skin and its preference key and loads that skin's cues when sounds are on; it never reconfigures the session.
16. Narration hook (the one owner rule): in `mobile/lib/features/novels/widgets/novel_audio_player.dart`, `await ref.read(skinAudioProvider).request(AudioSessionState.narration)` before each `play()` call, and `request(AudioSessionState.idle)` in `dispose()` (State B holds while narration plays **or is paused inside the reader**, cinematic §6). Nothing else in that widget changes; narration sounds and behaves exactly as before (the same `speech()` configuration is active whenever it plays).
17. Commit (`feat(mobile): skin audio layer and the single audio session owner`), push, CI green.

### E. The Feedback lab (debug) and tests

18. `mobile/lib/features/settings/screens/feedback_lab_screen.dart` (legacy UI folder, deleted at the flip with legacy), pushed with `Navigator.of(context).push(MaterialPageRoute(…))` from a new row "Feedback lab (debug)" in the Diagnostics "Edition (debug)" section of mobile/01. Legacy styling. Content:
    - a `SegmentedButton<SkinId>` `CINEMATIC | GLASS` choosing which skin's maps to use (independent of the running skin; each segment ≥ 44 tall, padded tap targets);
    - a switch "Play sounds" (this screen only; it does not write the user's sound preference) and the system line "Haptics switch: on/off" (the device setting, read-only here);
    - one row per `HapticEvent` that is not `none` for the chosen skin: the event id (for example `chapter.complete`), its pattern string in a monospace face, a trailing play icon button (48 × 48, `Semantics` label "Play <event>"); tapping fires `SkinHaptics(skin: chosen, map: chosen map, enabled: true).fire(event, velocity: 2000, depth: 3)` and, when "Play sounds" is on, the matching sound;
    - iOS only: a line "Audio session category: <value of `mm/platform audio.category`>", refreshed after each play (the §15.8 check: it must read `AVAudioSessionCategoryAmbient`).
19. Tests:
    - `mobile/test/skins/skin_haptics_test.dart`: parser vectors (`soft:0.4`, `rigid:velocity`, `soft:velocity<=0.5`, `ahap:rise{depth}`, `none`, one invalid string); routing per the table with `debugDefaultTargetPlatformOverride` for iOS and Android and both skins, through the recording driver; the switch off → nothing; Android system haptics off → no `ahap`, `oneShot` or Android `named` calls; `chapter.complete` fires `medium` then `light` 120 ms later (`fakeAsync`); velocity 0 → 0.3, 1,000 → 0.55, 2,800 → 1.0, and `motion.catch` capped at 0.5; `nav.push` at depth 3 loads `assets/haptics/glass/rise3.ahap.json`; every non-`none` pattern in `cinematicHaptics` and `glassHaptics` parses.
    - `mobile/test/skins/skin_audio_test.dart` (fake configurator and engine): `start()` configures `idle`; sounds off → `init` never called; enabling calls `init` once and re-applies the current configuration right after; `play` is suppressed in `narration`, in `soundscape`, and with a Cinematic soundscape active; `tap.primary` in Cinematic plays the `set` cue's asset; Glass `nav.push` at depth 3 plays `push-3`; Cinematic preferences are scoped per profile (two profiles, two keys) and Glass's are per device; gain 60 % → 0.6 and −6 dB → 0.501; `beginVoiceSample` / `endVoiceSample` return to the previous state.
    - `mobile/test/android/audio_service_manifest_test.dart`: `MainActivity.kt` contains `class MainActivity : AudioServiceActivity()`; the manifest has the service, the receiver, the four permissions and `enableOnBackInvokedCallback`.
    - `mobile/test/audit/pubspec_pins_test.dart`: every package of item 1 is pinned exactly; `phosphor_flutter` and `dependency_overrides` are absent; `liquid_glass_widgets` is absent until mobile/03 (the test reads a constant list, and mobile/03 updates it).
    - `mobile/test/features/settings/feedback_lab_test.dart`: rows render for both skins; tapping a row calls the recording driver; the play buttons are 48 × 48. With `MM_PROOF_DIR` set, writes `legacy-feedback-lab-cinematic-390x844.png` and `legacy-feedback-lab-glass-390x844.png` through `writeShot()`.

## File layout (create or change; nothing else)

```
mobile/pubspec.yaml, mobile/pubspec.lock                                   change (A; D assets)
.github/workflows/tests.yml                                                change (android-apk job)
mobile/android/app/src/main/AndroidManifest.xml                            change (B)
mobile/android/app/src/main/kotlin/com/manhwamaniacs/reader/MainActivity.kt   change (B, C)
mobile/android/app/src/main/kotlin/com/manhwamaniacs/reader/MmPlatformChannel.kt   new (C)
mobile/ios/Runner/AppDelegate.swift                                        change (C)
mobile/lib/main.dart                                                       change (AudioService.init, SkinAudio.start)
mobile/lib/features/novels/services/narration_audio_handler.dart           new
mobile/lib/features/novels/providers/narration_audio_handler_provider.dart new
mobile/lib/features/novels/widgets/novel_audio_player.dart                 change (session requests only)
mobile/lib/skins/skin_haptics.dart, skin_audio.dart                        new
mobile/lib/features/settings/screens/feedback_lab_screen.dart              new
mobile/lib/features/settings/screens/diagnostics_screen.dart               change (one row)
mobile/test/skins/{skin_haptics,skin_audio}_test.dart                      new
mobile/test/android/audio_service_manifest_test.dart                       new
mobile/test/audit/pubspec_pins_test.dart                                   new
mobile/test/features/settings/feedback_lab_test.dart                       new
docs/redesign/plans/mobile-02.md                                           new
docs/redesign/proof/mobile-02/{pub-deps.txt,dependency-gate.md,device-check.md,*.png}   new
```

## Acceptance criteria

- [ ] The dependency commit contains only `pubspec.yaml`, `pubspec.lock`, `tests.yml` and the proof text, and CI was green for it (tests: `backend`, `frontend`, `mobile`, `android-apk`; iOS: `build-ios`) before any commit that imports a new package; run ids are in `dependency-gate.md`.
- [ ] Every package of item 1 is pinned exactly, or replaced by its ledger fallback with the reason recorded; `phosphor_flutter` and `dependency_overrides` are absent; `meta` stays 1.18.0 and `win32` 5.x.
- [ ] `MainActivity` extends `AudioServiceActivity`; the manifest carries the service, the receiver and the permissions; `AudioService.init` runs once, before `runApp`, and the handler reaches the tree through `audioHandlerProvider`.
- [ ] `flutter analyze`: no issues. `flutter test`: 0 failed; the count is at least your pre-change count plus the new tests; everything that passed before still passes.
- [ ] Legacy parity: a legacy user sees no change except the "Feedback lab (debug)" row; the legacy haptics helper is untouched; narration still plays in the background with the screen locked (device check).
- [ ] Haptics honour the device "Haptic feedback" switch; a sequence plays with its `afterMs` gaps; velocity and depth rules match glass §5.1.
- [ ] UI sounds are off by default, `flutter_soloud` is not initialised while they are off, cues are suppressed during narration and soundscapes, and State A is re-applied right after init.
- [ ] Hit targets: every Feedback lab control is ≥ 44 pt (iOS) / 48 dp (Android).
- [ ] Reduced motion: nothing in this step animates; haptics and sounds do not depend on the reduce-motion setting (glass §5: haptics stay on under Reduce Motion).
- [ ] Per-skin differences: Cinematic's Android impacts go through `haptic_feedback` and Glass's through `mm/platform`; Cinematic sound preferences are per profile (0–100 %, default 60 %) and Glass's per device (−24 to 0 dB, default −6 dB); each skin plays only its own cue set and AHAP folder.
- [ ] Hardware keyboard: the Feedback lab's segmented control, switch and play buttons are reachable with Tab and show focus.

## Verification

```bash
cd /srv/manhwamaniacs/dev/ManhwaManiacs/mobile
F=/srv/manhwamaniacs/dev/flutter/bin/flutter
free -m && $F test 2>&1 | tail -3        # BEFORE any change: record the count
free -m && $F pub get && $F pub deps --style=compact > ../docs/redesign/proof/mobile-02/pub-deps.txt
free -m && $F analyze                    # baseline: No issues found!
free -m && $F test test/skins test/android test/audit test/features/settings test/features/novels
free -m && $F test 2>&1 | tail -3        # full suite, 0 failed
free -m && MM_PROOF_DIR=../docs/redesign/proof/mobile-02 $F test test/features/settings/feedback_lab_test.dart
```

Stop under 1,024 MB available; never alongside a `next build` (`pgrep -fa "next build"`); never `flutter build` here. Web and backend code do not change in this step; the CI `frontend` and `backend` jobs must stay green on every pushed commit (they run in the same `tests` workflow).

**Reading CI.** If `command -v gh` works: `gh run list --branch feat/vps-slim-source-native --limit 6` and `gh run view <id> --log-failed`. Otherwise the anonymous API, at most once every 5 minutes (60 requests per hour per IP, shared with production's `mm-fetch-ios` timer on this box):

```bash
curl -s "https://api.github.com/repos/yash-dhanda/ManhwaManiacs/actions/runs?branch=feat/vps-slim-source-native&per_page=6" \
 | python3 -c "import json,sys; [print(r['id'], r['head_sha'][:7], r['name'], r['status'], r['conclusion']) for r in json.load(sys.stdin)['workflow_runs']]"
curl -s "https://api.github.com/repos/yash-dhanda/ManhwaManiacs/actions/runs/<run_id>/jobs" \
 | python3 -c "import json,sys; [print(j['id'], j['name'], j['status'], j['conclusion']) for j in json.load(sys.stdin)['jobs']]"
curl -s "https://api.github.com/repos/yash-dhanda/ManhwaManiacs/check-runs/<job_id>/annotations"   # a failed job's messages
```

Wait between checks with a background loop (`sleep 300` inside a script run in the background) or the Monitor tool, never a foreground sleep. A runner-side failure (`ENOTFOUND`, `Request timeout` on the Actions cache or artifact upload) is GitHub, not your code: push an empty commit only if the owner agrees, otherwise re-check later.

**Visual proof.** Open the two Feedback lab PNGs in `docs/redesign/proof/mobile-02/`.

**Owner device checklist** (`docs/redesign/proof/mobile-02/device-check.md`, run on the iPhone build CI publishes and on the Android flagship's next signed build): Feedback lab → CINEMATIC: `tap.primary` (impress), `follow.add` (stamp), `reader.enter` (wipe), `streak.milestone` (ignite, then stamp 520 ms later), `chapter.complete` (medium, then light) all feel distinct; GLASS: `nav.push` (rise3), `threshold.cross` (rigid 0.6), `motion.catch` (soft, capped), `profile.select` (droplet) feel crisp and light; with the system haptics setting off on Android, nothing vibrates; "Play sounds" on: Cinematic `tap.primary` plays `set`, Glass `nav.push` plays `push-3`; iOS "Audio session category" reads `AVAudioSessionCategoryAmbient` after the first sound and the ring/silent switch mutes cues; start a narration in a novel, lock the phone: it keeps playing (State B) and music apps pause as before; Android: back out of the app from the Library root and reopen it: it opens normally (the `AudioServiceActivity` engine is cached, which can resume the previous state instead of cold-starting; note what you see).

## Git

- Branch `feat/vps-slim-source-native`. Commits: plan; A (dependency commit, alone); B; C; D; E (lab and tests); proof. Push after each and wait for the CI gates described in A, B and C. A green push also publishes the iPhone build through `ios-build.yml`.
- Stage explicit paths only; never `git add -A`, `git add .` or `git commit -a`.
- No Claude or AI attribution anywhere (no `Co-Authored-By`, no "Generated with" line). Never commit secrets, `key.properties`, keystores, `.env*` or `.claude/`.

## Guardrails

- Never edit `backend/connectors/`, `frontend/`, `design/`, generated files, or anything under `/srv/manhwamaniacs/{app,data}`; no Docker commands; never touch production containers.
- Never force a dependency (`dependency_overrides`, `--legacy-peer-deps`, a git or path dependency); use the ledger fallback.
- RAM guard: `free -m` before every pub get, analyze and test; stop under 1,024 MB available; one heavy command at a time; never Gradle or Xcode here.

## Report back

Reply with:
1. Done items by section (A–E) with commit hashes, and the CI run ids and conclusions for each gate (dependency commit, audio_service wiring, `mm/platform`).
2. Resolved versions of every new package (from `pub-deps.txt`) and any fallback taken, with the failing job's annotation.
3. The deviations you applied and why: no `phosphor_flutter`; the haptics switch per device, not per profile; `WAKE_LOCK` and `VIBRATE` added; the notification icon you used.
4. Test counts before and after (passed / failed / skipped) and the `flutter analyze` result.
5. The proof folder `docs/redesign/proof/mobile-02/` (PNGs, `pub-deps.txt`, `dependency-gate.md`, `device-check.md`).
6. The lowest `free -m` available figure you saw and open issues.

Next prompt in the mobile track: `docs/redesign/prompts/mobile/03-foundation-fonts-icons-harness-glass-gate.md` (it also needs `shared/02` done). Next in the global order: `docs/redesign/prompts/web/03-foundation-reader-seam-limiter-proof.md`.
