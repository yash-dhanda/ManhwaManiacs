import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/circle/utils/letters_deferred.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';

/// The pending recommendation: [cancel] before the toast leaves stops the letter.
class LetterHandle {
  LetterHandle._(this.pending);
  final PendingLetter pending;

  bool get cancelled => pending.cancelled;
  bool get sent => pending.done && !pending.cancelled;

  void cancel() => pending.undo();
}

/// The letter the note sheet holds ("Add a note"); its Send calls `sendWithNote`, closing it unsent flushes it.
final heldLetterProvider = StateProvider<PendingLetter?>((ref) => null, name: 'glassHeldLetter');

/// Recommends [sourceId]:[seriesKey] to [toProfileId] with a deferred send (glass 9.3.4) through the shared `pendingLettersProvider`:
/// the toast "Recommended to {name}" with Undo (10 s, the draining rim) and, when [onAddNote] is given, "Add a note" (which holds the
/// letter for the note sheet). The letter is sent when the toast leaves or its 10 s window ends, whichever is first, or when the app
/// is paused; Undo cancels it. A failed send shows "Couldn't send that" with "Try again" and calls [onFailed]; by then the poster
/// and the orbs are gone, so the toast is the whole failure state.
LetterHandle scheduleLetter(
  ProviderContainer container, {
  required int toProfileId,
  required String toName,
  required String sourceId,
  required String seriesKey,
  bool mature = false,
  VoidCallback? onFailed,
  VoidCallback? onAddNote,
}) {
  ProviderSubscription<List<GlassToastEntry>>? sub;
  late final PendingLetter pending;
  // The sender is the profile active now: the send may run after a profile switch.
  int? from;
  try {
    from = container.read(activeProfileProvider)?.id;
  } catch (_) {}

  Future<void> send(LetterDraft d) async {
    sub?.close();
    final err = await container.read(circleActionsProvider).sendLetter(toProfileIds: d.toProfileIds, sourceId: d.sourceId, seriesKey: d.seriesKey, note: d.note, asProfileId: from);
    if (err == null) return;
    onFailed?.call();
    final toasts = container.read(glassToastProvider.notifier);
    if (err is ApiError && err.code == 'recipient_unavailable') {
      toasts.show(GlassToastSpec("$toName isn't taking recommendations any more.", kind: GlassToastKind.warning));
      return;
    }
    toasts.show(GlassToastSpec("Couldn't send that", kind: GlassToastKind.error, actionLabel: 'Try again', onAction: () => unawaited(send(d))));
  }

  pending = container.read(pendingLettersProvider.notifier).schedule(toProfileIds: [toProfileId], sourceId: sourceId, seriesKey: seriesKey, mature: mature, send: send);
  final spec = GlassToastSpec(
    'Recommended to $toName',
    kind: GlassToastKind.success,
    undo: pending.undo,
    tag: mature ? 'mature:$sourceId:$seriesKey' : null,
    actionLabel: onAddNote == null ? null : 'Add a note',
    onAction: onAddNote == null
        ? null
        : () {
            sub?.close();
            pending.hold();
            container.read(heldLetterProvider.notifier).state = pending;
            onAddNote();
          },
  );
  container.read(glassToastProvider.notifier).show(spec);
  var seen = false;
  sub = container.listen<List<GlassToastEntry>>(glassToastProvider, (_, List<GlassToastEntry> next) {
    final present = next.any((GlassToastEntry e) => identical(e.spec, spec));
    if (present) {
      seen = true;
    } else if (seen && !pending.held) {
      unawaited(pending.flush());
    }
  }, fireImmediately: true,);
  return LetterHandle._(pending);
}
