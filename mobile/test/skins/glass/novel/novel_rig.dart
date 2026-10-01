// ignore_for_file: require_trailing_commas
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/novels/models/novel_cast.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_audio_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_cast_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_chapter_provider.dart';
import 'package:manhwamaniacs/features/reader/utils/reader_wakelock.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/skins/glass/glass_skin.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast_host.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/novel_reader_screen.dart';
import 'package:manhwamaniacs/skins/glass/shell/glass_migration.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/test_overrides.dart';
import '../../cinematic/novel/novel_test_support.dart';

export '../../cinematic/novel/novel_test_support.dart' show FeatureRig, Recorder, fixtureAttribution, fixtureAttributionStale, fixtureChapter, kNovelSeries, kNovelSource, longFixtureParagraphs, novelChapterFor;

class _NoWakelock implements ReaderWakelock {
  int enabled = 0;
  @override
  Future<void> enable() async => enabled++;
  @override
  Future<void> disable() async {}
}

class GlassNovelRig {
  GlassNovelRig(this.tester, this.router, this.wakelock);
  final WidgetTester tester;
  final GoRouter router;
  final _NoWakelock wakelock;

  ProviderContainer get container => ProviderScope.containerOf(tester.element(find.byType(GlassNovelReader)));

  GlassNovelReaderState get state => tester.state<GlassNovelReaderState>(find.byType(GlassNovelReader));

  String get location => router.routerDelegate.currentConfiguration.uri.toString();
}

/// Mounts the Glass novel reader at `/novels/demo/k/{chapter}` over `/` (or alone with [pushed] false) on the feature fakes and a
/// 12-chapter fixture book, under the Glass root.
Future<GlassNovelRig> pumpGlassNovel(
  WidgetTester tester, {
  String chapterKey = '1',
  Size size = const Size(390, 844),
  bool pushed = true,
  String query = '',
  Map<String, Object> prefs = const {},
  NovelAttribution? attribution,
  bool offline = false,
  bool cacheStale = false,
  List<String>? paragraphs,
  Map<String, Object> failing = const {},
  Map<String, Future<void>> holds = const {},
  bool reduced = false,
  bool boldText = false,
  double textScale = 1,
  bool android = false,
  bool accessibleNavigation = false,
  EdgeInsets padding = EdgeInsets.zero,
  List<Override> extra = const [],
  Key? boundaryKey,
  FeatureRig? rig,
}) async {
  final r = rig ?? FeatureRig();
  SharedPreferences.setMockInitialValues(testPrefsDefaults(prefs));
  final sp = await SharedPreferences.getInstance();
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  if (padding != EdgeInsets.zero) {
    tester.view.padding = FakeViewPadding(left: padding.left, top: padding.top, right: padding.right, bottom: padding.bottom);
  }
  if (android) debugDefaultTargetPlatformOverride = TargetPlatform.android;
  addTearDown(() => debugDefaultTargetPlatformOverride = null);
  final router = GoRouter(
    initialLocation: pushed ? '/' : '/novels/$kNovelSource/$kNovelSeries/$chapterKey$query',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const Scaffold(body: Text('book page'))),
      GoRoute(path: '/sources/:sourceId/series/:seriesKey', builder: (context, state) => const Scaffold(body: Text('feature page'))),
      GoRoute(path: '/novels/:sourceId/:seriesKey/:chapterKey', pageBuilder: (context, state) => glassNovelPage(state)),
    ],
  );
  final wakelock = _NoWakelock();
  final fixture = loadSeriesFixture('manga-ongoing');
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...featureOverrides(r, sp, novel: true),
        glassPrefsMigrationProvider.overrideWithValue(null),
        if (reduced) glassMotionPrefsProvider.overrideWith((ref) => const GlassMotionPrefs(reduced: true)),
        readerWakelockProvider.overrideWithValue(wakelock),
        sourceSeriesDetailProvider.overrideWith((ref, k) async => SourceSeriesDetailData(series: fixture.series, chapters: novelChapters())),
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
        playableNovelAudioProvider.overrideWith((ref, key) async => null),
        ...extra,
      ],
      child: RepaintBoundary(
        key: boundaryKey,
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          routerConfig: router,
          theme: GlassSkin.baseTheme.copyWith(platform: defaultTargetPlatform),
          builder: (context, c) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              disableAnimations: reduced,
              boldText: boldText,
              accessibleNavigation: accessibleNavigation,
            ),
            child: GlassRoot(child: GlassToastHost(child: c!)),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  if (pushed) {
    unawaited(router.push<void>('/novels/$kNovelSource/$kNovelSeries/$chapterKey$query'));
    await tester.pump();
  }
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  return GlassNovelRig(tester, router, wakelock);
}

Future<void> settle(WidgetTester tester, {int ms = 1000}) async {
  for (var t = 0; t < ms; t += 100) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> disposeGlassNovel(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 11));
}

List<SourceChapterSummary> glassNovelChapters() => novelChapters();
