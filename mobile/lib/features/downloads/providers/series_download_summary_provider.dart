import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/downloads/models/chapter_identity.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/providers/series_download_status_provider.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';

typedef SeriesDownloadSummary = ({
  int saved,
  int total,
  int? downloadingPage,
  int? pageTotal,
  int waiting,
  int failed,
  DownloadQueuePauseReason? pauseReason,
});

/// Pure figures for the series download card. [total] is the larger of the
/// listed chapters and the store's rows.
SeriesDownloadSummary summarizeSeriesDownloads({
  required Iterable<DownloadChapterState> states,
  required int listed,
  ({int pagesDone, int pageTotal})? active,
  DownloadQueuePauseReason pauseReason = DownloadQueuePauseReason.none,
}) {
  final all = states.toList();
  final saved = all.where((s) => s == DownloadChapterState.complete).length;
  final failed = all.where((s) => s == DownloadChapterState.failed).length;
  final waiting = all.length - saved - failed;
  final blocked = pauseReason == DownloadQueuePauseReason.freeSpaceFloor ||
      pauseReason == DownloadQueuePauseReason.cap;
  return (
    saved: saved,
    total: listed > all.length ? listed : all.length,
    downloadingPage: active?.pagesDone,
    pageTotal: active?.pageTotal,
    waiting: waiting,
    failed: failed,
    pauseReason: blocked && (active != null || waiting > 0) ? pauseReason : null,
  );
}

final seriesDownloadSummaryProvider = Provider.autoDispose
    .family<SeriesDownloadSummary?, ({SeriesIdentity series, int listed})>((ref, k) {
  final statuses = ref.watch(seriesChapterDownloadStatusProvider(k.series)).valueOrNull;
  if (statuses == null || statuses.isEmpty) return null;
  return summarizeSeriesDownloads(
    states: statuses.values.map((s) => s.state),
    listed: k.listed,
    active: ref.watch(seriesActiveChapterProgressProvider(k.series))?.progress,
    pauseReason: ref.watch(downloadQueueControllerProvider).pauseReason,
  );
});
