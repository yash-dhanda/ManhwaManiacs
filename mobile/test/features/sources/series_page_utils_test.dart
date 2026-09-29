import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/novels/utils/novel_book.dart';
import 'package:manhwamaniacs/features/sources/utils/chapter_sort_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('chapter sort default and round trip, per profile', () async {
    SharedPreferences.setMockInitialValues({});
    final p = await SharedPreferences.getInstance();
    String get(String? prof, bool novel) =>
        chapterSortFor(p, profileId: prof, sourceId: 's', seriesKey: 'k', novel: novel);
    expect(get('1', false), 'newest');
    expect(get('1', true), 'oldest');
    await saveChapterSort(p, profileId: '1', sourceId: 's', seriesKey: 'k', order: 'oldest');
    expect(get('1', false), 'oldest');
    expect(get('2', false), 'newest');
  });

  test('toc window', () {
    expect(tocWindowAround(100, 50), (start: 0, end: 100));
    expect(tocWindowAround(3000, 1500), (start: 1300, end: 1700));
    expect(tocWindowAround(3000, 5), (start: 0, end: 400));
    expect(tocWindowAround(3000, 2999), (start: 2600, end: 3000));
    final w = tocWindowAround(3000, 1500);
    expect(extendTocWindow(w, 3000, earlier: true), (start: 900, end: 1700));
    expect(extendTocWindow(w, 3000, earlier: false), (start: 1300, end: 2100));
    expect(extendTocWindow((start: 100, end: 500), 3000, earlier: true), (start: 0, end: 500));
  });
}
