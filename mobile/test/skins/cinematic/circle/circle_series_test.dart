import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/circle/utils/spoiler_guard.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/chapter_reaction_folio.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/circle_panel.dart';

import 'circle_harness.dart';

ChapterReactions _c(String key, double n, {bool sealed = true, ReactionKind? mine}) => ChapterReactions(
      chapterKey: key,
      chapterNumber: n,
      counts: {for (final k in ReactionKind.values) k: k == ReactionKind.loved ? 2 : 0},
      total: 2,
      by: [ReactionBy.of(riya, ReactionKind.loved), ReactionBy.of(arjun, ReactionKind.loved)],
      mine: mine,
      sealed: sealed,
    );

Future<void> _pump(WidgetTester t, FakeCircleRepository repo, Widget child, {TargetPlatform platform = TargetPlatform.iOS}) async {
  await pumpCine(
    t,
    CineTestEnv(),
    router: circleRouter(screen: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: child))),
    platform: platform,
    extra: [circleRepositoryProvider.overrideWithValue(repo)],
  );
  await settle(t, 800);
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('the schedule row folio counts the circle reactions and a long-press lists who, guarded per chapter', (t) async {
    final repo = FakeCircleRepository(reactionList: [_c('c142', 142), _c('c141', 141, sealed: false)]);
    await _pump(t, repo, const Column(children: [
      ChapterReactionFolio(sourceId: 's', seriesKey: 'or', chapterKey: 'c142', chapterNumber: 142),
      ChapterReactionFolio(sourceId: 's', seriesKey: 'or', chapterKey: 'c141', chapterNumber: 141),
      ChapterReactionFolio(sourceId: 's', seriesKey: 'or', chapterKey: 'c1', chapterNumber: 1),
    ],),);
    expect(find.text('2'), findsNWidgets(2));
    expect(find.bySemanticsLabel('2 circle reactions'), findsNWidgets(2));
    // The sealed chapter: "Riya reacted to Ch. 142", no reaction name.
    await t.longPress(find.bySemanticsLabel('2 circle reactions').first);
    await settle(t, 800);
    expect(find.text('Riya reacted to Ch. 142'), findsOneWidget);
    expect(find.text('Riya · Loved'), findsNothing);
  });

  testWidgets('a finished chapter lists the full reaction', (t) async {
    final repo = FakeCircleRepository(reactionList: [_c('c141', 141, sealed: false)]);
    await _pump(t, repo, const ChapterReactionFolio(sourceId: 's', seriesKey: 'or', chapterKey: 'c141', chapterNumber: 141));
    await t.longPress(find.bySemanticsLabel('2 circle reactions'));
    await settle(t, 800);
    expect(find.text('Riya · Loved'), findsOneWidget);
  });

  testWidgets('04 CIRCLE: followers, readers, reactions per chapter (guarded) and Recommend to…', (t) async {
    final repo = FakeCircleRepository(
      membersList: [member(riya, canReceive: true)],
      seriesData: CircleSeriesData(
        followers: const [riya],
        readers: [const CircleReader(member: arjun, chapterKey: 'c150', chapterNumber: 150)],
        chapters: [_c('c142', 142)],
      ),
      reactionList: [_c('c142', 142)],
    );
    await _pump(t, repo, const FeatureCircleContent(sourceId: 's', seriesKey: 'or', title: 'Omniscient Reader'));
    expect(find.text('Riya'), findsOneWidget);
    expect(find.text('Arjun is on Ch. 150'), findsOneWidget);
    expect(find.bySemanticsLabel('2 reactions, hidden until you finish the chapter'), findsOneWidget);
    expect(find.text('Recommend to…'), findsOneWidget);
  });

  testWidgets('the same chapter finished this session unseals the tab without a refetch', (t) async {
    final repo = FakeCircleRepository(
      membersList: [member(riya)],
      seriesData: CircleSeriesData(chapters: [_c('c142', 142)]),
      reactionList: [_c('c142', 142)],
    );
    await _pump(t, repo, const FeatureCircleContent(sourceId: 's', seriesKey: 'or', title: 'Omniscient Reader'));
    final container = ProviderScope.containerOf(t.element(find.byType(FeatureCircleContent)));
    container.read(completedThisSessionProvider.notifier).markCompleted('s', 'or', 'c142');
    await settle(t, 600);
    expect(find.bySemanticsLabel('Reactions to chapter 142'), findsOneWidget);
  });

  testWidgets('an empty circle says nobody has read it', (t) async {
    await _pump(t, FakeCircleRepository(seriesData: const CircleSeriesData()), const FeatureCircleContent(sourceId: 's', seriesKey: 'or', title: 'X'));
    expect(find.text('Nobody in your circle has read this yet.'), findsOneWidget);
  });
}
