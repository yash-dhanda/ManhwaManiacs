import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/primitives/charts/chart_math.dart';
import 'package:manhwamaniacs/skins/glass/primitives/charts/chart_paint.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';

/// The genre radar (glass 7.39): 6 to 8 axes normalised to the maximum, a polygon in `iris500` at 24 % with a 1.5 px `iris400`
/// outline and 4 px vertex dots, quarter rings at `0x0FFFFFFF`. The polygon springs out from the centre ([scale] on `springCelebrate`).
/// The axis labels are buttons drawn by the chart (they call `onLabel`).
class RadarPainter extends CustomPainter {
  const RadarPainter({required this.data, required this.scale, this.selected, this.reduced = false});
  final List<ChartDatum> data;
  final double scale;
  final int? selected;
  final bool reduced;

  static double radius(Size s) => math.min(s.width, s.height) / 2 - 28;

  static Offset center(Size s) => Offset(s.width / 2, s.height / 2);

  /// Where axis [i]'s label sits (just outside the outer ring).
  static Offset labelAt(int i, int n, Size s) => center(s) + radarVertex(i, n, 1, 1, radius(s) + 16);

  /// The vertex of datum [i] (for the readout's lens ring).
  static Offset vertexAt(List<ChartDatum> data, int i, Size s) {
    final max = data.fold<double>(0, (m, d) => math.max(m, d.value));
    return center(s) + radarVertex(i, data.length, data[i].value, max, radius(s));
  }

  @override
  void paint(Canvas canvas, Size s) {
    final n = data.length;
    if (n < 3) return;
    final c = center(s), r = radius(s);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = kChartLine;
    for (final q in [0.25, 0.5, 0.75, 1.0]) {
      final ring = Path();
      for (var i = 0; i < n; i++) {
        final p = c + radarVertex(i, n, q, 1, r);
        i == 0 ? ring.moveTo(p.dx, p.dy) : ring.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(ring..close(), line);
    }
    for (var i = 0; i < n; i++) {
      canvas.drawLine(c, c + radarVertex(i, n, 1, 1, r), line);
    }
    final max = data.fold<double>(0, (m, d) => math.max(m, d.value));
    final poly = Path();
    final pts = <Offset>[];
    for (var i = 0; i < n; i++) {
      final p = c + radarVertex(i, n, data[i].value, max, r) * (reduced ? 1 : scale);
      pts.add(p);
      i == 0 ? poly.moveTo(p.dx, p.dy) : poly.lineTo(p.dx, p.dy);
    }
    poly.close();
    canvas.drawPath(poly, Paint()..color = glassTokens.colorIris500.withValues(alpha: 0.24));
    canvas.drawPath(
      poly,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round
        ..color = glassTokens.colorIris400,
    );
    for (var i = 0; i < n; i++) {
      canvas.drawCircle(pts[i], selected == i ? 3 : 2, Paint()..color = selected == i ? glassTokens.colorOnGlass : glassTokens.colorIris400);
    }
  }

  @override
  bool shouldRepaint(RadarPainter old) => old.data != data || old.scale != scale || old.selected != selected || old.reduced != reduced;
}
