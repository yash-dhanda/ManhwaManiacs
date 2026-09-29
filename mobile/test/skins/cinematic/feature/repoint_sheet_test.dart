// ignore_for_file: require_trailing_commas, directives_ordering
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/library/models/global_search_result.dart';
import 'package:manhwamaniacs/features/sources/models/source_chapter_progress.dart';
import 'package:manhwamaniacs/features/sources/models/source_search_group.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/repoint_sheet.dart';

import 'feature_test_support.dart';

SourceSearchGroup _group(String id, String name,
        {List<GlobalSearchItem> items = const [], SourceGroupStatus status = SourceGroupStatus.ok}) =>
    SourceSearchGroup(source: id, sourceName: name, status: status, items: items);

List<SourceChapterSummary> _chaps(int n) => [
      for (var i = 1; i <= n; i++)
        SourceChapterSummary(id: 'x$i', sourceId: 'asura', seriesId: 'tower', title: 'Chapter $i', number: i.toDouble(), pageCount: 10),
    ];

Future<FeatureRig> _open(
  WidgetTester tester, {
  required FakeSources sources,
  bool down = false,
  FeatureRig? rig,
}) async {
  final r = rig ?? FeatureRig(followed: followedRow(), serverProgress: {
    'c2': SourceChapterProgress(page: 4, pageCount: 20, completed: false, updatedAt: DateTime.utc(2026, 9, 29)),
  });
  final data = fixtureData('manga-ongoing', followed: r.followed);
  final app = await pumpFeatureRouter(
    tester,
    rig: r,
    extra: [sourcesRepositoryProvider.overrideWithValue(sources)],
    routes: [
      GoRoute(
        path: '/',
        builder: (c, s) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => showRepointSheet(c, data, sourceIsDown: down),
              child: const Text('open'),
            ),
          ),
        ),
      ),
      GoRoute(path: '/sources/:sourceId/series/:seriesKey', builder: (c, s) => const Scaffold(body: Text('moved page'))),
    ],
  );
  await tester.tap(find.text('open'));
  await frames(tester, 600);
  return app.rig;
}

void main() {
  const asura = GlobalSearchItem(kind: 'source', source: 'asura', seriesId: 'tower', title: 'Tower of Dawn', extra: {'chapter_count': 150});

  testWidgets('candidates: the title is searched, each row shows source, title and chapters', (tester) async {
    final sources = FakeSources(groups: [_group('asura', 'Asura', items: [asura])], chapters: _chaps(150));
    await _open(tester, sources: sources);
    expect(sources.searched, ['Tower of Dawn']);
    expect(find.text('MOVE TO ANOTHER SOURCE'), findsOneWidget);
    expect(find.text('Tower of Dawn'), findsOneWidget);
    expect(find.text('Asura'), findsOneWidget);
    expect(find.text('CHAPTERS 150'), findsOneWidget);
  });

  testWidgets('no candidates says so; a source that failed offers Retry', (tester) async {
    await _open(tester, sources: FakeSources());
    expect(find.text('No other source has this series.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await _open(tester,
        sources: FakeSources(groups: [_group('asura', 'Asura', status: SourceGroupStatus.error)]));
    expect(find.text("Asura didn't answer."), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('a dead source shows the NOTE banner', (tester) async {
    await _open(tester, sources: FakeSources(), down: true);
    expect(find.text('This source is down. Move the series to another source to keep reading.'), findsOneWidget);
  });

  testWidgets('picking a candidate shows the mapping sentence and Keep following it on', (tester) async {
    final sources = FakeSources(groups: [_group('asura', 'Asura', items: [asura])], chapters: _chaps(150));
    await _open(tester, sources: sources);
    await tester.tap(find.text('Tower of Dawn'));
    await frames(tester);
    expect(find.textContaining("You're on chapter 2; Asura has chapters 1–150, so chapter 2 there becomes your place."), findsOneWidget);
    expect(find.text('Keep following it on demo too'), findsOneWidget);
    expect(find.text('Move'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);
    await tester.tap(find.text('Back'));
    await frames(tester, 300);
    expect(find.text('CHAPTERS 150'), findsOneWidget);
  });

  testWidgets('the out-of-range sentence starts at chapter 1', (tester) async {
    final sources = FakeSources(groups: [_group('asura', 'Asura', items: [asura])]);
    await _open(tester, sources: sources);
    await tester.tap(find.text('Tower of Dawn'));
    await frames(tester);
    expect(find.textContaining("Chapter numbers don't line up, so you'll start at chapter 1 on Asura."), findsOneWidget);
  });

  testWidgets('Move sends the repoint, replaces the page and says where you are', (tester) async {
    final sources = FakeSources(groups: [_group('asura', 'Asura', items: [asura])], chapters: _chaps(150));
    final r = await _open(tester, sources: sources);
    await tester.tap(find.text('Tower of Dawn'));
    await frames(tester);
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.tap(find.text('Move'));
    await frames(tester, 800);
    expect(r.rec.repoints.single, {'id': 7, 'source': 'asura', 'series': 'tower', 'keep_old': true});
    expect(find.text('moved page'), findsOneWidget);
    expect(find.text("Moved to Asura. You're on chapter 2."), findsOneWidget);
  });
}
