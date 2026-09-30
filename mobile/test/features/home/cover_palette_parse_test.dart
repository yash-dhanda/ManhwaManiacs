import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/color/cover_palette.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';

void main() {
  test('parses a palette and ignores a malformed hex', () {
    final p = CoverPalette.tryParse({'a': ['#112233', 'zz', '#445566', '#778899'], 'l': 0.4, 'lMax': 0.9})!;
    expect(p.a, [const Color(0xFF112233), const Color(0xFF445566), const Color(0xFF778899)]);
    expect((p.l, p.lMax), (0.4, 0.9));
    expect(CoverPalette.tryParse({'a': <String>[], 'l': 'x', 'lMax': 1}), isNull);
    expect(CoverPalette.tryParse(null), isNull);
  });

  test('the home cover and items carry the palette, null when absent', () {
    const pal = {'a': ['#112233'], 'l': 0.5, 'lMax': 0.8};
    final withPal = HomeCover.tryParse({'source_id': 's', 'series_key': 'k', 'palette': pal})!;
    expect(withPal.palette!.lMax, 0.8);
    expect(HomeCover.tryParse({'source_id': 's', 'series_key': 'k'})!.palette, isNull);
    expect(HomeCover.tryParse({'source_id': 's', 'series_key': 'k', 'palette': 7})!.palette, isNull);
    final sec = HomeSection.tryParse({
      'type': 'because',
      'items': [
        {'kind': 'world', 'why': 'w', 'palette': pal, 'item': {'title': 'T', 'anilist_id': 1}},
        {'kind': 'world', 'item': {'title': 'U', 'anilist_id': 2}},
      ],
    })!;
    expect((sec.items[0] as HomePickItem).palette, isNotNull);
    expect((sec.items[1] as HomePickItem).palette, isNull);
  });
}
