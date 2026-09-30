
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/engine/cruise_engage.dart';
import 'package:manhwamaniacs/features/reader/engine/lens_layout.dart';
import 'package:manhwamaniacs/features/reader/engine/page_sample.dart';
import 'package:manhwamaniacs/features/reader/engine/page_sampler.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_view.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_page_image.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_surface_slots.dart';
import 'package:manhwamaniacs/features/reader/engine/seam.dart';
import 'package:manhwamaniacs/features/reader/models/reader_chapter.dart';
import 'package:manhwamaniacs/features/reader/models/reader_feed.dart';
import 'package:manhwamaniacs/features/reader/models/reader_page.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

ReaderChapter _chapter(String id, {int pages = 6}) => ReaderChapter(
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

Future<ReaderEngine> _pump(WidgetTester tester, ReaderFeed feed) async {
  tester.view
    ..physicalSize = const Size(390, 844)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final engine = ReaderEngine(sampleDecoder: (_) async => null);
  addTearDown(engine.dispose);
  await tester.pumpWidget(ProviderScope(
    overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
    child: MaterialApp(
      home: ReaderEngineView(
        controller: engine,
        slots: _slots,
        autoHideAfter: const Duration(seconds: 600),
        chromeBuilder: (context, state) => const SizedBox.shrink(),
        feed: feed,
        scrollStorageKey: 'k',
        onBack: () {},
        onOpenSeries: () {},
      ),
    ),
  ),);
  await tester.pump();
  await tester.pump();
  return engine;
}

ScrollPosition _pos(WidgetTester tester) => tester.state<ScrollableState>(find.byType(Scrollable).first).position;

PageSample _s({Color? tint, double pTop = 1}) => PageSample(
      tint: tint, top: Colors.black, bottom: Colors.black, lTop: 0, lMid: 0, lBottom: 0, pTop: pTop, pMid: 0, pBottom: 0, source: PageSampleSource.decode,
    );

void main() {
  group('PageSampler', () {
    test('manifest tint paints first, the decode replaces it, cached pages do not decode again', () async {
      final got = <PageSample>[];
      var decodes = 0;
      final s = PageSampler(onSample: got.add, decoder: (_) async {
        decodes++;
        return _s(tint: const Color(0xFFE53935));
      },);
      addTearDown(s.dispose);
      const p = NetworkImage('http://example.test/a');
      s.onScroll('a', p, '#00FF00', 0);
      expect(got.single.source, PageSampleSource.manifest);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(got.last.source, PageSampleSource.decode);
      expect(decodes, 1);
      s.onScroll('b', p, null, 0);
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(decodes, 2); // b settled and decoded
      s.onScroll('a', p, '#00FF00', 0);
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(decodes, 2); // a came from the cache
    });

    test('holds above 3000 px/s and publishes the latest when it falls below', () async {
      final got = <PageSample>[];
      final s = PageSampler(onSample: got.add, decoder: (_) async => _s(pTop: 0.5));
      addTearDown(s.dispose);
      s.onScroll('a', const NetworkImage('http://example.test/a'), '#112233', 3500);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(got, isEmpty);
      s.setVelocity(2900);
      expect(got.single.pTop, 0.5);
    });

    test('at most one decode per 600 ms while scrolling', () async {
      var decodes = 0;
      final s = PageSampler(onSample: (_) {}, decoder: (_) async {
        decodes++;
        return _s();
      },);
      addTearDown(s.dispose);
      for (var i = 0; i < 20; i++) {
        s.onScroll('k$i', const NetworkImage('http://example.test/a'), null, 500);
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      expect(decodes, 1);
    });
  });

  testWidgets('a fling that slows to 15-240 px/s engages cruise', (tester) async {
    final engine = await _pump(tester, ReaderFeed.of([_chapter('1', pages: 40)]));
    final engaged = <CruiseEngaged>[];
    addTearDown(engine.cruiseEngagedEvents.listen(engaged.add).cancel);
    await tester.fling(find.byType(Scrollable).first, const Offset(0, -300), 2500);
    engine.engageFromVelocity();
    for (var i = 0; i < 400 && engaged.isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(engaged, isNotEmpty);
    expect(engaged.first.pxPerSecond, inInclusiveRange(15, 240));
    expect(engageSpeed(engaged.first.pxPerSecond), isNotNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('crossing a seam raises a reading-line event and a live seam progress', (tester) async {
    final engine = await _pump(tester, ReaderFeed.of([_chapter('1', pages: 2), _chapter('2', pages: 2)]));
    final events = <SeamEvent>[];
    addTearDown(engine.seamEvents.listen(events.add).cancel);
    final pos = _pos(tester);
    const seamTop = 16 + 2 * 1170.0; // list padding plus two pages of 390 / (800/2400)
    pos.jumpTo(seamTop - 600);
    await tester.pump();
    expect(engine.live.seamProgress.value, isNotNull);
    pos.jumpTo(seamTop + 200);
    await tester.pump();
    expect(events.any((e) => e.kind == SeamEventKind.readingLine), isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('the lens layer draws copies of the pages under its clip, removed by null', (tester) async {
    final engine = await _pump(tester, ReaderFeed.of([_chapter('1')]));
    final before = find.byType(ReaderPageImage).evaluate().length;
    engine.pageLayerTransform(const LensTransform(1.12, Offset(195, 300)), const LensClip(Rect.fromLTWH(95, 200, 200, 200), 24));
    await tester.pump();
    expect(find.byType(ReaderPageImage).evaluate().length, greaterThan(before));
    engine.pageLayerTransform(null, null);
    await tester.pump();
    expect(find.byType(ReaderPageImage).evaluate().length, before);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 5));
  });
}
