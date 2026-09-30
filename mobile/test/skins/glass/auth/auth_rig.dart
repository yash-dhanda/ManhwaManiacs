import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/app/skin_boot.dart' show kSkinDebugKey;
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/glass/dev/auth_fixtures.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart' show glassOfflineProvider;

import '../../../support/test_overrides.dart' show setupCompletedPrefKey;
import '../shell/shell_rig.dart';

class _Active extends ActiveProfileNotifier {
  _Active(this.value);
  final ActiveProfile? value;
  @override
  ActiveProfile? build() => value;
}

class _Ready extends ProfileSessionReadyNotifier {
  _Ready(this.value);
  final bool value;
  @override
  bool build() => value;
}

/// Pumps the Glass router on [start] with a [GlassAuthFixture]: the fakes of `mobile/30`, no network.
Future<ShellRig> pumpAuth(
  WidgetTester t,
  String start,
  GlassAuthFixture f, {
  Size size = const Size(390, 844),
  bool setupDone = true,
  bool sessionReady = false,
  bool reduced = false,
  List<Override> extra = const [],
  bool android = false,
  FakeOnboardingRepo? onboardingRepo,
  FakeLibrary? library,
  bool settle = true,
  bool debugGlass = true,
  Map<String, Object> prefs = const {},
  bool online = true,
}) {
  FakeProfiles.calls.clear();
  FakeAuth.calls.clear();
  return _pump(t, start, f, size: size, setupDone: setupDone, sessionReady: sessionReady, reduced: reduced, extra: extra, android: android, onboardingRepo: onboardingRepo, library: library, settle: settle, debugGlass: debugGlass, prefs: prefs, online: online);
}

Future<ShellRig> _pump(
  WidgetTester t,
  String start,
  GlassAuthFixture f, {
  required Size size,
  required bool setupDone,
  required bool sessionReady,
  required bool reduced,
  required List<Override> extra,
  required bool android,
  required FakeOnboardingRepo? onboardingRepo,
  required FakeLibrary? library,
  required bool settle,
  required bool debugGlass,
  required Map<String, Object> prefs,
  required bool online,
}) async {
  // Drops the previous test's tree first: its metrics observer would read a disposed container when this test resizes the view.
  await t.pumpWidget(const SizedBox.shrink());
  final rig = await pumpGlassShell(
    t,
    start: start,
    size: size,
    platformAndroid: android,
    settle: settle,
    prefsExtra: {setupCompletedPrefKey: setupDone, if (debugGlass) kSkinDebugKey: 'glass', ...prefs},
    extra: [
      ...glassAuthFixtureOverrides(f, onboardingRepo: onboardingRepo, library: library),
      activeProfileProvider.overrideWith(() => _Active(f.active)),
      profileSessionReadyProvider.overrideWith(() => _Ready(sessionReady)),
      // The shell rig pins it to true; Setup and "Change server" need the real preference behind it.
      setupCompletedProvider.overrideWith((ref) => ref.watch(preferencesProvider).setupCompleted),
      if (!online) glassOfflineProvider.overrideWithValue(true),
      ...extra,
    ],
  );
  if (reduced) {
    rig.container.read(glassInAppPrefsProvider.notifier).setReduceMotion(true);
    await t.pump(const Duration(milliseconds: 100));
  }
  return rig;
}

/// Pumps [ms] of fake time in 50 ms frames: chained timers and futures (the overlays' `Future.delayed`) need a frame per link.
Future<void> settleFor(WidgetTester t, [int ms = 1000]) async {
  await t.pump();
  for (var elapsed = 0; elapsed < ms; elapsed += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

/// The profile list of a fixture as the notifier holds it.
List<Profile> profilesOf(ProviderContainer c) => c.read(profilesProvider).valueOrNull ?? const [];
