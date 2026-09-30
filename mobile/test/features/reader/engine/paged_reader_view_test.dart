import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/engine/page_turn.dart';
import 'package:manhwamaniacs/features/reader/engine/paged_reader_view.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_options.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_layout.dart';
import 'package:manhwamaniacs/features/reader/models/reader_chapter.dart';
import 'package:manhwamaniacs/features/reader/models/reader_page.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

ReaderChapter chapter({int pages = 6, Set<int> wide = const {}}) => ReaderChapter(
      id: 'c1',
      seriesId: 's',
      sourceId: 'demo',
      title: 'Chapter 1',
      pageCount: pages,
      pages: [
        for (var n = 1; n <= pages; n++)
          ReaderPage(id: 'c1-$n', number: n, imageUrl: 'http://example.test/p/$n', width: wide.contains(n) ? 1600 : 800, height: 1200),
      ],
    );

class Rig {
  Rig(this.engine);
  final ReaderEngine engine;
  final ValueNotifier<ReaderLayoutSpec> spec = ValueNotifier(const ReaderLayoutSpec(layout: ReaderLayout.single));
  int nextCalls = 0;
  List<Offset> taps = [];
  List<(String, int)> longPresses = [];
}

Future<Rig> pump(
  WidgetTester tester, {
  ReaderLayoutSpec spec = const ReaderLayoutSpec(layout: ReaderLayout.single),
  ReaderChapter? ch,
  bool reduced = false,
  PageTurn turn = PageTurn.cut,
  bool withNext = true,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final rig = Rig(ReaderEngine());
  rig.spec.value = spec;
  addTearDown(rig.engine.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        home: ValueListenableBuilder<ReaderLayoutSpec>(
          valueListenable: rig.spec,
          builder: (context, s, _) => PagedReaderView(
            controller: rig.engine,
            chapter: ch ?? chapter(),
            spec: s,
            turn: turn,
            reducedMotion: reduced,
            autoHideAfter: const Duration(days: 1),
            chromeBuilder: (context, state) => const SizedBox.shrink(),
            onNextChapter: withNext ? () => rig.nextCalls++ : null,
            options: ReaderEngineOptions(
              tapSlop: 8,
              pinch: true,
              tapHandler: (i) => rig.taps.add(i.position),
              onPageLongPress: (c, p) => rig.longPresses.add((c, p)),
              creditsBuilder: (context, chapter, next, mode) => const SizedBox(height: 100, child: Text('CREDITS')),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return rig;
}

const _turn = (slideDuration: Duration(milliseconds: 280), slideCurve: Curves.linear, fadeDuration: Duration(milliseconds: 160));

void turnTo(ReaderEngine e, int page, {PageTurn kind = PageTurn.cut}) =>
    e.turnTo(page, kind: kind, slideDuration: _turn.slideDuration, slideCurve: _turn.slideCurve, fadeDuration: _turn.fadeDuration);

void main() {
  testWidgets('single: state, cut, slide and fade turns', (tester) async {
    final r = await pump(tester);
    expect(r.engine.value.page, 1);
    expect(r.engine.value.pageCount, 6);
    turnTo(r.engine, 3);
    await tester.pump();
    expect(r.engine.value.page, 3);
    turnTo(r.engine, 5, kind: PageTurn.slide);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 140));
    expect(r.engine.value.page, lessThan(5));
    await tester.pumpAndSettle();
    expect(r.engine.value.page, 5);
    turnTo(r.engine, 2, kind: PageTurn.fade);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(r.engine.value.page, 2);
  });

  testWidgets('a fling turns, a slow short drag returns (stock physics; the skin passes its own)', (tester) async {
    final r = await pump(tester);
    final g = await tester.startGesture(const Offset(200, 400));
    await g.moveBy(const Offset(-30, 0));
    await tester.pump(const Duration(milliseconds: 300));
    await g.moveBy(const Offset(-30, 0));
    await tester.pump(const Duration(milliseconds: 300));
    await g.up();
    await tester.pumpAndSettle();
    expect(r.engine.value.page, 1);
    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1200);
    await tester.pumpAndSettle();
    expect(r.engine.value.page, 2);
  });

  testWidgets('rtl: swiping right goes forward', (tester) async {
    final r = await pump(tester, spec: const ReaderLayoutSpec(layout: ReaderLayout.single, rtl: true));
    await tester.fling(find.byType(PageView), const Offset(300, 0), 1200);
    await tester.pumpAndSettle();
    expect(r.engine.value.page, 2);
  });

  testWidgets('a swipe that starts on the screen edge is ignored', (tester) async {
    final r = await pump(tester);
    await tester.flingFrom(const Offset(4, 400), const Offset(-300, 0), 1200);
    await tester.pumpAndSettle();
    expect(r.engine.value.page, 1);
  });

  testWidgets('double: cover alone, then spreads; one turn steps a whole spread', (tester) async {
    final r = await pump(tester, spec: const ReaderLayoutSpec(layout: ReaderLayout.double), ch: chapter(pages: 7));
    expect(r.engine.value.page, 1);
    r.engine.pageBy(forward: true);
    await tester.pump();
    expect(r.engine.value.page, 2);
    r.engine.pageBy(forward: true);
    await tester.pump();
    expect(r.engine.value.page, 4);
    r.engine.pageBy(forward: false);
    await tester.pump();
    expect(r.engine.value.page, 2);
  });

  testWidgets('double: a wide page is alone', (tester) async {
    final r = await pump(tester, spec: const ReaderLayoutSpec(layout: ReaderLayout.double), ch: chapter(wide: {3}));
    // views: [1] [2] [3] [4,5] [6]
    r.engine.pageBy(forward: true);
    await tester.pump();
    r.engine.pageBy(forward: true);
    await tester.pump();
    expect(r.engine.value.page, 3);
    r.engine.pageBy(forward: true);
    await tester.pump();
    expect(r.engine.value.page, 4);
  });

  testWidgets('switching layout keeps the page', (tester) async {
    final r = await pump(tester);
    turnTo(r.engine, 5);
    await tester.pump();
    r.spec.value = const ReaderLayoutSpec(layout: ReaderLayout.double);
    await tester.pumpAndSettle();
    expect(r.engine.value.page, 4); // 5 sits in the [4,5] spread
    r.spec.value = const ReaderLayoutSpec(layout: ReaderLayout.single);
    await tester.pumpAndSettle();
    expect(r.engine.value.page, 4);
  });

  testWidgets('end: credits after the last page, then the next chapter', (tester) async {
    final r = await pump(tester);
    turnTo(r.engine, 6);
    await tester.pump();
    expect(r.engine.value.atEnd, isFalse);
    r.engine.pageBy(forward: true);
    await tester.pumpAndSettle();
    expect(find.text('CREDITS'), findsOneWidget);
    expect(r.engine.value.atEnd, isTrue);
    expect(r.nextCalls, 0);
    r.engine.pageBy(forward: true);
    await tester.pumpAndSettle();
    expect(r.nextCalls, 1);
  });

  testWidgets('no next chapter: credits are the last screen', (tester) async {
    final r = await pump(tester, withNext: false);
    turnTo(r.engine, 6);
    await tester.pump();
    r.engine.pageBy(forward: true);
    await tester.pumpAndSettle();
    r.engine.pageBy(forward: true);
    await tester.pumpAndSettle();
    expect(r.nextCalls, 0);
    expect(find.text('CREDITS'), findsOneWidget);
  });

  testWidgets('zoom: pinchZoom clamps to 1..3 and a drag pans instead of turning', (tester) async {
    final r = await pump(tester);
    r.engine.pinchZoom(const Offset(195, 422), 2.5, 0, min: 1, max: 3);
    await tester.pump();
    expect(r.engine.value.zoom, 2.5);
    r.engine.pinchZoom(const Offset(195, 422), 9, 0, min: 1, max: 3);
    await tester.pump();
    expect(r.engine.value.zoom, 3);
    await tester.flingFrom(const Offset(200, 400), const Offset(-200, 0), 1500);
    await tester.pumpAndSettle();
    expect(r.engine.value.page, 1);
    r.engine.resetZoom();
    await tester.pump();
    expect(r.engine.value.zoom, 1);
  });

  testWidgets('zoom resets when the page turns', (tester) async {
    final r = await pump(tester);
    r.engine.pinchZoom(const Offset(195, 422), 2, 0, min: 1, max: 3);
    await tester.pump();
    turnTo(r.engine, 2);
    await tester.pump();
    expect(r.engine.value.zoom, 1);
  });

  testWidgets('taps reach the skin handler; a long press reports the page', (tester) async {
    final r = await pump(tester);
    await tester.tapAt(const Offset(200, 400));
    await tester.pump();
    expect(r.taps, hasLength(1));
    await tester.longPressAt(const Offset(200, 400));
    await tester.pump();
    expect(r.longPresses, [('c1', 1)]);
  });

  testWidgets('reduced motion: every turn is a fade, a swipe is a fade too', (tester) async {
    final r = await pump(tester, reduced: true);
    turnTo(r.engine, 4, kind: PageTurn.slide);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    await tester.pumpAndSettle();
    expect(r.engine.value.page, 4);
    await tester.flingFrom(const Offset(300, 400), const Offset(-200, 0), 1200);
    await tester.pumpAndSettle();
    expect(r.engine.value.page, 5);
  });

  testWidgets('pageAtReadingLine is the current page in a paged layout', (tester) async {
    final r = await pump(tester);
    turnTo(r.engine, 4);
    await tester.pump();
    expect(r.engine.pageAtReadingLine(), 4);
  });
}
