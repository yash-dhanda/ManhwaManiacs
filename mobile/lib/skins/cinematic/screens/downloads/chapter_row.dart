import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/models/saved_chapter.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/downloads/utils/download_mark.dart';
import 'package:manhwamaniacs/features/downloads/utils/queue_summary.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_download_mark.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_icon_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/dialogue/scan/scan_dialogue_button.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/downloads/downloads_copy.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// One chapter of an expanded series block (cinematic 7.16 standard row, 56 dp): the download
/// mark, `CH 12`, a status caption and the trailing actions. A left swipe past 50 % commits
/// the removal (the row springs back and reads `REMOVING…` until the 8 s window closes).
class DownloadChapterRow extends ConsumerWidget {
  const DownloadChapterRow({
    super.key,
    required this.chapter,
    required this.pending,
    required this.onOpen,
    required this.onRemove,
    required this.onSaveToFiles,
    required this.onRetry,
    this.focusNode,
    this.onArrow,
  });

  final SavedChapter chapter;
  final bool pending;
  final VoidCallback onOpen;
  final VoidCallback onRemove;
  final VoidCallback onSaveToFiles;
  final VoidCallback onRetry;
  final FocusNode? focusNode;

  /// ↓ (+1) and ↑ (-1) move through the block's rows.
  final void Function(int delta)? onArrow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.cine;
    final q = ref.watch(downloadQueueControllerProvider);
    final paused = q.isPaused && q.pauseReason != DownloadQueuePauseReason.none;
    final lead = q.currentChapter == chapter.identity;
    final progress = lead && q.pageTotal > 0 ? q.pagesDone / q.pageTotal : 0.0;
    final mark = downloadMarkState(chapter.state, progress: progress, paused: paused);
    final audio = chapter.kind.isAudio;
    final label = chapterLabelOf(chapter);
    final saved = chapter.state == DownloadChapterState.complete;
    final caption = pending
        ? 'REMOVING…'
        : switch (chapter.state) {
            DownloadChapterState.complete => 'SAVED · ${formatMb(chapter.bytes)}',
            DownloadChapterState.queued => 'QUEUED',
            DownloadChapterState.downloading => 'DOWNLOADING',
            DownloadChapterState.failed => 'FAILED — ${chapter.error ?? 'unknown error'}',
          };
    final captionColor = pending
        ? c.colorInk45
        : (chapter.state == DownloadChapterState.failed ? c.colorProof : c.colorInk60);
    final ocr = saved && !chapter.kind.isNovelSide;
    final removeLabel = audio ? 'Remove saved audio' : 'Remove ${label.toLowerCase().replaceFirst('ch ', 'chapter ')} from this phone';

    Widget row = Container(
      constraints: const BoxConstraints(minHeight: 56),
      decoration: BoxDecoration(border: Border(bottom: c.ruleHair)),
      child: Row(
        children: [
          CineDownloadMark(
            state: mark,
            reason: q.pauseReason,
            page: lead ? q.pagesDone : null,
            pageTotal: lead ? q.pageTotal : null,
            onTap: chapter.state == DownloadChapterState.failed ? onRetry : null,
          ),
          Expanded(
            child: CinePressable(
              enabled: saved && !pending,
              onTap: onOpen,
              hit: false,
              builder: (context, st) => Padding(
                padding: EdgeInsets.symmetric(vertical: c.space2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(child: CineRoleText(label, c.typeFolioLg, color: st.hovered || st.focused ? c.colorInk100 : c.colorInk80)),
                        if (audio) ...[
                          SizedBox(width: c.space2),
                          CineRoleText('· AUDIO', c.typeFolioLg, color: c.colorInk60),
                          SizedBox(width: c.space1),
                          CineGlyphIcon(CineGlyph.headphones, size: 16, color: c.colorInk60),
                        ],
                      ],
                    ),
                    CineRoleText(caption, c.typeCaption, color: captionColor),
                  ],
                ),
              ),
            ),
          ),
          if (ocr && !pending) ScanDialogueButton(chapter: chapter.identity, chapterNumber: chapter.chapterNumber),
          if (saved && !audio && !chapter.kind.isNovel && !pending)
            CineIconButton(label: 'Save chapter to Files', codepoint: 0xEAF0, onPressed: onSaveToFiles),
          CineIconButton(label: removeLabel, role: CineIconRole.delete, onPressed: pending ? null : onRemove),
        ],
      ),
    );

    row = Dismissible(
      key: ValueKey('swipe-${chapter.rowId}'),
      direction: pending ? DismissDirection.none : DismissDirection.endToStart,
      dismissThresholds: const {DismissDirection.endToStart: 0.5},
      movementDuration: const Duration(milliseconds: 504),
      resizeDuration: const Duration(milliseconds: 240),
      background: ExcludeSemantics(child: _Slab(color: c.colorProof)),
      secondaryBackground: ExcludeSemantics(child: _Slab(color: c.colorProof)),
      confirmDismiss: (_) async {
        cineFeedback(context, HapticEvent.deleteConfirm);
        onRemove();
        return false;
      },
      child: row,
    );

    return Focus(
      focusNode: focusNode,
      onKeyEvent: (node, e) {
        if (e is! KeyDownEvent) return KeyEventResult.ignored;
        final k = e.logicalKey;
        if (k == LogicalKeyboardKey.arrowDown) {
          onArrow?.call(1);
          return onArrow == null ? KeyEventResult.ignored : KeyEventResult.handled;
        }
        if (k == LogicalKeyboardKey.arrowUp) {
          onArrow?.call(-1);
          return onArrow == null ? KeyEventResult.ignored : KeyEventResult.handled;
        }
        if ((k == LogicalKeyboardKey.delete || k == LogicalKeyboardKey.backspace) && !pending) {
          onRemove();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Semantics(
        container: true,
        customSemanticsActions: {
          if (!pending) const CustomSemanticsAction(label: 'Remove'): onRemove,
        },
        child: row,
      ),
    );
  }
}

class _Slab extends StatelessWidget {
  const _Slab({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: 72,
        child: ColoredBox(
          color: color,
          child: Center(child: CineRoleText('Remove', c.typeLabel, color: const Color(0xFF000000), textAlign: TextAlign.center)),
        ),
      ),
    );
  }
}
