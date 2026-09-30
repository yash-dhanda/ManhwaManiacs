// ignore_for_file: directives_ordering
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/sections.dart' show planSections;

import '../../../features/circle/fakes.dart';
import '../support/cine_harness.dart' show headline;
import '../tonight/tonight_test_support.dart';

const _stamp = {'mm.tonight.typed.u1p1': '{"date":"2026-09-30","variant":"normal"}'};

Future<TonightRig> _pump(WidgetTester t, FakeCircleRepository repo) async {
  final rig = await pumpTonight(t, feed: 'circle', size: const Size(390, 9000), prefs: _stamp, extra: [circleRepositoryProvider.overrideWithValue(repo)]);
  await settleTonight(t, by: const Duration(seconds: 3));
  return rig;
}

void main() {
  testWidgets('Sent to you, From the Circle and Most read in the circle render in the server order with gapless folios', (t) async {
    await _pump(t, FakeCircleRepository(letterList: [letter(1)]));
    for (final h in ['Sent to you', 'From the Circle', 'Most read in the circle']) {
      expect(headline(h), findsWidgets, reason: h);
    }
    // Ranked posters read "Number 2, Tower of God".
    expect(find.bySemanticsLabel('Number 2, Tower of God'), findsOneWidget);
    // The plan keeps the server's order and assigns folios without a gap.
    final plan = planSections(loadFeed('circle'));
    expect(plan.map((p) => p.folio), [for (var i = 1; i <= plan.length; i++) i.toString().padLeft(2, '0')]);
    final types = plan.map((p) => p.section.type).toList();
    expect(types.indexOf(HomeSectionType.sentToYou), lessThan(types.indexOf(HomeSectionType.picked)));
    expect(types.indexOf(HomeSectionType.circleTop), types.indexOf(HomeSectionType.circle) + 1);
  });

  testWidgets('the section note types under the heading', (t) async {
    await _pump(t, FakeCircleRepository(letterList: [letter(1)]));
    expect(find.bySemanticsLabel("Riya: you'll love the tower arc."), findsOneWidget);
  });

  testWidgets('a poster of Sent to you opens the series and marks its letter read', (t) async {
    final repo = FakeCircleRepository(letterList: [letter(1)]);
    final rig = await _pump(t, repo);
    final poster = find.byKey(const ValueKey('sent-1'));
    await t.ensureVisible(poster);
    await t.tap(poster);
    await settleTonight(t, by: const Duration(seconds: 1));
    expect(repo.log, contains('patchLetter 1 read'));
    expect(rig.visited.any((u) => u.contains('/sources/shelf/series/tower-of-god')), isTrue);
  });

  testWidgets('the Also in this issue letter card opens the LETTERS tab', (t) async {
    final rig = await _pump(t, FakeCircleRepository());
    final pager = find.byType(PageView).first;
    for (var i = 0; i < 3; i++) {
      await t.drag(pager, const Offset(-380, 0));
      await settleTonight(t, by: const Duration(milliseconds: 500));
    }
    final card = find.text('Riya recommends Tower of God');
    await t.tap(card.first);
    await settleTonight(t, by: const Duration(seconds: 1));
    expect(rig.visited, contains('/circle?tab=letters'));
  });
}
