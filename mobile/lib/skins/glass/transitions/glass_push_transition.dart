import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';

/// glass 8.0.5: 615 ms on `springPage`, both directions; 200 ms under Reduce Motion.
const Duration kGlassPageDuration = Duration(milliseconds: 615);
const Duration kGlassPageReducedDuration = Duration(milliseconds: 200);

Duration glassPageDuration() => GlassMotion.isReduced() ? kGlassPageReducedDuration : kGlassPageDuration;

final Curve _pageCurve = SpringCurve(GlassSprings.page, settleMs: 615);

/// The Glass push: the incoming page slides in from the trailing edge; the page beneath moves to -30 % under a 30 % black scrim.
/// Reduced motion cross-fades instead. `isGesture` (a back swipe under the finger) drives the raw animation value with no spring.
class GlassPushTransition extends StatelessWidget {
  const GlassPushTransition({super.key, required this.animation, required this.secondaryAnimation, required this.child, this.isGesture = false});
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;
  final bool isGesture;

  static double curved(double v, bool isGesture) => isGesture ? v : _pageCurve.transform(v.clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final reduced = GlassMotion.isReduced();
    return AnimatedBuilder(
      animation: Listenable.merge([animation, secondaryAnimation]),
      child: child,
      builder: (context, child) {
        final a = animation.value, s = secondaryAnimation.value;
        if (reduced) {
          return Opacity(opacity: a.clamp(0.0, 1.0) * (1 - 0.0 * s), child: child);
        }
        final w = MediaQuery.sizeOf(context).width;
        final rtl = Directionality.of(context) == TextDirection.rtl;
        final dir = rtl ? -1.0 : 1.0;
        final dx = dir * ((1 - curved(a, isGesture)) * w - 0.30 * w * curved(s, false));
        final scrim = 0.30 * curved(s, false);
        return Stack(
          fit: StackFit.passthrough,
          children: [
            Transform.translate(offset: Offset(dx, 0), child: child),
            if (scrim > 0) Positioned.fill(child: IgnorePointer(child: ColoredBox(color: Color.fromRGBO(0, 0, 0, scrim)))),
          ],
        );
      },
    );
  }
}
