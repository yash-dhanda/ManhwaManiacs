import 'dart:math' as math;
import 'dart:ui' show Rect, Size;

import 'package:flutter/widgets.dart' show Matrix4;

/// A camera target: [fraction] is a rect in page fractions of [page].
class CameraTarget {
  const CameraTarget(this.page, this.fraction);
  final int page;
  final Rect fraction;

  @override
  bool operator ==(Object other) => other is CameraTarget && other.page == page && other.fraction == fraction;
  @override
  int get hashCode => Object.hash(page, fraction);
}

/// The transform that fits [rectPx] (viewport px at scale 1) inside [viewport] within [margin] on
/// every side, at a scale of at most [maxScale], centred.
Matrix4 fitRect(Rect rectPx, Size viewport, {double margin = 24, double maxScale = 3}) {
  final aw = math.max(viewport.width - 2 * margin, 1);
  final ah = math.max(viewport.height - 2 * margin, 1);
  final scale = math.min(math.min(aw / rectPx.width, ah / rectPx.height), maxScale);
  final tx = viewport.width / 2 - rectPx.center.dx * scale;
  final ty = viewport.height / 2 - rectPx.center.dy * scale;
  return Matrix4.identity()
    ..translateByDouble(tx, ty, 0, 1)
    ..scaleByDouble(scale, scale, 1, 1);
}

/// A panel taller than the viewport is walked in steps of 75 % of the viewport height: the rect
/// slices the camera visits, top to bottom. A panel that fits gives one step (itself).
List<Rect> tallPanelSteps(Rect rectPx, Size viewport) {
  if (rectPx.height <= viewport.height) return [rectPx];
  final step = viewport.height * 0.75;
  final out = <Rect>[];
  var top = rectPx.top;
  while (true) {
    final h = math.min(viewport.height, rectPx.bottom - top);
    out.add(Rect.fromLTWH(rectPx.left, top, rectPx.width, h));
    if (top + viewport.height >= rectPx.bottom) break;
    top += step;
  }
  // Last slice always shows the panel's bottom edge at full viewport height.
  final last = out.last;
  if (last.height < viewport.height) {
    out[out.length - 1] = Rect.fromLTWH(last.left, rectPx.bottom - viewport.height, last.width, viewport.height);
  }
  return out;
}
