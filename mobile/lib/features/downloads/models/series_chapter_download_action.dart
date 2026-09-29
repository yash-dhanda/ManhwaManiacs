import 'package:flutter/foundation.dart';

/// Which of the five distinct things a chapter row's download control can be
/// saying. They used to collapse into one disabled icon button, so a chapter
/// mid-download, one waiting its turn and one entirely on the phone were
/// pixel-identical — the reason downloading felt like it did nothing.
enum SeriesChapterDownloadPhase {
  /// Nothing on this phone for this chapter — the row offers to fetch it.
  notDownloaded,

  /// Accepted into the durable queue, not yet reached by the fetch loop.
  queued,

  /// Being fetched right now. The only phase that carries a page counter.
  downloading,

  /// Every page is on disk: readable with no network at all. Marked with a
  /// persistent badge rather than a disabled button, because "already done"
  /// and "can't press this" are different statements.
  downloaded,

  /// Bounded retries exhausted. The affordance is "retry", not "download".
  failed,
}

/// Trailing download control for one chapter row, plus the words that go with
/// it. Both series pages build this through `chapterDownloadAction()` so the
/// library and source lists can never disagree about what a state looks like.
class SeriesChapterDownloadAction {
  const SeriesChapterDownloadAction({
    required this.phase,
    this.onPressed,
    this.pagesDone = 0,
    this.pageTotal = 0,
    this.error,
    this.buttonKey,
  });

  final SeriesChapterDownloadPhase phase;

  /// Only [SeriesChapterDownloadPhase.notDownloaded] and
  /// [SeriesChapterDownloadPhase.failed] are pressable; every other phase is
  /// a status badge, so a null callback here is never the thing that
  /// communicates state.
  final VoidCallback? onPressed;

  /// Pages of this chapter already on disk and how many it has in total, live
  /// from the queue — non-zero only while this exact chapter is the one being
  /// fetched. [pageTotal] is 0 until the manifest lands, which is precisely
  /// when the bar must stay indeterminate rather than claim "0 of 0".
  final int pagesDone;
  final int pageTotal;

  /// Last failure message for [SeriesChapterDownloadPhase.failed].
  final String? error;

  final Key? buttonKey;

  /// Null means indeterminate — see [pageTotal].
  double? get progressValue =>
      pageTotal > 0 ? (pagesDone / pageTotal).clamp(0.0, 1.0) : null;

  /// The line printed under the chapter title. Deliberately a sentence rather
  /// than an icon alone: the badge answers "what state", this answers "how
  /// far along" and "why did it stop".
  String? get statusText => switch (phase) {
        SeriesChapterDownloadPhase.notDownloaded => null,
        SeriesChapterDownloadPhase.queued => 'Queued for download',
        SeriesChapterDownloadPhase.downloading => pageTotal > 0
            ? 'Downloading · page $pagesDone of $pageTotal'
            : 'Downloading · reading chapter details…',
        SeriesChapterDownloadPhase.downloaded => 'Saved offline',
        SeriesChapterDownloadPhase.failed =>
          error == null ? 'Download failed' : 'Download failed — $error',
      };

  String get tooltip => switch (phase) {
        SeriesChapterDownloadPhase.notDownloaded => 'Download Chapter',
        SeriesChapterDownloadPhase.queued => 'Queued for download',
        SeriesChapterDownloadPhase.downloading => pageTotal > 0
            ? 'Downloading — page $pagesDone of $pageTotal'
            : 'Downloading',
        SeriesChapterDownloadPhase.downloaded =>
          'Saved offline — reads with no connection',
        SeriesChapterDownloadPhase.failed => 'Retry Download',
      };
}
