import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/color/oklch.dart';
import 'package:manhwamaniacs/skins/glass/glass/lb.dart';
import 'package:manhwamaniacs/skins/glass/glass/palette.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';

int argb(int rgb) => 0xFF000000 | rgb;

void main() {
  test('rank rule: discards near-black, near-white and near-grey, ranks by population x (0.5 + C)', () {
    final ranked = rankPalette({
      argb(0x050505): 5000, // L < 0.12
      argb(0xFAFAFA): 4000, // L > 0.94
      argb(0x808080): 3000, // C < 0.025
      argb(0xE04040): 600, // red, the most populous survivor
      argb(0x3050E0): 500,
      argb(0x40C060): 300,
      argb(0xE0C040): 100,
    });
    expect(ranked.length, 3);
    expect(ranked.first.toARGB32(), argb(0xE04040));
    expect(ranked.map((c) => c.toARGB32()), isNot(contains(argb(0x050505))));
    expect(ranked.map((c) => c.toARGB32()), isNot(contains(argb(0x808080))));
    // 500 x (0.5 + C) overtakes 600 x (0.5 + C) when its chroma is far higher.
    final byChroma = rankPalette({argb(0x907070): 700, argb(0x0040FF): 500});
    expect(byChroma.first.toARGB32(), argb(0x0040FF));
  });

  test('when every colour would be discarded, the two most populous are kept', () {
    final ranked = rankPalette({argb(0x000000): 900, argb(0xFFFFFF): 500, argb(0x808080): 100});
    expect(ranked.length, 2);
    expect(ranked.map((c) => c.toARGB32()).toSet(), {argb(0x000000), argb(0xFFFFFF)});
  });

  test('a synthetic 64 px image: dark cover with a white patch gives lMax about 1.0 and a mean near dark', () async {
    final px = Uint32List(64 * 64);
    for (var i = 0; i < px.length; i++) {
      px[i] = argb(0x15151C);
    }
    // A 10 % white patch (over the 95th percentile line) and a red block.
    for (var i = 0; i < 410; i++) {
      px[i] = argb(0xFFFFFF);
    }
    for (var i = 2000; i < 2800; i++) {
      px[i] = argb(0xD03030);
    }
    final p = await paletteFromPixels(px);
    expect(p.lMax, closeTo(1.0, 1e-6));
    expect(p.l, lessThan(0.25));
    expect(p.a, isNotEmpty);
    expect(oklchFromColor(p.a.first).c, greaterThan(0.1), reason: 'the red block ranks first');
    // Read through the cover Lb source, the dim is the full 0.64 despite the dark mean.
    expect(dimFor(Lb.cover(p.lMax)), closeTo(0.64, 1e-9));
  });

  test('a colourless image never turns into Google blue (no Score.score)', () async {
    final px = Uint32List(64 * 64)..fillRange(0, 64 * 64, argb(0x808080));
    final p = await paletteFromPixels(px);
    for (final c in p.a) {
      expect(c.toARGB32(), isNot(0xFF4285F4));
    }
  });

  test('fieldColours clamps in OKLCH (L 0.55 to 0.78, C 0.06 to 0.16), hue kept', () {
    const hot = Color(0xFFFF0000);
    const dark = Color(0xFF1A0A50);
    const soft = Color(0xFFB7A8C9);
    final f = fieldColours(const CoverPalette(a: [hot, dark, soft], l: 0.3, lMax: 0.6), const Color(0xFF4336A3));
    for (var i = 0; i < 3; i++) {
      final o = oklchFromColor(f.colors[i]);
      expect(o.l, inInclusiveRange(0.55 - 0.02, 0.78 + 0.02), reason: 'colour $i $o');
      expect(o.c, inInclusiveRange(0.06 - 0.01, 0.16 + 0.01), reason: 'colour $i $o');
    }
    final hueIn = oklchFromColor(hot).h, hueOut = oklchFromColor(f.colors[0]).h;
    expect((hueIn - hueOut).abs(), lessThan(3));
    expect(f.scales, [1.0, 1.0, 1.0]);
  });

  test('a near-grey is replaced by the mood colour, and fewer than three colours reuse the first at 60 %', () {
    const mood = Color(0xFFFF7AA8);
    final f = fieldColours(const CoverPalette(a: [Color(0xFF808080), Color(0xFF2050E0)], l: 0.3, lMax: 0.6), mood);
    expect(f.colors[0], mood);
    expect(f.colors[1], isNot(mood));
    expect(f.colors[2], f.colors[0]);
    expect(f.scales, [1.0, 1.0, 0.6]);
    final none = fieldColours(null, mood);
    expect(none.colors, [mood, mood, mood]);
  });

  test('rimTint is the first colour at OKLCH L 0.86 with C at most 0.08', () {
    final t = rimTint(const CoverPalette(a: [Color(0xFFD03030)], l: 0.2, lMax: 0.5));
    final o = oklchFromColor(t);
    expect(o.l, closeTo(0.86, 0.02));
    expect(o.c, lessThanOrEqualTo(0.081));
  });

  test('the server palette wins and is used as is; decoded palettes are cached per URL', () async {
    final p = await coverPalette(
      cacheKey: 'x',
      server: {
        'a': ['#112233', '#445566', '#778899'],
        'l': 0.41,
        'lMax': 0.88,
      },
    );
    expect(p.a.first.toARGB32(), 0xFF112233);
    expect(p.l, 0.41);
    expect(p.lMax, 0.88);
  });

  test('Lb sources', () {
    expect(Lb.unknown, 1.0);
    expect(Lb.field(0.5, 0.26), closeTo(0.5 * 0.26 + 0.02, 1e-9));
    expect(Lb.page(_sample(0.2, 0.9, 0.4)), 0.9);
    expect(Lb.page(_sample(0.2, 0.9, 0.4), bands: {PageBand.top, PageBand.bottom}), 0.4);
    expect(Lb.bar(0.3, 0.8), 0.8);
    expect(Lb.bar(0.9, 0.2), 0.9);
    expect(Lb.paper(0.55), 0.55);
  });
}

PageSample _sample(double t, double m, double b) => PageSample(
      tint: null,
      top: const Color(0xFF000000),
      bottom: const Color(0xFF000000),
      lTop: t,
      lMid: m,
      lBottom: b,
      pTop: t,
      pMid: m,
      pBottom: b,
      source: PageSampleSource.decode,
    );
