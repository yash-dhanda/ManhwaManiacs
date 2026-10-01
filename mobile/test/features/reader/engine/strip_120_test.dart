import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_view.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_page_image.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_surface_slots.dart';
import 'package:manhwamaniacs/features/reader/models/reader_chapter.dart';
import 'package:manhwamaniacs/features/reader/models/reader_feed.dart';
import 'package:manhwamaniacs/features/reader/models/reader_page.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _slots = ReaderSurfaceSlots(chapterSeam: _seam, brokenPage: _broken, pagedCornerRadius: 0);
Widget _seam(BuildContext c, ReaderChapter ch, Axis a) => const SizedBox();
Widget _broken(BuildContext c, VoidCallback retry) => const SizedBox();

void main() {
  testWidgets('120 pages of 720 x 2880 scroll end to end at 6000 px/s', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final engine = ReaderEngine(sampleDecoder: (_) async => null);
    addTearDown(engine.dispose);
    // The sampler's 600 ms throttle must run on the test's fake time; wall-clock time made the request bound flaky.
    engine.sampler.clock = tester.binding.clock.now;
    final chapter = ReaderChapter(
      id: 'long',
      seriesId: 's',
      title: 'Long',
      pageCount: 120,
      pages: [
        for (var n = 1; n <= 120; n++)
          ReaderPage(id: 'l-$n', number: n, imageUrl: 'http://example.test/reader/page/l-$n/image', width: 720, height: 2880),
      ],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        home: ReaderEngineView(
          controller: engine,
          slots: _slots,
          autoHideAfter: const Duration(seconds: 600),
          chromeBuilder: (context, state) => const SizedBox.shrink(),
          feed: ReaderFeed.of([chapter]),
          scrollStorageKey: 'k',
          onBack: () {},
          onOpenSeries: () {},
        ),
      ),
    ),);
    await tester.pump();
    await tester.pump();
    final pos = tester.state<ScrollableState>(find.byType(Scrollable).first).position;
    final max = pos.maxScrollExtent;
    expect(max, greaterThan(180000));
    final seconds = max / 6000;
    unawaited(pos.animateTo(max, duration: Duration(microseconds: (seconds * 1e6).round()), curve: Curves.linear));
    var mounted = 0;
    var vMin = double.infinity, vMax = 0.0;
    final frames = (seconds * 1000 / 8.33).ceil();
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(microseconds: 8330));
      if (i % 20 == 0) {
        mounted = math.max(mounted, find.byType(ReaderPageImage).evaluate().length);
        if (i > 60 && i < frames - 60) {
          final v = engine.live.scrollVelocity.value;
          vMin = math.min(vMin, v);
          vMax = math.max(vMax, v);
        }
      }
    }
    expect(mounted, lessThanOrEqualTo(12));
    expect(vMin, closeTo(6000, 60));
    expect(vMax, closeTo(6000, 60));
    await tester.pump(const Duration(milliseconds: 300));
    expect(engine.live.scrollVelocity.value, 0);
    final elapsedMs = frames * 8.33;
    // One decode at the start and one per 600 ms window (the last window's trailing decode lands just after the scroll ends), plus
    // the settle. The fixture decoder returns null, so nothing is cached and the settle decodes again.
    expect(engine.sampler.requests, lessThanOrEqualTo((elapsedMs / 600).ceil() + 2));
    final dir = Platform.environment['MM_PROOF_DIR'];
    if (dir != null) {
      File('$dir/strip-120.json').writeAsStringSync(const JsonEncoder.withIndent('  ').convert({
        'pages': 120,
        'pageSize': '720x2880',
        'viewport': '390x844',
        'maxScrollExtent': max,
        'frames': frames,
        'frameMs': 8.33,
        'maxMountedPageImages': mounted,
        'velocityMin': vMin,
        'velocityMax': vMax,
        'sampleRequests': engine.sampler.requests,
        'scrollMs': elapsedMs.round(),
        'sampleRequestsBound': (elapsedMs / 600).ceil() + 2,
      }),);
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 5));
  });
}

void unawaited(Future<void> f) {}
