import 'dart:math' as math;

import 'package:flutter/services.dart' show PredictiveBackEvent, SwipeEdge;
import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/transitions/glass_push_transition.dart';
import 'package:manhwamaniacs/skins/glass/transitions/predictive_back_detector.dart';

/// Android page transition (glass 8.0.5). With no gesture in progress (a button, a key, 3-button back, a programmatic pop) it draws
/// [GlassPushTransition]; during a predictive-back gesture the page becomes a glass card: scale 1 to 0.90, an x shift toward the swipe
/// edge, a y shift following the finger, a corner radius 0 to 36 through a superellipse clip, the T4 rim and a deep shadow. Commit
/// and cancel are the route's own animation finishing, so the card follows the same 615 ms mapping.
class GlassPageTransitionsBuilder extends PageTransitionsBuilder {
  const GlassPageTransitionsBuilder();

  @override
  Duration get transitionDuration => kGlassPageDuration;

  @override
  Duration get reverseTransitionDuration => kGlassPageDuration;

  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return GlassPredictiveBackDetector(
      route: route,
      builder: (context, phase, start, current) => GlassBackTransition(
        route: route,
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        phase: phase,
        startEvent: start,
        currentEvent: current,
        child: child,
      ),
    );
  }
}

/// Geometry of the predictive card, pure for tests. [p] is the gesture progress 0..1.
class GlassPredictiveGeometry {
  const GlassPredictiveGeometry({required this.scale, required this.dx, required this.dy, required this.radius});
  final double scale;
  final double dx;
  final double dy;
  final double radius;

  static GlassPredictiveGeometry of({required double p, required Size size, required SwipeEdge edge, required double touchY}) {
    final maxY = size.height / 20 - 8;
    final xShift = size.width / 20 - 8;
    final y = ((touchY - size.height / 2) / 20).clamp(-maxY, maxY);
    return GlassPredictiveGeometry(
      scale: 1 - 0.10 * p,
      dx: (edge == SwipeEdge.left ? 1 : -1) * xShift * p,
      dy: y * p,
      radius: 36 * p,
    );
  }
}

class GlassBackTransition extends StatelessWidget {
  const GlassBackTransition({
    super.key,
    required this.route,
    required this.animation,
    required this.secondaryAnimation,
    required this.phase,
    required this.startEvent,
    required this.currentEvent,
    required this.child,
  });
  final PageRoute<dynamic> route;
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final GlassPredictiveBackPhase phase;
  final PredictiveBackEvent? startEvent;
  final PredictiveBackEvent? currentEvent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (GlassMotion.isReduced() || !(route.popGestureInProgress || phase == GlassPredictiveBackPhase.commit || phase == GlassPredictiveBackPhase.cancel)) {
      // The same tree shape as the card below is not needed: with no gesture the child keeps one stable parent chain.
      return GlassPushTransition(animation: animation, secondaryAnimation: secondaryAnimation, child: child);
    }
    final size = MediaQuery.sizeOf(context);
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final p = (1 - animation.value).clamp(0.0, 1.0);
        final g = GlassPredictiveGeometry.of(
          p: p,
          size: size,
          edge: (currentEvent ?? startEvent)?.swipeEdge ?? SwipeEdge.left,
          touchY: (currentEvent ?? startEvent)?.touchOffset?.dy ?? size.height / 2,
        );
        final radius = BorderRadius.circular(g.radius);
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..translateByDouble(g.dx, g.dy, 0, 1)
            ..scaleByDouble(g.scale, g.scale, 1, 1),
          child: DecoratedBox(
            decoration: ShapeDecoration(
              shape: RoundedSuperellipseBorder(borderRadius: radius, side: BorderSide(color: Color.fromRGBO(255, 255, 255, 0.30 * math.min(1, p * 4)), width: 0.5)),
              shadows: [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.6 * math.min(1, p * 4)), offset: const Offset(0, 24), blurRadius: 64)],
            ),
            child: ClipRSuperellipse(borderRadius: radius, child: child),
          ),
        );
      },
    );
  }
}
