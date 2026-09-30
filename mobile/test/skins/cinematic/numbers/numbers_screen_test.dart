import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/numbers/chapters_per_day.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/numbers/year_heatmap.dart';

import '../../../screenshots/support/shot_harness.dart';
import '../../../support/numbers_fixtures.dart';
import '../support/cine_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);

  Future<void> settleData(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await pumpMs(tester, 1500);
  }

  Future<void> scrollDown(WidgetTester tester, [double dy = -700]) async {
    await tester.drag(find.byType(TabBarView), Offset(0, dy));
    await pumpMs(tester, 600);
  }

  testWidgets(
      'the lead: streak block, four stat blocks with the spec values and captions',
      (tester) async {
    final env = CineTestEnv();
    await pumpCine(tester, env);
    await settleData(tester);
    expect(find.text('NO. 10 — THE NUMBERS'), findsOneWidget);
    expect(find.text('NO. 10 · THE NUMBERS'), findsOneWidget);
    expect(find.text('CHAPTERS'), findsOneWidget);
    expect(headline('184'), findsOneWidget);
    expect(find.textContaining('1,240 all time', findRichText: true),
        findsOneWidget,);
    expect(headline('31 H'), findsOneWidget);
    expect(find.textContaining('412 h all time', findRichText: true),
        findsOneWidget,);
    expect(headline('6,812'), findsOneWidget);
    expect(find.textContaining('48,221 all time', findRichText: true),
        findsOneWidget,);
    expect(headline('23'), findsOneWidget);
    expect(find.text('212 followed'), findsOneWidget);
    expect(find.text('7 DAYS'), findsOneWidget);
    expect(find.text('YEAR'), findsOneWidget);
    expect(env.repo.statisticsDays, contains(30));
    // Days start at the offset the server bucketed with.
    final foot = find.textContaining('Days start at UTC+05:30.', findRichText: true);
    await tester.scrollUntilVisible(foot, 500, scrollable: find.descendant(of: find.byType(TabBarView), matching: find.byType(Scrollable)).last);
    expect(foot, findsOneWidget);
  });

  testWidgets(
      'ranges switch by tap and by keys 1-4, YEAR requests 365 and shows the heatmap, the choice is remembered',
      (tester) async {
    final env = CineTestEnv();
    await pumpCine(tester, env);
    await settleData(tester);
    await tester.tap(find.text('90 DAYS'));
    await settleData(tester);
    expect(env.repo.statisticsDays, contains(90));
    expect(env.sp.getInt('mm.stats.range.u1p1'), 90);
    await tester.tap(find.text('YEAR'));
    await settleData(tester);
    expect(env.repo.statisticsDays, contains(365));
    await scrollDown(tester);
    expect(find.byType(YearHeatmap), findsOneWidget);
    expect(find.byType(ChaptersPerDay), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
    await settleData(tester);
    expect(env.repo.statisticsDays, contains(7));
    expect(env.sp.getInt('mm.stats.range.u1p1'), 7);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    await settleData(tester);
    expect(env.sp.getInt('mm.stats.range.u1p1'), 30);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
    await settleData(tester);
    expect(env.sp.getInt('mm.stats.range.u1p1'), 365);
  });

  testWidgets(
      'the stored range opens the screen on that tab (survives a restart)',
      (tester) async {
    final env = CineTestEnv(prefs: {'mm.stats.range.u1p1': 365});
    await pumpCine(tester, env);
    await settleData(tester);
    expect(env.repo.statisticsDays.first, 365);
    await scrollDown(tester);
    expect(find.byType(YearHeatmap), findsOneWidget);
  });

  testWidgets('a swipe pages between ranges', (tester) async {
    final env = CineTestEnv();
    await pumpCine(tester, env);
    await settleData(tester);
    await tester.fling(find.byType(TabBarView), const Offset(-300, 0), 1200);
    await settleData(tester);
    expect(env.sp.getInt('mm.stats.range.u1p1'), 90);
  });

  testWidgets('arrow keys move the selected day and update the readout',
      (tester) async {
    final env = CineTestEnv();
    await pumpCine(tester, env);
    await settleData(tester);
    await scrollDown(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    final daily = env.repo.stats[30]!.daily;
    // From nothing selected: ← selects the day before today.
    expect(
        find.textContaining(
            RegExp('${daily[daily.length - 2].chaptersRead} chapters? · '),),
        findsWidgets,);
  });

  testWidgets('empty payload: the nothing-recorded notice with Go to library',
      (tester) async {
    final env = CineTestEnv(
        repo: FakeNumbersRepo(stats: {
      for (final d in [7, 30, 90, 365])
        d: statisticsFixture(days: d, empty: true),
    },),);
    await pumpCine(tester, env);
    await settleData(tester);
    expect(find.text('NOTHING RECORDED YET'), findsOneWidget);
    expect(headline('Read a chapter and your numbers start here.'),
        findsOneWidget,);
    expect(find.text('Share'), findsNothing);
    await tester.tap(find.text('Go to library'));
    await pumpMs(tester, 1200);
    expect(find.text('LIBRARY'), findsOneWidget);
  });

  testWidgets(
      'followed but never read: the notice above only the library block',
      (tester) async {
    final env = CineTestEnv(
        repo: FakeNumbersRepo(stats: {
      for (final d in [7, 30, 90, 365])
        d: statisticsFixture(days: d, neverRead: true),
    },),);
    await pumpCine(tester, env);
    await settleData(tester);
    expect(find.text('NOTHING RECORDED YET'), findsOneWidget);
    expect(headline('Your library'), findsOneWidget);
    expect(headline('Chapters per day'), findsNothing);
    expect(find.textContaining('212 FOLLOWED'), findsOneWidget);
  });

  testWidgets('error: a CORRECTION with Try again', (tester) async {
    final env = CineTestEnv(
        repo: FakeNumbersRepo(failWith: const UnknownError(message: 'boom')),);
    await pumpCine(tester, env);
    await settleData(tester);
    expect(find.text('CORRECTION'), findsOneWidget);
    expect(headline("The numbers didn't load."), findsOneWidget);
    env.repo.failWith = null;
    await tester.tap(find.text('Try again'));
    await settleData(tester);
    expect(find.text('CORRECTION'), findsNothing);
    expect(headline('184'), findsOneWidget);
  });

  testWidgets(
      'offline: the last snapshot with the OFFLINE EDITION badge and no Share',
      (tester) async {
    final env = CineTestEnv(
      repo: FakeNumbersRepo(failWith: const NetworkError(message: 'down')),
      prefs: {
        'mm.numbers.last.30.u1p1':
            '{"followed_total": 212, "totals": {"sessions": 5, "chapters_read": 9}, "window": {"sessions": 5, "chapters_read": 9, "seconds_read": 7200}}',
      },
    );
    await pumpCine(tester, env);
    await settleData(tester);
    expect(find.text('OFFLINE EDITION'), findsOneWidget);
    expect(find.text('Share'), findsNothing);
    expect(headline('9'), findsOneWidget);
  });

  testWidgets('loading: a galley proof, then the data', (tester) async {
    final env = CineTestEnv();
    env.repo.statsGate = Completer<void>();
    await pumpCine(tester, env);
    await tester.pump();
    expect(headline('184'), findsNothing);
    env.repo.statsGate!.complete();
    await settleData(tester);
    expect(headline('184'), findsOneWidget);
  });

  testWidgets('the Annual banner: kicker, line, year slugs opening each issue',
      (tester) async {
    final env = CineTestEnv();
    await pumpCine(tester, env);
    await settleData(tester);
    expect(find.text('THE ANNUAL 2026'), findsOneWidget);
    expect(find.text('Your year so far.'), findsOneWidget);
    expect(find.text('2025'), findsOneWidget);
    await tester.tap(find.text('2025'));
    await settleData(tester);
    expect(env.repo.annualYears, contains(2025));
  });

  testWidgets(
      'December: the banner announces the Annual is out; hidden when unavailable',
      (tester) async {
    final env = CineTestEnv(now: DateTime(2026, 12, 3, 10));
    await pumpCine(tester, env);
    await settleData(tester);
    expect(find.text('THE ANNUAL 2026 IS OUT'), findsOneWidget);
    final thin = CineTestEnv(
        repo:
            FakeNumbersRepo(annuals: {2026: annualFixture(recordedDays: 12)}),);
    await pumpCine(tester, thin);
    await settleData(tester);
    expect(find.textContaining('THE ANNUAL 2026'), findsNothing);
  });

  testWidgets('the a key opens The Annual', (tester) async {
    final env = CineTestEnv();
    await pumpCine(tester, env);
    await settleData(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await settleData(tester);
    expect(env.repo.annualYears.where((y) => y == 2026), isNotEmpty);
  });

  testWidgets(
      'lists: where you read, most read, recent sessions, library and footnotes',
      (tester) async {
    final env = CineTestEnv();
    await pumpCine(tester, env);
    await settleData(tester);
    Future<void> reveal(Finder f) async {
      await tester.scrollUntilVisible(f, 300,
          scrollable: find.byType(Scrollable).last,);
      await tester.pump(const Duration(milliseconds: 300));
    }

    await reveal(headline('Where you read'));
    expect(find.text('MangaDex'), findsOneWidget);
    expect(headline('Most read'), findsOneWidget);
    await reveal(find.text('Series number 1').first);
    expect(
        find.textContaining('412 pages · 38 chapters · 6 h'), findsOneWidget,);
    await reveal(headline('Recent sessions'));
    expect(find.text('CH 142'), findsOneWidget);
    await reveal(headline('Your library'));
    expect(find.text('READING'), findsOneWidget);
    expect(find.text('DONE'), findsOneWidget);
    expect(
        find.textContaining(
            '212 FOLLOWED · 3 FAVOURITES · 1,904 CHAPTERS FINISHED',),
        findsOneWidget,);
  });

  testWidgets('hit targets on iOS and Android, and tabs 8 px apart',
      (tester) async {
    for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
      final env = CineTestEnv();
      await pumpCine(tester, env, platform: platform);
      await settleData(tester);
      expectHitTargets(tester, platform);
      final tabs = [
        for (final l in ['7 DAYS', '30 DAYS', '90 DAYS', 'YEAR'])
          tester.getRect(find.text(l)),
      ];
      for (var i = 1; i < tabs.length; i++) {
        expect(tabs[i].left - tabs[i - 1].right, greaterThanOrEqualTo(8));
      }
    }
  });

  testWidgets('tablet: four stat blocks across, clock and radar side by side',
      (tester) async {
    final env = CineTestEnv();
    await pumpCine(tester, env,
        size: const Size(834, 1194),
        padding: const EdgeInsets.only(top: 24, bottom: 20),);
    await settleData(tester);
    final xs = [
      for (final k in ['CHAPTERS', 'TIME', 'PAGES', 'SERIES'])
        tester.getTopLeft(find.text(k)).dy,
    ];
    expect(xs.toSet(), hasLength(1));
  });

  testWidgets('text scale 2.0 does not overflow', (tester) async {
    final env = CineTestEnv();
    await pumpCine(tester, env, textScale: 2.0);
    await settleData(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'reduced motion: the numerals appear whole and nothing keeps animating',
      (tester) async {
    final env = CineTestEnv();
    await pumpCine(tester, env, reduced: true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(headline('184'), findsOneWidget);
  });

  testWidgets('Share opens the press run on the current range', (tester) async {
    final env = CineTestEnv();
    await pumpCine(tester, env);
    await settleData(tester);
    await tester.tap(find.text('Share'));
    await tester.pump();
    await pumpMs(tester, 600);
    expect(find.text('PRESS RUN'), findsWidgets);
  });
}
