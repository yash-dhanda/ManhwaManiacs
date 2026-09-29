// ignore_for_file: require_trailing_commas, directives_ordering
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/downloads/providers/mature_gate_provider.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/features/settings/repositories/mature_settings_repository.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/cinematic_skin.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart' show CinePressable;
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_certificate_dialog.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_switch.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toast_host.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/shared/mature_gate_switch.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/skin_haptics.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/test_overrides.dart';
import '../auth/auth_test_support.dart' show SeededActive, settle;
import '../primitives/cine_harness.dart' show TestHaptics;

class _Repo implements MatureSettingsRepository {
  _Repo({this.value = false, this.fail = false}) : hold = null;
  bool value;
  bool fail;
  Completer<void>? hold;
  final writes = <bool>[];

  @override
  Future<Result<bool>> getMatureEnabled() async => Ok(value);

  @override
  Future<Result<bool>> setMatureEnabled(bool enabled) async {
    await hold?.future;
    writes.add(enabled);
    if (fail) return const Err(NetworkError(message: 'x'));
    value = enabled;
    return Ok(enabled);
  }
}

const _yash = ActiveProfile(id: 1, name: 'Yash', avatarKey: 'violet', mood: Mood.neutral);

Future<(ProviderContainer, List<HapticEvent>)> _pump(WidgetTester t, _Repo repo, {ActiveProfile? active = _yash}) async {
  SharedPreferences.setMockInitialValues(testPrefsDefaults());
  final sp = await SharedPreferences.getInstance();
  final haptics = <HapticEvent>[];
  final c = ProviderContainer(overrides: [
    sharedPrefsProvider.overrideWithValue(sp),
    matureSettingsRepositoryProvider.overrideWithValue(repo),
    activeProfileProvider.overrideWith(() => SeededActive(active)),
    skinHapticsProvider.overrideWithValue(TestHaptics(haptics)),
  ],);
  addTearDown(c.dispose);
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, __) => const Scaffold(body: SingleChildScrollView(child: MatureGateSwitch.settings()))),
    GoRoute(path: '/profiles', builder: (_, __) => const Scaffold(body: Text('PICKER'))),
  ]);
  addTearDown(router.dispose);
  await t.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp.router(
      theme: CinematicSkin.baseTheme,
      routerConfig: router,
      builder: (context, child) => CineToastHost(child: child!),
    ),
  ),);
  await t.pump();
  await t.pump(const Duration(milliseconds: 50));
  await t.pump(const Duration(milliseconds: 50));
  return (c, haptics);
}

Finder _toggle() => find.descendant(of: find.byType(CineSwitch), matching: find.byType(CinePressable));

void main() {
  testWidgets('off: label and description; turning on opens the certificate and only Enable 18+ opens the gate', (t) async {
    final repo = _Repo();
    final (c, haptics) = await _pump(t, repo);
    expect(find.text('Show mature content (18+)'), findsOneWidget);
    expect(find.text('Adult sources, series, search results and recommendations. Off by default.'), findsOneWidget);
    await t.tap(_toggle());
    await settle(t, 800);
    expect(find.byType(CineCertificateDialog), findsOneWidget);
    expect(find.text('Show mature content on Yash?'), findsOneWidget);
    expect(repo.writes, isEmpty, reason: 'nothing is written before the certificate is confirmed');
    expect(t.widget<CineButton>(find.byKey(const Key('cert-enable'))).onPressed, isNull);
    await t.tap(find.byKey(const Key('cert-check')));
    await t.pump();
    await t.tap(find.byKey(const Key('cert-enable')));
    await t.pump(const Duration(milliseconds: 100));
    await settle(t, 1500);
    expect(repo.writes, [true]);
    expect(find.byType(CineCertificateDialog), findsNothing);
    expect(t.widget<CineSwitch>(find.byType(CineSwitch)).value, isTrue);
    expect(haptics, contains(HapticEvent.gateConfirm));
    expect(c.read(matureGateOpenProvider), isTrue, reason: 'the device stores follow the gate');
  });

  testWidgets('cancelling the certificate leaves the switch off and writes nothing', (t) async {
    final repo = _Repo();
    await _pump(t, repo);
    await t.tap(_toggle());
    await settle(t, 800);
    await t.tap(find.byKey(const Key('cert-cancel-top')));
    await settle(t, 800);
    expect(repo.writes, isEmpty);
    expect(t.widget<CineSwitch>(find.byType(CineSwitch)).value, isFalse);
  });

  testWidgets('turning off needs no confirmation, hides at once and toasts', (t) async {
    final repo = _Repo(value: true);
    final (c, _) = await _pump(t, repo);
    expect(t.widget<CineSwitch>(find.byType(CineSwitch)).value, isTrue);
    await t.tap(_toggle());
    await t.pump(const Duration(milliseconds: 300));
    expect(repo.writes, [false]);
    expect(find.byType(CineCertificateDialog), findsNothing);
    expect(c.read(cineToastsProvider).map((x) => x.text), contains('18+ content hidden on Yash'));
    expect(c.read(matureGateOpenProvider), isFalse);
  });

  testWidgets('loading: the knob is the leader dial and the switch is already at its new value', (t) async {
    final repo = _Repo(value: true)..hold = Completer<void>();
    await _pump(t, repo);
    await t.tap(_toggle());
    await t.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('cine-switch-knob')), findsNothing, reason: 'the knob became the dial');
    repo.hold!.complete();
    await t.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('cine-switch-knob')), findsOneWidget);
  });

  testWidgets('error: the switch reverts and says "Couldn\'t change this setting."', (t) async {
    final repo = _Repo(value: true, fail: true);
    await _pump(t, repo);
    await t.tap(_toggle());
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text("Couldn't change this setting."), findsOneWidget);
    expect(t.widget<CineSwitch>(find.byType(CineSwitch)).value, isTrue, reason: 'reverted');
    await t.pump(const Duration(milliseconds: 2100));
  });

  testWidgets('blocked without an active profile: disabled, the explanation and Choose a profile', (t) async {
    await _pump(t, _Repo(), active: null);
    expect(find.text("No reading profile is active, so there's nowhere to save this yet."), findsOneWidget);
    expect(t.widget<CineSwitch>(find.byType(CineSwitch)).onChanged, isNull);
    await t.tap(find.text('Choose a profile'));
    await settle(t, 800);
    expect(find.text('PICKER'), findsOneWidget);
  });

}
