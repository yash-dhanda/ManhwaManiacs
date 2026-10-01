import 'dart:ui';

// Orbs fly out (glass 9.3.4, 4.10): each selected orb leaves the recommend sheet along a quadratic Bezier.

/// The path of one orb: from its centre [start] to the top edge [topY] at `start.x + 40 * s` (s = -1 left of [sheetCentreX], +1
/// otherwise), the control point 120 px above the start.
({Offset p0, Offset p1, Offset p2}) orbFlightPath(Offset start, {required double sheetCentreX, required double topY}) {
  final s = start.dx < sheetCentreX ? -1.0 : 1.0;
  return (p0: start, p1: start.translate(0, -120), p2: Offset(start.dx + 40 * s, topY));
}

/// The point at [t] (0..1) on the quadratic Bezier.
Offset bezierAt(({Offset p0, Offset p1, Offset p2}) c, double t) {
  final u = 1 - t;
  return c.p0 * (u * u) + c.p1 * (2 * u * t) + c.p2 * (t * t);
}

/// Orb [index] starts 40 ms after the one before it.
Duration orbFlightDelay(int index) => Duration(milliseconds: 40 * index);
