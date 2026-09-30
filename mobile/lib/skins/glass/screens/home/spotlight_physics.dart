import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';

/// The most a spotlight drags past its first or last card: 25 % of the width (glass 4.5).
double spotlightOverscrollCap(double width) => width * 0.25;

/// The rubber-banded overscroll for a raw pull of [x] px past an end: `rubberband(x, width, 0.55)` capped at 25 % of [width].
double spotlightRubber(double x, double width) {
  final r = rubberband(x, width);
  final cap = spotlightOverscrollCap(width);
  return r.abs() > cap ? cap * r.sign : r;
}

/// The page a release at [velocity] settles on: the projection, capped to one viewport, rounded, and never more than one page from
/// the page the finger started nearest to (one card per flick, glass 4.4).
int spotlightTargetPage(double pixels, double velocity, double width, int pages) {
  final from = (pixels / width).round();
  final projected = projectCapped(pixels, velocity, width);
  final page = (projected / width).round().clamp(from - 1, from + 1);
  return page.clamp(0, pages - 1);
}

/// Page physics of the Home spotlight: one card per flick, settling on `springSettle`, a rubber band capped at 25 % at both ends.
class SpotlightPhysics extends ScrollPhysics {
  const SpotlightPhysics({super.parent});

  @override
  SpotlightPhysics applyTo(ScrollPhysics? ancestor) => SpotlightPhysics(parent: buildParent(ancestor));

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    final w = position.viewportDimension;
    final cap = spotlightOverscrollCap(w);
    final next = position.pixels - offset;
    final over = next < position.minScrollExtent ? position.minScrollExtent - next : (next > position.maxScrollExtent ? next - position.maxScrollExtent : 0.0);
    if (over == 0) return offset;
    // Past an end the finger moves the card at `rubberband` friction, never beyond the cap.
    final already = position.pixels < position.minScrollExtent ? position.minScrollExtent - position.pixels : (position.pixels > position.maxScrollExtent ? position.pixels - position.maxScrollExtent : 0.0);
    final raw = already + (over - already) * 1.0;
    final target = spotlightRubber(raw, w).clamp(0.0, cap);
    final sign = next < position.minScrollExtent ? -1.0 : 1.0;
    final edge = sign < 0 ? position.minScrollExtent : position.maxScrollExtent;
    return position.pixels - (edge + sign * target);
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) => 0;

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    final w = position.viewportDimension;
    final tol = toleranceFor(position);
    if (position.pixels < position.minScrollExtent || position.pixels > position.maxScrollExtent) {
      final edge = position.pixels < position.minScrollExtent ? position.minScrollExtent : position.maxScrollExtent;
      return ScrollSpringSimulation(springOf(GlassSprings.settle), position.pixels, edge, velocity, tolerance: tol);
    }
    final pages = (position.maxScrollExtent / w).round() + 1;
    final target = spotlightTargetPage(position.pixels, velocity, w, pages) * w;
    if ((target - position.pixels).abs() < tol.distance && velocity.abs() < tol.velocity) return null;
    return ScrollSpringSimulation(springOf(GlassSprings.settle), position.pixels, target, velocity, tolerance: tol);
  }

  @override
  bool get allowImplicitScrolling => false;
}
