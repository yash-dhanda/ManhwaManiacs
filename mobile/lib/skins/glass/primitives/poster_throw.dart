import 'dart:ui' show Offset, Size;

import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';

/// glass 4.6: a tap is a release before 450 ms; the lift starts at 150 ms and reaches 1.06 at 450 ms.
double liftScale(double heldMs) {
  if (heldMs <= GlassThresholds.liftStart) return 1;
  final x = ((heldMs - GlassThresholds.liftStart) / (GlassThresholds.liftMenu - GlassThresholds.liftStart)).clamp(0.0, 1.0);
  return 1 + 0.06 * x;
}

sealed class ThrowDecision {
  const ThrowDecision();
}

/// Up, or above the top 20 % of the screen: the `heroine` zoom inherits the velocity.
class ThrowOpen extends ThrowDecision {
  const ThrowOpen();
}

/// Sideways off an AI card: "Not interested".
class ThrowAway extends ThrowDecision {
  const ThrowAway();
}

/// Within 64 px of a registered friend orb.
class ThrowTarget extends ThrowDecision {
  const ThrowTarget(this.target);
  final MagnetTarget target;
}

class ThrowDrop extends ThrowDecision {
  const ThrowDrop();
}

/// Where a released poster goes (pure). [centre] is the poster's centre in the viewport, [velocity] the
/// release velocity in px/s.
ThrowDecision decideThrow({
  required Offset centre,
  required Offset velocity,
  required Size viewport,
  List<MagnetTarget> targets = const [],
  bool allowAway = false,
}) {
  MagnetTarget? near;
  var best = double.infinity;
  for (final t in targets) {
    final d = (t.center - centre).distance;
    if (d <= GlassPhysics.magnetRadius && d < best) {
      near = t;
      best = d;
    }
  }
  if (near != null) return ThrowTarget(near);
  final px = project(centre.dx, velocity.dx);
  final py = project(centre.dy, velocity.dy);
  if (py < viewport.height * 0.2 || velocity.dy <= -GlassThresholds.throwVelocity) return const ThrowOpen();
  if (allowAway && (px < 0 || px > viewport.width || velocity.dx.abs() >= GlassThresholds.throwVelocity)) return const ThrowAway();
  return const ThrowDrop();
}
