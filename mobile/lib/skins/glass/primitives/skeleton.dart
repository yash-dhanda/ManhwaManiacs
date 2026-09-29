import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';

/// One sheen clock for a group of skeletons: one `AnimationController` per group, phase-offset 60 ms per
/// row so the sheen travels down a list (glass 7.18). AI skeletons take 2,800 ms instead of 1,400 ms.
/// The region carries the semantics value "Loading" and its skeletons are excluded from semantics.
class GlassSkeletonGroup extends ConsumerStatefulWidget {
  const GlassSkeletonGroup({super.key, required this.child, this.ai = false, this.label = 'Loading'});
  final Widget child;
  final bool ai;
  final String label;

  @override
  ConsumerState<GlassSkeletonGroup> createState() => _GlassSkeletonGroupState();
}

class _GlassSkeletonGroupState extends ConsumerState<GlassSkeletonGroup> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: Duration(milliseconds: widget.ai ? 2800 : 1400));

  @override
  void initState() {
    super.initState();
    _c.value = 0;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = ref.watch(glassReducedProvider);
    if (reduced) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
    return _SkeletonClock(
      clock: _c,
      periodMs: _c.duration!.inMilliseconds,
      child: Semantics(container: true, value: widget.label, child: ExcludeSemantics(child: widget.child)),
    );
  }
}

class _SkeletonClock extends InheritedWidget {
  const _SkeletonClock({required this.clock, required this.periodMs, required super.child});
  final Animation<double> clock;
  final int periodMs;

  static _SkeletonClock? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_SkeletonClock>();

  @override
  bool updateShouldNotify(_SkeletonClock old) => old.clock != clock;
}

/// "Wet glass" (glass 7.18): shapes and radii match the content they stand for; fill `surface2`; a sheen
/// band 40 % of the element's width, angled 100 degrees, sweeping left to right (`curveShimmer`, linear).
/// Skeletons appear only after 180 ms. Reduced motion: static `surface2`.
class GlassSkeleton extends ConsumerStatefulWidget {
  const GlassSkeleton({super.key, this.width, this.height, this.radius = 14, this.circle = false, this.index = 0, this.delayed = true});

  final double? width;
  final double? height;
  final double radius;
  final bool circle;

  /// The row in its list: each row is 60 ms behind the one above.
  final int index;

  /// False in captures, where the 180 ms appearance delay would hide it.
  final bool delayed;

  @override
  ConsumerState<GlassSkeleton> createState() => _GlassSkeletonState();
}

class _GlassSkeletonState extends ConsumerState<GlassSkeleton> {
  bool _shown = false;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    if (!widget.delayed) {
      _shown = true;
    } else {
      _t = Timer(const Duration(milliseconds: 180), () {
        if (mounted) setState(() => _shown = true);
      });
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = ref.watch(glassReducedProvider);
    final clock = _SkeletonClock.maybeOf(context);
    final size = SizedBox(width: widget.width, height: widget.height);
    if (!_shown) return size;
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: RepaintBoundary(
        child: clock == null || reduced
            ? CustomPaint(painter: _SkeletonPainter(phase: null, radius: widget.radius, circle: widget.circle), child: const SizedBox.expand())
            : AnimatedBuilder(
                animation: clock.clock,
                builder: (context, _) {
                  final p = (clock.clock.value + widget.index * 60 / clock.periodMs) % 1.0;
                  return CustomPaint(painter: _SkeletonPainter(phase: p, radius: widget.radius, circle: widget.circle), child: const SizedBox.expand());
                },
              ),
      ),
    );
  }
}

class _SkeletonPainter extends CustomPainter {
  const _SkeletonPainter({required this.phase, required this.radius, required this.circle});
  final double? phase;
  final double radius;
  final bool circle;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = circle ? RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(size.shortestSide / 2)) : RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    canvas.drawRRect(rrect, Paint()..color = gt.colorSurface2);
    final p = phase;
    if (p == null || size.isEmpty) return;
    canvas.save();
    canvas.clipRRect(rrect);
    final band = size.width * 0.4;
    final x = -band + (size.width + band) * p;
    final rect = Rect.fromLTWH(x, -size.height, band, size.height * 3);
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.rotate(10 * math.pi / 180);
    canvas.translate(-rect.center.dx, -rect.center.dy);
    canvas.drawRect(
      rect,
      Paint()..shader = const LinearGradient(colors: [Color(0x00FFFFFF), Color(0x0DFFFFFF), Color(0x00FFFFFF)]).createShader(rect),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SkeletonPainter old) => old.phase != phase || old.radius != radius || old.circle != circle;
}
