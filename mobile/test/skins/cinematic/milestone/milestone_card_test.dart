import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/library/providers/numbers_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/milestone_card_host.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/streak_flame.dart';

import '../../../screenshots/support/shot_harness.dart';
import '../../../support/numbers_fixtures.dart';
import '../support/cine_harness.dart';

/// Stands in for Tonight (mobile/08): a page that loads the streak and mounts the host.
class _TonightStandIn extends ConsumerWidget {
  const _TonightStandIn({required this.label});
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(numbersStatisticsProvider(30)).valueOrNull?.data;
    return Scaffold(body: MilestoneCardHost(streak: s?.streak, shareable: s?.shareable, child: Center(child: Text(label))));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);

  CineTestEnv env30(int days, List<int> seen) => CineTestEnv(repo: FakeNumbersRepo(stats: {30: statisticsFixture(currentDays: days, milestonesSeen: seen)}));

  GoRouter router() => GoRouter(routes: [
        GoRoute(path: '/', builder: (_, __) => const _TonightStandIn(label: 'TONIGHT')),
        GoRoute(path: '/second', builder: (_, __) => const _TonightStandIn(label: 'TONIGHT AGAIN')),
      ],);

  Future<void> open(WidgetTester tester, CineTestEnv env) async {
    await pumpCine(tester, env, router: router());
    await tester.pump();
    await pumpMs(tester, 1200);
  }

  testWidgets('30 days with 7 seen: the first visit pushes the card and marks 30', (tester) async {
    final env = env30(30, [7]);
    await open(tester, env);
    expect(find.text('Thirty days in a row.'), findsOneWidget);
    expect(find.text('STREAK'), findsOneWidget);
    expect(find.text('Your longest yet.'), findsNothing); // longest is 31
    expect(find.text('Your longest is 31.'), findsOneWidget);
    expect(env.repo.marked, [30]);
    // The tier flame: 96 px with the ring painter (30-99 days).
    final flame = tester.widget<StreakFlame>(find.byType(StreakFlame));
    expect(flame.size, 96);
    expect(flame.streak.currentDays, 30);
    expect(find.byWidgetPredicate((w) => w is CustomPaint && w.painter.runtimeType.toString() == '_RingPainter'), findsOneWidget);
    expect(env.haptics.events.map((e) => e.name), contains('streakMilestone'));
  });

  testWidgets('it closes on Esc, and does not reappear on the next visit', (tester) async {
    final env = env30(30, [7]);
    await open(tester, env);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await pumpMs(tester, 800);
    expect(find.text('Thirty days in a row.'), findsNothing);
    final r = GoRouter.of(tester.element(find.text('TONIGHT')));
    r.go('/second');
    await tester.pump();
    await pumpMs(tester, 1200);
    expect(find.text('Thirty days in a row.'), findsNothing);
    expect(env.repo.marked, [30]);
  });

  testWidgets('it closes on the platform back button', (tester) async {
    final env = env30(30, [7]);
    await open(tester, env);
    await tester.binding.handlePopRoute();
    await pumpMs(tester, 800);
    expect(find.text('Thirty days in a row.'), findsNothing);
  });

  testWidgets('it closes on a swipe down past 120 px and springs back below it', (tester) async {
    final env = env30(30, [7]);
    await open(tester, env);
    final g = await tester.startGesture(const Offset(195, 300));
    await g.moveBy(const Offset(0, 60));
    await tester.pump();
    await g.up();
    await pumpMs(tester, 800);
    expect(find.text('Thirty days in a row.'), findsOneWidget);
    final g2 = await tester.startGesture(const Offset(195, 300));
    await g2.moveBy(const Offset(0, 90));
    await g2.moveBy(const Offset(0, 60));
    await tester.pump();
    await g2.up();
    await pumpMs(tester, 800);
    expect(find.text('Thirty days in a row.'), findsNothing);
  });

  testWidgets('a tap outside the column closes it', (tester) async {
    final env = env30(30, [7]);
    await open(tester, env);
    await tester.tapAt(const Offset(195, 780));
    await pumpMs(tester, 800);
    expect(find.text('Thirty days in a row.'), findsNothing);
  });

  testWidgets('45 days with nothing seen shows 30 and marks 7 and 30', (tester) async {
    final env = env30(45, const []);
    await open(tester, env);
    expect(find.text('Thirty days in a row.'), findsOneWidget);
    expect(env.repo.marked, [7, 30]);
  });

  testWidgets('the copy of 7, 100 and 365', (tester) async {
    for (final (days, headline) in [(7, 'Seven days in a row.'), (100, 'One hundred days in a row.'), (365, 'A whole year, every day.')]) {
      final env = env30(days, const []);
      await open(tester, env);
      expect(find.text(headline), findsOneWidget, reason: '$days');
    }
  });

  testWidgets('nothing pending: no card', (tester) async {
    final env = env30(12, [7]);
    await open(tester, env);
    expect(find.text('STREAK'), findsNothing);
    expect(env.repo.marked, isEmpty);
  });

  testWidgets('Share opens the press run with the Streak template', (tester) async {
    final env = env30(30, [7]);
    await open(tester, env);
    await tester.tap(find.text('Share'));
    await tester.pump();
    await pumpMs(tester, 800);
    expect(find.text('PRESS RUN'), findsWidgets);
    expect(find.text('STREAK'), findsWidgets);
  });

  testWidgets('reduced motion: the card is on screen after 200 ms with text at rest', (tester) async {
    final env = env30(30, [7]);
    await pumpCine(tester, env, router: router(), reduced: true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Thirty days in a row.'), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('the card also opens from The Numbers', (tester) async {
    final env = env30(30, [7]);
    await pumpCine(tester, env);
    await tester.pump();
    await pumpMs(tester, 1800);
    expect(find.text('Thirty days in a row.'), findsOneWidget);
    expect(env.repo.marked, [30]);
  });
}
