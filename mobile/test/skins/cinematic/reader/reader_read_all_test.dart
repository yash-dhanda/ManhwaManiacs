import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_view.dart';
import 'package:manhwamaniacs/features/reader/models/chapter_manifest.dart';
import 'package:manhwamaniacs/features/reader/models/chapter_manifest_window.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_signals_provider.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/read_all_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_states.dart';

import '../../../screenshots/support/shot_network.dart';
import 'reader_test_support.dart';

/// A reader repository whose batch endpoint the test steers.
class BatchReader extends FakeReader {
  BatchReader(super.rec, {this.gate, this.failKeys = const {}});
  final Future<void>? gate;
  final Set<String> failKeys;
  final List<List<String>> asked = [];

  @override
  Future<Result<ChapterManifestWindow>> manifestWindow({required String sourceId, required String seriesKey, required List<String> chapterKeys}) async {
    asked.add(List.of(chapterKeys));
    if (gate != null) await gate;
    ChapterManifest m(String k) => ChapterManifest(
          sourceId: sourceId,
          seriesKey: seriesKey,
          chapterKey: k,
          chapterNumber: null,
          pageCount: 3,
          pages: [for (var n = 1; n <= 3; n++) ManifestPage(number: n, url: '/reader/page/$k-$n/image')],
          prev: null,
          next: null,
        );
    return Ok(ChapterManifestWindow(
      maxChapters: 20,
      manifests: {for (final k in chapterKeys) if (!failKeys.contains(k)) k: m(k)},
      errors: {for (final k in chapterKeys) if (failKeys.contains(k)) k: 'no'},
    ));
  }
}

Set<String> texts(WidgetTester tester) => {
      for (final e in find.byType(RichText).evaluate()) (e.widget as RichText).text.toPlainText().replaceAll('\uFFFC', ''),
    }..remove('');

ProviderContainer container(WidgetTester tester) => ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

void main() {
  setUpAll(setUpShotCoverCache);

  testWidgets('the first chapter shows before any batch returns; the running head adds 1 OF 4', (tester) async {
    final gate = Completer<void>();
    final batch = BatchReader(Recorder(), gate: gate.future);
    await pumpReader(tester, chapterKey: 'c1', origin: ReaderRigOrigin.readAll, extra: [readerRepositoryProvider.overrideWithValue(batch)]);
    await settleReader(tester, ms: 800);
    expect(find.byType(ReadAllScreen), findsOneWidget);
    expect(find.byType(ReaderEngineView), findsOneWidget);
    expect(find.text('CH 1 · 1 OF 4'), findsOneWidget);
    expect(batch.asked, isNotEmpty, reason: 'the window fills in behind it');
    final view = tester.widget<ReaderEngineView>(find.byType(ReaderEngineView));
    expect(view.feed.chapters.map((c) => c.id), ['c1'], reason: 'nothing else has arrived yet');
    gate.complete();
    await settleReader(tester, ms: 500);
    final after = tester.widget<ReaderEngineView>(find.byType(ReaderEngineView));
    expect(after.feed.chapters.map((c) => c.id), ['c1', 'c2', 'c3', 'cx']);
    await disposeReader(tester);
  });

  testWidgets('a failed batch item is a notice in its place and reading continues past it', (tester) async {
    final batch = BatchReader(Recorder(), failKeys: {'c3'});
    await pumpReader(tester, chapterKey: 'c1', origin: ReaderRigOrigin.readAll, extra: [readerRepositoryProvider.overrideWithValue(batch)]);
    await settleReader(tester, ms: 1500);
    final feed = tester.widget<ReaderEngineView>(find.byType(ReaderEngineView)).feed;
    expect(feed.chapters.map((c) => c.id), ['c1', 'c2', 'c3', 'cx'], reason: 'the failed one is in the feed and the chapter after it too');
    // Scroll to the failed chapter.
    final engine = tester.widget<ReaderEngineView>(find.byType(ReaderEngineView)).controller;
    engine.seekToChapter(2);
    await settleReader(tester, ms: 6000);
    expect(texts(tester), containsAll(["Chapter 3 didn't load.", 'Try again', 'Open it on its own →']));
    await disposeReader(tester);
  });

  testWidgets('a 429 on the batch call sets the wait and leaves the strip where it is', (tester) async {
    final rate = _RateLimited(Recorder());
    await pumpReader(tester, chapterKey: 'c1', origin: ReaderRigOrigin.readAll, extra: [readerRepositoryProvider.overrideWithValue(rate)]);
    await settleReader(tester, ms: 1000);
    expect(container(tester).read(readerRateLimitedUntilProvider), isNotNull);
    final feed = tester.widget<ReaderEngineView>(find.byType(ReaderEngineView)).feed;
    expect(feed.chapters.map((c) => c.id), ['c1']);
    await disposeReader(tester);
  });

  testWidgets('the chapter list failing shows the exact notice', (tester) async {
    await pumpReader(
      tester,
      chapterKey: 'c1',
      origin: ReaderRigOrigin.readAll,
      extra: [sourceSeriesDetailProvider.overrideWith((ref, k) async => throw Exception('no list'))],
    );
    await settleReader(tester, ms: 9000);
    expect(texts(tester), containsAll([ReadAllListFailureView.deck, 'Try again', 'Go to the series']));
    expect(find.byType(ReadAllListFailureView), findsOneWidget);
    await disposeReader(tester);
  });

  testWidgets('layout keys are inert in read-all', (tester) async {
    await pumpReader(tester, chapterKey: 'c1', origin: ReaderRigOrigin.readAll, extra: [readerRepositoryProvider.overrideWithValue(BatchReader(Recorder()))]);
    await settleReader(tester, ms: 800);
    for (final k in [LogicalKeyboardKey.keyV, LogicalKeyboardKey.keyR]) {
      await tester.sendKeyEvent(k);
      await settleReader(tester, ms: 500);
      expect(find.byType(ReaderEngineView), findsOneWidget);
    }
    await disposeReader(tester);
  });
}

class _RateLimited extends BatchReader {
  _RateLimited(super.rec);

  @override
  Future<Result<ChapterManifestWindow>> manifestWindow({required String sourceId, required String seriesKey, required List<String> chapterKeys}) async =>
      const Err(ApiError(statusCode: 429, code: 'rate_limited', message: 'slow down', retryAfter: Duration(seconds: 12)));
}
