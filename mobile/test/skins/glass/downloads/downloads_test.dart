import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/platform/media_store.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode.dart';
import 'package:manhwamaniacs/features/downloads/models/chapter_identity.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/models/downloaded_series_group.dart';
import 'package:manhwamaniacs/features/downloads/models/saved_chapter.dart';
import 'package:manhwamaniacs/features/downloads/models/storage_cap.dart';
import 'package:manhwamaniacs/features/downloads/providers/active_download_queue_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloaded_series_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart' show downloadsStoreProvider;
import 'package:manhwamaniacs/features/downloads/providers/downloads_storage_providers.dart';
import 'package:manhwamaniacs/features/downloads/providers/storage_settings_provider.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/downloads/services/chapter_export.dart';
import 'package:manhwamaniacs/features/downloads/store/downloads_store.dart';
import 'package:manhwamaniacs/features/downloads/utils/active_download_count.dart';
import 'package:manhwamaniacs/features/downloads/utils/queue_summary.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/reorder_list.dart';
import 'package:manhwamaniacs/skins/glass/screens/downloads/queue_tab.dart';
import 'package:manhwamaniacs/skins/glass/screens/downloads/series_downloads_card.dart';

import '../../../screenshots/support/shot_harness.dart';
import '../library/library_rig.dart';

const _mb = 1024 * 1024;

SavedChapter chapter(int row, {String series = 'series-1', String title = 'Solo Leveling', DownloadChapterState state = DownloadChapterState.complete, int bytes = 40 * _mb, bool mature = false}) => SavedChapter(
      rowId: row,
      scopeId: 'u1p1',
      sourceId: 'shelf',
      seriesKey: series,
      chapterKey: 'c$row',
      chapterNumber: row.toDouble(),
      title: null,
      seriesTitle: title,
      pageCount: 40,
      bytes: bytes,
      state: state,
      pinned: false,
      readAt: null,
      createdAt: DateTime(2026, 9),
      retryCount: 0,
      error: null,
      mature: mature,
    );

DownloadedSeriesGroup savedSeries(String key, String title, int n) =>
    DownloadedSeriesGroup(sourceId: 'shelf', seriesKey: key, seriesTitle: title, chapters: [for (var i = 1; i <= n; i++) chapter(i, series: key, title: title)]);

class _Cap10 extends StorageCapNotifier {
  @override
  StorageCap build() => StorageCap.gb10;
}

class _RecQueue extends DownloadQueueController {
  final List<String> moves = [];
  @override
  Future<void> moveInQueue(ChapterIdentity id, int newIndex) async => moves.add('${id.chapterKey}->$newIndex');
}

class _Store implements DownloadsStore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Exporter extends ChapterExporter {
  _Exporter() : super(documentsDirectory: Future.value(Directory.systemTemp));
  @override
  Future<ChapterExportResult> export({required DownloadsStore store, required String seriesLabel, required List<SavedChapter> chapters, required ChapterExportFormat format}) async =>
      ChapterExportResult(directory: Directory.systemTemp.createTempSync('mm-export-'), seriesFolderName: seriesLabel, format: format, chapterCount: chapters.length, pageCount: chapters.length * 40, skippedCount: 0);
}

class _Api28 extends MediaStoreChannel {
  @override
  Future<ExportDestination> destination({TargetPlatform? platform}) async => ExportDestination.shareOnly;
}

Future<void> _settle(WidgetTester t, [int steps = 6]) async {
  for (var i = 0; i < steps; i++) {
    await t.pump(const Duration(milliseconds: 150));
  }
}

List<Override> downloadOverrides(List<DownloadedSeriesGroup> groups, {int app = 0}) => [
      downloadedSeriesProvider.overrideWith((ref) async => groups),
      totalDeviceDownloadBytesProvider.overrideWith((ref) async => app),
      deviceSpaceProvider.overrideWith((ref) async => (free: 20 * 1024 * _mb, total: 64 * 1024 * _mb)),
      storageCapProvider.overrideWith(_Cap10.new),
    ];

void main() {
  setUpAll(loadAppFonts);

  testWidgets('the meter carries the exact semantics value', (t) async {
    final gs = [savedSeries('series-1', 'Solo Leveling', 3)];
    await pumpLibrary(t, FakeLib(), start: '/downloads', extra: downloadOverrides(gs, app: 3 * 40 * _mb + 1024 * _mb));
    final node = t.getSemantics(find.bySemanticsLabel('Storage'));
    expect(node.value, '120 MB of 10 GB used: this profile 120 MB, other app data 1 GB, 8.9 GB free');
  });

  testWidgets('removing a series drains its card on springDismiss', (t) async {
    final gs = [savedSeries('series-1', 'Solo Leveling', 2)];
    await pumpLibrary(t, FakeLib(), start: '/downloads', extra: downloadOverrides(gs));
    final card = t.state<GlassSeriesDownloadsCardState>(find.byType(GlassSeriesDownloadsCard));
    expect(card.collapseValue, 1);
    card.drain();
    await _settle(t, 2);
    expect(card.collapseValue, lessThan(1));
  });

  testWidgets('the queue reorder calls moveInQueue', (t) async {
    final rec = _RecQueue();
    final rows = [chapter(1, state: DownloadChapterState.queued), chapter(2, state: DownloadChapterState.queued), chapter(3, state: DownloadChapterState.queued)];
    await pumpLibrary(t, FakeLib(), start: '/downloads?tab=queue', extra: [
      downloadQueueControllerProvider.overrideWith(() => rec),
      activeDownloadQueueProvider.overrideWith((ref) async => rows),
      ...downloadOverrides(const []),
    ],);
    final list = t.widget<GlassReorderList<SavedChapter>>(find.byType(GlassReorderList<SavedChapter>));
    list.onReorder(2, 0);
    await _settle(t, 1);
    expect(rec.moves, ['c3->0']);
  });

  test('the pacing line counts down from pacedUntil and clears itself', () {
    final at = DateTime(2026, 10, 1, 12);
    final s = QueueSummary(
      headline: QueueHeadline.waiting,
      current: null,
      alongside: 0,
      seriesSaved: 0,
      seriesTotal: 0,
      waitingCount: 3,
      failedCount: 0,
      pauseReason: DownloadQueuePauseReason.none,
      pacedUntil: at.add(const Duration(seconds: 12)),
    );
    expect(queuePauseLine(s, cap: '10 GB', noun: 'phone', now: at), 'Waiting 12 s: the server is pacing downloads');
    expect(queuePauseLine(s, cap: '10 GB', noun: 'phone', now: at.add(const Duration(seconds: 5))), 'Waiting 7 s: the server is pacing downloads');
    expect(queuePauseLine(s, cap: '10 GB', noun: 'phone', now: at.add(const Duration(seconds: 13))), isNull);
  });

  testWidgets('Save to Files on Android 7 to 9 answers with Share instead of a path', (t) async {
    final gs = [savedSeries('series-1', 'Solo Leveling', 2)];
    await pumpLibrary(t, FakeLib(), start: '/downloads?sheet=save-files&series=shelf:series-1', android: true, extra: [
      ...downloadOverrides(gs),
      downloadsStoreProvider.overrideWithValue(_Store()),
      chapterExporterProvider.overrideWithValue(_Exporter()),
      mediaStoreChannelProvider.overrideWithValue(_Api28()),
    ],);
    await t.tap(find.text('CBZ file'));
    await _settle(t, 10);
    expect(find.textContaining('Saved to Files · 2 chapters · 80 pages'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.textContaining('Download/ManhwaManiacs'), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  test('18+: a mature download counts toward no badge on a gate-closed profile', () {
    final rows = [chapter(1, state: DownloadChapterState.queued), chapter(2, state: DownloadChapterState.queued, mature: true)];
    const closed = DownloadRowFilter(gateOpen: false, mode: ContentMode.manga);
    const open = DownloadRowFilter(gateOpen: true, mode: ContentMode.manga);
    expect(activeDownloadCount(const DownloadQueueState(), rows, closed), 1);
    expect(activeDownloadCount(const DownloadQueueState(), rows, open), 2);
  });
}
