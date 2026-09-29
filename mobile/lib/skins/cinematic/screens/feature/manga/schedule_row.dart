import 'dart:async';

import 'package:flutter/material.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/downloads/utils/download_mark.dart';
import 'package:manhwamaniacs/features/sources/models/source_chapter_progress.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/features/sources/utils/chapter_date.dart';
import 'package:manhwamaniacs/features/sources/utils/chapter_label.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/phosphor.g.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_ambient.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_download_mark.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_states.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// The 20 px select-mode checkbox (§7.21): a 1 px `ink.45` outline; checked,
/// an `ink.100` fill with a `#000` 2 px square-capped check, filling in 120 ms.
class CineCheckbox extends StatelessWidget {
  const CineCheckbox({super.key, required this.checked, this.dimmed = false});
  final bool checked;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final t = cineOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: checked ? 1 : 0),
      duration: CineDur.snap,
      builder: (context, v, _) => CustomPaint(
        size: const Size.square(20),
        painter: _CheckPainter(
          v,
          outline: dimmed ? t.colorInk30 : t.colorInk45,
          fill: dimmed ? t.colorInk30 : t.colorInk100,
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter(this.v, {required this.outline, required this.fill});
  final double v;
  final Color outline, fill;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Color.lerp(const Color(0x00000000), fill, v)!,
    );
    canvas.drawRect(
      (Offset.zero & size).deflate(0.5),
      Paint()
        ..color = outline
        ..style = PaintingStyle.stroke,
    );
    if (v > 0.5) {
      canvas.drawPath(
        Path()
          ..moveTo(5, 10.5)
          ..lineTo(9, 14.5)
          ..lineTo(15.5, 6),
        Paint()
          ..color = const Color(0xFF000000)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.square,
      );
    }
  }

  @override
  bool shouldRepaint(_CheckPainter o) => o.v != v || o.outline != outline || o.fill != fill;
}

/// One chapter row of the CHAPTERS schedule (§7.16): 56 px minimum.
class ScheduleRow extends StatefulWidget {
  const ScheduleRow({
    super.key,
    required this.chapter,
    required this.progress,
    required this.downloadState,
    required this.selecting,
    required this.selected,
    required this.current,
    required this.highlighted,
    required this.onTap,
    required this.onLongPress,
    required this.onMenu,
    this.onSwipeRead,
    this.onMarkTap,
    this.onPress,
    this.onDwell,
    this.cursor = false,
    this.markProgress = 0,
    this.markPage,
    this.stale = false,
    this.paused = false,
    this.pauseReason,
  });

  final SourceChapterSummary chapter;
  final SourceChapterProgress? progress;
  final DownloadChapterState? downloadState;
  final bool selecting;
  final bool selected;
  final bool current;
  final bool highlighted;

  /// The J / K keyboard cursor sits here.
  final bool cursor;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onMenu;

  /// Null disables the swipe (offline, or select mode).
  final VoidCallback? onSwipeRead;
  final VoidCallback? onMarkTap;
  final VoidCallback? onPress;

  /// A hardware keyboard focused the row for 150 ms.
  final VoidCallback? onDwell;
  final double markProgress;
  final int? markPage;
  final bool stale;
  final bool paused;
  final DownloadQueuePauseReason? pauseReason;

  @override
  State<ScheduleRow> createState() => _ScheduleRowState();
}

class _ScheduleRowState extends State<ScheduleRow> {
  Timer? _dwell;

  @override
  void dispose() {
    _dwell?.cancel();
    super.dispose();
  }

  void _focus(bool f) {
    _dwell?.cancel();
    if (f && FocusManager.instance.highlightMode == FocusHighlightMode.traditional) {
      _dwell = Timer(const Duration(milliseconds: 150), () => widget.onDwell?.call());
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = cineOf(context);
    final ink = CineAmbient.of(context).ink;
    final c = widget.chapter;
    final label = chapterLabel(number: c.number, title: c.title);
    final n = c.number;
    final p = widget.progress;
    final read = p?.completed ?? false;
    final saved = widget.downloadState == DownloadChapterState.complete;
    final mark = downloadMarkState(
      widget.downloadState,
      stale: widget.stale,
      progress: widget.markProgress,
      paused: widget.paused,
    );
    final failed = mark is MarkFailed;
    final date = chapterDateLabel(c.releaseDate);
    final caption = [
      if (date != null) date,
      if (c.pageCount > 0) '${c.pageCount} PAGES',
    ].join(' · ');
    final text = read ? t.colorInk45 : t.colorInk100;
    final active = widget.current || widget.highlighted || widget.cursor;

    Widget row = Container(
      constraints: const BoxConstraints(minHeight: 56),
      decoration: BoxDecoration(
        color: widget.selected
            ? t.colorPaper3
            : active
                ? t.colorSpotWash
                : null,
        border: widget.selected ? Border(left: BorderSide(color: t.colorSpot, width: 2)) : null,
      ),
      padding: const EdgeInsets.only(left: 12),
      child: Row(
        children: [
          if (widget.selecting)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CineCheckbox(checked: widget.selected || saved, dimmed: saved),
            ),
          SizedBox(
            width: 56,
            child: Text(
              n == null ? '·' : (n % 1 == 0 ? n.toInt().toString() : n.toString()),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: ink,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.secondary ?? label.primary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16, color: text),
                ),
                if (caption.isNotEmpty || widget.current || failed)
                  Row(
                    children: [
                      if (widget.current)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          color: t.colorSpot,
                          child: const Text(
                            'READING',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: Color(0xFF000000),),
                          ),
                        ),
                      Flexible(
                        child: Text(
                          failed ? 'DOWNLOAD FAILED' : caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 0.8,
                            color: failed ? t.colorProof : t.colorInk60,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (p != null && !read && p.pageCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text('${p.page}/${p.pageCount}',
                  style: TextStyle(
                      fontSize: 12, fontFamily: 'IBM Plex Mono', color: t.colorSpot,),),
            )
          else if (read)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text('READ', style: TextStyle(fontSize: 10, color: t.colorInk45)),
            ),
          if (failed && widget.onMarkTap != null)
            TextButton(
              style: TextButton.styleFrom(minimumSize: const Size(44, 48)),
              onPressed: widget.onMarkTap,
              child: const Text('Retry'),
            ),
          CineDownloadMark(
            state: mark,
            page: widget.markPage,
            pageTotal: widget.markPage == null ? null : (widget.markProgress > 0 ? (widget.markPage! / widget.markProgress).round() : c.pageCount),
            reason: widget.pauseReason,
            onTap: widget.onMarkTap,
          ),
          if (!widget.selecting)
            IconButton(
              tooltip: 'Chapter options',
              constraints: const BoxConstraints(minWidth: 44, minHeight: 48),
              padding: EdgeInsets.zero,
              icon: const Icon(PhosphorRegular.dotsThree, size: 20),
              onPressed: widget.onMenu,
            )
          else
            const SizedBox(width: 8),
        ],
      ),
    );

    row = Semantics(
      button: true,
      selected: widget.selected,
      label: '${label.primary}${label.secondary != null ? ', ${label.secondary}' : ''}'
          '${read ? ', read' : ''}${widget.current ? ', reading' : ''}',
      child: Listener(
        onPointerDown: (_) => widget.onPress?.call(),
        child: InkWell(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          onFocusChange: _focus,
          child: CineFocusRing(child: row),
        ),
      ),
    );

    if (widget.onSwipeRead == null) return row;
    return Dismissible(
      key: ValueKey('row-${c.id}'),
      direction: DismissDirection.endToStart,
      dismissThresholds: const {DismissDirection.endToStart: 0.5},
      confirmDismiss: (_) async {
        widget.onSwipeRead!();
        return false;
      },
      background: const SizedBox.shrink(),
      secondaryBackground: Align(
        alignment: Alignment.centerRight,
        child: Container(
          width: 72,
          color: t.colorInk100,
          alignment: Alignment.center,
          child: const Text(
            'READ',
            style: TextStyle(
                color: Color(0xFF000000),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,),
          ),
        ),
      ),
      child: row,
    );
  }
}
