import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/primitives/charts/chart_math.dart';
import 'package:manhwamaniacs/skins/glass/primitives/charts/chart_paint.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';

/// The reading heatmap (glass 7.39): 10 px cells with 2 px gaps, weeks as columns, Monday at the top; level [heatLevel] colours
/// `heat0` to `heat4`; today is outlined 1 px in `aurora1`; month labels sit above. A partial cell (today) draws at 60 %.
class HeatmapPainter extends CustomPainter {
  const HeatmapPainter({required this.data, required this.label, this.selected, required this.today, this.fade = 1});
  final List<ChartDatum> data;
  final TextStyle label;
  final int? selected;
  final DateTime today;
  final double fade;

  static const double cell = 10, gap = 2, top = 16;

  static int firstWeekday(List<ChartDatum> data) => data.isEmpty || data.first.day == null ? 0 : data.first.day!.weekday - 1;

  static int columns(List<ChartDatum> data) => data.isEmpty ? 0 : heatCell(data.length - 1, firstWeekday(data)).col + 1;

  static Size sizeFor(List<ChartDatum> data) => Size(math.max(0, columns(data) * (cell + gap) - gap), top + 7 * (cell + gap) - gap);

  static Rect cellRect(List<ChartDatum> data, int i) {
    final c = heatCell(i, firstWeekday(data));
    return Rect.fromLTWH(c.col * (cell + gap), top + c.row * (cell + gap), cell, cell);
  }

  /// The data index under [p], or null.
  static int? indexAt(List<ChartDatum> data, Offset p) {
    final col = (p.dx / (cell + gap)).floor(), row = ((p.dy - top) / (cell + gap)).floor();
    if (col < 0 || row < 0 || row > 6) return null;
    final i = col * 7 + row - firstWeekday(data);
    return i < 0 || i >= data.length ? null : i;
  }

  static Color colorFor(int level) => switch (level) {
        0 => glassTokens.colorHeat0,
        1 => glassTokens.colorHeat1,
        2 => glassTokens.colorHeat2,
        3 => glassTokens.colorHeat3,
        _ => glassTokens.colorHeat4,
      };

  @override
  void paint(Canvas canvas, Size s) {
    if (data.isEmpty) return;
    final max = data.fold<double>(0, (m, d) => math.max(m, d.value));
    var lastMonth = -1;
    for (var i = 0; i < data.length; i++) {
      final d = data[i];
      final r = cellRect(data, i);
      final alpha = (d.partial ? 0.6 : 1.0) * fade;
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2.5)), Paint()..color = colorFor(heatLevel(d.value, max)).withValues(alpha: colorFor(heatLevel(d.value, max)).a * alpha));
      final day = d.day;
      if (day != null && day.month != lastMonth && (heatCell(i, firstWeekday(data)).row == 0 || i == 0)) {
        lastMonth = day.month;
        paintChartText(canvas, kMonthShort[day.month - 1], Offset(r.left, 0), label);
      }
      if (day != null && day.year == today.year && day.month == today.month && day.day == today.day) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(r.inflate(0.5), const Radius.circular(3)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = glassTokens.colorAurora1,
        );
      }
      if (selected == i) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(r.inflate(1.5), const Radius.circular(3.5)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = glassTokens.colorOnGlass,
        );
      }
    }
  }

  @override
  bool shouldRepaint(HeatmapPainter old) => old.data != data || old.selected != selected || old.fade != fade || old.today != today || old.label != label;
}
