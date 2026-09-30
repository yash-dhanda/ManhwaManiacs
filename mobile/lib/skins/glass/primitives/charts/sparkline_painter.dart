import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/primitives/charts/chart_math.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';

/// The 7-point sparkline (glass 7.39): 24 px tall, a 1.5 px `iris500` line.
class SparklinePainter extends CustomPainter {
  const SparklinePainter({required this.data, required this.progress, this.selected});
  final List<ChartDatum> data;
  final double progress;
  final int? selected;

  static const double height = 24;

  static Offset pointAt(List<ChartDatum> data, int i, Size s) {
    final max = data.fold<double>(0, (m, d) => math.max(m, d.value));
    final step = data.length <= 1 ? 0.0 : (s.width - 4) / (data.length - 1);
    return Offset(2 + i * step, s.height - 2 - (max <= 0 ? 0 : data[i].value / max) * (s.height - 4));
  }

  @override
  void paint(Canvas canvas, Size s) {
    if (data.isEmpty) return;
    final path = Path();
    for (var i = 0; i < data.length; i++) {
      final p = pointAt(data, i, s);
      final q = Offset(p.dx, s.height - 2 - (s.height - 2 - p.dy) * progress.clamp(0.0, 1.2));
      i == 0 ? path.moveTo(q.dx, q.dy) : path.lineTo(q.dx, q.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = glassTokens.colorIris500,
    );
    if (selected != null) canvas.drawCircle(pointAt(data, selected!, s), 3, Paint()..color = glassTokens.colorIris400);
  }

  @override
  bool shouldRepaint(SparklinePainter old) => old.data != data || old.progress != progress || old.selected != selected;
}
