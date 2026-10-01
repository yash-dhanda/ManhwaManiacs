import 'dart:ui' show Offset, Rect, lerpDouble;

/// How far the phone sheet has travelled from `medium` (0) to `large` (1), from the sheet's top edge in screen y.
double collapseProgress(double sheetTop, double mediumTop, double largeTop) {
  if (mediumTop <= largeTop) return 1;
  return ((mediumTop - sheetTop) / (mediumTop - largeTop)).clamp(0.0, 1.0);
}

/// The transform that carries the 112 × 168 header cover into the 24 px thumbnail of the title capsule.
typedef CoverToCapsule = ({double scale, Offset offset});

/// At [p] 0 the cover sits in [headerSlot]; at 1 it fills [capsuleThumb] (scale about its top-left).
CoverToCapsule coverToCapsule(double p, Rect headerSlot, Rect capsuleThumb) {
  final t = p.clamp(0.0, 1.0);
  final end = capsuleThumb.width / headerSlot.width;
  return (
    scale: lerpDouble(1, end, t)!,
    offset: Offset.lerp(Offset.zero, capsuleThumb.topLeft - headerSlot.topLeft, t)!,
  );
}
