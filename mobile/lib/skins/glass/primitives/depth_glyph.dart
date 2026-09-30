import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';

/// "Back to {previous title}, {n} levels deep" (glass 7.37); "1 level deep" for one.
String depthLabel(String previousTitle, int n) => 'Back to $previousTitle, $n ${n == 1 ? 'level' : 'levels'} deep';

/// The bars of the `strata` glyph on its 256 grid: y centres and widths, top to bottom.
const List<double> kStrataY = [56, 100, 144, 188];
const List<double> kStrataWidth = [124, 136, 148, 160];

/// How many bars are lit for [depth]: from the bottom up, at most four.
int litBars(int depth) => depth.clamp(0, 4);

/// The strata depth glyph (glass 7.37, 2.7): four horizontal capsules 20 units tall on the 256 grid at 22 px. Lit bars (filled)
/// count the levels you came through from the bottom up, each tinted with that level's ambient rim colour ([tints], newest last;
/// `onGlass` when missing). Unlit bars are 16-unit outlines. Newly lit bars fill left to right 40 ms apart on `springTick`; reduced
/// motion cross-fades over 150 ms. Decorative: the back button carries the [depthLabel].
class DepthGlyph extends ConsumerStatefulWidget {
  const DepthGlyph({super.key, required this.depth, this.tints = const [], this.size = 22});
  final int depth;
  final List<Color> tints;
  final double size;

  @override
  ConsumerState<DepthGlyph> createState() => _DepthGlyphState();
}

class _DepthGlyphState extends ConsumerState<DepthGlyph> with TickerProviderStateMixin {
  // Fill progress per level (0 = bottom bar).
  late final List<AnimationController> _fill;
  final List<Timer> _timers = [];

  @override
  void initState() {
    super.initState();
    _fill = [for (var i = 0; i < 4; i++) AnimationController.unbounded(vsync: this, value: i < litBars(widget.depth) ? 1 : 0)];
  }

  @override
  void didUpdateWidget(DepthGlyph old) {
    super.didUpdateWidget(old);
    final was = litBars(old.depth), now = litBars(widget.depth);
    final reduced = ref.read(glassMotionPrefsProvider).reduced;
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    for (var i = 0; i < 4; i++) {
      final target = i < now ? 1.0 : 0.0;
      if (_fill[i].value == target && !_fill[i].isAnimating) continue;
      if (reduced) {
        unawaited(_fill[i].animateTo(target, duration: const Duration(milliseconds: 150)));
      } else if (target == 1 && i >= was) {
        final delay = Duration(milliseconds: 40 * (i - was));
        _timers.add(Timer(delay, () {
          if (mounted) unawaited(_fill[i].springTo(1, gt.springTick));
        }),);
      } else {
        _fill[i].value = target;
      }
    }
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    for (final c in _fill) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: AnimatedBuilder(
          animation: Listenable.merge(_fill),
          builder: (context, _) => CustomPaint(
            size: Size.square(widget.size),
            painter: DepthGlyphPainter(fills: [for (final c in _fill) c.value.clamp(0.0, 1.0)], tints: widget.tints, fallback: gt.colorOnGlass),
          ),
        ),
      );
}

class DepthGlyphPainter extends CustomPainter {
  const DepthGlyphPainter({required this.fills, required this.tints, required this.fallback});
  final List<double> fills;
  final List<Color> tints;
  final Color fallback;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 256;
    for (var row = 0; row < 4; row++) {
      final level = 3 - row; // the bottom bar is level 0
      final w = kStrataWidth[row] * u;
      final cx = 128 * u;
      final lit = fills[level];
      final color = level < tints.length ? tints[level] : fallback;
      final barH = 20 * u;
      final rect = Rect.fromCenter(center: Offset(cx, kStrataY[row] * u), width: w, height: barH);
      if (lit < 1) {
        final outline = Rect.fromCenter(center: rect.center, width: w, height: 16 * u);
        canvas.drawRRect(
          RRect.fromRectAndRadius(outline, Radius.circular(8 * u)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6 * u
            ..color = fallback.withValues(alpha: 0.4),
        );
      }
      if (lit > 0) {
        canvas.save();
        canvas.clipRect(Rect.fromLTWH(rect.left, rect.top - 2, w * lit, barH + 4));
        canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(10 * u)), Paint()..color = color);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(DepthGlyphPainter old) => old.fills != fills || old.tints != tints || old.fallback != fallback;
}
