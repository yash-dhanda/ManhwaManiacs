import 'package:flutter/foundation.dart';

/// The phone-only left-edge brightness band (glass 8.14.3): 12 % of the width, from x 24 on iOS (clear of the 20 px back strip)
/// and from the edge on Android.
({double start, double end}) brightnessBandRange(double width, TargetPlatform platform) {
  final start = platform == TargetPlatform.iOS ? 24.0 : 0.0;
  return (start: start, end: start + 0.12 * width);
}

bool inBrightnessBand(double x, double width, TargetPlatform platform) {
  final r = brightnessBandRange(width, platform);
  return x >= r.start && x <= r.end;
}

/// Ownership: a drag that started inside the band activates once it has moved 10 px with `|dy| > 2 |dx|`. Null: undecided;
/// false: the strip keeps it.
bool? bandActivates(double dx, double dy) {
  if (dx * dx + dy * dy < 100) return null;
  return dy.abs() > 2 * dx.abs();
}

/// Up raises, down lowers: 20 to 100 % over 60 % of the screen height.
double bandBrightness(double start, double dy, double height) =>
    (start - dy / (0.6 * height) * 0.8).clamp(0.2, 1.0);
