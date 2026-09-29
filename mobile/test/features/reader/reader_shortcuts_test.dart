import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_view.dart';
import 'package:manhwamaniacs/features/reader/models/reader_chapter.dart';
import 'package:manhwamaniacs/features/reader/models/reader_feed.dart';
import 'package:manhwamaniacs/features/reader/models/reader_page.dart';
import 'package:manhwamaniacs/features/reader/widgets/reader_content.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

ReaderChapter _chapter(String id) => ReaderChapter(
      id: id,
      seriesId: 's',
      title: 'Chapter $id',
      pageCount: 10,
      pages: [
        for (var n = 1; n <= 10; n++)
          ReaderPage(
            id: '$id-$n',
            number: n,
            imageUrl: 'http://example.test/reader/page/$id-$n/image',
            width: 800,
            height: 2400,
          ),
      ],
    );

void main() {
  testWidgets('hardware keys H, L, B, =, -, 0 drive the reader',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var previous = 0;
    var next = 0;
    var bookmarks = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          home: ReaderContent(
            feed: ReaderFeed.of([_chapter('1'), _chapter('2'), _chapter('3')]),
            scrollStorageKey: 'k',
            onBack: () {},
            onOpenSeries: () {},
            onPreviousChapter: () => previous++,
            onNextChapter: () => next++,
            onAddBookmark: (_, __) async {
              bookmarks++;
              return true;
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final ReaderEngine engine =
        tester.widget<ReaderEngineView>(find.byType(ReaderEngineView)).controller;

    await tester.sendKeyEvent(LogicalKeyboardKey.keyH);
    await tester.pump();
    expect(previous, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyL);
    await tester.pump();
    expect(next, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
    await tester.pump();
    await tester.pump();
    expect(bookmarks, 1);

    expect(engine.value.zoom, 1.0);
    await tester.sendKeyEvent(LogicalKeyboardKey.equal);
    await tester.pump();
    expect(engine.value.zoom, 1.1);

    await tester.sendKeyEvent(LogicalKeyboardKey.minus);
    await tester.pump();
    expect(engine.value.zoom, 1.0);

    await tester.sendKeyEvent(LogicalKeyboardKey.equal);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.digit0);
    await tester.pump();
    expect(engine.value.zoom, 1.0);

    expect(previous, 1);
    expect(next, 1);
    expect(bookmarks, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 5));
  });
}
