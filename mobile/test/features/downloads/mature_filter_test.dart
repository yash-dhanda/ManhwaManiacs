// ignore_for_file: require_trailing_commas
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/downloads/utils/mature_filter.dart';

void main() {
  bool m({String? r, bool? o, String? c, List<String>? g, bool s = false}) =>
      isMatureLocal(
          resolvedRating: r,
          matureOverride: o,
          contentRating: c,
          genres: g,
          sourceMature: s);

  test('resolved rating wins', () {
    expect(m(r: 'mature'), isTrue);
    expect(m(r: 'safe', s: true, o: true), isFalse);
    expect(m(r: 'unknown', s: true), isFalse);
  });
  test('override next', () {
    expect(m(o: true), isTrue);
    expect(m(o: false, s: true), isFalse);
  });
  test('content rating and genre hint', () {
    expect(m(c: 'erotica'), isTrue);
    expect(m(g: ['Action', 'Smut']), isTrue);
    expect(m(c: ' Adult '), isTrue);
    expect(m(c: 'safe', s: true), isFalse);
  });
  test('source flag is the last resort', () {
    expect(m(s: true), isTrue);
    expect(m(), isFalse);
  });
  test('filterMature', () {
    final rows = [1, 2, 3];
    bool odd(int x) => x.isOdd;
    expect(filterMature(rows, gateOpen: false, isMature: odd), [2]);
    expect(filterMature(rows, gateOpen: true, isMature: odd), [1, 2, 3]);
  });
}
