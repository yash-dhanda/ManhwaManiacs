import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/downloads/models/chapter_identity.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/downloads/providers/series_download_status_provider.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/downloads/store/downloads_store.dart';
import 'package:manhwamaniacs/features/reader/models/reader_chapter.dart';
import 'package:manhwamaniacs/features/reader/models/reader_page.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_download_mark.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/chapter_download_control.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/running_head.dart';

import '../../../screenshots/support/shot_network.dart';
import 'reader_test_support.dart';

final _status = StateProvider<Map<String, ChapterDownloadStatus>>((ref) => const {});
final _active = StateProvider<({String chapterKey, ChapterDownloadProgress progress})?>((ref) => null);
final _pause = StateProvider<DownloadQueuePauseReason>((ref) => DownloadQueuePauseReason.none);

class _Queue extends RecordingQueue {
  _Queue(super.rec);
  final cancelled = <String>[];

  @override
  DownloadQueueState build() => DownloadQueueState(pauseReason: ref.watch(_pause));

  @override
  Future<void> cancelChapter(ChapterIdentity id) async => cancelled.add(id.chapterKey);
}

class _Store implements DownloadsStore {
  final deleted = <String>[];

  @override
  Future<void> deleteDownload(ChapterIdentity id) async => deleted.add(id.chapterKey);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ChapterDownloadStatus _s(DownloadChapterState s) => (state: s, error: null);

Future<({_Queue queue, _Store store, ProviderContainer c})> _pump(WidgetTester tester) async {
  final queue = _Queue(Recorder());
  final store = _Store();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        seriesChapterDownloadStatusProvider.overrideWith((ref, k) async => ref.watch(_status)),
        seriesActiveChapterProgressProvider.overrideWith((ref, k) => ref.watch(_active)),
        downloadQueueControllerProvider.overrideWith(() => queue),
        downloadsStoreProvider.overrideWithValue(store),
      ],
      child: MaterialApp(
        theme: featureTheme(TargetPlatform.android),
        home: const Scaffold(body: Center(child: ChapterDownloadControl(sourceId: 'demo', seriesKey: 'k', chapterKey: 'c2'))),
      ),
    ),
  );
  await tester.pump();
  final c = ProviderScope.containerOf(tester.element(find.byType(ChapterDownloadControl)));
  return (queue: queue, store: store, c: c);
}

Future<void> _set(WidgetTester tester, ProviderContainer c, DownloadChapterState? s, {int done = 0, int total = 0}) async {
  c.read(_status.notifier).state = s == null ? const {} : {'c2': _s(s)};
  c.read(_active.notifier).state = total > 0 ? (chapterKey: 'c2', progress: (pagesDone: done, pageTotal: total)) : null;
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('the mark cycles Download, saving 12/40 with cancel, SAVED, the inline confirm and back', (tester) async {
    final r = await _pump(tester);
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.bySemanticsLabel('Not downloaded'), findsOneWidget);

    // Download: a tap enqueues the chapter.
    await tester.tap(find.byType(CineDownloadMark));
    await tester.pump();
    expect(r.queue.rec.enqueued.single.single.id.chapterKey, 'c2');

    // Saving 12/40 · 30%, and a tap on it cancels.
    await _set(tester, r.c, DownloadChapterState.downloading, done: 12, total: 40);
    expect(find.text('12/40 · 30%'), findsOneWidget);
    await tester.tap(find.byType(CineDownloadMark));
    await tester.pump();
    expect(r.queue.cancelled, ['c2']);

    // SAVED.
    await _set(tester, r.c, DownloadChapterState.complete);
    expect(find.text('SAVED'), findsOneWidget);
    expect(find.text('12/40 · 30%'), findsNothing);

    // Tap: the inline confirm; the Remove arm is dead before 1000 ms and live after.
    await tester.tap(find.byType(CineDownloadMark));
    await tester.pump();
    expect(find.text('Remove from this device?'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Remove'), warnIfMissed: false);
    await tester.pump();
    expect(r.store.deleted, isEmpty, reason: 'not accepted before 1000 ms');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Remove'));
    await tester.pump();
    expect(r.store.deleted, ['c2'], reason: 'accepted after 1000 ms');
    expect(find.text('Remove from this device?'), findsNothing);
  });

  testWidgets('the confirm reverts after 4 s untouched', (tester) async {
    final r = await _pump(tester);
    await _set(tester, r.c, DownloadChapterState.complete);
    await tester.tap(find.byType(CineDownloadMark));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 3900));
    expect(find.text('Remove from this device?'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Remove from this device?'), findsNothing);
    expect(find.text('SAVED'), findsOneWidget);
    expect(r.store.deleted, isEmpty);
  });

  testWidgets('a stale copy reads Save again, an interrupted one Resume 12/40; a tap saves again', (tester) async {
    final r = await _pump(tester);
    await _set(tester, r.c, DownloadChapterState.failed);
    expect(find.text('Save again'), findsOneWidget);
    await tester.tap(find.byType(CineDownloadMark));
    await tester.pump();
    expect(r.queue.rec.enqueued, hasLength(1));
    await _set(tester, r.c, DownloadChapterState.failed, done: 12, total: 40);
    expect(find.text('Resume 12/40'), findsOneWidget);
    expect(find.text('Save again'), findsNothing);
    await tester.tap(find.byType(CineDownloadMark));
    await tester.pump();
    expect(r.queue.rec.enqueued, hasLength(2));
  });

  testWidgets('the running head shows OFFLINE EDITION when told so and not otherwise', (tester) async {
    for (final offline in [true, false]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: featureTheme(TargetPlatform.android),
          home: Scaffold(
            body: ReaderRunningHead(seriesTitle: 'Tower', folio: 'CH 2', onBack: () {}, onOpenSeries: () {}, onOpenContents: () {}, offlineEdition: offline),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('OFFLINE EDITION'), offline ? findsOneWidget : findsNothing);
    }
  });

  testWidgets('the reader running head shows OFFLINE EDITION when the chapter is read from disk', (tester) async {
    setUpShotCoverCache();
    final dir = Directory.systemTemp.createTempSync('mm-offline-reader');
    addTearDown(() => dir.deleteSync(recursive: true));
    // A 1 x 1 PNG.
    final png = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==');
    final files = [for (var n = 1; n <= 3; n++) File('${dir.path}/$n.png')..writeAsBytesSync(png)];
    final local = ReaderChapter(
      id: 'c2',
      seriesId: kReaderSeries,
      title: 'Chapter 2',
      pageCount: 3,
      sourceId: kReaderSource,
      seriesTitle: 'Tower of Dawn',
      pages: [for (var n = 1; n <= 3; n++) ReaderPage(id: 'c2-$n', number: n, imageUrl: '', localFile: files[n - 1], width: 800, height: 2400)],
    );
    await pumpReader(tester, chapters: {'c2': local});
    await settleReader(tester, ms: 600);
    expect(find.text('OFFLINE EDITION'), findsOneWidget);
    await disposeReader(tester);
    await pumpReader(tester);
    await settleReader(tester, ms: 600);
    expect(find.text('OFFLINE EDITION'), findsNothing);
    await disposeReader(tester);
  });
}
