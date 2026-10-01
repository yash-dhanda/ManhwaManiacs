
import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';

/// Extra distance a focused rect must be scrolled so it clears a band it overlaps (WCAG 2.4.11), or 0.
double focusOverlapShift({required Rect focused, required double viewportHeight, required double topBand, required double bottomBand}) {
  if (focused.top < topBand) return focused.top - topBand - 8; // negative: scroll up
  if (focused.bottom > viewportHeight - bottomBand) return focused.bottom - (viewportHeight - bottomBand) + 8;
  return 0;
}

/// Reading-order traversal for Glass; [bands] gives the floating chrome bands that [scrollFocusClearOfBands] keeps focus out of.
class GlassFocusTraversalPolicy extends ReadingOrderTraversalPolicy {
  GlassFocusTraversalPolicy({required this.bands});

  /// `(top, bottom)` bands for the current frame; read at focus time.
  final ({double top, double bottom}) Function(BuildContext context) bands;
}

/// Keeps hardware-keyboard focus out from under the floating bars (glass 2.2, WCAG 2.4.11): after the frame, the nearest vertical
/// scroll position moves by the overlap plus 8 px on `springSettle`. Called for every focus change (GlassRoot listens to the focus
/// manager), so nested traversal groups (rails, grouped lists) whose own policy moved focus get it too.
void scrollFocusClearOfBands(FocusNode node, ({double top, double bottom}) Function(BuildContext context) bands) {
  final ctx = node.context;
  if (ctx == null) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!ctx.mounted) return;
    final ro = ctx.findRenderObject();
    // The vertical scroller: a rail's horizontal scroller cannot move the control out of a band.
    final scrollable = Scrollable.maybeOf(ctx, axis: Axis.vertical);
    if (ro is! RenderBox || !ro.attached || scrollable == null) return;
    final box = scrollable.context.findRenderObject();
    if (box is! RenderBox || !box.attached) return;
    final rect = box.globalToLocal(ro.localToGlobal(Offset.zero)) & ro.size;
    final b = bands(ctx);
    final shift = focusOverlapShift(focused: rect, viewportHeight: box.size.height, topBand: b.top, bottomBand: b.bottom);
    if (shift == 0) return;
    final pos = scrollable.position;
    final target = (pos.pixels + shift).clamp(pos.minScrollExtent, pos.maxScrollExtent);
    if (target == pos.pixels) return;
    if (GlassMotion.isReduced()) {
      pos.jumpTo(target);
    } else {
      pos.animateTo(target, duration: const Duration(milliseconds: 414), curve: SpringCurve(GlassSprings.settle));
    }
  });
  WidgetsBinding.instance.ensureVisualUpdate();
}

/// A surface whose floating chrome is not the frame's nav row or toolbar declares its own bands: the series window (its nav row is
/// part of the scrolling band, nothing floats above it) and the search page (its field floats at the bottom, nothing at the top).
class GlassFocusBandsScope extends InheritedWidget {
  const GlassFocusBandsScope({super.key, required this.top, required this.bottom, required super.child});
  final double top;
  final double bottom;

  @override
  bool updateShouldNotify(GlassFocusBandsScope old) => old.top != top || old.bottom != bottom;
}

/// The bands of the current frame: safe-top + 60 and safe-bottom + 85 on phones, 76 and 24 on wider frames, unless a
/// [GlassFocusBandsScope] above [context] declares its own.
({double top, double bottom}) glassFocusBands(BuildContext context, {bool accessory = false}) {
  final scope = context.getInheritedWidgetOfExactType<GlassFocusBandsScope>();
  if (scope != null) return (top: scope.top, bottom: scope.bottom);
  final safe = MediaQuery.paddingOf(context);
  if (GlassFrame.of(context) == GlassFrameKind.phone) {
    return (top: safe.top + 60, bottom: safe.bottom + 85 + (accessory ? 56 : 0));
  }
  return (top: 76, bottom: 24);
}

