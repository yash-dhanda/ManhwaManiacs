import 'dart:math' as math;

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/features/novels/models/glass_novel_prefs.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';

/// The farthest-corner distance from [origin] in [size]: the ripple's end radius.
double rippleRadius(Offset origin, Size size) => [
      origin.distance,
      (origin - Offset(size.width, 0)).distance,
      (origin - Offset(0, size.height)).distance,
      (origin - Offset(size.width, size.height)).distance,
    ].reduce(math.max);

/// The Paper ripple (H7): while it runs the reader tree is kept beneath under the old paper ([builder] with `ghost: true`, inert), and
/// the live tree under the new paper sits above it clipped by a circle centred on the orb, its radius driven 0 -> the farthest corner
/// by `SpringSimulation(springPage, 0, 1, 0)`. The old copy is removed on settle, so focus and selection stay on the live tree. Reduce
/// Motion: a 200 ms cross-fade. It is the only sprung colour change.
class NovelPaperRipple extends StatefulWidget {
  const NovelPaperRipple({super.key, required this.paper, required this.origin, required this.reduced, required this.builder});
  final GlassPaper paper;

  /// Where the last orb was pressed (global), or null for a change from elsewhere (no ripple).
  final Offset? origin;
  final bool reduced;
  final Widget Function(BuildContext context, GlassPaper paper, bool ghost) builder;

  @override
  State<NovelPaperRipple> createState() => _NovelPaperRippleState();
}

class _NovelPaperRippleState extends State<NovelPaperRipple> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, value: 1);
  }
  GlassPaper? _old;
  Offset? _at;

  @override
  void didUpdateWidget(NovelPaperRipple old) {
    super.didUpdateWidget(old);
    if (old.paper != widget.paper && widget.origin != null) {
      _old = old.paper;
      final ro = context.findRenderObject();
      _at = ro is RenderBox && ro.hasSize ? ro.globalToLocal(widget.origin!) : Offset.zero;
      _run();
    }
  }

  Future<void> _run() async {
    final entry = GlassMotion.recorder.begin(MotionName.paperRipple.label, widget.reduced ? 200 : 615);
    _c.value = 0;
    if (widget.reduced) {
      await _c.animateTo(1, duration: const Duration(milliseconds: 200)).orCancel.catchError((Object _) {});
    } else {
      await _c.animateWith(SpringSimulation(springOf(glassTokens.springPage), 0, 1, 0)).orCancel.catchError((Object _) {});
    }
    GlassMotion.recorder.end(entry);
    if (mounted) setState(() => _old = null);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final live = widget.builder(context, widget.paper, false);
    final old = _old;
    if (old == null) return live;
    return LayoutBuilder(
      builder: (context, c) {
        final size = c.biggest;
        final at = _at ?? size.center(Offset.zero);
        final end = rippleRadius(at, size);
        return Stack(
          fit: StackFit.expand,
          children: [
            IgnorePointer(child: ExcludeSemantics(child: widget.builder(context, old, true))),
            AnimatedBuilder(
              animation: _c,
              child: live,
              builder: (context, child) => widget.reduced
                  ? Opacity(opacity: _c.value.clamp(0.0, 1.0), child: child)
                  : ClipPath(key: const ValueKey('paper-ripple-clip'), clipper: _Circle(at, end * _c.value.clamp(0.0, 1.2)), child: child),
            ),
          ],
        );
      },
    );
  }
}

class _Circle extends CustomClipper<Path> {
  _Circle(this.centre, this.radius);
  final Offset centre;
  final double radius;

  @override
  Path getClip(Size size) => Path()..addOval(Rect.fromCircle(center: centre, radius: math.max(0, radius)));

  @override
  bool shouldReclip(_Circle old) => old.centre != centre || old.radius != radius;
}
