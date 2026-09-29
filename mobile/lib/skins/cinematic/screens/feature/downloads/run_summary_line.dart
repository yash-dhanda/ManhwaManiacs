import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/downloads/models/chapter_identity.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/providers/series_download_status_provider.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/downloads/services/device_storage_info.dart';
import 'package:manhwamaniacs/features/downloads/utils/run_summary.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_states.dart';

/// Free megabytes on the device, for the `Out of room` line; null when it cannot
/// be read.
final _freeMbProvider = FutureProvider.autoDispose<int?>((ref) async {
  final bytes = await ref.watch(deviceStorageInfoProvider).freeSpaceBytes();
  return bytes == null ? null : bytes ~/ (1024 * 1024);
});

/// The running state (`DOWNLOADING 4 OF 12` + rule + `Stop`) and, once every
/// chapter of the run settled, the [describeRun] summary with `Dismiss`.
class DownloadRunLine extends ConsumerWidget {
  const DownloadRunLine({
    super.key,
    required this.series,
    required this.runKeys,
    required this.alreadySaved,
    required this.onDismiss,
    this.onManage,
  });

  final SeriesIdentity series;
  final Set<String> runKeys;
  final int alreadySaved;
  final VoidCallback onDismiss;
  final VoidCallback? onManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (runKeys.isEmpty) return const SizedBox.shrink();
    final t = cineOf(context);
    final statuses = ref.watch(seriesChapterDownloadStatusProvider(series)).valueOrNull ?? const {};
    final mine = [for (final k in runKeys) statuses[k]?.state];
    final saved = mine.where((s) => s == DownloadChapterState.complete).length;
    final failed = mine.where((s) => s == DownloadChapterState.failed).length;
    final running = runKeys.length - saved - failed;
    final paused = ref.watch(downloadQueueControllerProvider.select((q) => q.pauseReason));
    final blocked = paused == DownloadQueuePauseReason.userPaused ||
        paused == DownloadQueuePauseReason.freeSpaceFloor ||
        paused == DownloadQueuePauseReason.cap;
    if (running > 0 && !blocked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('DOWNLOADING $saved OF ${runKeys.length}', style: kickerStyle(context)),
              ),
              TextButton(
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: () => ref.read(downloadQueueControllerProvider.notifier).pause(),
                child: const Text('Stop'),
              ),
            ],
          ),
          SizedBox(
            height: 2,
            child: LinearProgressIndicator(
              value: saved / runKeys.length,
              color: t.colorSpot,
              backgroundColor: t.colorRule1,
            ),
          ),
        ],
      );
    }
    final stopped = running > 0;
    final freeMb = paused == DownloadQueuePauseReason.freeSpaceFloor
        ? ref.watch(_freeMbProvider).valueOrNull
        : null;
    final line = describeRun(
      (
        requested: runKeys.length,
        saved: (saved - alreadySaved).clamp(0, saved),
        alreadySaved: alreadySaved,
        missingPages: 0,
        failed: failed,
        stopped: stopped,
        freeMb: freeMb,
      ),
    );
    final problem = failed > 0 || stopped || freeMb != null;
    return Container(
      padding: const EdgeInsets.all(12),
      color: t.colorPaper1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (problem) Text('NOTE', style: kickerStyle(context, color: t.colorSpot)),
          Text(line, key: const Key('run-summary')),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (onManage != null && paused == DownloadQueuePauseReason.freeSpaceFloor)
                TextButton(
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  onPressed: onManage,
                  child: const Text('Manage downloads'),
                ),
              TextButton(
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: onDismiss,
                child: const Text('Dismiss'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
