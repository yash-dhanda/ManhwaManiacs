/// The sentence-ticked scrubber (glass 8.16.2, E7): a 6 px track with the chapter's sentence boundaries as 1 px ticks (white at 0.22),
/// a `mono` time bubble over the thumb while dragged, "5:12" and "-18:40" at the ends. A drag previews and seeks on release;
/// one sentence per arrow key or accessibility step, 15 s per Page Up / Down.
library;

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/novels/controllers/narration_controller.dart';
import 'package:manhwamaniacs/features/novels/models/novel_audio.dart';
import 'package:manhwamaniacs/skins/glass/listen/listen_common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// Tick positions (0..1) of the sentence starts, the first excluded.
List<double> sentenceTicks(List<NovelAudioSegment> segments, int totalMs) {
  if (totalMs <= 0) return const [];
  return [for (final s in segments.skip(1)) (s.startMs / totalMs).clamp(0.0, 1.0)];
}

class GlassScrubber extends ConsumerStatefulWidget {
  const GlassScrubber({super.key});

  @override
  ConsumerState<GlassScrubber> createState() => _GlassScrubberState();
}

class _GlassScrubberState extends ConsumerState<GlassScrubber> {
  double? _drag;
  double _trackLen = 1;
  final FocusNode _focus = FocusNode(debugLabel: 'GlassScrubber');

  NarrationController get _n => ref.read(narrationControllerProvider.notifier);

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _commit(double f, int total) {
    final ms = (f.clamp(0.0, 1.0) * total).round();
    unawaited(_n.seek(Duration(milliseconds: ms)));
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(narrationControllerProvider.select((s) => s.target));
    if (t == null) return const SizedBox(height: 44);
    final total = t.audio.totalMs;
    final ticks = sentenceTicks(t.audio.segments, total);
    return ValueListenableBuilder<int>(
      valueListenable: _n.position,
      builder: (context, pos, _) {
        final f = _drag ?? (total <= 0 ? 0.0 : (pos / total).clamp(0.0, 1.0));
        final shownMs = (_drag != null ? _drag! * total : pos.toDouble()).round();
        return Semantics(
          slider: true,
          excludeSemantics: true,
          label: 'Position',
          value: listenSpokenClock(pos, total),
          increasedValue: 'Next sentence',
          decreasedValue: 'Previous sentence',
          onIncrease: () => unawaited(_n.stepSentence(1)),
          onDecrease: () => unawaited(_n.stepSentence(-1)),
          child: Focus(
            focusNode: _focus,
            onKeyEvent: (node, e) {
              if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
              final k = e.logicalKey;
              if (k == LogicalKeyboardKey.arrowRight || k == LogicalKeyboardKey.arrowUp) {
                unawaited(_n.stepSentence(1));
              } else if (k == LogicalKeyboardKey.arrowLeft || k == LogicalKeyboardKey.arrowDown) {
                unawaited(_n.stepSentence(-1));
              } else if (k == LogicalKeyboardKey.pageUp) {
                unawaited(_n.seekBy(const Duration(seconds: 15)));
              } else if (k == LogicalKeyboardKey.pageDown) {
                unawaited(_n.seekBy(const Duration(seconds: -15)));
              } else {
                return KeyEventResult.ignored;
              }
              return KeyEventResult.handled;
            },
            child: SizedBox(
              height: 44,
              child: Row(
                children: [
                  SizedBox(width: 44, child: GlassText(listenClock(shownMs), role: gt.typeMono, size: 12, onGlass: true, maxScale: 1.3, maxLines: 1)),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, c) {
                        _trackLen = c.maxWidth <= 0 ? 1 : c.maxWidth;
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapDown: (d) {
                            _focus.requestFocus();
                            _commit(d.localPosition.dx / _trackLen, total);
                          },
                          onHorizontalDragStart: (d) => setState(() => _drag = (d.localPosition.dx / _trackLen).clamp(0.0, 1.0)),
                          onHorizontalDragUpdate: (d) => setState(() => _drag = (d.localPosition.dx / _trackLen).clamp(0.0, 1.0)),
                          onHorizontalDragEnd: (_) {
                            final v = _drag;
                            setState(() => _drag = null);
                            if (v != null) _commit(v, total);
                          },
                          onHorizontalDragCancel: () => setState(() => _drag = null),
                          child: CustomPaint(
                            painter: _ScrubPainter(progress: f, ticks: ticks, dragging: _drag != null),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                if (_drag != null)
                                  Positioned(
                                    left: (f * _trackLen - 28).clamp(-8.0, _trackLen - 48.0),
                                    top: -10,
                                    width: 56,
                                    height: 26,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(color: gt.colorFill2, borderRadius: BorderRadius.circular(13)),
                                      child: Center(child: GlassText(listenClock(shownMs), role: gt.typeMono, size: 12, onGlass: true, maxLines: 1)),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 52, child: Align(alignment: Alignment.centerRight, child: GlassText(listenClock(total - shownMs, remaining: true), role: gt.typeMono, size: 12, onGlass: true, maxScale: 1.3, maxLines: 1))),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ScrubPainter extends CustomPainter {
  _ScrubPainter({required this.progress, required this.ticks, required this.dragging});
  final double progress;
  final List<double> ticks;
  final bool dragging;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final track = RRect.fromRectAndRadius(Rect.fromLTWH(0, cy - 3, size.width, 6), const Radius.circular(3));
    canvas.drawRRect(track, Paint()..color = gt.colorFill1);
    canvas.save();
    canvas.clipRRect(track);
    canvas.drawRect(Rect.fromLTWH(0, cy - 3, size.width * progress, 6), Paint()..color = gt.colorIris500);
    final tick = Paint()..color = const Color(0x38FFFFFF);
    for (final t in ticks) {
      canvas.drawRect(Rect.fromLTWH((t * size.width).floorToDouble(), cy - 3, 1, 6), tick);
    }
    canvas.restore();
    final x = size.width * progress;
    canvas.drawCircle(Offset(x, cy), dragging ? 10 : 8, Paint()..color = const Color(0xFFFFFFFF));
  }

  @override
  bool shouldRepaint(_ScrubPainter o) => o.progress != progress || o.dragging != dragging || o.ticks != ticks;
}
