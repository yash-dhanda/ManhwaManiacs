import 'dart:ui' show Offset, Size;

/// Paged zoom limits (cinematic 8.14.7): 1x to 3x.
const double kPagedZoomMin = 1.0;
const double kPagedZoomMax = 3.0;

/// The pan (offset of the content centre from the viewport centre) that keeps the content point
/// under [focal] fixed while the scale goes from [oldScale] to [newScale], clamped so the scaled
/// content still covers the viewport [size].
Offset panForFocal({
  required Offset focal,
  required Size size,
  required Offset oldPan,
  required double oldScale,
  required double newScale,
}) {
  if (newScale <= 1.0) return Offset.zero;
  final centre = Offset(size.width / 2, size.height / 2);
  final rel = focal - centre;
  final content = (rel - oldPan) / oldScale;
  return clampPan(rel - content * newScale, size, newScale);
}

/// [pan] limited to the overflow of a [scale]d viewport of [size].
Offset clampPan(Offset pan, Size size, double scale) {
  final lx = (scale - 1) * size.width / 2, ly = (scale - 1) * size.height / 2;
  return Offset(pan.dx.clamp(-lx, lx), pan.dy.clamp(-ly, ly));
}

/// Double tap in a paged layout: 1x goes to 2x, anything zoomed goes back to 1x.
double pagedDoubleTapTarget(double current) => current > 1.01 ? 1.0 : 2.0;
