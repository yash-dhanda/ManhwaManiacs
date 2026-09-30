import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/engine/spread.dart';

void main() {
  test('cover stands alone, then pairs', () {
    expect(buildSpreads(6), [[1], [2, 3], [4, 5], [6]]);
    expect(buildSpreads(5), [[1], [2, 3], [4, 5]]);
  });
  test('coverAlone false pairs from 1', () {
    expect(buildSpreads(3, coverAlone: false), [[1, 2], [3]]);
  });
  test('empty and one page', () {
    expect(buildSpreads(0), isEmpty);
    expect(buildSpreads(1), [[1]]);
  });
  test('a wide page is alone and pairing resumes after it', () {
    // pages 1..8, page 4 wide: [1] [2,3] [4] [5,6] [7,8]
    expect(buildSpreads(8, isWide: (p) => p == 4), [[1], [2, 3], [4], [5, 6], [7, 8]]);
    // wide page as the second of a would-be pair leaves the first alone
    expect(buildSpreads(6, isWide: (p) => p == 3), [[1], [2], [3], [4, 5], [6]]);
    // a wide cover is alone anyway
    expect(buildSpreads(4, isWide: (p) => p == 1), [[1], [2, 3], [4]]);
  });
  test('display order mirrors in rtl', () {
    expect(spreadDisplayOrder([2, 3], rtl: true), [3, 2]);
    expect(spreadDisplayOrder([2, 3], rtl: false), [2, 3]);
  });
  test('view lookup and progress page', () {
    final v = buildSpreads(6);
    expect(findViewIndex(v, 3), 1);
    expect(findViewIndex(v, 99), v.length - 1);
    expect(findViewIndex(v, 0), 0);
    expect(viewLeadPage([2, 3]), 2);
    expect(viewProgressPage([6, 7], 6), 6);
    expect(buildSingles(3), [[1], [2], [3]]);
  });
}
