import 'dart:math' as math;
import 'dart:ui';

import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';

/// glass 7.31: the maths of the image viewer.
const double kZoomMin = 1, kZoomMax = 4, kZoomDouble = 2.5, kZoomRubber = 0.18;

/// The translation that keeps [focal] (a screen point) fixed while the scale goes from [s0] to [s1].
Offset zoomAround({required Offset focal, required Offset translation, required double s0, required double s1}) =>
    focal - (focal - translation) * (s1 / s0);

/// A scale within 1 to 4 stays; past them it rubber-bands at most 0.18 (`zoom.limit` fires there).
double rubberScale(double s) {
  if (s > kZoomMax) return kZoomMax + math.min(kZoomRubber, rubberband(s - kZoomMax, kZoomRubber * 4, glassTokens.physicsRubberBandC));
  if (s < kZoomMin) return kZoomMin - math.min(kZoomRubber, rubberband(kZoomMin - s, kZoomRubber * 4, glassTokens.physicsRubberBandC));
  return s;
}

bool scaleAtLimit(double s) => s >= kZoomMax || s <= kZoomMin;

/// A second tap within 280 ms and 24 px of the first is a double tap (single taps are never delayed).
bool isDoubleTap({required Duration dt, required double distance}) =>
    dt.inMilliseconds <= glassTokens.thresholdDoubleTapWindow && distance <= glassTokens.thresholdDoubleTapSlop;

/// The scale a double tap goes to: 1x to 2.5x, anything else back to 1x.
double doubleTapTarget(double scale) => scale < 1.5 ? kZoomDouble : kZoomMin;

/// At 1x a vertical drag dismisses: scale `1 - min(|dy| / 1200, 0.15)`, radius 0 to 28, backdrop `1 - min(|dy| / 320, 1)`.
double dismissScale(double dy) => 1 - math.min(dy.abs() / 1200, 0.15);
double dismissRadius(double dy) => 28 * math.min(dy.abs() / 180, 1);
double dismissBackdrop(double dy) => 1 - math.min(dy.abs() / 320, 1);

/// A release whose projection passes 180 px, or with |vy| >= 800 px/s, flies back into the thumbnail.
bool shouldDismissImage(double dy, double vy) =>
    project(dy, vy).abs() >= glassTokens.thresholdImageDismiss || vy.abs() >= glassTokens.thresholdImageDismissVelocity;

/// The largest translation (each side) that keeps the zoomed image covering the viewport.
Offset panLimit({required Size image, required Size viewport, required double scale}) =>
    Offset(math.max(0, (image.width * scale - viewport.width) / 2), math.max(0, (image.height * scale - viewport.height) / 2));

/// A translation clamped to +-[limit]; past it, a rubber band of at most 40 px.
double panClamp(double t, double limit, {bool rubber = true}) {
  if (t.abs() <= limit) return t;
  final over = t.abs() - limit;
  return t.sign * (limit + (rubber ? math.min(40, rubberband(over, 400, glassTokens.physicsRubberBandC)) : 0));
}
