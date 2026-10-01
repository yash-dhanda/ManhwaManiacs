// ignore_for_file: require_trailing_commas
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/platform/gravity.dart';
import 'package:manhwamaniacs/core/platform/mm_platform.dart';
import 'package:manhwamaniacs/features/ocr/models/page_text.dart';
import 'package:manhwamaniacs/features/ocr/providers/ocr_providers.dart';
import 'package:manhwamaniacs/features/reader/models/reader_chapter.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_chapter_provider.dart';
import 'package:manhwamaniacs/features/reader/utils/reader_wakelock.dart';
import 'package:manhwamaniacs/features/sources/providers/source_reader_provider.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/skins/glass/glass_skin.dart';
import 'package:manhwamaniacs/skins/glass/primitives/overlay_queue.dart' show glassReaderActiveProvider;
import 'package:manhwamaniacs/skins/glass/primitives/toast_host.dart';
import 'package:manhwamaniacs/skins/glass/router.dart' show kGlassReaderPageKey;
import 'package:manhwamaniacs/skins/glass/screens/reader/glass_manga_reader.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/reader_screen.dart';
import 'package:manhwamaniacs/skins/glass/shell/glass_migration.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../cinematic/reader/reader_test_support.dart';

export '../../cinematic/feature/feature_test_support.dart' show FeatureRig;
export '../../cinematic/reader/reader_test_support.dart' show readerChapter, kReaderSource, kReaderSeries, settleReader, Recorder;

/// Records wakelock calls.
class FakeWakelock implements ReaderWakelock {
  final List<String> calls = [];
  bool on = false;

  @override
  Future<void> enable() async {
    calls.add('enable');
    on = true;
  }

  @override
  Future<void> disable() async {
    calls.add('disable');
    on = false;
  }
}

/// Records `mm/platform` calls (`gestures.setExclusionRects`, `display.stableInsets`).
class RecordingPlatform extends MmPlatform {
  RecordingPlatform() : super(channel: const MethodChannel('mm/platform-test'));
  final List<List<List<double>>> exclusions = [];

  @override
  Future<void> setExclusionRects(List<List<double>> rects) async => exclusions.add(rects);

  @override
  Future<EdgeInsets?> stableInsets() async => const EdgeInsets.only(top: 24, bottom: 48);
}

class GlassReaderRig {
  GlassReaderRig({required this.router, required this.feature, required this.wakelock, required this.platform, required this.systemCalls});
  final GoRouter router;
  final FeatureRig feature;
  final FakeWakelock wakelock;
  final RecordingPlatform platform;

  /// `SystemChrome` messages on `SystemChannels.platform`.
  final List<MethodCall> systemCalls;

  /// The location of the top route (a pushed reader is an imperative match over `/`).
  Uri get at {
    final cfg = router.routerDelegate.currentConfiguration;
    final last = cfg.last;
    return last is ImperativeRouteMatch ? last.matches.uri : cfg.uri;
  }

  GlassMangaReaderState state(WidgetTester t) => t.state<GlassMangaReaderState>(find.byType(GlassMangaReader));
}

enum GlassReaderOrigin { manifest, source, readAll }

/// Mounts the Glass manga reader at `/reader/demo/k/<chapter>` (or the source alias) on top of `/`, inside the Glass root, over the
/// feature fakes and the three-chapter series c1, c2, c3 (fixture `manga-ongoing`).
Future<GlassReaderRig> pumpGlassReader(
  WidgetTester tester, {
  String chapterKey = 'c2',
  int pages = 6,
  Size size = const Size(390, 844),
  EdgeInsets padding = EdgeInsets.zero,
  TargetPlatform platform = TargetPlatform.iOS,
  GlassReaderOrigin origin = GlassReaderOrigin.manifest,
  Map<String, Object> prefsValues = const {},
  List<Override> extra = const [],
  String query = '',
  bool pushed = true,
  bool accessible = false,
  Map<String, ReaderChapter> chapters = const {},
  List<PageText>? ocr,
  bool mockPathProvider = true,
  FeatureRig? feature,
  bool toasts = false,
}) async {
  final r = feature ?? FeatureRig();
  SharedPreferences.setMockInitialValues(prefsValues);
  final prefs = await SharedPreferences.getInstance();
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size
    ..padding = FakeViewPadding(left: padding.left, top: padding.top, right: padding.right, bottom: padding.bottom)
    ..viewPadding = FakeViewPadding(left: padding.left, top: padding.top, right: padding.right, bottom: padding.bottom);
  addTearDown(tester.view.reset);
  debugDefaultTargetPlatformOverride = platform;
  addTearDown(() => debugDefaultTargetPlatformOverride = null);
  final systemCalls = <MethodCall>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    systemCalls.add(call);
    return null;
  });
  addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
  // Plugins the app's providers reach while real async runs (the auth restore, the image cache).
  // The screenshot suite installs its own path_provider (the cover cache lives there): it passes false.
  if (mockPathProvider) {
    final temp = Directory.systemTemp.createTempSync('mm-glass-reader-');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), (c) async => temp.path);
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), null));
  }
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'), (c) async => null);
  addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'), null));
  final wakelock = FakeWakelock();
  final mm = RecordingPlatform();
  final fixture = loadSeriesFixture('manga-ongoing');
  ({String? prev, String? next}) n(String k) => k == 'c1' ? (prev: null, next: 'c2') : k == 'c2' ? (prev: 'c1', next: 'c3') : (prev: 'c2', next: null);
  ReaderChapter chapterFor(String k) => chapters[k] ?? readerChapter(k, pages: pages, prev: n(k).prev, next: n(k).next);
  final readerPath = origin == GlassReaderOrigin.source
      ? '/sources/$kReaderSource/series/$kReaderSeries/chapters/$chapterKey/read$query'
      : origin == GlassReaderOrigin.readAll
          ? '/read-all/$kReaderSource/$kReaderSeries$query'
          : '/reader/$kReaderSource/$kReaderSeries/$chapterKey$query';
  Page<void> page(GoRouterState s, Widget child) => NoTransitionPage<void>(key: kGlassReaderPageKey, child: child);
  final router = GoRouter(
    initialLocation: pushed ? '/' : readerPath,
    routes: [
      GoRoute(path: '/', builder: (context, state) => const ColoredBox(color: Colors.black, child: Center(child: Text('series page')))),
      GoRoute(path: '/reader/:sourceId/:seriesKey/:chapterKey', pageBuilder: (c, s) => page(s, GlassReaderScreen.of(s))),
      GoRoute(path: '/library/read/:sourceId/:seriesKey/:chapterKey', pageBuilder: (c, s) => page(s, GlassReaderScreen.of(s))),
      GoRoute(path: '/sources/:sourceId/series/:seriesKey/chapters/:chapterKey/read', pageBuilder: (c, s) => page(s, GlassReaderScreen.of(s))),
      GoRoute(path: '/read-all/:sourceId/:seriesKey', pageBuilder: (c, s) => page(s, GlassReadAllScreen.of(s))),
      GoRoute(path: '/sources/:sourceId/series/:seriesKey', builder: (c, s) => const Text('feature page')),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...featureOverrides(r, prefs, novel: false),
        glassPrefsMigrationProvider.overrideWithValue(null),
        gravitySensorProvider.overrideWithValue(() => const Stream.empty()),
        readerWakelockProvider.overrideWithValue(wakelock),
        mmPlatformProvider.overrideWithValue(mm),
        sourceSeriesDetailProvider.overrideWith((ref, k) async => SourceSeriesDetailData(series: fixture.series, chapters: fixture.chapters)),
        resolvedReaderChapterProvider.overrideWith((ref, key) async {
          final x = n(key.chapterKey);
          return (chapter: chapterFor(key.chapterKey), chapterNumber: 1.0, prev: x.prev, next: x.next, isOffline: false);
        }),
        sourceReaderChapterProvider.overrideWith((ref, key) async {
          final x = n(key.chapterId);
          return readerChapter(key.chapterId, pages: pages, prev: x.prev, next: x.next);
        }),
        sourceChapterNeighboursProvider.overrideWith((ref, key) async => (previousChapterId: n(key.chapterId).prev, nextChapterId: n(key.chapterId).next)),
        chapterNeighboursProvider.overrideWith((ref, key) async => (chapterNumber: 1.0, prev: n(key.chapterKey).prev, next: n(key.chapterKey).next)),
        ocrChapterTextProvider.overrideWith((ref, id) async => ocr),
        if (toasts) glassReaderActiveProvider.overrideWith((ref) => true),
        ...extra,
      ],
      child: RepaintBoundary(
        key: kShotBoundary,
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          routerConfig: router,
          theme: GlassSkin.baseTheme.copyWith(platform: platform),
          builder: (context, c) => MediaQuery(
            data: MediaQuery.of(context).copyWith(accessibleNavigation: accessible),
            // The shell's toast host, for captures that show a reader toast (top-centre, 60 px down).
            child: const GlassSkin().wrap(
                context,
                toasts
                    ? Overlay(initialEntries: [OverlayEntry(builder: (_) => GlassToastHost(child: c ?? const SizedBox.shrink()))])
                    : c ?? const SizedBox.shrink()),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  if (pushed) {
    unawaited(router.push<void>(readerPath));
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
  return GlassReaderRig(router: router, feature: r, wakelock: wakelock, platform: mm, systemCalls: systemCalls);
}

/// Tears the reader down and lets its timers run out.
Future<void> disposeGlassReader(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 11));
  debugDefaultTargetPlatformOverride = null;
}
