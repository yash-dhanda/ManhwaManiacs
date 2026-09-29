import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/downloads/models/chapter_identity.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';

/// The series as the local store knows it: the saved chapters only, so the
/// page can render under the `OFFLINE EDITION` badge with the network gone.
/// Null when nothing of the series is saved.
final offlineEditionProvider = FutureProvider.autoDispose
    .family<({SourceSeriesSummary series, List<SourceChapterSummary> chapters})?, SeriesIdentity>(
        (ref, k) async {
  final store = ref.watch(downloadsStoreProvider);
  if (store == null) return null;
  final saved = [
    for (final c in await store.listChapters())
      if (c.sourceId == k.sourceId &&
          c.seriesKey == k.seriesKey &&
          c.state == DownloadChapterState.complete)
        c,
  ];
  if (saved.isEmpty) return null;
  return (
    series: SourceSeriesSummary(
      id: k.seriesKey,
      sourceId: k.sourceId,
      title: saved.first.seriesTitle ?? k.seriesKey,
      chapterCount: saved.length,
      genres: const [],
      coverUrl: '',
    ),
    chapters: [
      for (final c in saved)
        SourceChapterSummary(
          id: c.chapterKey,
          sourceId: k.sourceId,
          seriesId: k.seriesKey,
          title: c.title ?? 'Chapter ${c.chapterNumber ?? ''}',
          number: c.chapterNumber,
          pageCount: c.pageCount,
        ),
    ],
  );
});
