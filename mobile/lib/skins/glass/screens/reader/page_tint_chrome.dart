import 'dart:math' as math;
import 'dart:ui';

import 'package:manhwamaniacs/core/color/oklch.dart';

/// Page-tinted chrome (glass 9.4.4): the sample's tint is clamped to L 0.35-0.50 and C <= 0.12, the rim tint to L 0.86 and
/// C <= 0.08; a new tint applies only past a Delta E (OKLab) of 0.04.
abstract final class PageTint {
  /// Inside every reader glass surface.
  static const double layer = 0.18;

  /// On the rims.
  static const double rim = 0.22;

  /// The soft edges, the minimised pill's inner glow and the micro-progress line.
  static const double edge = 0.30;

  static const double gate = 0.04;
}

/// The tint layer's colour: the sample clamped to L 0.35-0.50 and C <= 0.12, hue kept.
Color clampTint(Color c) {
  final o = oklchFromColor(c);
  return colorFromOklch(Oklch(o.l.clamp(0.35, 0.50), math.min(o.c, 0.12), o.h));
}

/// The rim's colour: L 0.86 and C <= 0.08 on the sample's hue.
Color rimTint(Color c) {
  final o = oklchFromColor(c);
  return colorFromOklch(Oklch(0.86, math.min(o.c, 0.08), o.h));
}

/// Euclidean distance in OKLab.
double deltaE(Color a, Color b) {
  final (l1, a1, b1) = srgbToOklab(a.r, a.g, a.b);
  final (l2, a2, b2) = srgbToOklab(b.r, b.g, b.b);
  return math.sqrt(math.pow(l1 - l2, 2) + math.pow(a1 - a2, 2) + math.pow(b1 - b2, 2));
}

/// The tint the chrome should move to: [next] when it differs from [current] by more than the gate, else [current].
Color? gatedTint(Color? current, Color? next) {
  if (next == null) return current;
  if (current == null) return next;
  return deltaE(current, next) > PageTint.gate ? next : current;
}
