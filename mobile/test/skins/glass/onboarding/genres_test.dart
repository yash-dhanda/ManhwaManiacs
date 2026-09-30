import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/copy/genres.dart';

void main() {
  test('24 bodies with and without the gate', () {
    expect(glassGenres(matureOpen: false), hasLength(24));
    expect(glassGenres(matureOpen: true), hasLength(24));
  });

  test('the five mature genres exist only with the gate open, in ranks 20 to 24', () {
    final closed = glassGenres(matureOpen: false);
    for (final m in kMatureGenres) {
      expect(closed, isNot(contains(m)));
    }
    final open = glassGenres(matureOpen: true);
    expect(open.sublist(19), kMatureGenres);
    expect(open, isNot(contains('Murim')));
    expect(open.first, 'Action');
  });

  test('rank radii run from 52 to 36', () {
    expect(genreRadius(1), 52);
    expect(genreRadius(24), closeTo(36, 1e-9));
    expect(genreRadius(12), closeTo(52 - 11 * 16 / 23, 1e-9));
  });
}
