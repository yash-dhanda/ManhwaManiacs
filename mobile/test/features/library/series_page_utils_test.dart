// ignore_for_file: require_trailing_commas, avoid_dynamic_calls, prefer_const_declarations, unnecessary_null_checks
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/utils/mark_read.dart';
import 'package:manhwamaniacs/features/library/utils/repoint_mapping.dart';
import 'package:manhwamaniacs/features/library/utils/series_time.dart';
import 'package:manhwamaniacs/features/reader/models/reading_progress.dart';

ReadingProgress _p(int secs) => ReadingProgress(
      id: 1,
      sourceId: 's',
      seriesKey: 'k',
      chapterKey: 'c',
      chapterNumber: 1,
      lastPage: 0,
      pageCount: 1,
      scrollOffsetPx: 0,
      isCompleted: false,
      timeSpentSeconds: secs,
    );

void main() {
  test('mappingSentence in range, out of range and unknown', () {
    expect(
      mappingSentence(currentNumber: 142, candidateRange: (from: 1, to: 150), sourceName: 'Asura'),
      "Your place moves by chapter number. You're on chapter 142; Asura has chapters 1–150, so chapter 142 there becomes your place.",
    );
    const off = "Chapter numbers don't line up, so you'll start at chapter 1 on Asura.";
    expect(
        mappingSentence(
            currentNumber: 200, candidateRange: (from: 1, to: 150), sourceName: 'Asura'),
        off);
    expect(mappingSentence(currentNumber: null, candidateRange: null, sourceName: 'Asura'), off);
  });

  test('timeHere', () {
    expect(timeHere([]), '—');
    expect(timeHere([_p(30)]), '—');
    expect(timeHere([_p(45 * 60)]), '45 M');
    expect(timeHere([_p(11 * 3600), _p(20 * 60)]), '11 H 20 M');
  });

  test('chaptersUpTo and undoMarkReadKeys', () {
    final cs = <ChapterMark>[
      (key: 'a', number: 1, completed: true),
      (key: 'b', number: 2, completed: false),
      (key: 'c', number: null, completed: false),
      (key: 'd', number: 3, completed: false),
      (key: 'e', number: 4, completed: false),
    ];
    expect(chaptersUpTo(cs, 3).map((c) => c.key), ['b', 'd']);
    expect(undoMarkReadKeys({'a'}, ['a', 'b']), ['b']);
    expect(chunksOf200(List.generate(450, (i) => i)).map((c) => c.length), [200, 200, 50]);
  });
}
