import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/models/library_statistics.dart';
import 'package:manhwamaniacs/features/library/models/shareable.dart';
import 'package:manhwamaniacs/features/library/utils/streak_state.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/typed_text.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/numbers_streak_flame.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/numbers/chapters_per_day.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/numbers/clock_chart.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/numbers/genre_radar.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/numbers/stat_blocks.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/numbers/streak_block.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/numbers/year_heatmap.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

import '../../../screenshots/support/shot_harness.dart';
import '../../../support/numbers_fixtures.dart';
import '../support/cine_harness.dart';


void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);

  Future<CineTestEnv> pumpChild(WidgetTester tester, Widget child, {DateTime? now, bool reduced = false, Map<String, Object> prefs = const {}, Size size = const Size(390, 844), double textScale = 1}) async {
    final env = CineTestEnv(now: now, prefs: prefs);
    await pumpCine(tester, env, size: size, reduced: reduced, textScale: textScale, router: cineRouter(initial: '/', home: Scaffold(backgroundColor: Colors.black, body: SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(20), child: child)))));
    return env;
  }

  group('typed numerals', () {
    testWidgets('a value types one grapheme per 50 ms after its delay, with the whole value in semantics', (tester) async {
      await pumpChild(tester, const StatBlock(kicker: 'CHAPTERS', value: '1,240', caption: 'x', signature: true));
      final handle = tester.ensureSemantics();
      expect(find.bySemanticsLabel('CHAPTERS 1,240'), findsOneWidget);
      String visible() {
        final rt = tester.widget<RichText>(find.descendant(of: find.byType(TypedText), matching: find.byType(RichText)).first);
        final root = rt.text as TextSpan;
        return (root.children!.first as TextSpan).text!;
      }

      expect(visible(), '');
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pump(const Duration(milliseconds: 110));
      expect(visible(), '1,');
      await tester.pump(const Duration(milliseconds: 400));
      expect(visible(), '1,240');
      handle.dispose();
    });

    testWidgets('reduced motion shows the value whole, no caret', (tester) async {
      await pumpChild(tester, const StatBlock(kicker: 'TIME', value: '31 H', caption: 'x', signature: true), reduced: true);
      await tester.pump();
      expect(find.text('31 H'), findsOneWidget);
    });

    testWidgets('rules draw 32 ms apart in reading order', (tester) async {
      await pumpChild(
        tester,
        const Column(children: [
          StatBlock(kicker: 'A', value: '1', caption: 'x', signature: true),
          StatBlock(kicker: 'B', value: '2', caption: 'x', signature: true, ruleDelay: Duration(milliseconds: 32)),
        ],),
      );
      await tester.pump(const Duration(milliseconds: 100));
      double w(int i) => tester.getSize(find.descendant(of: find.byType(StatBlock).at(i), matching: find.byType(FractionallySizedBox)).first).width;
      expect(w(0), greaterThan(w(1)));
      await tester.pump(const Duration(milliseconds: 600));
      expect(w(0), closeTo(w(1), 0.5));
    });

    testWidgets('another range cross-fades without retyping', (tester) async {
      await pumpChild(tester, const StatBlock(kicker: 'TIME', value: '31 H', caption: 'x'));
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.text('31 H'), findsOneWidget);
    });
  });

  group('chapters per day', () {
    final daily = statisticsFixture().daily;

    Future<ValueNotifier<int?>> pumpBars(WidgetTester tester, {int days = 30}) async {
      final sel = ValueNotifier<int?>(null);
      await pumpChild(
        tester,
        ValueListenableBuilder<int?>(valueListenable: sel, builder: (_, s, __) => ChaptersPerDay(daily: daily, days: days, selected: s, onSelect: (i) => sel.value = i)),
      );
      return sel;
    }

    testWidgets('one semantics node per bar with the exact label, summary above', (tester) async {
      await pumpBars(tester);
      final handle = tester.ensureSemantics();
      await tester.pump();
      final d = daily.last;
      final label = daySemantics(d);
      expect(find.bySemanticsLabel(label), findsWidgets);
      expect(find.textContaining('30 days: '), findsOneWidget);
      expect(find.textContaining('Best day'), findsWidgets);
      handle.dispose();
    });

    testWidgets('a tap selects a day (sticky) and a second tap on it clears', (tester) async {
      final sel = await pumpBars(tester);
      final box = tester.getRect(find.byType(CustomPaint).last);
      final n = daily.length;
      const left = 30.0;
      final plotW = box.width - left - 44;
      final x = box.left + left + (plotW / n) * 10 + 2;
      await tester.tapAt(Offset(x, box.top + 40));
      await tester.pump();
      expect(sel.value, isNotNull);
      final picked = sel.value!;
      expect(find.text(dayReadout(daily[picked])), findsOneWidget);
      await tester.tapAt(Offset(x, box.top + 40));
      await tester.pump();
      expect(sel.value, isNull);
    });

    testWidgets('the year range draws the heatmap: 53 columns, 634 wide, legend and summary', (tester) async {
      final year = statisticsFixture(days: 365).daily;
      await pumpChild(tester, YearHeatmap(daily: year, today: DateTime(2026, 9, 29), selected: null, onSelect: (_) {}));
      await tester.pump();
      expect(tester.getSize(find.descendant(of: find.byType(SingleChildScrollView).last, matching: find.byType(CustomPaint)).first).width, 53 * 12 - 2);
      expect(find.textContaining('Last year: read on'), findsOneWidget);
      for (final l in ['0', '1–2', '3–5', '6–10', '11+']) {
        expect(find.text(l), findsOneWidget);
      }
    });
  });

  group('clock and radar', () {
    testWidgets('the clock has 24 hour nodes', (tester) async {
      await pumpChild(tester, ClockChart(byHour: [for (var h = 0; h < 24; h++) h == 22 ? 11400 : 0]));
      final handle = tester.ensureSemantics();
      await tester.pump();
      expect(find.bySemanticsLabel('22:00, 3 hours 10 minutes'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^\d\d:00, ')), findsNWidgets(24));
      handle.dispose();
    });

    testWidgets('the radar summarises the top genres, and fewer than 3 become rows', (tester) async {
      const g = [GenreWeight(genre: 'Fantasy', weight: 0.41), GenreWeight(genre: 'Romance', weight: 0.22), GenreWeight(genre: 'Action', weight: 0.15)];
      expect(genreSummary(g), 'Top genres: Fantasy 41 %, Romance 22 %, Action 15 %.');
      await pumpChild(tester, const GenreRadar(genres: g));
      final handle = tester.ensureSemantics();
      await tester.pump();
      expect(find.bySemanticsLabel('Top genres: Fantasy 41 %, Romance 22 %, Action 15 %.'), findsOneWidget);
      expect(find.bySemanticsLabel('Fantasy, 41 percent'), findsOneWidget);
      handle.dispose();
      await pumpChild(tester, const GenreRadar(genres: [GenreWeight(genre: 'Fantasy', weight: 0.41), GenreWeight(genre: 'Romance', weight: 0.22)]));
      expect(find.text('FANTASY · 41 %'), findsOneWidget);
    });
  });

  group('streak block', () {
    Future<CineTestEnv> pumpStreak(WidgetTester tester, {required int days, required DateTime now, required DateTime? last, bool atRisk = false, Map<String, Object> prefs = const {}}) => pumpChild(
          tester,
          StreakBlock(
            streak: ReadingStreak(currentDays: days, longestDays: 31, lastActiveDate: last, atRisk: atRisk),
            daily: [DailyActivity(date: DateTime(2026, 9, 28), chaptersRead: 3, sessions: 1), DailyActivity(date: DateTime(2026, 9, 29), chaptersRead: 2, sessions: 1)],
          ),
          now: now,
          prefs: prefs,
        );

    testWidgets('tier and state labels for 0, 3, 12, 45 and 120 days', (tester) async {
      final now = DateTime(2026, 9, 29, 10);
      final handle = tester.ensureSemantics();
      for (final (days, label) in [(0, 'No streak'), (3, '3-day streak, read today'), (12, '12-day streak, read today'), (45, '45-day streak, read today'), (120, '120-day streak, read today')]) {
        await pumpStreak(tester, days: days, now: now, last: days == 0 ? null : DateTime(2026, 9, 29));
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
      }
      handle.dispose();
    });

    testWidgets('not yet today before 20:00, at risk after 20:00, captions by state', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpStreak(tester, days: 12, now: DateTime(2026, 9, 29, 10), last: DateTime(2026, 9, 28));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.bySemanticsLabel('12-day streak'), findsOneWidget);
      expect(find.text('Read today to keep your 12-day streak.'), findsOneWidget);
      await pumpStreak(tester, days: 12, now: DateTime(2026, 9, 29, 21), last: DateTime(2026, 9, 28), atRisk: true);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.bySemanticsLabel('12-day streak, at risk'), findsOneWidget);
      expect(find.text('Twelve days and counting. One chapter keeps it alive.'), findsOneWidget);
      await pumpStreak(tester, days: 0, now: DateTime(2026, 9, 29, 10), last: null);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Longest: 31 days. Start a new one today.'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('week dots: one group label naming the days read', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpStreak(tester, days: 12, now: DateTime(2026, 9, 29, 10), last: DateTime(2026, 9, 29));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.bySemanticsLabel('Read on Monday and Tuesday'), findsOneWidget);
      expect(find.bySemanticsLabel('Monday'), findsNothing);
      handle.dispose();
      expect(weekSemantics([true, true, false, true, false, false, false]), 'Read on Monday, Tuesday and Thursday');
      expect(weekSemantics(List.filled(7, false)), 'No reading yet this week');
    });

    testWidgets('Ignite plays once when the last active day flips to today', (tester) async {
      final env = await pumpStreak(tester, days: 12, now: DateTime(2026, 9, 29, 10), last: DateTime(2026, 9, 29));
      await tester.pump(const Duration(milliseconds: 100));
      expect(env.haptics.events, contains(HapticEvent.streakExtend));
      expect(env.sp.getString('mm.streak.seen.u1p1'), '2026-09-29');
      // The next visit: the day is remembered, so no Ignite.
      final again = await pumpStreak(tester, days: 12, now: DateTime(2026, 9, 29, 11), last: DateTime(2026, 9, 29), prefs: {'mm.streak.seen.u1p1': '2026-09-29'});
      await tester.pump(const Duration(milliseconds: 100));
      expect(again.haptics.events, isNot(contains(HapticEvent.streakExtend)));
    });
  });

  group('flame', () {
    Future<void> flame(WidgetTester tester, int days, StreakState s, {bool reduced = false}) => pumpChild(tester, NumbersStreakFlame(days: days, state: s), reduced: reduced);

    testWidgets('the ember dot is a 6 x 6 square at zero days', (tester) async {
      await flame(tester, 0, StreakState.broken);
      final box = tester.getSize(find.byWidgetPredicate((w) => w is Container && w.constraints?.maxWidth == 6));
      expect(box, const Size(6, 6));
    });

    testWidgets('tiers add the ring at 30 days and sparks at 100', (tester) async {
      await flame(tester, 12, StreakState.readToday);
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(CustomPaint).evaluate().where((e) => (e.widget as CustomPaint).painter.runtimeType.toString() == '_RingPainter'), isEmpty);
      await flame(tester, 45, StreakState.readToday);
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(CustomPaint).evaluate().where((e) => (e.widget as CustomPaint).painter.runtimeType.toString() == '_RingPainter'), hasLength(1));
      await flame(tester, 120, StreakState.readToday);
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(CustomPaint).evaluate().where((e) => (e.widget as CustomPaint).painter.runtimeType.toString() == '_RingPainter'), hasLength(1));
    });

    testWidgets('reduced motion leaves no running animation', (tester) async {
      await flame(tester, 120, StreakState.readToday, reduced: true);
      await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 2));
      expect(tester.hasRunningAnimations, isFalse);
    });
  });
}
