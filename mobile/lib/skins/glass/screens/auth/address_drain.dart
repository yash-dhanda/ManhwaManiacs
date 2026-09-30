import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/screens/auth/overlay_run.dart';

/// The Address drain and its portal (glass 4.10, 8.1): a copy of the field's text scales 1 to 0.2 and travels into the lens on
/// `springZoom`, fading out over its last 120 ms; [onImpact] fires when it lands (the lens swells and flashes its rim); then a black
/// layer with a circular hole grows from the lens to the far corner, revealing what [onCovered] navigated to beneath it.
/// Reduced motion: a 200 ms cross-fade.
Future<void> playAddressDrain(
  BuildContext context, {
  required String text,
  required Rect textRect,
  required Rect lensRect,
  required TextStyle style,
  required bool reduced,
  required VoidCallback onImpact,
  required VoidCallback onCovered,
}) =>
    playRootOverlay(
      context,
      (done) => _Drain(text: text, textRect: textRect, lensRect: lensRect, style: style, reduced: reduced, onImpact: onImpact, onCovered: onCovered, done: done),
    );

class _Drain extends StatefulWidget {
  const _Drain({required this.text, required this.textRect, required this.lensRect, required this.style, required this.reduced, required this.onImpact, required this.onCovered, required this.done});
  final String text;
  final Rect textRect;
  final Rect lensRect;
  final TextStyle style;
  final bool reduced;
  final VoidCallback onImpact;
  final VoidCallback onCovered;
  final VoidCallback done;

  @override
  State<_Drain> createState() => _DrainState();
}

class _DrainState extends State<_Drain> with TickerProviderStateMixin {
  late final AnimationController _text = AnimationController(vsync: this);
  late final AnimationController _portal = AnimationController(vsync: this);
  late final AnimationController _fade = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    if (widget.reduced) {
      await _fade.forward();
      widget.onCovered();
      await _fade.reverse();
      widget.done();
      return;
    }
    await GlassMotion.play(MotionName.addressDrain, controller: _text, target: 1);
    if (!mounted) return;
    widget.onImpact();
    await _fade.forward();
    if (!mounted) return;
    widget.onCovered();
    await GlassMotion.play(MotionName.zoom, controller: _portal, target: 1);
    widget.done();
  }

  @override
  void dispose() {
    _text.dispose();
    _portal.dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final lens = widget.lensRect;
    final far = farCornerRadius(lens.center, size);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: Listenable.merge([_text, _portal, _fade]),
        builder: (context, _) {
          final t = _text.value;
          final from = widget.textRect.center;
          final pos = Offset.lerp(from, lens.center, t.clamp(0.0, 1.0))!;
          final scale = 1 + (0.2 - 1) * t.clamp(0.0, 1.0);
          final fade = ((t - 0.78) / 0.22).clamp(0.0, 1.0);
          final hole = lens.width / 2 + (far - lens.width / 2) * _portal.value.clamp(0.0, 1.2);
          return Stack(
            fit: StackFit.expand,
            children: [
              if (_fade.value > 0)
                Opacity(
                  opacity: widget.reduced ? _fade.value : 1,
                  child: CustomPaint(painter: _HolePainter(center: lens.center, radius: widget.reduced ? 0 : (_fade.isCompleted ? hole : lens.width / 2), alpha: _fade.value)),
                ),
              if (!widget.reduced && t < 1)
                Positioned(
                  left: pos.dx - widget.textRect.width / 2,
                  top: pos.dy - widget.textRect.height / 2,
                  width: widget.textRect.width,
                  height: widget.textRect.height,
                  child: Opacity(
                    opacity: 1 - fade,
                    child: Transform.scale(scale: scale, child: Text(widget.text, maxLines: 1, overflow: TextOverflow.clip, style: widget.style.copyWith(decoration: TextDecoration.none))),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _HolePainter extends CustomPainter {
  const _HolePainter({required this.center, required this.radius, required this.alpha});
  final Offset center;
  final double radius;
  final double alpha;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size);
    if (radius > 0) path.addOval(Rect.fromCircle(center: center, radius: math.min(radius, size.longestSide * 3)));
    canvas.drawPath(path, Paint()..color = const Color(0xFF000000).withValues(alpha: alpha));
  }

  @override
  bool shouldRepaint(_HolePainter old) => old.center != center || old.radius != radius || old.alpha != alpha;
}
