import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';

/// The seven states of a chapter's download mark (DESIGN §7.18).
sealed class DownloadMarkState {
  const DownloadMarkState();
}

class MarkNone extends DownloadMarkState {
  const MarkNone();
}

class MarkQueued extends DownloadMarkState {
  const MarkQueued();
}

class MarkDownloading extends DownloadMarkState {
  const MarkDownloading(this.progress);
  final double progress; // 0..1
}

class MarkSaved extends DownloadMarkState {
  const MarkSaved();
}

class MarkFailed extends DownloadMarkState {
  const MarkFailed();
}

class MarkPaused extends DownloadMarkState {
  const MarkPaused();
}

class MarkStale extends DownloadMarkState {
  const MarkStale();
}

/// [state] is the store row's state (null = no row). [progress] is 0..1 for
/// the active chapter, [paused] when the queue is blocked, [stale] when the
/// source changed the pages since the copy was saved.
DownloadMarkState downloadMarkState(
  DownloadChapterState? state, {
  bool stale = false,
  double progress = 0,
  bool paused = false,
}) =>
    switch (state) {
      null => const MarkNone(),
      DownloadChapterState.complete => stale ? const MarkStale() : const MarkSaved(),
      DownloadChapterState.failed => const MarkFailed(),
      DownloadChapterState.queued => paused ? const MarkPaused() : const MarkQueued(),
      DownloadChapterState.downloading =>
        paused ? const MarkPaused() : MarkDownloading(progress.clamp(0.0, 1.0)),
    };

/// The screen-reader name (§7 semantics table).
String downloadMarkLabel(DownloadMarkState s) => switch (s) {
      MarkNone() => 'Not downloaded',
      MarkQueued() => 'Queued',
      MarkDownloading(:final progress) => 'Downloading, ${(progress * 100).round()} percent',
      MarkSaved() => 'Saved',
      MarkFailed() => 'Failed, tap to retry',
      MarkPaused() => 'Paused',
      MarkStale() => 'Saved copy is out of date, download again',
    };

/// The tooltip (DP7 / mobile §6c wording).
String downloadMarkTooltip(
  DownloadMarkState s, {
  DownloadQueuePauseReason? reason,
  int? page,
  int? pageTotal,
}) =>
    switch (s) {
      MarkNone() => 'Download this chapter',
      MarkQueued() => 'Queued to download',
      MarkDownloading() => page != null && pageTotal != null && pageTotal > 0
          ? 'Downloading — page $page of $pageTotal'
          : 'Downloading',
      MarkSaved() => 'Downloaded — opens with no connection',
      MarkFailed() => 'Failed — tap to try again',
      MarkPaused() => reason == DownloadQueuePauseReason.cap
          ? 'Paused — your 10 GB limit is full'
          : 'Paused — this phone is almost full',
      MarkStale() => 'The source changed these pages — download it again',
    };
