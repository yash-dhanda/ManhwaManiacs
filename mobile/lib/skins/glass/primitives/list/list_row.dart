import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/row_shell.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// One row of a grouped or plain list (glass 7.17): optional 30 x 30 icon tile (radius 12, an 18 px glyph), title, subtitle,
/// trailing value and a trailing control. Min height 52 (64 with a subtitle). Stacks below 360 px and at text scale 1.6.
class GlassListRow extends ConsumerWidget {
  const GlassListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.value,
    this.icon,
    this.iconColor,
    this.trailing,
    this.caret = false,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.loading = false,
    this.selectMode = false,
    this.selected = false,
    this.error,
    this.forceStates = GlassWidgetStates.none,
    this.customActions = const {},
    this.focusNode,
  });

  final String title;
  final String? subtitle;
  final String? value;
  final IconData? icon;

  /// The tile's semantic colour; null draws it on `surface3`.
  final Color? iconColor;

  /// A `GlassSwitch`, a `GlassBadge` or a button.
  final Widget? trailing;

  /// The 14 px `caret-right` in `g600`.
  final bool caret;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enabled;
  final bool loading;
  final bool selectMode;
  final bool selected;
  final String? error;
  final GlassWidgetStates forceStates;
  final Map<CustomSemanticsAction, VoidCallback> customActions;
  final FocusNode? focusNode;

  bool get hasIconTile => icon != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = [title, if (subtitle != null) subtitle!, if (value != null) value!].join(', ');
    return GlassRowShell(
      minHeight: subtitle != null ? 64 : 52,
      semanticsLabel: label,
      onTap: onTap,
      onLongPress: onLongPress,
      enabled: enabled,
      loading: loading,
      selectMode: selectMode,
      selected: selected,
      error: error,
      forceStates: forceStates,
      customActions: customActions,
      focusNode: focusNode,
      builder: (context, stacked, info) {
        final host = GlassHost.of(context);
        final off = !enabled;
        final tile = icon == null
            ? null
            : Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: iconColor ?? gt.colorSurface3, borderRadius: BorderRadius.circular(gt.radiusIconTile)),
                child: Icon(icon, size: 18, color: const Color(0xFFFFFFFF)),
              );
        final titleW = GlassText(title, role: gt.typeBody, color: glassRowTone(context, 1, disabled: off), onGlass: host, maxScale: 1.6);
        final subW = subtitle == null ? null : GlassText(subtitle!, role: gt.typeFootnote, color: glassRowTone(context, 2, disabled: off), onGlass: host, maxScale: 1.6);
        final valueW = value == null ? null : GlassText(value!, role: gt.typeBody, color: glassRowTone(context, 2, disabled: off), onGlass: host, maxScale: 1.6);
        final caretW = caret ? Icon(GlassGlyph.caretRight.bold, size: 14, color: GlassColors.g600) : null;
        final texts = Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [titleW, if (subW != null) subW]);
        if (stacked) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // The title wraps beside the tile; the control and caret stay at the row's end, never on a line of their own.
                Row(children: [
                  if (tile != null) ...[tile, const SizedBox(width: 12)],
                  Expanded(child: titleW),
                  if (trailing != null) ...[const SizedBox(width: 12), trailing!],
                  if (caretW != null) ...[const SizedBox(width: 8), caretW],
                ],),
                if (subW != null) Padding(padding: const EdgeInsets.only(top: 2), child: subW),
                if (valueW != null) Padding(padding: const EdgeInsets.only(top: 4), child: valueW),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              if (tile != null) ...[tile, const SizedBox(width: 12)],
              Expanded(child: texts),
              // The value sits against the trailing edge (beside its caret), never floating mid-row.
              if (valueW != null) ...[const SizedBox(width: 12), Flexible(child: Align(alignment: AlignmentDirectional.centerEnd, child: valueW))],
              if (trailing != null) ...[const SizedBox(width: 12), trailing!],
              if (caretW != null) ...[const SizedBox(width: 8), caretW],
            ],
          ),
        );
      },
    );
  }
}
