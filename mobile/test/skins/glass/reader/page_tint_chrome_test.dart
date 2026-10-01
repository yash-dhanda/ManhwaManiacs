import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/color/oklch.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/page_tint_chrome.dart';

void main() {
  test('a saturated red clamps to L 0.35-0.50 and C <= 0.12, hue kept', () {
    const red = Color(0xFFFF0000);
    final t = oklchFromColor(clampTint(red));
    expect(t.l, inInclusiveRange(0.349, 0.501));
    expect(t.c, lessThanOrEqualTo(0.1201));
    expect((t.h - oklchFromColor(red).h).abs(), lessThan(2));
    final r = oklchFromColor(rimTint(red));
    expect(r.l, closeTo(0.86, 0.01));
    expect(r.c, lessThanOrEqualTo(0.0801));
  });

  test('a near-grey keeps its tiny chroma and lands inside the lightness band', () {
    final t = oklchFromColor(clampTint(const Color(0xFFF2F1EF)));
    expect(t.l, closeTo(0.50, 0.01));
    expect(t.c, lessThan(0.02));
    expect(oklchFromColor(clampTint(const Color(0xFF050505))).l, closeTo(0.35, 0.01));
  });

  test('the 0.04 Delta E gate', () {
    const a = Color(0xFF3A4A80);
    expect(deltaE(a, a), 0);
    final near = colorFromOklch(Oklch(oklchFromColor(a).l + 0.03, oklchFromColor(a).c, oklchFromColor(a).h));
    final far = colorFromOklch(Oklch(oklchFromColor(a).l + 0.06, oklchFromColor(a).c, oklchFromColor(a).h));
    expect(deltaE(a, near), lessThan(0.04));
    expect(gatedTint(a, near), a, reason: 'under the gate the chrome keeps its tint');
    expect(deltaE(a, far), greaterThan(0.04));
    expect(gatedTint(a, far), far);
    expect(gatedTint(null, a), a);
    expect(gatedTint(a, null), a);
  });
}
