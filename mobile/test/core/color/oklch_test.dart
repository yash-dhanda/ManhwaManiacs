import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/color/oklch.dart';

void main() {
  test('sRGB to OKLCH and back round-trips', () {
    for (final c in const [Color(0xFF8F7EFF), Color(0xFFFF7AA8), Color(0xFF4336A3), Color(0xFF9FD98A), Color(0xFF808080)]) {
      final back = colorFromOklch(oklchFromColor(c));
      expect((back.r - c.r).abs() * 255, lessThan(1.01));
      expect((back.g - c.g).abs() * 255, lessThan(1.01));
      expect((back.b - c.b).abs() * 255, lessThan(1.01));
    }
  });

  test('known anchors', () {
    expect(oklchFromColor(const Color(0xFFFFFFFF)).l, closeTo(1.0, 1e-3));
    expect(oklchFromColor(const Color(0xFF000000)).l, closeTo(0.0, 1e-3));
    expect(oklchFromColor(const Color(0xFF808080)).c, lessThan(1e-3));
    expect(relativeLuminance(const Color(0xFFFFFFFF)), closeTo(1, 1e-6));
    expect(relativeLuminance(const Color(0xFF000000)), 0);
  });

  test('an out-of-gamut request keeps lightness and hue and drops chroma', () {
    final c = colorFromOklch(const Oklch(0.7, 0.4, 145));
    final o = oklchFromColor(c);
    expect(o.l, closeTo(0.7, 0.02));
    expect(o.c, lessThan(0.4));
  });

  test('mixOklab endpoints', () {
    const a = Color(0xFFFF0000), b = Color(0xFF0000FF);
    expect(mixOklab(a, b, 0).toARGB32(), a.toARGB32());
    expect(mixOklab(a, b, 1).toARGB32(), b.toARGB32());
  });
}
