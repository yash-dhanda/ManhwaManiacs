import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/novels/models/glass_novel_prefs.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/papers.dart';

void main() {
  // glass 8.15.1, the contract table.
  const table = {
    GlassPaper.voidPaper: (0xFF000000, 0xFFD9D6D0, 0xFF8A877F),
    GlassPaper.ink: (0xFF0B0B0C, 0xFFE6E3DD, 0xFF8F8C86),
    GlassPaper.nightPaper: (0xFF15110C, 0xFFE8D8BE, 0xFF9C8E78),
    GlassPaper.dusk: (0xFF0D1117, 0xFFD3DAE3, 0xFF8590A0),
    GlassPaper.moss: (0xFF0E130F, 0xFFD5DECF, 0xFF879384),
    GlassPaper.rosewood: (0xFF160E10, 0xFFEBD5D8, 0xFFA08A8E),
    GlassPaper.glass: (0xFF000000, 0xFFECECF1, 0xFF8F8F99),
  };

  for (final e in table.entries) {
    test('${e.key.label}: generated tokens equal the table and clear 13:1 / 5.8:1', () {
      final c = paperColors(e.key);
      expect(c.bg, Color(e.value.$1));
      expect(c.ink, Color(e.value.$2));
      expect(c.muted, Color(e.value.$3));
      expect(contrastRatio(c.ink, c.bg), greaterThanOrEqualTo(13));
      expect(contrastRatio(c.muted, c.bg), greaterThanOrEqualTo(5.8));
    });
  }

  test('the lowest figures are the contract figures', () {
    final ink = [for (final p in GlassPaper.values) contrastRatio(paperColors(p).ink, paperColors(p).bg)]..sort();
    final muted = [for (final p in GlassPaper.values) contrastRatio(paperColors(p).muted, paperColors(p).bg)]..sort();
    expect(ink.first, closeTo(13.42, 0.02));
    expect(muted.first, closeTo(5.84, 0.02));
  });

  test('oklabMix against hand-computed values', () {
    // L 0.5 between black and white: linear 0.125, sRGB 0.3886 (99).
    final half = oklabMix(const Color(0xFF000000), const Color(0xFFFFFFFF), 0.5);
    expect(half.r * 255, closeTo(99.1, 1));
    expect(half.g, closeTo(half.r, 1e-6));
    // L 0.25: linear 0.015625, sRGB 0.1315 (34).
    final quarter = oklabMix(const Color(0xFF000000), const Color(0xFFFFFFFF), 0.25);
    expect(quarter.b * 255, closeTo(33.5, 1));
    expect(oklabMix(const Color(0xFF15110C), const Color(0xFF131317), 0).toARGB32(), 0xFF15110C);
  });

  test('Lb: a paper reads its own luminance; the Glass paper l x 0.10 + 0.02', () {
    expect(paperLb(GlassPaper.voidPaper), 0);
    expect(paperLb(GlassPaper.glass, fieldL: 0.5), closeTo(0.07, 1e-9));
    expect(paperLb(GlassPaper.nightPaper), lessThan(0.01));
  });
}
