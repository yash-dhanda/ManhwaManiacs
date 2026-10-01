import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/color/oklch.dart';
import 'package:manhwamaniacs/skins/glass/ambient/page_tint.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';

void main() {
  test('clampTint of pure red sits at L 0.35-0.50 and C <= 0.12, hue kept', () {
    final red = oklchFromColor(const Color(0xFFFF0000));
    final o = oklchFromColor(clampTint(const Color(0xFFFF0000)));
    expect(o.l, inInclusiveRange(0.349, 0.501));
    expect(o.c, lessThanOrEqualTo(0.1205));
    expect((o.h - red.h).abs(), lessThan(8));
  });

  test('rimTint is L 0.86 and C <= 0.08', () {
    final o = oklchFromColor(rimTint(const Color(0xFF3366FF)));
    expect(o.l, closeTo(0.86, 0.005));
    expect(o.c, lessThanOrEqualTo(0.0805));
  });

  test('deltaE of identical colours is 0 and of near neighbours is under 0.04', () {
    expect(deltaE(const Color(0xFF123456), const Color(0xFF123456)), 0);
    expect(deltaE(const Color(0xFF123456), const Color(0xFF123457)), lessThan(0.04));
    expect(deltaE(const Color(0xFF123456), const Color(0xFFFF8800)), greaterThan(0.04));
  });

  test('shouldApply: false at 3500 px/s, true at 1000 px/s when the change is large, false for a small change', () {
    const a = Color(0xFF123456), b = Color(0xFFAA5522);
    expect(shouldApply(a, b, 3500), isFalse);
    expect(shouldApply(a, b, -3500), isFalse);
    expect(shouldApply(a, b, 1000), isTrue);
    expect(shouldApply(a, const Color(0xFF123457), 0), isFalse);
    expect(shouldApply(null, b, 0), isTrue);
  });

  test('five greyscale samples keep the previous tint and the sixth returns the cover a[0] clamped', () {
    const cover = Color(0xFF22AA66);
    final f = TintFollower()..cover = cover;
    final first = f.feed(const Color(0xFFCC3322), 0);
    expect(first, clampTint(const Color(0xFFCC3322)));
    for (var i = 0; i < 5; i++) {
      expect(f.feed(null, 0), first);
    }
    expect(f.feed(null, 0), clampTint(cover));
  });

  test('a fling holds the tint until it settles', () {
    final f = TintFollower();
    final calm = f.feed(const Color(0xFF3366CC), 0);
    expect(f.feed(const Color(0xFFCC6633), 4000), calm);
    expect(f.feed(const Color(0xFFCC6633), 100), isNot(calm));
  });

  test('dimFor: 0.64 over white and 0.22 over black; Increase Contrast lifts the floor to 0.40', () {
    expect(dimFor(1.0), closeTo(0.64, 1e-9));
    expect(dimFor(0), closeTo(0.22, 1e-9));
    // The Increase Contrast clamp is [0.40, 0.72] around the same formula: the floor lifts, the formula never reaches the ceiling.
    expect(dimFor(1.0, highContrast: true), closeTo(0.64, 1e-9));
    expect(dimFor(0, highContrast: true), closeTo(0.40, 1e-9));
    expect(dimFor(0.1), closeTo(0.262, 1e-9));
    expect(gradFor(1.0), 40);
    expect(gradFor(0.1), 4);
  });

  test('the novel tint for Void ink #D9D6D0 is the ink at 12 %', () {
    final t = novelTint(const Color(0xFFD9D6D0));
    expect(t.a, closeTo(0.12, 0.005));
    expect(t.toARGB32() & 0xFFFFFF, 0xD9D6D0);
  });
}
