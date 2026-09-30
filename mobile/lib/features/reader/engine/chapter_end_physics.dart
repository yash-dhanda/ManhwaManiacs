import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/features/reader/engine/neighbour.dart';

/// The settle spring of glass 4.x: what an overscroll below 72 px returns on.
const SpringDescription kOverscrollReturn = SpringDescription(mass: 1, stiffness: 322.3, damping: 35.9);

/// What `applyPhysicsToUserOffset` returns for a finger [offset] (drag delta: negative scrolls
/// forward) at [pixels], so the displayed overscroll follows the 0.55 band of glass 4.5 exactly.
/// Stateless: the raw travel is recovered from the displayed overscroll through the inverse.
double overscrollUserOffset(double pixels, double min, double max, double offset, double viewport) =>
    -_pixelDelta(pixels, min, max, -offset, viewport);

/// Same in the pixel domain: [offset] is the raw change of `pixels` the finger asks for.
double _pixelDelta(double pixels, double min, double max, double offset, double viewport) {
  final past = pixels > max || (pixels >= max && offset > 0);
  final before = !past && (pixels < min || (pixels <= min && offset < 0));
  if (!past && !before) return offset;
  final y0 = past ? pixels - max : min - pixels;
  final d = past ? offset : -offset; // travel that deepens the overscroll
  final x1 = (y0 >= viewport ? 1e9 : rawFromDisplayed(y0, viewport)) + d;
  if (x1 <= 0) return past ? -y0 + x1 : y0 - x1; // back across the edge: the rest is in range
  final delta = displayedFromRaw(x1, viewport) - y0;
  return past ? delta : -delta;
}

/// One-at-a-time chapters: inside the chapter everything is the [parent]'s; past either end the
/// finger follows the rubber band, a release below 72 displayed px springs back and a release at
/// 72 holds for `commitNeighbour`.
class ChapterEndPhysics extends ScrollPhysics {
  const ChapterEndPhysics({super.parent, this.spring = kOverscrollReturn});
  @override
  final SpringDescription spring;

  @override
  ChapterEndPhysics applyTo(ScrollPhysics? ancestor) =>
      ChapterEndPhysics(parent: buildParent(ancestor), spring: spring);

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    final atEdgeOut = (position.pixels >= position.maxScrollExtent && offset < 0) ||
        (position.pixels <= position.minScrollExtent && offset > 0);
    if (position.outOfRange || atEdgeOut) {
      return overscrollUserOffset(
          position.pixels, position.minScrollExtent, position.maxScrollExtent, offset, position.viewportDimension,);
    }
    return super.applyPhysicsToUserOffset(position, offset);
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    if (!position.outOfRange) return super.createBallisticSimulation(position, velocity);
    final edge = position.pixels > position.maxScrollExtent ? position.maxScrollExtent : position.minScrollExtent;
    if ((position.pixels - edge).abs() >= commitPx) return null;
    return ScrollSpringSimulation(spring, position.pixels, edge, velocity, tolerance: toleranceFor(position));
  }
}
