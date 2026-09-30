import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';

/// A plain tappable region with a 48 x 48 minimum hit area and button semantics.
class GlassTap extends StatelessWidget {
  const GlassTap({super.key, required this.label, required this.onTap, required this.child, this.minWidth = 48, this.selected});
  final String label;
  final VoidCallback? onTap;
  final Widget child;
  final double minWidth;
  final bool? selected;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        selected: selected,
        excludeSemantics: true,
        onTap: onTap,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: ConstrainedBox(constraints: BoxConstraints(minHeight: 48, minWidth: minWidth), child: Align(alignment: Alignment.centerLeft, widthFactor: 1, child: child)),
        ),
      );
}

/// Brings a late section up from depth (glass 4.10 "Surface from depth"): scale 0.94 to 1 and brightness 0.4 to 1 on `springSnappy`;
/// reduced motion is a 150 ms fade. [animate] false shows the child at once (the first tier).
class DepthIn extends ConsumerStatefulWidget {
  const DepthIn({super.key, required this.child, this.animate = true});
  final Widget child;
  final bool animate;

  @override
  ConsumerState<DepthIn> createState() => _DepthInState();
}

class _DepthInState extends ConsumerState<DepthIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, value: widget.animate ? 0 : 1);

  @override
  void initState() {
    super.initState();
    if (widget.animate) unawaited(GlassMotion.play(MotionName.surfaceFromDepth, controller: _c, target: 1));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = ref.watch(glassReducedProvider);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value.clamp(0.0, 1.0);
        if (t >= 1) return child!;
        if (reduced) return Opacity(opacity: t, child: child);
        final b = 0.4 + 0.6 * t;
        return Transform.scale(
          scale: 0.94 + 0.06 * t,
          child: ColorFiltered(colorFilter: ColorFilter.matrix([b, 0, 0, 0, 0, 0, b, 0, 0, 0, 0, 0, b, 0, 0, 0, 0, 0, 1, 0]), child: child),
        );
      },
      child: widget.child,
    );
  }
}
