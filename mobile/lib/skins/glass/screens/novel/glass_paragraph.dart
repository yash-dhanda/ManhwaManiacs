import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/features/novels/utils/speaker_slots.dart';

/// One decoration of a paragraph (D6). The painters ask the paragraph's [RenderParagraph] (read through a `GlobalKey` inside
/// `paint()`, after the child laid out) for the boxes of a run, so later steps add theirs: `mobile/37` appends the listen band and
/// the word underline to the ordered decoration list.
abstract class GlassParagraphDecoration {
  const GlassParagraphDecoration();

  /// Behind the text.
  void paintBehind(Canvas canvas, GlassParagraphGeometry g) {}

  /// Over the text.
  void paintFront(Canvas canvas, GlassParagraphGeometry g) {}
}

/// What a decoration may ask of one text piece. Offsets are paragraph offsets: a piece of the paragraph (the drop cap's two
/// pieces, a paged slice) maps them onto its own text.
class GlassParagraphGeometry {
  GlassParagraphGeometry._(this._p, this._start, this._end, this._shift, this.fontSize, this._baselineDrop);
  final RenderParagraph _p;
  final int _start, _end, _shift;
  final double fontSize;
  final double _baselineDrop;

  /// The tight boxes of paragraph offsets [start, end) that fall in this piece.
  List<Rect> boxes(int start, int end) {
    final s = math.max(start, _start), e = math.min(end, _end);
    if (e <= s) return const [];
    return [
      for (final b in _p.getBoxesForSelection(TextSelection(baseOffset: s - _start + _shift, extentOffset: e - _start + _shift)))
        if (b.right - b.left > 0.5) b.toRect(),
    ];
  }

  /// The alphabetic baseline of the line a tight [box] sits on.
  double baselineOf(Rect box) => box.bottom - _baselineDrop;

  /// The piece's size.
  Size get size => _p.size;
}

/// The distance from the baseline to a tight box's bottom for [style] (the descent the box includes).
double _tightDrop(TextStyle style) {
  final tp = TextPainter(text: TextSpan(text: 'Hg', style: style), textDirection: TextDirection.ltr, textScaler: TextScaler.noScaling)..layout();
  try {
    final m = tp.computeLineMetrics().first;
    final boxes = tp.getBoxesForSelection(const TextSelection(baseOffset: 0, extentOffset: 2));
    final bottom = boxes.isEmpty ? m.baseline + m.descent : boxes.map((b) => b.bottom).reduce(math.max);
    return bottom - m.baseline;
  } finally {
    tp.dispose();
  }
}

final Map<TextStyle, double> _drops = {};

/// The first-line indent (glass 3.4): 1.3 em, drawn as a leading `WidgetSpan` `SizedBox`, so selection and semantics skip it.
const double kGlassIndentEm = 1.3;

/// One `Text.rich` holding paragraph offsets [start, end) of [paragraph] (D6), inside a `CustomPaint` whose painters draw the
/// [decorations]. Attributed runs carry a tap recognizer ([onRunTap], the run chip of D10) and the "Mira: " semantics prefix.
class GlassTextPiece extends StatefulWidget {
  const GlassTextPiece({
    super.key,
    required this.paragraph,
    required this.style,
    this.start = 0,
    int? end,
    this.align = TextAlign.start,
    this.indent = false,
    this.runs = const [],
    this.decorations = const [],
    this.onRunTap,
    this.locale,
    this.repaint,
    this.textKey,
  }) : end = end ?? -1;

  final String paragraph;
  final TextStyle style;
  final int start;
  final int end;
  final TextAlign align;
  final bool indent;
  final List<SpeakerRun> runs;
  final List<GlassParagraphDecoration> decorations;
  final void Function(SpeakerRun run, Rect globalRect)? onRunTap;
  final Locale? locale;

  /// Repaints the decorations without a rebuild (a moving listen band).
  final Listenable? repaint;

  /// The text's key (the menu finds "the paragraph under the press" through it, F2).
  final GlobalKey? textKey;

  int get endOffset => end < 0 ? paragraph.length : end;

  @override
  State<GlassTextPiece> createState() => _GlassTextPieceState();
}

class _GlassTextPieceState extends State<GlassTextPiece> {
  final GlobalKey _own = GlobalKey();
  final List<TapGestureRecognizer> _recognizers = [];

  GlobalKey get _key => widget.textKey ?? _own;

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  Rect _runRect(SpeakerRun run) {
    final ro = _key.currentContext?.findRenderObject();
    if (ro is! RenderParagraph || !ro.hasSize) return Rect.zero;
    final s = math.max(run.start, widget.start), e = math.min(run.end, widget.endOffset);
    final shift = widget.indent ? 1 - widget.start : -widget.start;
    final boxes = ro.getBoxesForSelection(TextSelection(baseOffset: s + shift, extentOffset: e + shift));
    if (boxes.isEmpty) return Rect.zero;
    final first = boxes.first.toRect();
    return first.shift(ro.localToGlobal(Offset.zero));
  }

  InlineSpan _span() {
    _disposeRecognizers();
    final text = widget.paragraph;
    final start = widget.start, end = widget.endOffset;
    final children = <InlineSpan>[];
    if (widget.indent) {
      children.add(WidgetSpan(alignment: PlaceholderAlignment.baseline, baseline: TextBaseline.alphabetic, child: SizedBox(width: kGlassIndentEm * (widget.style.fontSize ?? 16))));
    }
    var at = start;
    for (final r in widget.runs) {
      final s = math.max(r.start, start), e = math.min(r.end, end);
      if (e <= s) continue;
      if (s > at) children.add(TextSpan(text: text.substring(at, s)));
      final rec = widget.onRunTap == null ? null : (TapGestureRecognizer()..onTap = () => widget.onRunTap!(r, _runRect(r)));
      if (rec != null) _recognizers.add(rec);
      final piece = text.substring(s, e);
      children.add(TextSpan(text: piece, recognizer: rec, semanticsLabel: s == r.start ? '${r.name}: $piece' : piece));
      at = e;
    }
    if (at < end) children.add(TextSpan(text: text.substring(at, end)));
    return TextSpan(style: widget.style, children: children, locale: widget.locale);
  }

  @override
  Widget build(BuildContext context) {
    final drop = _drops.putIfAbsent(widget.style, () => _tightDrop(widget.style));
    final text = Text.rich(
      _span(),
      key: _key,
      textAlign: widget.align,
      textScaler: TextScaler.noScaling,
      locale: widget.locale,
    );
    if (widget.decorations.isEmpty) return text;
    GlassParagraphGeometry? geometry() {
      final ro = _key.currentContext?.findRenderObject();
      if (ro is! RenderParagraph || !ro.hasSize) return null;
      return GlassParagraphGeometry._(ro, widget.start, widget.endOffset, widget.indent ? 1 : 0, widget.style.fontSize ?? 16, drop);
    }

    return CustomPaint(
      painter: _DecorationPainter(geometry, widget.decorations, front: false, repaint: widget.repaint),
      foregroundPainter: _DecorationPainter(geometry, widget.decorations, front: true, repaint: widget.repaint),
      child: text,
    );
  }
}

class _DecorationPainter extends CustomPainter {
  _DecorationPainter(this.geometry, this.decorations, {required this.front, Listenable? repaint}) : super(repaint: repaint);
  final GlassParagraphGeometry? Function() geometry;
  final List<GlassParagraphDecoration> decorations;
  final bool front;

  @override
  void paint(Canvas canvas, Size size) {
    final g = geometry();
    if (g == null) return;
    for (final d in decorations) {
      front ? d.paintFront(canvas, g) : d.paintBehind(canvas, g);
    }
  }

  @override
  bool shouldRepaint(_DecorationPainter old) => !listEquals(old.decorations, decorations);
}

/// The paragraph's text with its runs' names, for a merged semantics label ("Mira: " before each attributed run, D9).
String semanticsWithSpeakers(String text, List<SpeakerRun> runs) {
  if (runs.isEmpty) return text;
  final b = StringBuffer();
  var at = 0;
  for (final r in runs) {
    if (r.start < at || r.end > text.length) continue;
    b
      ..write(text.substring(at, r.start))
      ..write('${r.name}: ')
      ..write(text.substring(r.start, r.end));
    at = r.end;
  }
  b.write(text.substring(at));
  return b.toString();
}
