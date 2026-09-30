import 'package:flutter/widgets.dart';

/// The hairline of a chart's baseline and quarter lines (glass 7.39): `Color(0x0FFFFFFF)`, no other gridlines.
const Color kChartLine = Color(0x0FFFFFFF);

/// Paints [text] with its left edge at [at] (or centred on it), top aligned.
void paintChartText(Canvas canvas, String text, Offset at, TextStyle style, {bool center = false, bool right = false, double? maxWidth}) {
  final tp = TextPainter(text: TextSpan(text: text, style: style), textDirection: TextDirection.ltr, maxLines: 1, ellipsis: '…', textScaler: TextScaler.noScaling)..layout(maxWidth: maxWidth ?? double.infinity);
  final dx = center ? -tp.width / 2 : (right ? -tp.width : 0.0);
  tp.paint(canvas, at + Offset(dx, 0));
  tp.dispose();
}

/// The short weekday label of a day: M T W T F S S.
String weekdayInitial(DateTime d) => const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][d.weekday - 1];

const List<String> kMonthShort = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
