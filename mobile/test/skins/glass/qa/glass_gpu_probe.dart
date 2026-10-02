import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Offscreen passes in the frame just painted: backdrop reads, image-filter layers (blur), shader masks and opacity save layers.
class GpuPasses {
  GpuPasses(this.backdrop, this.imageFilter, this.shaderMask);
  final int backdrop;
  final int imageFilter;
  final int shaderMask;
  int get blur => backdrop + imageFilter;
  @override
  String toString() => 'backdrop $backdrop, imageFilter $imageFilter, shaderMask $shaderMask';
}

GpuPasses countGpuPasses(WidgetTester t) {
  var b = 0, i = 0, s = 0;
  void walk(Layer? l) {
    for (var c = l; c != null; c = c.nextSibling) {
      if (c is BackdropFilterLayer) b++;
      if (c is ImageFilterLayer) i++;
      if (c is ShaderMaskLayer) s++;
      if (c is ContainerLayer) walk(c.firstChild);
    }
  }

  for (final v in t.binding.renderViews) {
    walk(v.debugLayer);
  }
  return GpuPasses(b, i, s);
}
