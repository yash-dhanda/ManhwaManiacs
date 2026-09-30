import 'dart:async';
// ignore_for_file: require_trailing_commas, directives_ordering
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/reader/models/reader_chapter.dart';
import 'package:manhwamaniacs/features/reader/models/reader_page.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_chapter_provider.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/cine_reader_route.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_chrome.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../feature/feature_test_support.dart';

export '../feature/feature_test_support.dart';

const kReaderSource = 'demo';
const kReaderSeries = 'k';

/// A chapter of [pages] tall pages (800 x 2400) so each one is well over a screen on a phone.
ReaderChapter readerChapter(String id, {int pages = 6, String? title}) => ReaderChapter(
      id: id,
      seriesId: kReaderSeries,
      title: title ?? 'Chapter ${id.replaceAll(RegExp('[^0-9]'), '')}',
      pageCount: pages,
      sourceId: kReaderSource,
      seriesTitle: 'Tower of Dawn',
      pages: [
        for (var n = 1; n <= pages; n++)
          ReaderPage(id: '$id-$n', number: n, imageUrl: 'http://example.test/reader/page/$id-$n/image', width: 800, height: 2400),
      ],
    );

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
}) async {
  final r = rig ?? FeatureRig();
  SharedPreferences.setMockInitialValues(prefsValues);
  final prefs = await SharedPreferences.getInstance();
  sizeView(tester, size: size, wide: wide);
  final fixture = loadSeriesFixture('manga-ongoing');
  ReaderChapter chapterFor(String k) => chapters[k] ?? readerChapter(k, pages: pages);
  ({String? prev, String? next}) neighboursFor(String k) =>
      neighbours[k] ?? (k == 'c1' ? (prev: null, next: 'c2') : k == 'c2' ? (prev: 'c1', next: 'c3') : (prev: 'c2', next: null));
  final router = GoRouter(
    initialLocation: pushed ? '/' : '/read',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const Scaffold(body: Text('series page'))),
      GoRoute(
        path: '/read',
        builder: (context, state) => CineReaderRoute.manifest(sourceId: kReaderSource, seriesKey: kReaderSeries, chapterKey: chapterKey),
      ),
      GoRoute(path: '/library/read/:sourceId/:seriesKey/:chapterKey', builder: (context, state) => const Scaffold(body: Text('another chapter'))),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...featureOverrides(r, prefs, novel: false),
        sourceSeriesDetailProvider.overrideWith(
          (ref, k) async => SourceSeriesDetailData(series: fixture.series, chapters: fixture.chapters),
        ),
        resolvedReaderChapterProvider.overrideWith((ref, key) async {
          final n = neighboursFor(key.chapterKey);
          return (chapter: chapterFor(key.chapterKey), chapterNumber: 1.0, prev: n.prev, next: n.next, isOffline: false);
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
    unawaited(router.push<void>('/read'));
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
}

/// Tears the reader down and lets its timers (retry back-off, toasts, idle hide) run out.
Future<void> disposeReader(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 11));
}
