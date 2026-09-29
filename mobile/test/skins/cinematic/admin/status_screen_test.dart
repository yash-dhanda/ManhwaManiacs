// ignore_for_file: directives_ordering
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/admin/providers/status_providers.dart';
import 'package:manhwamaniacs/features/admin/utils/status_summary.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/models/auth_user.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/features/sources/models/source_health.dart';
import 'package:manhwamaniacs/features/sources/providers/discover_providers.dart';
import 'package:manhwamaniacs/features/updates/models/update_settings.dart';
import 'package:manhwamaniacs/features/updates/repositories/updates_repository.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/admin/status_screen.dart';
import 'package:manhwamaniacs/skins/skin_haptics.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/test_overrides.dart';
import '../downloads/downloads_rig.dart' show HapticLog, heading, rigTheme, settle, typed;

class _Member extends AuthController {
  @override
  AuthState build() => AuthAuthenticated(AuthUser(id: 2, username: 'guest', isAdmin: false, createdAt: DateTime.utc(2024)));
}

class _Resolving extends AuthController {
  @override
  AuthState build() => const AuthUnknown();
}

class FakeUpdatesRepo implements UpdatesRepository {
  FakeUpdatesRepo({this.conflict = false});
  final bool conflict;
  int checks = 0;

  @override
  Future<Result<UpdateCheckOutcome>> triggerCheck({List<int>? followedIds}) async {
    checks++;
    if (conflict) return const Err(ApiError(statusCode: 409, code: 'check_already_running', message: 'busy'));
    return const Ok(UpdateCheckOutcome(queued: false));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

SourceSummary src(String id, SourceHealthStatus status, {int fails = 0, bool demoted = false, String? err}) => SourceSummary(
      id: id,
      name: 'Source $id',
      description: '',
      browsable: true,
      supportsImport: false,
      health: SourceHealth(status: status, consecutiveFailures: fails, demoted: demoted, lastError: err, lastCheckedAt: DateTime.now().subtract(const Duration(minutes: 4))),
    );

UpdateRun run(int id, String status, {String? error}) => UpdateRun(
      id: id,
      trigger: 'scheduled',
      status: status,
      seriesChecked: 212,
      newChaptersFound: 3,
      error: error,
      startedAt: DateTime.now().subtract(Duration(minutes: 10 * id)),
      finishedAt: DateTime.now().subtract(Duration(minutes: 10 * id - 1)),
    );

class StatusRig {
  StatusRig({
    this.admin = true,
    this.resolving = false,
    this.backend,
    this.sources = const [],
    this.runs = const [],
    this.settings,
    this.settingsError = false,
    this.conflict = false,
  });
  final bool admin, resolving, settingsError, conflict;
  final BackendHealth? backend;
  final List<SourceSummary> sources;
  final List<UpdateRun> runs;
  final UpdateSettings? settings;
  final List<String> haptics = [];
  late final FakeUpdatesRepo repo = FakeUpdatesRepo(conflict: conflict);
  late final ProviderContainer container;
}

BackendHealth healthyBackend() => deriveBackendHealth(probe: const BackendProbe(status: 'online', name: 'ManhwaManiacs', version: '3.5.0'));

Future<StatusRig> pumpStatus(
  WidgetTester tester, {
  StatusRig? rig,
  Size size = const Size(390, 844),
  bool reduced = false,
}) async {
  final r = rig ?? StatusRig();
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(testPrefsDefaults());
  final prefs = await SharedPreferences.getInstance();
  r.container = ProviderContainer(
    overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      apiBaseUrlOverride('http://example.test'),
      if (r.resolving)
        authControllerProvider.overrideWith(_Resolving.new)
      else if (r.admin)
        authenticatedAuthOverride()
      else
        authControllerProvider.overrideWith(_Member.new),
      activeProfileOverride(),
      ...contentModeOverrides(),
      backendHealthProvider.overrideWith((ref) => Stream.value(BackendPoll(health: r.backend ?? healthyBackend(), nextPollAt: DateTime.now().add(const Duration(seconds: 15))))),
      updateSettingsProvider.overrideWith((ref) async {
        if (r.settingsError) throw const ApiError(statusCode: 500, code: 'boom', message: 'Server exploded');
        return r.settings ??
            UpdateSettings(enabled: true, checkIntervalMinutes: 30, notifyEnabled: true, checkOnStartup: true, lastRunAt: DateTime.now().subtract(const Duration(minutes: 12)));
      }),
      updateRunsProvider.overrideWith((ref) async => r.runs),
      sourcesHealthProvider.overrideWith((ref) async => r.sources),
      updatesRepositoryProvider.overrideWithValue(r.repo),
      skinHapticsProvider.overrideWithValue(HapticLog(r.haptics)),
    ],
  );
  addTearDown(r.container.dispose);
  final router = GoRouter(
    initialLocation: '/admin/status',
    routes: [
      GoRoute(path: '/admin/status', builder: (context, state) => const StatusScreen()),
      GoRoute(path: '/:rest(.*)', builder: (context, state) => Scaffold(body: Text('at ${state.uri}'))),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: r.container,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        theme: rigTheme(TargetPlatform.android),
        builder: (context, c) => MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: reduced), child: c!),
      ),
    ),
  );
  await settle(tester, ms: 800);
  return r;
}

/// Ends the test with the screen unmounted so its periodic timers are cancelled.
Future<void> unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('healthy: everything is running, credits and footnote', (tester) async {
    await pumpStatus(tester, rig: StatusRig(sources: [src('a', SourceHealthStatus.ok)], runs: [run(1, 'completed')]));
    expect(heading('System status'), findsOneWidget);
    expect(find.text('ADMINISTRATION'), findsOneWidget);
    expect(typed('Everything is running.'), findsOneWidget);
    expect(find.text('HEALTHY'), findsOneWidget);
    expect(find.text('GET /health'), findsOneWidget);
    expect(find.text('3.5.0'), findsOneWidget);
    expect(find.text('LIVE · 15 S'), findsOneWidget);
    await tester.scrollUntilVisible(find.textContaining('Everything on this page'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('nothing here changes a setting except Check now'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('two problems: the headline counts them in digits and the problems are listed', (tester) async {
    await pumpStatus(
      tester,
      rig: StatusRig(
        sources: [src('a', SourceHealthStatus.dead, fails: 10, err: 'NXDOMAIN'), src('b', SourceHealthStatus.failing, fails: 2)],
        runs: [run(1, 'completed')],
      ),
    );
    expect(typed('2 things need attention.'), findsOneWidget);
    expect(find.textContaining('Source a: Unreachable'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('update checker credits and failed runs in proof', (tester) async {
    await pumpStatus(tester, rig: StatusRig(runs: [run(2, 'failed', error: 'registry unavailable'), run(1, 'completed')]));
    await tester.scrollUntilVisible(find.text('FAILED RUNS (RECENT)'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('INTERVAL'), findsOneWidget);
    expect(find.text('30 MIN'), findsOneWidget);
    expect(find.text('registry unavailable'), findsWidgets);
    expect(find.text('Check now'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('Check now toasts and maps a 409 to "A check is already running."', (tester) async {
    final r = await pumpStatus(tester, rig: StatusRig(conflict: true));
    await tester.scrollUntilVisible(find.text('Check now'), 300, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Check now'));
    await settle(tester, ms: 300);
    expect(r.repo.checks, 1);
    expect(r.container.read(cineToastsProvider).any((t) => t.text == 'A check is already running.'), isTrue);
    expect(r.haptics, contains('error'));
    await unmount(tester);
  });

  testWidgets('recent checks: badges, counts and the empty line', (tester) async {
    await pumpStatus(tester, rig: StatusRig(runs: [run(1, 'completed'), run(2, 'running'), run(3, 'failed', error: 'x')]));
    await tester.scrollUntilVisible(find.text('RECENT CHECKS'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('FINISHED'), findsOneWidget);
    expect(find.text('RUNNING'), findsOneWidget);
    expect(find.text('FAILED'), findsOneWidget);
    expect(find.text('212 SERIES · 3 NEW'), findsWidgets);
    await unmount(tester);
  });

  testWidgets('recent checks empty', (tester) async {
    await pumpStatus(tester);
    await tester.scrollUntilVisible(find.text('No update checks have run yet.'), 300, scrollable: find.byType(Scrollable).first);
    await unmount(tester);
  });

  testWidgets('source health: worst first, demoted badge and collapsible last error', (tester) async {
    await pumpStatus(
      tester,
      rig: StatusRig(sources: [src('good', SourceHealthStatus.ok), src('bad', SourceHealthStatus.dead, fails: 9, demoted: true, err: 'NXDOMAIN')]),
    );
    await tester.scrollUntilVisible(find.text('SOURCE HEALTH'), 300, scrollable: find.byType(Scrollable).first);
    await tester.scrollUntilVisible(find.text('Source bad'), 300, scrollable: find.byType(Scrollable).first);
    final bad = tester.getTopLeft(find.text('Source bad')).dy;
    final good = tester.getTopLeft(find.text('Source good')).dy;
    expect(bad, lessThan(good));
    expect(find.text('DEMOTED'), findsOneWidget);
    expect(find.text('NXDOMAIN'), findsNothing);
    await tester.tap(find.text('LAST ERROR'));
    await settle(tester, ms: 300);
    expect(find.text('NXDOMAIN'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('tablet: the source table scrolls sideways inside itself', (tester) async {
    await pumpStatus(tester, size: const Size(834, 1194), rig: StatusRig(sources: [src('a', SourceHealthStatus.ok)]));
    await tester.scrollUntilVisible(find.byKey(const Key('source-table-scroll')), 300, scrollable: find.byType(Scrollable).first);
    final scroll = tester.widget<SingleChildScrollView>(find.byKey(const Key('source-table-scroll')));
    expect(scroll.scrollDirection, Axis.horizontal);
    await unmount(tester);
  });

  testWidgets('a card in error shows CORRECTION and retries alone', (tester) async {
    await pumpStatus(tester, rig: StatusRig(settingsError: true));
    await tester.scrollUntilVisible(find.textContaining('Server exploded', findRichText: true), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('Retry'), findsWidgets);
    await unmount(tester);
  });

  testWidgets('non-admin: ADMINISTRATORS ONLY and Back to Tonight', (tester) async {
    await pumpStatus(tester, rig: StatusRig(admin: false));
    expect(find.text('ADMINISTRATORS ONLY'), findsOneWidget);
    expect(typed('System status is instance-wide.'), findsOneWidget);
    expect(find.text('Ask the owner to check it.'), findsOneWidget);
    expect(find.text('Back to Tonight'), findsOneWidget);
    expect(find.text('HEALTHY'), findsNothing);
    await unmount(tester);
  });

  testWidgets('resolving shows the masthead only', (tester) async {
    await pumpStatus(tester, rig: StatusRig(resolving: true));
    expect(heading('System status'), findsOneWidget);
    expect(find.text('BACKEND'), findsNothing);
    expect(find.text('ADMINISTRATORS ONLY'), findsNothing);
    await unmount(tester);
  });

  testWidgets('hardware keys: r refreshes, c checks now', (tester) async {
    final r = await pumpStatus(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
    await settle(tester, ms: 300);
    expect(r.repo.checks, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
    await settle(tester, ms: 600);
    await unmount(tester);
  });

  testWidgets('reduced motion: the headline is complete at once', (tester) async {
    await pumpStatus(tester, reduced: true, rig: StatusRig(sources: [src('a', SourceHealthStatus.ok)]));
    expect(find.text('Everything is running.'), findsWidgets);
    await unmount(tester);
  });
}
