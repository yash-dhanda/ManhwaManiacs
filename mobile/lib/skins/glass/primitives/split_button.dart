import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/glass/glow.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/lit.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';

/// The split button (glass 7.1): one glass container (a `SkinGlassGroup` of two shapes) holding a tinted
/// primary segment (padding 0 20) and a trailing `glassThin` segment 50 x 50 with `caret-down`, separated
/// by a 0.5 px `separator`, height L 50. Pressing either lights both, the pressed one more (glow 16 %,
/// the other 8 %). Two buttons for semantics: "[label]" and "[moreLabel]". The trailing segment calls
/// [onMore] with its rect; the menu itself is `mobile/27`'s.
class GlassSplitButton extends ConsumerStatefulWidget {
  const GlassSplitButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.onMore,
    this.moreLabel = 'More ways to read',
    this.semanticsLabel,
    this.twin,
    this.forcePressed,
  });

  final String label;
  final VoidCallback? onPressed;
  final void Function(Rect anchor) onMore;
  final String moreLabel;

  /// "Continue, chapter 143": what the primary segment says to assistive tech when its visible label is shorter.
  final String? semanticsLabel;
  final GlassTwin? twin;

  /// For the gallery: 0 for the primary segment, 1 for the trailing one.
  final int? forcePressed;

  @override
  ConsumerState<GlassSplitButton> createState() => _GlassSplitButtonState();
}

class _GlassSplitButtonState extends ConsumerState<GlassSplitButton> with GlassLitState {
  final GlobalKey _moreKey = GlobalKey();
  int? _down;

  @override
  bool get isLit => widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    syncLit();
    final legible = ref.watch(glassA11yProvider.select((a) => a.legible));
    final st = roleStyle(context, gt.typeHeadline, onGlass: true, legible: legible, wght: 640, maxScale: 1.5);
    final lw = measureText(context, widget.label, st).width;
    final h = math.max(50.0, measureText(context, widget.label, st).height + 20);
    final primary = Size((lw + 40).ceilToDouble(), h);
    final more = Size(50, h);
    final pressed = widget.forcePressed ?? _down;
    final disabled = widget.onPressed == null;
    final suppressed = GlassLit.suppressed;

    Widget seg(int i, Size size, Widget Function(GlassPressInfo) content, VoidCallback? onTap, String label, {Key? key}) => GlassPressable(
          key: key,
          material: GlassMaterial.content,
          sink: 0.98,
          minHit: false,
          onTap: onTap,
          enabled: onTap != null,
          haptic: i == 0 ? HapticEvent.tapPrimary : null,
          semanticsLabel: label,
          onPressChanged: (d) => setState(() => _down = d ? i : (_down == i ? null : _down)),
          builder: (context, info) => SizedBox.fromSize(
            size: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(child: IgnorePointer(child: _SegGlow(own: info.glow, ownOn: pressed == i, otherOn: pressed != null && pressed != i))),
                content(info),
              ],
            ),
          ),
        );

    final tintedFill = suppressed || disabled ? const Color(0x00000000) : gt.glassTinted.fill;
    return SkinGlassGroup(
      gap: 0.5,
      debugLabel: 'GlassSplitButton',
      shapes: [
        SkinGlassShape(
          size: primary,
          twin: widget.twin,
          child: Stack(
            children: [
              Positioned.fill(child: AnimatedContainer(duration: Duration(milliseconds: gt.curveDimShift.ms ~/ 2), color: tintedFill)),
              seg(
                0,
                primary,
                (info) => Center(child: GlassLabel(widget.label, role: gt.typeHeadline, wght: 640, color: disabled ? gt.colorLabel4 : gt.colorOnTint, onGlass: true)),
                widget.onPressed,
                widget.semanticsLabel ?? widget.label,
              ),
              Positioned(right: 0, top: 6, bottom: 6, width: 0.5, child: ColoredBox(color: gt.colorSeparator)),
            ],
          ),
        ),
        SkinGlassShape(
          size: more,
          twin: widget.twin,
          child: seg(
            1,
            more,
            (info) => Center(child: GlyphIcon(GlassGlyph.caretDown, size: 20, color: gt.colorOnGlass)),
            () {
              final box = _moreKey.currentContext?.findRenderObject();
              final rect = box is RenderBox && box.attached ? box.localToGlobal(Offset.zero) & box.size : Rect.zero;
              widget.onMore(rect);
            },
            widget.moreLabel,
            key: _moreKey,
          ),
        ),
      ],
    );
  }
}

/// The lit segment's glow: 16 % on the pressed segment, 8 % on the other.
class _SegGlow extends StatelessWidget {
  const _SegGlow({required this.own, required this.ownOn, required this.otherOn});
  final ValueListenable<GlassPressGlow?> own;
  final bool ownOn;
  final bool otherOn;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<GlassPressGlow?>(
        valueListenable: own,
        builder: (context, g, _) => TweenAnimationBuilder<double>(
          tween: Tween(end: ownOn ? 1.0 : (otherOn ? 0.5 : 0.0)),
          duration: Duration(milliseconds: ownOn || otherOn ? gt.curveGlowIn.ms : gt.curveGlowOut.ms),
          builder: (context, amount, _) => CustomPaint(
            painter: GlassGlowPainter(shape: const GlassShape.capsule(), at: g?.local ?? const Offset(20, 25), amount: amount, tinted: false),
          ),
        ),
      );
}
