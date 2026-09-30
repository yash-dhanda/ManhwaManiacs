import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/icons/glass_glyphs.g.dart';
import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart' show GlassIconWeight;
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/download_state.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs_more.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/primitives/progress.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';

/// The per-chapter download control (glass 7.29): a 28 px visual in a `hitMin` hit area. Presentational: the caller maps
/// the shared store with [chapterDownloadView] and wires the handlers.
class GlassDownloadControl extends ConsumerStatefulWidget {
  const GlassDownloadControl({
    super.key,
    required this.view,
    required this.chapterLabel,
    this.onDownload,
    this.onCancel,
    this.onRemove,
    this.onExtractText,
    this.onSaveToFiles,
    this.quietDone = false,
    this.forceStates = GlassWidgetStates.none,
  });

  final ChapterDownloadView view;
  final String chapterLabel;
  final VoidCallback? onDownload;
  final VoidCallback? onCancel;
  final VoidCallback? onRemove;

  /// Only passed while the device OCR engine is available (8.0.8); null omits the item.
  final VoidCallback? onExtractText;

  /// Null until `mobile/29`'s `?sheet=save-files` registry exists; null omits the item.
  final VoidCallback? onSaveToFiles;

  /// A batch fires `download.done` once itself; the control then stays silent.
  final bool quietDone;
  final GlassWidgetStates forceStates;

  @override
  ConsumerState<GlassDownloadControl> createState() => _GlassDownloadControlState();
}

class _GlassDownloadControlState extends ConsumerState<GlassDownloadControl> {
  @override
  void didUpdateWidget(GlassDownloadControl old) {
    super.didUpdateWidget(old);
    final was = old.view.kind, now = widget.view.kind;
    if (was == now) return;
    if (now == ChapterDownloadKind.saved && !widget.quietDone) {
      glassFire(ref, HapticEvent.downloadDone);
      glassSound(ref, SoundEvent.downloadDone);
    }
    if (now == ChapterDownloadKind.failed) glassFire(ref, HapticEvent.downloadFail);
  }

  void _tap() {
    final v = widget.view;
    switch (v.kind) {
      case ChapterDownloadKind.none:
        glassFire(ref, HapticEvent.downloadStart);
        widget.onDownload?.call();
      case ChapterDownloadKind.queued:
      case ChapterDownloadKind.downloading:
        widget.onCancel?.call();
      case ChapterDownloadKind.incomplete:
      case ChapterDownloadKind.stale:
      case ChapterDownloadKind.failed:
      case ChapterDownloadKind.paused:
        glassFire(ref, HapticEvent.downloadStart);
        widget.onDownload?.call();
      case ChapterDownloadKind.saved:
        _menu();
    }
  }

  void _menu() {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    unawaited(showGlassMenu(
      context,
      anchor: box.localToGlobal(Offset.zero) & box.size,
      title: 'Downloaded chapter',
      entries: [
        GlassMenuEntry(label: 'Remove download', icon: GlassGlyph.trash.regular, destructive: true, onSelected: widget.onRemove),
        if (widget.onExtractText != null) GlassMenuEntry(label: 'Extract text', icon: GlassGlyph.magnifyingGlass.regular, onSelected: widget.onExtractText),
        if (widget.onSaveToFiles != null) GlassMenuEntry(label: 'Save to Files', icon: GlassGlyph.arrowSquareOut.regular, onSelected: widget.onSaveToFiles),
      ],
    ),);
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.view;
    final hit = GlassFrame.hitMin(context);
    final reduced = ref.watch(glassMotionPrefsProvider.select((m) => m.reduced));
    final host = GlassHost.of(context);
    Widget visual = _visual(v, reduced);
    if (host && v.kind != ChapterDownloadKind.queued && v.kind != ChapterDownloadKind.downloading) {
      visual = GlassBacking(size: 28, child: visual);
    }
    return GlassPressable(
      material: GlassMaterial.content,
      sink: 0.92,
      shape: const GlassShape.circle(),
      onTap: _tap,
      forceStates: widget.forceStates,
      semanticsLabel: downloadSemanticsLabel(v, widget.chapterLabel),
      builder: (context, info) => SizedBox(
        width: hit,
        height: hit,
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: reduced ? 150 : 260),
              switchInCurve: reduced ? Curves.linear : Curves.easeOutBack,
              transitionBuilder: (child, a) => reduced ? FadeTransition(opacity: a, child: child) : ScaleTransition(scale: a, child: FadeTransition(opacity: a, child: child)),
              child: KeyedSubtree(key: ValueKey(v.kind), child: Center(child: visual)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _visual(ChapterDownloadView v, bool reduced) => switch (v.kind) {
        ChapterDownloadKind.none => const GlyphIcon(GlassGlyph.cloudArrowDown, color: GlassColors.g800),
        ChapterDownloadKind.queued => GlassQueuedRing(animate: !reduced),
        ChapterDownloadKind.downloading => GlassRingProgress(value: v.progress, size: 22, stroke: 2.5, color: gt.colorIris500),
        ChapterDownloadKind.saved => Icon(GlassGlyphs.dropletFill, size: 22, color: gt.colorSuccess),
        ChapterDownloadKind.incomplete => SizedBox(
            width: 22,
            height: 22,
            child: Stack(clipBehavior: Clip.none, children: [
              Icon(GlassGlyphs.dropletFill, size: 22, color: gt.colorWarning),
              Positioned(right: -3, bottom: -3, child: DecoratedBox(decoration: const BoxDecoration(color: GlassColors.g0, shape: BoxShape.circle), child: GlyphIcon(GlassGlyph.warningCircle, size: 12, color: gt.colorWarning, weight: GlassIconWeight.bold))),
            ],),
          ),
        ChapterDownloadKind.paused => GlyphIcon(GlassGlyph28.pauseCircle, color: gt.colorWarning),
        ChapterDownloadKind.stale => GlyphIcon(GlassGlyph28.arrowsClockwise, color: gt.colorWarning),
        ChapterDownloadKind.failed => GlyphIcon(GlassGlyph.warningCircle, color: gt.colorDanger),
      };
}

/// A dashed 22 px ring in `g600`, one turn per 4 s (glass 4.10, Queued ring). Static under reduced motion.
class GlassQueuedRing extends StatefulWidget {
  const GlassQueuedRing({super.key, this.animate = true, this.size = 22});
  final bool animate;
  final double size;

  @override
  State<GlassQueuedRing> createState() => _GlassQueuedRingState();
}

class _GlassQueuedRingState extends State<GlassQueuedRing> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 4));

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.repeat();
  }

  @override
  void didUpdateWidget(GlassQueuedRing old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_c.isAnimating) _c.repeat();
    if (!widget.animate && _c.isAnimating) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(size: Size.square(widget.size), painter: _DashedRing(_c.value * 2 * math.pi)),
      );
}

class _DashedRing extends CustomPainter {
  _DashedRing(this.turn);
  final double turn;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = GlassColors.g600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final r = size.width / 2 - 1;
    const dashes = 10;
    for (var i = 0; i < dashes; i++) {
      final a = turn + i * 2 * math.pi / dashes;
      canvas.drawArc(Rect.fromCircle(center: size.center(Offset.zero), radius: r), a, 2 * math.pi / dashes * 0.55, false, p);
    }
  }

  @override
  bool shouldRepaint(_DashedRing old) => old.turn != turn;
}
