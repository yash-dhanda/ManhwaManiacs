import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/models/saved_chapter.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/downloads/utils/queue_summary.dart';

SavedChapter row(int id, String key, DownloadChapterState s, {double? n, DownloadKind kind = DownloadKind.manga, String series = 's1'}) => SavedChapter(
      rowId: id,
      scopeId: 'u1p1',
      sourceId: 'src',
      seriesKey: series,
      chapterKey: key,
      chapterNumber: n,
      title: null,
      seriesTitle: 'Solo',
      pageCount: 0,
      bytes: 0,
      state: s,
      pinned: false,
      readAt: null,
      createdAt: DateTime(2026),
      retryCount: 0,
      error: null,
      kind: kind,
    );

void main() {
  final cur = row(1, 'c12', DownloadChapterState.downloading, n: 12);
  final q = row(2, 'c13', DownloadChapterState.queued, n: 13);
  final f = row(3, 'c14', DownloadChapterState.failed, n: 14);
  final done = row(4, 'c11', DownloadChapterState.complete, n: 11);
  const id = (sourceId: 'src', seriesKey: 's1', chapterKey: 'c12');

  test('downloading: current chapter, tally, waiting and failed counts', () {
    final s = summariseQueue(
      const DownloadQueueState(isDownloading: true, currentChapter: id, pagesDone: 7, pageTotal: 40, activeChapterCount: 3),
      [cur, q, f],
      [cur, q, f, done],
    )!;
    expect(s.headline, QueueHeadline.downloading);
    expect(s.current!.chapterLabel, 'CH 12');
    expect(s.current!.pageDone, 7);
    expect(s.current!.pageTotal, 40);
    expect(s.alongside, 2);
    expect((s.seriesSaved, s.seriesTotal), (1, 4));
    expect((s.waitingCount, s.failedCount), (1, 1));
  });

  test('each pause reason reads as paused and keeps its reason', () {
    for (final r in [
      DownloadQueuePauseReason.userPaused,
      DownloadQueuePauseReason.freeSpaceFloor,
      DownloadQueuePauseReason.cap,
      DownloadQueuePauseReason.backgrounded,
    ]) {
      final s = summariseQueue(DownloadQueueState(pauseReason: r), [q], [q])!;
      expect(s.headline, QueueHeadline.paused);
      expect(s.pauseReason, r);
    }
  });

  test('waiting: queued rows and nothing running', () {
    final s = summariseQueue(const DownloadQueueState(), [q], [q])!;
    expect(s.headline, QueueHeadline.waiting);
  });

  test('a row left downloading by a kill counts as waiting until the loop runs', () {
    final s = summariseQueue(const DownloadQueueState(), [cur], [cur])!;
    expect(s.headline, QueueHeadline.waiting);
    expect(s.waitingCount, 1);
    expect(s.current!.chapterLabel, 'CH 12');
  });

  test('nothing to show returns null', () {
    expect(summariseQueue(const DownloadQueueState(), const [], const []), isNull);
    expect(summariseQueue(const DownloadQueueState(), [f], [f]), isNull);
  });

  test('kinds pass through and audio rows are not counted in the tally', () {
    final novel = row(5, 'n1', DownloadChapterState.downloading, n: 1, kind: DownloadKind.novel, series: 'b');
    final audio = row(6, 'n1:audio', DownloadChapterState.complete, n: 1, kind: DownloadKind.audio, series: 'b');
    final s = summariseQueue(
      const DownloadQueueState(isDownloading: true, currentChapter: (sourceId: 'src', seriesKey: 'b', chapterKey: 'n1')),
      [novel],
      [novel, audio],
    )!;
    expect(s.current!.kind, DownloadKind.novel);
    expect(s.seriesTotal, 1);
  });

  test('pacing: pacedUntil and its seconds left; signed out is its own flag', () {
    final until = DateTime(2026, 1, 1, 12, 0, 30);
    final s = summariseQueue(DownloadQueueState(isDownloading: true, currentChapter: id, pacedUntil: until), [cur, q], [cur, q])!;
    expect(s.pacedUntil, until);
    expect(s.pacedSecondsLeft(DateTime(2026, 1, 1, 12, 0, 18)), 12);
    expect(s.pacedSecondsLeft(DateTime(2026, 1, 1, 12, 0, 30)), isNull);
    final out = summariseQueue(const DownloadQueueState(pauseReason: DownloadQueuePauseReason.noScope), [q], [q])!;
    expect(out.signedOut, isTrue);
    expect(summariseQueue(const DownloadQueueState(), [], []), isNull);
  });
}
