import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/engine/chapter_end_physics.dart';
import 'package:manhwamaniacs/features/reader/engine/neighbour.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_view.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_surface_slots.dart';
import 'package:manhwamaniacs/features/reader/models/reader_chapter.dart';
import 'package:manhwamaniacs/features/reader/models/reader_feed.dart';
import 'package:manhwamaniacs/features/reader/models/reader_page.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

ReaderChapter _chapter(String id, {int pages = 3}) => ReaderChapter(
      id: id,
      seriesId: 's',
      title: 'Chapter $id',
      pageCount: pages,
      pages: [
        for (var n = 1; n <= pages; n++)
          ReaderPage(id: '$id-$n', number: n, imageUrl: 'http://example.test/reader/page/$id-$n/image', width: 800, height: 2400),
      ],
    );

const _slots = ReaderSurfaceSlots(chapterSeam: _seam, brokenPage: _broken, pagedCornerRadius: 0);
Widget _seam(BuildContext c, ReaderChapter ch, Axis a) => const SizedBox();
Widget _broken(BuildContext c, VoidCallback retry) => const SizedBox();

Future<ReaderEngine> _pump(WidgetTester tester, {ReaderChapterMode mode = ReaderChapterMode.single, void Function(dynamic)? onReplace}) async {
  tester.view
    ..physicalSize = const Size(390, 844)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final engine = ReaderEngine();
  addTearDown(engine.dispose);
  await tester.pumpWidget(ProviderScope(
    overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
    child: MaterialApp(
      home: ReaderEngineView(
        controller: engine,
        slots: _slots,
        autoHideAfter: const Duration(seconds: 30),
        chromeBuilder: (context, state) => const SizedBox.shrink(),
        feed: ReaderFeed.of([_chapter('1')]),
        scrollStorageKey: 'k',
        onBack: () {},
        onOpenSeries: () {},
        chapterMode: mode,
        loadNeighbour: (d) async => _chapter('2'),
        onReplaceChapter: onReplace,
      ),
    ),
  ),);
  await tester.pump();
  await tester.pump();
  return engine;
}

Future<void> _finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 5));
}

ScrollPosition _pos(WidgetTester tester) => tester.state<ScrollableState>(find.byType(Scrollable).first).position;

void main() {
  test('overscrollUserOffset follows the 0.55 band (drag delta: negative scrolls forward)', () {
    // At the end, dragging out 93 px from the edge: displayed 48.2 on 844.
    expect(-overscrollUserOffset(1000, 0, 1000, -93, 844), closeTo(48.2, 0.1));
    // In range: untouched.
    expect(overscrollUserOffset(500, 0, 1000, -30, 844), -30);
    // Already at 48.2 displayed, dragging 51 more raw px reaches 72.4 total.
    const y0 = 48.2;
    expect(y0 - overscrollUserOffset(1000 + y0, 0, 1000, -51, 844), closeTo(72.4, 0.3));
    // Start side mirrors: pixels go negative.
    expect(overscrollUserOffset(0, 0, 1000, 93, 844), closeTo(48.2, 0.1));
    // Back across the edge: the remainder is in range.
    expect(overscrollUserOffset(1010, 0, 1000, 300, 844), greaterThan(10));
  });

  testWidgets('a drag 93 raw px past the end reads 48.2 and arms; 144 reads 72.4 and locks', (tester) async {
    final engine = await _pump(tester);
    final events = <NeighbourEvent>[];
    final sub = engine.neighbourEvents.listen(events.add);
    addTearDown(sub.cancel);
    final pos = _pos(tester);
    pos.jumpTo(pos.maxScrollExtent);
    await tester.pump();
    final g = await tester.startGesture(const Offset(200, 400));
    await g.moveBy(const Offset(0, -19)); // past the touch slop
    await tester.pump();
    await tester.pump();
    await g.moveBy(const Offset(0, -93));
    await tester.pump();
    expect(engine.live.overscrollExtent.value, closeTo(48.2, 1.0));
    expect(events.last.phase, NeighbourPhase.armed);
    await g.moveBy(const Offset(0, -51));
    await tester.pump();
    expect(engine.live.overscrollExtent.value, closeTo(72.4, 1.5));
    expect(events.last.phase, NeighbourPhase.locked);
    // Released at 72: the position holds.
    await g.up();
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(engine.live.overscrollExtent.value, greaterThan(70));
    pos.jumpTo(pos.maxScrollExtent);
    await tester.pump();
    await _finish(tester);
  });

  testWidgets('a release below 72 springs back to 0', (tester) async {
    final engine = await _pump(tester);
    final pos = _pos(tester);
    pos.jumpTo(pos.maxScrollExtent);
    await tester.pump();
    final g = await tester.startGesture(const Offset(200, 400));
    await g.moveBy(const Offset(0, -19));
    await tester.pump();
    await g.moveBy(const Offset(0, -93));
    await tester.pump();
    expect(engine.live.overscrollExtent.value, greaterThan(40));
    await g.up();
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(engine.live.overscrollExtent.value, 0);
    await _finish(tester);
  });

  testWidgets('continuous mode never reports an overscroll', (tester) async {
    final engine = await _pump(tester, mode: ReaderChapterMode.continuous);
    final pos = _pos(tester);
    pos.jumpTo(pos.maxScrollExtent);
    await tester.pump();
    final g = await tester.startGesture(const Offset(200, 400));
    await g.moveBy(const Offset(0, -19));
    await tester.pump();
    await g.moveBy(const Offset(0, -93));
    await tester.pump();
    expect(engine.live.overscrollExtent.value, 0);
    await g.up();
    await tester.pump(const Duration(seconds: 3));
    await _finish(tester);
  });

  testWidgets('armNeighbour resolves the info and commitNeighbour calls onReplaceChapter', (tester) async {
    final replaced = <dynamic>[];
    final engine = await _pump(tester, onReplace: replaced.add);
    final info = await tester.runAsync(() => engine.armNeighbour(NeighbourDirection.next));
    expect(info!.pageCount, 3);
    expect(info.minutes, 1);
    expect(info.chapter.chapterKey, '2');
    engine.commitNeighbour(NeighbourDirection.next);
    expect(replaced, hasLength(1));
    await _finish(tester);
  });
}
