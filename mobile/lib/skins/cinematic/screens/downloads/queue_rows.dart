import 'package:flutter/material.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/models/saved_chapter.dart';
import 'package:manhwamaniacs/features/downloads/utils/download_mark.dart';
import 'package:manhwamaniacs/features/downloads/utils/queue_summary.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_download_mark.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_icon_button.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The expanded queue under Activity: one row per chapter still owed (queued, running, failed).
class QueueRows extends StatelessWidget {
  const QueueRows({super.key, required this.rows, required this.onRetry, required this.onRemove, this.paused = false});
  final List<SavedChapter> rows;
  final void Function(SavedChapter) onRetry;
  final void Function(SavedChapter) onRemove;
  final bool paused;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Column(
      key: const Key('queue-rows'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final r in rows)
          Container(
            key: ValueKey('queue-${r.rowId}'),
            constraints: const BoxConstraints(minHeight: 56),
            decoration: BoxDecoration(border: Border(bottom: c.ruleHair)),
            child: Row(
              children: [
                Padding(
                  padding: EdgeInsets.only(right: c.space3),
                  child: _Mark(row: r, paused: paused),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: c.space2),
                        child: CineRoleText('${r.seriesTitle ?? r.seriesKey} · ${chapterLabelOf(r)}', c.typeTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: c.space2),
                        child: CineRoleText(
                          switch (r.state) {
                            DownloadChapterState.queued => 'Waiting',
                            DownloadChapterState.downloading => 'Downloading',
                            DownloadChapterState.failed => 'Failed — ${r.error ?? 'unknown error'}',
                            DownloadChapterState.complete => 'Saved',
                          },
                          c.typeCaption,
                          color: r.state == DownloadChapterState.failed ? c.colorProof : c.colorInk60,
                        ),
                      ),
                    ],
                  ),
                ),
                if (r.state == DownloadChapterState.failed)
                  CineButton(
                    label: 'Retry',
                    variant: CineButtonVariant.quiet,
                    size: CineButtonSize.sm,
                    onPressed: () => onRetry(r),
                  ),
                CineIconButton(
                  label: 'Remove ${chapterLabelOf(r).toLowerCase()} from queue',
                  role: CineIconRole.close,
                  onPressed: () => onRemove(r),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark({required this.row, required this.paused});
  final SavedChapter row;
  final bool paused;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final state = downloadMarkState(row.state, paused: paused);
    return Semantics(
      label: downloadMarkLabel(state),
      excludeSemantics: true,
      child: CustomPaint(
        size: const Size.square(16),
        painter: DownloadMarkPainter(state: state, ink: c.colorInk45, spot: c.colorSpot, set: c.colorSet, proof: c.colorProof),
      ),
    );
  }
}
