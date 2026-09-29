import 'package:flutter/material.dart';

/// A paragraph with a drop cap spanning its first three lines. Flutter has no
/// float, so the first three lines are measured with a [TextPainter] beside
/// the cap and the rest is set below at full width. Under [minLength] (80)
/// characters there is no cap.
class DropCapParagraph extends StatelessWidget {
  const DropCapParagraph({
    super.key,
    required this.text,
    required this.style,
    required this.capStyle,
    this.minLength = 80,
    this.lines = 3,
  });

  final String text;
  final TextStyle style;
  final TextStyle capStyle;
  final int minLength;
  final int lines;

  /// Splits [rest] into what fits in the first [lines] lines at [width] and
  /// the remainder.
  static ({String head, String tail}) split(String rest, TextStyle style, double width, int lines) {
    final tp =
        TextPainter(text: TextSpan(text: rest, style: style), textDirection: TextDirection.ltr)
          ..layout(maxWidth: width);
    final m = tp.computeLineMetrics();
    if (m.length <= lines) return (head: rest, tail: '');
    final bottom = m.take(lines).fold<double>(0, (a, l) => a + l.height);
    final end = tp.getPositionForOffset(Offset(width, bottom - 1)).offset;
    tp.dispose();
    return (head: rest.substring(0, end).trimRight(), tail: rest.substring(end).trimLeft());
  }

  @override
  Widget build(BuildContext context) {
    final t = text.trim();
    if (t.length < minLength) return Text(t, style: style);
    final cap = t.substring(0, 1);
    final rest = t.substring(1);
    return LayoutBuilder(
      builder: (context, box) {
        final capPainter = TextPainter(
            text: TextSpan(text: cap, style: capStyle), textDirection: TextDirection.ltr,)
          ..layout();
        final capW = capPainter.width;
        final lineH = (style.fontSize ?? 16) * (style.height ?? 1.5);
        final parts = split(rest, style, box.maxWidth - capW - 8, lines);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: lineH * lines,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: capW,
                    child: Align(
                      alignment: Alignment.topLeft,
                      // The cap's baseline sits on the third text baseline.
                      child: Transform.translate(
                        offset: Offset(0, -(capPainter.height - lineH * lines) - 4),
                        child: Text(cap, style: capStyle),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(parts.head, style: style)),
                ],
              ),
            ),
            if (parts.tail.isNotEmpty) Text(parts.tail, style: style),
          ],
        );
      },
    );
  }
}
