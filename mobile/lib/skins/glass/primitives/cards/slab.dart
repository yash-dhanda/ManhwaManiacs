import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/contract.g.dart' show HapticEvent;
import 'package:manhwamaniacs/skins/glass/glass/shape.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/primitives/rail_focus.dart';
import 'package:manhwamaniacs/skins/glass/primitives/spring_value.dart';

/// The default card slab (glass 7.7): `surface1` with `slabBorder` (1 px `rgba(255,255,255,0.06)`), radius
/// `radiusXl` 26, padding 12. Cards sit on black or on the ambient field and are never glass. Hover lifts
/// -2 px on `springSnappy` with a `0 12px 32px rgba(0,0,0,0.5)` shadow; pressed sinks to 0.97; focused gets
/// the ring and scale 1.04; disabled is 55 % opacity with the reason; selected (select mode) has a 2 px
/// `iris500` inset ring and a 24 px check orb that pops on `springTick`.
class GlassSlab extends ConsumerWidget {
  const GlassSlab({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.radius = 26,
    this.padding = const EdgeInsets.all(12),
    this.semanticsLabel,
    this.selectMode = false,
    this.selected = false,
    this.enabled = true,
    this.disabledReason,
    this.dashed = false,
    this.width,
    this.height,
    this.forceStates = GlassWidgetStates.none,
    this.customActions = const {},
    this.onKey,
    this.sink = 0.97,
    this.borderColor = const Color(0x0FFFFFFF),
    this.borderWidth = 1,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double radius;
  final EdgeInsets padding;
  final String? semanticsLabel;
  final bool selectMode;
  final bool selected;
  final bool enabled;
  final String? disabledReason;

  /// The info-only world card: a dashed 1 px `slabBorder`.
  final bool dashed;
  final double? width;
  final double? height;
  final GlassWidgetStates forceStates;
  final Map<CustomSemanticsAction, VoidCallback> customActions;
  final KeyEventResult Function(FocusNode, KeyEvent)? onKey;
  final double sink;

  /// The rim: `slabBorder` by default; an AI card carries a 0.5 px `machineRim` instead (glass 2.1.9).
  final Color borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shape = GlassShape.superellipse(radius);
    final disabled = !enabled || forceStates.disabled;
    Widget card = GlassPressable(
      material: GlassMaterial.content,
      sink: sink,
      shape: shape,
      minHit: false,
      onTap: disabled ? null : onTap,
      onLongPress: disabled ? null : onLongPress,
      longPressHaptic: onLongPress == null ? null : HapticEvent.longpressOpen,
      enabled: !disabled,
      forceStates: forceStates,
      semanticsLabel: semanticsLabel,
      semanticsHint: disabled ? disabledReason : null,
      checked: selectMode ? selected : null,
      focusNode: GlassRailItemScope.maybeOf(context),
      focusScale: 1.04,
      hoverGlow: false,
      customActions: customActions,
      builder: (context, info) {
        final hover = info.states.hovered && !disabled && !info.reduced;
        return SpringValue(
          value: hover ? 1 : 0,
          spring: gt.springSnappy,
          builder: (context, h, _) => Transform.translate(
            offset: Offset(0, -2 * h),
            child: SizedBox(
              width: width,
              height: height,
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: gt.colorSurface1,
                  shape: dashed ? _DashedBorder(radius) : RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(radius), side: BorderSide(color: borderColor, width: borderWidth)),
                  shadows: h > 0 ? [BoxShadow(color: const Color(0x80000000).withValues(alpha: 0.5 * h), blurRadius: 32, offset: Offset(0, 12 * h))] : null,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Padding(padding: padding, child: Opacity(opacity: selectMode && selected ? 0.8 : 1, child: child)),
                    if (selectMode && selected)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(decoration: ShapeDecoration(shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(radius), side: BorderSide(color: gt.colorIris500, width: 2)))),
                        ),
                      ),
                    if (selectMode) Positioned(top: 8, right: 8, child: GlassCheckOrb(on: selected)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    if (onKey != null) card = Focus(canRequestFocus: false, skipTraversal: true, onKeyEvent: onKey, child: card);
    return Opacity(opacity: disabled ? 0.55 : 1, child: card);
  }
}

/// The select-mode check orb: 24 px, pops on `springTick` when it turns on.
class GlassCheckOrb extends StatelessWidget {
  const GlassCheckOrb({super.key, required this.on});
  final bool on;

  @override
  Widget build(BuildContext context) => SpringValue(
        value: on ? 1 : 0,
        spring: gt.springTick,
        builder: (context, v, _) => Transform.scale(
          scale: 0.6 + 0.4 * v.clamp(0.0, 1.3),
          child: Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: on ? gt.colorIris500 : const Color(0xB8000000), shape: BoxShape.circle, border: Border.all(color: const Color(0x38FFFFFF), width: 0.5)),
            child: on ? const GlyphIcon(GlassGlyph.check, size: 14, color: Color(0xFF000000)) : null,
          ),
        ),
      );
}

/// A dashed 1 px `slabBorder` rounded border.
class _DashedBorder extends ShapeBorder {
  const _DashedBorder(this.radius);
  final double radius;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(1);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => getOuterPath(rect.deflate(1), textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(radius)).getOuterPath(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final path = getOuterPath(rect.deflate(0.5));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x24FFFFFF);
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, (d + 6).clamp(0, m.length)), paint);
        d += 10;
      }
    }
  }

  @override
  ShapeBorder scale(double t) => this;
}
