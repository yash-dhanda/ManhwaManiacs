import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';

/// Equal widths, or content-fit widths when the labels differ by more than 40 % (glass 7.6).
List<double> segmentWidths({required List<double> labelWidths, required double total, double padding = 32}) {
  final n = labelWidths.length;
  assert(n >= 2 && n <= 5, 'A segmented control has 2 to 5 segments; more must be a menu (glass 7.6).');
  final lo = labelWidths.reduce((a, b) => a < b ? a : b);
  final hi = labelWidths.reduce((a, b) => a > b ? a : b);
  if (hi == 0 || (hi - lo) / hi <= 0.4) return List.filled(n, total / n);
  final want = [for (final w in labelWidths) w + padding];
  final sum = want.fold<double>(0, (a, b) => a + b);
  return [for (final w in want) w / sum * total];
}

List<double> segmentCentres(List<double> widths) {
  var x = 0.0;
  return [
    for (final w in widths)
      () {
        final c = x + w / 2;
        x += w;
        return c;
      }(),
  ];
}

/// The segment a release at [thumbCentre] with [velocity] (px/s) settles on: the projected rest point's
/// nearest segment centre.
int projectedSegment({required double thumbCentre, required double velocity, required List<double> widths}) {
  final target = project(thumbCentre, velocity).clamp(0.0, widths.fold<double>(0, (a, b) => a + b));
  final centres = segmentCentres(widths);
  var best = 0;
  for (var i = 1; i < centres.length; i++) {
    if ((centres[i] - target).abs() < (centres[best] - target).abs()) best = i;
  }
  return best;
}

/// The segment under [x] (clamped).
int segmentAt(double x, List<double> widths) {
  var edge = 0.0;
  for (var i = 0; i < widths.length; i++) {
    edge += widths[i];
    if (x < edge) return i;
  }
  return widths.length - 1;
}

/// How many segment boundaries the thumb crossed moving from [from] to [to] (one haptic tick each).
int boundaryCrossings(double from, double to, List<double> widths) => (segmentAt(to, widths) - segmentAt(from, widths)).abs();
