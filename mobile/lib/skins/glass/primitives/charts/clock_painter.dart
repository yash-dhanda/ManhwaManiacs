import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/primitives/charts/chart_math.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';

/// The 24-hour clock (glass 7.39): 24 radial bars around a 160 px circle, each from radius 40 to `40 + 40 v / max`, `iris500` at
/// opacity `0.25 + 0.75 v / max`; midnight at the top. The peak is labelled by the chart ("You read most around 23:00").
class ClockPainter extends CustomPainter {
  const ClockPainter({required this.data, required this.grow, this.selected, this.reduced = false});
  final List<ChartDatum> data;
  final double grow;
  final int? selected;
  final bool reduced;

  static const double diameter = 160;

  static Offset center(Size s) => s.center(Offset.zero);

  /// The outer end of hour [i]'s bar.
  static Offset markCenter(List<ChartDatum> data, int i, Size s) {
    final max = data.fold<double>(0, (m, d) => math.max(m, d.value));
    final r = clockBarEnd(data[i].value, max);
    final a = clockAngle(i);
    return center(s) + Offset(r * math.cos(a), r * math.sin(a));
  }

  /// The hour under [p] (its angle around the centre), or null inside the hub.
  static int? indexAt(Offset p, Size s) {
    final d = p - center(s);
    if (d.distance < 24) return null;
    var a = math.atan2(d.dy, d.dx) + math.pi / 2;
    if (a < 0) a += 2 * math.pi;
    return ((a / (2 * math.pi) * 24) + 0.5).floor() % 24;
  }

  @override
  void paint(Canvas canvas, Size s) {
    if (data.length != 24) return;
    final c = center(s);
    final max = data.fold<double>(0, (m, d) => math.max(m, d.value));
    canvas.drawCircle(c, kClockInner, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x0FFFFFFF),);
    canvas.drawCircle(c, kClockInner + kClockSpan, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x0FFFFFFF),);
    final k = reduced ? 1.0 : grow.clamp(0.0, 1.2);
    for (var i = 0; i < 24; i++) {
      final a = clockAngle(i);
      final end = kClockInner + (clockBarEnd(data[i].value, max) - kClockInner) * k;
      final color = glassTokens.colorIris500.withValues(alpha: clockOpacity(data[i].value, max) * (data[i].partial ? 0.6 : 1));
      canvas.drawLine(
        c + Offset(kClockInner * math.cos(a), kClockInner * math.sin(a)),
        c + Offset(end * math.cos(a), end * math.sin(a)),
        Paint()
          ..strokeWidth = selected == i ? 8 : 6
          ..strokeCap = StrokeCap.round
          ..color = selected == i ? glassTokens.colorIris400 : color,
      );
    }
  }

  @override
  bool shouldRepaint(ClockPainter old) => old.data != data || old.grow != grow || old.selected != selected || old.reduced != reduced;
}
