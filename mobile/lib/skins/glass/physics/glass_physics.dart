
import 'dart:async';

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';
import 'package:manhwamaniacs/skins/token_types.g.dart';

/// The thickness scale of glass 2.4.3. [auto] lets a surface pick by its shorter side.
enum GlassTierId { t1, t2, t3, t4, t5, auto }

const double _decel = GlassPhysics.decelerationRate;

/// glass 4.4: where a release at [velocityPxPerS] comes to rest (`position + 0.499 v`).
double project(double position, double velocityPxPerS) =>
    position + (velocityPxPerS / 1000) * _decel / (1 - _decel);

/// [project], but never more than one viewport of [length] away.
double projectCapped(double position, double v, double cap) {
  final travel = project(position, v) - position;
  final limit = GlassPhysics.projectionCap * cap;
  return position + travel.clamp(-limit, limit);
}

double nearest(List<double> points, double x) {
  var best = points.first;
  for (final p in points) {
    if ((p - x).abs() < (best - x).abs()) best = p;
  }
  return best;
}

double railSnap(double offset, double v, double stride) =>
    (project(offset, v) / stride).round() * stride;

/// glass 4.5: `d (1 - 1 / (x c / d + 1))`, sign preserving.
double rubberband(double x, double d, [double c = GlassPhysics.rubberBandC]) {
  final a = x.abs();
  return x.sign * d * (1 - 1 / (a * c / d + 1));
}

/// Mass 1, `k = (2 pi / d)^2`, `c = 4 pi (1 - bounce) / d`. The glass tokens carry no Flutter scale.
SpringDescription springOf(SpringToken t) =>
    SpringDescription.withDurationAndBounce(duration: Duration(milliseconds: t.ms), bounce: t.bounce);

/// glass 5.1: `0.30 + 0.08 depth`.
double depthIntensity(int depth) =>
    GlassPhysics.depthIntensityBase + GlassPhysics.depthIntensityStep * depth;

/// glass 5.1: `clamp(0.3 + |v| / 4000, 0.3, 1)`.
double impactIntensity(double v) =>
    (0.3 + v.abs() / GlassPhysics.impactVelocityDivisor).clamp(0.3, 1.0);

/// glass 2.4.3 `glassSnap` [36, 57, 97]: T5 is declared, never reached by size.
GlassTierId tierFor(double shorterSide) {
  final snap = glassTokens.glassSnap;
  if (shorterSide < snap[0]) return GlassTierId.t1;
  if (shorterSide < snap[1]) return GlassTierId.t2;
  if (shorterSide < snap[2]) return GlassTierId.t3;
  return GlassTierId.t4;
}

/// glass 2.1.7: the legibility dim for a backdrop luminance [lb].
double dimFor(double lb, {bool highContrast = false}) {
  const t = glassTokens;
  final v = t.dimMin + t.dimSlope * lb;
  return highContrast ? v.clamp(t.dimMinHc, t.dimMaxHc) : v.clamp(t.dimMin, t.dimMax);
}

/// glass 3.5: text grade follows the backdrop; Bold Text adds 20.
int gradFor(double lb, {bool bold = false}) => (glassTokens.gradSlope * lb).round() + (bold ? 20 : 0);

/// `ROND` is `20 x tier`, fractional while a surface grows.
double rondFor(double tier) => 20 * tier;

/// glass 4.3: catch a spring in flight and retarget it without losing velocity.
extension CatchableSpring on AnimationController {
  /// Stops the controller and returns where it was and how fast it was moving.
  ({double value, double velocity}) catchMotion() {
    final v = velocity;
    final x = value;
    stop();
    return (value: x, velocity: v);
  }

  /// Spring toward [target]; [velocityPxPerS] over [travelPx] is the release velocity in unit space.
  TickerFuture springTo(double target, SpringToken token, {double velocityPxPerS = 0, double travelPx = 1}) {
    final v = velocityPxPerS == 0 && isAnimating ? velocity : velocityPxPerS / travelPx;
    final run = animateWith(SpringSimulation(springOf(token), value, target, v, tolerance: glassSpringTolerance((target - value).abs())));
    // Done within the tolerance: land exactly on the target unless another move has started since.
    unawaited(run.then((_) {
      if (!isAnimating) value = target;
    }),);
    return run;
  }
}

/// When a Glass spring counts as settled: within 0.5 % of its travel (the spec's settle, design/lib/spring.mjs) and slower than
/// 10 % of the travel per second. Flutter's default (1e-3 absolute) ran every move 1.3 to 2x its planned settle; this one is
/// never early and at most about 45 ms late (test/skins/glass/qa/motion_settle_test.dart).
Tolerance glassSpringTolerance(double travel) =>
    travel < 1e-6 ? Tolerance.defaultTolerance : Tolerance(distance: 0.005 * travel, velocity: 0.1 * travel);

/// Lands a fling on the nearest multiple of [stride] (rails, the voice orbit, pagers).
class SnapPhysics extends ScrollPhysics {
  const SnapPhysics({required this.stride, this.settle = GlassSprings.settle, ScrollPhysics? parent})
      : super(parent: parent ?? const BouncingScrollPhysics());

  final double stride;
  final SpringToken settle;

  @override
  SnapPhysics applyTo(ScrollPhysics? ancestor) =>
      SnapPhysics(stride: stride, settle: settle, parent: buildParent(ancestor));

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    if (position.outOfRange) return super.createBallisticSimulation(position, velocity);
    final px = position.pixels;
    var target = railSnap(px, velocity, stride);
    target = target.clamp(px - position.viewportDimension, px + position.viewportDimension);
    target = target.clamp(position.minScrollExtent, position.maxScrollExtent);
    if ((target - px).abs() < 0.01 && velocity.abs() < toleranceFor(position).velocity) return null;
    return ScrollSpringSimulation(springOf(settle), px, target, velocity, tolerance: toleranceFor(position));
  }
}

class MagnetTarget {
  const MagnetTarget(this.center, [this.id]);
  final Offset center;
  final Object? id;
}

/// glass 4.5 magnet: pulls 0.35 of the remaining distance per frame toward a target within 64 px.
class Magnet {
  Magnet({
    this.radius = GlassPhysics.magnetRadius,
    this.pull = GlassPhysics.magnetPull,
    this.onCapture,
    this.onRelease,
  });

  final double radius;
  final double pull;
  final void Function(MagnetTarget target)? onCapture;
  final void Function(MagnetTarget target)? onRelease;

  MagnetTarget? _held;
  MagnetTarget? get captured => _held;

  Offset step(Offset pos, List<MagnetTarget> targets) {
    MagnetTarget? best;
    var bestD = double.infinity;
    for (final t in targets) {
      final d = (t.center - pos).distance;
      if (d <= radius && d < bestD) {
        best = t;
        bestD = d;
      }
    }
    final was = _held;
    if (best == null) {
      if (was != null) {
        _held = null;
        onRelease?.call(was);
      }
      return pos;
    }
    if (was == null || was.id != best.id || was.center != best.center) {
      if (was != null) onRelease?.call(was);
      _held = best;
      onCapture?.call(best);
    }
    return pos + (best.center - pos) * pull;
  }
}


/// Settle time in ms of the springs the overlays drive through a [Curve] (glass 4.2, 4.10).
const Map<String, int> kSpringSettleMs = {'sheet': 447, 'dismiss': 378, 'sheetSnap': 342, 'settle': 414, 'zoom': 558};

/// A curve that samples a unit spring (0 to 1, at rest) over its settle time, for APIs that only take a
/// [Curve] and a duration (`SheetController.animateTo`, `PageController.animateToPage`).
/// `transform(1.0) == 1.0`, so the animation always ends exactly on target.
class SpringCurve extends Curve {
  SpringCurve(SpringToken token, {int? settleMs})
      : _sim = SpringSimulation(springOf(token), 0, 1, 0),
        _settleMs = (settleMs ?? _settleFor(token)).toDouble();

  final SpringSimulation _sim;
  final double _settleMs;

  static int _settleFor(SpringToken t) {
    if (identical(t, GlassSprings.sheet)) return 447;
    if (identical(t, GlassSprings.dismiss)) return 378;
    if (identical(t, GlassSprings.sheetSnap)) return 342;
    if (identical(t, GlassSprings.settle)) return 414;
    if (identical(t, GlassSprings.zoom)) return 558;
    return (t.ms * 1.06).round();
  }

  @override
  double transformInternal(double t) => t >= 1.0 ? 1.0 : _sim.x(t * _settleMs / 1000);
}
