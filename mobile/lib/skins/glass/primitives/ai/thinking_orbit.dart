import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';

/// One revolution per 1,400 ms, linear (glass 4.10, Thinking orbit).
const Duration kOrbitPeriod = Duration(milliseconds: 1400);

/// The dot sizes at 64 px (8 / 6 / 4) and at 28 px (4 / 3 / 2).
List<double> orbitDotSizes(double size) => size >= 64 ? const [8, 6, 4] : const [4, 3, 2];

/// The thinking orbit (glass 7.38): three `machine` dots on a tilted ellipse (rx 24, ry 9 at 64 px, tilt 12 deg) whose outline is a
/// 0.5 px `machineRim` stroke over a `machineWash` fill. The near dot is full brightness at 1.2 scale, the far dot 0.4 at 0.8.
/// 28 px inline, 64 px in a loading area. Reduced motion: the dots pulse in sequence in place.
class ThinkingOrbit extends ConsumerStatefulWidget {
  const ThinkingOrbit({super.key, this.size = 28});
  final double size;

  @override
  ConsumerState<ThinkingOrbit> createState() => _ThinkingOrbitState();
}

class _ThinkingOrbitState extends ConsumerState<ThinkingOrbit> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: kOrbitPeriod)..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = ref.watch(glassMotionPrefsProvider.select((m) => m.reduced));
    return Semantics(
      label: 'Thinking',
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(
            key: const ValueKey('glass-thinking-orbit'),
            size: Size.square(widget.size),
            painter: OrbitPainter(turn: _c.value, size: widget.size, reduced: reduced),
          ),
        ),
      ),
    );
  }
}

class OrbitPainter extends CustomPainter {
  const OrbitPainter({required this.turn, required this.size, required this.reduced});
  final double turn;
  final double size;
  final bool reduced;

  /// Where dot [k] is on the ellipse, its brightness and its scale at [turn] (0..1 of a revolution).
  static ({Offset at, double opacity, double scale}) dot(int k, double turn, double diameter, {bool reduced = false}) {
    final k1 = diameter / 64;
    final rx = 24 * k1, ry = 9 * k1;
    if (reduced) {
      // In place: three fixed dots, opacity 0.4 to 1 over 1.2 s, 0.4 s apart.
      final phase = ((turn * 1.4 / 1.2) - k / 3) % 1.0;
      final v = 0.4 + 0.6 * (0.5 - 0.5 * math.cos(2 * math.pi * phase));
      final a = k * 2 * math.pi / 3;
      return (at: Offset(rx * math.cos(a), ry * math.sin(a)), opacity: v, scale: 1);
    }
    final a = 2 * math.pi * turn + k * 2 * math.pi / 3;
    final depth = (math.sin(a) + 1) / 2; // 1 near (front), 0 far
    return (at: Offset(rx * math.cos(a), ry * math.sin(a)), opacity: 0.4 + 0.6 * depth, scale: 0.8 + 0.4 * depth);
  }

  @override
  void paint(Canvas canvas, Size s) {
    final d = size;
    final k1 = d / 64;
    canvas.save();
    canvas.translate(s.width / 2, s.height / 2);
    canvas.rotate(12 * math.pi / 180);
    final rect = Rect.fromCenter(center: Offset.zero, width: 48 * k1, height: 18 * k1);
    canvas.drawOval(rect, Paint()..color = gt.colorMachineWash);
    canvas.drawOval(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5
        ..color = gt.colorMachineRim,
    );
    final sizes = orbitDotSizes(d);
    for (var k = 0; k < 3; k++) {
      final p = dot(k, turn, d, reduced: reduced);
      canvas.drawCircle(p.at, sizes[k] / 2 * p.scale, Paint()..color = gt.colorMachine.withValues(alpha: p.opacity));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(OrbitPainter old) => old.turn != turn || old.size != size || old.reduced != reduced;
}
