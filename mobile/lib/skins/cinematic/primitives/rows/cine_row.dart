import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_checkbox.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_galley.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_icon_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_menu.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/cinematic/stock.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// The shared frame of every row type (cinematic 7.16): a 1 px `rule.1` divider, hover / pressed /
/// selected / current / error / loading / disabled grounds, the trailing `dots-three` menu button
/// and the 450 ms long-press that open the same [showCineMenu], a leading select-mode checkbox and
/// an optional trailing [handle] (reorder).
class CineRowShell extends StatefulWidget {
  const CineRowShell({
    super.key,
    required this.child,
    this.onTap,
    this.menu,
    this.selected = false,
    this.selectMode = false,
    this.onSelectedChanged,
    this.disabled = false,
    this.loading = false,
    this.error = false,
    this.current = false,
    this.minHeight = 56,
    this.handle,
    this.semanticLabel,
    this.semanticValue,
    this.semanticActions,
    this.focusNode,
    this.dim = false,
    this.tight = false,
  });

  /// The content runs edge to edge vertically and the divider is painted over the row instead of
  /// added under it, so a 72 px cover makes a 72 px row (the Library LIST).
  final bool tight;

  final Widget child;
  final VoidCallback? onTap;

  /// Row actions; when non-empty the row gets the trailing button and the long-press.
  final List<CineMenuEntry<Object?>>? menu;
  final bool selected, selectMode, disabled, loading, error, current, dim;
  final ValueChanged<bool>? onSelectedChanged;
  final double minHeight;
  final Widget? handle;
  final String? semanticLabel, semanticValue;
  final Map<CustomSemanticsAction, VoidCallback>? semanticActions;
  final FocusNode? focusNode;

  @override
  State<CineRowShell> createState() => _CineRowShellState();
}

class _CineRowShellState extends State<CineRowShell> {
  Future<void> _openMenu(BuildContext ctx) async {
    final entries = widget.menu;
    if (entries == null || entries.isEmpty) return;
    await showCineMenu<Object?>(ctx, anchor: cineAnchorRect(ctx), entries: entries);
  }

  void _tap() {
    if (widget.selectMode) {
      widget.onSelectedChanged?.call(!widget.selected);
      return;
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final reduced = CineMotion.reduced(context);
    final hasMenu = widget.menu != null && widget.menu!.isNotEmpty;
    final on = !widget.disabled && !widget.loading;
    final interactive = on && (widget.onTap != null || widget.selectMode);
    return Semantics(
      container: true,
      label: widget.semanticLabel,
      value: widget.semanticValue ?? (widget.current ? 'current' : null),
      selected: widget.selected,
      enabled: !widget.disabled,
      customSemanticsActions: widget.semanticActions,
      child: CinePressable(
        enabled: interactive || hasMenu,
        focusNode: widget.focusNode,
        hit: false,
        onTap: interactive ? _tap : null,
        onLongPress: hasMenu && on
            ? () {
                cineFeedback(context, HapticEvent.longpressOpen);
                _openMenu(context);
              }
            : null,
        builder: (context, st) {
          final wash = widget.current;
          final raised = st.pressed || widget.selected || widget.error;
          final Color? fill = wash
              ? c.colorSpotWash
              : (widget.error ? c.colorProofWash : (raised ? c.colorPaper3 : null));
          final bar = widget.selected || wash ? c.colorSpot : (st.hovered || st.focused ? c.colorInk100 : null);
          final d = reduced ? Duration.zero : (st.pressed ? const Duration(milliseconds: 80) : c.durSnap);
          Widget body = AnimatedContainer(
            duration: wash && !reduced ? c.durLine : d,
            constraints: BoxConstraints(minHeight: widget.minHeight),
            decoration: BoxDecoration(color: fill, border: widget.tight ? null : Border(bottom: c.ruleHair)),
            foregroundDecoration: widget.tight ? BoxDecoration(border: Border(bottom: c.ruleHair)) : null,
            child: Stack(children: [
              Padding(
                padding: EdgeInsets.only(left: c.space4, right: hasMenu || widget.handle != null ? 0 : c.space4),
                child: Row(children: [
                  if (widget.selectMode) ...[
                    CineCheckbox(value: widget.selected, onChanged: widget.disabled ? null : (v) => widget.onSelectedChanged?.call(v), semanticLabel: widget.semanticLabel),
                    SizedBox(width: c.space3),
                  ],
                  Expanded(child: Padding(padding: EdgeInsets.symmetric(vertical: widget.tight ? 0 : c.space2), child: widget.child)),
                  if (hasMenu && !widget.selectMode)
                    Builder(
                      builder: (btn) => CineIconButton(
                        label: 'More actions',
                        codepoint: CineGlyph.dotsThree,
                        onPressed: on ? () => _openMenu(btn) : null,
                      ),
                    ),
                  if (widget.handle != null) widget.handle!,
                ],),
              ),
              Positioned(left: 0, top: 0, bottom: 0, width: 2, child: ColoredBox(color: bar ?? const Color(0x00000000))),
            ],),
          );
          if (widget.dim) body = Opacity(opacity: 0.55, child: body);
          if (wash) return CineStock.wash(body);
          return raised ? CineStock.raised(body) : body;
        },
      ),
    );
  }
}

/// The standard row (cinematic 7.16): a leading 20 px icon, 40 x 60 cover or 32 px avatar, a
/// `typeTitle` title over a `typeCaption` `ink.45` caption, and a trailing folio value or chevron.
/// Minimum 56 with one line, 72 with two. [loading] shows galley lines, [errorText] the reason in
/// `proof` with a trailing `quiet` Retry.
class CineRow extends StatelessWidget {
  const CineRow({
    super.key,
    required this.title,
    this.caption,
    this.leading,
    this.trailingFolio,
    this.trailing,
    this.chevron = false,
    this.onTap,
    this.menu,
    this.selected = false,
    this.selectMode = false,
    this.onSelectedChanged,
    this.disabled = false,
    this.loading = false,
    this.errorText,
    this.onRetry,
    this.current = false,
    this.handle,
    this.semanticActions,
    this.dim = false,
    this.focusNode,
  });

  final String title;
  final String? caption;
  final Widget? leading;
  final String? trailingFolio;
  final Widget? trailing;
  final bool chevron, selected, selectMode, disabled, loading, current, dim;
  final VoidCallback? onTap;
  final List<CineMenuEntry<Object?>>? menu;
  final ValueChanged<bool>? onSelectedChanged;
  final String? errorText;
  final VoidCallback? onRetry;
  final Widget? handle;
  final Map<CustomSemanticsAction, VoidCallback>? semanticActions;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    if (loading) {
      return ExcludeSemantics(
        child: CineRowShell(minHeight: 72, disabled: true, loading: true, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          CineGalleyLine(lineHeight: c.typeTitle.lines.first),
          CineGalleyLine(lineHeight: c.typeCaption.lines.first, index: 1),
        ],),),
      );
    }
    final ink = disabled ? c.colorInk30 : c.colorInk100;
    final sub = errorText ?? caption;
    final content = Row(children: [
      if (leading != null) ...[leading!, SizedBox(width: c.space4)],
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          CineRoleText(title, c.typeTitle, color: ink),
          if (sub != null) CineRoleText(sub, c.typeCaption, color: errorText != null ? c.colorProof : (disabled ? c.colorInk30 : c.colorInk45)),
        ],),
      ),
      if (errorText != null && onRetry != null) CineButton(label: 'Retry', variant: CineButtonVariant.quiet, onPressed: onRetry) else ...[
        if (trailingFolio != null) Padding(padding: EdgeInsets.only(left: c.space3), child: CineRoleText(trailingFolio!, c.typeFolio, color: c.colorInk45)),
        if (trailing != null) Padding(padding: EdgeInsets.only(left: c.space3), child: trailing),
        if (chevron) Padding(padding: EdgeInsets.only(left: c.space3), child: CineGlyphIcon(CineGlyph.caretRight, size: 16, color: c.colorInk45)),
      ],
    ],);
    return CineRowShell(
      minHeight: sub != null ? 72 : 56,
      onTap: onTap,
      menu: menu,
      selected: selected,
      selectMode: selectMode,
      onSelectedChanged: onSelectedChanged,
      disabled: disabled,
      error: errorText != null,
      current: current,
      handle: handle,
      dim: dim,
      focusNode: focusNode,
      semanticActions: semanticActions,
      semanticLabel: [title, if (sub != null) sub].join(', '),
      child: content,
    );
  }
}

/// A 20 px Regular row icon in `ink.60`.
Widget cineRowIcon(BuildContext context, int glyph) => CineGlyphIcon(glyph, color: context.cine.colorInk60);
