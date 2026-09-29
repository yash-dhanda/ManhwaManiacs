import 'dart:math' as math;
import 'dart:ui';

/// Lightbox maths (cinematic 7.30, pure).
const double kLightboxBarrier = 0.96;

/// The art at rest: `contain` in [viewport], never larger than 1.5 x its natural pixels (a
/// 720 x 1080 cover shows at most 1080 x 1620 logical px).
Size lightboxFitSize(Size natural, Size viewport) {
  if (natural.isEmpty) return Size.zero;
  final contain = math.min(viewport.width / natural.width, viewport.height / natural.height);
  return natural * math.min(contain, 1.5);
}

/// Barrier opacity while dragging down by [dy]: `0.96 * (1 - dy / 400)`.
double lightboxBarrierOpacity(double dy) => (kLightboxBarrier * (1 - dy.abs() / 400)).clamp(0.0, kLightboxBarrier);

/// A release dismisses past 120 px or faster than 800 px/s.
bool lightboxShouldDismiss(double dy, double velocityPxPerS) => dy.abs() > 120 || velocityPxPerS.abs() > 800;

/// The zoom chip text, `250%`.
String lightboxZoomLabel(double scale) => '${(scale * 100).round()}%';
