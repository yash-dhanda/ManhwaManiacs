import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_text_field.dart';

/// A numeric field: `typeFolioLg`, right-aligned, a unit suffix ("min", "GB"), digits only.
class CineNumberField extends StatelessWidget {
  const CineNumberField({
    super.key,
    required this.label,
    this.controller,
    this.focusNode,
    this.unit,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.loading = false,
    this.onChanged,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? unit, helperText, errorText;
  final bool enabled, loading;
  final ValueChanged<String>? onChanged, onSubmitted;

  @override
  Widget build(BuildContext context) => CineTextField(
        label: label,
        controller: controller,
        focusNode: focusNode,
        numeric: true,
        textAlign: TextAlign.end,
        suffixText: unit,
        helperText: helperText,
        errorText: errorText,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textInputAction: TextInputAction.done,
        enabled: enabled,
        loading: loading,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
      );
}
