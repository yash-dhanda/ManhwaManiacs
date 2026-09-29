import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/downloads/utils/next_chapters.dart';

void main() {
  final all = [for (var i = 1; i <= 12; i++) 'c$i'];

  test('five from the chapter being read', () {
    expect(nextUnreadKeys(all, currentKey: 'c3'), ['c3', 'c4', 'c5', 'c6', 'c7']);
  });

  test('a finished chapter is not offered again', () {
    expect(nextUnreadKeys(all, currentKey: 'c3', currentFinished: true), ['c4', 'c5', 'c6', 'c7', 'c8']);
  });

  test('saved chapters are skipped and the tail is short', () {
    expect(nextUnreadKeys(all, currentKey: 'c10', saved: {'c11'}), ['c10', 'c12']);
  });

  test('an unknown current chapter starts at the top', () {
    expect(nextUnreadKeys(all, currentKey: 'zz'), ['c1', 'c2', 'c3', 'c4', 'c5']);
  });
}
