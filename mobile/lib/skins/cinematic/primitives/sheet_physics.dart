/// Pure sheet maths (cinematic 7.9, 11): rubber band, detent choice, dismissal rule.
library;

/// Above the top detent the displacement is `d * (1 - 1 / (x * 0.35 / d + 1))`, `x` the overdrag
/// and `d` the sheet height (`scalar.rubber` = 0.35).
double rubberBand(double x, double d, {double c = 0.35}) {
  if (x <= 0 || d <= 0) return 0;
  return d * (1 - 1 / (x * c / d + 1));
}

/// The detent (a visible height) nearest to the current visible [offset].
double nearestDetent(double offset, List<double> detentHeights) {
  assert(detentHeights.isNotEmpty);
  var best = detentHeights.first;
  for (final d in detentHeights) {
    if ((d - offset).abs() < (best - offset).abs()) best = d;
  }
  return best;
}

/// Dismiss below 30 % of the sheet's height visible, or on a downward fling faster than 800 px/s.
bool shouldDismiss(double visibleFraction, double velocityPxPerS) => visibleFraction < 0.30 || velocityPxPerS > 800;
