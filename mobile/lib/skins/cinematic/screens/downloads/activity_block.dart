import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/downloads/models/downloaded_series_group.dart';
import 'package:manhwamaniacs/features/downloads/models/saved_chapter.dart';
import 'package:manhwamaniacs/features/downloads/providers/active_download_queue_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloaded_series_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/storage_settings_provider.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/downloads/utils/queue_summary.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_confirm_dialog.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_progress.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/downloads/downloads_copy.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/downloads/queue_rows.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/downloads/storage_meter.dart' show deviceNounOf;
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// Activity (cinematic 8.23): pinned at the top of SAVED while something runs or is paused.
/// Reads [QueueSummary] so it never touches the controller's internals.
class ActivityBlock extends ConsumerStatefulWidget {
  const ActivityBlock({super.key, this.initiallyExpanded = false, this.onStorageSettings, this.preview});
  final bool initiallyExpanded;
  final VoidCallback? onStorageSettings;

  /// Test and proof hook: a fixed summary and queue instead of the providers.
  final ({QueueSummary summary, List<SavedChapter> queue})? preview;

  @override
  ConsumerState<ActivityBlock> createState() => _ActivityBlockState();
}

class _ActivityBlockState extends ConsumerState<ActivityBlock> {
  late bool _open = widget.initiallyExpanded;

  DownloadQueueController get _q => ref.read(downloadQueueControllerProvider.notifier);

  Future<void> _cancelAll() async {
    final ok = await showCineConfirm(
      context,
      title: 'Cancel all downloads?',
      body: 'Everything queued, downloading or failed is dropped. Finished chapters stay.',
      confirmLabel: 'Cancel all',
      cancelLabel: 'Keep them',
      destructive: true,
    );
    if (ok) await _q.cancelAll();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final preview = widget.preview;
    final state = preview == null ? ref.watch(downloadQueueControllerProvider) : const DownloadQueueState();
    final queue = preview?.queue ?? ref.watch(activeDownloadQueueProvider).valueOrNull ?? const <SavedChapter>[];
    final all = preview == null
        ? <SavedChapter>[
            for (final g in ref.watch(downloadedSeriesProvider).valueOrNull ?? const <DownloadedSeriesGroup>[]) ...g.chapters,
          ]
        : const <SavedChapter>[];
    final s = preview?.summary ?? summariseQueue(state, queue, all);
    if (s == null) return const SizedBox.shrink();
    final cap = ref.watch(storageCapProvider);
    final noun = deviceNounOf(context).toLowerCase();
    final note = pauseLine(s.pauseReason, cap: cap, noun: noun);
    final cur = s.current;
    final kicker = switch (s.headline) {
      QueueHeadline.downloading => 'DOWNLOADING',
      QueueHeadline.waiting => 'WAITING TO START',
      QueueHeadline.paused => 'PAUSED',
    };
    final userPaused = s.pauseReason == DownloadQueuePauseReason.userPaused;
    final pausedNow = s.headline == QueueHeadline.paused;

    return Container(
      key: const Key('activity-block'),
      margin: EdgeInsets.only(bottom: c.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CineRoleText(kicker, c.typeKicker, color: c.colorInk60),
          SizedBox(height: c.space2),
          if (cur != null) ...[
            CineRoleText(cur.seriesTitle, c.typeTitle, maxLines: 2, overflow: TextOverflow.ellipsis),
            SizedBox(height: c.space1),
            CineRoleText(
              pageFolio(
                chapter: cur.chapterLabel,
                done: cur.pageDone,
                total: cur.pageTotal,
                novel: cur.kind.isNovel,
                audio: cur.kind.isAudio,
              ),
              c.typeFolio,
              color: c.colorInk60,
            ),
            SizedBox(height: c.space2),
            if (cur.pageTotal > 0 && !cur.kind.isNovelSide)
              CineRuleProgress(value: cur.pageDone / cur.pageTotal, semanticLabel: 'This chapter')
            else if (s.headline == QueueHeadline.downloading)
              const CineIndeterminateRule(),
            if (s.alongside > 0) ...[
              SizedBox(height: c.space2),
              CineRoleText(
                '${s.alongside} more ${s.alongside == 1 ? 'chapter' : 'chapters'} downloading alongside',
                c.typeCaption,
                color: c.colorInk60,
              ),
            ],
            if (s.seriesTotal > 0) ...[
              SizedBox(height: c.space3),
              CineRoleText('${s.seriesSaved} of ${s.seriesTotal} saved in this series', c.typeCaption, color: c.colorInk60),
              SizedBox(height: c.space1),
              CineRuleProgress(value: s.seriesSaved / s.seriesTotal, semanticLabel: 'This series'),
            ],
          ],
          if (note != null) ...[
            SizedBox(height: c.space3),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'NOTE  ', style: CineText.style(context, c.typeKicker).copyWith(color: c.colorSpot)),
                  TextSpan(text: note, style: CineText.style(context, c.typeCaption).copyWith(color: c.colorInk60)),
                ],
              ),
            ),
          ],
          SizedBox(height: c.space3),
          Wrap(
            spacing: c.space2,
            runSpacing: c.space2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (userPaused)
                CineButton(
                  label: 'Resume all',
                  variant: CineButtonVariant.secondary,
                  size: CineButtonSize.sm,
                  onPressed: () {
                    cineFeedback(context, HapticEvent.downloadStart);
                    _q.resume();
                  },
                )
              else if (!pausedNow || s.pauseReason == DownloadQueuePauseReason.backgrounded)
                CineButton(
                  label: 'Pause all',
                  variant: CineButtonVariant.secondary,
                  size: CineButtonSize.sm,
                  onPressed: _q.pause,
                ),
              if (s.pauseReason == DownloadQueuePauseReason.cap && widget.onStorageSettings != null)
                CineButton(
                  label: 'Storage settings',
                  variant: CineButtonVariant.secondary,
                  size: CineButtonSize.sm,
                  onPressed: widget.onStorageSettings,
                ),
              CineButton(label: 'Cancel all', variant: CineButtonVariant.quiet, size: CineButtonSize.sm, onPressed: _cancelAll),
              CineButton(
                label: _open ? 'Hide queue' : 'Show queue ${superscript(queue.length)}',
                variant: CineButtonVariant.quiet,
                size: CineButtonSize.sm,
                onPressed: () => setState(() => _open = !_open),
              ),
            ],
          ),
          if (_open) ...[
            SizedBox(height: c.space2),
            QueueRows(
              rows: queue,
              paused: pausedNow,
              onRetry: (r) => unawaited(_q.retryChapter(r.identity)),
              onRemove: (r) => unawaited(_q.cancelChapter(r.identity)),
            ),
          ],
          SizedBox(height: c.space3),
          CineRoleText(kForegroundNote, c.typeCaption, color: c.colorInk60),
        ],
      ),
    );
  }
}
