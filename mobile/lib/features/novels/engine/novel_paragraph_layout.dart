import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart' show WidgetSpan, SizedBox;
import 'package:manhwamaniacs/features/novels/models/novel_typography.dart';
import 'package:manhwamaniacs/features/novels/utils/novel_book.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// First-line indent, in ems (cinematic 8.15.2).
const double kNovelIndentEm = 1.3;

/// Height of a scene-break rule: 24 px above, the 1 px rule, 24 px below.
const double kNovelSceneBreakExtent = 24 + 1 + 24;

/// Whether paragraph [i] is set with a first-line indent: every paragraph except the first and the
/// one after a scene break.
bool novelParagraphIndents(List<String> paragraphs, int i) => i > 0 && !isSceneBreak(paragraphs[i - 1]) && !isSceneBreak(paragraphs[i]);

/// One laid-out line of a paragraph: UTF-16 offsets into the paragraph text (end exclusive,
/// including the trailing space) and its box in paragraph coordinates.
class NovelLine {
  const NovelLine({required this.start, required this.end, required this.top, required this.bottom, required this.baseline, required this.left, required this.right});
  final int start, end;
  final double top, bottom, baseline, left, right;
}

class _Block {
  _Block(this.painter, this.origin, this.globalStart, {this.clipBottom});
  final TextPainter painter;
  final Offset origin;

  /// Added to a painter offset to get an offset into the paragraph text.
  final int globalStart;

  /// When set, only the part of the painter above this y is painted and hit-tested (the first
  /// three lines of a drop-cap paragraph, laid out narrow).
  final double? clipBottom;
}

/// The one layout of a paragraph, shared by the painter (`NovelParagraph`) and the paginator, so a
/// page can never clip a line (cinematic 8.15.2, 8.15.4).
///
/// A `TextPainter` per block with `TextScaler.noScaling`, the face style of [type], `textAlign`
/// from `type.justify`, laid out at [width]. A drop-cap paragraph lays its first three lines at
/// the width minus the cap and its gap and the rest at full width; an indented one leads with a
/// placeholder.
///
/// Flutter has no automatic hyphenation, so a justified paragraph justifies without hyphens.
class NovelParagraphLayout {
  NovelParagraphLayout({
    required this.text,
    required this.type,
    required this.width,
    required this.ink,
    this.indent = false,
    this.dropCap = false,
  }) {
    _build();
  }

  final String text;
  final NovelType type;
  final double width;
  final Color ink;

  /// Whether the paragraph asks for a first-line indent (dropped when `paragraphSpacing` > 0).
  final bool indent;

  /// Whether the paragraph asks for a drop cap (only granted when [splitDropCap] allows it).
  final bool dropCap;

  final List<_Block> _blocks = [];
  final List<NovelLine> lines = [];
  late final double height;

  /// The drop cap, when granted: its painter and where it is painted.
  TextPainter? _cap;
  Offset _capOrigin = Offset.zero;

  bool get hasDropCap => _cap != null;

  /// The body line height in px.
  double get lineHeightPx => type.fontSize * type.lineHeight;

  TextPainter _painter(InlineSpan span, double w, {List<PlaceholderDimensions>? placeholders}) {
    final tp = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
      textAlign: type.justify ? TextAlign.justify : TextAlign.left,
    );
    if (placeholders != null) tp.setPlaceholderDimensions(placeholders);
    tp.layout(maxWidth: w);
    return tp;
  }

  void _build() {
    final style = type.style(ink);
    final dc = dropCap ? splitDropCap(text) : null;
    if (dc != null && text.startsWith(dc.initial)) {
      _buildDropCap(style, dc);
    } else if (indent && type.paragraphSpacing == 0) {
      final px = kNovelIndentEm * type.fontSize;
      final tp = _painter(
        TextSpan(style: style, children: [const WidgetSpan(child: SizedBox()), TextSpan(text: text)]),
        width,
        placeholders: [PlaceholderDimensions(size: Size(px, 1), alignment: ui.PlaceholderAlignment.baseline, baseline: TextBaseline.alphabetic, baselineOffset: 0)],
      );
      _blocks.add(_Block(tp, Offset.zero, -1));
      height = tp.height;
    } else {
      final tp = _painter(TextSpan(style: style, text: text), width);
      _blocks.add(_Block(tp, Offset.zero, 0));
      height = tp.height;
    }
    for (final b in _blocks) {
      _addLines(b);
    }
  }

  void _buildDropCap(TextStyle style, DropCap dc) {
    final capStyle = CineType.dropcap(lineHeightPx).copyWith(color: ink);
    final cap = TextPainter(text: TextSpan(text: dc.initial, style: capStyle), textDirection: TextDirection.ltr, textScaler: TextScaler.noScaling)..layout();
    final gap = 0.08 * (capStyle.fontSize ?? type.fontSize * 3);
    final indentX = cap.width + gap;
    final narrowW = math.max(1.0, width - indentX);
    final rest = dc.rest;
    final narrow = _painter(TextSpan(style: style, text: rest), narrowW);
    final metrics = narrow.computeLineMetrics();
    final start = dc.initial.length;
    if (metrics.length <= 3) {
      _blocks.add(_Block(narrow, Offset(indentX, 0), start));
      height = math.max(narrow.height, 3 * lineHeightPx);
      final third = _lineBox(narrow, metrics.length - 1);
      _place(cap, third.baseline);
      return;
    }
    // Where the third line ends and how low it reaches.
    final l3 = _lineBox(narrow, 2);
    final cut = l3.end;
    final tail = _painter(TextSpan(style: style, text: rest.substring(cut)), width);
    _blocks
      ..add(_Block(narrow, Offset(indentX, 0), start, clipBottom: l3.bottom))
      ..add(_Block(tail, Offset(0, l3.bottom), start + cut));
    height = l3.bottom + tail.height;
    _place(cap, l3.baseline);
  }

  void _place(TextPainter cap, double thirdBaseline) {
    _cap = cap;
    _capOrigin = Offset(0, thirdBaseline - cap.computeDistanceToActualBaseline(TextBaseline.alphabetic));
  }

  /// Line [n] of [tp]: its offsets, extent and baseline, in [tp] coordinates.
  ({int start, int end, double top, double bottom, double baseline}) _lineBox(TextPainter tp, int n) {
    final metrics = tp.computeLineMetrics();
    var start = 0;
    for (var i = 0; i <= n && i < metrics.length; i++) {
      final range = tp.getLineBoundary(TextPosition(offset: start));
      if (i == n) {
        final boxes = tp.getBoxesForSelection(TextSelection(baseOffset: range.start, extentOffset: math.max(range.start + 1, range.end)));
        var top = double.infinity, bottom = 0.0;
        for (final b in boxes) {
          top = math.min(top, b.top);
          bottom = math.max(bottom, b.bottom);
        }
        if (boxes.isEmpty) {
          top = metrics[i].baseline - metrics[i].ascent;
          bottom = metrics[i].baseline + metrics[i].descent;
        }
        return (start: range.start, end: range.end, top: top, bottom: bottom, baseline: metrics[i].baseline);
      }
      start = range.end;
    }
    return (start: start, end: start, top: 0, bottom: tp.height, baseline: tp.height);
  }

  void _addLines(_Block b) {
    final metrics = b.painter.computeLineMetrics();
    final limit = b.clipBottom == null ? metrics.length : math.min(3, metrics.length);
    for (var i = 0; i < limit; i++) {
      final l = _lineBox(b.painter, i);
      lines.add(NovelLine(
        start: math.max(0, l.start + b.globalStart),
        end: math.min(text.length, l.end + b.globalStart),
        top: l.top + b.origin.dy,
        bottom: l.bottom + b.origin.dy,
        baseline: l.baseline + b.origin.dy,
        left: metrics[i].left + b.origin.dx,
        right: metrics[i].left + metrics[i].width + b.origin.dx,
      ),);
    }
  }

  Size get size => Size(width, height);

  /// Paints the paragraph's text (and its drop cap) with its top-left at [origin].
  void paintText(Canvas canvas, Offset origin) {
    final cap = _cap;
    if (cap != null) cap.paint(canvas, origin + _capOrigin);
    for (final b in _blocks) {
      if (b.clipBottom != null) {
        canvas
          ..save()
          ..clipRect(Rect.fromLTWH(origin.dx, origin.dy, width, b.clipBottom!));
        b.painter.paint(canvas, origin + b.origin);
        canvas.restore();
      } else {
        b.painter.paint(canvas, origin + b.origin);
      }
    }
  }

  /// The boxes covering text offsets [start, end) in paragraph coordinates, one per line piece
  /// (`getBoxesForSelection` per block), so decorations can be laid on runs.
  List<Rect> boxesFor(int start, int end) {
    final out = <Rect>[];
    for (final b in _blocks) {
      final s = start - b.globalStart, e = end - b.globalStart;
      final len = b.painter.plainText.length;
      final ls = s.clamp(0, len), le = e.clamp(0, len);
      if (le <= ls) continue;
      for (final box in b.painter.getBoxesForSelection(TextSelection(baseOffset: ls, extentOffset: le))) {
        final r = box.toRect().shift(b.origin);
        if (b.clipBottom != null && r.top >= b.clipBottom! - 0.5) continue;
        if (r.width > 0.5) out.add(r);
      }
    }
    return out;
  }

  /// The text offset under [p] (paragraph coordinates), or null outside the text block.
  int? offsetAt(Offset p) {
    if (p.dy < 0 || p.dy > height) return null;
    for (final b in _blocks.reversed) {
      if (p.dy >= b.origin.dy) {
        final pos = b.painter.getPositionForOffset(p - b.origin).offset;
        return (pos + b.globalStart).clamp(0, text.length);
      }
    }
    return null;
  }

  void dispose() {
    for (final b in _blocks) {
      b.painter.dispose();
    }
    _cap?.dispose();
  }
}
