import 'dart:math' as math;

import 'package:manhwamaniacs/features/reader/utils/glass_reader_values.dart';

/// Cruise maths (glass 9.4.1, 4.6). Pure: the controller and the pill call these, never the other way round.
abstract final class Cruise {
  /// Vertical drag on the pill: 8 px per 0.05x.
  static const double pxPerStep = 8, step = 0.05;

  /// Ticks fire every 0.25x; the keys and the semantics actions step by it.
  static const double tick = 0.25;

  /// Within this of 1.0x the value shows and applies as exactly 1.0 (`physicsValueMagnetSpeed`, 12.8 px of drag).
  static const double magnetBand = 0.08;

  /// The engine's flick-to-cruise ceiling and the hold-off before a release resumes.
  static const double engageBelowPxPerS = 240, resumeBelowPxPerS = 15;
  static const Duration resumeDelay = Duration(milliseconds: 800), ramp = Duration(milliseconds: 400);
}

double clampSpeed(double m) => m.clamp(kGlassCruiseMin, kGlassCruiseMax);

/// Manga: 60 px/s at 1.0x, so 15 to 240 px/s over the range.
double mangaPxPerSecond(double m) => 60 * clampSpeed(m);

/// Novel scroll mode (glass 8.15.4): `m x (wpm / 60) / wordsPerLine x lineHeightPx`.
double novelPxPerSecond(double m, {required double wpm, required double wordsPerLine, required double lineHeightPx}) =>
    clampSpeed(m) * (wpm / 60) / math.max(wordsPerLine, 1) * lineHeightPx;

/// The multiplier for a coasting scroll at [pxPerSecond] (the flick that engages cruise): round(v / 60, 0.05).
double speedForVelocity(double pxPerSecond) => snapCruise(pxPerSecond / 60);

/// The raw (unsnapped, unmagnetised) value after dragging [dy] px (up is negative) from [start].
double rawAfterDrag(double start, double dy) => clampSpeed(start - dy / Cruise.pxPerStep * Cruise.step);

/// What the pill shows and applies for a raw value: the 0.05 grid with the 1.0x magnet.
double settle(double raw) => cruiseMagnet(raw);

/// "1.0×" and "1.25×": one decimal, two when the second is not zero.
String formatSpeed(double m) {
  final s = m.toStringAsFixed(2);
  return '${s.endsWith('0') ? s.substring(0, s.length - 1) : s}×';
}

/// A multiple of 0.25 crossed between two values (an `autoscroll.step` tick), or null.
double? tickCrossed(double from, double to) {
  if (from == to) return null;
  final a = (from / Cruise.tick).floor(), b = (to / Cruise.tick).floor();
  if (a == b) return null;
  return (to > from ? b : a) * Cruise.tick;
}

/// Whether a release velocity engages cruise from a flick: forward (content moving up) coasting at or below 240 px/s and
/// above the resume floor. [v] is the engine's `scrollVelocity` (px/s, positive while reading forward).
bool engages(double v) => v > Cruise.resumeBelowPxPerS && v <= Cruise.engageBelowPxPerS;
