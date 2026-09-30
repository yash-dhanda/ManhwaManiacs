// ignore_for_file: require_trailing_commas, directives_ordering
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/novels/models/novel_cast.dart';
import 'package:manhwamaniacs/features/novels/models/novel_chapter.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_cast_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_chapter_provider.dart';
import 'package:manhwamaniacs/features/reader/utils/reader_wakelock.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/novel/novel_route.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_route_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../feature/feature_test_support.dart';
import '../../../features/novels/support/novel_fixtures.dart';

export '../feature/feature_test_support.dart';
export '../../../features/novels/support/novel_fixtures.dart';

const kNovelSource = 'demo';
const kNovelSeries = 'k';

class _NoWakelock implements ReaderWakelock {
  @override
  Future<void> enable() async {}
  @override
  Future<void> disable() async {}
}

/// Twelve chapters of the fixture series, numbered 1-12, keyed `1`-`12`.
List<SourceChapterSummary> novelChapters({int count = 12}) => [
      for (var i = 1; i <= count; i++)
        SourceChapterSummary(id: '$i', sourceId: kNovelSource, seriesId: kNovelSeries, title: 'Chapter $i. Down the well $i', number: i.toDouble(), pageCount: 0),
    ];

/// The fixture chapter re-keyed to [key] (paragraphs unchanged).
NovelChapter novelChapterFor(String key, {String? title, bool offline = false, bool cacheStale = false, List<String>? paragraphs}) {
  final base = fixtureChapter();
  final n = int.tryParse(key) ?? 1;
  return NovelChapter(
    sourceId: kNovelSource,
    seriesKey: kNovelSeries,
    chapterKey: key,
    chapterNumber: n.toDouble(),
    title: title ?? (n == 1 ? base.title : 'Down the well $n'),
    paragraphs: paragraphs ?? base.paragraphs,
    previousChapterKey: n > 1 ? '${n - 1}' : null,
    nextChapterKey: n < 12 ? '${n + 1}' : null,
    wordCount: base.wordCount,
    isOffline: offline,
    cacheStale: cacheStale,
    cacheFetchedAt: cacheStale ? DateTime.now().toUtc().subtract(const Duration(hours: 3)).toIso8601String() : null,
  );
}

class NovelRig {
  NovelRig({required this.feature, required this.router});
  final FeatureRig feature;
  final GoRouter router;
  Recorder get rec => feature.rec;
}

/// Mounts the Cinematic novel reader at `/novels/demo/k/1` on top of `/` over the feature fakes
/// and a 12-chapter fixture book.
Future<NovelRig> pumpNovel(
  WidgetTester tester, {
  String chapterKey = '1',
  Size? size,
  bool wide = false,
  double textScale = 1,
  bool reduced = false,
  bool boldText = false,
  TargetPlatform platform = TargetPlatform.android,
  Map<String, Object> prefsValues = const {},
  List<Override> extra = const [],
  NovelAttribution? attribution,
  Map<String, Object> failing = const {},
  Map<String, Future<void>> holds = const {},
  bool offline = false,
  bool cacheStale = false,
  List<String>? paragraphs,
  String query = '',
  bool pushed = true,
  FeatureRig? rig,
}) async {
  final r = rig ?? FeatureRig();
  SharedPreferences.setMockInitialValues(prefsValues);
  final prefs = await SharedPreferences.getInstance();
  sizeView(tester, size: size, wide: wide);
  final fixture = loadSeriesFixture('manga-ongoing');
  final router = GoRouter(
    initialLocation: pushed ? '/' : '/novels/$kNovelSource/$kNovelSeries/$chapterKey$query',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const Scaffold(body: Text('book page'))),
      GoRoute(
        path: '/novels/:sourceId/:seriesKey/:chapterKey',
        pageBuilder: (context, state) => cineReaderPage(context, state, novelScreenFor(state), pageKey: novelPageKeyFor(state)),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...featureOverrides(r, prefs, novel: true),
        readerWakelockProvider.overrideWithValue(_NoWakelock()),
        sourceSeriesDetailProvider.overrideWith(
          (ref, k) async => SourceSeriesDetailData(series: fixture.series, chapters: novelChapters()),
        ),
        resolvedNovelChapterProvider.overrideWith((ref, key) async {
          final hold = holds[key.chapterKey];
          if (hold != null) await hold;
          final fail = failing[key.chapterKey];
          if (fail != null) throw fail;
          return novelChapterFor(key.chapterKey, offline: offline, cacheStale: cacheStale, paragraphs: paragraphs);
        }),
        novelChapterNeighboursProvider.overrideWith((ref, key) async {
          final n = int.tryParse(key.chapterKey) ?? 1;
          return (previousChapterKey: n > 1 ? '${n - 1}' : null, nextChapterKey: n < 12 ? '${n + 1}' : null);
        }),
        novelAttributionProvider.overrideWith((ref, key) async => attribution ?? NovelAttribution.none),
        ...extra,
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        theme: featureTheme(platform),
        builder: (context, c) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: reduced,
            boldText: boldText,
          ),
          child: c!,
        ),
      ),
    ),
  );
  await tester.pump();
  if (pushed) {
    unawaited(router.push<void>('/novels/$kNovelSource/$kNovelSeries/$chapterKey$query'));
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
  return NovelRig(feature: r, router: router);
}

Future<void> settleNovel(WidgetTester tester, {int ms = 1000}) async {
  for (var t = 0; t < ms; t += 100) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Tears the reader down and lets its timers run out.
Future<void> disposeNovel(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 11));
}
