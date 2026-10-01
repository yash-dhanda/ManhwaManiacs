import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/novels/models/novel_cast.dart';
import 'package:manhwamaniacs/features/novels/providers/narration_jobs_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_chapter_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/series_audio_provider.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';

/// Who speaks in this chapter, and in whose voice.
///
/// A separate request from the prose and never awaited in front of it:
/// attribution exists for a fraction of the library, so a reader must not wait
/// on a lookup that usually answers nothing.
///
/// A failure resolves to [NovelAttribution.unavailable] (a [NovelAttribution.none] with `failed`) rather than throwing. The
/// cast panel is an addition to the page — it has to leave exactly the reading
/// experience that shipped before it existed, not an error screen.
final novelAttributionProvider = FutureProvider.autoDispose
    .family<NovelAttribution, NovelChapterKey>((ref, key) async {
      final result = await ref
          .watch(novelsRepositoryProvider)
          .attribution(
            sourceId: key.sourceId,
            seriesKey: key.seriesKey,
            chapterKey: key.chapterKey,
          );
      return result.isErr ? NovelAttribution.unavailable : result.value;
    });

/// Every voice a character can be given.
///
/// Per-server and effectively static — the roster changes when somebody drops
/// a clip on the box, not when a reader does anything — so it is kept alive
/// for the session rather than refetched per chapter.
///
/// An empty list is a real answer, and the one the picker checks: a deployment
/// with no pack installed still reads novels, it just cannot cast anybody, and
/// nothing should offer a choice that is not really there.
final novelVoicesProvider = FutureProvider<List<NovelVoice>>((ref) async {
  final result = await ref.watch(novelsRepositoryProvider).voices();
  return result.isErr ? const <NovelVoice>[] : result.value;
});

/// Pin a voice, for one character or for the series' narration.
///
/// Answers null when it stuck, or the error when it did not, so the sheet can
/// say WHY rather than silently showing a choice the server refused. Casting
/// is an owner's decision — the server answers a non-admin with a 403 whose
/// message says exactly that — and a panel that swallowed it would leave a
/// reader tapping a voice that never changes, with no idea why.
class NovelVoiceWriter {
  const NovelVoiceWriter(this._ref);

  final Ref _ref;

  /// [voiceId] null clears the pin: the character goes back to a voice the
  /// renderer assigns automatically.
  Future<AppError?> setCharacter(
    NovelChapterKey key,
    String name,
    String? voiceId,
  ) async {
    final result = await _ref
        .read(novelsRepositoryProvider)
        .setCastVoice(
          sourceId: key.sourceId,
          seriesKey: key.seriesKey,
          name: name,
          voiceId: voiceId,
        );
    if (result.isErr) return result.error;
    _ref.read(novelCastingWriterProvider)._refresh(key);
    return null;
  }

  Future<AppError?> setNarrator(NovelChapterKey key, String? voiceId) async {
    final result = await _ref
        .read(novelsRepositoryProvider)
        .setNarratorVoice(
          sourceId: key.sourceId,
          seriesKey: key.seriesKey,
          voiceId: voiceId,
        );
    if (result.isErr) return result.error;
    _ref.read(novelCastingWriterProvider)._refresh(key);
    return null;
  }
}

/// The owner's other casting and rendering writes (cinematic 8.16.5, 8.16.8). Each answers null
/// when it stuck or the error, and each refreshes what depends on it: the attribution, the book's
/// audio coverage and the jobs.
class NovelCastingWriter {
  const NovelCastingWriter(this._ref);

  final Ref _ref;

  void _refresh(NovelChapterKey key) {
    final series = (sourceId: key.sourceId, seriesKey: key.seriesKey);
    _ref.invalidate(novelAttributionProvider(key));
    // Only what somebody is watching: invalidating a provider nobody read would build it for nothing.
    void refresh(ProviderBase<Object?> p) {
      if (_ref.exists(p)) _ref.invalidate(p);
    }

    refresh(seriesAudioProvider(series));
    refresh(seriesAudioDetailProvider(series));
    refresh(novelAudioJobsProvider(series));
    refresh(activeAudioJobsProvider);
  }

  /// `male`, `female` or `unknown`.
  Future<AppError?> setGender(NovelChapterKey key, String name, String gender) async {
    final r = await _ref.read(novelsRepositoryProvider).setCastGender(
          sourceId: key.sourceId,
          seriesKey: key.seriesKey,
          name: name,
          gender: gender,
        );
    if (r.isErr) return r.error;
    _refresh(key);
    return null;
  }

  /// [alias] is the same character as [canonical].
  Future<AppError?> mergeAlias(NovelChapterKey key, String alias, String canonical) async {
    final r = await _ref.read(novelsRepositoryProvider).mergeCastAlias(
          sourceId: key.sourceId,
          seriesKey: key.seriesKey,
          alias: alias,
          canonical: canonical,
        );
    if (r.isErr) return r.error;
    _refresh(key);
    return null;
  }

  /// Queues [chapterKeys] for narration. [force] re-renders chapters that already have audio.
  /// Answers the queued and skipped chapters, or the error (503 `narration_unavailable` among
  /// them).
  Future<Result<NovelAudioRequest>> requestRender(
    NovelChapterKey key,
    List<String> chapterKeys, {
    int priority = 0,
    bool force = false,
  }) async {
    final r = await _ref.read(novelsRepositoryProvider).requestAudio(
          sourceId: key.sourceId,
          seriesKey: key.seriesKey,
          chapterKeys: chapterKeys,
          priority: priority,
          force: force,
        );
    if (r.isOk) _refresh(key);
    return r;
  }

  /// Stops a render; it stops shortly (the render box learns on its next heartbeat).
  Future<AppError?> cancelJob(NovelChapterKey key, String jobId) async {
    final r = await _ref.read(novelsRepositoryProvider).cancelAudioJob(jobId);
    if (r.isErr) return r.error;
    _refresh(key);
    return null;
  }
}

final novelCastingWriterProvider = Provider<NovelCastingWriter>(NovelCastingWriter.new);

final novelVoiceWriterProvider = Provider<NovelVoiceWriter>(
  NovelVoiceWriter.new,
);
