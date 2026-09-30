
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_options.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_state.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_view.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_surface_slots.dart';
import 'package:manhwamaniacs/features/reader/engine/tap_classifier.dart';
import 'package:manhwamaniacs/features/reader/models/reader_chapter.dart';
import 'package:manhwamaniacs/features/reader/models/reader_feed.dart';
import 'package:manhwamaniacs/features/reader/models/reader_page.dart';
import 'package:manhwamaniacs/features/reader/utils/auto_scroll_speed.dart';
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

const _slots = ReaderSurfaceSlots(
  chapterSeam: _seam,
  brokenPage: _broken,
  pagedCornerRadius: 0,
);
Widget _seam(BuildContext c, ReaderChapter ch, Axis a) => const SizedBox();
Widget _broken(BuildContext c, VoidCallback retry) => const SizedBox();

Future<ReaderEngine> _pump(
  WidgetTester tester, {
  ReaderFeed? feed,
  ReaderEngineOptions options = const ReaderEngineOptions(),
  Size size = const Size(390, 844),
  VoidCallback? onPrevious,
  ValueChanged<ReaderEngineEvent>? onEvent,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final engine = ReaderEngine();
  addTearDown(engine.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        home: ReaderEngineView(
          controller: engine,
          slots: _slots,
          autoHideAfter: const Duration(seconds: 30),
          chromeBuilder: (context, state) => const SizedBox.shrink(),
          feed: feed ?? ReaderFeed.of([_chapter('1')]),
          scrollStorageKey: 'k',
          onBack: () {},
          onOpenSeries: () {},
          onPreviousChapter: onPrevious,
          options: options,
          onEvent: onEvent,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return engine;
}

Future<void> _finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 5));
}

double _offset(WidgetTester tester) => tester.state<ScrollableState>(find.byType(Scrollable).first).position.pixels;

void main() {
  testWidgets('pageStateBuilder is called with the page and the placeholder status', (tester) async {
    final calls = <(int, PageStatus)>[];
    await _pump(
      tester,
      options: ReaderEngineOptions(
        pageStateBuilder: (context, page, status, reason, retry) {
          calls.add((page, status));
          return const SizedBox();
        },
      ),
    );
    expect(calls.map((c) => c.$1), containsAll([1, 2]));
    expect(calls.where((c) => c.$2 == PageStatus.placeholder), isNotEmpty);
    await _finish(tester);
  });

  testWidgets('bandBuilder gets the seam with both chapter titles', (tester) async {
    final seen = <(BandKind, String?, String?)>[];
    final engine = await _pump(
      tester,
      feed: ReaderFeed.of([_chapter('1', pages: 4), _chapter('2')]),
      options: ReaderEngineOptions(
        seamExtent: 128,
        bandBuilder: (context, kind, {from, to, retryIn}) {
          seen.add((kind, from, to));
          return const SizedBox();
        },
      ),
    );
    engine.seekToPage(4);
    await tester.pump();
    await tester.pump();
    expect(seen, contains((BandKind.seam, 'Chapter 1', 'Chapter 2')));
    await _finish(tester);
  });

  testWidgets('a previous chapter reserves the top band, loading state included', (tester) async {
    final kinds = <BandKind>[];
    await _pump(
      tester,
      onPrevious: () {},
      options: ReaderEngineOptions(
        topBandExtent: 96,
        bandBuilder: (context, kind, {from, to, retryIn}) {
          kinds.add(kind);
          return const SizedBox();
        },
      ),
    );
    expect(kinds, contains(BandKind.top));
    await _finish(tester);
  });

  testWidgets('creditsBuilder is placed after the last page with the mode and the chapter', (tester) async {
    final calls = <(String, String?, CreditsMode)>[];
    final engine = await _pump(
      tester,
      options: ReaderEngineOptions(
        footerExtent: 400,
        creditsMode: CreditsMode.full,
        creditsBuilder: (context, chapter, next, mode) {
          calls.add((chapter.id, next, mode));
          return const SizedBox(key: Key('credits'), height: 100);
        },
      ),
    );
    engine.seekToPage(3);
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('credits'), skipOffstage: false), findsOneWidget);
    expect(calls.first, ('1', null, CreditsMode.full));
    await _finish(tester);
  });

  testWidgets('the offline end reaches the band slot when nothing follows', (tester) async {
    final kinds = <BandKind>[];
    final engine = await _pump(
      tester,
      options: ReaderEngineOptions(
        footerExtent: 200,
        offline: true,
        bandBuilder: (context, kind, {from, to, retryIn}) {
          kinds.add(kind);
          return const SizedBox();
        },
      ),
    );
    engine.seekToPage(3);
    await tester.pump();
    await tester.pump();
    expect(kinds, contains(BandKind.offlineEnd));
    await _finish(tester);
  });

  testWidgets('the tap handler gets single then double taps, with the skin slop and window', (tester) async {
    final kinds = <TapKind>[];
    await _pump(
      tester,
      options: ReaderEngineOptions(
        tapSlop: 8,
        doubleTapWindow: const Duration(milliseconds: 300),
        doubleTapSlop: 24,
        tapHandler: (info) => kinds.add(info.kind),
      ),
    );
    await tester.tapAt(const Offset(200, 400));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tapAt(const Offset(210, 405));
    await tester.pump(const Duration(seconds: 1));
    expect(kinds, [TapKind.single, TapKind.double]);
    // A press that drifts past 8 px is no tap.
    final g = await tester.startGesture(const Offset(200, 400));
    await g.moveBy(const Offset(0, -3));
    await g.moveBy(const Offset(0, -12));
    await g.up();
    await tester.pump(const Duration(seconds: 1));
    expect(kinds, hasLength(2));
    await _finish(tester);
  });

  testWidgets('a two-finger pinch changes zoom; a one-finger drag scrolls without changing it', (tester) async {
    final engine = await _pump(tester, options: const ReaderEngineOptions(pinch: true));
    final before = _offset(tester);
    await tester.dragFrom(const Offset(200, 500), const Offset(0, -200));
    await tester.pump(const Duration(milliseconds: 500));
    expect(engine.value.zoom, 1.0);
    expect(_offset(tester), greaterThan(before + 100));

    final a = await tester.startGesture(const Offset(150, 400), pointer: 1);
    final b = await tester.startGesture(const Offset(250, 400), pointer: 2);
    await tester.pump();
    await a.moveTo(const Offset(100, 400));
    await b.moveTo(const Offset(300, 400));
    await tester.pump();
    expect(engine.value.zoom, closeTo(2.0, 0.05));
    await a.up();
    await b.up();
    await tester.pump(const Duration(milliseconds: 400));
    expect(engine.value.zoom, 2.0);
    await _finish(tester);
  });

  testWidgets('zoomAt animates to the level and keeps the point under the finger', (tester) async {
    final engine = await _pump(tester, options: const ReaderEngineOptions(pinch: true));
    await tester.dragFrom(const Offset(200, 500), const Offset(0, -300));
    await tester.pump(const Duration(milliseconds: 500));
    final offset = _offset(tester);
    const focal = Offset(195, 300);
    engine.zoomAt(focal, 2.0, duration: const Duration(milliseconds: 240), curve: Curves.linear);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(engine.value.zoom, 2.0);
    // (offset + fy) * 2 - fy, before the list's clamp.
    expect(_offset(tester), closeTo((offset + focal.dy) * 2 - focal.dy, 60));
    await _finish(tester);
  });

  testWidgets('chapterCompleted fires once when the last page passes 60 % of the viewport', (tester) async {
    final engine = await _pump(tester);
    final done = <ChapterRef>[];
    // The subscription is left open: cancelling a broadcast subscription under FakeAsync spins the binding.
    engine.chapterCompleted.listen(done.add);
    engine.seekToPage(2);
    await tester.pump();
    await tester.pump();
    expect(done, isEmpty);
    await tester.dragFrom(const Offset(200, 600), const Offset(0, -900));
    await tester.pump(const Duration(seconds: 2));
    await tester.dragFrom(const Offset(200, 600), const Offset(0, -900));
    await tester.pump(const Duration(seconds: 2));
    expect(done.map((c) => c.chapterKey), ['1']);
    await _finish(tester);
  });

  testWidgets('the ruler dragged to the last page completes the chapter', (tester) async {
    final engine = await _pump(tester, options: const ReaderEngineOptions(autoHide: ReaderAutoHide()));
    final done = <ChapterRef>[];
    // The subscription is left open: cancelling a broadcast subscription under FakeAsync spins the binding.
    engine.chapterCompleted.listen(done.add);
    engine.jumpToPage(3);
    await tester.pump();
    expect(done.map((c) => c.chapterKey), ['1']);
    await _finish(tester);
  });

  testWidgets('furtherElsewhere carries the server row until an advancing save clears it', (tester) async {
    final engine = await _pump(tester);
    expect(engine.value.furtherElsewhere, isNull);
    engine.reportServerProgress(chapterKey: '145', chapterNumber: 145, lastPage: 3, advanced: false);
    await tester.pump();
    expect(engine.value.furtherElsewhere, const FurtherElsewhere(chapterKey: '145', chapterNumber: 145, lastPage: 3));
    engine.reportServerProgress(chapterKey: '1', chapterNumber: 1, lastPage: 2, advanced: true);
    await tester.pump();
    expect(engine.value.furtherElsewhere, isNull);
    await _finish(tester);
  });

  testWidgets('setAutoScrollSpeedX converts with the viewport height', (tester) async {
    final engine = await _pump(tester);
    engine.setAutoScrollSpeedX(1.5);
    await tester.pump();
    expect(engine.value.autoScrollSpeed, closeTo(autoScrollPxPerSecondX(1.5, 844), 1e-9));
    await _finish(tester);
  });

  testWidgets('the tablet column narrows the strip and the ground shows either side', (tester) async {
    await _pump(
      tester,
      size: const Size(834, 1194),
      options: const ReaderEngineOptions(columnWidth: 720, ground: Color(0xFF0B0B0A)),
    );
    final list = tester.getSize(find.byType(ListView));
    expect(list.width, 720);
    expect(tester.getTopLeft(find.byType(ListView)).dx, closeTo((834 - 720) / 2, 0.5));
    await _finish(tester);
  });

  testWidgets('auto-hide: 24 px forward hides, 56 px back shows, never inside the grace', (tester) async {
    final engine = await _pump(
      tester,
      feed: ReaderFeed.of([_chapter('1', pages: 10)]),
      options: const ReaderEngineOptions(autoHide: ReaderAutoHide(grace: Duration.zero)),
    );
    expect(engine.value.chromeVisible, isTrue);
    await tester.dragFrom(const Offset(200, 700), const Offset(0, -60));
    await tester.pump(const Duration(milliseconds: 600));
    expect(engine.value.chromeVisible, isFalse);
    await tester.dragFrom(const Offset(200, 700), const Offset(0, -500));
    await tester.pump(const Duration(seconds: 2));
    await tester.dragFrom(const Offset(200, 300), const Offset(0, 40));
    await tester.pump(const Duration(milliseconds: 600));
    expect(engine.value.chromeVisible, isFalse, reason: '40 px back, less than 56 after the slop');
    await tester.dragFrom(const Offset(200, 300), const Offset(0, 200));
    await tester.pump(const Duration(milliseconds: 600));
    expect(engine.value.chromeVisible, isTrue);
    await _finish(tester);

    final graced = await _pump(
      tester,
      feed: ReaderFeed.of([_chapter('1', pages: 10)]),
      options: const ReaderEngineOptions(autoHide: ReaderAutoHide()),
    );
    await tester.dragFrom(const Offset(200, 700), const Offset(0, -60));
    await tester.pump(const Duration(milliseconds: 300));
    expect(graced.value.chromeVisible, isTrue, reason: 'inside the first 800 ms');
    await _finish(tester);
  });
}
