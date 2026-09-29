import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// The six greeked bars of a neighbour tab's galley proof (cinematic 11 "Horizontal swipe"):
/// widths in percent of the content width, 56 px apart.
const List<int> kHubProofWidths = [92, 78, 96, 64, 88, 92];

/// Wraps the hub's content slivers: paints and hit-tests them shifted by `dx` (a finger-tracked
/// drag between tabs) and, while shifted, paints the neighbour tab's galley proof one viewport
/// width away. The masthead and the tab row are outside it and do not move.
class HubSlideSliver extends SingleChildRenderObjectWidget {
  const HubSlideSliver({
    super.key,
    required this.dx,
    required this.barColor,
    required this.barHeight,
    required this.margin,
    required this.hasPrevious,
    required this.hasNext,
    super.child,
  });

  /// The current horizontal offset; only paint listens, so a drag never rebuilds the page.
  final ValueListenable<double> dx;
  final Color barColor;

  /// 50 % of a `type.title` line height.
  final double barHeight;

  /// The grid margins the bars sit inside.
  final EdgeInsets margin;
  final bool hasPrevious, hasNext;

  @override
  RenderHubSlide createRenderObject(BuildContext context) => RenderHubSlide(
        dx: dx,
        barColor: barColor,
        barHeight: barHeight,
        margin: margin,
        hasPrevious: hasPrevious,
        hasNext: hasNext,
      );

  @override
  void updateRenderObject(BuildContext context, RenderHubSlide renderObject) => renderObject
    ..dx = dx
    ..barColor = barColor
    ..barHeight = barHeight
    ..margin = margin
    ..hasPrevious = hasPrevious
    ..hasNext = hasNext;
}

class RenderHubSlide extends RenderProxySliver {
  RenderHubSlide({
    required ValueListenable<double> dx,
    required Color barColor,
    required double barHeight,
    required EdgeInsets margin,
    required bool hasPrevious,
    required bool hasNext,
  })  : _dx = dx,
        _barColor = barColor,
        _barHeight = barHeight,
        _margin = margin,
        _hasPrevious = hasPrevious,
        _hasNext = hasNext;

  ValueListenable<double> _dx;
  Color _barColor;
  double _barHeight;
  EdgeInsets _margin;
  bool _hasPrevious, _hasNext;

  set dx(ValueListenable<double> v) {
    if (identical(v, _dx)) return;
    if (attached) _dx.removeListener(markNeedsPaint);
    _dx = v;
    if (attached) v.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  set barColor(Color v) {
    if (v == _barColor) return;
    _barColor = v;
    markNeedsPaint();
  }

  set barHeight(double v) {
    if (v == _barHeight) return;
    _barHeight = v;
    markNeedsPaint();
  }

  set margin(EdgeInsets v) {
    if (v == _margin) return;
    _margin = v;
    markNeedsPaint();
  }

  set hasPrevious(bool v) => _hasPrevious = v;
  set hasNext(bool v) => _hasNext = v;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _dx.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _dx.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null || !child.geometry!.visible) return;
    final dx = _dx.value;
    context.paintChild(child, offset + Offset(dx, 0));
    if (dx == 0) return;
    final width = constraints.crossAxisExtent;
    final neighbour = dx < 0 ? _hasNext : _hasPrevious;
    if (!neighbour) return;
    final x0 = dx + (dx < 0 ? width : -width);
    final paint = Paint()..color = _barColor;
    final top = offset.dy + 16;
    final extent = geometry!.paintExtent;
    for (var i = 0; i < kHubProofWidths.length; i++) {
      final y = top + i * 56.0;
      if (y + _barHeight > offset.dy + extent) break;
      final w = (width - _margin.horizontal) * kHubProofWidths[i] / 100;
      context.canvas.drawRect(Rect.fromLTWH(offset.dx + x0 + _margin.left, y, w, _barHeight), paint);
    }
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    transform.translateByDouble(_dx.value, 0, 0, 1);
  }

  @override
  bool hitTestChildren(SliverHitTestResult result, {required double mainAxisPosition, required double crossAxisPosition}) {
    final child = this.child;
    if (child == null || child.geometry!.hitTestExtent <= 0) return false;
    return child.hitTest(result, mainAxisPosition: mainAxisPosition, crossAxisPosition: crossAxisPosition - _dx.value);
  }
}
