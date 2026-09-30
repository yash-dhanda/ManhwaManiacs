import 'dart:math' as math;
import 'dart:ui';

// The ballistic send (glass 9.3.2): the glyph flies to its slot in the strip under gravity.

const double kFlightGravity = 2400; // px/s^2
const double kFlightSpeed = 1400; // px/s for the time estimate
const double kFlightMin = 0.28; // s
const double kFlightMax = 0.6; // s

/// `T = clamp(distance / 1400 px/s, 0.28 s, 0.6 s)`.
double flightTime(double distance) => (distance / kFlightSpeed).clamp(kFlightMin, kFlightMax);

/// `vx = dx / T`, `vy = (dy - 1/2 g T^2) / T`, so the arc lands exactly on the slot at `T`.
({double vx, double vy, double t}) flightVelocity(Offset from, Offset to) {
  final d = to - from;
  final t = flightTime(d.distance);
  return (vx: d.dx / t, vy: (d.dy - 0.5 * kFlightGravity * t * t) / t, t: t);
}

/// The glyph's position [t] seconds into the flight.
Offset flightAt(Offset from, Offset to, double t) {
  final v = flightVelocity(from, to);
  return Offset(from.dx + v.vx * t, from.dy + v.vy * t + 0.5 * kFlightGravity * t * t);
}

/// The six `bloom` burst particles: 4 px dots radiating 24 px over 300 ms while fading. [progress] is 0..1 of the burst.
List<({Offset at, double opacity})> burstParticles(Offset centre, double progress) {
  final p = progress.clamp(0.0, 1.0);
  return [
    for (var k = 0; k < 6; k++)
      (at: centre + Offset(math.cos(k * math.pi / 3), math.sin(k * math.pi / 3)) * (24 * p), opacity: 1 - p),
  ];
}

const Duration kBurst = Duration(milliseconds: 300);
