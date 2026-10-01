import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/primitives/charts/chart_math.dart';
import 'package:manhwamaniacs/skins/glass/primitives/charts/chart_paint.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';

/// Daily bars (glass 7.39): `iris500` with 3 px rounded tops, width `min(16, available / n - 3)`, zero days as 2 px `fill2` stubs,
/// an optional second-axis line in `aurora1` (1.5 px, 4 px round markers), a baseline and quarter lines at `0x0FFFFFFF`, labels in
/// `caption2`. A partial day (today) draws at 60 %. Bars rise in a wave from the left ([tMs] into the rise).
class BarPainter extends CustomPainter {
  const BarPainter({required this.data, required this.tMs, required this.label, this.selected, this.labelEvery = 1, this.reduced = false});
  final List<ChartDatum> data;
  final double tMs;
  final TextStyle label;
  final int? selected;
  final int labelEvery;
  final bool reduced;

  static const double labelBand = 18;

  static Rect plot(Size s) => Rect.fromLTWH(0, 4, s.width, s.height - labelBand - 4);

  /// The centre of bar [i]'s top, for the readout's lens ring.
  static Offset markCenter(List<ChartDatum> data, int i, Size s) {
    final r = plot(s);
    final max = data.fold<double>(0, (m, d) => math.max(m, d.value));
    final step = s.width / data.length;
    final h = max <= 0 ? 0.0 : data[i].value / max * r.height;
    return Offset(i * step + step / 2, r.bottom - math.max(h, 2));
  }

  @override
  void paint(Canvas canvas, Size s) {
    if (data.isEmpty) return;
    final r = plot(s);
    final line = Paint()
      ..color = kChartLine
      ..strokeWidth = 1;
    for (final q in [0.0, 0.25, 0.5, 0.75, 1.0]) {
      final y = r.bottom - r.height * q;
      canvas.drawLine(Offset(0, y), Offset(s.width, y), line);
    }
    final max = data.fold<double>(0, (m, d) => math.max(m, d.value));
    final step = s.width / data.length;
    final bw = barWidth(s.width, data.length);
    // Labels never overlap: every Nth one, N from the widest label against the bar step (52 weeks on a phone show a few).
    String textOf(ChartDatum d) => d.label ?? (d.day == null ? '' : weekdayInitial(d.day!));
    var widest = 0.0;
    for (final d in data) {
      final p = TextPainter(text: TextSpan(text: textOf(d), style: label), textDirection: TextDirection.ltr)..layout();
      widest = math.max(widest, p.width);
      p.dispose();
    }
    final every = math.max(labelEvery, ((widest + 6) / step).ceil());
    for (var i = 0; i < data.length; i++) {
      final d = data[i];
      final x = i * step + (step - bw) / 2;
      final k = reduced ? 1.0 : riseProgress(i * step, tMs);
      final alpha = (d.partial ? 0.6 : 1.0);
      if (d.value <= 0) {
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, r.bottom - 2, bw, 2), const Radius.circular(1)), Paint()..color = glassTokens.colorFill2);
      } else {
        final h = d.value / max * r.height * k;
        final color = (selected == i ? glassTokens.colorIris400 : glassTokens.colorIris500).withValues(alpha: alpha);
        canvas.drawRRect(
          RRect.fromRectAndCorners(Rect.fromLTWH(x, r.bottom - math.max(h, 2), bw, math.max(h, 2)), topLeft: const Radius.circular(3), topRight: const Radius.circular(3)),
          Paint()..color = color,
        );
      }
      if (i % every == 0) paintChartText(canvas, textOf(d), Offset(i * step + step / 2, r.bottom + 4), label, center: true);
    }
    // the second axis
    final seconds = [for (final d in data) d.second];
    if (seconds.any((v) => v != null)) {
      final max2 = seconds.fold<double>(0, (m, v) => math.max(m, v ?? 0));
      final path = Path();
      final pts = <Offset>[];
      for (var i = 0; i < data.length; i++) {
        final v = seconds[i];
        if (v == null) continue;
        final p = Offset(i * step + step / 2, r.bottom - (max2 <= 0 ? 0 : v / max2) * r.height * (reduced ? 1.0 : riseProgress(i * step, tMs)));
        pts.add(p);
        pts.length == 1 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeJoin = StrokeJoin.round
          ..color = glassTokens.colorAurora1,
      );
      for (final p in pts) {
        canvas.drawCircle(p, 2, Paint()..color = glassTokens.colorAurora1);
      }
    }
  }

  @override
  bool shouldRepaint(BarPainter old) => old.data != data || old.tMs != tMs || old.selected != selected || old.reduced != reduced || old.label != label;
}
