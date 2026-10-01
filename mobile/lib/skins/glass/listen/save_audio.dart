/// Save audio to this device (glass 8.16.2, G): the player's ⋯ row. "Save audio to this device" -> "Saving audio..." -> "Audio saved"
/// (a tap asks "Remove saved audio?" with Keep / Remove) -> failed "Couldn't save the audio · tap to retry" -> unplayable
/// "The saved audio can't play here · tap to save again", all from `savedAudioStateProvider`. A first request answered
/// `503 audio_preparing` shows "Preparing audio" with the liquid ring (the queue retries after `Retry-After`, 3 s without one).
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/downloads/models/chapter_identity.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/novels/controllers/narration_controller.dart';
import 'package:manhwamaniacs/features/novels/providers/saved_audio_provider.dart';
import 'package:manhwamaniacs/skins/glass/icons/phosphor.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/alert.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/progress.dart';

String saveAudioLabel(SavedAudioState s) => switch (s) {
      SavedAudioState.none => 'Save audio to this device',
      SavedAudioState.preparing => 'Preparing audio',
      SavedAudioState.saving => 'Saving audio…',
      SavedAudioState.saved => 'Audio saved',
      SavedAudioState.failed => "Couldn't save the audio · tap to retry",
      SavedAudioState.unplayable => "The saved audio can't play here · tap to save again",
    };

/// Whether the ⋯ offers the row: phones with a downloads scope.
bool saveAudioAvailable(WidgetRef ref) => ref.read(downloadsStoreProvider) != null;

/// What a tap does for [state]; null while saving or preparing.
Future<void> Function()? saveAudioTap(BuildContext context, WidgetRef ref, NarrationTarget t, SavedAudioState state) {
  final ChapterIdentity id = t.key;
  final queue = ref.read(downloadQueueControllerProvider.notifier);
  Future<void> save() => queue.enqueueChapters(narrationDownloadRequests(chapter: id, chapterNumber: t.chapterNumber, title: t.chapterTitle, seriesTitle: t.bookTitle));
  return switch (state) {
    SavedAudioState.none || SavedAudioState.failed => save,
    SavedAudioState.saving || SavedAudioState.preparing => null,
    SavedAudioState.saved => () async {
        final remove = await showGlassAlert<bool>(
          context,
          title: 'Remove saved audio?',
          body: 'The chapter stays on this device to read.',
          actions: const [
            GlassAlertAction<bool>('Keep', role: GlassAlertRole.cancel, value: false),
            GlassAlertAction<bool>('Remove', role: GlassAlertRole.destructive, value: true),
          ],
        );
        if (remove ?? false) await queue.cancelChapter(audioIdentity(id));
      },
    SavedAudioState.unplayable => () async {
        // The old row has to go first: saving onto a complete row keeps the bytes it has, which are the ones that do not play.
        await queue.cancelChapter(audioIdentity(id));
        await save();
      },
  };
}

/// The menu row.
GlassMenuEntry saveAudioEntry(BuildContext context, WidgetRef ref, NarrationTarget t) {
  final state = ref.read(savedAudioStateProvider(t.key));
  final tap = saveAudioTap(context, ref, t, state);
  final busy = state == SavedAudioState.saving || state == SavedAudioState.preparing;
  return GlassMenuEntry(
    label: saveAudioLabel(state),
    icon: state == SavedAudioState.saved ? PhosphorRegular.check : PhosphorRegular.cloudArrowDown,
    leading: busy ? const GlassSpinner() : null,
    enabled: tap != null,
    onSelected: tap == null ? null : () => unawaited(tap()),
  );
}
