import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/models/reader_chapter.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/glass_manga_reader.dart';

ReaderChapter ch(String id, {String? prev, String? next}) =>
    ReaderChapter(id: id, seriesId: 's', title: id, pageCount: 0, pages: const [], previousChapterId: prev, nextChapterId: next);

void main() {
  // Chapter 10 opened at page 1: the feed already prepended 9 and appended 11.
  final feed = [ch('9', prev: '8', next: '10'), ch('10', prev: '9', next: '11'), ch('11', prev: '10', next: '12')];

  test('previous and next step from the chapter being read, not the feed edges', () {
    expect(feedNeighbour(feed, '10', -1), '9');
    expect(feedNeighbour(feed, '10', 1), '11');
  });

  test('past the loaded feed it falls back to the manifest neighbour', () {
    expect(feedNeighbour(feed, '11', 1), '12');
    expect(feedNeighbour(feed, '9', -1), '8');
    expect(feedNeighbour(feed, 'x', 1), isNull);
  });
}
