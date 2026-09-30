import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_series.dart';

SourceChapterSummary _c(String id, double? n) =>
    SourceChapterSummary(id: id, sourceId: 's', seriesId: 'k', title: 'T$id', number: n, pageCount: 10);

void main() {
  final series = ReaderSeries(
    title: 'Solo',
    status: 'Completed',
    chapters: readingOrder([_c('c', null), _c('b', 2), _c('a', 1), _c('d', 2.5)]),
    summary: const SourceSeriesSummary(id: 'k', sourceId: 's', title: 'Solo', chapterCount: 4, genres: [], coverUrl: ''),
  );

  test('reading order is numbered ascending, unnumbered last', () {
    expect([for (final c in series.chapters) c.id], ['a', 'b', 'd', 'c']);
  });

  test('neighbours and lookups', () {
    expect(series.previousOf('a'), isNull);
    expect(series.nextOf('a')?.id, 'b');
    expect(series.previousOf('d')?.id, 'b');
    expect(series.nextOf('c'), isNull);
    expect(series.chapterTitled('Tb')?.id, 'b');
    expect(series.completed, isTrue);
  });

  test('folios', () {
    expect(chapterFolio(142), 'CH 142');
    expect(chapterFolio(142.5), 'CH 142.5');
    expect(chapterFolio(null), 'CH ·');
  });
}
