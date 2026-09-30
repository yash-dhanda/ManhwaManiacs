import 'dart:async';
import 'dart:convert';
import 'dart:io';
// ignore_for_file: require_trailing_commas, directives_ordering
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/reader/models/reader_chapter.dart';
import 'package:manhwamaniacs/features/reader/models/reader_page.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_chapter_provider.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/features/sources/providers/source_reader_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/cine_reader_route.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_route_page.dart';
import 'package:manhwamaniacs/skins/reader_entries.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_chrome.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../feature/feature_test_support.dart';

export '../feature/feature_test_support.dart';

const kReaderSource = 'demo';
const kReaderSeries = 'k';

/// A chapter of [pages] tall pages (800 x 2400) so each one is well over a screen on a phone.
ReaderChapter readerChapter(String id, {int pages = 6, String? title, String? prev, String? next, String base = 'reader/page'}) => ReaderChapter(
      previousChapterId: prev,
      nextChapterId: next,
      id: id,
      seriesId: kReaderSeries,
      title: title ?? 'Chapter ${id.replaceAll(RegExp('[^0-9]'), '')}',
      pageCount: pages,
      sourceId: kReaderSource,
      seriesTitle: 'Tower of Dawn',
      pages: [
        for (var n = 1; n <= pages; n++)
          ReaderPage(id: '$id-$n', number: n, imageUrl: 'http://example.test/$base/$id-$n/image', width: 800, height: 2400),
      ],
    );

enum ReaderRigOrigin { manifest, source, legacy }

/// What a reader test can steer.
class ReaderRig {
  ReaderRig({required this.feature, required this.router});
  final FeatureRig feature;
  final GoRouter router;
  Recorder get rec => feature.rec;
}

/// Mounts the Cinematic manifest reader at `/read` on top of `/` (so it can pop), over the feature
/// fakes and a two-chapter series `c1`, `c2`, `c3` (fixture `manga-ongoing`).
Future<ReaderRig> pumpReader(
  WidgetTester tester, {
  String chapterKey = 'c2',
  int pages = 6,
  Size? size,
  double textScale = 1,
  bool reduced = false,
  TargetPlatform platform = TargetPlatform.android,
  Map<String, Object> prefsValues = const {},
  List<Override> extra = const [],
  FeatureRig? rig,
  Map<String, ReaderChapter> chapters = const {},
  Map<String, ({String? prev, String? next})> neighbours = const {},
  bool pushed = true,
  bool wide = false,
  String? status,
  Map<String, Object> failing = const {},
  Map<String, Future<void>> holds = const {},
  ReaderRigOrigin origin = ReaderRigOrigin.manifest,
  String pageBase = 'reader/page',
  bool cineRoute = false,
  Map<String, String>? pushExtra,
}) async {
  final r = rig ?? FeatureRig();
  SharedPreferences.setMockInitialValues(prefsValues);
  final prefs = await SharedPreferences.getInstance();
  sizeView(tester, size: size, wide: wide);
  final fixture = loadSeriesFixture('manga-ongoing');
  final series = status == null
      ? fixture.series
      : SourceSeriesSummary.fromJson(
          {
            ...(jsonDecode(File('test/fixtures/series/manga-ongoing.json').readAsStringSync()) as Map<String, dynamic>)['series'] as Map<String, dynamic>,
            'status': status,
          },
          'http://example.test',
        );
  ReaderChapter chapterFor(String k) => chapters[k] ?? readerChapter(k, pages: pages, base: pageBase);
  ({String? prev, String? next}) neighboursFor(String k) =>
      neighbours[k] ?? (k == 'c1' ? (prev: null, next: 'c2') : k == 'c2' ? (prev: 'c1', next: 'c3') : k == 'c3' ? (prev: 'c2', next: 'cx') : (prev: 'c3', next: null));
  Widget entry(BuildContext context) => switch (origin) {
        ReaderRigOrigin.manifest => CineReaderRoute.manifest(sourceId: kReaderSource, seriesKey: kReaderSeries, chapterKey: chapterKey),
        ReaderRigOrigin.source => CineReaderRoute.source(sourceId: kReaderSource, seriesKey: kReaderSeries, chapterKey: chapterKey),
        ReaderRigOrigin.legacy => manifestReaderEntry(sourceId: kReaderSource, seriesKey: kReaderSeries, chapterKey: chapterKey),
      };
  final router = GoRouter(
    initialLocation: pushed ? '/' : '/read',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const Scaffold(body: Text('series page'))),
      GoRoute(
        path: '/read',
        pageBuilder: cineRoute ? (context, state) => cineReaderPage(context, state, entry(context)) : null,
        builder: cineRoute ? null : (context, state) => entry(context),
      ),
      GoRoute(path: '/reader/:sourceId/:seriesKey/:chapterKey', builder: (context, state) => const Scaffold(body: Text('another chapter'))),
      GoRoute(path: '/library/read/:sourceId/:seriesKey/:chapterKey', builder: (context, state) => const Scaffold(body: Text('another chapter'))),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...featureOverrides(r, prefs, novel: false),
        sourceSeriesDetailProvider.overrideWith(
          (ref, k) async => SourceSeriesDetailData(series: series, chapters: fixture.chapters),
        ),
        resolvedReaderChapterProvider.overrideWith((ref, key) async {
          final hold = holds[key.chapterKey];
          if (hold != null) await hold;
          final fail = failing[key.chapterKey];
          if (fail != null) throw fail;
          final n = neighboursFor(key.chapterKey);
          return (chapter: chapterFor(key.chapterKey), chapterNumber: 1.0, prev: n.prev, next: n.next, isOffline: false);
        }),
        sourceReaderChapterProvider.overrideWith((ref, key) async {
          final hold = holds[key.chapterId];
          if (hold != null) await hold;
          final fail = failing[key.chapterId];
          if (fail != null) throw fail;
          final n = neighboursFor(key.chapterId);
          return readerChapter(key.chapterId, pages: pages, prev: n.prev, next: n.next, base: pageBase);
        }),
        sourceChapterNeighboursProvider.overrideWith((ref, key) async {
          final n = neighboursFor(key.chapterId);
          return (previousChapterId: n.prev, nextChapterId: n.next);
        }),
        chapterNeighboursProvider.overrideWith((ref, key) async {
          final n = neighboursFor(key.chapterKey);
          return (chapterNumber: 1.0, prev: n.prev, next: n.next);
        }),
        ...extra,
      ],
      child: RepaintBoundary(
        key: kShotBoundary,
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          routerConfig: router,
          theme: featureTheme(platform),
          builder: (context, c) => featureMediaWrap(context, c, textScale: textScale, reduced: reduced),
        ),
      ),
    ),
  );
  await tester.pump();
  if (pushed) {
    unawaited(router.push<void>('/read', extra: pushExtra));
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
  return ReaderRig(feature: r, router: router);
}

/// Lets the reader's timers and entrance animations run.
Future<void> settleReader(WidgetTester tester, {int ms = 1500}) async {
  for (var t = 0; t < ms; t += 100) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Whether the reader's chrome is on (hidden chrome is `Offstage`).
bool chromeVisible(WidgetTester tester) {
  final motions = find.byType(ReaderChromeMotion).evaluate();
  return motions.isNotEmpty && motions.every((e) => (e.widget as ReaderChromeMotion).visible);
}

/// A single tap at [at]: the engine's tap classifier reads the wall clock, so a real 350 ms gap
/// keeps two taps from being read as a double tap.
Future<void> tapSingle(WidgetTester tester, [Offset at = const Offset(195, 422)]) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 350)));
  await tester.tapAt(at);
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 300));
}

/// Tears the reader down and lets its timers (retry back-off, toasts, idle hide) run out.
Future<void> disposeReader(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 11));
}
