import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/glass_motion_recorder.dart' show GlassMotionEntry;
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/progress.dart';
import 'package:manhwamaniacs/skins/glass/primitives/spring_value.dart';

/// The daily goal ring on the profile orb (glass 9.2.2, 7.26): with a goal set, a 2 px ring 3 px outside the
/// orb fills clockwise from 12 o'clock with today's minutes toward the goal, in `streak` at 80 %; on
/// `goal.met` it closes and fills solid for 600 ms (`success`, then a shimmer), then stays closed in
/// `streakCore` for the rest of the local day. Semantics "Today: 8 of 10 minutes". [onDisc] draws it on a
/// backing disc 8 px wider than the ring (glass hosts other than the edge plateau and the docked sidebar).
class GlassGoalRing extends ConsumerStatefulWidget {
  const GlassGoalRing({super.key, required this.child, required this.orbSize, required this.minutes, required this.goal, this.onDisc = false});

  final Widget child;
  final double orbSize;
  final int minutes;
  final int goal;
  final bool onDisc;

  @override
  ConsumerState<GlassGoalRing> createState() => _GlassGoalRingState();
}

class _GlassGoalRingState extends ConsumerState<GlassGoalRing> with SingleTickerProviderStateMixin {
  late final AnimationController _close = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  bool get _met => widget.goal > 0 && widget.minutes >= widget.goal;
  bool _wasMet = false;
  GlassMotionEntry? _entry;

  @override
  void initState() {
    super.initState();
    _wasMet = _met;
    _close.value = _met ? 1 : 0;
  }

  @override
  void didUpdateWidget(GlassGoalRing old) {
    super.didUpdateWidget(old);
    if (_met && !_wasMet) {
      // goal.met fires once from the streak events listener (mobile/42), not once per orb wearing the ring.
      if (!ref.read(glassReducedProvider)) {
        _entry = GlassMotion.recorder.begin(MotionName.goalRingClose.label, 600);
        _close.forward(from: 0).whenComplete(() {
          final e = _entry;
          _entry = null;
          if (e != null) GlassMotion.recorder.end(e);
        });
      } else {
        _close.value = 1;
      }
    }
    _wasMet = _met;
  }

  @override
  void dispose() {
    _close.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.orbSize;
    final outer = s + 2 * (3 + 2);
    final frac = widget.goal <= 0 ? 0.0 : (widget.minutes / widget.goal).clamp(0.0, 1.0);
    final label = 'Today: ${widget.minutes} of ${widget.goal} minutes';
    final box = outer + (widget.onDisc ? 8 : 0);
    return Semantics(
      label: label,
      child: SizedBox(
        width: box,
        height: box,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (widget.onDisc) Container(width: box, height: box, decoration: BoxDecoration(color: gt.colorBackingDisc, shape: BoxShape.circle)),
            ExcludeSemantics(
              child: SpringValue(
                value: frac,
                spring: gt.springSnappy,
                builder: (context, v, _) => AnimatedBuilder(
                  animation: _close,
                  builder: (context, _) {
                    final closing = _close.value;
                    Color color = gt.colorStreak.withValues(alpha: 0.8);
                    var value = v;
                    if (_met) {
                      value = 1;
                      // 600 ms: success (with a shimmer), then streakCore for the rest of the day.
                      color = closing < 1 ? Color.lerp(gt.colorSuccess, gt.colorStreakCore, math.max(0, (closing - 0.6) / 0.4))! : gt.colorStreakCore;
                    }
                    return CustomPaint(size: Size.square(outer), painter: RingPainter(v: value, stroke: 2, color: color, trackColor: gt.colorFill1));
                  },
                ),
              ),
            ),
            ExcludeSemantics(child: widget.child),
          ],
        ),
      ),
    );
  }
}
