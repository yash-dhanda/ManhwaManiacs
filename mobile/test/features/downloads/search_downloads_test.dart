import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/models/downloaded_series_group.dart';
import 'package:manhwamaniacs/features/downloads/models/saved_chapter.dart';
import 'package:manhwamaniacs/features/downloads/utils/search_downloads.dart';

SavedChapter ch(int id, {DownloadChapterState s = DownloadChapterState.complete, DownloadKind kind = DownloadKind.manga, bool? mature}) => SavedChapter(
      rowId: id,
      scopeId: 'u1p1',
      sourceId: 'src',
      seriesKey: 's',
      chapterKey: 'c$id',
      chapterNumber: id.toDouble(),
      title: null,
      seriesTitle: null,
      pageCount: 1,
      bytes: 10,
      state: s,
      pinned: false,
      readAt: null,
      createdAt: DateTime(2026),
      retryCount: 0,
      error: null,
      kind: kind,
      mature: mature,
    );

DownloadedSeriesGroup g(String? title, List<SavedChapter> c) => DownloadedSeriesGroup(sourceId: 'src', seriesKey: title ?? 'x', seriesTitle: title, chapters: c);

void main() {
  final groups = [
    g('Café Tower of Rabbits', [ch(1)]),
    g('Tower Defense', [ch(2, mature: true)]),
    g('Queued Tower', [ch(3, s: DownloadChapterState.queued)]),
    g('Tower Audio', [ch(4, kind: DownloadKind.audio)]),
  ];
  test('every word, folded, any order', () {
    expect(searchDownloads(groups, 'rabbits cafe', gateOpen: false).map((x) => x.seriesTitle), ['Café Tower of Rabbits']);
  });
  test('the gate hides a mature series', () {
    expect(searchDownloads(groups, 'defense', gateOpen: false), isEmpty);
    expect(searchDownloads(groups, 'defense', gateOpen: true), hasLength(1));
  });
  test('needs a ready chapter that is not narration', () {
    expect(searchDownloads(groups, 'tower', gateOpen: true).map((x) => x.seriesTitle), ['Café Tower of Rabbits', 'Tower Defense']);
  });
  test('empty query finds nothing', () {
    expect(searchDownloads(groups, '  ', gateOpen: true), isEmpty);
  });
}
