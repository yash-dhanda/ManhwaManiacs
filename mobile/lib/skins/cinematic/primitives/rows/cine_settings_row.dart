import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_menu.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_dot_leader.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_row.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The settings row (cinematic 7.16): `typeUi` label, `typeCaption` `ink.45` description and a
/// trailing switch or other [control], a [value] after dot leaders, or a chevron. One column from
/// text scale 2.0, the control under the text.
class CineSettingsRow extends StatelessWidget {
  const CineSettingsRow({
    super.key,
    required this.label,
    this.description,
    this.control,
    this.value,
    this.chevron = false,
    this.onTap,
    this.menu,
    this.disabled = false,
    this.errorText,
  });

  final String label;
  final String? description;
  final Widget? control;
  final String? value;
  final bool chevron, disabled;
  final VoidCallback? onTap;
  final List<CineMenuEntry<Object?>>? menu;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final ink = disabled ? c.colorInk30 : c.colorInk100;
    final stacked = CineReflow.of(context).fullDetent;
    final text = Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      CineRoleText(label, c.typeUi, color: ink),
      if (description != null) CineRoleText(description!, c.typeCaption, color: disabled ? c.colorInk30 : c.colorInk45),
      if (errorText != null) CineRoleText(errorText!, c.typeCaption, color: c.colorProof),
    ],);
    final Widget content;
    if (value != null && !stacked) {
      content = Row(children: [
        Expanded(child: CineLeaderRow(label: text, value: CineRoleText(value!, c.typeFolio, color: disabled ? c.colorInk30 : c.colorInk60, maxLines: 1, overflow: TextOverflow.ellipsis))),
        if (chevron) Padding(padding: EdgeInsets.only(left: c.space2), child: CineGlyphIcon(CineGlyph.caretRight, size: 16, color: c.colorInk45)),
      ],);
    } else if (stacked) {
      content = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        text,
        if (control != null) Padding(padding: EdgeInsets.only(top: c.space2), child: control),
        if (value != null) CineRoleText(value!, c.typeFolio, color: c.colorInk60),
      ],);
    } else {
      content = Row(children: [
        Expanded(child: text),
        if (control != null) Padding(padding: EdgeInsets.only(left: c.space3), child: control),
        if (chevron) Padding(padding: EdgeInsets.only(left: c.space3), child: CineGlyphIcon(CineGlyph.caretRight, size: 16, color: c.colorInk45)),
      ],);
    }
    return CineRowShell(
      onTap: onTap,
      menu: menu,
      disabled: disabled,
      error: errorText != null,
      semanticLabel: [label, if (description != null) description!, if (value != null) value!].join(', '),
      child: content,
    );
  }
}
