// ignore_for_file: require_trailing_commas, directives_ordering
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/models/ambient.dart';
import 'package:manhwamaniacs/features/novels/models/novel_typography.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/novel/novel_paragraph.dart';

import '../skins/cinematic/novel/novel_test_support.dart';
import 'support/series_shots.dart';
import 'support/skin_shots.dart';

/// The mobile-14 proof shots: the Cinematic novel reader, "The page", in every stock, face, layout
/// and state, over the invented Alice fixture chapter (public domain).
void mobile14Shots() {
  const landscape = kSkinShotLandscape;

  SourceSeriesSummary withAmbient() {
    final f = loadSeriesFixture('manga-ongoing').series;
    return SourceSeriesSummary(
      id: f.id,
      sourceId: f.sourceId,
      title: f.title,
      chapterCount: f.chapterCount,
      genres: f.genres,
      coverUrl: f.coverUrl,
      status: f.status,
      ambient: const Ambient(duo: Color(0xFFD98C3F), tint: Color(0xFF17100A), ink: Color(0xFFF0C98F)),
    );
  }

  SourceSeriesSummary withStatus(String status) {
    final f = loadSeriesFixture('manga-ongoing').series;
    return SourceSeriesSummary(id: f.id, sourceId: f.sourceId, title: f.title, chapterCount: f.chapterCount, genres: f.genres, coverUrl: f.coverUrl, status: status);
  }

  Future<void> scrollBy(WidgetTester t, double dy) async {
    await t.drag(find.byType(ListView).first, Offset(0, -dy));
    await settleNovel(t, ms: 500);
  }

  Future<void> toEnd(WidgetTester t) async {
    final pos = t.state<ScrollableState>(find.byType(Scrollable).first).position;
    for (var i = 0; i < 6; i++) {
      pos.jumpTo(pos.maxScrollExtent);
      await t.pump(const Duration(milliseconds: 200));
    }
    await settleNovel(t, ms: 500);
  }

  Future<void> openSheet(WidgetTester t, LogicalKeyboardKey key) async {
    await t.sendKeyEvent(key);
    await settleNovel(t, ms: 900);
  }

  Future<void> show(
    WidgetTester tester,
    String name, {
    SkinShotSize size = const SkinShotSize('phone', Size(390, 844), 3.0, EdgeInsets.only(top: 47, bottom: 34)),
    bool chrome = false,
    Map<String, dynamic> settings = const {},
    Future<void> Function(dynamic c)? book,
    Future<void> Function(WidgetTester tester, NovelRig rig)? act,
    bool reduced = false,
    double textScale = 1,
    bool bold = false,
    bool offline = false,
    bool cacheStale = false,
    bool issue = false,
    bool completed = false,
    Map<String, Object> failing = const {},
    Map<String, Future<void>> holds = const {},
    bool alt = false,
    TargetPlatform platform = TargetPlatform.android,
    List<String>? paragraphs,
    bool attribution = false,
    String chapterKey = '1',
  }) async {
    final rig = await pumpNovel(
      tester,
      size: size.logical,
      padding: size.padding,
      chapterKey: chapterKey,
      reduced: reduced,
      textScale: textScale,
      boldText: bold,
      offline: offline,
      cacheStale: cacheStale,
      failing: failing,
      holds: holds,
      platform: platform,
      paragraphs: paragraphs,
      attribution: attribution ? fixtureAttribution() : null,
      series: issue ? withAmbient() : (completed ? withStatus('Completed') : null),
      boundaryKey: kSkinShotKey,
    );
    await settleNovel(tester, ms: 800);
    if (settings.isNotEmpty) await rig.settings(settings);
    if (book != null) await rig.book((c) => book(c));
    await settleNovel(tester, ms: 400);
    if (act != null) await act(tester, rig);
    if (chrome) {
      await tester.tapAt(Offset(size.logical.width / 2, size.logical.height / 2));
      await settleNovel(tester, ms: 500);
    }
    await captureSeriesShot(tester, name, size);
    await disposeNovel(tester);
  }


  final tablet = kSkinShotSizes[1];

  testWidgets('mobile-14 stocks', (tester) async {
    await show(tester, 'novel-nitrate', chrome: true);
    for (final (id, name) in const [('ink', 'ink'), ('sepiaNight', 'sepia-night'), ('dusk', 'dusk'), ('moss', 'moss'), ('rosewood', 'rosewood')]) {
      await show(tester, 'novel-$name', settings: {'stock': id});
    }
    await show(tester, 'novel-issue', settings: {'stock': 'issue'}, issue: true);
    await show(tester, 'novel-nitrate', size: tablet, chrome: true);
    await show(tester, 'novel', size: landscape);
  });

  testWidgets('mobile-14 chapter parts', (tester) async {
    await show(tester, 'novel-opener-dropcap');
    await show(tester, 'novel-scene-break', act: (t, r) => scrollBy(t, 5200));
    await show(tester, 'novel-speaker-popover', attribution: true, act: (t, r) async {
      Finder f() => find.byWidgetPredicate((w) => w is NovelParagraph && w.text.startsWith('“Well!”'));
      for (var i = 0; i < 20 && f().evaluate().isEmpty; i++) {
        await scrollBy(t, 300);
      }
      await scrollBy(t, 250);
      final at = t.getTopLeft(f()) + const Offset(30, 12);
      await t.longPressAt(at);
      await settleNovel(t, ms: 300);
    });
    await show(tester, 'novel-end-matter', act: (t, r) => toEnd(t));
    await show(tester, 'novel-the-end', chapterKey: '12', completed: true, act: (t, r) => toEnd(t));
  });

  testWidgets('mobile-14 faces and scale', (tester) async {
    for (final f in NovelFace.values) {
      await show(tester, 'novel-faces-${f == NovelFace.sourceSerif ? 'source-serif' : f.wire}', book: (dynamic c) async {
        // ignore: avoid_dynamic_calls
        await c.setFace(f);
      });
    }
    await show(tester, 'novel-text-scale-2', textScale: 2);
  });

  testWidgets('mobile-14 paged', (tester) async {
    await show(tester, 'novel-paged', settings: {'layout': 'paged'});
    await show(tester, 'novel-paged', size: tablet, settings: {'layout': 'paged'});
    await show(tester, 'novel-paged-slide-midturn', settings: {'layout': 'paged', 'pageTurn': 'slide'}, act: (t, r) async {
      await t.timedDrag(find.byType(PageView), const Offset(-160, 0), const Duration(milliseconds: 300));
    });
    await show(tester, 'novel-paged-one-hand', settings: {'layout': 'paged', 'tapZones': 'oneHand'}, chrome: true);
  });

  testWidgets('mobile-14 sheets and panels', (tester) async {
    await show(tester, 'novel-type-sheet', act: (t, r) => openSheet(t, LogicalKeyboardKey.keyT));
    await show(tester, 'novel-type-sheet-full', act: (t, r) async {
      await openSheet(t, LogicalKeyboardKey.keyT);
      await t.fling(find.text('TEXT AND PAGE').first, const Offset(0, -600), 1200);
      await settleNovel(t, ms: 900);
    });
    await show(tester, 'novel-contents-sheet', act: (t, r) => openSheet(t, LogicalKeyboardKey.keyO));
    await show(tester, 'novel-contents-no-match', act: (t, r) async {
      await openSheet(t, LogicalKeyboardKey.keyO);
      await t.enterText(find.byType(TextField).first, '480');
      await settleNovel(t, ms: 500);
    });
    await show(tester, 'novel-contents-panel', size: tablet, act: (t, r) async {
      await t.tapAt(const Offset(417, 597));
      await settleNovel(t, ms: 500);
      await t.tap(find.bySemanticsLabel('Contents').first);
      await settleNovel(t, ms: 900);
    });
    await show(tester, 'novel-margins', size: tablet, act: (t, r) async {
      await t.tapAt(const Offset(417, 597));
      await settleNovel(t, ms: 500);
      await t.tap(find.bySemanticsLabel('Margins').first);
      await settleNovel(t, ms: 900);
    });
    await show(tester, 'novel-progress-field', chrome: true, act: (t, r) async {
      await t.tapAt(const Offset(195, 422));
      await settleNovel(t, ms: 500);
      await t.sendKeyEvent(LogicalKeyboardKey.keyG);
      await settleNovel(t, ms: 600);
    });
    await show(tester, 'novel-brightness-hud', settings: {'brightness': -40}, act: (t, r) async {
      final g = await t.startGesture(const Offset(20, 500));
      await g.moveBy(const Offset(0, -60));
      await t.pump(const Duration(milliseconds: 100));
    });
  });

  testWidgets('mobile-14 states', (tester) async {
    final gate = Completer<void>();
    await show(tester, 'novel-loading', holds: {'1': gate.future}, act: (t, r) => settleNovel(t, ms: 200));
    gate.complete();
    await show(tester, 'novel-offline-end', offline: true, chapterKey: '12', act: (t, r) => toEnd(t));
    await show(tester, 'novel-error', failing: {'1': const UnknownError(message: 'x')}, act: (t, r) => settleNovel(t, ms: 3000));
    await show(tester, 'novel-not-available', failing: {'1': const ApiError(statusCode: 404, code: 'series_not_found', message: 'gone')}, act: (t, r) => settleNovel(t, ms: 3000));
    await show(tester, 'novel-empty', paragraphs: const [], act: (t, r) => settleNovel(t, ms: 3000));
    await show(tester, 'novel-rate-limited', failing: {'1': const ApiError(statusCode: 429, code: 'rate_limited', message: 'slow', retryAfter: Duration(seconds: 8))}, act: (t, r) => settleNovel(t, ms: 3000));
    await show(tester, 'novel-saved-copy', cacheStale: true, offline: true, chrome: true);
    await show(tester, 'novel-rating-card', act: (t, r) => settleNovel(t, ms: 600));
    await show(tester, 'novel-reduced-motion', reduced: true, chrome: true);
  });
}
