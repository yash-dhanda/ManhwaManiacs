import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_text_field.dart';

/// A multi-line field with faint 1 px `rule.1` lines behind the text; grows to 6 lines, then scrolls.
class CineTextarea extends StatelessWidget {
  const CineTextarea({
    super.key,
    required this.label,
    this.controller,
    this.focusNode,
    this.hint,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.onChanged,
  });

  final String label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hint, helperText, errorText;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => CineTextField(
        label: label,
        controller: controller,
        focusNode: focusNode,
        hint: hint,
        helperText: helperText,
        errorText: errorText,
        enabled: enabled,
        onChanged: onChanged,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        minLines: 1,
        maxLines: 6,
        ruled: true,
      );
}
