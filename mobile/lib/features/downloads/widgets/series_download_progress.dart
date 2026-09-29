import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/app/theme/app_colors.dart';
import 'package:manhwamaniacs/app/theme/app_presets.dart';
import 'package:manhwamaniacs/features/downloads/models/chapter_identity.dart';
import 'package:manhwamaniacs/features/downloads/providers/series_download_summary_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/storage_settings_provider.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_copy.dart';
import 'package:manhwamaniacs/shared/widgets/glass_card.dart';

/// How much of *this* series is on the phone, on the series page itself.
///
/// The Downloads tab already answers this for the queue as a whole, but the
/// owner's report was specifically about tapping "Download Series" here and
/// having no way to tell anything had started without leaving the page. So
/// this card sits above the chapter list and answers, in order: how many
/// chapters are saved, what is being fetched right now, why nothing is moving
/// if nothing is, and — always, because it is the likeliest explanation for a
/// download that looks stuck — that downloads only run in the foreground.
///
/// Renders nothing until this series has at least one row in the store: a
/// series nobody has downloaded from must not carry a progress card.
class SeriesDownloadProgress extends ConsumerWidget {
  const SeriesDownloadProgress({
    super.key,
    required this.identity,
    required this.totalChapters,
  });

  final SeriesIdentity identity;

  /// Chapters the page is listing. The denominator for "12 of 30 saved" —
  /// taken from the rendered list rather than the store, so it counts
  /// chapters that exist but have never been queued.
  final int totalChapters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(
      seriesDownloadSummaryProvider((series: identity, listed: totalChapters)),
    );
    if (summary == null) return const SizedBox.shrink();

    final saved = summary.saved;
    final failed = summary.failed;
    final waiting = summary.waiting;
    final total = summary.total;
    final activePage = summary.downloadingPage;
    final activePageTotal = summary.pageTotal ?? 0;
    final queue = ref.watch(downloadQueueControllerProvider);
    final pauseMessage = summary.pauseReason == null
        ? null
        : downloadPauseMessage(summary.pauseReason!, ref.watch(storageCapProvider));

    return GlassCard(
      padding: EdgeInsets.all(context.space.lg),
      glowColor: queue.isBlocked ? context.colors.warning : context.colors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                saved == total ? Icons.offline_pin : Icons.downloading_outlined,
                size: 20,
                color: saved == total ? context.colors.success : context.colors.primary,
              ),
              SizedBox(width: context.space.sm),
              Expanded(
                child: Text(
                  '$saved of $total chapters saved on this phone',
                  key: const Key('series-download-saved-count'),
                  style: context.text.labelLg,
                ),
              ),
            ],
          ),
          SizedBox(height: context.space.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(context.space.xs),
            child: LinearProgressIndicator(
              key: const Key('series-download-bar'),
              value: total == 0 ? 0 : (saved / total).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: context.colors.fg.withAlpha(20),
              valueColor: AlwaysStoppedAnimation(
                saved == total ? context.colors.success : context.colors.primary,
              ),
            ),
          ),
          if (activePage != null) ...[
            SizedBox(height: context.space.sm),
            Text(
              activePageTotal > 0
                  ? 'Downloading now · page $activePage of '
                      '$activePageTotal'
                  : 'Downloading now · reading chapter details…',
              key: const Key('series-download-current'),
              style: context.text.bodySm.copyWith(color: context.colors.primary),
            ),
          ],
          if (waiting > 0 || failed > 0) ...[
            SizedBox(height: context.space.xxs),
            Text(
              [
                if (waiting > 0) '$waiting waiting in the queue',
                if (failed > 0) '$failed failed',
              ].join(' · '),
              key: const Key('series-download-queue-summary'),
              style: context.text.caption.copyWith(
                color: failed > 0 ? context.colors.danger : context.colors.muted,
              ),
            ),
          ],
          if (pauseMessage != null) ...[
            SizedBox(height: context.space.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: context.colors.warning, size: 16),
                SizedBox(width: context.space.sm),
                Expanded(
                  child: Text(
                    pauseMessage,
                    style: context.text.bodySm.copyWith(height: 1.4),
                  ),
                ),
              ],
            ),
          ],
          if (waiting > 0 || activePage != null) ...[
            SizedBox(height: context.space.sm),
            Text(
              kForegroundOnlyDownloadsNote,
              style: context.text.caption.copyWith(color: context.colors.muted),
            ),
          ],
        ],
      ),
    );
  }
}
