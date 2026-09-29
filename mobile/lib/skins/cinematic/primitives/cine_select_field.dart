import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_radio.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_row.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/sheet_route.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

class CineOption<T> {
  const CineOption(this.value, this.label);
  final T value;
  final String label;
}

/// The Select field (cinematic 7.3): the editorial underline field with a trailing `caret-down`.
/// On the app it always opens a `CineSheet` of radio rows; the value shows in the field.
class CineSelectField<T> extends StatelessWidget {
  const CineSelectField({super.key, required this.label, required this.value, required this.options, required this.onChanged, this.enabled = true});

  final String label;
  final T? value;
  final List<CineOption<T>> options;
  final ValueChanged<T>? onChanged;
  final bool enabled;

  String? get _current {
    for (final o in options) {
      if (o.value == value) return o.label;
    }
    return null;
  }

  Future<void> _open(BuildContext context) async {
    final picked = await showCineSheet<T>(
      context,
      kicker: label.toUpperCase(),
      title: label,
      builder: (ctx) => Column(children: [
        for (final o in options)
          CineRow(
            title: o.label,
            leading: IgnorePointer(child: CineRadio<T>(value: o.value, groupValue: value, onChanged: (_) {}, semanticLabel: o.label)),
            onTap: () => Navigator.of(ctx).pop(o.value),
          ),
      ],),
    );
    if (picked != null && picked != value) onChanged?.call(picked);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final on = enabled && onChanged != null;
    return Semantics(
      button: true,
      enabled: on,
      label: label,
      value: _current,
      excludeSemantics: true,
      onTap: on ? () => _open(context) : null,
      child: CinePressable(
        enabled: on,
        onTap: () => _open(context),
        builder: (context, st) => Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: EdgeInsets.symmetric(vertical: c.space2),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: !on ? c.colorRule1 : (st.focused || st.hovered ? c.colorInk100 : c.colorInk45), width: st.focused ? 2 : 1))),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                CineRoleText(label, c.typeKicker, color: c.colorInk60),
                CineRoleText(_current ?? ' ', c.typeField, color: on ? c.colorInk100 : c.colorInk30),
              ],),
            ),
            CineGlyphIcon(CineGlyph.caretDown, size: 16, color: on ? c.colorInk60 : c.colorInk30),
          ],),
        ),
      ),
    );
  }
}
