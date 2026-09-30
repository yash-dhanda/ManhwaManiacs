import 'package:flutter/material.dart';

/// One recap paragraph with a drop cap spanning its first three lines. Flutter has no float, so
/// the text that fits three lines beside the cap is measured with a [TextPainter] at
/// `width - capWidth - gap` and breaks on a word boundary; the rest is set at full width below.
/// [buildSpans] turns a slice of the plain text into styled spans (italic cast names, word fades)
/// and is given each slice's start offset within [text].
class RecapDropCap extends StatelessWidget {
  const RecapDropCap({
    super.key,
    required this.text,
    required this.style,
    required this.capStyle,
    required this.buildSpans,
    this.textScaler = TextScaler.noScaling,
    this.lines = 3,
    this.gap = 8,
  });

  /// The paragraph text; its first character is the cap.
  final String text;
  final TextStyle style, capStyle;
  final List<InlineSpan> Function(String slice, int start) buildSpans;
  final TextScaler textScaler;
  final int lines, gap;

  /// The first [lines] lines of [rest] at [width], broken at a space, and what follows.
  static ({String head, String tail}) split(String rest, TextStyle style, double width, int lines, {TextScaler scaler = TextScaler.noScaling}) {
    final tp = TextPainter(text: TextSpan(text: rest, style: style), textDirection: TextDirection.ltr, textScaler: scaler)..layout(maxWidth: width);
    final metrics = tp.computeLineMetrics();
    if (metrics.length <= lines) {
      tp.dispose();
      return (head: rest, tail: '');
    }
    final bottom = metrics.take(lines).fold<double>(0, (a, l) => a + l.height);
    var end = tp.getPositionForOffset(Offset(width, bottom - 1)).offset.clamp(0, rest.length);
    tp.dispose();
    // Break on a word boundary: back up to the space before a partial word.
    if (end < rest.length && rest[end] != ' ') {
      final sp = rest.lastIndexOf(' ', end);
      if (sp > 0) end = sp;
    }
    return (head: rest.substring(0, end).trimRight(), tail: rest.substring(end).trimLeft());
  }

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    final cap = text.substring(0, 1);
    final rest = text.substring(1);
    return LayoutBuilder(builder: (context, box) {
      final capPainter = TextPainter(text: TextSpan(text: cap, style: capStyle), textDirection: TextDirection.ltr, textScaler: textScaler)..layout();
      final capW = capPainter.width;
      final leading = (style.fontSize ?? 18) * (style.height ?? 1.5) * textScaler.scale(1);
      final parts = split(rest, style, box.maxWidth - capW - gap, lines, scaler: textScaler);
      capPainter.dispose();
      const headOffset = 1; // the cap took one character
      final tailOffset = headOffset + rest.length - parts.tail.length;
      return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          height: leading * lines,
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned(left: 0, top: 0, child: Text(cap, style: capStyle, textScaler: textScaler)),
            Positioned(
              left: capW + gap,
              right: 0,
              top: 0,
              child: Text.rich(TextSpan(style: style, children: buildSpans(parts.head, headOffset)), textScaler: textScaler),
            ),
          ],),
        ),
        if (parts.tail.isNotEmpty) Text.rich(TextSpan(style: style, children: buildSpans(parts.tail, tailOffset)), textScaler: textScaler),
      ],);
    },);
  }
}
