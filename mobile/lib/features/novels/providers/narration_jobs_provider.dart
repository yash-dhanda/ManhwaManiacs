import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/novels/models/novel_cast.dart';
import 'package:manhwamaniacs/features/novels/providers/series_audio_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';

/// One book's narration in flight, for `NarratingIndicator`, Index and Downloads.
///
/// `GET /novels/audio/jobs/active` names jobs by chapter, not by book, so the book is the one this
/// device last queued (kept in [narratingBookProvider]); a render queued from another device
/// reads as a job with no book, which the indicator shows and Index leaves untappable.
class NarrationJob {
  const NarrationJob({
    required this.sourceId,
    required this.seriesKey,
    required this.title,
    required this.done,
    required this.total,
    double? average,
  }) : _average = average;

  final String sourceId;
  final String seriesKey;
  final String title;

  /// Chapters finished and chapters asked for, in the jobs still active.
  final int done;
  final int total;
  final double? _average;

  bool get hasBook => sourceId.isNotEmpty && seriesKey.isNotEmpty;

  double get progress => _average ?? (total <= 0 ? 0 : (done / total).clamp(0.0, 1.0));
}

/// `mm.narrating-book`: the book the owner last queued a render for on this device.
typedef NarratingBook = ({String sourceId, String seriesKey, String title});

const String kNarratingBookKey = 'mm.narrating-book';

final narratingBookProvider = StateProvider<NarratingBook?>((ref) {
  final raw = ref.watch(sharedPrefsProvider).getStringList(kNarratingBookKey);
  return raw != null && raw.length == 3 ? (sourceId: raw[0], seriesKey: raw[1], title: raw[2]) : null;
}, name: 'narratingBook',);

Future<void> rememberNarratingBook(WidgetRef ref, NarratingBook book) async {
  ref.read(narratingBookProvider.notifier).state = book;
  await ref.read(sharedPrefsProvider).setStringList(kNarratingBookKey, [book.sourceId, book.seriesKey, book.title]);
}

/// True while an Audiobook sheet is open, which keeps the active-jobs poll alive on an idle server.
final audiobookSheetOpenProvider = StateProvider<bool>((ref) => false, name: 'audiobookSheetOpen');

/// How long to wait before the next poll of `jobs/active` (the cadence, pure so it is testable):
/// every base interval (5 s) while a job renders; three times that (15 s) while every job only
/// waits for the render PC; doubling back-off after failures up to 60 s.
Duration nextJobsPoll({required Duration base, required List<NovelAudioJob> jobs, required int failures}) {
  if (failures > 0) {
    final factor = 1 << (failures > 4 ? 4 : failures);
    final wait = base * factor;
    const cap = Duration(seconds: 60);
    return wait > cap ? cap : wait;
  }
  if (jobs.isNotEmpty && jobs.every((j) => j.isWaiting)) return base * 3;
  return base;
}

/// Every render still queued or running, polled. Stops when a SUCCESSFUL answer says nothing is
/// active and no Audiobook sheet is open; a failed poll keeps the last answer and backs off while
/// jobs were in flight, and ends the poll when none were.
/// Restarted by [audiobookSheetOpenProvider] opening, or by a new render being queued (which
/// invalidates this provider).
final activeAudioJobsProvider = StreamProvider<List<NovelAudioJob>>((ref) async* {
  final repository = ref.watch(novelsRepositoryProvider);
  final base = ref.watch(novelAudioJobsPollIntervalProvider);
  var disposed = false;
  ref.onDispose(() => disposed = true);
  ref.listen<bool>(audiobookSheetOpenProvider, (was, open) {
    if (open && was != true) ref.invalidateSelf();
  });

  List<NovelAudioJob>? jobs;
  var failures = 0;
  while (!disposed) {
    final result = await repository.activeAudioJobs();
    if (disposed) return;
    if (result.isOk) {
      failures = 0;
      jobs = result.value;
      yield jobs;
      if (!jobs.any((j) => j.isActive) && !ref.read(audiobookSheetOpenProvider)) return;
    } else {
      failures++;
      final watching = jobs?.any((j) => j.isActive) ?? false;
      if (jobs == null) {
        jobs = const <NovelAudioJob>[];
        yield jobs;
      }
      // Nothing was in flight the last time we heard, so there is nothing to keep watching for:
      // a failed first look ends the poll instead of retrying an idle server forever. Opening the
      // Audiobook sheet (or queueing a render) starts it again.
      if (!watching && !ref.read(audiobookSheetOpenProvider)) return;
    }
    await Future<void>.delayed(nextJobsPoll(base: base, jobs: jobs, failures: failures));
  }
}, name: 'activeAudioJobs',);

/// The narrations in flight as the Downloads and Index blocks read them: one entry while any job
/// is active, none otherwise.
final activeNarrationJobsProvider = Provider<List<NarrationJob>>((ref) {
  final jobs = (ref.watch(activeAudioJobsProvider).valueOrNull ?? const <NovelAudioJob>[]).where((j) => j.isActive).toList();
  if (jobs.isEmpty) return const [];
  final book = ref.watch(narratingBookProvider);
  final average = jobs.fold<double>(0, (a, j) => a + (j.isRunning ? j.progress : 0)) / jobs.length;
  return [
    NarrationJob(
      sourceId: book?.sourceId ?? '',
      seriesKey: book?.seriesKey ?? '',
      title: book?.title ?? 'Audiobook',
      done: 0,
      total: jobs.length,
      average: average,
    ),
  ];
}, name: 'activeNarrationJobs',);
