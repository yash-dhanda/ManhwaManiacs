// ignore_for_file: directives_ordering, unawaited_futures, avoid_dynamic_calls, library_private_types_in_public_api, inference_failure_on_collection_literal

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/app/app_restart.dart';
import 'package:manhwamaniacs/core/platform/app_icon_switcher.dart';
import 'package:manhwamaniacs/features/downloads/providers/active_download_queue_provider.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/features/updates/providers/unread_count_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/app_frame.dart';
import 'package:manhwamaniacs/skins/cinematic/cinematic_skin.dart';
import 'package:manhwamaniacs/skins/cinematic/navigation.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/settings_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/splash/cine_splash.dart';
import 'package:manhwamaniacs/skins/skin_audio.dart';
import 'package:manhwamaniacs/skins/skins.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/test_overrides.dart';
import 'settings_rig.dart';

class _Unread extends UnreadCountNotifier {
  @override
  int build() => 0;
}

class _Configurator implements SessionConfigurator {
  @override
  Future<void> configure(AudioSessionConfiguration c) async {}
  @override
  Future<void> setActive(bool a) async {}
}

class _Engine implements CueEngine {
  @override
  Future<void> init() async {}
  @override
  Future<dynamic> loadAsset(String path) async => path;
  @override
  Future<dynamic> play(dynamic source, {required double volume}) async => 1;
  @override
  void setRelativePlaySpeed(dynamic handle, double rate) {}
}

Future<(ProviderContainer, GoRouter, int Function())> pumpApp(WidgetTester t, {String start = '/', Map<String, Object> prefs = const {}, bool admin = true, bool iconFollows = false}) async {
  final rig = SettingsRig(admin: admin, prefs: {...prefs, if (iconFollows) kIconFollowKey: true});
  SharedPreferences.setMockInitialValues(rig.prefs);
  final p = await SharedPreferences.getInstance();
  final audio = SkinAudio.forTest(_Configurator(), _Engine())..bind(skin: SkinId.cinematic, userId: 1, profileId: 1, prefs: p);
  final c = ProviderContainer(overrides: [
    ...settingsOverrides(rig, p, audio),
    profileSessionReadyOverride(),
    setupCompletedProvider.overrideWithValue(true),
    tonightIdleOverride(),
    ...shelfIdleOverrides(),
    splashDoneProvider.overrideWith((ref) => true),
    unreadNotificationCountProvider.overrideWith(_Unread.new),
    activeDownloadCountProvider.overrideWithValue(0),
    // An Android device with the alternate icons registered: the switch queues the alias in prefs, no platform channel.
    if (iconFollows) appIconSwitcherProvider.overrideWithValue(AppIconSwitcher(prefs: p, glassAvailable: true, platform: TargetPlatform.android)),
  ],);
  addTearDown(c.dispose);
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final router = c.read(skinRouterProvider);
  if (start != '/') router.go(start);
  var builds = 0;
  await t.pumpWidget(AppRestart(builder: () {
    builds++;
    return UncontrolledProviderScope(
      container: c,
      child: MaterialApp.router(
        theme: CinematicSkin.baseTheme,
        routerConfig: router,
        builder: (context, child) => CineAppFrame(splash: false, child: child!),
      ),
    );
  },),);
  for (var i = 0; i < 20; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
  return (c, router, () => builds);
}

void main() {
  for (final path in ['/settings', '/settings/storage', '/settings/backup', '/settings/diagnostics', '/settings/reading-manga', '/settings/about?licenses=1']) {
    testWidgets('$path resolves to the settings screen, not the pending stand-in', (t) async {
      final (_, router, _) = await pumpApp(t, start: path);
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(Uri.parse(cineLocationOf(router)).path, Uri.parse(path).path);
    });
  }

  testWidgets('a section slug reaches its own page', (t) async {
    await pumpApp(t, start: '/settings/backup');
    expect(find.text('Export backup'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('/settings/about?licenses=1 opens the licence list directly', (t) async {
    await pumpApp(t, start: '/settings/about?licenses=1');
    expect(find.text('DEMO ART'), findsOneWidget);
    expect(find.text('Edition previews use procedural demo covers made for ManhwaManiacs.'), findsOneWidget);
    expect(find.text('TYPE'), findsOneWidget);
  });

  testWidgets('arriving from Glass: the toast with Undo, once; the marker is consumed', (t) async {
    final (c, _, _) = await pumpApp(t, prefs: {'mm.skin.from': 'glass'});
    expect(find.text('Now in the Cinematic edition.'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    expect(c.read(sharedPrefsProvider).containsKey('mm.skin.from'), isFalse, reason: 'one-shot');
    // held for 10 s
    await t.pump(const Duration(seconds: 8));
    expect(find.text('Now in the Cinematic edition.'), findsOneWidget);
    await t.pump(const Duration(seconds: 4));
    await t.pump(const Duration(seconds: 1));
    expect(find.text('Now in the Cinematic edition.'), findsNothing);
  });

  testWidgets('no marker, no toast (a boot mismatch restart or the debug row)', (t) async {
    await pumpApp(t);
    expect(find.text('Now in the Cinematic edition.'), findsNothing);
  });

  // One switch per file: Glass's prepare() caches its first attempt, so a second restart in the same isolate never completes.
  testWidgets('Undo plays Stop the press and switches back without writing mm.skin.from; the icon follows (release/01 D2)', (t) async {
    final (c, _, builds) = await pumpApp(t, prefs: {'mm.skin.from': 'glass'}, iconFollows: true);
    await t.tap(find.text('Undo'));
    for (var i = 0; i < 12; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    // The Glass shaders are not in the test bundle: prepare() reports them, the switch carries on.
    while (t.takeException() != null) {}
    final prefs = c.read(sharedPrefsProvider);
    expect(prefs.getString('mm.skin.active'), 'glass');
    expect(prefs.containsKey('mm.skin.from'), isFalse, reason: 'undoable: false');
    expect(prefs.getString(kIconPendingKey), kAndroidGlassIconAlias, reason: 'Undo is an explicit choice: the icon follows the skin back');
    expect(builds(), 2, reason: 'AppRestart rebuilt the tree');
  });
}
