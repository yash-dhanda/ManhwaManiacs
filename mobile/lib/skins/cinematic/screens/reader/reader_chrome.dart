import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// The chrome's motion (cinematic 8.14.3): in over 240 ms `settle` as a fade plus an 8 px slide
/// from its edge, out over 160 ms `lift`. Hidden chrome is `Offstage`, so it leaves focus
/// traversal and semantics. Reduced motion: a fade only, the same durations.
class ReaderChromeMotion extends StatefulWidget {
  const ReaderChromeMotion({super.key, required this.visible, required this.fromTop, required this.child});

  final bool visible, fromTop;
  final Widget child;

  @override
  State<ReaderChromeMotion> createState() => _ReaderChromeMotionState();
}

class _ReaderChromeMotionState extends State<ReaderChromeMotion> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, value: widget.visible ? 1 : 0);

  @override
  void didUpdateWidget(ReaderChromeMotion old) {
    super.didUpdateWidget(old);
    if (old.visible == widget.visible) return;
    final cine = context.cine;
    if (widget.visible) {
      _c.animateTo(1, duration: cine.durLine, curve: CineCurves.settle);
    } else {
      _c.animateTo(0, duration: cine.durBeat, curve: CineCurves.lift);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = CineMotion.reduced(context);
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = _c.value;
        final dy = reduced ? 0.0 : (1 - t) * 8 * (widget.fromTop ? -1 : 1);
        return Offstage(
          offstage: t == 0 && !widget.visible,
          child: IgnorePointer(
            ignoring: !widget.visible,
            child: Opacity(opacity: t.clamp(0.0, 1.0), child: Transform.translate(offset: Offset(0, dy), child: child)),
          ),
        );
      },
    );
  }
}
