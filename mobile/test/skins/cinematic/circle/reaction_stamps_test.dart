import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/circle/utils/spoiler_guard.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/reaction_stamps.dart';

import 'circle_harness.dart';

ChapterReactions _chapter({bool sealed = true, ReactionKind? mine, Map<ReactionKind, int> counts = const {ReactionKind.loved: 2}, bool others = true}) => ChapterReactions(
      chapterKey: 'c142',
      chapterNumber: 142,
      counts: {for (final k in ReactionKind.values) k: counts[k] ?? 0},
      total: counts.values.fold(0, (a, b) => a + b),
      by: [
        if (others) ReactionBy.of(riya, ReactionKind.loved),
        if (others) ReactionBy.of(arjun, ReactionKind.loved),
      ],
      mine: mine,
      sealed: sealed,
    );

Future<ProviderContainer> _pump(WidgetTester tester, FakeCircleRepository repo, {CineTestEnv? env, bool reduced = false, TargetPlatform platform = TargetPlatform.iOS}) async {
  await pumpCine(
    tester,
    env ?? CineTestEnv(),
    router: circleRouter(
      screen: const Scaffold(
        body: Padding(padding: EdgeInsets.all(16), child: Align(alignment: Alignment.topLeft, child: ReactionStamps(sourceId: 's', seriesKey: 'or', chapterKey: 'c142', chapterNumber: 142))),
      ),
    ),
    reduced: reduced,
    platform: platform,
    extra: [circleRepositoryProvider.overrideWithValue(repo)],
  );
  await settle(tester, 400);
  return ProviderScope.containerOf(tester.element(find.byType(ReactionStamps)));
}

Finder _stamp(String label) => find.bySemanticsLabel(RegExp('^$label'));

void main() {
  setUpAll(loadAppFonts);

  testWidgets('the five offered stamps always show; HYPE and WRECKED only with counts', (tester) async {
    await _pump(tester, FakeCircleRepository(reactionList: [_chapter(sealed: false, counts: {ReactionKind.loved: 2})]));
    for (final l in ['Loved', 'Shook', 'Laughed', 'Tears', "Chef's kiss"]) {
      expect(_stamp(l), findsOneWidget, reason: l);
    }
    expect(find.text('HYPE'), findsNothing);
    expect(find.text('WRECKED'), findsNothing);
  });

  testWidgets('HYPE and WRECKED show once their count is above zero', (tester) async {
    await _pump(tester, FakeCircleRepository(reactionList: [_chapter(sealed: false, counts: {ReactionKind.hype: 1, ReactionKind.wrecked: 1})]));
    expect(find.text('HYPE'), findsOneWidget);
    expect(find.text('WRECKED'), findsOneWidget);
  });

  testWidgets('pressing fills the stamp and calls react; another moves it; the same clears with the body', (tester) async {
    final repo = FakeCircleRepository();
    final env = CineTestEnv();
    await _pump(tester, repo, env: env);
    await tester.tap(_stamp('Loved'));
    await settle(tester, 300);
    expect(repo.log, contains('react c142 loved'));
    expect(find.bySemanticsLabel(RegExp('Loved, 1 reaction, selected')), findsOneWidget);
    expect(env.haptics.events.map((e) => e.id), contains('reaction.send'));
    await tester.tap(_stamp('Shook'));
    await settle(tester, 300);
    expect(repo.log, contains('react c142 shook'));
    await tester.tap(_stamp('Shook'));
    await settle(tester, 300);
    expect(repo.log.last, 'unreact c142');
  });

  testWidgets('offline presses draw at once and queue in the outbox', (tester) async {
    final repo = FakeCircleRepository()..failReact = const NetworkError(message: 'x');
    final env = CineTestEnv();
    await _pump(tester, repo, env: env);
    await tester.tap(_stamp('Tears'));
    await settle(tester, 300);
    expect(find.bySemanticsLabel(RegExp('Tears, 1 reaction, selected')), findsOneWidget);
    final key = env.sp.getKeys().firstWhere((k) => k.startsWith('mm.circle.reaction-outbox.'));
    expect(env.sp.getString(key), contains('"kind":"tears"'));
  });

  testWidgets('a guarded chapter shows the total only, then unseals when the chapter completes', (tester) async {
    final repo = FakeCircleRepository(reactionList: [_chapter()]);
    final container = await _pump(tester, repo);
    expect(find.bySemanticsLabel('2 reactions, hidden until you finish the chapter'), findsOneWidget);
    expect(find.text('2 reactions'), findsOneWidget);
    // No per-stamp counts while guarded.
    expect(find.text('2'), findsNothing);
    final calls = repo.log.length;
    container.read(completedThisSessionProvider.notifier).markCompleted('s', 'or', 'c142');
    await settle(tester, 600);
    expect(find.bySemanticsLabel('Reactions to chapter 142'), findsOneWidget);
    expect(find.text('2'), findsOneWidget); // the Loved count, unsealed without a refetch
    expect(repo.log.length, calls);
  });

  testWidgets('the viewer\'s own reaction is never guarded and shows filled', (tester) async {
    await _pump(tester, FakeCircleRepository(reactionList: [_chapter(mine: ReactionKind.loved, counts: {ReactionKind.loved: 1}, others: false)]));
    expect(find.bySemanticsLabel('Reactions to chapter 142'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Loved, 1 reaction, selected')), findsOneWidget);
  });

  testWidgets('semantics: a mutually exclusive group of buttons', (tester) async {
    final h = tester.ensureSemantics();
    await _pump(tester, FakeCircleRepository(reactionList: [_chapter(sealed: false, mine: ReactionKind.shook, counts: {ReactionKind.shook: 1, ReactionKind.loved: 1})]));
    final node = tester.getSemantics(_stamp('Shook'));
    expect(node.getSemanticsData().flagsCollection.isInMutuallyExclusiveGroup, isTrue);
    expect(node.getSemanticsData().flagsCollection.isButton, isTrue);
    h.dispose();
  });

  testWidgets('hit targets: 44 on iOS, 48 on Android, 8 px apart', (tester) async {
    for (final p in [TargetPlatform.iOS, TargetPlatform.android]) {
      await _pump(tester, FakeCircleRepository(reactionList: [_chapter(sealed: false)]), platform: p);
      final min = p == TargetPlatform.iOS ? 44.0 : 48.0;
      final rects = [for (final l in ['Loved', 'Shook', 'Laughed', 'Tears', "Chef's kiss"]) tester.getRect(_stamp(l))];
      for (final r in rects) {
        expect(r.width, greaterThanOrEqualTo(min - 0.01));
        expect(r.height, greaterThanOrEqualTo(min - 0.01));
      }
      for (var i = 1; i < rects.length; i++) {
        expect(rects[i].left - rects[i - 1].right, greaterThanOrEqualTo(8 - 0.01));
      }
    }
  });

  testWidgets('arrow keys move between stamps and Space presses', (tester) async {
    final repo = FakeCircleRepository();
    await _pump(tester, repo);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await settle(tester, 300);
    expect(repo.log.where((e) => e.startsWith('react')), isNotEmpty);
  });
}
