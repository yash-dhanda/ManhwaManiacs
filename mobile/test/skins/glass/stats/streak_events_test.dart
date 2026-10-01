import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/models/library_statistics.dart';
import 'package:manhwamaniacs/features/library/providers/streak_events_provider.dart';
import 'package:manhwamaniacs/features/reader/models/reading_progress.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/parts/streak/plus_one.dart';
import 'package:manhwamaniacs/skins/glass/parts/streak/streak_ui.dart';
import 'package:manhwamaniacs/skins/glass/primitives/streak_flame.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/numbers_fixtures.dart';
import '../primitives/support.dart';
import 'stats_rig.dart';

ProgressAnswer _ans(bool ext, int days, [int secs = 600]) => ProgressAnswer(streak: StreakSnapshot(currentDays: days, extendedToday: ext), todaySeconds: secs);

LibraryStatistics _day(int current, {int longest = 31, List<int> seen = const [7]}) =>
    LibraryStatistics.fromJson(statisticsJson(days: 1, currentDays: current, longestDays: longest, milestonesSeen: seen));

Future<void> _run(WidgetTester t, [int n = 6]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 150));
  }
}

void main() {
  testWidgets('false then true flares once: 8 embers, the toast, no second flare', (t) async {
    final repo = FakeNumbers()..stats[1] = _day(13, seen: [7]);
    final rig = await pumpStats(t, repo);
    GlassHaptics.debugLog.clear();
    StreakFlame.debugEmbers = 0;
    final handle = rig.container.read(progressAnswerHandlerProvider);
    handle(_ans(false, 12));
    await _run(t, 2);
    expect(find.text('13-day streak'), findsNothing);
    handle(_ans(true, 13));
    await _run(t, 2);
    expect(find.text('13-day streak'), findsOneWidget, reason: 'the flare toast');
    expect(StreakFlame.debugEmbers, 8);
    expect(GlassHaptics.debugLog.where((e) => e.event == HapticEvent.streakExtend), hasLength(1));
    expect(rig.container.read(streakUiProvider).flare, 1);
    handle(_ans(true, 13));
    await _run(t, 2);
    expect(rig.container.read(streakUiProvider).flare, 1, reason: 'already extended today');
    await t.pump(const Duration(minutes: 11));
  });

  testWidgets('a sequence starting with true stays quiet', (t) async {
    final rig = await pumpStats(t, FakeNumbers());
    final handle = rig.container.read(progressAnswerHandlerProvider);
    handle(_ans(true, 13));
    handle(_ans(true, 13));
    await _run(t, 2);
    expect(rig.container.read(streakUiProvider).flare, 0);
    expect(find.text('13-day streak'), findsNothing);
    await t.pump(const Duration(minutes: 11));
  });

  testWidgets('a new record shows the sparks and the caption', (t) async {
    final repo = FakeNumbers()..stats[1] = _day(32, longest: 32, seen: [7, 30]);
    final rig = await pumpStats(t, repo);
    final handle = rig.container.read(progressAnswerHandlerProvider);
    handle(_ans(false, 31));
    handle(_ans(true, 32));
    await _run(t);
    expect(rig.container.read(streakUiProvider).sparks, 1);
    expect(find.text('New longest streak: 32 days'), findsOneWidget);
    expect(repo.marked, isEmpty, reason: 'no milestone pending');
    await t.pump(const Duration(minutes: 11));
  });

  testWidgets('a 30-day milestone toasts once and marks 30 (and an unseen 7)', (t) async {
    final repo = FakeNumbers()..stats[1] = _day(30, longest: 30, seen: const []);
    final rig = await pumpStats(t, repo);
    final handle = rig.container.read(progressAnswerHandlerProvider);
    handle(_ans(false, 29));
    handle(_ans(true, 30));
    await _run(t);
    expect(find.text('30 days in a row'), findsOneWidget);
    expect(repo.marked..sort(), [7, 30]);
    expect(find.text('Share'), findsWidgets);
    await t.pump(const Duration(minutes: 11));
  });

  testWidgets('Home chip "+1": plays once per flare, also on the next build after a flare elsewhere', (t) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final home = ValueNotifier(true);
    final host = primHost(
      ValueListenableBuilder<bool>(valueListenable: home, builder: (_, on, __) => on ? const GlassPlusOne(child: SizedBox(width: 80, height: 32)) : const SizedBox()),
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
    );
    await t.pumpWidget(host);
    final c = ProviderScope.containerOf(t.element(find.byType(GlassPlusOne)));
    expect(find.text('+1'), findsNothing);
    c.read(streakUiProvider.notifier).flare();
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('+1'), findsOneWidget);
    await t.pump(const Duration(seconds: 3));
    expect(find.text('+1'), findsNothing);
    // Away from Home: the flare happens, then Home builds again.
    home.value = false;
    await t.pump();
    c.read(streakUiProvider.notifier).flare();
    home.value = true;
    await t.pump();
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('+1'), findsOneWidget, reason: 'the next build plays it');
    await t.pump(const Duration(seconds: 3));
    home.value = false;
    await t.pump();
    home.value = true;
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('+1'), findsNothing, reason: 'once');
  });

  testWidgets('the milestone Share opens Statistics with the streak share intent', (t) async {
    final repo = FakeNumbers()..stats[1] = _day(7, seen: const []);
    final rig = await pumpStats(t, repo, start: '/library/statistics?range=7');
    final handle = rig.container.read(progressAnswerHandlerProvider);
    handle(_ans(false, 6));
    handle(_ans(true, 7));
    await _run(t);
    expect(find.text('7 days in a row'), findsOneWidget);
    await t.tap(find.text('Share').last);
    await _run(t, 3);
    expect(rig.at, Routes.numbers());
    await t.pump(const Duration(minutes: 11));
  });
}
