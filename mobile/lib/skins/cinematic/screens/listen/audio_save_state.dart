import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/downloads/models/chapter_identity.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_chapter_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/saved_audio_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_confirm_dialog.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_progress.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// The words of a saved-audio state (cinematic 8.16.9), `null` for `none` (the row then offers
/// the save).
String? audioSaveCaption(SavedAudioState s) => switch (s) {
      SavedAudioState.none => null,
      SavedAudioState.preparing => 'Preparing the audio…',
      SavedAudioState.saving => 'Saving audio…',
      SavedAudioState.saved => 'Audio saved',
      SavedAudioState.failed => "Couldn't save the audio. Tap to try again.",
      SavedAudioState.unplayable => "The saved audio can't play on this device. Tap to save it again.",
    };

/// The row that carries a chapter's audio save state, in the mini player's overflow and the
/// opener: `Save audio to this device` -> saving (leader dial) -> `Audio saved` (check) -> a tap
/// asks `Remove saved audio? The chapter stays on this device to read.` (destructive, the 1000 ms
/// arm) / failed / unplayable / preparing. Built only when a downloads scope exists.
class AudioSaveRow extends ConsumerWidget {
  const AudioSaveRow({super.key, required this.chapter, this.chapterNumber, this.title, this.seriesTitle, this.compact = false});

  final NovelChapterKey chapter;
  final double? chapterNumber;
  final String? title, seriesTitle;

  /// A caption in `typeFolio` (the opener) rather than a full row.
  final bool compact;

  ChapterIdentity get _id => chapter;

  void _save(WidgetRef ref) => unawaited(
        ref.read(downloadQueueControllerProvider.notifier).enqueueChapters(
              narrationDownloadRequests(chapter: _id, chapterNumber: chapterNumber, title: title, seriesTitle: seriesTitle),
            ),
      );

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final ok = await showCineConfirm(
      context,
      title: 'Remove saved audio?',
      body: 'The chapter stays on this device to read.',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (!ok) return;
    if (context.mounted) cineFeedback(context, HapticEvent.deleteConfirm);
    await ref.read(downloadQueueControllerProvider.notifier).cancelChapter(audioIdentity(_id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(downloadsStoreProvider) == null) return const SizedBox.shrink();
    final c = context.cine;
    final state = ref.watch(savedAudioStateProvider(chapter));
    final busy = state == SavedAudioState.saving || state == SavedAudioState.preparing;
    final caption = audioSaveCaption(state) ?? 'Save audio to this device';
    final VoidCallback? tap = switch (state) {
      SavedAudioState.none => () => _save(ref),
      SavedAudioState.saving || SavedAudioState.preparing => null,
      SavedAudioState.saved => () => unawaited(_remove(context, ref)),
      SavedAudioState.failed => () => _save(ref),
      SavedAudioState.unplayable => () => unawaited(_resave(ref)),
    };
    return Semantics(
      button: tap != null,
      label: caption,
      excludeSemantics: true,
      onTap: tap,
      child: CinePressable(
        onTap: tap,
        builder: (context, st) => Container(
          key: const Key('audio-save-row'),
          constraints: const BoxConstraints(minHeight: 44),
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy) ...[const CineLeaderDial(size: 16, showAfter: Duration.zero), SizedBox(width: c.space2)],
              if (state == SavedAudioState.saved) ...[CineGlyphIcon(CineGlyph.check, size: 16, color: c.colorInk100), SizedBox(width: c.space2)],
              Flexible(child: CineRoleText(caption, compact ? c.typeFolio : c.typeUi, color: state == SavedAudioState.failed ? c.colorProof : (st.hovered ? c.colorInk100 : c.colorInk80))),
            ],
          ),
        ),
      ),
    );
  }

  /// The old row has to go first: saving onto a complete row keeps the bytes it has, which are the
  /// ones that do not play.
  Future<void> _resave(WidgetRef ref) async {
    await ref.read(downloadQueueControllerProvider.notifier).cancelChapter(audioIdentity(_id));
    _save(ref);
  }
}
