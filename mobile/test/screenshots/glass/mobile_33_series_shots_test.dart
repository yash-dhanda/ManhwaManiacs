@Tags(['screenshots'])
library;

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/platform/gravity.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/providers/series_download_status_provider.dart';
import 'package:manhwamaniacs/features/library/models/global_search_result.dart';
import 'package:manhwamaniacs/features/reader/utils/reader_wakelock.dart';
import 'package:manhwamaniacs/features/sources/models/source_chapter_progress.dart';
import 'package:manhwamaniacs/features/sources/models/source_search_group.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/features/sources/repositories/sources_repository.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/glass/glass/light_angle.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/download_control.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/routes/nav_extra.dart';
import 'package:manhwamaniacs/skins/glass/screens/series/series_actions.dart' show openMoveSource;
import 'package:manhwamaniacs/skins/glass/screens/series/series_detail.dart';
import 'package:manhwamaniacs/skins/glass/transitions/book_open_page.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../skins/glass/series/series_rig.dart';
import '../glass_shell_shots_support.dart';
import '../support/skin_shots.dart';

/// The mobile/33 proof captures: the Glass series sheet, window and full page, the book page, the inner sheets and every state, on
/// invented data (nothing mature). Written only when `MM_PROOF_DIR` is set; otherwise rasterised and discarded.

const _loc = '/sources/demo/series/k1000';
final _phone = kSkinShotSizes[0];
final _tablet = kSkinShotSizes[1];
const _desk = kSkinShotDesktop;

class _Sources implements SourcesRepository {
  @override
  Future<Result<GroupedSearchResult>> searchGrouped(String query, {int page = 1, int perPage = 40, int? tier}) async => Ok(
        GroupedSearchResult(
          groups: [
            for (final s in const ['Asura Scans', 'Flame Comics'])
              SourceSearchGroup(source: s.toLowerCase().replaceAll(' ', '-'), sourceName: s, status: SourceGroupStatus.ok, items: [GlobalSearchItem(kind: 'source', source: s.toLowerCase().replaceAll(' ', '-'), seriesId: 'solo', title: 'Solo Leveling', extra: const {'chapter_count': 412})]),
          ],
          sourcesQueried: 2,
          tier: tier,
        ),
      );
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

final _progress = {'c142': SourceChapterProgress(page: 18, pageCount: 40, completed: false, updatedAt: DateTime(2026, 9, 28)), for (var i = 1; i < 142; i++) 'c$i': SourceChapterProgress(page: 40, pageCount: 40, completed: true, updatedAt: DateTime(2026, 9, 1, 0, i))};

Map<String, ChapterDownloadStatus> _saved(int from, int to) => {for (var i = from; i <= to; i++) 'c$i': (state: DownloadChapterState.complete, error: null)};

class _Wake implements ReaderWakelock {
  @override
  Future<void> enable() async {}
  @override
  Future<void> disable() async {}
}

List<Override> _ov({SourceSeriesDetailData? data, bool followed = false, bool novel = false, bool mature = false, Map<String, ChapterDownloadStatus> saved = const {}, Map<String, SourceChapterProgress>? progress}) => [
      ...seriesOverrides(data: data, followed: followed ? [followRow()] : const [], novel: novel, mature: mature, progress: progress ?? _progress),
      seriesChapterDownloadStatusProvider.overrideWith((ref, s) async => saved),
      sourcesRepositoryProvider.overrideWithValue(_Sources()),
      // Book open lands on mobile/36's novel reader, which holds the screen awake.
      readerWakelockProvider.overrideWithValue(_Wake()),
      glassLightAngleProvider.overrideWith((ref) => Stream.value(kLightAngleRest)),
    ];

Future<ShotSession> _sheet(WidgetTester t, SkinShotSize size, {List<Override> extra = const [], Offset? velocity, bool sheet = true, String start = '/'}) async {
  final s = await openShell(t, size, start: start, extra: extra);
  if (sheet) {
    unawaited(s.router.push<void>(_loc, extra: GlassNavExtra(velocity: velocity)));
    await s.settle(600);
    await s.settle(600);
    await s.settle(600);
  }
  return s;
}

Future<void> _frames(WidgetTester t, [int ms = 900]) async {
  for (var i = 0; i < ms ~/ 50; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _end(WidgetTester t) async {
  await t.pumpWidget(const SizedBox.shrink());
  await t.pump(const Duration(minutes: 11));
}

Future<void> _scrollTo(WidgetTester t, Finder f) async {
  await t.dragUntilVisible(f, find.byType(Scrollable).first, const Offset(0, -200));
  await t.pump(const Duration(milliseconds: 400));
}

SeriesPageState _page(WidgetTester t) => t.state<SeriesPageState>(find.byType(GlassSeriesPage));

void main() {
  testWidgets('phone sheet: medium, large, mid drag, a11y copies', (t) async {
    var s = await _sheet(t, _phone, extra: _ov());
    await s.snap('sheet-medium', _phone);
    final g = await t.startGesture(t.getCenter(find.byKey(const ValueKey('series-band'))));
    await g.moveBy(const Offset(0, -60));
    await t.pump(const Duration(milliseconds: 50));
    await g.moveBy(const Offset(0, -120));
    await t.pump(const Duration(milliseconds: 50));
    await s.snap('sheet-mid-drag', _phone);
    await g.up();
    await _end(t);
    s = await _sheet(t, _phone, extra: _ov(), velocity: const Offset(0, -2400));
    await s.snap('sheet-large-collapsed', _phone);
    await _end(t);
    s = await _sheet(t, _phone, extra: [..._ov(), glassMotionPrefsProvider.overrideWith((ref) => const GlassMotionPrefs(reduced: true))]);
    await s.snap('sheet-medium-reduced', _phone);
    await _end(t);
    s = await _sheet(t, _phone, extra: _ov());
    s.container.read(glassInAppPrefsProvider.notifier).setSolidGlass(true);
    await s.settle(600);
    await s.snap('sheet-medium-solid', _phone);
    s.container.read(glassInAppPrefsProvider.notifier)
      ..setSolidGlass(false)
      ..setIncreaseContrast(true);
    await s.settle(600);
    await s.snap('sheet-medium-contrast', _phone);
    await _end(t);
  });

  testWidgets('full page, cover landing, follow ring, tilt', (t) async {
    var s = await _sheet(t, _phone, extra: _ov(), sheet: false, start: _loc);
    await s.snap('full-page', _phone);
    await _end(t);
    s = await openShell(t, _phone, extra: _ov());
    unawaited(s.router.push<void>(_loc, extra: const GlassNavExtra()));
    await t.pump();
    await t.pump(const Duration(milliseconds: 180));
    await s.snap('cover-landing-mid', _phone);
    await s.settle(900);
    await t.tap(find.byKey(_page(t).followKey));
    await t.pump(const Duration(milliseconds: 240));
    await s.snap('follow-ring', _phone);
    await t.pump(const Duration(seconds: 11));
    await _end(t);
    final events = StreamController<AccelerometerEvent>.broadcast();
    s = await _sheet(t, _phone, extra: [..._ov(), gravitySensorProvider.overrideWithValue(() => events.stream)]);
    for (var i = 0; i < 40; i++) {
      events.add(AccelerometerEvent(i == 0 ? 0 : 4.9, i == 0 ? 0 : 4.9, 8, DateTime(2026)));
      await t.pump(const Duration(milliseconds: 33));
    }
    await s.settle(400);
    await s.snap('tilt', _phone);
    await events.close();
    await _end(t);
  });

  testWidgets('menu, tags, move source, toasts', (t) async {
    var s = await _sheet(t, _phone, extra: _ov(followed: true));
    _page(t).openMenu(const Rect.fromLTWH(300, 120, 44, 44));
    await _frames(t, 600);
    await s.snap('menu', _phone);
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await _frames(t, 600);
    _page(t).commands.tags!();
    await _frames(t);
    await s.snap('tags-sheet', _phone);
    await _end(t);
    s = await _sheet(t, _phone, extra: _ov(followed: true));
    openMoveSource(t.element(find.byType(GlassSeriesPage)), _page(t).data);
    await _frames(t);
    await t.tap(find.text('Solo Leveling').last);
    await s.settle(400);
    await s.snap('move-source', _phone);
    await _end(t);
    s = await _sheet(t, _phone, extra: _ov());
    s.container.read(glassToastProvider.notifier).show(const GlassToastSpec('10 of 12 downloaded, 1 with missing pages, 1 failed', kind: GlassToastKind.error));
    await s.settle(500);
    await s.snap('summary-toast', _phone);
    await t.pump(const Duration(seconds: 11));
    await _end(t);
  });

  testWidgets('chapters: select mode, running, row menu, swipe, saved menu, fast scroll', (t) async {
    var s = await _sheet(t, _phone, extra: _ov(saved: _saved(1, 24)), sheet: false, start: _loc);
    final p = _page(t);
    p.toggleSelect();
    p.chapters.selection.replaceWith([for (var i = 143; i <= 152; i++) 'c$i']);
    await s.settle(400);
    await _scrollTo(t, find.byKey(const ValueKey('helper-Next 10')));
    await s.snap('select-mode', _phone);
    p.chapters.run = {for (var i = 143; i <= 154; i++) 'c$i'};
    p.chapters.selection.end();
    await s.settle(400);
    await s.snap('select-running', _phone);
    await _end(t);
    s = await _sheet(t, _phone, extra: _ov(saved: _saved(990, 1000)), sheet: false, start: _loc);
    final row = find.byKey(const ValueKey('chapter-c999'));
    await _scrollTo(t, row);
    await t.longPress(row);
    await s.settle(600);
    await s.snap('chapter-context-menu', _phone);
    await t.tapAt(const Offset(20, 60));
    await s.settle(600);
    final g = await t.startGesture(t.getCenter(find.byKey(const ValueKey('chapter-c998'))));
    await g.moveBy(const Offset(40, 0));
    await t.pump(const Duration(milliseconds: 30));
    await g.moveBy(const Offset(80, 0));
    await t.pump(const Duration(milliseconds: 60));
    await s.snap('swipe-row', _phone);
    await g.cancel();
    await s.settle(600);
    await t.tap(find.descendant(of: find.byKey(const ValueKey('chapter-c999')), matching: find.byType(GlassDownloadControl)));
    await s.settle(600);
    await s.snap('saved-chapter-menu', _phone);
    await _end(t);
    s = await _sheet(t, _phone, extra: _ov(), sheet: false, start: _loc);
    await t.fling(find.byType(Scrollable).first, const Offset(0, -2500), 6000);
    await t.pump(const Duration(milliseconds: 300));
    await s.snap('fast-scroll-1000', _phone);
    await _end(t);
  });

  testWidgets('book page, book open, TOC pulse', (t) async {
    var s = await _sheet(t, _phone, extra: _ov(novel: true, progress: const {}), sheet: false, start: _loc);
    await s.snap('book-page', _phone);
    _page(t).jumpTo('c500');
    await t.pump(const Duration(milliseconds: 700));
    await s.snap('toc-pulse', _phone);
    await _end(t);
    s = await _sheet(t, _phone, extra: _ov(novel: true, progress: const {}), sheet: false, start: _loc);
    unawaited(s.router.push<void>('/novels/demo/k1000/c1', extra: bookOpenExtra(plateRect: const Rect.fromLTWH(16, 220, 144, 208), paper: const Color(0xFFF4EEE2))));
    await t.pump();
    await t.pump(const Duration(milliseconds: 260));
    await s.snap('book-open-mid', _phone);
    await t.pump(const Duration(seconds: 1));
    await _end(t);
    s = await _sheet(t, _desk, extra: _ov(novel: true, progress: const {}));
    await s.snap('book-page', _desk);
    await _end(t);
  });

  testWidgets('windows: tablet and desktop, scrolled, a11y copies', (t) async {
    var s = await _sheet(t, _tablet, extra: _ov());
    await s.snap('series-window', _tablet);
    await _end(t);
    s = await _sheet(t, _desk, extra: _ov(followed: true));
    await s.snap('series-window', _desk);
    await t.drag(find.byType(Scrollable).first, const Offset(0, -700));
    await s.settle(500);
    await s.snap('series-window-scrolled', _desk);
    await _end(t);
    s = await _sheet(t, _desk, extra: [..._ov(), glassMotionPrefsProvider.overrideWith((ref) => const GlassMotionPrefs(reduced: true))]);
    await s.snap('series-window-reduced', _desk);
    await _end(t);
    s = await _sheet(t, _desk, extra: _ov());
    s.container.read(glassInAppPrefsProvider.notifier).setSolidGlass(true);
    await s.settle(600);
    await s.snap('series-window-solid', _desk);
    s.container.read(glassInAppPrefsProvider.notifier)
      ..setSolidGlass(false)
      ..setIncreaseContrast(true);
    await s.settle(600);
    await s.snap('series-window-contrast', _desk);
    await _end(t);
  });

  final base = loadSeries();
  final states = <String, List<Override>>{
    'loading': [sourceSeriesDetailProvider.overrideWith((ref, k) => Completer<SourceSeriesDetailData>().future)],
    'offline': [sourceSeriesDetailProvider.overrideWith((ref, k) async => throw const NetworkError(message: 'offline'))],
    'error': [sourceSeriesDetailProvider.overrideWith((ref, k) async => throw const ApiError(statusCode: 500, code: 'internal', message: 'boom'))],
    'unavailable': [sourceSeriesDetailProvider.overrideWith((ref, k) async => throw const ApiError(statusCode: 404, code: 'series_not_found', message: 'gone'))],
    'chapters-unavailable': [sourceSeriesDetailProvider.overrideWith((ref, k) async => SourceSeriesDetailData(series: base.series, chapters: const []))],
    'no-chapters': [sourceSeriesDetailProvider.overrideWith((ref, k) async => const SourceSeriesDetailData(series: SourceSeriesSummary(id: 'k1000', sourceId: 'demo', title: 'Solo Leveling', chapterCount: 0, genres: ['Action'], coverUrl: ''), chapters: []))],
  };
  for (final e in states.entries) {
    testWidgets('state ${e.key}', (t) async {
      for (final size in [_phone, if (const {'offline', 'error', 'unavailable'}.contains(e.key)) _desk]) {
        final s = await _sheet(t, size, extra: [..._ov(followed: e.key == 'unavailable'), ...e.value], sheet: false, start: _loc);
        await s.snap(e.key, size);
        await _end(t);
      }
    });
  }
  testWidgets('state gated and caught up', (t) async {
    var s = await _sheet(t, _phone, extra: _ov(mature: true), sheet: false, start: _loc);
    await s.snap('gated', _phone);
    await _end(t);
    s = await _sheet(t, _desk, extra: _ov(mature: true), sheet: false, start: _loc);
    await s.snap('gated', _desk);
    await _end(t);
    s = await _sheet(t, _phone, extra: _ov(progress: {for (var i = 1; i <= 1000; i++) 'c$i': SourceChapterProgress(page: 40, pageCount: 40, completed: true, updatedAt: DateTime(2026, 9, 2, 0, i % 60))}), sheet: false, start: _loc);
    await s.snap('caught-up', _phone);
    await _end(t);
  });
}
