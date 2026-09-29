import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/models/saved_chapter.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';

enum QueueHeadline { downloading, waiting, paused }

class QueueCurrent {
  const QueueCurrent({
    required this.seriesTitle,
    required this.chapterLabel,
    required this.pageDone,
    required this.pageTotal,
    required this.kind,
  });
  final String seriesTitle;

  /// `CH 12`.
  final String chapterLabel;
  final int pageDone;

  /// 0 until the page list is known (the skin says `READING CHAPTER DETAILS…`).
  final int pageTotal;
  final DownloadKind kind;
}

/// The queue as the Downloads screen's Activity block reads it, so a skin never touches the
/// controller's internals. Null when nothing runs, nothing waits and nothing is paused.
class QueueSummary {
  const QueueSummary({
    required this.headline,
    required this.current,
    required this.alongside,
    required this.seriesSaved,
    required this.seriesTotal,
    required this.waitingCount,
    required this.failedCount,
    required this.pauseReason,
  });

  final QueueHeadline headline;
  final QueueCurrent? current;

  /// Chapters downloading beside the current one.
  final int alongside;
  final int seriesSaved;
  final int seriesTotal;
  final int waitingCount;
  final int failedCount;
  final DownloadQueuePauseReason pauseReason;
}

String chapterLabelOf(SavedChapter c) {
  final n = c.chapterNumber;
  if (n != null) return 'CH ${n == n.roundToDouble() ? n.toInt() : n}';
  final t = c.title;
  return t == null || t.isEmpty ? 'CH ${c.chapterKey}' : t.toUpperCase();
}

/// [unfinished] is `activeDownloadQueueProvider`'s rows (queued, downloading, failed); [all] is
/// every saved row, for the "12 of 40 saved in this series" tally.
QueueSummary? summariseQueue(
  DownloadQueueState state,
  List<SavedChapter> unfinished,
  List<SavedChapter> all,
) {
  final waiting = unfinished.where((c) => c.state == DownloadChapterState.queued).length;
  final failed = unfinished.where((c) => c.state == DownloadChapterState.failed).length;
  final running = state.isDownloading || state.currentChapter != null;
  final paused = state.isPaused && state.pauseReason != DownloadQueuePauseReason.noScope;
  if (!running && !paused && waiting == 0) return null;
  if (paused && unfinished.isEmpty && !running) return null;

  final id = state.currentChapter;
  SavedChapter? row;
  if (id != null) {
    for (final c in unfinished) {
      if (c.identity == id) row = c;
    }
  }
  row ??= unfinished.where((c) => c.state == DownloadChapterState.downloading).firstOrNull ??
      (unfinished.where((c) => c.state == DownloadChapterState.queued).firstOrNull);

  QueueCurrent? current;
  var saved = 0;
  var total = 0;
  if (row != null) {
    current = QueueCurrent(
      seriesTitle: row.seriesTitle ?? row.seriesKey,
      chapterLabel: chapterLabelOf(row),
      pageDone: state.pagesDone,
      pageTotal: state.pageTotal,
      kind: row.kind,
    );
    for (final c in all) {
      if (c.sourceId != row.sourceId || c.seriesKey != row.seriesKey || c.kind.isAudio) continue;
      total++;
      if (c.state == DownloadChapterState.complete) saved++;
    }
  }

  return QueueSummary(
    headline: paused
        ? QueueHeadline.paused
        : (running ? QueueHeadline.downloading : QueueHeadline.waiting),
    current: current,
    alongside: state.activeChapterCount > 1 ? state.activeChapterCount - 1 : 0,
    seriesSaved: saved,
    seriesTotal: total,
    waitingCount: waiting,
    failedCount: failed,
    pauseReason: state.pauseReason,
  );
}
