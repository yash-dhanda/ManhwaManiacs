// ignore_for_file: require_trailing_commas, directives_ordering
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/features/sources/providers/source_progress_provider.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/drop_cap_paragraph.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_view.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/test_overrides.dart';

SourceSeriesSummary _series({String title = 'Tower of Dawn'}) => SourceSeriesSummary(
      id: 'k',
      sourceId: 's',
      title: title,
      chapterCount: 3,
      description: 'A hunter climbs a tower that rewrites its own floors every night. '
          'Nobody who went in has come back the same.',
      author: 'Han',
      artist: 'Mi',
      status: 'ongoing',
      genres: const ['Action'],
      coverUrl: '',
    );

List<SourceChapterSummary> _chapters(int n) => [
      for (var i = 1; i <= n; i++)
        SourceChapterSummary(
            id: 'c$i',
            sourceId: 's',
            seriesId: 'k',
            title: 'Chapter $i',
            number: i.toDouble(),
            pageCount: 20),
    ];

Future<void> _pump(
  WidgetTester tester, {
  required Future<SourceSeriesDetailData> Function() detail,
  ContentMode mode = ContentMode.manga,
  bool wide = false,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = wide ? const Size(834, 1194) : const Size(390, 844);
  addTearDown(tester.view.reset);
  addTearDown(() async => tester.pumpWidget(const SizedBox()));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        apiBaseUrlOverride('http://example.test'),
        ...noDownloadsStoreOverrides(),
        ...contentModeOverrides(mode: mode, novelsEnabled: true),
        activeProfileOverride(),
        sourceModeIndexProvider.overrideWithValue({'s': mode}),
        sourceSeriesDetailProvider.overrideWith((ref, p) => detail()),
        sourceSeriesServerProgressProvider.overrideWith((ref, p) async => const {}),
      ],
      child: MaterialApp(
        theme: ThemeData(brightness: Brightness.dark, extensions: const [cinematicTokens]),
        home: const FeatureView(sourceId: 's', seriesKey: 'k'),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('manga: title, split primary, tabs, rows', (tester) async {
    await _pump(tester,
        detail: () async => SourceSeriesDetailData(series: _series(), chapters: _chapters(3)));
    expect(find.text('Tower of Dawn'), findsWidgets);
    expect(find.widgetWithText(FilledButton, 'Read  │  CH 1'), findsOneWidget);
    expect(find.text('01 CHAPTERS 3'), findsOneWidget);
    expect(find.text('02 DETAILS'), findsOneWidget);
    expect(find.text('FOLLOW'), findsOneWidget);
    expect(find.text('DOWNLOAD'), findsOneWidget);
  });

  testWidgets('manga: select mode shows the bar and counts', (tester) async {
    await _pump(tester,
        detail: () async => SourceSeriesDetailData(series: _series(), chapters: _chapters(3)));
    await tester.tap(find.text('DOWNLOAD'));
    await tester.pump();
    expect(find.text('Select chapters to download'), findsOneWidget);
    await tester.tap(find.text('NEXT 10'));
    await tester.pump();
    expect(find.text('3 SELECTED · 0 ALREADY SAVED'), findsOneWidget);
    expect(find.text('Download 3'), findsOneWidget);
  });

  testWidgets('manga on tablet renders the spread', (tester) async {
    await _pump(tester,
        wide: true,
        detail: () async => SourceSeriesDetailData(series: _series(), chapters: _chapters(3)));
    expect(find.text('Tower of Dawn'), findsWidgets);
    expect(find.byKey(const Key('primary-action')), findsOneWidget);
  });

  testWidgets('novel source renders the Book page', (tester) async {
    await _pump(
      tester,
      mode: ContentMode.novel,
      detail: () async => SourceSeriesDetailData(series: _series(), chapters: _chapters(3)),
    );
    expect(find.textContaining('NOVEL ·'), findsOneWidget);
    expect(find.text('by Han'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Start reading  │  CH 1'), findsOneWidget);
    expect(find.text('FIRST → LAST'), findsOneWidget);
  });

  testWidgets('a 404 shows the not-available notice', (tester) async {
    await _pump(
      tester,
      detail: () async =>
          throw const ApiError(statusCode: 404, code: 'series_not_found', message: 'x'),
    );
    expect(find.text('NOT IN THIS ISSUE'), findsOneWidget);
    expect(find.text("This series isn't available here any more."), findsOneWidget);
  });

  testWidgets('another error shows CORRECTION with Try again', (tester) async {
    await _pump(tester, detail: () async => throw const NetworkError(message: 'x'));
    expect(find.text('CORRECTION'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  test('drop cap split keeps the first three lines beside the cap', () {
    const style = TextStyle(fontSize: 16, height: 1.5);
    final text = List.filled(60, 'word').join(' ');
    final r = DropCapParagraph.split(text, style, 200, 3);
    final head =
        TextPainter(text: TextSpan(text: r.head, style: style), textDirection: TextDirection.ltr)
          ..layout(maxWidth: 200);
    expect(head.computeLineMetrics().length, lessThanOrEqualTo(3));
    expect('${r.head} ${r.tail}'.replaceAll(RegExp(r'\s+'), ' ').trim(), text);
    expect(r.tail, isNotEmpty);
  });
}
