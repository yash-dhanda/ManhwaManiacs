import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_text_field.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// A password field: a `quiet` "Show" / "Hide" word at the right end (words, not an eye), next in
/// the focus order after the field.
class CinePasswordField extends StatefulWidget {
  const CinePasswordField({
    super.key,
    required this.label,
    this.controller,
    this.focusNode,
    this.hint,
    this.helperText,
    this.errorText,
    this.textInputAction,
    this.autofillHints = const [AutofillHints.password],
    this.enabled = true,
    this.loading = false,
    this.onChanged,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hint, helperText, errorText;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool enabled, loading;
  final ValueChanged<String>? onChanged, onSubmitted;

  @override
  State<CinePasswordField> createState() => _CinePasswordFieldState();
}

class _CinePasswordFieldState extends State<CinePasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return CineTextField(
      label: widget.label,
      controller: widget.controller,
      focusNode: widget.focusNode,
      hint: widget.hint,
      helperText: widget.helperText,
      errorText: widget.errorText,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      autocorrect: false,
      enableSuggestions: false,
      obscureText: !_visible,
      enabled: widget.enabled,
      loading: widget.loading,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      trailing: Semantics(
        button: true,
        toggled: _visible,
        label: 'Show password',
        excludeSemantics: true,
        onTap: () => setState(() => _visible = !_visible),
        child: CinePressable(
          enabled: widget.enabled,
          onTap: () => setState(() => _visible = !_visible),
          builder: (context, st) => Padding(
            padding: EdgeInsets.only(left: c.space2),
            child: CineRoleText(_visible ? 'Hide' : 'Show', c.typeLabel, color: st.hovered ? c.colorInk100 : c.colorInk60),
          ),
        ),
      ),
    );
  }
}
