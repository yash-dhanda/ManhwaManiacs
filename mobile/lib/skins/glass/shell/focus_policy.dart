
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

/// Reading-order traversal that keeps hardware-keyboard focus out from under the floating bars: after `ensureVisible`, the nearest
/// scroll position moves by the overlap plus 8 px on `springSettle` (glass 2.2).
class GlassFocusTraversalPolicy extends ReadingOrderTraversalPolicy {
  GlassFocusTraversalPolicy({required this.bands}) : super(requestFocusCallback: _request);

  /// `(top, bottom)` bands for the current frame; read at focus time.
  final ({double top, double bottom}) Function(BuildContext context) bands;

  static void _request(FocusNode node, {ScrollPositionAlignmentPolicy? alignmentPolicy, double? alignment, Duration? duration, Curve? curve}) {
    FocusTraversalPolicy.defaultTraversalRequestFocusCallback(node, alignmentPolicy: alignmentPolicy, alignment: alignment, duration: duration, curve: curve);
    final ctx = node.context;
    if (ctx == null) return;
    final policy = FocusTraversalGroup.maybeOf(ctx);
    if (policy is! GlassFocusTraversalPolicy) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!ctx.mounted) return;
      final ro = ctx.findRenderObject();
      final scrollable = Scrollable.maybeOf(ctx);
      if (ro is! RenderBox || !ro.attached || scrollable == null) return;
      final box = scrollable.context.findRenderObject();
      if (box is! RenderBox) return;
      final rect = box.globalToLocal(ro.localToGlobal(Offset.zero)) & ro.size;
      final b = policy.bands(ctx);
      final shift = focusOverlapShift(focused: rect, viewportHeight: box.size.height, topBand: b.top, bottomBand: b.bottom);
      if (shift == 0) return;
      final pos = scrollable.position;
      final target = (pos.pixels + shift).clamp(pos.minScrollExtent, pos.maxScrollExtent);
      if (GlassMotion.isReduced()) {
        pos.jumpTo(target);
      } else {
        pos.animateTo(target, duration: const Duration(milliseconds: 414), curve: SpringCurve(GlassSprings.settle));
      }
    });
  }
}

/// The bands of the current frame: safe-top + 60 and safe-bottom + 85 on phones, 76 and 24 on wider frames.
({double top, double bottom}) glassFocusBands(BuildContext context, {bool accessory = false}) {
  final safe = MediaQuery.paddingOf(context);
  if (GlassFrame.of(context) == GlassFrameKind.phone) {
    return (top: safe.top + 60, bottom: safe.bottom + 85 + (accessory ? 56 : 0));
  }
  return (top: 76, bottom: 24);
}

