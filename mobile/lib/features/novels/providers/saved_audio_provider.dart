import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/downloads/providers/series_download_status_provider.dart';
import 'package:manhwamaniacs/features/novels/controllers/narration_controller.dart';
import 'package:manhwamaniacs/features/novels/models/narration_save_state.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_audio_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_chapter_provider.dart';

/// Where a chapter's audio stands on this device (cinematic 8.16.9). [preparing] is a save whose
/// first request drew `503 audio_preparing`: the server is converting the chapter for this
/// phone, and the queue is waiting for its `Retry-After`.
enum SavedAudioState { none, preparing, saving, saved, failed, unplayable }

/// How many times a `503 audio_preparing` is retried before it counts as a failure.
const int kNarrationPrepareRetries = 40;

/// The chapter ids ("source:series:chapter") whose save is waiting on `503 audio_preparing`. The
/// download queue writes it; the mini player and the Audiobook sheet read it through
/// [savedAudioStateProvider].
final narrationPreparingProvider = StateProvider<Set<String>>((ref) => const {}, name: 'narrationPreparing');

String preparingId(String sourceId, String seriesKey, String chapterKey) => '$sourceId\u0000$seriesKey\u0000$chapterKey';

/// The wait before retrying a `503 audio_preparing` (the server's `Retry-After`, 1-30 s, 3 s
/// without one). A seam so tests do not wait.
final narrationPrepareDelayProvider = Provider<Duration Function(Duration? retryAfter)>(
  (ref) => (retryAfter) {
    final d = retryAfter ?? const Duration(seconds: 3);
    if (d < const Duration(seconds: 1)) return const Duration(seconds: 1);
    if (d > const Duration(seconds: 30)) return const Duration(seconds: 30);
    return d;
  },
  name: 'narrationPrepareDelay',
);

/// One chapter's saved audio, as a single answer: `none | preparing | saving | saved | failed |
/// unplayable`. `none` also when there is no downloads scope (the controls are then not built).
/// Exported for mobile/17's Downloads rows.
final savedAudioStateProvider = Provider.autoDispose.family<SavedAudioState, NovelChapterKey>((ref, key) {
  if (ref.watch(downloadsStoreProvider) == null) return SavedAudioState.none;
  final series = (sourceId: key.sourceId, seriesKey: key.seriesKey);
  final status = ref.watch(seriesNarrationStatusProvider(series)).valueOrNull?[key.chapterKey];
  final unplayable = ref.watch(unplayableNarrationSavesProvider(series)).valueOrNull?.contains(key.chapterKey) ?? false;
  final state = narrationSaveState(status, unplayable: unplayable);
  final preparing = ref.watch(narrationPreparingProvider).contains(preparingId(key.sourceId, key.seriesKey, key.chapterKey));
  return switch (state) {
    NarrationSaveState.none => SavedAudioState.none,
    NarrationSaveState.saving => preparing ? SavedAudioState.preparing : SavedAudioState.saving,
    NarrationSaveState.saved => SavedAudioState.saved,
    NarrationSaveState.failed => SavedAudioState.failed,
    NarrationSaveState.unplayable => SavedAudioState.unplayable,
  };
}, name: 'savedAudioState',);

/// Reads a chapter's saved audio aloud (mobile/17's Downloads row). Loads the saved narration and
/// the chapter text, starts the shared [NarrationController] at the chapter's start, and returns
/// whether anything played (false when nothing usable is saved).
Future<bool> playSavedAudio(WidgetRef ref, NovelChapterKey chapter, {String bookTitle = '', String? coverUrl}) async {
  final saved = await ref.read(savedNarrationProvider(chapter).future);
  if (saved == null || !saved.playable) return false;
  final text = await ref.read(resolvedNovelChapterProvider(chapter).future);
  await ref.read(narrationControllerProvider.notifier).start(
        NarrationTarget(
          key: chapter,
          audio: saved.audio,
          file: saved.file.path,
          paragraphs: text.paragraphs,
          bookTitle: bookTitle.isEmpty ? text.title : bookTitle,
          chapterNumber: text.chapterNumber,
          chapterTitle: text.title,
          coverUrl: coverUrl,
        ),
      );
  return true;
}
