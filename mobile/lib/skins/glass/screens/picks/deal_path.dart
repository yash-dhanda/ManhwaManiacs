import 'dart:math' as math;
import 'dart:ui';

/// Distance of the Bezier control point from the chord's midpoint (glass 4.10, Deal).
const double kDealControl = 48;

/// The control point: 48 px perpendicular to the chord's midpoint, on the side toward the top of the screen.
Offset dealControl(Offset start, Offset end) {
  final mid = (start + end) / 2;
  final d = end - start;
  if (d.distance == 0) return mid - const Offset(0, kDealControl);
  var n = Offset(-d.dy, d.dx) / d.distance;
  if (n.dy > 0) n = -n;
  return mid + n * kDealControl;
}

/// A point of the quadratic Bezier from [start] to [end] at [t] in 0..1.
Offset dealPoint(Offset start, Offset end, double t) {
  final c = dealControl(start, end);
  final u = 1 - t;
  return start * (u * u) + c * (2 * u * t) + end * (t * t);
}

/// `why` lines type in at 12 ms per character (glass 4.10, Quick type).
Duration quickTypeFor(int chars) =>
    Duration(milliseconds: 12 * math.max(0, chars));
