import 'package:flutter/physics.dart' show SpringSimulation;
import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/features/reader/engine/page_turn.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// The page (in page units) a release settles on: the neighbour when the drag passed 72 px or the
/// velocity exceeds 600 px/s in the same direction, else the page the drag left. [pixels] and
/// [velocity] are in the scroll axis (a higher offset is a later view, whatever the reading
/// direction: `PageView.reverse` mirrors the axis, so no mirroring is needed here).
double cinePageTarget({required double pixels, required double viewport, required double velocity}) {
  final f = pixels / viewport;
  final base = velocity > 0 ? f.floor() : (velocity < 0 ? f.ceil() : f.round());
  final travel = (f - base) * viewport;
  final dir = velocity != 0 ? (velocity > 0 ? 1 : -1) : (travel > 0 ? 1 : -1);
  final passed = travel * dir >= kTurnCommitPx;
  final fast = velocity.abs() >= kTurnCommitVelocity;
  return (passed || fast) ? (base + dir).toDouble() : base.toDouble();
}

/// Finger-tracked page physics of the Cinematic reader: commit at 72 px or 600 px/s, settle on the
/// 504 ms release spring (`CineSprings.release`, bounce 0).
class CinePagePhysics extends PageScrollPhysics {
  const CinePagePhysics({super.parent});

  @override
  CinePagePhysics applyTo(ScrollPhysics? ancestor) => CinePagePhysics(parent: buildParent(ancestor));

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final tol = toleranceFor(position);
    final vp = position.viewportDimension;
    final target = (cinePageTarget(pixels: position.pixels, viewport: vp, velocity: velocity) * vp)
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    if ((target - position.pixels).abs() < tol.distance && velocity.abs() < tol.velocity) return null;
    return SpringSimulation(CineSprings.release.description, position.pixels, target, velocity, tolerance: tol);
  }
}
