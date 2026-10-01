import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/models/saved_chapter.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/downloads/utils/active_download_count.dart';

SavedChapter _r(int i, DownloadChapterState s, {bool? mature, DownloadKind kind = DownloadKind.manga}) => SavedChapter(
      rowId: i,
      scopeId: 'u1p1',
      sourceId: 'src',
      seriesKey: 's',
      chapterKey: 'c$i',
      chapterNumber: null,
      title: null,
      seriesTitle: 'S',
      pageCount: 0,
      bytes: 0,
      state: s,
      pinned: false,
      readAt: null,
      createdAt: DateTime(2026),
      retryCount: 0,
      error: null,
      kind: kind,
      mature: mature,
    );

void main() {
  const state = DownloadQueueState();
  final rows = [
    _r(1, DownloadChapterState.queued),
    _r(2, DownloadChapterState.downloading),
    _r(3, DownloadChapterState.failed),
    _r(4, DownloadChapterState.complete),
    _r(5, DownloadChapterState.queued, mature: true),
    _r(6, DownloadChapterState.queued, kind: DownloadKind.novel),
  ];

  test('counts queued, downloading and failed after the mature and content-mode filters', () {
    expect(activeDownloadCount(state, rows, const DownloadRowFilter(gateOpen: false, mode: ContentMode.manga)), 3);
    expect(activeDownloadCount(state, rows, const DownloadRowFilter(gateOpen: true, mode: ContentMode.manga)), 4);
    expect(activeDownloadCount(state, rows, const DownloadRowFilter(gateOpen: false, mode: ContentMode.novel)), 1);
  });

  test('badge text: none for 0, the number up to 9, 9+ above', () {
    expect(badgeText(0), isNull);
    expect(badgeText(1), '1');
    expect(badgeText(9), '9');
    expect(badgeText(10), '9+');
    expect(badgeText(12), '9+');
  });
}
