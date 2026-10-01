import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/features/novels/models/glass_novel_prefs.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';

/// What a tap on a paged page does (glass 8.15.4).
enum PageTapAction { back, menu, forward }

/// The tap bands (G3). Novels read left to right, so the bands never mirror. `standard` 25 / 50 / 25 %; `bothMargins` sends
/// both side bands forward; `oneHand` is the left 20 % back, the top 12 % across the full width menu, the rest forward.
PageTapAction tapBand(GlassTapZones zones, Offset at, Size size) {
  final x = size.width <= 0 ? 0.5 : at.dx / size.width;
  final y = size.height <= 0 ? 0.5 : at.dy / size.height;
  switch (zones) {
    case GlassTapZones.standard:
      if (x < 0.25) return PageTapAction.back;
      if (x >= 0.75) return PageTapAction.forward;
      return PageTapAction.menu;
    case GlassTapZones.bothMargins:
      return x < 0.25 || x >= 0.75 ? PageTapAction.forward : PageTapAction.menu;
    case GlassTapZones.oneHand:
      if (y < 0.12) return PageTapAction.menu;
      if (x < 0.20) return PageTapAction.back;
      return PageTapAction.forward;
  }
}

/// Which page a release settles on (G4): the projection `x + 0.499 v` (glass 4.4), past half the width turns, never more than one
/// page from where the drag started ([from]).
int slideTarget({required double pixels, required double velocity, required double pageWidth, required int from}) {
  if (pageWidth <= 0) return from;
  final projected = project(pixels, velocity) / pageWidth;
  return projected.round().clamp(from - 1, from + 1);
}

/// Lift and keys share the commit rule: progress (drag over width, the release projected) past 0.5 turns.
bool liftCommits(double dragPx, double velocityPxPerS, double pageWidth) =>
    pageWidth > 0 && (project(dragPx, velocityPxPerS) / pageWidth).abs() > 0.5;

/// The Slide physics (G4): the page follows the finger 1:1, the release projects and settles on `springPage` with the release
/// velocity.
class GlassPagePhysics extends PageScrollPhysics {
  const GlassPagePhysics({super.parent});

  @override
  GlassPagePhysics applyTo(ScrollPhysics? ancestor) => GlassPagePhysics(parent: buildParent(ancestor));

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    if ((velocity <= 0 && position.pixels <= position.minScrollExtent) || (velocity >= 0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final w = position.viewportDimension;
    // The page the drag left: behind the finger's direction.
    final from = velocity >= 0 ? (position.pixels / w).floor() : (position.pixels / w).ceil();
    final page = slideTarget(pixels: position.pixels, velocity: velocity, pageWidth: w, from: from);
    final target = (page * w).clamp(position.minScrollExtent, position.maxScrollExtent);
    if ((target - position.pixels).abs() < toleranceFor(position).distance) return null;
    return ScrollSpringSimulation(springOf(glassTokens.springPage), position.pixels, target, velocity, tolerance: toleranceFor(position));
  }
}
