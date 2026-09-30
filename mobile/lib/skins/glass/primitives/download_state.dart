import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';

// The eight states of the per-chapter download control (glass 7.29) and the mapping from the shared store row and
// queue item. Pure; the widget is presentational.

enum ChapterDownloadKind { none, queued, downloading, saved, incomplete, paused, stale, failed }

/// The download vocabulary's pause reasons (inventory mobile 6c).
enum DownloadPauseReason { noScope, backgrounded, freeSpaceFloor, cap, userPaused }

/// What the shared store and queue know about one chapter.
class ChapterDownloadFacts {
  const ChapterDownloadFacts({
    this.row,
    this.inQueue = false,
    this.pagesDone = 0,
    this.pagesTotal = 0,
    this.pauseReason,
    this.stale = false,
    this.missingPages = false,
  });

  /// The `saved_chapters` row state, null when there is no row.
  final DownloadChapterState? row;
  final bool inQueue;
  final int pagesDone;
  final int pagesTotal;
  final DownloadPauseReason? pauseReason;

  /// The source changed the pages after they were saved.
  final bool stale;

  /// A complete-looking row with pages missing on disk.
  final bool missingPages;
}

class ChapterDownloadView {
  const ChapterDownloadView(this.kind, {this.progress = 0, this.pagesDone = 0, this.pagesTotal = 0, this.pauseReason});
  final ChapterDownloadKind kind;
  final double progress;
  final int pagesDone;
  final int pagesTotal;
  final DownloadPauseReason? pauseReason;

  @override
  bool operator ==(Object other) =>
      other is ChapterDownloadView && other.kind == kind && other.progress == progress && other.pagesDone == pagesDone && other.pagesTotal == pagesTotal && other.pauseReason == pauseReason;

  @override
  int get hashCode => Object.hash(kind, progress, pagesDone, pagesTotal, pauseReason);
}

ChapterDownloadView chapterDownloadView(ChapterDownloadFacts f) {
  final total = f.pagesTotal;
  final progress = total <= 0 ? 0.0 : (f.pagesDone / total).clamp(0.0, 1.0);
  ChapterDownloadView v(ChapterDownloadKind k) => ChapterDownloadView(k, progress: progress, pagesDone: f.pagesDone, pagesTotal: total, pauseReason: f.pauseReason);
  if (f.row == DownloadChapterState.failed) return v(ChapterDownloadKind.failed);
  final active = f.inQueue || f.row == DownloadChapterState.queued || f.row == DownloadChapterState.downloading;
  if (f.pauseReason != null && active) return v(ChapterDownloadKind.paused);
  if (f.row == DownloadChapterState.complete) {
    if (f.stale) return v(ChapterDownloadKind.stale);
    if (f.missingPages) return v(ChapterDownloadKind.incomplete);
    return ChapterDownloadView(ChapterDownloadKind.saved, progress: 1, pagesDone: total, pagesTotal: total);
  }
  if (f.row == DownloadChapterState.downloading) return v(ChapterDownloadKind.downloading);
  if (active) return v(ChapterDownloadKind.queued);
  return v(ChapterDownloadKind.none);
}

/// The exact semantics labels of glass 7.29.
String downloadSemanticsLabel(ChapterDownloadView v, String chapterLabel) => switch (v.kind) {
      ChapterDownloadKind.none => 'Download $chapterLabel',
      ChapterDownloadKind.queued => 'Queued to download',
      ChapterDownloadKind.downloading => 'Downloading, page ${v.pagesDone} of ${v.pagesTotal}',
      ChapterDownloadKind.saved => 'Downloaded, opens with no connection',
      ChapterDownloadKind.incomplete => 'Incomplete, some pages are missing',
      ChapterDownloadKind.paused => switch (v.pauseReason) {
          DownloadPauseReason.freeSpaceFloor => 'Paused, device is full',
          DownloadPauseReason.cap => 'Paused, storage cap reached',
          DownloadPauseReason.backgrounded => 'Paused until you reopen the app',
          DownloadPauseReason.noScope => 'Paused, choose a profile first',
          _ => 'Paused',
        },
      ChapterDownloadKind.stale => 'The source changed these pages, download again',
      ChapterDownloadKind.failed => 'Download failed, retry',
    };
