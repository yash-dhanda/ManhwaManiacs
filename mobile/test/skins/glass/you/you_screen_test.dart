import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/novels/providers/narration_jobs_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novels_gate_provider.dart';
import 'package:manhwamaniacs/features/settings/models/app_version.dart';
import 'package:manhwamaniacs/skins/glass/listen/narrating_chip.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/screens/you/orb_lift.dart';
import 'package:manhwamaniacs/skins/glass/screens/you/you_lists.dart';
import 'package:manhwamaniacs/skins/glass/screens/you/you_screen.dart';

import '../../../screenshots/support/shot_harness.dart';
import '../shell/shell_rig.dart';
import 'm40_rig.dart';

Future<ShellRig> pumpYou(WidgetTester t, {bool admin = true, Size size = const Size(390, 844), List<Override> extra = const [], DateTime? now, bool android = false, bool sharing = true}) async {
  await m40Clear(t);
  final rig = await pumpGlassShell(
    t,
    start: '/more',
    size: size,
    platformAndroid: android,
    extra: [
      ...youOverrides(admin: admin, sharing: sharing),
      youClockProvider.overrideWithValue(() => now ?? m40Now),
      ...extra,
    ],
  );
  await m40Settle(t, 1500);
  return rig;
}

Future<void> scrollTo(WidgetTester t, String text) async {
  final s = find.byType(Scrollable).first;
  for (var i = 0; i < 40 && find.text(text).hitTestable().evaluate().isEmpty; i++) {
    await t.drag(s, const Offset(0, -200));
    await t.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUpAll(loadAppFonts);

  m40Test('profile block, Reading card with this week and the Circle card', (t) async {
    await pumpYou(t);
    expect(find.text('You'), findsWidgets);
    expect(find.text('@yash · Administrator'), findsOneWidget);
    expect(find.text('Switch profile'), findsOneWidget);
    expect(find.text('12-day streak'), findsOneWidget);
    expect(find.textContaining('This week: '), findsOneWidget);
    expect(find.text('Circle'), findsWidgets);
    expect(find.textContaining('Aarav'), findsWidgets);
  });

  m40Test('the Wrapped card shows from 1 December to 31 January only', (t) async {
    await pumpYou(t, now: DateTime(2026, 11, 30));
    expect(find.text('Your 2026 in chapters'), findsNothing);
    await pumpYou(t, now: DateTime(2026, 12));
    expect(find.text('Your 2026 in chapters'), findsOneWidget);
    await pumpYou(t, now: DateTime(2027, 1, 31));
    expect(find.text('Your 2026 in chapters'), findsOneWidget);
  });

  m40Test('a profile that does not share sees the Read together line', (t) async {
    await pumpYou(t, sharing: false);
    expect(find.text('Read together: share what this profile reads with the other readers on this server.'), findsOneWidget);
    expect(find.text('Turn on sharing'), findsOneWidget);
  });

  m40Test('admin rows hide for a non-admin; Server shows on phones; Shortcuts only on wider frames', (t) async {
    await pumpYou(t, admin: false);
    expect(find.text('@yash'), findsOneWidget);
    expect(find.text('Notifications', skipOffstage: false), findsNothing);
    expect(find.text('Backup', skipOffstage: false), findsNothing);
    expect(find.text('System status', skipOffstage: false), findsNothing);
    expect(find.text('Members', skipOffstage: false), findsNothing);
    expect(find.text('Server', skipOffstage: false), findsOneWidget);
    expect(find.text('Shortcuts', skipOffstage: false), findsNothing);

    await pumpYou(t, size: const Size(834, 1194));
    expect(find.text('Shortcuts', skipOffstage: false), findsOneWidget);
    expect(find.text('System status', skipOffstage: false), findsOneWidget);
    expect(find.text('Members', skipOffstage: false), findsOneWidget);
    expect(find.text('Notifications', skipOffstage: false), findsOneWidget);
  });

  m40Test('Dialogue search hides in Novels mode', (t) async {
    await pumpYou(t);
    expect(find.text('Dialogue search', skipOffstage: false), findsOneWidget);
    await pumpYou(t, extra: [novelsEnabledProvider.overrideWithValue(true), contentModeControllerProvider.overrideWith(_Novel.new)]);
    expect(find.text('Dialogue search', skipOffstage: false), findsNothing);
  });

  m40Test('the Downloads row carries the Narrating chip (chapters in flight) while narration jobs run', (t) async {
    final jobs = [for (var i = 0; i < 3; i++) NarrationJob(sourceId: 'novels', seriesKey: 'n$i', title: 'Book $i', done: 1, total: 4)];
    await pumpYou(t, extra: [activeNarrationJobsProvider.overrideWithValue(jobs)]);
    expect(find.byType(GlassNarratingChip, skipOffstage: false), findsOneWidget);
    expect(find.text('Narrating 4', skipOffstage: false), findsOneWidget);
  });

  test('update row lines on Android', () {
    expect(youUpdateLine(const AsyncLoading()).line, 'Checking…');
    expect(youUpdateLine(AsyncError(StateError('x'), StackTrace.empty)), (line: "Couldn't check for updates", warning: true, retry: true, open: false));
    expect(youUpdateLine(const AsyncData(null)).line, 'Server unreachable');
    const up = AppVersionInfo(remoteVersion: '3.5.1', remoteBuild: 58, localVersion: '3.5.0', localBuild: 57, downloadUrl: 'https://x/app.apk', channel: AppUpdateChannel.apk);
    expect(youUpdateLine(const AsyncData(up)).line, 'Update available · 3.5.1');
    const same = AppVersionInfo(remoteVersion: '3.5.0', remoteBuild: 57, localVersion: '3.5.0', localBuild: 57, downloadUrl: 'https://x/app.apk', channel: AppUpdateChannel.apk);
    expect(youUpdateLine(const AsyncData(same)).line, 'Up to date');
  });

  m40Test('iOS reads "Managed by SideStore"; the version row reads the package info', (t) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await pumpYou(t);
    expect(find.text('Managed by SideStore', skipOffstage: false), findsOneWidget);
    expect(find.text('ManhwaManiacs 3.5.0 (57)', skipOffstage: false), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  group('Orb lift', () {
    setUp(() => GlassMotion.recorder.clear());
    int lifts() => GlassMotion.recorder.entries.where((e) => e.label == 'ORB LIFT').length;

    m40Test('plays once per app session per profile on the phone frame', (t) async {
      final rig = await pumpYou(t);
      expect(lifts(), 1);
      expect(rig.container.read(youOrbLiftShownProvider), contains(1));
      rig.router.go('/settings');
      await m40Settle(t, 800);
      rig.router.go('/more');
      await m40Settle(t, 800);
      expect(lifts(), 1, reason: 'a second visit cross-fades');
    });

    m40Test('never on the tablet frame', (t) async {
      await pumpYou(t, size: const Size(834, 1194));
      expect(lifts(), 0);
    });

    m40Test('reduced motion: a 200 ms cross-fade', (t) async {
      final rig = await pumpGlassShell(t, extra: [...youOverrides(), youClockProvider.overrideWithValue(() => m40Now)]);
      rig.container.read(glassInAppPrefsProvider.notifier).setReduceMotion(true);
      await t.pump(const Duration(milliseconds: 100));
      rig.router.go('/more');
      await m40Settle(t, 1500);
      final e = GlassMotion.recorder.entries.where((e) => e.label == 'ORB LIFT').toList();
      expect(e, hasLength(1));
      expect(e.single.plannedMs, 200);
    });
  });
}

class _Novel extends ContentModeController {
  @override
  ContentMode build() => ContentMode.novel;
}
