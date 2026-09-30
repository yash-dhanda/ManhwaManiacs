import 'dart:math' as math;

/// Manga strip rate: 60 px/s at 1.00x on a 1080 px viewport, scaled by viewport height.
double mangaPxPerSecond(double speedX, double viewportHeight) => 60 * speedX * viewportHeight / 1080;

/// 1.2 - words / 60 clamped 0.5-1.0 (12 words or fewer 1.0, 42 words 0.5).
double paceFactor(int words) => (1.2 - words / 60).clamp(0.5, 1.0);

/// Speed multiplier snapped to 0.05 steps inside 0.50-3.00.
double snapSpeedX(double v) => ((v.clamp(0.5, 3.0)) * 20).round() / 20;

/// Words per minute pace to px/s for the novel scroll layout.
double novelPxPerSecond(double paceWpm, double speedX, double lineHeightPx, double avgWordsPerLine) =>
    (paceWpm * speedX / 60) * lineHeightPx / math.max(avgWordsPerLine, 1);

/// Eases the effective rate toward a new target over [ramp] along [curve]; elapsed-time based.
class RateRamp {
  RateRamp({required this.ramp, required this.curve, double initial = 0}) : _from = initial, _to = initial;
  final Duration ramp;
  final double Function(double t) curve;
  double _from, _to;
  double _t = 1;

  double get rate => _from + (_to - _from) * curve(_t);
  double get target => _to;

  void retarget(double to) {
    if (to == _to) return;
    _from = rate;
    _to = to;
    _t = 0;
  }

  /// Advance by [dt] and return the distance covered in px (trapezoid over the step).
  double advance(Duration dt) {
    final before = rate;
    _t = math.min(1, _t + dt.inMicroseconds / math.max(ramp.inMicroseconds, 1));
    final after = rate;
    return (before + after) / 2 * dt.inMicroseconds / 1e6;
  }
}

enum AutoScrollState { off, running, paused }

