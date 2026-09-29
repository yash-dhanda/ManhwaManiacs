import 'dart:math' as math;

import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';

/// glass 7.21 / 8.14.2 / 8.16.3: the pure maths of sliders, the scrub rail and the speed dial.

/// The nearest step index of a value at [pos] (0 to [steps] positions over the track).
int nearestStep(double pos, double spacing, int steps) => (pos / spacing).round().clamp(0, steps);

/// Within 30 % of the step spacing (`physicsValueMagnetStepFraction`) the thumb is pulled to the step; between
/// steps it follows the finger. Returns the thumb position and whether a step holds it.
({double pos, bool magnet}) stepMagnet(double pos, double spacing, int steps) {
  final i = nearestStep(pos, spacing, steps);
  final at = i * spacing;
  if ((pos - at).abs() <= glassTokens.physicsValueMagnetStepFraction * spacing) return (pos: at, magnet: true);
  return (pos: pos, magnet: false);
}

/// Past min or max the thumb rubber-bands at most 12 px (`rubberband` with d = the track length).
double sliderRubber(double overshoot, double trackLength) {
  final r = rubberband(overshoot.abs(), trackLength, glassTokens.physicsRubberBandC);
  return overshoot.sign * math.min(12, r);
}

/// The dial: 6 px per 0.05, 0.5x to 3.0x.
const double kDialMin = 0.5, kDialMax = 3.0, kDialStep = 0.05, kDialPxPerStep = 6, kDialMagnetBand = 0.08;

/// The raw (unclamped, unquantised) value of a vertical drag: up raises it.
double dialRaw(double startValue, double dy) => startValue - dy / kDialPxPerStep * kDialStep;

/// Quantise to 0.05 and clamp; the ±0.08 magnet at 1.0 pulls values near 1x to 1x.
({double value, bool magnet}) dialValue(double raw) {
  var v = (raw.clamp(kDialMin, kDialMax) / kDialStep).round() * kDialStep;
  v = double.parse(v.toStringAsFixed(2));
  if ((raw - 1.0).abs() <= kDialMagnetBand) return (value: 1.0, magnet: true);
  return (value: v, magnet: false);
}

/// How far past the ends a raw dial value is, in px, rubber-banded to at most 12.
double dialOvershootPx(double raw) {
  final over = raw > kDialMax ? raw - kDialMax : (raw < kDialMin ? raw - kDialMin : 0.0);
  if (over == 0) return 0;
  return sliderRubber(over / kDialStep * kDialPxPerStep, 240);
}

/// True when the value moved across a multiple of 0.25x (the 0.05 steps are silent).
bool dialTick(double from, double to) => (from / 0.25).floor() != (to / 0.25).floor();

/// The page under a thumb at [fraction] (0 to 1 down the rail) of [pageCount].
int scrubPage(double fraction, int pageCount) => pageCount <= 1 ? 0 : (fraction.clamp(0.0, 1.0) * (pageCount - 1)).round();

/// The rail position of [page] (the thumb snaps page by page).
double scrubFraction(int page, int pageCount) => pageCount <= 1 ? 0 : page / (pageCount - 1);

/// The page a released thumb settles on (projection to the nearest page).
int scrubProjectedPage(double fraction, double velocityFractionPerS, int pageCount) =>
    scrubPage(fraction + velocityFractionPerS * 0.499, pageCount);
