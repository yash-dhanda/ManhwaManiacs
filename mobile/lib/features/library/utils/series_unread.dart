import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/library/utils/mark_read.dart';
import 'package:manhwamaniacs/features/reader/models/reading_progress.dart';
import 'package:manhwamaniacs/features/sources/providers/source_progress_provider.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';

/// The library's bulk Mark unread for one series (both skins): deletes the server rows for [keys], then this
/// phone's own records, which `mergeSourceProgress` would otherwise OR straight back in. Returns its Undo, which
/// re-posts the rows with their own read times (not "now") and restores the phone's records.
Future<Result<Future<void> Function()>> markSeriesUnread(
  ProviderContainer c, {
  required String sourceId,
  required String seriesKey,
  required List<String> keys,
}) async {
  final reader = c.read(readerRepositoryProvider);
  final stored = await reader.seriesProgress(sourceId: sourceId, seriesKey: seriesKey);
  if (stored.isErr) return Err(stored.error);
  final want = keys.toSet();
  final restore = [
    for (final p in stored.value)
      if (want.contains(p.chapterKey))
        ProgressPush(
          sourceId: sourceId,
          seriesKey: seriesKey,
          chapterKey: p.chapterKey,
          chapterNumber: p.chapterNumber,
          lastPage: p.lastPage,
          pageCount: p.pageCount,
          isCompleted: p.isCompleted,
          lastReadAt: p.lastReadAt,
          manual: true,
        ),
  ];
  for (final chunk in chunksOf200(keys)) {
    final r = await reader.deleteProgress(sourceId: sourceId, seriesKey: seriesKey, chapterKeys: chunk);
    if (r.isErr) return Err(r.error);
  }
  final local = await c.read(sourceProgressProvider.notifier).forget(sourceId: sourceId, seriesId: seriesKey, chapterIds: keys);
  return Ok(() async {
    for (final chunk in chunksOf200(restore)) {
      await reader.saveProgressBatch(chunk);
    }
    await c.read(sourceProgressProvider.notifier).restoreRecords(sourceId: sourceId, seriesId: seriesKey, records: local);
  });
}
