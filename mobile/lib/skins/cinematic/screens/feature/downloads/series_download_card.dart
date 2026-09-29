import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/downloads/models/chapter_identity.dart';
import 'package:manhwamaniacs/features/downloads/providers/series_download_summary_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/storage_settings_provider.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_states.dart';

const String kSeriesForegroundNote =
    'Downloads run while the app is open; leaving pauses them and coming back '
    'picks up where they stopped.';

/// `ON THIS DEVICE`: figures from [seriesDownloadSummaryProvider]; absent when
/// nothing is saved or queued.
class SeriesDownloadCard extends ConsumerWidget {
  const SeriesDownloadCard({super.key, required this.series, required this.listed, this.onStorage});

  final SeriesIdentity series;
  final int listed;
  final VoidCallback? onStorage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(seriesDownloadSummaryProvider((series: series, listed: listed)));
    if (s == null) return const SizedBox.shrink();
    final t = cineOf(context);
    final busy = s.downloadingPage != null || s.waiting > 0;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      color: t.colorPaper1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ON THIS DEVICE', style: kickerStyle(context)),
          const SizedBox(height: 4),
          Text('${s.saved} OF ${s.total} CHAPTERS SAVED', key: const Key('series-download-saved')),
          const SizedBox(height: 8),
          SizedBox(
            height: 2,
            child: LinearProgressIndicator(
              value: s.total == 0 ? 0 : (s.saved / s.total).clamp(0.0, 1.0),
              color: t.colorSpot,
              backgroundColor: t.colorRule1,
            ),
          ),
          if (s.downloadingPage != null && (s.pageTotal ?? 0) > 0)
            Text('DOWNLOADING NOW · PAGE ${s.downloadingPage} OF ${s.pageTotal}',
                style: kickerStyle(context),),
          if (s.waiting > 0 || s.failed > 0)
            Text(
              [if (s.waiting > 0) '${s.waiting} WAITING', if (s.failed > 0) '${s.failed} FAILED']
                  .join(' · '),
              style: kickerStyle(context),
            ),
          if (s.pauseReason != null) ...[
            const SizedBox(height: 8),
            Text('NOTE', style: kickerStyle(context, color: t.colorSpot)),
            Text(
              switch (s.pauseReason!) {
                DownloadQueuePauseReason.cap =>
                  'Paused: your ${ref.watch(storageCapProvider).label} limit is full.',
                DownloadQueuePauseReason.userPaused => 'Paused: you paused downloads.',
                _ => 'Paused: this phone is almost full.',
              },
              key: const Key('series-download-pause'),
            ),
            if (onStorage != null)
              TextButton(
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: onStorage,
                child: const Text('Storage settings'),
              ),
          ],
          if (busy) ...[
            const SizedBox(height: 8),
            Text(kSeriesForegroundNote, style: TextStyle(fontSize: 12, color: t.colorInk60)),
          ],
        ],
      ),
    );
  }
}
