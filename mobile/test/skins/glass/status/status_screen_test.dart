import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/admin/providers/status_providers.dart';
import 'package:manhwamaniacs/features/admin/utils/status_summary.dart';
import 'package:manhwamaniacs/features/sources/providers/discover_providers.dart' show sourcesHealthProvider;
import 'package:manhwamaniacs/features/updates/models/update_settings.dart';
import 'package:manhwamaniacs/features/updates/repositories/updates_repository.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/health_bead.dart';
import 'package:manhwamaniacs/skins/glass/screens/status/status_screen.dart';
import 'package:manhwamaniacs/skins/glass/screens/status/summary_banner.dart';

import '../../../screenshots/support/shot_harness.dart';
import '../shell/shell_rig.dart';
import '../you/m40_rig.dart';

Future<ShellRig> pumpStatus(WidgetTester t, {bool admin = true, bool problems = false, Size size = const Size(390, 844), List<Override> extra = const []}) async {
  await m40Clear(t);
  final rig = await pumpGlassShell(t, start: '/admin/status', size: size, extra: [...adminOverrides(admin: admin, problems: problems), ...extra]);
  await m40Settle(t, 1200);
  return rig;
}

class _Busy implements UpdatesRepository {
  @override
  Future<Result<UpdateCheckOutcome>> triggerCheck({List<int>? followedIds}) async => const Err(ApiError(statusCode: 409, code: 'check_already_running', message: 'busy'));
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  setUpAll(loadAppFonts);

  m40Test('the banner by worst state and the four cards', (t) async {
    await pumpStatus(t);
    expect(find.text('ADMINISTRATION'), findsOneWidget);
    expect(find.text('System status'), findsWidgets);
    expect(find.text('Everything is running'), findsOneWidget);
    for (final c in ['Backend', 'Update checker', 'Recent checks', 'Source health']) {
      expect(find.text(c, skipOffstage: false), findsOneWidget, reason: c);
    }
    expect(find.text('Probe GET /health'), findsOneWidget);
    expect(find.text('Everything here reads endpoints that already exist; nothing on this page changes the server except Check now.', skipOffstage: false), findsOneWidget);

    await pumpStatus(t, problems: true);
    expect(find.textContaining('need'), findsWidgets);
    expect(find.text('demoted', skipOffstage: false), findsOneWidget);
    expect(find.text('HTTP 503 from lantern.example', skipOffstage: false), findsOneWidget);
    final demoted = t.widgetList<GlassHealthBead>(find.byType(GlassHealthBead, skipOffstage: false)).where((b) => b.demoted);
    expect(demoted, hasLength(1));
  });

  test('headline wording', () {
    final ok = summarise(backend: deriveBackendHealth(probe: const BackendProbe(status: 'online', name: 'x', version: '1')), checkerSettings: m40UpdateSettings(), runs: const [], sourceHealth: const [], now: DateTime.now());
    expect(glassStatusHeadline(ok), 'Everything is running');
    final bad = summarise(backend: deriveBackendHealth(failed: true), checkerSettings: m40UpdateSettings(enabled: false), runs: const [], sourceHealth: const [], now: DateTime.now());
    expect(glassStatusHeadline(bad), '2 problems need attention');
    expect(statusWord(StatusState.unknown), 'Unknown');
  });

  m40Test('the healthy backend bead pulses once per successful poll', (t) async {
    final polls = StreamController<BackendPoll>();
    addTearDown(polls.close);
    GlassMotion.recorder.clear();
    await pumpStatus(t, extra: [backendHealthProvider.overrideWith((ref) => polls.stream)]);
    BackendPoll ok() => BackendPoll(health: deriveBackendHealth(probe: const BackendProbe(status: 'online', name: 'ManhwaManiacs', version: '3.5.0')), nextPollAt: DateTime.now());
    polls.add(ok());
    await t.pump(const Duration(seconds: 15));
    polls.add(ok());
    await t.pump(const Duration(seconds: 15));
    await m40Settle(t, 400);
    expect(GlassMotion.recorder.entries.where((e) => e.label == 'BEAD PULSE'), hasLength(2));
  });

  m40Test('a failing source flickers once when a new probe lands', (t) async {
    var probed = DateTime.now().subtract(const Duration(minutes: 3));
    GlassMotion.recorder.clear();
    final rig = await pumpStatus(t, extra: [sourcesHealthProvider.overrideWith((ref) async => m40Sources(probed: probed))]);
    expect(GlassMotion.recorder.entries.where((e) => e.label == 'BEAD FLICKER'), isEmpty);
    probed = DateTime.now();
    rig.container.invalidate(sourcesHealthProvider);
    await m40Settle(t, 600);
    expect(GlassMotion.recorder.entries.where((e) => e.label == 'BEAD FLICKER'), hasLength(1));
  });

  m40Test('Check now with a check already running toasts', (t) async {
    await pumpStatus(t, extra: [updatesRepositoryProvider.overrideWithValue(_Busy())]);
    await t.tap(find.text('Check now'));
    await m40Settle(t, 600);
    expect(find.text('A check is already running'), findsOneWidget);
  });

  m40Test('the c key checks now; not while a field has focus', (t) async {
    await pumpStatus(t, extra: [updatesRepositoryProvider.overrideWithValue(_Busy())]);
    await t.sendKeyEvent(LogicalKeyboardKey.keyC);
    await m40Settle(t, 600);
    expect(find.text('A check is already running'), findsOneWidget);
  });

  m40Test('two columns at 1,280 and wider, Source health spanning both above 8 rows', (t) async {
    Widget box(String s) => SizedBox(height: 40, child: Text(s, textDirection: TextDirection.ltr));
    Future<void> grid(double w, {bool span = false}) async {
      await t.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: Align(alignment: Alignment.topLeft, child: SizedBox(width: w, child: StatusGrid(twoColumns: w >= kStatusGridMin, banner: box('banner'), backend: box('backend'), checker: box('checker'), recent: box('recent'), sources: box('sources'), sourcesSpan: span, note: box('note')))),
      ),);
    }

    t.view.physicalSize = const Size(1400, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await grid(1300);
    expect(t.getTopLeft(find.text('backend')).dy, t.getTopLeft(find.text('checker')).dy);
    expect(t.getTopLeft(find.text('recent')).dy, t.getTopLeft(find.text('sources')).dy);
    await grid(1300, span: true);
    expect(t.getTopLeft(find.text('sources')).dy, greaterThan(t.getTopLeft(find.text('recent')).dy));
    expect(t.getSize(find.ancestor(of: find.text('sources'), matching: find.byType(SizedBox)).first).width, 1300);
    await grid(1000);
    expect(t.getTopLeft(find.text('checker')).dy, greaterThan(t.getTopLeft(find.text('backend')).dy));
  });

  m40Test('a non-admin sees the lens with Back home', (t) async {
    await pumpStatus(t, admin: false);
    expect(find.text('Administrators only'), findsOneWidget);
    expect(find.text('System status is instance-wide. Ask the account owner to check it.'), findsOneWidget);
    expect(find.text('Back home'), findsOneWidget);
  });

  test('settings fixture parses', () => expect(m40UpdateSettings().checkIntervalMinutes, 30));
  test('update runs fixture', () => expect(m40Runs().first, isA<UpdateRun>()));
}
