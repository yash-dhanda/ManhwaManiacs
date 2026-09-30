import 'dart:math' as math;
import 'dart:ui';

// Pure flame numbers (glass 9.2.2): the teardrop path, the tip spring, the lean cap and the flicker noise.

/// Tip lean (tilt plus scroll) never exceeds this share of the flame height.
const double kFlameLeanCap = 0.18;

/// Gravity: 1 g pushes the tip with 400 px/s^2.
const double kFlameGravityPx = 400;

/// Scroll lean: `0.004 x a` px opposite to the scroll acceleration `a` (px/s^2).
const double kFlameScrollLean = 0.004;

/// The `drift` spring (k 48.7, c 13.96) that pulls the tip to rest.
const double kFlameK = 48.7;
const double kFlameC = 13.96;

/// A cubic Bezier teardrop inside [size]: a round belly at the bottom, the point at [tip] (the rest tip is `(w/2, 0)`), [inset] shrinks
/// it towards the belly so the three layers nest.
Path teardrop(Size size, Offset tip, double inset) {
  final w = size.width, h = size.height;
  final cx = w / 2;
  final left = inset + w * 0.04, right = w - inset - w * 0.04;
  final top = tip.dy + inset * 0.6;
  final bottom = h - inset;
  final tx = tip.dx;
  final belly = bottom - (right - left) * 0.5;
  return Path()
    ..moveTo(tx, top)
    ..cubicTo(tx + (cx - tx) * 0.2 + w * 0.05, top + h * 0.3, right, belly - h * 0.12, right, belly)
    ..arcToPoint(Offset(left, belly), radius: Radius.circular((right - left) / 2), clockwise: true)
    ..cubicTo(left, belly - h * 0.12, tx - (cx - tx) * 0.2 - w * 0.05, top + h * 0.3, tx, top)
    ..close();
}

/// The lean of the tip, in px, from the tilt [gravity] (g, screen plane) and the scroll acceleration [scrollAccel] (px/s^2 on y),
/// opposite to both, capped to [kFlameLeanCap] of [height] in length.
Offset flameLean({required Offset gravity, required double scrollAccel, required double height}) {
  final push = Offset(-gravity.dx * kFlameGravityPx * 0.01, gravity.dy * kFlameGravityPx * 0.01 - scrollAccel * kFlameScrollLean);
  final cap = height * kFlameLeanCap;
  final d = push.distance;
  return d <= cap || d == 0 ? push : push * (cap / d);
}

/// 1-D value noise in [-1, 1] at [t] seconds and [hz] knots per second (smoothstep between seeded lattice values).
double flameNoise(double t, double hz, {int seed = 7}) {
  double lattice(int i) {
    var x = (i * 374761393 + seed * 668265263) & 0x7fffffff;
    x = ((x ^ (x >> 13)) * 1274126177) & 0x7fffffff;
    return (x % 2001) / 1000 - 1;
  }

  final p = t * hz;
  final i = p.floor();
  final f = p - i;
  final s = f * f * (3 - 2 * f);
  return lattice(i) + (lattice(i + 1) - lattice(i)) * s;
}

/// The flicker offset of the tip, `2 %` of [height] at most (5 Hz; 2.5 Hz in the not-yet-today state).
double flameFlicker(double t, double height, {bool slow = false}) => flameNoise(t, slow ? 2.5 : 5) * height * 0.02;

/// The tip as a damped spring (`drift`): [pos] relative to the rest tip, pulled to [target] (the lean). Semi-implicit Euler in
/// sub-steps, so it is stable at any frame time.
class FlameTip {
  Offset pos = Offset.zero;
  Offset vel = Offset.zero;

  bool get resting => pos.distance < 0.02 && vel.distance < 0.05;

  void step(double dt, Offset target) {
    var left = math.min(dt, 0.1);
    while (left > 0) {
      final h = math.min(left, 1 / 240);
      final a = (target - pos) * kFlameK - vel * kFlameC;
      vel += a * h;
      pos += vel * h;
      left -= h;
    }
  }
}

/// Embers: 8 particles rising with +300 px/s^2 and lateral drift of +-20 px/s, fading over 900 ms.
class Ember {
  Ember(this.pos, this.vel);
  Offset pos;
  Offset vel;
  double age = 0;

  double get opacity => (1 - age / 0.9).clamp(0.0, 1.0);
  bool get dead => age >= 0.9;

  void step(double dt) {
    vel += const Offset(0, -300) * dt;
    pos += vel * dt;
    age += dt;
  }
}

List<Ember> spawnEmbers(Offset tip, math.Random r, {int n = 8}) =>
    [for (var i = 0; i < n; i++) Ember(tip + Offset((r.nextDouble() - 0.5) * 6, 0), Offset((r.nextDouble() * 2 - 1) * 20, -20 - r.nextDouble() * 20))];
