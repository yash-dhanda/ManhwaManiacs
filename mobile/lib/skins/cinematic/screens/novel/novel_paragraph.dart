import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:manhwamaniacs/features/novels/engine/novel_paragraph_layout.dart';
import 'package:manhwamaniacs/features/novels/models/novel_typography.dart';
import 'package:manhwamaniacs/features/novels/utils/speaker_slots.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/listen/follow_along.dart' show sweepRects;
import 'package:manhwamaniacs/skins/cinematic/stock.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// A stretch of a paragraph drawn behind and under its text: the speaker tint today, `mobile/15`'s
/// Listen band and spoken-word underline next. Offsets are UTF-16 offsets into the paragraph.
///
/// Painted in order: every [fill] first, then the text, then every [underline] stroke.
class NovelDecoration {
  const NovelDecoration({
    required this.start,
    required this.end,
    this.fill,
    this.underline,
    this.dotted = false,
    this.speaker,
    this.sweep = 1,
  });

  final int start, end;

  /// How much of the [fill] is drawn, 0-1, in reading order along the run's line boxes: the
  /// Listen band sweeps in left to right, line after line (cinematic 4.5, Highlight sweep).
  final double sweep;

  /// Behind the text, over the run's boxes.
  final Color? fill;

  /// A 2 px stroke 0.18em below the baseline of each line the run covers.
  final Color? underline;

  /// The stroke is 2 px on, 2 px off (a slot 11+ reuse).
  final bool dotted;

  /// The speaker this run belongs to; the semantics label carries `Name: ` before it.
  final String? speaker;
}

/// The colour of speaker slot [slot] (1-10).
Color speakerColor(CineTokens t, int slot) => switch (slot) {
      1 => t.colorSpeaker1,
      2 => t.colorSpeaker2,
      3 => t.colorSpeaker3,
      4 => t.colorSpeaker4,
      5 => t.colorSpeaker5,
      6 => t.colorSpeaker6,
      7 => t.colorSpeaker7,
      8 => t.colorSpeaker8,
      9 => t.colorSpeaker9,
      _ => t.colorSpeaker10,
    };

/// The tints of [runs]: 12 % fill, 70 % alpha 2 px underline (dotted from the 11th speaker).
List<NovelDecoration> speakerDecorations(CineTokens t, List<SpeakerRun> runs) => [
      for (final r in runs)
        NovelDecoration(
          start: r.start,
          end: r.end,
          fill: speakerColor(t, r.slot).withValues(alpha: 0.12),
          underline: speakerColor(t, r.slot).withValues(alpha: 0.7),
          dotted: r.dotted,
          speaker: r.name,
        ),
    ];

/// The paragraph as a screen reader hears it: `Name: ` before each attributed run.
String novelSemanticsLabel(String text, List<NovelDecoration> decorations) {
  final named = [for (final d in decorations) if (d.speaker != null) d]..sort((a, b) => a.start.compareTo(b.start));
  if (named.isEmpty) return text;
  final out = StringBuffer();
  var at = 0;
  for (final d in named) {
    if (d.start < at || d.start > text.length) continue;
    out
      ..write(text.substring(at, d.start))
      ..write('${d.speaker}: ');
    at = d.start;
  }
  out.write(text.substring(at));
  return out.toString();
}

/// One paragraph of the body, painted by a `CustomPainter` over its cached
/// [NovelParagraphLayout] (cinematic 8.15.2). The face, size and leading come from [type]; the
/// text is [stock] ink. A 450 ms press on a decorated run calls [onSpeakerPress].
class NovelParagraph extends StatefulWidget {
  const NovelParagraph({
    super.key,
    required this.text,
    required this.type,
    required this.width,
    required this.stock,
    this.indent = false,
    this.dropCap = false,
    this.decorations = const [],
    this.onSpeakerPress,
  });

  final String text;
  final NovelType type;
  final double width;
  final CineStockColors stock;
  final bool indent, dropCap;
  final List<NovelDecoration> decorations;

  /// Called with the speaker's name and the global position of the press.
  final void Function(String speaker, Offset globalPosition)? onSpeakerPress;

  @override
  State<NovelParagraph> createState() => _NovelParagraphState();
}

class _NovelParagraphState extends State<NovelParagraph> {
  NovelParagraphLayout? _layout;
  Object? _layoutKey;

  NovelParagraphLayout get layout {
    final key = Object.hash(widget.text, widget.type, widget.width, widget.stock.ink, widget.indent, widget.dropCap);
    if (_layout == null || _layoutKey != key) {
      _layout?.dispose();
      _layoutKey = key;
      _layout = NovelParagraphLayout(
        text: widget.text,
        type: widget.type,
        width: widget.width,
        ink: widget.stock.ink,
        indent: widget.indent,
        dropCap: widget.dropCap,
      );
    }
    return _layout!;
  }

  @override
  void dispose() {
    _layout?.dispose();
    super.dispose();
  }

  void _press(LongPressStartDetails d) {
    final cb = widget.onSpeakerPress;
    if (cb == null) return;
    final box = context.findRenderObject();
    if (box is! RenderBox) return;
    final offset = layout.offsetAt(box.globalToLocal(d.globalPosition));
    if (offset == null) return;
    for (final r in widget.decorations) {
      if (r.speaker != null && offset >= r.start && offset < r.end) {
        cb(r.speaker!, d.globalPosition);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = layout;
    final gestures = widget.onSpeakerPress == null || widget.decorations.every((d) => d.speaker == null)
        ? const <Type, GestureRecognizerFactory>{}
        : <Type, GestureRecognizerFactory>{
            LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
              () => LongPressGestureRecognizer(duration: const Duration(milliseconds: 450)),
              (r) => r.onLongPressStart = _press,
            ),
          };
    final gap = widget.type.paragraphSpacing * widget.type.fontSize;
    return Padding(
      padding: EdgeInsets.only(bottom: gap),
      child: Semantics(
        label: novelSemanticsLabel(widget.text, widget.decorations),
        textDirection: TextDirection.ltr,
        excludeSemantics: true,
        child: RawGestureDetector(
          behavior: HitTestBehavior.translucent,
          gestures: gestures,
          child: CustomPaint(
            size: Size(widget.width, l.height),
            painter: NovelParagraphPainter(l, widget.decorations),
          ),
        ),
      ),
    );
  }
}

/// Paints the decoration fills, the text (and drop cap), then the decoration strokes.
class NovelParagraphPainter extends CustomPainter {
  NovelParagraphPainter(this.layout, this.decorations);

  final NovelParagraphLayout layout;
  final List<NovelDecoration> decorations;

  @override
  void paint(Canvas canvas, Size size) {
    for (final d in decorations) {
      final fill = d.fill;
      if (fill == null) continue;
      final paint = Paint()..color = fill;
      final boxes = layout.boxesFor(d.start, d.end);
      for (final box in d.sweep >= 1 ? boxes : sweepRects(boxes, d.sweep)) {
        canvas.drawRect(box, paint);
      }
    }
    layout.paintText(canvas, Offset.zero);
    for (final d in decorations) {
      final color = d.underline;
      if (color == null) continue;
      final paint = Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      for (final box in layout.boxesFor(d.start, d.end)) {
        final y = _baselineFor(box) + 0.18 * layout.type.fontSize + 1;
        if (d.dotted) {
          for (var x = box.left; x < box.right; x += 4) {
            canvas.drawLine(Offset(x, y), Offset(math.min(x + 2, box.right), y), paint);
          }
        } else {
          canvas.drawLine(Offset(box.left, y), Offset(box.right, y), paint);
        }
      }
    }
  }

  /// The baseline of the line [box] sits on (its centre falls between the line's top and bottom).
  double _baselineFor(Rect box) {
    final cy = box.center.dy;
    for (final l in layout.lines) {
      if (cy >= l.top - 0.5 && cy <= l.bottom + 0.5) return l.baseline;
    }
    return box.bottom - 0.25 * layout.type.fontSize;
  }

  @override
  bool shouldRepaint(NovelParagraphPainter old) => !identical(old.layout, layout) || old.decorations != decorations;
}

/// A scene break: a centred 32 px rule, 24 px above and below, excluded from semantics.
class NovelSceneBreak extends StatelessWidget {
  const NovelSceneBreak({super.key, required this.stock});
  final CineStockColors stock;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SizedBox(
          height: kNovelSceneBreakExtent,
          child: Center(child: SizedBox(width: 32, height: 1, child: ColoredBox(color: stock.muted))),
        ),
      );
}
