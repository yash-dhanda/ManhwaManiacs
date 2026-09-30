import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/models/downloaded_series_group.dart';
import 'package:manhwamaniacs/features/downloads/models/saved_chapter.dart';
import 'package:manhwamaniacs/features/downloads/providers/active_download_queue_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloaded_series_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/storage_settings_provider.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/downloads/utils/queue_summary.dart';
import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/confirm_alert.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/icon_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/liquid_progress.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/reorder_list.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/row_shell.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/lens_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/object_lens.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/library_common.dart' show roleButtonIcon;
import 'package:manhwamaniacs/skins/glass/skin_glass.dart' show GlassTwin;

const String kForegroundNote = 'Downloads run while ManhwaManiacs is open; leaving pauses them and coming back picks up where they stopped.';

/// The pause reason line with its clearing behaviour (glass 8.22): null when the queue clears itself without a word.
String? queuePauseLine(QueueSummary s, {required String cap, required String noun, DateTime? now}) {
  final wait = now == null ? null : s.pacedSecondsLeft(now);
  if (wait != null) return 'Waiting $wait s: the server is pacing downloads';
  if (s.signedOut) return 'Signed out';
  return switch (s.pauseReason) {
    DownloadQueuePauseReason.userPaused => 'Paused by you',
    DownloadQueuePauseReason.backgrounded => 'Paused while ManhwaManiacs was in the background',
    DownloadQueuePauseReason.freeSpaceFloor => 'Paused: this $noun is almost full. Downloads stop before the last 1.5 GB.',
    DownloadQueuePauseReason.cap => 'Paused: downloads filled your $cap limit.',
    _ => null,
  };
}

/// The Queue tab (glass 8.22): the active panel with pause and resume and Cancel all, the current chapter block, the pause reasons
/// with their actions, and the queue rows reorderable by drag (`moveInQueue`).
class GlassQueueTab extends ConsumerStatefulWidget {
  const GlassQueueTab({super.key, required this.onStorageSettings, this.summaryOverride, this.rowsOverride});
  final VoidCallback onStorageSettings;

  /// Captures: a fixed summary and rows.
  final QueueSummary? summaryOverride;
  final List<SavedChapter>? rowsOverride;

  @override
  ConsumerState<GlassQueueTab> createState() => _GlassQueueTabState();
}

class _GlassQueueTabState extends ConsumerState<GlassQueueTab> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  DownloadQueueController get _q => ref.read(downloadQueueControllerProvider.notifier);

  Future<void> _cancelAll(Rect from) async {
    final ok = await confirmAlert(context, title: 'Cancel all downloads?', body: 'Everything queued, downloading or failed is dropped. Finished chapters stay.', confirmLabel: 'Cancel all', destructive: true, sourceRect: from);
    if (ok) await _q.cancelAll();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(downloadQueueControllerProvider);
    final raw = widget.rowsOverride ?? ref.watch(activeDownloadQueueProvider).valueOrNull ?? const <SavedChapter>[];
    final all = <SavedChapter>[for (final g in ref.watch(downloadedSeriesProvider).valueOrNull ?? const <DownloadedSeriesGroup>[]) ...g.chapters];
    final rows = widget.rowsOverride != null ? raw : ref.read(downloadQueueControllerProvider.notifier).applyQueueOrder(raw);
    final s = widget.summaryOverride ?? summariseQueue(state, rows, all);
    final now = ref.watch(clockProvider)();
    final cap = ref.watch(storageCapProvider).label;
    final noun = MediaQuery.sizeOf(context).shortestSide >= 600 ? 'tablet' : 'phone';
    if (s == null && rows.isEmpty) {
      return Column(children: [
        const SizedBox(height: 24),
        const GlassObjectLens(situation: LensSituation.nothingDownloaded, title: 'Nothing in the queue', description: 'Chapters you download wait here until they are saved.', placement: GlassLensPlacement.inline),
        Padding(padding: const EdgeInsets.only(top: 16), child: GlassLabel(kForegroundNote, role: gt.typeFootnote, color: gt.colorLabel3, maxLines: 4)),
      ],);
    }
    final headline = s == null ? 'Waiting to start' : switch (s.headline) { QueueHeadline.downloading => 'Downloading', QueueHeadline.waiting => 'Waiting to start', QueueHeadline.paused => 'Paused' };
    final userPaused = state.pauseReason == DownloadQueuePauseReason.userPaused;
    final line = s == null ? null : queuePauseLine(s, cap: cap, noun: noun, now: now);
    final cur = s?.current;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0x9E131317), borderRadius: BorderRadius.circular(26), border: Border.all(color: const Color(0x38FFFFFF), width: 0.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Semantics(header: true, child: GlassLabel(headline, role: gt.typeFootnote, wght: 600, upper: true, color: gt.colorLabel2)),
          if (cur != null) ...[
            const SizedBox(height: 8),
            GlassLabel(cur.seriesTitle, role: gt.typeHeadline, maxLines: 2),
            GlassLabel(
              cur.kind.isAudio ? 'Fetching the audio…' : (cur.kind.isNovel ? 'Fetching the text…' : (cur.pageTotal <= 0 ? 'Reading chapter details…' : '${cur.chapterLabel[0]}${cur.chapterLabel.substring(1).toLowerCase()} · page ${cur.pageDone.clamp(0, cur.pageTotal)} of ${cur.pageTotal}')),
              role: gt.typeFootnote,
              color: gt.colorLabel2,
            ),
            if (cur.pageTotal > 0 && !cur.kind.isNovelSide) Padding(padding: const EdgeInsets.only(top: 8), child: ClipRRect(borderRadius: BorderRadius.circular(3), child: DecoratedBox(decoration: BoxDecoration(color: gt.colorFill2), child: LiquidProgress(value: cur.pageDone / cur.pageTotal, height: 6)))),
            if ((s?.alongside ?? 0) > 0) Padding(padding: const EdgeInsets.only(top: 8), child: GlassLabel('${s!.alongside} more ${s.alongside == 1 ? 'chapter' : 'chapters'} downloading alongside', role: gt.typeCaption1, color: gt.colorLabel3)),
            if ((s?.seriesTotal ?? 0) > 0) Padding(padding: const EdgeInsets.only(top: 4), child: GlassLabel('${s!.seriesSaved} of ${s.seriesTotal} saved in this series', role: gt.typeCaption1, color: gt.colorLabel3)),
          ],
          if (line != null) Padding(padding: const EdgeInsets.only(top: 12), child: Semantics(liveRegion: true, child: GlassLabel(line, role: gt.typeSubhead, color: gt.colorWarning, maxLines: 3))),
          const SizedBox(height: 12),
          Builder(builder: (context) {
            Rect rect() {
              final ro = context.findRenderObject();
              return ro is RenderBox && ro.attached ? ro.localToGlobal(Offset.zero) & ro.size : Rect.zero;
            }

            return Wrap(spacing: 8, runSpacing: 8, children: [
              if (userPaused) GlassButton(label: 'Resume', variant: GlassButtonVariant.primary, onPressed: _q.resume) else GlassButton(label: 'Pause', onPressed: _q.pause),
              if (s?.pauseReason == DownloadQueuePauseReason.cap) GlassButton(label: 'Storage settings', onPressed: widget.onStorageSettings),
              GlassButton(label: 'Cancel all', variant: GlassButtonVariant.plain, onPressed: () => unawaited(_cancelAll(rect()))),
            ],);
          },),
        ],),
      ),
      const SizedBox(height: 16),
      if (rows.isNotEmpty)
        GlassReorderList<SavedChapter>(
          items: rows,
          nameOf: (c) => '${c.seriesTitle ?? c.seriesKey} ${chapterLabelOf(c)}',
          onReorder: (from, to) => unawaited(_q.moveInQueue(rows[from].identity, to)),
          itemBuilder: (context, c, i, info) => _QueueRow(chapter: c, paused: state.isPaused),
        ),
      Padding(padding: const EdgeInsets.only(top: 16, bottom: 8), child: GlassLabel(kForegroundNote, role: gt.typeFootnote, color: gt.colorLabel3, maxLines: 4)),
    ],);
  }
}

class _QueueRow extends ConsumerWidget {
  const _QueueRow({required this.chapter, required this.paused});
  final SavedChapter chapter;
  final bool paused;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = chapter;
    final q = ref.read(downloadQueueControllerProvider.notifier);
    final st = ref.watch(downloadQueueControllerProvider);
    final lead = st.currentChapter == c.identity;
    final text = switch (c.state) {
      DownloadChapterState.queued => c.kind.isAudio ? 'Fetching the audio…' : (c.kind.isNovel ? 'Fetching the text…' : 'Waiting'),
      DownloadChapterState.downloading => c.kind.isNovelSide ? (c.kind.isAudio ? 'Fetching the audio…' : 'Fetching the text…') : (lead && st.pageTotal > 0 ? 'page ${st.pagesDone} of ${st.pageTotal}' : 'Downloading'),
      DownloadChapterState.failed => 'Failed: ${c.error ?? 'unknown error'}',
      DownloadChapterState.complete => 'Saved',
    };
    return GlassRowShell(
      semanticsLabel: '${c.seriesTitle ?? c.seriesKey}, ${chapterLabelOf(c)}, $text',
      minHeight: 64,
      builder: (context, stacked, info) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              GlassLabel('${c.seriesTitle ?? c.seriesKey} · ${chapterLabelOf(c)}', role: gt.typeBody),
              GlassLabel(text, role: gt.typeFootnote, color: c.state == DownloadChapterState.failed ? gt.colorDanger : gt.colorLabel2, maxLines: 2),
            ],),
          ),
          if (c.state == DownloadChapterState.failed) GlassButton(label: 'Retry', variant: GlassButtonVariant.plain, size: GlassButtonSize.small, onPressed: () => unawaited(q.retryChapter(c.identity))),
          GlassIconButton(icon: roleButtonIcon(GlassIconRole.close), label: 'Remove ${chapterLabelOf(c)} from the queue', kind: GlassIconButtonKind.row, twin: GlassTwin.content, onPressed: () => unawaited(q.cancelChapter(c.identity))),
        ],),
      ),
    );
  }
}
