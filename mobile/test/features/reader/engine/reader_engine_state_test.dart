import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_state.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_view.dart';
import 'package:manhwamaniacs/features/reader/models/reader_chapter.dart';
import 'package:manhwamaniacs/features/reader/models/reader_feed.dart';
import 'package:manhwamaniacs/features/reader/models/reader_page.dart';
import 'package:manhwamaniacs/features/reader/widgets/reader_content.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _base = ReaderEngineState(
  chapterId: 'c1',
  chapterTitle: 'Chapter 1',
  chapterIndex: 0,
  page: 3,
  pageCount: 12,
  progress: 0.2,
  atStart: false,
  atEnd: false,
  hasPrevious: true,
  hasNext: true,
  loadedChapterIds: ['c1', 'c2'],
  nextState: ReaderNextState.ready,
  bookmarks: [(page: 2, fraction: 0.5)],
  zoom: 1.0,
  autoScrolling: false,
  autoScrollSpeed: 60,
  chromeVisible: true,
  locked: false,
);

ReaderChapter _chapter(String id, {int pages = 2}) => ReaderChapter(
      id: id,
      seriesId: 's',
      title: 'Chapter $id',
      pageCount: pages,
      pages: [
        for (var n = 1; n <= pages; n++)
          ReaderPage(
            id: '$id-$n',
            number: n,
            imageUrl: 'http://example.test/reader/page/$id-$n/image',
            width: 800,
            height: 1200,
          ),
      ],
    );

Future<void> _pump(
  WidgetTester tester,
  SharedPreferences prefs,
  ReaderFeed feed, {
  Future<void> Function()? onReachedFeedEnd,
  VoidCallback? onNextChapter,
}) =>
    tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          home: ReaderContent(
            feed: feed,
            scrollStorageKey: 'k',
            onBack: () {},
            onOpenSeries: () {},
            onReachedFeedEnd: onReachedFeedEnd,
            onNextChapter: onNextChapter,
          ),
        ),
      ),
    );

ReaderEngine _engine(WidgetTester tester) =>
    tester.widget<ReaderEngineView>(find.byType(ReaderEngineView)).controller;

void main() {
  group('ReaderEngineState', () {
    test('== and hashCode cover every field', () {
      final same = _base.copyWith(
        loadedChapterIds: ['c1', 'c2'],
        bookmarks: [(page: 2, fraction: 0.5)],
      );
      expect(same, _base);
      expect(same.hashCode, _base.hashCode);

      final variants = <String, ReaderEngineState>{
        'chapterId': _base.copyWith(chapterId: 'c2'),
        'chapterTitle': _base.copyWith(chapterTitle: 'Chapter 2'),
        'chapterIndex': _base.copyWith(chapterIndex: 1),
        'page': _base.copyWith(page: 4),
        'pageCount': _base.copyWith(pageCount: 13),
        'progress': _base.copyWith(progress: 0.201),
        'atStart': _base.copyWith(atStart: true),
        'atEnd': _base.copyWith(atEnd: true),
        'hasPrevious': _base.copyWith(hasPrevious: false),
        'hasNext': _base.copyWith(hasNext: false),
        'loadedChapterIds': _base.copyWith(loadedChapterIds: ['c1']),
        'nextState': _base.copyWith(nextState: ReaderNextState.loading),
        'bookmarks': _base.copyWith(bookmarks: [(page: 2, fraction: 0.6)]),
        'zoom': _base.copyWith(zoom: 1.1),
        'autoScrolling': _base.copyWith(autoScrolling: true),
        'autoScrollSpeed': _base.copyWith(autoScrollSpeed: 120),
        'chromeVisible': _base.copyWith(chromeVisible: false),
        'locked': _base.copyWith(locked: true),
      };
      for (final entry in variants.entries) {
        expect(entry.value, isNot(_base), reason: entry.key);
      }
    });

    test('progress is quantised to 0.001', () {
      expect(ReaderEngineState.quantiseProgress(0.12345), 0.123);
      expect(ReaderEngineState.quantiseProgress(0.1235), 0.124);
      expect(ReaderEngineState.quantiseProgress(1.4), 1.0);
      expect(ReaderEngineState.quantiseProgress(-0.2), 0.0);
    });

    test('initial is page 1 of 1 with nothing next', () {
      const initial = ReaderEngineState.initial;
      expect(initial.chapterId, '');
      expect(initial.page, 1);
      expect(initial.pageCount, 1);
      expect(initial.progress, 0);
      expect(initial.nextState, ReaderNextState.none);
      expect(initial.zoom, 1.0);
      expect(initial.autoScrollSpeed, 60);
    });
  });

  group('nextState', () {
    testWidgets('nothing next anywhere: none', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await _pump(tester, prefs, ReaderFeed.single(_chapter('1')));
      await tester.pump();
      expect(_engine(tester).value.nextState, ReaderNextState.none);
    });

    testWidgets('the last chapter of a series: the fetch finding nothing is none, not failed', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final request = Completer<void>();
      await _pump(tester, prefs, ReaderFeed.single(_chapter('1')), onReachedFeedEnd: () => request.future);
      await tester.pump();
      request.complete();
      await tester.pump();
      expect(_engine(tester).value.nextState, ReaderNextState.none);
    });

    testWidgets('a next chapter exists: loading while it is fetched, failed when it does not stitch in, then ready', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final feed = ReaderFeed.single(_chapter('1'));
      var request = Completer<void>();
      var calls = 0;
      Future<void> extend() {
        calls++;
        return request.future;
      }

      await _pump(tester, prefs, feed, onReachedFeedEnd: extend, onNextChapter: () {});
      await tester.pump();
      expect(calls, 1);
      expect(_engine(tester).value.nextState, ReaderNextState.loading);

      // The fetch finishes without handing back a longer feed.
      request.complete();
      await tester.pump();
      expect(_engine(tester).value.nextState, ReaderNextState.failed);

      // A longer feed handed back: there is a chapter after the reading one.
      request = Completer<void>();
      await _pump(
        tester,
        prefs,
        feed.withAppended(_chapter('2')),
        onReachedFeedEnd: extend,
        onNextChapter: () {},
      );
      await tester.pump();
      expect(_engine(tester).value.nextState, ReaderNextState.ready);
      expect(_engine(tester).value.loadedChapterIds, ['1', '2']);
    });
  });
}
