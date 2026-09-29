import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/downloads/models/chapter_identity.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/providers/series_download_status_provider.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/downloads/utils/run_summary.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_states.dart';

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
    if (running > 0 && paused != DownloadQueuePauseReason.userPaused) {
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
    final line = describeRun(
      (
        requested: runKeys.length,
        saved: saved,
        alreadySaved: alreadySaved,
        missingPages: 0,
        failed: failed,
        stopped: stopped,
        freeMb: null, // TODO(mobile/17): free-space figure from the queue
      ),
    );
    final problem = failed > 0 || stopped;
    return Container(
      padding: const EdgeInsets.all(12),
      color: t.colorPaper1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (problem) Text('NOTE', style: kickerStyle(context, color: t.colorSpot)),
          Text(line, key: const Key('run-summary')),
          Row(
            children: [
              if (onManage != null && paused == DownloadQueuePauseReason.freeSpaceFloor)
                TextButton(onPressed: onManage, child: const Text('Manage downloads')),
              const Spacer(),
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
