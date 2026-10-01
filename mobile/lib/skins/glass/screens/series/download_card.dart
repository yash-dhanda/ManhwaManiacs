import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/providers/series_download_status_provider.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/sources/providers/source_progress_provider.dart';
import 'package:manhwamaniacs/skins/glass/primitives/ai/machine_badge.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/liquid_progress.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/routes/sheet_registry.dart';
import 'package:manhwamaniacs/skins/glass/screens/series/series_actions.dart';
import 'package:manhwamaniacs/skins/glass/screens/series/series_data.dart';
import 'package:manhwamaniacs/skins/glass/screens/series/tags_sheet.dart' show pushSeriesSheet;

String? _pauseLine(DownloadQueuePauseReason r) => switch (r) {
      DownloadQueuePauseReason.userPaused => 'Paused',
      DownloadQueuePauseReason.cap => 'Paused: your storage limit is full',
      DownloadQueuePauseReason.freeSpaceFloor => 'Paused: this device is almost full',
      _ => null,
    };

/// The download card (glass 8.12 Below), shown when anything is queued or saved: the saved count with a liquid bar, the chapter
/// downloading now, waiting and failed, the pause reason, the phone note and "Save to Files…".
class SeriesDownloadCard extends ConsumerWidget {
  const SeriesDownloadCard({super.key, required this.data});
  final GlassSeriesData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = data;
    final statuses = ref.watch(seriesChapterDownloadStatusProvider(d.identity)).valueOrNull ?? const {};
    if (statuses.isEmpty) return const SizedBox.shrink();
    final saved = statuses.values.where((s) => s.state == DownloadChapterState.complete).length;
    final waiting = statuses.values.where((s) => s.state == DownloadChapterState.queued).length;
    final failed = statuses.values.where((s) => s.state == DownloadChapterState.failed).length;
    final active = ref.watch(seriesActiveChapterProgressProvider(d.identity));
    final pause = _pauseLine(ref.watch(downloadQueueControllerProvider.select((q) => q.pauseReason)));
    final total = d.chapters.isEmpty ? saved : d.chapters.length;
    final lines = [
      if (active != null) 'Downloading now · page ${active.progress.pagesDone} of ${active.progress.pageTotal}',
      if (waiting > 0 || failed > 0) [if (waiting > 0) '$waiting waiting', if (failed > 0) '$failed failed'].join(' · '),
      if (pause != null) pause,
    ];
    return DecoratedBox(
      key: const ValueKey('series-download-card'),
      decoration: BoxDecoration(color: gt.colorSurface1, borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassLabel('$saved of $total chapters saved on this device', role: gt.typeHeadline, maxLines: 2),
            const SizedBox(height: 8),
            LiquidProgress(value: total == 0 ? 0 : saved / total, height: 8, meniscus: false),
            for (final l in lines) Padding(padding: const EdgeInsets.only(top: 6), child: GlassLabel(l, role: gt.typeFootnote, color: gt.colorLabel2)),
            Padding(padding: const EdgeInsets.only(top: 6), child: GlassLabel('Downloads run while the app is open', role: gt.typeCaption1, color: gt.colorLabel3)),
            if (saved > 0 && glassSheetRegistered('save-files'))
              GlassButton(
                label: 'Save to Files…',
                variant: GlassButtonVariant.plain,
                size: GlassButtonSize.small,
                onPressed: () {
                  final spec = glassSheetSpec('save-files')!;
                  unawaited(pushSeriesSheet(context, title: spec.title, builder: spec.builder, detents: spec.detents));
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// "Previously on" (glass 9.1.3; when the profile has progress): a row with the machine sparkle that opens the `recap` route.
class PreviouslyOnRow extends ConsumerWidget {
  const PreviouslyOnRow({super.key, required this.data});
  final GlassSeriesData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(sourceSeriesProgressProvider(data.progressKey)).isEmpty) return const SizedBox.shrink();
    return GlassPressable(
      key: const ValueKey('series-previously-on'),
      material: GlassMaterial.content,
      semanticsLabel: 'Previously on ${data.title}',
      onTap: () => openPreviouslyOn(ref, data),
      builder: (context, info) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(children: [
          const MachineBadge(),
          const SizedBox(width: 8),
          Expanded(child: GlassLabel('Previously on ${data.title}', role: gt.typeBody, wght: 600)),
        ],),
      ),
    );
  }
}
