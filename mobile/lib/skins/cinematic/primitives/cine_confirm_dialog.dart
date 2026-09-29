import 'package:flutter/material.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/arm.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_checkbox.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_dialog.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_text_field.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/dialog_route.dart';

/// A confirmation dialog (cinematic 7.10). A [destructive] confirm opens armed for 1000 ms: the
/// committing button is dead while a `proof` rule fills under it; `Cancel` is live from the first
/// frame and holds the initial focus. Heavy confirmations add [typedPhrase] ("Type RESTORE to
/// confirm", case-insensitive), [acknowledge] (a checkbox) or [typedUsername]; the confirm
/// enables only when the arm has elapsed and the condition is met.
///
/// [onConfirm] runs while the button shows its loading state, Cancel is disabled and the barrier
/// is locked; on success the dialog pops `true`, on a failure an error line shows in `proof`.
/// Without [onConfirm] it pops `true` at once.
class CineConfirmDialog extends StatefulWidget {
  const CineConfirmDialog({
    super.key,
    required this.title,
    required this.confirmLabel,
    this.body,
    this.cancelLabel = 'Cancel',
    this.destructive = false,
    this.filled = false,
    this.onConfirm,
    this.typedPhrase,
    this.acknowledge,
    this.typedUsername,
  });

  final String title, confirmLabel, cancelLabel;
  final String? body;
  final bool destructive, filled;
  final Future<void> Function()? onConfirm;
  final String? typedPhrase, acknowledge, typedUsername;

  @override
  State<CineConfirmDialog> createState() => _CineConfirmDialogState();
}

class _CineConfirmDialogState extends State<CineConfirmDialog> {
  final _cancel = FocusNode(debugLabel: 'confirm-cancel');
  final _text = TextEditingController();
  bool _ack = false, _pending = false;
  String? _error;

  String? get _needle => widget.typedPhrase ?? widget.typedUsername;

  bool get _condition {
    if (_needle != null && _text.text.trim().toLowerCase() != _needle!.toLowerCase()) return false;
    if (widget.acknowledge != null && !_ack) return false;
    return true;
  }

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _cancel.requestFocus();
    });
  }

  @override
  void dispose() {
    _cancel.dispose();
    _text.dispose();
    super.dispose();
  }

  void _close(bool v) {
    if (_pending) return;
    Navigator.of(context).pop(v);
  }

  Future<void> _confirm() async {
    final run = widget.onConfirm;
    if (run == null) return Navigator.of(context).pop(true);
    final route = cineDialogRouteOf(context);
    setState(() {
      _pending = true;
      _error = null;
    });
    route?.locked = true;
    try {
      await run();
      if (mounted) {
        route?.locked = false;
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      route?.locked = false;
      if (mounted) {
        setState(() {
          _pending = false;
          _error = e is AppError ? e.userMessage : 'That didn’t go through. Try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget? content;
    if (_needle != null) {
      content = CineTextField(
        key: const Key('confirm-phrase'),
        label: widget.typedPhrase != null ? 'Type ${widget.typedPhrase} to confirm' : 'Type $_needle to confirm',
        controller: _text,
        enabled: !_pending,
        autocorrect: false,
        enableSuggestions: false,
      );
    } else if (widget.acknowledge != null) {
      content = CineCheckbox(key: const Key('confirm-ack'), value: _ack, label: widget.acknowledge, onChanged: _pending ? null : (v) => setState(() => _ack = v));
    }
    return PopScope(
      canPop: !_pending,
      child: CineDialog(
        title: widget.title,
        body: widget.body,
        content: content,
        errorText: _error,
        onCancel: _pending ? null : () => _close(false),
        actions: [
          CineArmButton(
            key: const Key('confirm-commit'),
            label: widget.confirmLabel,
            destructive: widget.destructive,
            filled: widget.filled,
            conditionMet: _condition,
            loading: _pending,
            onPressed: _confirm,
          ),
          CineButton(
            key: const Key('confirm-cancel'),
            label: widget.cancelLabel,
            variant: CineButtonVariant.quiet,
            focusNode: _cancel,
            onPressed: _pending ? null : () => _close(false),
          ),
        ],
      ),
    );
  }
}

/// Opens a [CineConfirmDialog]; resolves `true` only when the user committed.
Future<bool> showCineConfirm(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String? body,
  bool destructive = false,
  bool filled = false,
  Future<void> Function()? onConfirm,
  String? typedPhrase,
  String? acknowledge,
  String? typedUsername,
}) async =>
    await showCineDialog<bool>(
      context,
      builder: (_) => CineConfirmDialog(
        title: title,
        body: body,
        confirmLabel: confirmLabel,
        destructive: destructive,
        filled: filled,
        onConfirm: onConfirm,
        typedPhrase: typedPhrase,
        acknowledge: acknowledge,
        typedUsername: typedUsername,
      ),
    ) ??
    false;
