import 'dart:ui';

/// The Avatar arc (glass 4.10): a copy of the chosen orb flies along a parabola into the live preview. Gravity 3,000 px/s², a 280 ms
/// flight, the initial velocity solved so the arc lands on the preview centre. Pure.
class AvatarArc {
  const AvatarArc._({required this.from, required this.to, required this.velocity, required this.gravity, required this.flightMs});

  factory AvatarArc.solve({required Offset from, required Offset to, double gravity = 3000, int flightMs = 280}) {
    final t = flightMs / 1000;
    final vx = (to.dx - from.dx) / t;
    // to.dy = from.dy + vy * t + g * t^2 / 2
    final vy = (to.dy - from.dy - gravity * t * t / 2) / t;
    return AvatarArc._(from: from, to: to, velocity: Offset(vx, vy), gravity: gravity, flightMs: flightMs);
  }

  final Offset from;
  final Offset to;

  /// The initial velocity in px/s.
  final Offset velocity;
  final double gravity;
  final int flightMs;

  /// The position [ms] after the launch, clamped to the flight.
  Offset at(double ms) {
    final t = (ms.clamp(0, flightMs)) / 1000;
    return Offset(from.dx + velocity.dx * t, from.dy + velocity.dy * t + gravity * t * t / 2);
  }
}
