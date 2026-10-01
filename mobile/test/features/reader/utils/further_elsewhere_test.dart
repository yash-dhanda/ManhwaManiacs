import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/models/reading_progress.dart';
import 'package:manhwamaniacs/features/reader/utils/further_elsewhere.dart';

ReadingProgress row(String key, double? n, int page) => ReadingProgress(
    id: 0, sourceId: 'src', seriesKey: 's', chapterKey: key, chapterNumber: n, lastPage: page, pageCount: 30, scrollOffsetPx: 0, isCompleted: false, timeSpentSeconds: 0,);

void main() {
  final rows = [row('c3', 3, 30), row('c40', 40, 12)];

  test('re-reading an earlier chapter on the same device offers nothing', () {
    expect(furtherElsewhere(rows, hereKey: 'c3', here: 3, own: (number: 40, page: 12)), isNull);
  });

  test('a row past what this device saved is further elsewhere', () {
    expect(furtherElsewhere(rows, hereKey: 'c3', here: 3, own: (number: 18, page: 4))?.chapterKey, 'c40');
    expect(furtherElsewhere(rows, hereKey: 'c3', here: 3)?.chapterKey, 'c40');
  });

  test('an unknown current chapter number never counts any row as ahead', () {
    expect(furtherElsewhere(rows, hereKey: 'cx', here: null), isNull);
  });
}
