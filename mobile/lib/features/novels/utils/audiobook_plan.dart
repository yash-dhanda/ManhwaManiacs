/// The Audiobook sheet's rules (cinematic 8.16.8): which chapters can be picked in each mode, the
/// quick picks, the status caption under each row, and how a NARRATE send is grouped. Pure, so the
/// wording and the `force` split are testable without a widget.
library;

import 'package:manhwamaniacs/features/novels/models/narration_save_state.dart';

enum AudiobookMode { narrate, save }

class AudiobookChapter {
  const AudiobookChapter({required this.key, required this.label});
  final String key;

  /// `Chapter 12 · The Tower`.
  final String label;
}

/// At most this many chapter keys per `POST /novels/audio/render`.
const int kRenderBatchMax = 200;

class AudiobookPlan {
  const AudiobookPlan({
    required this.chapters,
    required this.rendered,
    required this.narratable,
    required this.saved,
    this.revoice = const [],
    this.fromKey,
  });

  /// In reading order.
  final List<AudiobookChapter> chapters;

  /// Chapters that already have audio on the server.
  final Set<String> rendered;

  /// Chapters whose text is on the server (rendering reads it).
  final Set<String> narratable;

  /// Saved-audio state per chapter on this device.
  final Map<String, NarrationSaveState> saved;

  /// Narrated chapters whose `rendered_at` predates the book's `cast_changed_at`.
  final List<String> revoice;

  /// Where `NEXT 10` starts (the chapter being read); the first chapter when null.
  final String? fromKey;

  NarrationSaveState _saved(String key) => saved[key] ?? NarrationSaveState.none;

  bool isRendered(String key) => rendered.contains(key);

  /// Whether [key] can be ticked in [mode].
  bool selectable(AudiobookMode mode, String key) => switch (mode) {
        // Already-narrated chapters are selectable in NARRATE: they are re-voiced.
        AudiobookMode.narrate => narratable.contains(key) || rendered.contains(key),
        AudiobookMode.save => rendered.contains(key) && offersNarrationSave(_saved(key)),
      };

  /// The uppercase caption under a row, or null for none.
  String? caption(AudiobookMode mode, String key, {required bool selected}) {
    switch (mode) {
      case AudiobookMode.narrate:
        if (rendered.contains(key)) {
          if (selected) return 'ALREADY NARRATED · WILL BE RE-VOICED';
          return _saved(key) == NarrationSaveState.saved ? 'ALREADY NARRATED · SAVED' : 'ALREADY NARRATED';
        }
        if (!narratable.contains(key)) return 'DOWNLOAD THE TEXT FIRST';
        return null;
      case AudiobookMode.save:
        return switch (_saved(key)) {
          NarrationSaveState.saved => 'SAVED',
          NarrationSaveState.unplayable => "SAVED COPY CAN'T PLAY ON THIS PHONE",
          NarrationSaveState.saving => 'SAVING…',
          NarrationSaveState.failed => "COULDN'T BE SAVED",
          NarrationSaveState.none => rendered.contains(key) ? 'NARRATED' : 'NOT NARRATED YET',
        };
    }
  }

  List<String> get _eligibleUnnarrated => [for (final c in chapters) if (narratable.contains(c.key) && !rendered.contains(c.key)) c.key];

  List<String> get _eligibleSaveable => [for (final c in chapters) if (selectable(AudiobookMode.save, c.key)) c.key];

  /// `NEXT 10`: the next ten pickable chapters from [fromKey] on.
  List<String> nextTen(AudiobookMode mode) {
    final eligible = (mode == AudiobookMode.narrate ? _eligibleUnnarrated : _eligibleSaveable).toSet();
    final start = fromKey == null ? 0 : chapters.indexWhere((c) => c.key == fromKey).clamp(0, chapters.length);
    return [for (final c in chapters.skip(start)) if (eligible.contains(c.key)) c.key].take(10).toList();
  }

  /// `ALL UN-NARRATED` (NARRATE) or `ALL NARRATED` (SAVE).
  List<String> all(AudiobookMode mode) => mode == AudiobookMode.narrate ? _eligibleUnnarrated : _eligibleSaveable;

  /// A NARRATE send split by `force`: chapters that already have audio are re-rendered
  /// (`force: true`), the rest are new. Each group is chunked to [kRenderBatchMax].
  ({List<List<String>> force, List<List<String>> fresh}) groups(Iterable<String> selected) {
    final keys = selected.toList();
    return (
      force: _chunks([for (final k in keys) if (rendered.contains(k)) k]),
      fresh: _chunks([for (final k in keys) if (!rendered.contains(k)) k]),
    );
  }

  static List<List<String>> _chunks(List<String> keys) => [
        for (var i = 0; i < keys.length; i += kRenderBatchMax) keys.sublist(i, i + kRenderBatchMax > keys.length ? keys.length : i + kRenderBatchMax),
      ];
}

/// The primary button's words: `Narrate 12 chapters` / `Save audio of 12 chapters`.
String audiobookPrimaryLabel(AudiobookMode mode, int n) {
  final chapters = n == 1 ? 'chapter' : 'chapters';
  return mode == AudiobookMode.narrate ? 'Narrate $n $chapters' : 'Save audio of $n $chapters';
}

/// The estimate under the list.
String audiobookEstimate(AudiobookMode mode) => mode == AudiobookMode.narrate
    ? 'About 9 minutes of rendering per chapter on the narration PC.'
    : 'Saves while the app is open; the text is saved too.';

/// The 503 `narration_unavailable` caption.
const String kNarrationUnavailableCaption = "Narration of new chapters isn't available right now. Chapters that already have audio can still be saved.";
