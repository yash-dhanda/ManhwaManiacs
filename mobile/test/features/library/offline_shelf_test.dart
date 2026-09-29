import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/models/downloaded_series_group.dart';
import 'package:manhwamaniacs/features/downloads/models/saved_chapter.dart';
import 'package:manhwamaniacs/features/library/utils/offline_shelf.dart';

import 'shelf_fixtures.dart';

SavedChapter _chapter(String key, {DownloadChapterState state = DownloadChapterState.complete}) => SavedChapter(
      rowId: 1,
      scopeId: 'u1p1',
      sourceId: 'shelf',
      seriesKey: key,
      chapterKey: 'c1',
      chapterNumber: 1,
      title: null,
      seriesTitle: null,
      pageCount: 3,
      bytes: 10,
      state: state,
      pinned: false,
      readAt: null,
      createdAt: DateTime(2026),
      retryCount: 0,
      error: null,
    );

DownloadedSeriesGroup _group(int id, {DownloadChapterState state = DownloadChapterState.complete}) =>
    DownloadedSeriesGroup(sourceId: 'shelf', seriesKey: 'series-$id', seriesTitle: null, chapters: [_chapter('series-$id', state: state)]);

void main() {
  final follows = [shelfSeries(1), shelfSeries(2, rating: 'mature'), shelfSeries(3)];

  test('only followed series with a saved chapter appear', () {
    final rows = offlineShelf(cachedFollows: follows, saved: [_group(1), _group(2)], matureEnabled: true);
    expect([for (final r in rows) r.id], [1, 2]);
  });

  test('a closed gate hides a saved mature series without a trace', () {
    final rows = offlineShelf(cachedFollows: follows, saved: [_group(1), _group(2)], matureEnabled: false);
    expect([for (final r in rows) r.id], [1]);
  });

  test('nothing saved (or only queued chapters) is an empty edition', () {
    expect(offlineShelf(cachedFollows: follows, saved: const [], matureEnabled: true), isEmpty);
    expect(offlineShelf(cachedFollows: follows, saved: [_group(1, state: DownloadChapterState.queued)], matureEnabled: true), isEmpty);
  });
}
