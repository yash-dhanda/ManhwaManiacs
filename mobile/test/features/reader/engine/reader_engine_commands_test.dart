import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_provider.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_state.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_view.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_surface_slots.dart';
import 'package:manhwamaniacs/features/reader/models/reader_chapter.dart';
import 'package:manhwamaniacs/features/reader/models/reader_feed.dart';
import 'package:manhwamaniacs/features/reader/models/reader_page.dart';
import 'package:manhwamaniacs/features/reader/utils/reader_anchor.dart';
import 'package:manhwamaniacs/features/reader/widgets/reader_content.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tall pages (800 x 2400) so every page can reach the reading line.
ReaderChapter _chapter(String id, {int pages = 10}) => ReaderChapter(
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
            height: 2400,
          ),
      ],
    );

ReaderFeed _threeChapters() =>
    ReaderFeed.of([_chapter('1'), _chapter('2'), _chapter('3')]);

Future<SharedPreferences> _prefs() async {
  SharedPreferences.setMockInitialValues({});
  return SharedPreferences.getInstance();
}

ReaderEngine _engine(WidgetTester tester) =>
    tester.widget<ReaderEngineView>(find.byType(ReaderEngineView)).controller;

void main() {
  group('ReaderEngine commands through ReaderContent', () {
    late List<(ReaderChapter, ReaderAnchor)> added;

    Future<void> pumpReader(WidgetTester tester) async {
      added = [];
      final prefs = await _prefs();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            home: ReaderContent(
              feed: _threeChapters(),
              scrollStorageKey: 'k',
              onBack: () {},
              onOpenSeries: () {},
              onAddBookmark: (chapter, anchor) async {
                added.add((chapter, anchor));
                return true;
              },
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    Future<void> finish(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 5));
    }

    testWidgets('seekToPage(7) moves the state to page 7', (tester) async {
      await pumpReader(tester);
      final engine = _engine(tester);
      expect(engine.value.page, 1);
      expect(engine.value.chapterId, '1');
      engine.seekToPage(7);
      await tester.pump();
      expect(engine.value.page, 7);
      expect(engine.value.pageCount, 10);
      expect(engine.value.progress, closeTo(0.6, 0.02));
      await finish(tester);
    });

    testWidgets('toggleAutoScroll flips autoScrolling', (tester) async {
      await pumpReader(tester);
      final engine = _engine(tester);
      expect(engine.value.autoScrolling, isFalse);
      engine.toggleAutoScroll();
      await tester.pump();
      expect(engine.value.autoScrolling, isTrue);
      engine.toggleAutoScroll();
      await tester.pump();
      expect(engine.value.autoScrolling, isFalse);
      await finish(tester);
    });

    testWidgets('zoomIn moves zoom from 1.0 to 1.1', (tester) async {
      await pumpReader(tester);
      final engine = _engine(tester);
      expect(engine.value.zoom, 1.0);
      engine.zoomIn();
      await tester.pump();
      expect(engine.value.zoom, 1.1);
      await finish(tester);
    });

    testWidgets('bookmark() stores and the anchor reaches the state',
        (tester) async {
      await pumpReader(tester);
      final engine = _engine(tester);
      expect(engine.value.bookmarks, isEmpty);
      bool? stored;
      unawaited(engine.bookmark().then((value) => stored = value));
      await tester.pump();
      await tester.pump();
      expect(stored, isTrue);
      expect(added, hasLength(1));
      expect(added.single.$1.id, '1');
      expect(engine.value.bookmarks, [added.single.$2]);
      await finish(tester);
    });

    testWidgets('readerEngineProvider is readable below the view',
        (tester) async {
      await pumpReader(tester);
      final element = tester.element(find.text('Chapter 1').first);
      final container = ProviderScope.containerOf(element);
      expect(container.read(readerEngineProvider), same(_engine(tester)));
      await finish(tester);
    });
  });

  testWidgets(
      'chromeBuilder gets a new state when the page changes, '
      'and is not rebuilt while the state is equal', (tester) async {
    final prefs = await _prefs();
    final engine = ReaderEngine();
    addTearDown(engine.dispose);
    final states = <ReaderEngineState>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          home: Scaffold(
            body: ReaderEngineView(
              controller: engine,
              feed: _threeChapters(),
              scrollStorageKey: 'k',
              onBack: () {},
              onOpenSeries: () {},
              slots: ReaderSurfaceSlots(
                chapterSeam: (_, chapter, __) => Text(chapter.title),
                brokenPage: (_, __) => const SizedBox(),
                pagedCornerRadius: 4,
              ),
              autoHideAfter: const Duration(seconds: 3),
              chromeBuilder: (context, state) {
                states.add(state);
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    final builds = states.length;
    expect(states.last.page, 1);

    // A nudge far below 0.001 of the chapter changes nothing the state says.
    final controller =
        tester.widget<ListView>(find.byType(ListView)).controller!;
    controller.jumpTo(controller.offset + 0.01);
    await tester.pump();
    expect(states.length, builds);

    engine.seekToPage(4);
    await tester.pump();
    expect(states.length, greaterThan(builds));
    expect(states.last.page, 4);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 5));
  });
}
