import 'dart:math' as math;

/// Zoom limits shared with `reader_ui_provider.dart` (0.5-3.0, step 0.1).
const double kZoomMin = 0.5;
const double kZoomMax = 3.0;

/// The scroll offset that keeps the content point under [focalY] (viewport y) fixed while the
/// page width scales from [oldScale] to [newScale]:
/// `newOffset = (offset + focalY) * newScale / oldScale - focalY`.
double focalOffset(double offset, double focalY, double oldScale, double newScale) =>
    oldScale <= 0 ? offset : (offset + focalY) * newScale / oldScale - focalY;

/// The horizontal twin: the pan offset of a strip [newScale] wide that keeps the point under
/// [focalX] fixed.
double focalOffsetX(double offset, double focalX, double oldScale, double newScale) =>
    focalOffset(offset, focalX, oldScale, newScale);

/// [value] inside [min]..[max].
double clampZoom(double value, {double min = kZoomMin, double max = kZoomMax}) => value.clamp(min, max);

/// [value] snapped to the nearest multiple of [step] (0.1 by default), free of float noise.
double snapZoom(double value, [double step = 0.1]) {
  final snapped = (value / step).round() * step;
  return double.parse(snapped.toStringAsFixed(4));
}

/// The rubber band of cinematic 4.4 (`scalarRubber`): how far past a limit a drag of [x] shows
/// when the resistance distance is [d] and the coefficient [c]: `d * (1 - 1 / (x * c / d + 1))`.
double rubberBand(double x, double d, [double c = 0.35]) => d <= 0 ? 0 : d * (1 - 1 / (x * c / d + 1));

/// A pinch scale [raw] outside [min]..[max] pulled back by the rubber band (in log-free scale
/// units), inside it unchanged.
double rubberScale(double raw, {double min = kZoomMin, double max = kZoomMax, double d = 0.5}) {
  if (raw > max) return max + rubberBand(raw - max, d);
  if (raw < min) return min - rubberBand(min - raw, d);
  return raw;
}

/// The distance between two pointers.
double pointerDistance(({double x, double y}) a, ({double x, double y}) b) =>
    math.sqrt(math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2));
