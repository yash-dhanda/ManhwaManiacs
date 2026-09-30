import 'dart:math' as math;
import 'dart:ui' show Offset, Rect, Size;

import 'package:flutter/foundation.dart' show ChangeNotifier;
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

/// A camera transform: uniform [scale] and a translation, applied to the page layer.
class CameraPose {
  const CameraPose(this.scale, this.dx, this.dy);
  static const CameraPose identity = CameraPose(1, 0, 0);
  final double scale, dx, dy;

  Matrix4 toMatrix() => Matrix4.identity()
    ..translateByDouble(dx, dy, 0, 1)
    ..scaleByDouble(scale, scale, 1, 1);

  static CameraPose lerp(CameraPose a, CameraPose b, double t) =>
      CameraPose(a.scale + (b.scale - a.scale) * t, a.dx + (b.dx - a.dx) * t, a.dy + (b.dy - a.dy) * t);

  static CameraPose of(Matrix4 m) => CameraPose(m.storage[0], m.storage[12], m.storage[13]);
}

/// The guided layout's camera (glass 15.4 `setCamera`, `cameraRect`, `pageToViewport`,
/// `viewportToPage`): one page at a time, fitted (contain) in the viewport at pose identity, with
/// the [pose] on top. Skin-neutral: the skin passes durations, curves and springs.
class ReaderCamera extends ChangeNotifier {
  /// The viewport in logical px; set by whoever lays the stage out.
  Size viewport = Size.zero;

  /// Width / height of a page (0.7 when unknown).
  double Function(int page) pageAspect = (_) => 0.7;

  bool active = false;
  int page = 1;
  CameraPose pose = CameraPose.identity;
  CameraTarget? target;

  /// The rect the camera is fitted on, or null when showing a whole page.
  CameraTarget? get cameraRect => target;

  /// The page laid out at pose identity: contained in the viewport, centred.
  Rect pageRectPx(int p) {
    final ar = pageAspect(p);
    final vr = viewport.width / (viewport.height == 0 ? 1 : viewport.height);
    final w = ar >= vr ? viewport.width : viewport.height * ar;
    final h = ar >= vr ? viewport.width / ar : viewport.height;
    return Rect.fromLTWH((viewport.width - w) / 2, (viewport.height - h) / 2, w, h);
  }

  /// Viewport px of a point given in page fractions of [p], current pose applied.
  Offset pageToViewport(int p, double x, double y) {
    final r = pageRectPx(p);
    final base = Offset(r.left + x * r.width, r.top + y * r.height);
    if (p != page) return base;
    return Offset(base.dx * pose.scale + pose.dx, base.dy * pose.scale + pose.dy);
  }

  /// The page and fractions under a viewport point (the camera's page).
  (int, Offset) viewportToPage(Offset point) {
    final r = pageRectPx(page);
    final base = Offset((point.dx - pose.dx) / pose.scale, (point.dy - pose.dy) / pose.scale);
    return (page, Offset((base.dx - r.left) / r.width, (base.dy - r.top) / r.height));
  }

  /// The pose that fits [t] within 24 px margins at most 3x.
  CameraPose poseFor(CameraTarget t, {double margin = 24, double maxScale = 3}) {
    final r = pageRectPx(t.page);
    final px = Rect.fromLTWH(
      r.left + t.fraction.left * r.width,
      r.top + t.fraction.top * r.height,
      t.fraction.width * r.width,
      t.fraction.height * r.height,
    );
    return CameraPose.of(fitRect(px, viewport, margin: margin, maxScale: maxScale));
  }

  /// The whole page, no camera rect.
  void showWholePage(int p) {
    page = p;
    target = null;
    pose = CameraPose.identity;
    notifyListeners();
  }

  /// Sets the pose directly (a cut, or one animation frame).
  void setPose(CameraPose next, {CameraTarget? target, int? page}) {
    if (page != null) this.page = page;
    if (target != null || page != null) this.target = target;
    pose = next;
    notifyListeners();
  }
}
