import 'dart:ui' show Offset, Rect;

class LensTransform {
  const LensTransform(this.scale, this.origin);
  final double scale;
  final Offset origin;
}

class LensClip {
  const LensClip(this.rect, this.radius);
  final Rect rect;
  final double radius;
}

class LensPage {
  const LensPage(this.index, this.rect);
  final int index;

  /// Relative to the clip's top-left, before the layer's scale about the origin.
  final Rect rect;
}

/// The copies the lens layer draws: the pages whose rects intersect [clip], positioned relative
/// to the clip so that at scale 1 each lines up with the page beneath. [t] scales the layer
/// about [LensTransform.origin] (viewport coordinates); that is applied by the layer's `Transform`.
List<LensPage> lensLayout(List<Rect> pageRects, LensClip clip, LensTransform t) {
  final out = <LensPage>[];
  for (var i = 0; i < pageRects.length; i++) {
    final r = pageRects[i];
    if (!r.overlaps(clip.rect)) continue;
    out.add(LensPage(i, r.shift(-clip.rect.topLeft)));
  }
  return out;
}

/// Where the viewport point [p] lands after scaling by [t] about its origin.
Offset lensMap(Offset p, LensTransform t) => t.origin + (p - t.origin) * t.scale;
