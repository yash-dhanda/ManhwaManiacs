// ignore_for_file: require_trailing_commas
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/ai/models/similar_result.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/features/library/providers/intelligence_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_progress.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/manga_view.dart';

import 'feature_test_support.dart';

WorldItem _w(String t, {int id = 1, String? why, bool on = true}) => WorldItem(
      title: t,
      anilistId: id,
      why: why,
      available: on ? const [WorldAvailability(sourceId: 's', sourceName: 'S', seriesKey: 'x')] : const [],
    );

Future<FeatureRig> _open(
  WidgetTester tester, {
  SimilarResult? similar,
  SimilarResult? genres,
  Completer<SimilarResult>? gate,
  WorldRecommendations? recs,
  bool wide = false,
}) async {
  final rig = FeatureRig(
    followed: followedRow(),
    extra: [recommendationsProvider.overrideWith((ref) async => recs ?? const WorldRecommendations())],
  );
  rig.ai
    ..similarResult = similar
    ..genresResult = genres
    ..similarGate = gate;
  await pumpFeature(
    tester,
    rig: rig,
    wide: wide,
    size: wide ? null : const Size(390, 1800),
    child: MangaFeatureView(data: fixtureData('manga-long', followed: rig.followed), initialTab: 'more-like-this'),
  );
  await frames(tester, 600);
  await scrollToPanels(tester);
  await settleFeature(tester, by: const Duration(seconds: 3));
  return rig;
}

void main() {
  testWidgets('the tab is 03 MORE LIKE THIS and ?tab= opens it', (tester) async {
    await _open(tester, similar: SimilarResult(items: [_w('Night Ward', why: 'Slow and political.')]));
    expect(find.textContaining('03 MORE LIKE THIS'), findsOneWidget);
    expect(find.text('Night Ward'), findsWidgets);
  });

  testWidgets('Similar shows its cards with the why under the poster', (tester) async {
    await _open(tester, similar: SimilarResult(items: [_w('Night Ward', why: 'Slow and political.')]));
    expect(find.byWidgetPredicate((w) => w is Text && (w.data ?? '').toLowerCase() == 'slow and political.'), findsWidgets);
    expect(find.textContaining('PICKED'), findsNothing);
  });

  testWidgets('stale: PICKED 3 DAYS AGO beside the H3', (tester) async {
    await _open(tester, similar: SimilarResult(items: [_w('Night Ward')], generatedAt: DateTime.now().subtract(const Duration(days: 3, hours: 1))));
    expect(find.text('PICKED 3 DAYS AGO'), findsOneWidget);
  });

  testWidgets('thinking: the H3, the typed line and the dial after 1 s; then the cards', (tester) async {
    final gate = Completer<SimilarResult>();
    final rig = FeatureRig(followed: followedRow(), extra: [recommendationsProvider.overrideWith((ref) async => const WorldRecommendations())]);
    rig.ai.similarGate = gate;
    await pumpFeature(tester, rig: rig, size: const Size(390, 1800), child: MangaFeatureView(data: fixtureData('manga-long', followed: rig.followed), initialTab: 'more-like-this'));
    await frames(tester, 600);
    await scrollToPanels(tester);
    await settleFeature(tester, by: const Duration(seconds: 3));
    expect(find.text('Finding series like this one…'), findsOneWidget);
    expect(find.descendant(of: find.byType(CineLeaderDial), matching: find.byType(CustomPaint)), findsWidgets);
    gate.complete(SimilarResult(items: [_w('Night Ward')]));
    await settleFeature(tester, by: const Duration(seconds: 1));
    expect(find.text('Finding series like this one…'), findsNothing);
    expect(find.text('Night Ward'), findsWidgets);
  });

  testWidgets('unavailable: the NOTE copy and the SAME GENRES fallback rail', (tester) async {
    await _open(
      tester,
      similar: const SimilarResult(available: false, reason: 'budget_exhausted'),
      genres: SimilarResult(items: [_w('Salt and Ember', id: 2)], basis: 'genres'),
    );
    expect(find.text('NOTE'), findsOneWidget);
    expect(find.textContaining('The picks desk is closed tonight. Asks reset at midnight UTC. Here are series from the same genres.'), findsOneWidget);
    expect(find.text('SAME GENRES'), findsWidgets);
    expect(find.text('Salt and Ember'), findsWidgets);
  });

  testWidgets('unavailable with the server already answering the genre fallback', (tester) async {
    await _open(tester, similar: SimilarResult(items: [_w('Salt and Ember', id: 2)], available: false, reason: 'not_configured', basis: 'genres'));
    expect(find.textContaining("The editors' desk isn't set up on this server. Here are series from the same genres."), findsOneWidget);
    expect(find.text('SAME GENRES'), findsWidgets);
  });

  testWidgets('empty: the italic line', (tester) async {
    await _open(tester, similar: const SimilarResult());
    expect(find.text('Nothing similar on your sources yet.'), findsOneWidget);
  });

  testWidgets('a Because you read rail seeded from this series follows', (tester) async {
    final recs = WorldRecommendations(sections: [
      WorldSection(becauseTitle: 'Some Series', becauseSourceId: 'demo', becauseSeriesKey: fixtureData('manga-long', followed: followedRow()).seriesKey, items: [_w('Tower Tale', id: 7)]),
    ]);
    await _open(tester, similar: SimilarResult(items: [_w('Night Ward')]), recs: recs);
    expect(find.textContaining('Because you read'), findsWidgets);
    expect(find.text('Tower Tale'), findsWidgets);
  });

  testWidgets('the tab meets the tap target, label and contrast guidelines', (tester) async {
    final h = tester.ensureSemantics();
    await _open(tester, similar: SimilarResult(items: [_w('Night Ward', why: 'Slow and political.')]));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    h.dispose();
  });
}
