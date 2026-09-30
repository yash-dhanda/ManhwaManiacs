/// The auto-scroll multiplier for a fling that has slowed to forward velocity [v] px/s:
/// `round(v / 60 / 0.05) * 0.05` clamped to 0.25-4, or null outside 15-240 px/s.
double? engageSpeed(double v) {
  if (v < 15 || v > 240) return null;
  final x = (v / 60 / 0.05).round() * 0.05;
  return double.parse(x.clamp(0.25, 4.0).toStringAsFixed(2));
}

class CruiseEngaged {
  const CruiseEngaged(this.multiplier, this.pxPerSecond);
  final double multiplier;
  final double pxPerSecond;
}
