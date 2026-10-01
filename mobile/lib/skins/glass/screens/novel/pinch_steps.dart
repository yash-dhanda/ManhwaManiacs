import 'dart:math' as math;

import 'package:manhwamaniacs/features/novels/models/glass_novel_prefs.dart';

/// One text-size step per x1.15 of pinch scale (glass 8.15.4, G8).
const double kPinchStepRatio = 1.15;

/// Whole steps for a pinch [scale] measured from the gesture's start: `trunc(ln(scale) / ln(1.15))`.
int pinchSteps(double scale) {
  if (scale <= 0 || !scale.isFinite) return 0;
  final v = math.log(scale) / math.log(kPinchStepRatio);
  // A scale of exactly 1.15^n is n steps, not n - epsilon.
  return (v + (v.isNegative ? -1e-9 : 1e-9)).truncate();
}

/// The size a pinch of [scale] from [start] asks for, clamped 15-30.
double pinchSize(double start, double scale) => (start + pinchSteps(scale)).clamp(GlassNovelRange.sizeMin, GlassNovelRange.sizeMax).toDouble();

/// The `=`, `+`, `-` and `0` keys: one step, or back to [defaultSize].
double keySize(double current, {int step = 0, bool reset = false, required double defaultSize}) =>
    (reset ? defaultSize : current + step).clamp(GlassNovelRange.sizeMin, GlassNovelRange.sizeMax).toDouble();
