// ignore_for_file: require_trailing_commas, avoid_dynamic_calls, prefer_const_declarations, unnecessary_null_checks
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/providers/series_download_summary_provider.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/downloads/utils/download_mark.dart';
import 'package:manhwamaniacs/features/downloads/utils/run_summary.dart';

DownloadRunOutcome _o(
        {int saved = 0,
        int already = 0,
        int missing = 0,
        int failed = 0,
        bool stopped = false,
        int? free}) =>
    (
      requested: saved + already + missing + failed,
      saved: saved,
      alreadySaved: already,
      missingPages: missing,
      failed: failed,
      stopped: stopped,
      freeMb: free
    );

void main() {
  test('mark state, label and tooltip for all seven states', () {
    final s = DownloadChapterState.values;
    final cases = <(DownloadMarkState, String, String)>[
      (downloadMarkState(null), 'Not downloaded', 'Download this chapter'),
      (downloadMarkState(s[0]), 'Queued', 'Queued to download'),
      (
        downloadMarkState(DownloadChapterState.downloading, progress: 0.3),
        'Downloading, 30 percent',
        'Downloading'
      ),
      (
        downloadMarkState(DownloadChapterState.complete),
        'Saved',
        'Downloaded — opens with no connection'
      ),
      (
        downloadMarkState(DownloadChapterState.failed),
        'Failed, tap to retry',
        'Failed — tap to try again'
      ),
      (
        downloadMarkState(DownloadChapterState.queued, paused: true),
        'Paused',
        'Paused — this phone is almost full'
      ),
      (
        downloadMarkState(DownloadChapterState.complete, stale: true),
        'Saved copy is out of date, download again',
        'The source changed these pages — download it again'
      ),
    ];
    for (final (m, label, tip) in cases) {
      expect(downloadMarkLabel(m), label);
      expect(downloadMarkTooltip(m), tip);
    }
    expect(downloadMarkTooltip(const MarkPaused(), reason: DownloadQueuePauseReason.cap),
        'Paused — your 10 GB limit is full');
    expect(downloadMarkTooltip(const MarkDownloading(.5), page: 12, pageTotal: 40),
        'Downloading — page 12 of 40');
  });

  test('describeRun lines', () {
    expect(describeRun(_o(saved: 12)), '12 chapters saved.');
    expect(describeRun(_o(already: 3)), 'Nothing to download — those are already saved.');
    expect(describeRun(_o(saved: 10, missing: 1, failed: 1)),
        '10 of 12 saved, 1 with missing pages, 1 failed.');
    expect(describeRun(_o(free: 380)),
        'Out of room: only 380 MB free. Remove some downloads and run it again.');
    expect(describeRun(_o(saved: 4, stopped: true)), 'Stopped: 4 saved.');
  });

  test('series summary figures', () {
    final r = summarizeSeriesDownloads(
      states: [
        DownloadChapterState.complete,
        DownloadChapterState.failed,
        DownloadChapterState.queued
      ],
      listed: 201,
      active: (pagesDone: 7, pageTotal: 40),
      pauseReason: DownloadQueuePauseReason.cap,
    );
    expect((r.saved, r.total, r.waiting, r.failed, r.downloadingPage, r.pageTotal),
        (1, 201, 1, 1, 7, 40));
    expect(r.pauseReason, DownloadQueuePauseReason.cap);
  });
}
