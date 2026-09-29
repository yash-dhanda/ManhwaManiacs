
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/glass/glow.dart';
import 'package:manhwamaniacs/skins/glass/glass/shape.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart' show GlassButtonIcon;
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';

/// One icon of a [GlassGroup].
class GlassGroupItem {
  const GlassGroupItem({required this.icon, required this.label, required this.onPressed, this.toggle});
  final GlassButtonIcon icon;
  final String label;
  final VoidCallback? onPressed;
  final bool? toggle;
}

/// One `glassThin` capsule `hitMin` tall holding 2 to 4 icons a `hitMin` apart with an 8 px gap: one
/// `SkinGlassGroup` (one layer, one shape). A pressed icon's glow spreads into its neighbours at 30 %
/// (one container, one light) (glass 7.2).
class GlassGroup extends ConsumerStatefulWidget {
  const GlassGroup({super.key, required this.items, this.twin, this.lb = 1.0, this.forcePressed});
  final List<GlassGroupItem> items;
  final GlassTwin? twin;
  final double lb;

  /// For the gallery: an item shown pressed.
  final int? forcePressed;

  @override
  ConsumerState<GlassGroup> createState() => _GlassGroupState();
}

class _GlassGroupState extends ConsumerState<GlassGroup> with SingleTickerProviderStateMixin {
  late final AnimationController _glow = AnimationController(vsync: this, duration: Duration(milliseconds: gt.curveGlowIn.ms), reverseDuration: Duration(milliseconds: gt.curveGlowOut.ms));
  int? _pressed;
  Offset _at = Offset.zero;

  @override
  void initState() {
    super.initState();
    assert(widget.items.length >= 2 && widget.items.length <= 4, 'A glass group holds 2 to 4 icons (glass 7.2).');
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hit = GlassFrame.hitMin(context);
    final n = widget.items.length;
    final w = n * hit + (n - 1) * 8.0;
    final size = Size(w, hit);
    final forced = widget.forcePressed;
    if (forced != null && _pressed != forced) {
      _pressed = forced;
      _at = Offset(forced * (hit + 8) + hit / 2, hit / 2);
      _glow.value = 1;
    }
    return SkinGlassGroup(
      tier: GlassTierId.t2,
      lb: widget.lb,
      debugLabel: 'GlassGroup',
      shapes: [
        SkinGlassShape(
          size: size,
          twin: widget.twin,
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _glow,
                    builder: (context, _) => CustomPaint(painter: _GroupGlowPainter(pressed: _pressed, at: _at, amount: _glow.value, pitch: hit + 8, hit: hit, count: n)),
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < n; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    _item(context, i, hit),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _item(BuildContext context, int i, double hit) {
    final it = widget.items[i];
    return SizedBox(
      width: hit,
      height: hit,
      child: GlassPressable(
        material: GlassMaterial.content,
        sink: 0.92,
        shape: const GlassShape.circle(),
        minHit: false,
        onTap: it.onPressed,
        enabled: it.onPressed != null,
        semanticsLabel: it.label,
        toggled: it.toggle,
        tooltip: it.label,
        onPressChanged: (down) {
          if (down) {
            _pressed = i;
            _glow.forward();
          } else {
            _glow.reverse();
          }
        },
        onHoverChanged: null,
        builder: (context, info) {
          final g = info.glow.value;
          if (g != null && g.on) _at = Offset(i * (hit + 8) + g.local.dx, g.local.dy);
          final selected = it.toggle == true;
          return Center(
            child: Icon(
              info.states.pressed || selected ? it.icon.fill : it.icon.regular,
              size: 22,
              color: it.onPressed == null ? GlassColors.g500 : gt.colorOnGlass,
            ),
          );
        },
      ),
    );
  }
}

class _GroupGlowPainter extends CustomPainter {
  const _GroupGlowPainter({required this.pressed, required this.at, required this.amount, required this.pitch, required this.hit, required this.count});
  final int? pressed;
  final Offset at;
  final double amount;
  final double pitch;
  final double hit;
  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    final p = pressed;
    if (p == null || amount <= 0) return;
    void glow(Offset c, double a) {
      final col = const Color(0x29FFFFFF);
      canvas.drawCircle(c, GlassGlowPainter.radius, Paint()..shader = RadialGradient(colors: [col.withValues(alpha: col.a * a), const Color(0x00FFFFFF)]).createShader(Rect.fromCircle(center: c, radius: GlassGlowPainter.radius)));
    }

    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(size.height / 2)));
    glow(at, amount);
    for (final d in [-1, 1]) {
      final j = p + d;
      if (j < 0 || j >= count) continue;
      glow(Offset(j * pitch + hit / 2, hit / 2), amount * 0.3);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GroupGlowPainter old) => old.pressed != pressed || old.amount != amount || old.at != at;
}

