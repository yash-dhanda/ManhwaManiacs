import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';

/// The pending recommendation: [cancel] before the toast leaves stops the letter.
class LetterHandle {
  LetterHandle._(this._onCancel);
  final VoidCallback _onCancel;
  bool _done = false;
  bool _cancelled = false;

  bool get cancelled => _cancelled;
  bool get sent => _done && !_cancelled;

  void cancel() {
    if (_done) return;
    _done = true;
    _cancelled = true;
    _onCancel();
  }
}

/// Recommends [sourceId]:[seriesKey] to [toProfileId] with a deferred send (glass 9.3.4): the toast "Recommended to {name}" with Undo
/// (10 s, the draining rim) and, when [onAddNote] is given, "Add a note" (which hands the letter to the note sheet instead). The
/// letter is sent when the toast leaves or is dismissed; Undo cancels it first. A failed send shows "Couldn't send that" and calls
/// [onFailed] so the poster springs back out of the orb.
LetterHandle scheduleLetter(
  ProviderContainer container, {
  required int toProfileId,
  required String toName,
  required String sourceId,
  required String seriesKey,
  VoidCallback? onFailed,
  VoidCallback? onAddNote,
}) {
  ProviderSubscription<List<GlassToastEntry>>? sub;
  late final LetterHandle handle;
  handle = LetterHandle._(() {
    sub?.close();
  });

  Future<void> send() async {
    if (handle._done) return;
    handle._done = true;
    sub?.close();
    final err = await container.read(circleActionsProvider).sendLetter(toProfileIds: [toProfileId], sourceId: sourceId, seriesKey: seriesKey);
    if (err == null) return;
    onFailed?.call();
    final unavailable = err is ApiError && err.code == 'recipient_unavailable';
    container.read(glassToastProvider.notifier).show(GlassToastSpec(unavailable ? "$toName isn't taking recommendations any more." : "Couldn't send that", kind: GlassToastKind.error));
  }

  final spec = GlassToastSpec(
    'Recommended to $toName',
    kind: GlassToastKind.success,
    undo: handle.cancel,
    actionLabel: onAddNote == null ? null : 'Add a note',
    onAction: onAddNote == null
        ? null
        : () {
            handle.cancel();
            onAddNote();
          },
  );
  final toasts = container.read(glassToastProvider.notifier);
  toasts.show(spec);
  var seen = false;
  sub = container.listen<List<GlassToastEntry>>(glassToastProvider, (_, List<GlassToastEntry> next) {
    final present = next.any((GlassToastEntry e) => identical(e.spec, spec));
    if (present) {
      seen = true;
    } else if (seen) {
      unawaited(send());
    }
  }, fireImmediately: true);
  return handle;
}
