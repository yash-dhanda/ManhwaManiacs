@Tags(['screenshots'])
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart' show TextField;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/app/skin_app.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/auth/models/bootstrap_status.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/features/setup/utils/server_check.dart';
import 'package:manhwamaniacs/features/setup/utils/server_check_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/glass/dev/auth_fixtures.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/poster.dart';
import 'package:manhwamaniacs/skins/glass/primitives/switch.dart';
import 'package:manhwamaniacs/skins/glass/screens/auth/lens_split_handoff.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart';
import 'package:manhwamaniacs/skins/skins.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../skins/glass/shell/shell_rig.dart';
import '../../support/test_overrides.dart';
import '../glass_shell_shots_support.dart';
import '../support/shot_harness.dart';
import '../support/skin_shots.dart';

/// The mobile/30 proof captures (glass 8.1 to 8.7): Setup, Login, Register, the picker and its hand-off, the profile form, Manage
/// profiles and onboarding, on fixtures. Written only when `MM_PROOF_DIR` is set; otherwise rasterised and discarded.

const _phone = SkinShotSize('phone', Size(390, 844), 3.0, EdgeInsets.only(top: 47, bottom: 34));
final _tablet = kSkinShotSizes[1];

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

const _me = ActiveProfile(id: 1, name: 'Yash', avatarKey: 'violet', mood: Mood.fantasy);

GlassAuthFixture _signed({int n = 4, List<Profile>? profiles, ActiveProfile? active = _me, AppError? profilesError}) =>
    GlassAuthFixture(signedIn: true, profiles: profilesError == null ? (profiles ?? fixtureProfiles(n)) : null, profilesError: profilesError, active: active);

GlassAuthFixture _step(int step) => GlassAuthFixture(signedIn: true, profiles: [fixtureProfile(1, 'Yash', step: '$step', mood: Mood.fantasy)], active: _me, seeds: fixtureSeeds(), similar: [for (var i = 0; i < 3; i++) WorldItemSim.of(i)]);

Future<ShotSession> _open(
  WidgetTester t,
  SkinShotSize size,
  String start,
  GlassAuthFixture f, {
  bool setupDone = true,
  bool sessionReady = false,
  Map<String, Object> prefs = const {},
  List<Override> extra = const [],
  bool settle = true,
  bool reduced = false,
}) async {
  await t.pumpWidget(const SizedBox.shrink());
  setSkinShotView(t, size);
  const haptics = MethodChannel('gaimon');
  t.binding.defaultBinaryMessenger.setMockMethodCallHandler(haptics, (_) async => null);
  addTearDown(() => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(haptics, null));
  SharedPreferences.setMockInitialValues(testPrefsDefaults({setupCompletedPrefKey: setupDone, ...prefs}));
  final sp = await SharedPreferences.getInstance();
  FakeProfiles.calls.clear();
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(sp),
        skinIdProvider.overrideWithValue(SkinId.glass),
        returnRouteProvider.overrideWithValue(start),
        ...shellTestOverrides(),
        ...glassAuthFixtureOverrides(f),
        setupCompletedProvider.overrideWith((ref) => ref.watch(preferencesProvider).setupCompleted),
        activeProfileProvider.overrideWith(() => _Active(f.active)),
        profileSessionReadyProvider.overrideWith(() => _Ready(sessionReady)),
        ...extra,
      ],
      child: RepaintBoundary(key: kSkinShotKey, child: const SkinApp()),
    ),
  );
  final container = ProviderScope.containerOf(t.element(find.byType(SkinApp)));
  final s = ShotSession(t, container);
  if (reduced) container.read(glassInAppPrefsProvider.notifier).setReduceMotion(true);
  if (settle) {
    await s.settle(600);
    await s.settle(800);
    await s.settle(1200);
  } else {
    await t.pump();
  }
  return s;
}

/// Three similar seeds for the "similar picks" capture.
abstract final class WorldItemSim {
  static WorldItem of(int i) => WorldItem(anilistId: 900 + i, title: ['Tower of God', 'Lookism', 'Eleceed'][i], available: [WorldAvailability(sourceId: 's', sourceName: 'S', seriesKey: 'sim-$i')]);
}

/// Drops the tree and lets its timers (the rate-limit countdown) end before the test does.
Future<void> _end(WidgetTester t) async {
  await t.pumpWidget(const SizedBox.shrink());
  await t.pump(const Duration(seconds: 1));
}

Future<void> _pumpMs(WidgetTester t, int ms) async {
  await t.pump();
  await t.pump(Duration(milliseconds: ms));
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('setup: phone, tablet and its states', (t) async {
    var s = await _open(t, _phone, '/setup', const GlassAuthFixture(), setupDone: false);
    await s.snap('setup', _phone);
    s = await _open(t, _tablet, '/setup', const GlassAuthFixture(), setupDone: false);
    await s.snap('setup', _tablet);

    final never = Completer<ServerCheck>();
    s = await _open(t, _phone, '/setup', const GlassAuthFixture(), setupDone: false, extra: [serverCheckProvider.overrideWithValue((_) => never.future)]);
    await t.enterText(find.byType(TextField), 'https://mm.example');
    await t.tap(find.text('Connect'));
    await _pumpMs(t, 400);
    await s.snap('setup-validating', _phone);

    for (final (name, check) in [('offline', const ServerCheck.offline()), ('tls', const ServerCheck.tls()), ('not-server', const ServerCheck.notManhwaManiacs())]) {
      s = await _open(t, _phone, '/setup', GlassAuthFixture(serverCheck: check), setupDone: false);
      await t.enterText(find.byType(TextField), 'https://mm.example');
      await t.tap(find.text('Connect'));
      await _pumpMs(t, 700);
      await s.snap('setup-$name', _phone);
    }

    s = await _open(t, _phone, '/setup', const GlassAuthFixture(), setupDone: false);
    await t.enterText(find.byType(TextField), 'https://mm.example');
    await t.tap(find.text('Connect'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 230));
    await s.snap('setup-drain-midway', _phone);
    await t.pump(const Duration(seconds: 3));
    await _end(t);
  });

  testWidgets('login: phone, tablet, desktop and its states', (t) async {
    var s = await _open(t, _phone, '/login', const GlassAuthFixture());
    await s.settle(3500);
    await s.snap('login', _phone);
    s = await _open(t, _tablet, '/login', const GlassAuthFixture());
    await s.settle(3500);
    await s.snap('login', _tablet);
    s = await _open(t, kSkinShotDesktop, '/login', const GlassAuthFixture());
    await s.settle(3500);
    await s.snap('login', kSkinShotDesktop);

    s = await _open(t, _phone, '/login', const GlassAuthFixture(), settle: false);
    await t.pump(const Duration(milliseconds: 200));
    await s.snap('login-typing-200ms', _phone);
    await t.pump(const Duration(seconds: 4));

    s = await _open(t, _phone, '/login', const GlassAuthFixture(), prefs: {'mm.known-accounts': jsonEncode(['demo', 'reader2', 'kai'])});
    await s.settle(3500);
    await s.snap('login-known-accounts', _phone);

    final never = Completer<BootstrapStatus>();
    s = await _open(t, _phone, '/login', const GlassAuthFixture(), extra: [bootstrapStatusProvider.overrideWith((ref) => never.future)]);
    await s.snap('login-resolving', _phone);
    s = await _open(t, _phone, '/login', const GlassAuthFixture(bootstrapError: NetworkError(message: 'x')));
    await s.snap('login-unreachable', _phone);
    s = await _open(t, _phone, '/login', const GlassAuthFixture(bootstrap: BootstrapStatus(needsBootstrap: true, registrationEnabled: true)));
    await s.settle(4000);
    await s.snap('login-bootstrap', _phone);

    for (final (name, err) in [('error', const ApiError(statusCode: 401, code: 'invalid_credentials', message: 'x')), ('rate-limited', const ApiError(statusCode: 429, code: 'rate_limited', message: 'x', retryAfter: Duration(seconds: 42)))]) {
      s = await _open(t, _phone, '/login', GlassAuthFixture(loginError: err));
      await s.settle(3500);
      await t.enterText(find.byType(TextField).at(0), 'demo');
      await t.enterText(find.byType(TextField).at(1), 'pw-1234567');
      await t.pump();
      await t.tap(find.widgetWithText(GlassButton, 'Sign in'));
      await _pumpMs(t, 500);
      await s.snap('login-$name', _phone);
    }

    for (final size in [_phone, kSkinShotDesktop]) {
      s = await _open(t, size, '/login', _signedOutWithProfiles());
      await s.settle(3500);
      await t.enterText(find.byType(TextField).at(0), 'demo');
      await t.enterText(find.byType(TextField).at(1), 'pw-1234567');
      await t.pump();
      await t.tap(find.widgetWithText(GlassButton, 'Sign in'));
      await _pumpMs(t, 230);
      await s.snap('login-condense-midway', size);
      await t.pump(const Duration(seconds: 3));
    }
    await _end(t);
  });

  testWidgets('register: three variants on phone and tablet, and validation', (t) async {
    for (final size in [_phone, _tablet]) {
      for (final (name, f) in [
        ('open', const GlassAuthFixture()),
        ('bootstrap', const GlassAuthFixture(bootstrap: BootstrapStatus(needsBootstrap: true, registrationEnabled: true))),
        ('closed', const GlassAuthFixture(bootstrap: BootstrapStatus(needsBootstrap: false, registrationEnabled: false))),
      ]) {
        final s = await _open(t, size, '/register', f);
        await s.settle(600);
        await s.snap('register-$name', size);
      }
    }
    final s = await _open(t, _phone, '/register', const GlassAuthFixture());
    await t.enterText(find.byType(TextField).at(0), 'ab');
    await t.enterText(find.byType(TextField).at(1), 'password1');
    await t.enterText(find.byType(TextField).at(2), 'password2');
    await t.pump();
    await t.tap(find.byType(TextField).at(0));
    await _pumpMs(t, 500);
    await s.snap('register-validation', _phone);
    await _end(t);
  });

  testWidgets('picker: sizes, split, hand-off, manage, menu and states', (t) async {
    for (final size in [_phone, _tablet, kSkinShotDesktop]) {
      final s = await _open(t, size, '/profiles', _signed());
      await s.settle(3500);
      await s.snap('picker', size);
    }
    var s = await _open(t, _phone, '/profiles', _signed(), settle: false, extra: [glassLensSplitProvider.overrideWith((ref) => const GlassLensSplit(centre: Offset(195, 150), radius: 28))]);
    await t.pump(const Duration(milliseconds: 300));
    await t.pump(const Duration(milliseconds: 250));
    await s.snap('picker-lens-split', _phone);
    await t.pump(const Duration(seconds: 2));

    s = await _open(t, _phone, '/profiles', _signed());
    await s.settle(3500);
    await t.tap(find.bySemanticsLabel('Read as Yash'), warnIfMissed: false);
    var at = 0;
    for (final ms in [0, 300, 600, 900]) {
      await t.pump(Duration(milliseconds: ms - at));
      at = ms;
      await s.snap('picker-handoff-${ms}ms', _phone);
    }
    await t.pump(const Duration(seconds: 2));

    s = await _open(t, _phone, '/profiles', _signed());
    await s.settle(3500);
    await t.tap(find.text('Edit'));
    await s.settle(600);
    await s.snap('picker-manage', _phone);

    s = await _open(t, _phone, '/profiles', _signed());
    await s.settle(3500);
    final g = await t.startGesture(t.getCenter(find.bySemanticsLabel('Read as Sunday')));
    await t.pump(const Duration(milliseconds: 600));
    await t.pump(const Duration(milliseconds: 400));
    await s.snap('picker-context-menu', _phone);
    await g.up();
    await s.settle(600);

    s = await _open(t, _phone, '/profiles', const GlassAuthFixture(signedIn: true, profiles: []));
    await s.settle(3500);
    await s.snap('picker-empty', _phone);
    s = await _open(t, _phone, '/profiles', _signed(profilesError: const ApiError(statusCode: 500, code: 'x', message: 'The server had a problem.')));
    await s.settle(3500);
    await s.snap('picker-error', _phone);
    s = await _open(t, _phone, '/profiles', _signed(profilesError: const NetworkError(message: 'x')));
    await s.settle(3500);
    await s.snap('picker-unreachable', _phone);
    s = await _open(t, _phone, '/profiles', _signed(n: 5));
    await s.settle(3500);
    await s.snap('picker-limit', _phone);
    await _end(t);
  });

  testWidgets('profile form: sheet, window, arc, alerts and offline', (t) async {
    var s = await _open(t, _phone, '/profiles', _signed());
    await s.settle(3500);
    await t.tap(find.bySemanticsLabel('Add profile').first, warnIfMissed: false);
    await s.settle(3500);
    await t.enterText(find.byType(TextField).first, 'Late-night reads');
    await s.settle(600);
    await s.snap('profile-form', _phone);
    await t.ensureVisible(find.bySemanticsLabel('Cyan Rocket'));
    await t.tap(find.bySemanticsLabel('Cyan Rocket'));
    await t.pump(const Duration(milliseconds: 140));
    await s.snap('profile-form-avatar-arc', _phone);
    await s.settle(600);
    await t.ensureVisible(find.byType(GlassSwitch).last);
    await t.tap(find.byType(GlassSwitch).last);
    await s.settle(900);
    await s.snap('profile-form-gate-alert', _phone);

    s = await _open(t, kSkinShotDesktop, '/profiles', _signed());
    await s.settle(3500);
    await t.tap(find.bySemanticsLabel('Add profile').first, warnIfMissed: false);
    await s.settle(3500);
    await s.snap('profile-form-window', kSkinShotDesktop);

    s = await _open(t, _phone, '/profiles/new', _signed(), extra: [glassOfflineProvider.overrideWithValue(true)]);
    await s.settle(1200);
    await t.enterText(find.byType(TextField).first, 'Reader');
    await s.settle(500);
    await s.snap('profile-form-offline', _phone);

    s = await _open(t, _phone, '/profiles/2/edit', _signed());
    await s.settle(3500);
    await t.ensureVisible(find.widgetWithText(GlassButton, 'Delete profile'));
    await t.tap(find.widgetWithText(GlassButton, 'Delete profile'));
    await s.settle(900);
    await s.snap('delete-profile-alert', _phone);
    await _end(t);
  });

  testWidgets('manage profiles: sizes and a reorder', (t) async {
    for (final size in [_phone, _tablet]) {
      final s = await _open(t, size, '/profiles/manage', _signed());
      await s.settle(3500);
      await s.snap('manage', size);
    }
    final s = await _open(t, _phone, '/profiles/manage', _signed());
    await s.settle(3500);
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.pump();
    await t.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await t.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await t.pump(const Duration(milliseconds: 120));
    await s.snap('manage-reorder', _phone);
    await s.settle(800);
    await _end(t);
  });

  testWidgets('onboarding: every step on phone and tablet and the moments', (t) async {
    for (var step = 1; step <= 7; step++) {
      for (final size in [_phone, _tablet]) {
        final s = await _open(t, size, '/welcome?step=$step', _step(step));
        await s.settle(step == 1 ? 3500 : 1500);
        await s.snap('onboarding-step$step', size);
      }
    }
    final draft = jsonEncode({
      'taste': {'formats': <String>[], 'genres': {'Fantasy': 2, 'Action': 1, 'Romance': 1, 'Horror': -1, 'Comedy': 2}, 'styles': <String>[], 'seeds': <Object>[]},
      'touched': ['genres'],
      'picks': <int>[],
    });
    var s = await _open(t, _phone, '/welcome?step=4', _step(4), prefs: {'mm.onboarding.draft.u1p1': draft});
    await s.settle(3000);
    await s.snap('onboarding-genres-weights', _phone);
    s = await _open(t, _phone, '/welcome?step=4', _step(4), prefs: {'mm.onboarding.draft.u1p1': draft}, reduced: true);
    await s.settle(3500);
    await s.snap('onboarding-genres-reduced', _phone);
    s = await _open(t, _phone, '/welcome?step=6', _step(6));
    await s.settle(3500);
    await t.tap(find.byType(GlassPoster).first);
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    await s.snap('onboarding-seeds-similar', _phone);
    s = await _open(t, _phone, '/welcome?step=7', _step(7));
    await t.pump(const Duration(milliseconds: 1200));
    await s.snap('onboarding-dots-merge', _phone);
    await t.pump(const Duration(seconds: 3));
    await _end(t);
  });

  testWidgets('solid glass and increase contrast: Login and the picker', (t) async {
    for (final (name, path, f) in [('login', '/login', const GlassAuthFixture()), ('picker', '/profiles', _signed())]) {
      var s = await _open(t, _phone, path, f);
      s.container.read(glassInAppPrefsProvider.notifier).setSolidGlass(true);
      await s.settle(name == 'login' ? 3500 : 1500);
      await s.snap('$name-solid', _phone);
      s = await _open(t, _phone, path, f);
      s.container.read(glassInAppPrefsProvider.notifier).setIncreaseContrast(true);
      await s.settle(name == 'login' ? 3500 : 1500);
      await s.snap('$name-contrast', _phone);
    }
    await _end(t);
  });
}

GlassAuthFixture _signedOutWithProfiles() => GlassAuthFixture(profiles: fixtureProfiles());
