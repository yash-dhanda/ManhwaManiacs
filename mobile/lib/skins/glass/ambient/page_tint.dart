import 'dart:ui';

import 'package:manhwamaniacs/skins/glass/screens/reader/page_tint_chrome.dart';

export 'package:manhwamaniacs/skins/glass/screens/reader/page_tint_chrome.dart' show PageTint, clampTint, deltaE, gatedTint, rimTint;

/// Page-tinted chrome rules (glass 9.4.4), pure.

/// Above this the tint holds: a fling is not a place to recolour the chrome (it is applied when the fling settles).
const double kTintFlingHold = 3000;

/// A new tint applies only past a Delta E of 0.04, and never while `abs(scrollVelocity) > 3000` px/s.
bool shouldApply(Color? current, Color next, double velocityPxPerS) {
  if (velocityPxPerS.abs() > kTintFlingHold) return false;
  return current == null || deltaE(current, next) > PageTint.gate;
}

/// Turns the page samples into the chrome's tint: the clamped sample when it changes enough and the strip is calm; a greyscale sample
/// (`null`) keeps the previous tint, and after [greyLimit] of them in a row the series cover palette's `a[0]` takes over through the
/// same clamp.
class TintFollower {
  TintFollower({this.greyLimit = 6});
  final int greyLimit;

  /// The series cover palette's first colour, when the screen has it.
  Color? cover;

  Color? current;
  int _grey = 0;

  /// The tint after [sample] (null for a greyscale page) at [velocity] px/s.
  Color? feed(Color? sample, double velocity) {
    Color? next;
    if (sample != null) {
      _grey = 0;
      next = clampTint(sample);
    } else {
      _grey++;
      if (_grey >= greyLimit && cover != null) next = clampTint(cover!);
    }
    if (next != null && shouldApply(current, next, velocity)) current = next;
    return current;
  }

  void reset() {
    current = null;
    _grey = 0;
  }
}

/// The novel chrome's tint is the paper's ink at 12 % (glass 9.4.4): the tint layer's colour; the rim tint is `rimTint(ink)`.
Color novelTint(Color ink) => ink.withValues(alpha: 0.12);
