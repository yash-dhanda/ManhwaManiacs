import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart';

/// "Arriving into Glass" (glass 8.25.2): on mount the shell reads and clears [glassArrivalProvider] and materialises its chrome (the
/// dock, or the sidebar's profile capsule) in a circular clip growing from the point `mobile/30` wrote, on `springZoom`.
class GlassArrivalReveal extends ConsumerStatefulWidget {
  const GlassArrivalReveal({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<GlassArrivalReveal> createState() => _GlassArrivalRevealState();
}

class _GlassArrivalRevealState extends ConsumerState<GlassArrivalReveal>
    with SingleTickerProviderStateMixin {
  AnimationController? _ctl;
  AnimationController get _c => _ctl ??= AnimationController(vsync: this, value: 1);
  Offset? _from;

  @override
  void initState() {
    super.initState();
    final a = ref.read(glassArrivalProvider);
    if (a != null) {
      _from = a.point;
      _c.value = 0;
      Future.microtask(() {
        if (!mounted) return;
        ref.read(glassArrivalProvider.notifier).state = null;
        GlassMotion.play(MotionName.zoom, controller: _c, target: 1);
      });
    }
  }

  @override
  void dispose() {
    _ctl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final from = _from;
    if (from == null) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        if (_c.value >= 1) return child!;
        final size = MediaQuery.sizeOf(context);
        final far = math.max(
            math.max(from.distance, (from - Offset(size.width, 0)).distance),
            math.max((from - Offset(0, size.height)).distance,
                (from - Offset(size.width, size.height)).distance,),);
        return ClipPath(
            clipper: _CircleClipper(from, far * _c.value.clamp(0.0, 1.2)),
            child: child,);
      },
    );
  }
}

class _CircleClipper extends CustomClipper<Path> {
  const _CircleClipper(this.center, this.radius);
  final Offset center;
  final double radius;

  @override
  Path getClip(Size size) =>
      Path()..addOval(Rect.fromCircle(center: center, radius: radius));

  @override
  bool shouldReclip(_CircleClipper old) =>
      old.radius != radius || old.center != center;
}
