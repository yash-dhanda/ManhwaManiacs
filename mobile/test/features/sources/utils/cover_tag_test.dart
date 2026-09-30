import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/sources/utils/cover_tag.dart';

void main() {
  test('is stable, 8 hex and separates source from series', () {
    final t = coverTag('mangadex', 'solo-leveling');
    expect(t, matches(RegExp(r'^cover-[0-9a-f]{8}$')));
    expect(coverTag('mangadex', 'solo-leveling'), t);
    expect(coverTag('mangadex', 'solo-levelin'), isNot(t));
    expect(coverTag('ab', 'c'), isNot(coverTag('a', 'bc')));
  });

  test('matches the FNV-1a 32 of the empty-ish input', () {
    // FNV-1a 32 of "\u0000" is 0x050c5d1f.
    expect(coverTag('', ''), 'cover-050c5d1f');
  });
}
