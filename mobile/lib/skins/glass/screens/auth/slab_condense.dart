import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/screens/auth/overlay_run.dart';

/// The droplet of the Slab condense (glass 4.10): a 24 px `glassFilm` droplet forms above the lens and falls into it under
/// 3,000 px/s². [onLand] fires when it touches the lens (the `logo.land` haptic and the `droplet` cue). Reduced motion: no droplet.
Future<void> playDropletLand(BuildContext context, {required Offset lensCentre, required bool reduced, required VoidCallback onLand}) {
  if (reduced) {
    onLand();
    return Future<void>.value();
  }
  return playRootOverlay(context, (done) => _Droplet(lensCentre: lensCentre, onLand: onLand, done: done));
}

/// Seconds a droplet takes to fall [distance] px from rest under 3,000 px/s².
double fallSeconds(double distance, {double gravity = 3000}) => math.sqrt(2 * distance / gravity);

class _Droplet extends StatefulWidget {
  const _Droplet({required this.lensCentre, required this.onLand, required this.done});
  final Offset lensCentre;
  final VoidCallback onLand;
  final VoidCallback done;

  @override
  State<_Droplet> createState() => _DropletState();
}

class _DropletState extends State<_Droplet> with SingleTickerProviderStateMixin {
  static const double _drop = 64;
  late final AnimationController _c = AnimationController(vsync: this, duration: Duration(milliseconds: (fallSeconds(_drop) * 1000).round()));
  bool _landed = false;

  @override
  void initState() {
    super.initState();
    _c.addListener(() {
      if (_c.isCompleted && !_landed) {
        _landed = true;
        widget.onLand();
        Future<void>.delayed(const Duration(milliseconds: 140), widget.done);
      }
    });
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;
            // y = drop * t^2 under constant acceleration, from rest.
            final y = -_drop + _drop * t * t;
            final form = (t / 0.3).clamp(0.0, 1.0);
            final landed = _landed;
            return Stack(
              children: [
                Positioned(
                  left: widget.lensCentre.dx - 12,
                  top: widget.lensCentre.dy + y - 12,
                  child: Opacity(
                    opacity: landed ? 0 : form,
                    child: Transform.scale(
                      scale: form,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0x40FFFFFF),
                          shape: BoxShape.circle,
                          border: Border.fromBorderSide(BorderSide(color: Color(0x66FFFFFF), width: 0.5)),
                        ),
                        child: SizedBox.square(dimension: 24),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
}
