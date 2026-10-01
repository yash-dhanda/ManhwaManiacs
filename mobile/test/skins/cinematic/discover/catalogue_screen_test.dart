import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/pagination.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/features/sources/models/source_genre.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/set_heading.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/catalogue/catalogue_screen.dart';

import 'harness.dart';

void main() {
  final items = [
    for (var i = 0; i < 6; i++) series('s$i', 'Series $i', 'asura'),
  ];

  testWidgets('loaded: deck count, modes, genre control, end of catalogue',
      (tester) async {
    await pumpScreen(
      tester,
      const CatalogueScreen(sourceId: 'asura'),
      sources: FakeSources(
        sources: [src('asura')],
        series: items,
        modes: const [
          SourceBrowseMode(id: 'popular', label: 'Popular'),
          SourceBrowseMode(id: 'latest', label: 'Latest'),
        ],
        genres: const [SourceGenre(id: 'r', label: 'Romance')],
      ),
    );
    await settle(tester, 800);
    expect(find.byWidgetPredicate((w) => w is SetHeading && w.text == 'ASURA'), findsOneWidget);
    expect(find.text('Catalogue · 6 series'), findsOneWidget);
    expect(find.text('POPULAR'), findsOneWidget);
    expect(find.text('Genre'), findsOneWidget);
    expect(find.text('Series 0'), findsWidgets);
    await tester.drag(find.byType(ListView).first, const Offset(0, -3000));
    await settle(tester, 300);
    expect(find.text('END OF CATALOGUE'), findsOneWidget);
  });

  testWidgets('opening state: after 3 s the deck changes and a tip types',
      (tester) async {
    await pumpScreen(
      tester,
      const CatalogueScreen(sourceId: 'asura'),
      sources: _Slow(),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(
        find.textContaining('This source can take about 10 s.'), findsNothing,);
    await tester.pump(const Duration(seconds: 3, milliseconds: 200));
    expect(find.text('This source can take about 10 s.'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.textContaining('Press / to search'), findsOneWidget);
  });

  testWidgets('not browsable shows the notice and hides modes and genre',
      (tester) async {
    await pumpScreen(
      tester,
      const CatalogueScreen(sourceId: 'asura'),
      sources: FakeSources(
        sources: [src('asura', browsable: false)],
        modes: const [SourceBrowseMode(id: 'popular', label: 'Popular')],
        genres: const [SourceGenre(id: 'r', label: 'Romance')],
      ),
    );
    await settle(tester, 4000);
    expect(find.textContaining('This source can only be searched, not browsed.'),
        findsOneWidget,);
    expect(find.text('POPULAR'), findsNothing);
    expect(find.text('Genre'), findsNothing);
    expect(find.text('Search it'), findsOneWidget);
  });

  testWidgets('source_not_found shows the not-available notice',
      (tester) async {
    await pumpScreen(
      tester,
      const CatalogueScreen(sourceId: 'gone'),
      sources: FakeSources(
        sources: [src('asura')],
        listSeriesError: const ApiError(
            statusCode: 404, code: 'source_not_found', message: 'nope',),
      ),
    );
    await settle(tester, 800);
    expect(find.text('NOT IN THIS ISSUE'), findsOneWidget);
    expect(find.text('Back to Tonight'), findsOneWidget);
  });

  testWidgets('full error shows CORRECTION with Try again', (tester) async {
    await pumpScreen(
      tester,
      const CatalogueScreen(sourceId: 'asura'),
      sources: FakeSources(
        sources: [src('asura')],
        listSeriesError: const ApiError(
            statusCode: 500, code: 'boom', message: 'Upstream exploded',),
      ),
    );
    await settle(tester, 800);
    expect(find.text('CORRECTION'), findsOneWidget);
    expect(find.text('Upstream exploded'), findsOneWidget);
  });

  testWidgets('tap targets', (tester) async {
    final h = tester.ensureSemantics();
    await pumpScreen(
      tester,
      const CatalogueScreen(sourceId: 'asura'),
      sources: FakeSources(sources: [src('asura')], series: items),
      platform: TargetPlatform.iOS,
    );
    await settle(tester, 800);
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    h.dispose();
  });

  testWidgets('picking a genre sends its id and keeps the back stack', (tester) async {
    final fake = FakeSources(
      sources: [src('asura')],
      series: items,
      genres: const [SourceGenre(id: 'r', label: 'Romance')],
    );
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const Scaffold(body: Text('list'))),
      GoRoute(
        path: '/sources/:id',
        builder: (_, s) => CatalogueScreen(
          sourceId: s.pathParameters['id']!,
          mode: s.uri.queryParameters['mode'],
          genre: s.uri.queryParameters['genre'],
          q: s.uri.queryParameters['q'],
        ),
      ),
    ],);
    await pumpScreen(tester, const SizedBox(), sources: fake, router: router);
    unawaited(router.push('/sources/asura'));
    await settle(tester, 800);
    await tester.tap(find.text('Genre'));
    await settle(tester);
    await tester.tap(find.text('Romance'));
    await settle(tester, 800);
    expect(fake.genresSent.last, 'r');
    expect(find.text('Genre: Romance'), findsOneWidget);
    router.pop();
    await settle(tester);
    expect(find.text('list'), findsOneWidget);
  });

  testWidgets('a short page with more to come loads the next by itself', (tester) async {
    final fake = FakeSources(sources: [src('asura')], series: [items.first], next: true);
    await pumpScreen(tester, const CatalogueScreen(sourceId: 'asura'), sources: fake);
    await settle(tester, 800);
    expect(fake.seriesCalls, greaterThan(1));
  });
}

class _Slow extends FakeSources {
  _Slow() : super(sources: [src('asura')]);

  @override
  Future<Result<PagedResult<SourceSeriesSummary>>> listSeries(
    String sourceId, {
    int page = 1,
    String? query,
    String? sort,
    String? genre,
    bool refresh = false,
  }) =>
      Completer<Result<PagedResult<SourceSeriesSummary>>>().future;
}
