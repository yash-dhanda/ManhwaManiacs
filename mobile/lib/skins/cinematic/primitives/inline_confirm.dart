import 'dart:async';

import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/arm.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';

/// An inline destructive confirm (cinematic 7.10): the button turns into "Confirm {verb}" with the
/// 1000 ms arm, and reverts after 4000 ms without a press.
class CineInlineConfirm extends StatefulWidget {
  const CineInlineConfirm({super.key, required this.label, required this.verb, required this.onConfirm});

  /// The idle label ("Remove downloads").
  final String label;

  /// The verb in "Confirm {verb}".
  final String verb;
  final VoidCallback onConfirm;

  @override
  State<CineInlineConfirm> createState() => _CineInlineConfirmState();
}

class _CineInlineConfirmState extends State<CineInlineConfirm> {
  Timer? _revert;
  bool _confirming = false;

  void _ask() {
    setState(() => _confirming = true);
    _revert?.cancel();
    _revert = Timer(const Duration(milliseconds: 4000), () {
      if (mounted) setState(() => _confirming = false);
    });
  }

  @override
  void dispose() {
    _revert?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_confirming) {
      return CineButton(label: widget.label, variant: CineButtonVariant.destructive, onPressed: _ask);
    }
    return CineArmButton(
      label: 'Confirm ${widget.verb}',
      onPressed: () {
        _revert?.cancel();
        setState(() => _confirming = false);
        widget.onConfirm();
      },
    );
  }
}
