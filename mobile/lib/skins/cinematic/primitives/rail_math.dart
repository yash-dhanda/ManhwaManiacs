import 'dart:math' as math;

/// Visible posters per rail: phone 3.2, tablet (width >= 600) 5.2; a phone at text scale >= 1.3
/// shows 2.3 (cinematic 7.8, 3.3).
double railVisible({required double width, double textScale = 1.0}) {
  if (width >= 600) return 5.2;
  return textScale >= 1.3 ? 2.3 : 3.2;
}

/// Gap between posters: phone 8, tablet 12.
double railGap(double width) => width >= 600 ? 12 : 8;

/// `(content width - floor(visible) x gap) / visible`.
double railPosterWidth({required double contentWidth, required double visible, required double gap}) =>
    (contentWidth - visible.floorToDouble() * gap) / visible;

/// The scroll offset that puts poster [index] first, clamped to [maxExtent].
double railSnapOffset({required double offset, required double posterWidth, required double gap, required double maxExtent}) {
  final step = posterWidth + gap;
  final k = (offset / step).round();
  return math.min(math.max(0, k * step), maxExtent);
}

/// The offset that brings poster [index] fully into view from the left (arrow keys, 7.8).
double railRevealOffset({required int index, required double offset, required double viewport, required double posterWidth, required double gap, required double maxExtent}) {
  final step = posterWidth + gap;
  final left = index * step, right = left + posterWidth;
  if (left < offset) return math.max(0, left);
  if (right > offset + viewport) return math.min(maxExtent, right - viewport);
  return offset;
}
