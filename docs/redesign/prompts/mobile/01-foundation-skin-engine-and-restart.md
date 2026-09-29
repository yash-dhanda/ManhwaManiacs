# Mobile foundation 01: Skin interface, AppRestart and the restart-to-switch mechanics

## Goal

Give the Flutter client (`mobile/`, Flutter 3.44.6, Riverpod 2.6.1, go_router 14.8.1) the skeleton that lets three skins live side by side on one data layer, and the machinery that switches between them by restarting the app. You add the `Skin` interface and the `SkinId` enum; a `legacy` skin that wraps today's `app_router.dart` and `AppTheme` unchanged; `cinematic` and `glass` skeleton skins whose routers cover every `ScreenId` of the generated contract through a `PENDING` set that maps to one skin-neutral pending screen; `AppRestart`, whose builder re-reads the boot state so a restart lands in the new skin on the same page; `SkinBoot` in `main.dart` (the `mm.skin.*` SharedPreferences keys); boot resolution steps 1–5 with a queued offline `PATCH` winning over the server's `profile.skin`; `switchSkin()` (outbox `PATCH`, device mirror, the `mm.skin.t0` timestamp, restart in under 1.5 s); the pre-flip debug row "Edition (debug)" in Settings → Diagnostics; the import-boundary and completeness tests; and `android:enableOnBackInvokedCallback="true"`. A legacy user sees nothing new except that debug row: same screens, same pixels, same behaviour. Cinematic and Glass are reachable only through the debug row until their own steps fill them in, and the flip (release/00) removes `legacy`.

## Read first

Read these before you plan. Section numbers are binding.

1. `docs/redesign/stack-decision.md` §2.3 (mobile folder layout; `app_restart.dart`, `skin_app.dart`, `skins/skin.dart`, `skins/legacy/legacy_skin.dart`; boundary and completeness tests), §2.4 (skin per profile, device mirror, return route, boot resolution steps 1–5), §2.5 "Mobile" steps 1–8 (restart to switch; budget under 1.5 s; downloads resume), §3 "Release model".
2. `docs/redesign/cinematic/DESIGN.md`:
   - §8.0.3 (the route contract: every ScreenId and path, mobile aliases, `setup` app-only, `readerLanding` registered on the app as a redirect to `/library`; static `/library/…` paths before `/library/:followedId`; encoded route builders),
   - §8.0.5 "System bars" row (the transparent `edgeToEdge` overlay style) and the Android predictive-back rule,
   - §8.0.7 (the `glass_available` flag; "The pre-flip debug row": `LEGACY │ CINEMATIC`, the `mm.skin.debug` device override read before the profile comparison, the 200 ms `dur.clip` fade to black, never writes `reading_profiles.skin`),
   - §8.2 "Outcomes" (a mismatched remembered profile: cut, 200 ms of `#000000`, restart, no confirm, no undo; a queued outbox `PATCH` wins),
   - §8.30.3 mechanics only: the "Outgoing sequence" rows t = 0 and "500, app", "The switch waits for the server" (the mobile half), "Budget and misses", "The restart re-reads the boot state" (the `main.dart` sketch, `SkinBoot.read`, `initialLocation`),
   - §15.9 "`SKIN RESTART`" bullet, §15.10 rows S5, S12, S15.
3. `docs/redesign/glass/DESIGN.md` §15.3 "Shader prewarm" bullet (every skin has a `prepare()` awaited before its router is built, from `main()` and from the restart path) and "Boundary and completeness" bullet, §15.6 first bullet (routes and screen ids are shared), §15.10 G7 and G13.
4. `docs/redesign/inventory/00-decisions.md` (the user picks a skin in Settings; the app restarts; everything changes).
5. `docs/redesign/inventory/mobile.md` §1 (today's routes), S02 (splash), S05 (profile picker), S34 (Diagnostics), G5–G7, §5c (internal persisted state that must survive).
6. `docs/redesign/00-baseline.md`.
7. The mirror of this step on the web, for vocabulary: `docs/redesign/prompts/web/00-foundation-skin-engine-and-routes.md` §B (pending screen, `PENDING`) and `docs/redesign/prompts/web/02-foundation-restart-haptics-sound.md` §B–§D (`switchSkin`, `resolveBootSkin`, the debug row, the 10-second loop guard).
8. Upstream outputs (read, never hand-edit): `mobile/lib/skins/contract.g.dart` (`enum ScreenId` with `.id` and `.path`, `abstract final class Routes` with patterns, alias patterns and encoding builders, `Flags.glassAvailable`, `enum HapticEvent`, `enum SoundEvent`), `mobile/lib/skins/token_types.g.dart`, `mobile/lib/skins/cinematic/tokens.g.dart` (`cinematicTokens`, `cinematicHaptics`, `cinematicSoundCues`, `cinematicSoundEvents`), `mobile/lib/skins/glass/tokens.g.dart` if present (`glassTokens`, `glassHaptics`, `glassSoundCues`, `glassSoundEvents`), `mobile/test/skins/generated_contract_test.dart`; `backend/routes/profiles.py` (backend/00 added `skin` to `PATCH /profiles/{id}`); the reader engine of mobile/00 (`mobile/lib/features/reader/engine/`) and `mobile/lib/features/downloads/providers/downloads_lifecycle_gate.dart` (moved there by mobile/00).
9. Today's code you wrap or change: `mobile/lib/main.dart`, `mobile/lib/app/app.dart`, `mobile/lib/app/router/{app_router,routes}.dart`, `mobile/lib/app/theme/{app_theme,app_theme_provider,theme_controller}.dart`, `mobile/lib/app/display/high_refresh_rate.dart`, `mobile/lib/features/profiles/{models/profile.dart,repositories/*,providers/profiles_providers.dart}`, `mobile/lib/features/settings/screens/diagnostics_screen.dart`, `mobile/lib/features/settings/widgets/whats_new_auto_show.dart`, `mobile/android/app/src/main/AndroidManifest.xml`, `mobile/test/support/test_overrides.dart`, and every test that pumps `ManhwaManiacsApp` (`grep -rln ManhwaManiacsApp mobile/test`).

## Preconditions (stop and report if any fails)

```bash
cd /srv/manhwamaniacs/dev/ManhwaManiacs
git branch --show-current                                               # feat/vps-slim-source-native
ls mobile/lib/features/reader/engine/reader_engine.dart                 # mobile/00 done
ls mobile/lib/features/downloads/providers/downloads_lifecycle_gate.dart   # mobile/00 section E done
ls mobile/lib/skins/contract.g.dart mobile/lib/skins/token_types.g.dart mobile/lib/skins/cinematic/tokens.g.dart   # shared/00 done
grep -n "glassAvailable" mobile/lib/skins/contract.g.dart               # Flags.glassAvailable = false
grep -n "skin" backend/routes/profiles.py | head -5                      # backend/00 done
ls mobile/lib/skins/glass/tokens.g.dart 2>/dev/null || echo "shared/01 not run: Glass skeleton gets no token extension"
```

If `contract.g.dart` is missing, shared/00 has not run; if `profiles.py` has no `skin`, backend/00 has not run; if the engine is missing, mobile/00 has not run. Report which and stop.

## Skills to invoke

- `superpowers:writing-plans` first. Save the plan at `docs/redesign/plans/mobile-01.md`.
- `superpowers:subagent-driven-development` to run it (or `superpowers:executing-plans` inline). Slices: (A) skin types and skeleton skins; (B) boot, restart and switch; (C) outbox and profile field; (D) debug row; (E) tests and manifest. B depends on A; give each subagent this file's path and its section. Verify every slice against `git status` and `git diff`, never against a report.
- `superpowers:test-driven-development` for `SkinBoot.read`, `resolveBootRestart`, the outbox, `switchSkin` ordering and the restart timing (write each test first).
- `impeccable` and `taste-skill:taste-skill` only for the one new visible element, the pending screen: keep it plain, skin-neutral and silent.
- `superpowers:verification-before-completion` before you claim anything is done.

## Track rules (every mobile step)

- Work in `mobile/` only, plus `docs/redesign/plans/` and `docs/redesign/proof/mobile-01/`. Never touch `frontend/`, `backend/` (never `backend/connectors/`), `design/` sources, or generated `*.g.dart` files (regenerate with `node design/build.mjs` only if the contract is wrong, and then report it instead of committing it).
- Stage only your own paths with explicit `git add <path>`; never `git add -A`, `git add .` or `git commit -a`.
- Flutter is `/srv/manhwamaniacs/dev/flutter/bin/flutter`; `flutter analyze` and `flutter test` only after `free -m`, one at a time, never while a `next build` runs.
- No Gradle and no Xcode here: never run `flutter build`.
- Remove every `ScreenId` you finish from its skin's `PENDING` set. This step finishes none: both sets hold every id.

## Scope, item by item

### A. The Skin interface and the three skins

1. `mobile/lib/skins/skin.dart`:

   ```dart
   enum SkinId { cinematic, glass, legacy }
   SkinId? skinIdFromName(String? name);         // exact enum name, else null
   const SkinId kDefaultSkin = SkinId.legacy;    // release/00 changes this to SkinId.cinematic and deletes legacy.
   const List<SkinId> kDebugSkins = [SkinId.legacy, SkinId.cinematic];   // mobile/25 adds SkinId.glass.

   abstract interface class Skin {
     SkinId get id;
     ThemeData theme(WidgetRef ref);                         // legacy watches its palette and preset providers
     SystemUiOverlayStyle overlayStyle(WidgetRef ref);
     GoRouter buildRouter(Ref ref);                          // called once per ProviderScope
     Widget wrap(BuildContext context, Widget child);        // skin-specific wrappers under MaterialApp.builder
     Widget splash(BuildContext context);                    // the skin's first frame after the black native frame
     Map<HapticEvent, List<HapticStep>> get haptics;         // generated maps; legacy: const {}
     Map<SoundEvent, List<String>> get soundEvents;          // generated maps; legacy: const {}
     Map<String, String> get soundCues;                      // cue → asset path; legacy: const {}
     Future<void> prepare();                                 // awaited before the router is built; no-op here, Glass's loads its shaders in mobile/03
   }
   ```

   `mobile/lib/skins/skins.dart`: `Skin skinFor(SkinId id)` returning one `const` instance per id; `final skinIdProvider = Provider<SkinId>((ref) => SkinId.legacy);` (overridden by `main`; the legacy default keeps every existing test that pumps the app unchanged); `final skinProvider = Provider<Skin>((ref) => skinFor(ref.watch(skinIdProvider)));`; `final skinRouterProvider = Provider<GoRouter>((ref) => ref.watch(skinProvider).buildRouter(ref));`; `final returnRouteProvider = Provider<String?>((ref) => null);`.
2. `mobile/lib/skins/legacy/legacy_skin.dart`: `theme(ref) => ref.watch(appThemeProvider)`; `overlayStyle(ref) => AppTheme.overlayStyleFor(ref.watch(themeControllerProvider))`; `buildRouter(ref) => ref.watch(appRouterProvider)`; `wrap(context, child) => WhatsNewAutoShow(child: child)`; `splash(context) => const SplashScreen()` (today's `features/auth/screens/splash_screen.dart`); empty haptic and sound maps; `prepare()` completes at once. `legacy` is the only skin allowed to import `app/theme/`, `app/router/` and `features/*/{screens,widgets}`.
3. `mobile/lib/app/router/app_router.dart`: one change, `initialLocation: ref.read(returnRouteProvider) ?? Routes.home`, so a restart into legacy lands on the page it left (the router is rebuilt on every auth transition and keeps using the same value for the life of this `ProviderScope`; the next restart or cold start clears it). Nothing else in the legacy router changes.
4. `mobile/lib/skins/pending_screen.dart`, the one skin-neutral screen for every unbuilt `ScreenId` of both new skins (the Flutter twin of web/00 item 4). It imports only `flutter/material.dart`, `flutter/services.dart`, `flutter_riverpod`, `contract.g.dart`, `skins.dart` and `app/switch_skin.dart`. `PendingScreen({required String screenId, required String location})` is a `ConsumerWidget` (it reads `skinIdProvider` for the kicker):
   - `Scaffold(backgroundColor: Color(0xFF000000))`, `SafeArea`, padding 24, one column of max width 560 centred both ways, gaps of 16;
   - kicker, 12 / 16 (height 1.333), `FontWeight.w600`, upper case, `letterSpacing` 1.92 (0.16 em), colour `Color(0xA3FFFFFF)` (64 %): `"${skinId.name.toUpperCase()} · NOT BUILT YET"`;
   - title, 28 / 34, `w600`, `Color(0xFFF5F5F5)`: the screen id;
   - paragraph, 16 / 24, `Color(0xA3FFFFFF)`: "This screen hasn't been built in this edition yet. It arrives in a later step of the redesign.";
   - the location in a monospace face (`fontFamily: 'Menlo'`, `fontFamilyFallback: ['monospace', 'Courier']`), 13 / 16;
   - a button "Leave the preview": minimum height 44 on iOS and 48 on Android (`defaultTargetPlatform`), horizontal padding 20, 1 px border `Color(0x66FFFFFF)` (40 %), transparent fill, radius 0, label 15 `w600`; pressed: border `Color(0xCCFFFFFF)` (80 %); keyboard focus (iPad or Android hardware keyboard): a 2 px `Color(0xFFFFFFFF)` outline 2 px outside the border, drawn from `WidgetState.focused`; `Semantics(button: true, label: 'Leave the preview')`. It calls `leavePreview(context, ref)` (item 12).
   - No animation of any kind, no haptic, no sound. The system font is used on purpose (skin-neutral).
   - The default text scale applies; at 2.0 nothing clips (the column scrolls in a `SingleChildScrollView`).
5. `mobile/lib/skins/cinematic/cinematic_skin.dart` and `mobile/lib/skins/cinematic/router.dart`:
   - `// ignore: constant_identifier_names` then `const Set<ScreenId> PENDING = {…every ScreenId.values entry…};`, written out as a literal, one id per line, so finishing a screen later is a one-line deletion. The name matches the web's `PENDING` on purpose: every later step finds it with `grep -rn "PENDING" mobile/lib/skins/<skin>`, and mobile/24 deletes it.
   - `GoRouter buildCinematicRouter(Ref ref)`: `initialLocation: ref.read(returnRouteProvider) ?? ScreenId.tonight.path`; one `GoRoute` per `ScreenId` in the contract's declaration order (the generator already puts static `/library/…` paths before `/library/:followedId`); `readerLanding` is `GoRoute(path: …, redirect: (_, __) => ScreenId.library.path)` (§8.0.3, S7); every other route builds `PendingScreen(screenId: id.id, location: state.uri.toString())` while the id is in `PENDING`. Register every mobile alias that `contract.g.dart` declares (read the file for its exact names; the aliases are those of §8.0.3's Notes column: `/profiles/create`, `/profiles/edit/:id`, `/collections…`, `/library/read/…`, `/sources/…/chapters/:chapterId/read`, `/novels/read/…`, `/ocr/search`) as routes to the same pending screen of their `ScreenId`. `errorBuilder` renders `PendingScreen(screenId: 'not-found', location: …)` (mobile/06 replaces it with the §8.32 status screen). No auth redirect yet; no shell.
   - `CinematicSkin`: `theme(ref)` returns `ThemeData(useMaterial3: true, brightness: Brightness.dark, scaffoldBackgroundColor: Color(0xFF000000), canvasColor: Color(0xFF000000), colorScheme: ColorScheme.dark(surface: Color(0xFF000000)), extensions: [cinematicTokens])`, built once and cached in a `static final`; `overlayStyle` returns `SystemUiOverlayStyle(statusBarColor: Color(0x00000000), statusBarIconBrightness: Brightness.light, statusBarBrightness: Brightness.dark, systemNavigationBarColor: Color(0x00000000), systemNavigationBarIconBrightness: Brightness.light, systemNavigationBarContrastEnforced: false)` (§8.0.5); `wrap` returns the child; `splash` returns `const ColoredBox(color: Color(0xFF000000))` (mobile/06 builds "Press start"); `haptics => cinematicHaptics`, `soundEvents => cinematicSoundEvents`, `soundCues => cinematicSoundCues`; `prepare()` completes at once.
6. `mobile/lib/skins/glass/glass_skin.dart` and `mobile/lib/skins/glass/router.dart`: the same shape with its own `PENDING` set in `glass/router.dart`, `buildGlassRouter`, `GlassSkin`, and `extensions: [glassTokens]` plus `glassHaptics`, `glassSoundEvents`, `glassSoundCues` when `mobile/lib/skins/glass/tokens.g.dart` exists (otherwise empty extensions and `const {}` maps, and say so in the report). `prepare()` completes at once in this step.

### B. Boot, restart and the switch

7. `mobile/lib/app/skin_boot.dart`:
   - keys, as constants: `kSkinActiveKey = 'mm.skin.active'`, `kSkinDebugKey = 'mm.skin.debug'`, `kSkinReturnKey = 'mm.skin.return'`, `kSkinT0Key = 'mm.skin.t0'`, `kSkinSessionKey = 'mm.skin.session'`, `kSkinBootRestartKey = 'mm.skin.boot-restart'`, `kSkinRestartLastKey = 'mm.skin.restart.last'`;
   - `SkinId SkinBoot.resolveSkin(SharedPreferences prefs)`, pure: `mm.skin.debug` when it names a valid `SkinId` (all three, `glass` included, because the debug row is how Glass is previewed later); else `mm.skin.active` when valid, with `glass` coerced to `cinematic` while `Flags.glassAvailable` is false (§8.0.7); else `kDefaultSkin`. Invalid strings are ignored;
   - `SkinId SkinBoot.resolveSkinWithoutDebug(SharedPreferences prefs)`: the same rules with the debug key skipped (what "Clear override" and "Leave the preview" restart into);
   - `SkinBoot SkinBoot.read(SharedPreferences prefs)` → `{skin, returnRoute, carrySession}`: `skin` from `resolveSkin`; `returnRoute` from `mm.skin.return`; `carrySession` true when `mm.skin.session == '1'`; it **removes** `mm.skin.return` and `mm.skin.session` after reading (S15).
8. `mobile/lib/app/app_restart.dart` (about 25 lines):

   ```dart
   class AppRestart extends StatefulWidget {
     const AppRestart({super.key, required this.builder});
     final Widget Function() builder;
     static AppRestartState of(BuildContext context) => context.findAncestorStateOfType<AppRestartState>()!;
     @override State<AppRestart> createState() => AppRestartState();
   }
   class AppRestartState extends State<AppRestart> {
     Key _key = UniqueKey();
     late Widget _child = widget.builder();
     void restart() => setState(() { _key = UniqueKey(); _child = widget.builder(); });
     @override Widget build(BuildContext context) => KeyedSubtree(key: _key, child: _child);
   }
   ```

   The key swap disposes every provider, the router and the caches; calling `builder()` again re-reads `SkinBoot` (a key swap alone would rebuild with the old overrides, §15.10 S15).
9. `mobile/lib/main.dart`: keep everything it does today; after `prefs` resolve, `await skinFor(SkinBoot.resolveSkin(prefs)).prepare();`, then

   ```dart
   runApp(AppRestart(builder: () {
     final boot = SkinBoot.read(prefs);
     return ProviderScope(
       overrides: [
         apiBaseUrlProvider.overrideWith((ref) => apiUrl),
         sharedPrefsProvider.overrideWithValue(prefs),
         skinIdProvider.overrideWithValue(boot.skin),
         returnRouteProvider.overrideWithValue(boot.returnRoute),
         skinRestartCarriesSessionProvider.overrideWithValue(boot.carrySession),
       ],
       child: const SkinApp(),
     );
   }));
   ```

   (mobile/02 adds `audioHandlerProvider` here.)
10. `mobile/lib/app/skin_app.dart`: `class SkinApp extends ConsumerWidget` builds `MaterialApp.router(title: 'ManhwaManiacs', debugShowCheckedModeBanner: false, theme: skin.theme(ref), darkTheme: skin.theme(ref), routerConfig: ref.watch(skinRouterProvider), builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(value: skin.overlayStyle(ref), child: DownloadsLifecycleGate(child: SkinBootCheck(child: skin.wrap(context, child ?? const SizedBox.shrink())))))` and keeps `ref.watch(highRefreshRateSyncProvider)`. For `legacy` this is exactly today's tree (the same `ThemeData` instance, the same overlay style, the same gate and `WhatsNewAutoShow`), plus `SkinBootCheck`, which renders its child unchanged. `mobile/lib/app/app.dart` becomes `typedef ManhwaManiacsApp = SkinApp;` plus the export, so every test that pumps `const ManhwaManiacsApp()` keeps compiling and runs the legacy skin. `DownloadsLifecycleGate` is mounted for every skin, so after a restart its launch pass calls `resumePendingOnLaunch()` again and every chapter left in `queued` or `downloading` state is re-queued (stack §2.5 step 7).
11. `mobile/lib/features/profiles/providers/profiles_providers.dart`: add `final skinRestartCarriesSessionProvider = Provider<bool>((ref) => false);` and, as the first line of `ProfileSessionReadyNotifier.build()`, `if (ref.read(skinRestartCarriesSessionProvider)) return ref.read(activeProfileProvider) != null;`. A skin restart happens inside an app session, so the profile gate that was already open stays open and the return route is honoured; a cold start still shows the picker (cinematic §8.5 "never auto-skip" is about cold starts).
12. `mobile/lib/app/switch_skin.dart`, the one restart path every caller uses:
    - `Future<void> restartInto(BuildContext context, WidgetRef ref, {required SkinId skin, required String returnRoute, _Mirror mirror = _Mirror.active})`, in this order: write `mm.skin.active` (or, for the debug path, `mm.skin.debug`; `_Mirror.clearDebug` removes it); write `mm.skin.return = returnRoute`; write `mm.skin.session = '1'` when `ref.read(profileSessionReadyProvider)` is true; `await skinFor(skin).prepare()`; `AppRestart.of(context).restart()`.
    - `String currentLocation(BuildContext context) => GoRouter.of(context).routerDelegate.currentConfiguration.uri.toString();`
    - `Future<void> switchSkin(BuildContext context, WidgetRef ref, {required SkinId to, required Future<void> Function() outgoing})` (stack §2.5 mobile steps 1–5; §8.30.3 rows t = 0 and "500, app"): at t = 0 write `mm.skin.t0 = DateTime.now().millisecondsSinceEpoch` and, when a profile is active, `ref.read(skinOutboxProvider).enqueue(profileId, to)` followed by an unawaited `flush()` (the mirror and the return route are **not** written yet); `await outgoing()` (Cinematic's Stop the press is 500 ms, mobile/18; Glass's melt, mobile/39); then `restartInto(context, ref, skin: to, returnRoute: currentLocation(context))`. The `PATCH` stays in the outbox until it lands. Haptic `skin.switch` and its sound play inside the skin's own `outgoing`, not here.
    - `Future<void> debugSwitchSkin(BuildContext context, WidgetRef ref, SkinId? to)` (§8.0.7): write `mm.skin.t0`; `await showRestartCurtain(context)`; then `restartInto(context, ref, skin: to ?? SkinBoot.resolveSkinWithoutDebug(prefs), returnRoute: '/settings/diagnostics', mirror: to == null ? _Mirror.clearDebug : _Mirror.debug)`. It never touches the outbox and never writes `reading_profiles.skin`.
    - `Future<void> leavePreview(BuildContext context, WidgetRef ref)`: the pending screen's button; the same as `debugSwitchSkin(context, ref, null)`.
    - `class RestartCurtain extends StatefulWidget`: a full-screen `ColoredBox(Color(0xFF000000))` whose opacity goes 0 → 1 over 200 ms `Curves.linear` (`dur.clip`), inside an `AbsorbPointer`. `Future<void> showRestartCurtain(BuildContext context)` inserts it as an `OverlayEntry` into `Overlay.of(context, rootOverlay: true)` and completes after 200 ms. The same 200 ms fade under reduced motion (it is already a plain fade, §4.8). The curtain absorbs taps.
13. **Restart timing** (§15.9 "`SKIN RESTART`"), in `switch_skin.dart`: `SkinRestartTiming.logFirstFrame(SharedPreferences prefs, {DateTime Function() now = DateTime.now})`, called by `SkinApp` in a one-shot `addPostFrameCallback` on its first build: when `mm.skin.t0` exists, compute `ms = now − t0`, remove the key, write `mm.skin.restart.last = ms`, and `debugPrint('SKIN RESTART  confirm → first frame  ${formatted} MS')` with thousands separators (`1,212`); when `ms > 1500` also `debugPrint('SKIN RESTART ${ms} ms > 1500 ms')`. It costs one read when nothing is pending. The motion-timings overlay (mobile/04, mobile/06) reads `mm.skin.restart.last` later.
14. `mobile/lib/app/skin_boot_check.dart`, boot resolution steps 2–5 (stack §2.4; §8.2 "Outcomes"; S5, S12):
    - pure `SkinId? resolveBootRestart({required SkinId running, required SkinId? debugOverride, required bool profileKnown, required String? profileSkin, required String? queuedOutboxSkin, required bool glassAvailable, required SkinId defaultSkin})`, rules in order: a debug override → `null` (the device override was already applied by `SkinBoot`, S5); `profileKnown` false (offline, or the profiles list has not loaded) → `null` (step 5, keep the mirror); a queued outbox skin for this profile → `null` (S12; the outbox flushes before the next comparison); `desired = skinIdFromName(profileSkin) ?? defaultSkin`, with `glass` coerced to `cinematic` while `glassAvailable` is false; `desired == running` → `null` (step 3); otherwise `desired` (step 4);
    - `SkinBootCheck` (a `ConsumerStatefulWidget` that renders `Stack(children: [child, if (_curtain) const RestartCurtain()])`) listens to `activeProfileProvider` and `profilesProvider`; when both have a value it looks up the active profile's row and runs `resolveBootRestart`. On a target: loop guard first (read `mm.skin.boot-restart` = `"<skin>:<epochMs>"`; if the same target was attempted less than 10,000 ms ago, do not restart and `debugPrint('Skin boot: <target> did not take; staying in <running>')`; otherwise write the key), then show the curtain for 200 ms and call `restartInto(skin: target, returnRoute: ref.read(skinRouterProvider).routerDelegate.currentConfiguration.uri.toString())` (the check sits in `MaterialApp.builder`, above the router's `InheritedGoRouter`, so `GoRouter.of(context)` is not available there; `AppRestart.of(context)` is, because `AppRestart` wraps the whole `ProviderScope`). No confirm and no undo.
15. `android:enableOnBackInvokedCallback="true"` on the `<application>` element of `mobile/android/app/src/main/AndroidManifest.xml` (§8.0.5; glass §15.3). Nothing else in the manifest changes in this step.

### C. The profile field and the offline outbox

16. `Profile` gains `final String? skin` (`json['skin']`, kept only when it is `'cinematic'` or `'glass'`, otherwise null). `ProfilesRepository.update(…)` gains `String? skin`, sent in the `PATCH /profiles/{id}` body only when non-null. Adjust the `ProfilesRepositoryImpl` and every fake in `mobile/test/` that implements the interface.
17. `mobile/lib/features/profiles/providers/skin_outbox.dart`: one pending entry per device (the latest switch wins), stored as SharedPreferences `mm.skin.outbox` = `{"profileId": 12, "skin": "glass"}`:
    - `enqueue(int profileId, SkinId skin)`, `String? pendingFor(int profileId)`, `Future<void> flush()`;
    - `flush()` sends `update(profileId, skin: …)` once at a time (a second call while one runs joins it); on success it removes the entry if it is still the same entry; on a network or 5xx error it keeps it; on 404 or 422 it drops it and logs with `appLogger.w`;
    - `final skinOutboxProvider = Provider<SkinOutbox>(…)`.
    Flush triggers: add `unawaited(ref.read(skinOutboxProvider).flush())` to `DownloadsLifecycleGate._onActive` (launch and resume) and to its connectivity-regained handler, next to the progress and bookmark outbox flushes.

### D. The pre-flip debug row (cinematic §8.0.7)

18. `mobile/lib/features/settings/screens/diagnostics_screen.dart` (legacy UI; styled like the screen's other sections): a new section after "Image cache", `_SectionHeading('Edition (debug)')` and a `GlassCard` holding:
    - a caption in the screen's existing caption style: "A device override for this phone. It never changes the profile's edition, and it goes away at the flip.";
    - two lines: "Now showing: {running skin id}" and "Override: {mm.skin.debug or none}";
    - a `SegmentedButton<SkinId>` over `kDebugSkins` with labels `LEGACY` and `CINEMATIC`, selected = the running skin, `tapTargetSize: MaterialTapTargetSize.padded` and a minimum size of 120 × 44 per segment; choosing a segment calls `debugSwitchSkin(context, ref, segment)`;
    - a `TextButton` "Clear override", enabled only when `mm.skin.debug` is set, which calls `debugSwitchSkin(context, ref, null)`;
    - `Semantics` labels on both controls; with a screen reader active the restart still happens after the 200 ms curtain.
    The row is the only visible change legacy users get in this step.

### E. Tests

19. `mobile/test/skins/import_boundary_test.dart` (stack §2.3): for every `.dart` file under `lib/skins/cinematic/` and `lib/skins/glass/`, fail on an import containing `/screens/`, `/widgets/`, `app/theme/`, `app/router/`, `app/app.dart`, `skins/legacy/`, or the other skin's folder (`skins/glass/` from cinematic, `skins/cinematic/` from glass). Also fail when any file under `lib/skins/` (legacy excluded) or `lib/app/{app_restart,skin_app,skin_boot,skin_boot_check,switch_skin}.dart` imports `app/router/routes.dart`: new code builds paths only from `contract.g.dart` (`ScreenId.x.path` and the encoding builders), which is what "Routes adopted" means until release/00 deletes `routes.dart`. Write the scan as a pure function `List<String> boundaryViolations(String path, String source)` and include self-checks on in-memory strings (one clean, one per banned pattern).
20. `mobile/test/skins/completeness_test.dart` (stack §2.3; glass §15.3): for `SkinId.cinematic` and `SkinId.glass`, build the router through a `ProviderContainer(overrides: [skinIdProvider.overrideWithValue(id)])` and `container.read(skinRouterProvider)`; for every `ScreenId.values` entry, fill each `:param` of its path with `x` and assert the router's configuration matches it (use `router.configuration.findMatch(…)` with the signature of the resolved go_router 14.8.1; read `~/.pub-cache/hosted/pub.dev/go_router-14.8.1/lib/src/configuration.dart`), and that `/library/history` matches `history`, not `featureByFollow`. Import the two routers with prefixes (`as cine`, `as glass`) and assert each `PENDING` is a subset of `ScreenId.values` and equals the ids whose route builds a `PendingScreen`. A `const mustBeComplete` map at the top (lowerCamelCase, so `flutter analyze` stays clean), `{SkinId.cinematic: false, SkinId.glass: false}` with the comment `// mobile/24 sets cinematic to true, mobile/45 sets glass to true (release gates).`; when a flag is true, that skin's pending set must be empty. Print `cinematic pending: N / total` and `glass pending: N / total`.
21. `mobile/test/app/skin_boot_test.dart`: `resolveSkin` precedence table (debug valid beats active; `glass` active with the flag false → `cinematic`; invalid strings ignored; nothing → `kDefaultSkin`); `read` consumes `mm.skin.return` and `mm.skin.session` (a second read returns null / false); `resolveBootRestart` covers every branch in a table; the loop guard (same target within 10,000 ms → no restart; after → restart).
22. `mobile/test/app/app_restart_test.dart`: `restart()` calls the builder again, a provider's state below it is fresh (a counter provider reads 0 again), and `AppRestart.of` resolves from deep in the tree.
23. `mobile/test/app/switch_skin_test.dart` (fake `AppRestart` host, fake clock, `SharedPreferences.setMockInitialValues`): `mm.skin.t0` and the outbox entry exist before `outgoing` starts; the mirror and return route do not exist until `outgoing` completes; `prepare()` is awaited before `restart()`; `restart()` runs exactly once; `debugSwitchSkin` writes `mm.skin.debug` and the `/settings/diagnostics` return route and never touches the outbox; "Clear override" removes the key; `SkinRestartTiming` logs 1,212 ms for t0 = 1,000 and a first frame at 2,212, removes t0 and stores `mm.skin.restart.last`; the curtain lasts 200 ms.
24. `mobile/test/features/profiles/skin_outbox_test.dart`: enqueue persists; the latest enqueue wins; `pendingFor`; success removes; a network error keeps; 404 and 422 drop; two overlapping `flush()` calls send one request.
25. `mobile/test/skins/pending_screen_test.dart`: kicker, title and location text render for `CINEMATIC` and `GLASS`; the button is at least 44 tall on iOS and 48 on Android (`debugDefaultTargetPlatformOverride`); it has a semantics label; no animation runs (`tester.binding.hasScheduledFrame` is false after the first pump); tapping it removes `mm.skin.debug` and restarts; at text scale 2.0 nothing overflows. When the environment variable `MM_PROOF_DIR` is set, it also writes PNGs with `writeShot()` from `test/screenshots/support/shot_harness.dart` (wrap the screen in a `RepaintBoundary`): `cinematic-pending-390x844.png`, `cinematic-pending-834x1194.png`, `glass-pending-390x844.png`, `glass-pending-834x1194.png`.
26. `mobile/test/features/settings/diagnostics_edition_row_test.dart`: the section renders both segments and the caption; choosing `CINEMATIC` writes `mm.skin.debug = cinematic` and the return route and restarts; "Clear override" is disabled without a key. With `MM_PROOF_DIR` set, writes `legacy-diagnostics-edition-390x844.png`.
27. `mobile/test/android/predictive_back_manifest_test.dart`: the main manifest's `<application>` carries `android:enableOnBackInvokedCallback="true"`.

## File layout (create or change; nothing else)

```
mobile/lib/main.dart                                              change
mobile/lib/app/app.dart                                           change (typedef ManhwaManiacsApp = SkinApp)
mobile/lib/app/app_restart.dart                                   new
mobile/lib/app/skin_app.dart                                      new
mobile/lib/app/skin_boot.dart                                     new
mobile/lib/app/skin_boot_check.dart                               new
mobile/lib/app/switch_skin.dart                                   new
mobile/lib/app/router/app_router.dart                             change (initialLocation only)
mobile/lib/skins/skin.dart, skins.dart, pending_screen.dart       new
mobile/lib/skins/legacy/legacy_skin.dart                          new
mobile/lib/skins/cinematic/{cinematic_skin,router}.dart           new
mobile/lib/skins/glass/{glass_skin,router}.dart                   new
mobile/lib/features/profiles/models/profile.dart                  change (skin)
mobile/lib/features/profiles/repositories/profiles_repository{,_impl}.dart   change (skin)
mobile/lib/features/profiles/providers/profiles_providers.dart    change (carried session)
mobile/lib/features/profiles/providers/skin_outbox.dart           new
mobile/lib/features/downloads/providers/downloads_lifecycle_gate.dart   change (flush the skin outbox)
mobile/lib/features/settings/screens/diagnostics_screen.dart      change (Edition (debug))
mobile/android/app/src/main/AndroidManifest.xml                   change (enableOnBackInvokedCallback)
mobile/test/skins/{import_boundary,completeness,pending_screen}_test.dart   new
mobile/test/app/{skin_boot,app_restart,switch_skin}_test.dart      new
mobile/test/features/profiles/skin_outbox_test.dart               new
mobile/test/features/settings/diagnostics_edition_row_test.dart   new
mobile/test/android/predictive_back_manifest_test.dart            new
mobile/test/** fakes of ProfilesRepository                        change (skin parameter)
docs/redesign/plans/mobile-01.md                                  new
docs/redesign/proof/mobile-01/*.png                               new
```

## Acceptance criteria

- [ ] `flutter analyze`: "No issues found!". `flutter test`: 0 failed, and the count is at least the count you recorded before your first change plus the new tests; every test that passed before still passes.
- [ ] Legacy parity: with no `mm.skin.*` keys the app boots into `legacy`, and the tests that pump `ManhwaManiacsApp` pass unchanged; the only new legacy UI is the Diagnostics "Edition (debug)" section.
- [ ] `SkinBoot.read` returns the debug skin first, then the mirror, then `kDefaultSkin`, coerces a stored `glass` to `cinematic` while `Flags.glassAvailable` is false, and consumes `mm.skin.return` and `mm.skin.session`.
- [ ] Choosing `CINEMATIC` in the debug row fades to black over 200 ms, restarts, and lands on the Cinematic pending screen for `settings` at `/settings/diagnostics`, with the profile gate still open; "Leave the preview" returns to legacy Diagnostics the same way.
- [ ] `switchSkin` writes `mm.skin.t0` and the outbox entry before `outgoing`, the mirror and return route after it, awaits `prepare()`, and restarts once; the `PATCH` is never awaited on mobile (S12: the outbox wins at boot).
- [ ] `resolveBootRestart` passes its table; a queued outbox entry for the active profile suppresses a mismatch restart; the 10-second loop guard holds.
- [ ] After a restart, `DownloadsLifecycleGate` runs its launch pass again (a test with a fake queue controller sees `resumePendingOnLaunch` called twice across one restart).
- [ ] `import_boundary_test.dart` and `completeness_test.dart` pass; both skins list every `ScreenId` in their pending sets; `readerLanding` redirects to `/library` on both.
- [ ] Hit targets: the pending screen's button is ≥ 44 pt (iOS) / 48 dp (Android) tall; each debug segment is ≥ 44 tall with padded tap targets.
- [ ] Keyboard: with a hardware keyboard, Tab reaches "Leave the preview" and the 2 px white focus ring shows; Enter or Space activates it.
- [ ] Reduced motion: the pending screen has no animation; the restart curtain is the same 200 ms linear fade with or without reduced motion.
- [ ] Per-skin differences: `legacy` renders today's theme, router, overlay style and `WhatsNewAutoShow`; `cinematic` and `glass` render `#000000`, the transparent light overlay style, their generated token extension and the pending screen with their own name in the kicker.
- [ ] Your commits carry no AI attribution: `git log -n 20 --format=%B | grep -c "Co-Authored-By\|Generated with"` prints 0.

## Verification

```bash
cd /srv/manhwamaniacs/dev/ManhwaManiacs/mobile
F=/srv/manhwamaniacs/dev/flutter/bin/flutter
free -m && $F test 2>&1 | tail -3      # BEFORE any change: record the count (2012 at the baseline plus later generated tests)
# … implement …
free -m && $F analyze                  # baseline: No issues found!
free -m && $F test test/skins test/app test/features/profiles test/features/settings test/android
free -m && $F test 2>&1 | tail -3      # full suite, 0 failed
free -m && MM_PROOF_DIR=../docs/redesign/proof/mobile-01 $F test test/skins/pending_screen_test.dart test/features/settings/diagnostics_edition_row_test.dart
```

Stop if `free -m` shows less than 1,024 MB available, and never run these while a `next build` is running (`pgrep -fa "next build"`). Web and backend: this step changes neither; no local `npm run lint`, `npm run build` or pytest run is needed, and the CI `frontend` and `backend` jobs must stay green on your pushed commits.

**Visual proof.** Open every PNG in `docs/redesign/proof/mobile-01/` (Read them): the Cinematic and Glass pending screens at 390 × 844 and 834 × 1,194, and the legacy Diagnostics edition section at 390 × 844.

**Owner device checklist** (append to `docs/redesign/proof/mobile-01/device-check.md`, run on the iPhone build CI publishes after your push and on the Android flagship): Settings → Diagnostics → Edition (debug) → CINEMATIC: black fade, restart, pending "settings" screen, no profile picker in between; "Leave the preview": back in legacy Diagnostics; kill the app while on the Cinematic pending screen and reopen: it opens in Cinematic again (the device override persists); a download started in legacy keeps going after a switch; Android 14+: the predictive back gesture still leaves each legacy screen the way it did.

## Git

- Branch `feat/vps-slim-source-native`. Commits, one per working step: plan; skin types and skeleton skins; boot, restart and `SkinApp`; switch and timing; profile field and outbox; debug row; boundary and completeness tests; manifest; proof. Push after each: `git push origin feat/vps-slim-source-native` (a green push also publishes the iPhone build through `ios-build.yml`).
- Stage explicit paths only; never `git add -A`, `git add .` or `git commit -a`.
- No Claude or AI attribution anywhere (no `Co-Authored-By`, no "Generated with" line, no AI author). Never commit secrets, `.env*` or `.claude/`.

## Guardrails

- Never edit `backend/connectors/`, `frontend/`, `design/`, generated files, or anything under `/srv/manhwamaniacs/{app,data}`; no Docker commands; never touch production containers.
- RAM guard: `free -m` before every analyze and test run; stop under 1,024 MB available; one heavy command at a time.
- `legacy` must stay pixel-identical: if a legacy test fails, fix your wiring, never the test's expectation.

## Report back

Reply with:
1. Done items by section (A–E) with commit hashes.
2. The `ScreenId` count per skin and the pending counts (`cinematic pending: N / N`, `glass pending: N / N`), the alias routes you registered, and whether Glass got its token extension (shared/01 present or not).
3. Test counts before and after (passed / failed / skipped) and the `flutter analyze` result.
4. The proof folder `docs/redesign/proof/mobile-01/` and what each PNG shows.
5. CI status of your last push, the lowest `free -m` available figure you saw, and open issues (any contract name you had to guess, anything deferred).

Next prompt in the mobile track: `docs/redesign/prompts/mobile/02-foundation-native-plugins-haptics-sound.md` (it also needs `shared/01` and `shared/03` done). Next in the global order: `docs/redesign/prompts/shared/03-ui-sounds-and-soundscape-audio.md`.
