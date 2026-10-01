import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'dart:async';

import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/skins/glass/parts/streak/streak_ui.dart';
import 'package:manhwamaniacs/skins/glass/screens/stats/statistics_screen.dart';

import '../../../support/numbers_fixtures.dart';
import 'stats_rig.dart';

void main() {
  test('range params', () {
    expect(rangeFromParam('year'), 365);
    expect(rangeFromParam('7'), 7);
    expect(rangeFromParam('x'), isNull);
    expect(rangeParam(365), 'year');
    expect(rangeParam(90), '90');
  });

  testWidgets('the hero, the totals, the charts and the footnotes', (t) async {
    final repo = FakeNumbers();
    await pumpStats(t, repo);
    expect(find.byType(GlassStatisticsScreen), findsOneWidget);
    expect(repo.statisticsDays.first, 30);
    expect(find.text('12-day streak'), findsOneWidget);
    expect(find.text('Longest: 31 days'), findsOneWidget);
    expect(find.textContaining('Days start at UTC+05:30'), findsOneWidget);
    expect(find.text('Time read'), findsOneWidget);
    expect(find.text('Series'), findsWidgets);
    await t.pump(const Duration(minutes: 11));
  });

  testWidgets('the Year range asks for 365 days and shows the heatmap', (t) async {
    final repo = FakeNumbers();
    await pumpStats(t, repo);
    await t.tap(find.text('Year'));
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 300));
    }
    expect(repo.statisticsDays, contains(365));
    expect(find.text('Chapters per week'), findsOneWidget);
    expect(find.bySemanticsLabel('Reading heatmap'), findsWidgets);
    await t.pump(const Duration(minutes: 11));
  });

  testWidgets('a streak share intent set before the data lands is consumed once it does', (t) async {
    final repo = FakeNumbers()..gate = Completer<void>();
    final rig = await pumpStats(t, repo, settle: false);
    rig.container.read(statsShareIntentProvider.notifier).state = 'streak';
    await t.pump(const Duration(milliseconds: 300));
    expect(rig.container.read(statsShareIntentProvider), 'streak');
    repo.gate!.complete();
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 300));
    }
    expect(rig.container.read(statsShareIntentProvider), isNull);
    await t.pump(const Duration(minutes: 11));
  });

  testWidgets('the URL wins on open', (t) async {
    final repo = FakeNumbers();
    await pumpStats(t, repo, start: '/library/statistics?range=7');
    expect(repo.statisticsDays.first, 7);
    await t.pump(const Duration(minutes: 11));
  });

  testWidgets('no streak shows the unlit wick and the start line', (t) async {
    final repo = FakeNumbers(stats: {30: statisticsFixture(currentDays: 0)});
    await pumpStats(t, repo);
    expect(find.text('No streak'), findsWidgets);
    expect(find.textContaining('Longest: 31 days. Start a new one today.'), findsOneWidget);
    await t.pump(const Duration(minutes: 11));
  });

  testWidgets('at risk names the one chapter to read', (t) async {
    final repo = FakeNumbers(stats: {30: statisticsFixture(atRisk: true, today: DateTime(2026, 9, 28))});
    await pumpStats(t, repo, now: DateTime(2026, 9, 29, 21));
    expect(find.text('Read one chapter to keep your 12-day streak'), findsOneWidget);
    await t.pump(const Duration(minutes: 11));
  });

  testWidgets('offline with a snapshot keeps the content under a warning', (t) async {
    final repo = FakeNumbers(failWith: const NetworkError(message: 'down'));
    final json = statisticsJson();
    const key = 'mm.numbers.last.30.u1p1';
    await pumpStats(t, repo, prefs: {key: '{"savedAt":"${DateTime(2026, 9, 29, 13).toUtc().toIso8601String()}","payload":${_enc(json)}}'});
    expect(find.textContaining('Last updated'), findsOneWidget);
    expect(find.text('12-day streak'), findsOneWidget);
    await t.pump(const Duration(minutes: 11));
  });

  testWidgets('an error with nothing saved shows the retry lens', (t) async {
    final repo = FakeNumbers(failWith: const UnknownError(message: 'boom'));
    await pumpStats(t, repo);
    expect(find.text("Couldn't load your reading"), findsWidgets);
    expect(find.text('Try again'), findsOneWidget);
    await t.pump(const Duration(minutes: 11));
  });

  testWidgets('never read on this profile', (t) async {
    final repo = FakeNumbers(stats: {30: statisticsFixture(neverRead: true)});
    await pumpStats(t, repo);
    expect(find.text('Nothing read on this profile yet'), findsOneWidget);
    expect(find.text('Your library'), findsOneWidget);
    await t.pump(const Duration(minutes: 11));
  });
}

String _enc(Object o) => jsonEncode(o);
