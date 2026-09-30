import 'package:flutter/foundation.dart';

/// The per-frame reader values (glass 15.4). They change every frame, so they live on their own
/// notifiers and never rebuild the chrome that listens to `ReaderEngineState`; a notifier only
/// fires when the value changed.
class EngineLive {
  /// Signed px/s, positive forward.
  final ValueNotifier<double> scrollVelocity = ValueNotifier<double>(0);

  /// 0-1 while a chapter seam overlaps the viewport, else null.
  final ValueNotifier<double?> seamProgress = ValueNotifier<double?>(null);

  /// Displayed px pulled past the chapter's end (positive) or start (negative).
  final ValueNotifier<double> overscrollExtent = ValueNotifier<double>(0);

  void dispose() {
    scrollVelocity.dispose();
    seamProgress.dispose();
    overscrollExtent.dispose();
  }
}

/// The value the state carries for [v]: changes only when `|v|` crosses 3000 px/s or reaches 0.
double stateVelocity(double previous, double v) {
  const t = 3000.0;
  if (v == 0) return 0;
  final crossed = (previous.abs() > t) != (v.abs() > t);
  if (crossed || previous == 0) return v;
  return previous;
}

/// The value the state carries for [raw] overscroll: changes only when it crosses 0, +-48 or +-72.
double stateOverscroll(double previous, double raw) {
  int band(double x) {
    final a = x.abs();
    final b = a >= 72 ? 3 : (a >= 48 ? 2 : (a > 0 ? 1 : 0));
    return x < 0 ? -b : b;
  }

  return band(previous) == band(raw) ? previous : raw;
}

/// The state value for a seam progress: a number while a seam is on screen, null otherwise.
double? stateSeam(double? previous, double? v) {
  if ((previous == null) == (v == null)) return previous;
  return v;
}
