import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';

/// The paged reader's finger physics (glass 8.14.1, 4.4): the release's projection decides (past half a page commits, at most
/// one page per release) and the page settles on `springPage` carrying the release velocity.
class GlassPagePhysics extends ScrollPhysics {
  const GlassPagePhysics({super.parent});

  @override
  GlassPagePhysics applyTo(ScrollPhysics? ancestor) => GlassPagePhysics(parent: buildParent(ancestor));

  /// The page a release at [pixels] with [velocity] lands on, for pages [extent] tall: the nearest page to the projection,
  /// kept to one of the two pages the release sits between.
  static double targetPage(double pixels, double velocity, double extent) {
    final at = pixels / extent;
    return (project(pixels, velocity) / extent).roundToDouble().clamp(at.floorToDouble(), at.ceilToDouble());
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    if ((velocity <= 0 && position.pixels <= position.minScrollExtent) || (velocity >= 0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final extent = position.viewportDimension;
    if (extent <= 0) return super.createBallisticSimulation(position, velocity);
    final target = (targetPage(position.pixels, velocity, extent) * extent).clamp(position.minScrollExtent, position.maxScrollExtent);
    if ((target - position.pixels).abs() < 0.5 && velocity.abs() < toleranceFor(position).velocity) return null;
    return ScrollSpringSimulation(springOf(glassTokens.springPage), position.pixels, target, velocity, tolerance: toleranceFor(position));
  }

  @override
  bool get allowImplicitScrolling => false;
}
