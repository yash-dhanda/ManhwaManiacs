import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/annual/annual_segments.dart';

import '../../../screenshots/support/shot_harness.dart';
import '../../../support/numbers_fixtures.dart';
import '../support/cine_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);

  CineTestEnv envWith({bool circle = false, bool voices = true, int recorded = 120, Object? failWith}) => CineTestEnv(
        repo: FakeNumbersRepo(annuals: {2026: annualFixture(circle: circle, voices: voices, recordedDays: recorded), 2025: annualFixture(year: 2025, partial: false)}, failWith: failWith),
      );

  Future<void> openAnnual(WidgetTester tester, CineTestEnv env, {Size size = const Size(390, 844), EdgeInsets? padding, bool reduced = false, bool accessible = false, TargetPlatform platform = TargetPlatform.iOS, String year = '2026'}) async {
    final router = cineRouter(initial: '/library/statistics/annual/$year');
    await pumpCine(tester, env, router: router, size: size, padding: padding ?? const EdgeInsets.only(top: 47, bottom: 34), reduced: reduced, accessible: accessible, platform: platform);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  int filled(WidgetTester tester) => tester.widgetList<FractionallySizedBox>(find.descendant(of: find.byType(AnnualSegments), matching: find.byType(FractionallySizedBox))).where((b) => b.widthFactor == 1).length;

  double currentFill(WidgetTester tester) {
    final boxes = tester.widgetList<FractionallySizedBox>(find.descendant(of: find.byType(AnnualSegments), matching: find.byType(FractionallySizedBox))).toList();
    return boxes.firstWhere((b) => b.widthFactor! < 1, orElse: () => boxes.last).widthFactor!;
  }

  int segments(WidgetTester tester) => find.descendant(of: find.byType(AnnualSegments), matching: find.byKey(const ValueKey('segment-fill'))).evaluate().length;

  testWidgets('eleven segments with the circle page, ten without', (tester) async {
    await openAnnual(tester, envWith(circle: true));
    expect(segments(tester), 11);
    await openAnnual(tester, envWith());
    expect(segments(tester), 10);
  });

  testWidgets('tap thirds move pages, the top and bottom margins ignore taps', (tester) async {
    await openAnnual(tester, envWith());
    expect(filled(tester), 0);
    await tester.tapAt(const Offset(350, 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(filled(tester), 1);
    await tester.tapAt(const Offset(40, 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(filled(tester), 0);
    await tester.tapAt(const Offset(350, 60));
    await tester.pump(const Duration(milliseconds: 400));
    expect(filled(tester), 0);
    await tester.tapAt(const Offset(350, 830));
    await tester.pump(const Duration(milliseconds: 400));
    expect(filled(tester), 0);
    // The middle third does nothing.
    await tester.tapAt(const Offset(195, 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(filled(tester), 0);
  });

  testWidgets('a horizontal swipe moves pages and fires the page haptic', (tester) async {
    final env = envWith();
    await openAnnual(tester, env);
    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1500);
    await tester.pump(const Duration(milliseconds: 600));
    expect(filled(tester), 1);
    expect(env.haptics.events.where((e) => e.name == 'annualPage'), isNotEmpty);
  });

  testWidgets('a 450 ms hold pauses and the segments freeze; release resumes', (tester) async {
    await openAnnual(tester, envWith());
    await pumpMs(tester, 1000);
    final g = await tester.startGesture(const Offset(195, 400));
    await tester.pump(const Duration(milliseconds: 500));
    final frozen = currentFill(tester);
    await pumpMs(tester, 1500);
    expect(currentFill(tester), frozen);
    await g.up();
    await pumpMs(tester, 1000);
    expect(currentFill(tester), greaterThan(frozen));
    // A hold never counts as a tap: still on page one.
    expect(filled(tester), 0);
  });

  testWidgets('a swipe down closes the story', (tester) async {
    await openAnnual(tester, envWith());
    await tester.fling(find.byType(PageView), const Offset(0, 400), 1500);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('INDEX'), findsOneWidget);
  });

  testWidgets('a short drag springs back', (tester) async {
    await openAnnual(tester, envWith());
    final g = await tester.startGesture(const Offset(195, 300));
    await g.moveBy(const Offset(0, 60));
    await tester.pump();
    await g.up();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byType(PageView), findsOneWidget);
  });

  testWidgets('auto-advance: page one holds 6 s, then page two', (tester) async {
    await openAnnual(tester, envWith());
    await pumpMs(tester, 5800);
    expect(filled(tester), 0);
    await pumpMs(tester, 600);
    expect(filled(tester), 1);
  });

  testWidgets('list pages hold 8 s (page four, Your No. 1)', (tester) async {
    final env = envWith();
    await openAnnual(tester, env);
    for (var i = 0; i < 3; i++) {
      await tester.tapAt(const Offset(350, 400));
      await pumpMs(tester, 400);
    }
    expect(filled(tester), 3);
    await pumpMs(tester, 7500);
    expect(filled(tester), 3);
    await pumpMs(tester, 1000);
    expect(filled(tester), 4);
  });

  testWidgets('reduced motion: it never advances and the colophon is a still page', (tester) async {
    await openAnnual(tester, envWith(), reduced: true);
    await pumpMs(tester, 9000);
    expect(filled(tester), 0);
  });

  testWidgets('screen reader: no auto-advance, three visible buttons, custom actions and an announcement', (tester) async {
    final handle = tester.ensureSemantics();
    await openAnnual(tester, envWith(), accessible: true);
    await pumpMs(tester, 9000);
    expect(filled(tester), 0);
    expect(find.text('Previous page'), findsOneWidget);
    expect(find.text('Pause'), findsOneWidget);
    expect(find.text('Next page'), findsOneWidget);
    final node = tester.getSemantics(find.bySemanticsLabel('The Annual 2026, page 1 of 10'));
    final actions = node.getSemanticsData().customSemanticsActionIds!;
    expect(actions, hasLength(3));
    expect([for (final id in actions) CustomSemanticsAction.getAction(id)!.label], containsAll(['Next page', 'Previous page', 'Pause']));
    await tester.tap(find.text('Next page'));
    await pumpMs(tester, 500);
    expect(filled(tester), 1);
    expect(find.bySemanticsLabel('The Annual 2026, page 2 of 10'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('keys: → and ← move, Space pauses, Esc closes', (tester) async {
    await openAnnual(tester, envWith());
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await pumpMs(tester, 400);
    expect(filled(tester), 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await pumpMs(tester, 400);
    expect(filled(tester), 0);
    final before = currentFill(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await pumpMs(tester, 1500);
    expect(currentFill(tester), before);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('INDEX'), findsOneWidget);
  });

  Future<void> goToColophon(WidgetTester tester, {required int pages}) async {
    for (var i = 0; i < pages - 2; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await pumpMs(tester, 350);
    }
  }

  testWidgets('the colophon rolls 360 px over 10 s, lists NARRATED BY, then closes on "See you in 2027." held', (tester) async {
    await openAnnual(tester, envWith());
    await goToColophon(tester, pages: 10);
    expect(find.text('NARRATED BY'), findsOneWidget);
    expect(find.text('Marlowe, Isolde'), findsOneWidget);
    final top0 = tester.getTopLeft(find.byKey(const ValueKey('credits-roll'))).dy;
    await pumpMs(tester, 5000);
    final mid = tester.getTopLeft(find.byKey(const ValueKey('credits-roll'))).dy;
    expect(top0 - mid, closeTo(180, 12));
    await pumpMs(tester, 5100);
    final end = tester.getTopLeft(find.byKey(const ValueKey('credits-roll'))).dy;
    expect(top0 - end, closeTo(360, 8));
    await pumpMs(tester, 800);
    expect(find.bySemanticsLabel('See you in 2027.').evaluate().isNotEmpty || find.text('See you in 2027.').evaluate().isNotEmpty, isTrue);
    // After the 12 s hold the story moves on to the press run.
    await pumpMs(tester, 2500);
    expect(find.text('PRESS RUN'), findsWidgets);
  });

  testWidgets('NARRATED BY is omitted when no voice is recorded, WITH appears for the circle', (tester) async {
    await openAnnual(tester, envWith(voices: false, circle: true));
    await goToColophon(tester, pages: 11);
    expect(find.text('NARRATED BY'), findsNothing);
    expect(find.text('WITH'), findsOneWidget);
    expect(find.text('STARRING'), findsOneWidget);
    expect(find.text('PRINTED ON'), findsOneWidget);
  });

  testWidgets('a tap on the colophon skips to the press run', (tester) async {
    await openAnnual(tester, envWith());
    await goToColophon(tester, pages: 10);
    await tester.tapAt(const Offset(195, 400));
    await pumpMs(tester, 600);
    expect(filled(tester), 9);
  });

  testWidgets('reduced motion colophon is a still page with every line visible', (tester) async {
    await openAnnual(tester, envWith(), reduced: true);
    await goToColophon(tester, pages: 10);
    expect(find.text('STARRING'), findsOneWidget);
    expect(find.text('See you in 2027.'), findsOneWidget);
    expect(find.byKey(const ValueKey('credits-roll')), findsNothing);
  });

  testWidgets('tablet and landscape phone: a centred 9:16 column on black', (tester) async {
    await openAnnual(tester, envWith(), size: const Size(834, 1194), padding: const EdgeInsets.only(top: 24, bottom: 20));
    final col = tester.getRect(find.byType(PageView));
    expect(col.height, 1194);
    expect(col.width, closeTo(1194 * 9 / 16, 1));
    expect(col.center.dx, closeTo(417, 1));
    // The thirds, segments and close apply to the column.
    await tester.tapAt(Offset(col.right - 20, 600));
    await pumpMs(tester, 400);
    expect(filled(tester), 1);
    await openAnnual(tester, envWith(), size: const Size(844, 390), padding: const EdgeInsets.only(left: 47, right: 47, bottom: 21));
    final land = tester.getRect(find.byType(PageView));
    expect(land.height, 390);
    expect(land.width, closeTo(390 * 9 / 16, 1));
  });

  testWidgets('the close button (44 / 48 hit) closes; controls are large enough', (tester) async {
    for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
      await openAnnual(tester, envWith(), platform: platform);
      expectHitTargets(tester, platform);
      await tester.tap(find.bySemanticsLabel('Close').hitTestable(), warnIfMissed: false);
    }
  });

  testWidgets('thin data: a single page "needs a few more weeks" and Close', (tester) async {
    await openAnnual(tester, envWith(recorded: 5));
    expect(find.text('Your Annual needs a few more weeks of reading. 5 days recorded so far.'), findsOneWidget);
    expect(find.byType(AnnualSegments), findsNothing);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('INDEX'), findsOneWidget);
  });

  testWidgets('error: CORRECTION with Try again and Close; offline without a snapshot', (tester) async {
    final env = envWith(failWith: const UnknownError(message: 'x'));
    await openAnnual(tester, env);
    expect(find.text('CORRECTION'), findsOneWidget);
    expect(find.text("The Annual didn't print."), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
    final off = envWith(failWith: const NetworkError(message: 'down'));
    await openAnnual(tester, off);
    expect(find.text('OFFLINE EDITION'), findsOneWidget);
    expect(find.text('The Annual needs a connection the first time.'), findsOneWidget);
  });

  testWidgets('offline with a snapshot shows the story', (tester) async {
    final env = CineTestEnv(
      repo: FakeNumbersRepo(failWith: const NetworkError(message: 'down')),
      prefs: {'mm.annual.last.2026.u1p1': '{"year": 2026, "recorded_days": 60, "seconds_read": 7200, "chapters_read": 30, "chapters_by_month": [1,1,1,1,1,1,1,1,1,0,0,0], "by_hour": [], "longest_streak": {"days": 3}, "top_series": [], "genres": [], "top_sources": [], "available_years": [2026]}'},
    );
    await openAnnual(tester, env);
    expect(find.byType(AnnualSegments), findsOneWidget);
  });

  testWidgets('a non-numeric year is not found inside the takeover', (tester) async {
    await openAnnual(tester, envWith(), year: 'soon');
    expect(find.text('NOT FOUND'), findsOneWidget);
  });

  testWidgets('loading: "Setting the pages…" with the indeterminate rule', (tester) async {
    final env = envWith();
    final router = cineRouter(initial: '/library/statistics/annual/2026');
    await pumpCine(tester, env, router: router);
    await tester.pump();
    expect(find.text('Setting the pages…'), findsOneWidget);
  });

  testWidgets('page copy: cover, time, chapters', (tester) async {
    await openAnnual(tester, envWith());
    await pumpMs(tester, 3000);
    expect(find.text('YOUR YEAR SO FAR'), findsOneWidget);
    expect(find.textContaining('No. 1 · 29 SEPTEMBER 2026'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await pumpMs(tester, 2500);
    expect(find.text('You read for 212 hours.'), findsOneWidget);
    expect(find.text("That's nine days, cover to cover."), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await pumpMs(tester, 2500);
    expect(find.text('4,812 chapters.'), findsOneWidget);
  });
}
