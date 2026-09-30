import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs_more.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/swipe_row.dart' show GlassSwipeSemantics;
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/primitives/selection_check.dart';
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';
import 'package:manhwamaniacs/skins/glass/primitives/spring_value.dart';
import 'package:manhwamaniacs/skins/glass/primitives/tooltip.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';

/// The selected-row fill (`iris600` at 14 %).
const Color kGlassRowSelectedFill = Color(0x247563F2);

/// True below 360 px of row width or at text scale 1.6 and up: the row stacks (glass 7.17).
bool glassRowStacks(BuildContext context, double width) => width < 360 || MediaQuery.textScalerOf(context).scale(10) >= 16;

/// The text tone of a row: `label1..4`, or `onGlass` inside a T4/T5 host (glass 2.1.2).
Color glassRowTone(BuildContext context, int level, {bool disabled = false}) {
  if (disabled) return GlassHost.of(context) ? gt.colorOnGlass.withValues(alpha: 0.38) : gt.colorLabel4;
  if (GlassHost.of(context)) return level == 1 ? gt.colorOnGlass : gt.colorOnGlass.withValues(alpha: level == 2 ? 0.72 : 0.56);
  return switch (level) { 1 => gt.colorLabel1, 2 => gt.colorLabel2, _ => gt.colorLabel3 };
}

/// What every list row shares: the press (sink to `surface3` at 0.99), hover `fill4`, the select-mode slide with its
/// check, the `iris600` selected fill, the loading skeleton and the error mark. One `Semantics(button)` node.
class GlassRowShell extends ConsumerWidget {
  const GlassRowShell({
    super.key,
    required this.builder,
    required this.semanticsLabel,
    this.minHeight = 52,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.loading = false,
    this.selectMode = false,
    this.selected = false,
    this.error,
    this.forceStates = GlassWidgetStates.none,
    this.customActions = const {},
    this.semanticsHint,
    this.focusNode,
    this.pressedFill,
  });

  /// Builds the row content; `stacked` is true when the row must stack its parts.
  final Widget Function(BuildContext context, bool stacked, GlassPressInfo info) builder;
  final String semanticsLabel;
  final double minHeight;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enabled;
  final bool loading;
  final bool selectMode;
  final bool selected;
  final String? error;
  final GlassWidgetStates forceStates;
  final Map<CustomSemanticsAction, VoidCallback> customActions;
  final String? semanticsHint;
  final FocusNode? focusNode;
  final Color? pressedFill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (loading) {
      return ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: GlassSkeleton(height: minHeight - 16, radius: 12)),
      );
    }
    return LayoutBuilder(
      builder: (context, box) {
        final stacked = glassRowStacks(context, box.maxWidth);
        return GlassPressable(
          material: GlassMaterial.content,
          sink: 0.99,
          shape: const GlassShape.superellipse(0),
          onTap: onTap,
          onLongPress: onLongPress,
          enabled: enabled && !loading,
          selected: selected,
          error: error != null,
          forceStates: forceStates,
          semanticsLabel: semanticsLabel,
          semanticsHint: semanticsHint,
          checked: selectMode ? selected : null,
          customActions: {...GlassSwipeSemantics.of(context), ...customActions},
          focusNode: focusNode,
          hoverGlow: false,
          builder: (context, info) {
            final s = info.states;
            final fill = s.pressed ? (pressedFill ?? gt.colorSurface3) : selected ? kGlassRowSelectedFill : s.hovered ? gt.colorFill4 : null;
            return DecoratedBox(
              decoration: BoxDecoration(color: fill),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minHeight),
                child: SpringValue(
                  value: selectMode ? 1 : 0,
                  spring: gt.springSnappy,
                  builder: (context, v, _) => Row(
                    children: [
                      if (v > 0.001)
                        ClipRect(
                          child: SizedBox(
                            width: 36 * v.clamp(0.0, 1.0),
                            child: OverflowBox(
                              alignment: Alignment.centerLeft,
                              minWidth: 36,
                              maxWidth: 36,
                              child: Padding(padding: const EdgeInsets.only(left: 12), child: GlassSelectionCheck(selected: selected)),
                            ),
                          ),
                        ),
                      Expanded(child: builder(context, stacked, info)),
                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GlassTooltip(
                            message: error!,
                            child: GlyphIcon(GlassGlyph.warningCircle, size: 20, color: gt.colorDanger),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// The plain `dots-three` "More actions" button every swipe row has (hit `hitMin`).
IconData get kMoreGlyph => GlassGlyph28.dotsThree.regular;
