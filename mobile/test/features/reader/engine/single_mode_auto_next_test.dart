import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/engine/neighbour.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_view.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_surface_slots.dart';
import 'package:manhwamaniacs/features/reader/models/reader_chapter.dart';
import 'package:manhwamaniacs/features/reader/models/reader_feed.dart';
import 'package:manhwamaniacs/features/reader/models/reader_page.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

ReaderChapter _chapter(String id) => ReaderChapter(
      id: id,
      seriesId: 's',
      title: 'Chapter $id',
      pageCount: 3,
      pages: [
        for (var n = 1; n <= 3; n++)
          ReaderPage(id: '$id-$n', number: n, imageUrl: 'http://example.test/reader/page/$id-$n/image', width: 800, height: 2400),
      ],
    );

Widget _blank(BuildContext c, [Object? a, Object? b]) => const SizedBox();

/// The engine's legacy end-of-chapter timer (the Cinematic and legacy readers) never runs in one-at-a-time mode, where the
/// Glass skin owns the end of the chapter; the default continuous path is unchanged.
Future<int> _calls(WidgetTester tester, ReaderChapterMode? mode) async {
  tester.view
    ..physicalSize = const Size(390, 844)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final engine = ReaderEngine();
  addTearDown(engine.dispose);
  var calls = 0;
  await tester.pumpWidget(ProviderScope(
    overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
    child: MaterialApp(
      home: ReaderEngineView(
        controller: engine,
        slots: const ReaderSurfaceSlots(chapterSeam: _blank, brokenPage: _blank, pagedCornerRadius: 0),
        autoHideAfter: const Duration(seconds: 30),
        chromeBuilder: (context, state) => const SizedBox.shrink(),
        feed: ReaderFeed.of([_chapter('1')]),
        scrollStorageKey: 'k',
        onBack: () {},
        onOpenSeries: () {},
        onNextChapter: () => calls++,
        chapterMode: mode ?? ReaderChapterMode.continuous,
      ),
    ),
  ),);
  await tester.pump();
  final pos = tester.state<ScrollableState>(find.byType(Scrollable).first).position;
  pos.jumpTo(pos.maxScrollExtent);
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 5));
  return calls;
}

void main() {
  testWidgets('continuous (the default, Cinematic): reaching the end still calls onNextChapter', (tester) async {
    expect(await _calls(tester, null), 1);
  });

  testWidgets('one at a time: the legacy timer stays off', (tester) async {
    expect(await _calls(tester, ReaderChapterMode.single), 0);
  });
}
