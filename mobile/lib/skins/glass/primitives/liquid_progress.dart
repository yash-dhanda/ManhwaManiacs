import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/spring_value.dart';

/// The meniscus bulge (glass 7.19): `3 px + clamp(velocity / 400, -3, 3) px`, from the level spring's velocity.
double meniscusBulge(double velocityPerSecond, double width) => 3 + (velocityPerSecond * width / 400).clamp(-3.0, 3.0);

/// Inside a capsule, the filled part is `iris600` at 60 % with a meniscus: its leading edge curves 3 px and
/// wobbles when the value changes. The level follows on `springLens` (k 223.8, c 20.94, bounce 0.3), so a
/// jump sloshes once. Used by the downloads meter, storage, hold-to-confirm and the progress button.
class LiquidProgress extends StatelessWidget {
  const LiquidProgress({super.key, required this.value, this.height = 24, this.color, this.meniscus = true, this.stepped = false});

  /// 0..1.
  final double value;
  final double height;

  /// The fill colour; default `iris600` at 60 %.
  final Color? color;
  final bool meniscus;

  /// The reduced-motion form of a hold: no meniscus.
  final bool stepped;

  @override
  Widget build(BuildContext context) => SpringValue(
        value: value.clamp(0.0, 1.0),
        spring: gt.springLens,
        name: MotionName.liquidFill,
        builder: (context, v, vel) => CustomPaint(
          painter: LiquidPainter(level: v, velocity: vel, color: color ?? const Color(0x997563F2), meniscus: meniscus && !stepped),
          child: SizedBox(height: height, width: double.infinity),
        ),
      );
}

class LiquidPainter extends CustomPainter {
  const LiquidPainter({required this.level, required this.velocity, required this.color, this.meniscus = true});
  final double level;
  final double velocity;
  final Color color;
  final bool meniscus;

  @override
  void paint(Canvas canvas, Size size) {
    if (level <= 0) return;
    final x = size.width * level.clamp(0.0, 1.0);
    final b = meniscus && level < 1 ? meniscusBulge(velocity, size.width) : 0.0;
    final p = Path()
      ..moveTo(0, 0)
      ..lineTo(math.max(0, x - b), 0)
      ..quadraticBezierTo(x + b, size.height / 2, math.max(0, x - b), size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(p, Paint()..color = color);
  }

  @override
  bool shouldRepaint(LiquidPainter old) => old.level != level || old.velocity != velocity || old.color != color || old.meniscus != meniscus;
}
