import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/app/app_restart.dart';
import 'package:manhwamaniacs/app/font_licenses.dart';
import 'package:manhwamaniacs/app/skin_app.dart';
import 'package:manhwamaniacs/app/skin_boot.dart';
import 'package:manhwamaniacs/core/config/env.dart';
import 'package:manhwamaniacs/core/config/startup_config.dart';
import 'package:manhwamaniacs/core/logging/app_logger.dart';
import 'package:manhwamaniacs/core/network/interceptors/app_version_interceptor.dart';
import 'package:manhwamaniacs/core/platform/system_ui.dart';
import 'package:manhwamaniacs/core/storage/preferences.dart';
import 'package:manhwamaniacs/core/storage/secure_storage.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/novels/providers/narration_audio_handler_provider.dart';
import 'package:manhwamaniacs/features/novels/services/narration_audio_handler.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/settings/utils/licenses.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/skin_audio.dart';
import 'package:manhwamaniacs/skins/skins.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // This build's version, for the X-App-Version header. Started here rather
  // than when the HTTP client is first built, so the platform has answered by
  // the time the first request goes out. Not awaited: a platform that never
  // answers must not hold up the first frame.
  startAppVersionLookup();

  // Three independent round trips, started together rather than chained.
  // None of them needs another's result, and all of them run before a single
  // frame can be scheduled — so serialising them was pure cold-start latency.
  // The secure-storage read is the expensive one: on Android that is
  // EncryptedSharedPreferences over the Keystore.
  //
  // Android: edge-to-edge with auto-hiding nav buttons (swipe up to reveal).
  // iOS: plain edge-to-edge — see `restingSystemUiMode` for why the immersive
  // modes are Android-only there.
  final systemUi = applyRestingSystemUiMode();
  final prefsLoad = SharedPreferences.getInstance();
  final storage = SecureStorageService();
  final savedApiUrl = storage.getApiUrl();

  // ponytail: SharedPreferences has no fallback (every provider reads it), so it is the one boot
  // await left unbounded; everything below gives up and carries on.
  final prefs = await prefsLoad;
  final preferences = PreferencesService(prefs);
  // A stuck keychain reads as "no saved URL": the build's default (a baked production URL wins
  // regardless), never a write over what is stored.
  final apiUrl = await applyStartupConfig(
    storage: storage,
    preferences: preferences,
    savedUrl: _bounded('API URL read', savedApiUrl, const Duration(seconds: 3), () => null),
  );
  await _bounded('system UI mode', systemUi, const Duration(seconds: 2), () {});
  appLogger.i('API base URL: $apiUrl  flavor: ${Env.flavor}');

  // State A of the audio session (ambient, mixes with others; narration flips
  // it to spoken word while a chapter plays). SkinAudio owns the session for
  // the process, so a skin restart never resets it. Not awaited: nothing plays
  // before a reader presses play and the first frame must not wait.
  unawaited(SkinAudio.instance.start());

  // Once per engine, before runApp and never inside the restart builder (it
  // asserts a single init; a skin switch restarts inside the same engine).
  // The narration controller attaches to this handler when a chapter is read aloud; until then
  // its playback state stays idle and no notification shows.
  // A media service that never binds leaves narration without lock-screen controls, not the app
  // without a first frame: the plain handler still plays.
  final handler = await _bounded(
    'audio service',
    AudioService.init<NarrationAudioHandler>(
      builder: NarrationAudioHandler.new,
      config: narrationAudioServiceConfig(SkinBoot.resolveSkin(prefs)),
    ),
    const Duration(seconds: 5),
    NarrationAudioHandler.new,
  );

  registerFontLicenses();
  await _bounded('art licences', registerArtLicences(rootBundle), const Duration(seconds: 3), () {});

  // Glass loads its shaders here; past the bound the surfaces draw as they would before they land.
  await _bounded('skin prepare', skinFor(SkinBoot.resolveSkin(prefs)).prepare(), const Duration(seconds: 6), () {});

  // The builder re-runs on every restart, so boot state (the mm.skin.* keys)
  // is read again and the new ProviderScope starts in the new skin.
  final apiUrlMemo = ApiUrlMemo(apiUrl);
  runApp(
    AppRestart(
      builder: () {
        final boot = SkinBoot.read(prefs);
        return ProviderScope(
          observers: [apiUrlMemo],
          overrides: [
            apiUrlMemo.scopeOverride,
            authTokenReadTimeoutProvider.overrideWithValue(const Duration(seconds: 4)),
            sharedPrefsProvider.overrideWithValue(prefs),
            skinIdProvider.overrideWithValue(boot.skin),
            returnRouteProvider.overrideWithValue(boot.returnRoute),
            skinRestartCarriesSessionProvider.overrideWithValue(boot.carrySession),
            audioHandlerProvider.overrideWithValue(handler),
          ],
          child: const SkinApp(),
        );
      },
    ),
  );
}

/// A boot step that may never answer (a stuck platform channel): past [limit] it is logged and
/// [fallback] stands in, so launch always reaches the first frame.
Future<T> _bounded<T>(String what, Future<T> step, Duration limit, T Function() fallback) =>
    step.timeout(limit, onTimeout: () {
      appLogger.w('Boot: $what did not answer in ${limit.inSeconds} s; carrying on without it');
      return fallback();
    },);
