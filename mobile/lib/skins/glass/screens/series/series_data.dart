import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/downloads/models/chapter_identity.dart';
import 'package:manhwamaniacs/features/downloads/models/chapter_selection.dart';
import 'package:manhwamaniacs/features/downloads/models/saved_chapter.dart' show DownloadKind;
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/providers/device_online_provider.dart';
import 'package:manhwamaniacs/features/library/utils/mark_read.dart';
import 'package:manhwamaniacs/features/reader/models/reading_progress.dart';
import 'package:manhwamaniacs/features/sources/models/source_chapter_progress.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/features/sources/providers/source_progress_provider.dart';
import 'package:manhwamaniacs/features/sources/utils/resume_order.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';

/// Everything the Glass series page renders (glass 8.12, 8.13): one shape for both routes.
class GlassSeriesData {
  const GlassSeriesData({required this.sourceId, required this.seriesKey, required this.series, required this.chapters, this.followed, this.novel = false, this.offline = false});

  final String sourceId, seriesKey;
  final SourceSeriesSummary series;
  final List<SourceChapterSummary> chapters;
  final FollowedSeries? followed;
  final bool novel;

  /// Rendered from the device (offline with saved chapters).
  final bool offline;

  SeriesIdentity get identity => (sourceId: sourceId, seriesKey: seriesKey);
  SourceSeriesRef get progressKey => (sourceId: sourceId, seriesId: seriesKey);
  String get title => series.title;
  bool get isFollowed => followed != null;

  /// Oldest to newest, unnumbered last (the reading order).
  List<SourceChapterSummary> get readingOrder => readingOrderOf(chapters);
}

/// "142", "12.5", or null.
String? chapterNum(double? n) => n == null ? null : (n % 1 == 0 ? '${n.toInt()}' : '$n');

/// Where Continue goes and what the split button says (glass 8.12 Actions).
typedef SeriesResume = ({String label, String? chapterKey, int? page, double? number, bool caughtUp, bool started});

SeriesResume seriesResume(List<SourceChapterSummary> order, Map<String, SourceChapterProgress> progress, {bool novel = false}) {
  if (order.isEmpty) return (label: 'Start reading', chapterKey: null, page: null, number: null, caughtUp: false, started: false);
  final last = lastTouchedKey(order, progress);
  final i = last == null ? -1 : order.indexWhere((c) => c.id == last);
  String ch(int k) => 'Ch ${chapterNum(order[k].number) ?? '${k + 1}'}';
  final cont = novel ? 'Continue reading' : 'Continue';
  if (i < 0) return (label: 'Start reading', chapterKey: order.first.id, page: null, number: order.first.number, caughtUp: false, started: false);
  final p = progress[last]!;
  if (!p.completed) return (label: '$cont · ${ch(i)}', chapterKey: last, page: p.page, number: order[i].number, caughtUp: false, started: true);
  if (nextUnreadAfter(order, i, progress) case final j?) return (label: '$cont · ${ch(j)}', chapterKey: order[j].id, page: null, number: order[j].number, caughtUp: false, started: true);
  return (label: 'All caught up', chapterKey: null, page: null, number: null, caughtUp: true, started: true);
}

/// The rows the select-mode helpers see.
List<SelectableChapter> selectableChapters(List<SourceChapterSummary> order, Map<String, SourceChapterProgress> progress, Set<String> saved) => [
      for (final c in order) (key: c.id, number: c.number, title: c.title, isRead: progress[c.id]?.completed ?? false, isDownloaded: saved.contains(c.id)),
    ];

/// Requests for [chapters] in the one shape `enqueueChapters` takes.
List<ChapterQueueRequest> seriesQueueRequests(GlassSeriesData d, Iterable<SourceChapterSummary> chapters) => [
      for (final c in chapters)
        (
          id: (sourceId: d.sourceId, seriesKey: d.seriesKey, chapterKey: c.id),
          chapterNumber: c.number,
          title: c.title,
          seriesTitle: d.title,
          kind: d.novel ? DownloadKind.novel : DownloadKind.manga,
        ),
    ];

/// Mark read and Mark unread (glass 8.12; cinematic 8.17, the one contract): `POST /reader/progress/batch` with `manual: true` rows in
/// chunks of 200, `DELETE /reader/progress` with at most 200 keys. Never `POST /reader/progress`.
class SeriesMarks {
  SeriesMarks(this.ref, this.d);
  final WidgetRef ref;
  final GlassSeriesData d;

  void _refresh() => ref.invalidate(sourceSeriesServerProgressProvider(d.progressKey));

  Set<String> completed() => {
        for (final e in ref.read(sourceSeriesProgressProvider(d.progressKey)).entries)
          if (e.value.completed) e.key,
      };

  /// Returns the keys that were marked, or null when the server refused.
  Future<List<String>?> markRead(List<SourceChapterSummary> chapters) async {
    final repo = ref.read(readerRepositoryProvider);
    final rows = manualReadRows([
      for (final c in chapters) (sourceId: d.sourceId, seriesKey: d.seriesKey, chapterKey: c.id, chapterNumber: c.number, pageCount: c.pageCount, completed: false),
    ], at: manualMarkStamp(ref.read(sourceSeriesProgressProvider(d.progressKey))),);
    for (final chunk in chunksOf200(rows)) {
      final r = await repo.saveProgressBatch(chunk);
      if (r.isErr) {
        _refresh();
        return null;
      }
    }
    _refresh();
    return [for (final c in chapters) c.id];
  }

  /// Undo of [markRead]: deletes only the keys that were not completed before.
  Future<void> undoMarkRead(Set<String> before, List<String> marked) async {
    final keys = undoMarkReadKeys(before, marked);
    for (final chunk in chunksOf200(keys)) {
      await ref.read(readerRepositoryProvider).deleteProgress(sourceId: d.sourceId, seriesKey: d.seriesKey, chapterKeys: chunk);
    }
    if (keys.isNotEmpty) _refresh();
  }

  /// Returns what was deleted, for the Undo, or null when the server refused.
  Future<Map<String, SourceChapterProgress>?> markUnread(List<String> keys) async {
    final merged = ref.read(sourceSeriesProgressProvider(d.progressKey));
    final prior = {
      for (final k in keys)
        if (merged[k] != null) k: merged[k]!,
    };
    // Server first: the local position is dropped only once the server row is gone too.
    for (final chunk in chunksOf200(keys)) {
      final r = await ref.read(readerRepositoryProvider).deleteProgress(sourceId: d.sourceId, seriesKey: d.seriesKey, chapterKeys: chunk);
      if (r.isErr) return null;
    }
    await ref.read(sourceProgressProvider.notifier).forget(sourceId: d.sourceId, seriesId: d.seriesKey, chapterIds: keys);
    _refresh();
    return prior;
  }

  /// Undo of [markUnread]: re-posts the deleted rows.
  Future<void> undoMarkUnread(Map<String, SourceChapterProgress> deleted) async {
    final numbers = {for (final c in d.chapters) c.id: c.number};
    final rows = [
      for (final e in deleted.entries)
        ProgressPush(
          sourceId: d.sourceId,
          seriesKey: d.seriesKey,
          chapterKey: e.key,
          chapterNumber: numbers[e.key],
          lastPage: e.value.page,
          pageCount: e.value.pageCount,
          isCompleted: e.value.completed,
          lastReadAt: e.value.updatedAt,
        ),
    ];
    for (final chunk in chunksOf200(rows)) {
      await ref.read(readerRepositoryProvider).saveProgressBatch(chunk);
    }
    await ref.read(sourceProgressProvider.notifier).restoreRecords(sourceId: d.sourceId, seriesId: d.seriesKey, records: deleted);
    _refresh();
  }
}

/// Whether the device is online, read (not watched) for callbacks.
bool onlineNow(WidgetRef ref) => ref.read(deviceOnlineProvider).valueOrNull ?? true;

/// Fire-and-forget helper for callbacks.
void fire(Future<void> f) => unawaited(f.catchError((Object e) => debugPrint('series: $e')));
