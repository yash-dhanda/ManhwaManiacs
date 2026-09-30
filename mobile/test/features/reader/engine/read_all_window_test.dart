import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/engine/read_all_window.dart';
import 'package:manhwamaniacs/features/reader/models/chapter_manifest_window.dart';

void main() {
  final keys = List.generate(50, (i) => 'c${i + 1}');
  test('window is up to 20 unsettled keys in series order', () {
    expect(nextWindow(keys, {}, 0), keys.take(20).toList());
    expect(nextWindow(keys, {'c1', 'c2'}, 0).first, 'c3');
    expect(nextWindow(keys, {'c1', 'c2'}, 0).length, 20);
    expect(nextWindow(keys, {}, 45), ['c46', 'c47', 'c48', 'c49', 'c50']);
    expect(nextWindow(keys, keys.toSet(), 0), isEmpty);
    expect(nextWindow(keys, {}, 99), isEmpty);
  });
  test('a failed item is a failed chapter, not a failed feed', () {
    final answer = ChapterManifestWindow.fromJson({
      'max_chapters': 20,
      'items': [
        {'chapter_key': 'c1', 'status': 'error', 'error': {'message': 'nope'}},
      ],
    });
    final out = mapWindowOutcomes(['c1', 'c2'], answer);
    expect(out, {'c1': ReadAllOutcome.failed, 'c2': ReadAllOutcome.failed});
  });
  test('boundaries, locate and position', () {
    expect(chapterStarts([10, 5, 8]), [0, 10, 15]);
    expect(locateGlobalPage([10, 5, 8], 0), (chapter: 0, page: 1));
    expect(locateGlobalPage([10, 5, 8], 10), (chapter: 1, page: 1));
    expect(locateGlobalPage([10, 5, 8], 22), (chapter: 2, page: 8));
    expect(locateGlobalPage([10, 5, 8], 99), (chapter: 2, page: 8));
    expect(seriesPosition(11, 0), 12);
    expect(readAllFlag('Ch 143', 7), 'CH 143 · p. 7');
  });
  test('ReadAllState equality', () {
    expect(const ReadAllState(index: 12, total: 201, boundaries: [10]), const ReadAllState(index: 12, total: 201, boundaries: [10]));
    expect(const ReadAllState(index: 12, total: 201), isNot(const ReadAllState(index: 13, total: 201)));
  });
}
