import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/copy/errors.dart';
import 'package:manhwamaniacs/skins/glass/primitives/alert.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/hold_to_confirm.dart';
import 'package:manhwamaniacs/skins/glass/primitives/progress.dart';
import 'package:manhwamaniacs/skins/glass/primitives/text_field.dart' show GlassFieldMessage;

/// The delete alert (glass 7.11, 8.6): "Delete {name}?", Cancel first with initial focus, a 1,200 ms "Hold to delete" and, always
/// visible, "Delete profile". Confirming fires `delete.confirm` and deletes; pending blocks the confirm and an error stays inline
/// with the shake. Resolves true when the profile was deleted. It blooms from [sourceRect] (the button or orb).
Future<bool> showDeleteProfileAlert(BuildContext context, WidgetRef ref, {required Profile profile, Rect? sourceRect}) async {
  final r = await showGlassAlert<bool>(
    context,
    title: 'Delete ${profile.name}?',
    body: 'This removes ${profile.name} and its reading data from this account. It cannot be undone.',
    sourceRect: sourceRect,
    extra: _DeleteConfirm(profile: profile),
    actions: const [GlassAlertAction<bool>('Cancel', role: GlassAlertRole.cancel, value: false)],
  );
  return r ?? false;
}

class _DeleteConfirm extends ConsumerStatefulWidget {
  const _DeleteConfirm({required this.profile});
  final Profile profile;

  @override
  ConsumerState<_DeleteConfirm> createState() => _DeleteConfirmState();
}

class _DeleteConfirmState extends ConsumerState<_DeleteConfirm> {
  bool _pending = false;
  String? _error;
  int _trigger = 0;

  Future<void> _delete() async {
    if (_pending) return;
    glassFire(ref, HapticEvent.deleteConfirm);
    setState(() {
      _pending = true;
      _error = null;
    });
    final err = await ref.read(profilesProvider.notifier).delete(widget.profile.id);
    if (!mounted) return;
    if (err == null) {
      Navigator.of(context).pop(true);
      return;
    }
    glassFire(ref, HapticEvent.error);
    setState(() {
      _pending = false;
      _error = errorEntry(err).copy;
      _trigger++;
    });
  }

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_pending)
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Center(child: GlassSpinner(size: 24)))
          else
            GlassShake(
              trigger: _trigger,
              child: HoldToConfirm(
                label: 'Hold to delete',
                mode: HoldMode.inAlert,
                fallbackLabel: 'Delete profile',
                onConfirm: () => unawaited(_delete()),
              ),
            ),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Semantics(liveRegion: true, child: GlassFieldMessage(text: _error, error: true))),
        ],
      );
}
