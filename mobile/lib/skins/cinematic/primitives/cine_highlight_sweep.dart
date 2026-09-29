import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// Highlight sweep (cinematic 4.5): one `spot.wash` band left -> right behind [child] over 200 ms
/// (`durClip`) `easeSet`, bands 60 ms apart by [index]. Reduced: the band at its end state.
class CineHighlightSweep extends StatefulWidget {
  const CineHighlightSweep({super.key, required this.child, this.index = 0, this.active = true});
  final Widget child;
  final int index;
  final bool active;

  @override
  State<CineHighlightSweep> createState() => _CineHighlightSweepState();
}

class _CineHighlightSweepState extends State<CineHighlightSweep> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started || !widget.active) return;
    _started = true;
    if (CineMotion.reduced(context)) {
      _c.value = 1;
    } else {
      final delay = 60 * widget.index, total = delay + CineDur.clip.inMilliseconds;
      CineMotion.play(MotionName.highlightSweep, _c,
          duration: Duration(milliseconds: total), curve: Interval(delay / total, 1, curve: CineCurves.easeSet),);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wash = context.cine.colorSpotWash;
    return Stack(children: [
      Positioned.fill(
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, __) => FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: widget.active ? _c.value : 0,
              child: ColoredBox(color: wash),
            ),
          ),
        ),
      ),
      widget.child,
    ],);
  }
}
