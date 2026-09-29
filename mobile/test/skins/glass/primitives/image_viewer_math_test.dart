import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/primitives/image_viewer_math.dart';

void main() {
  test('zooming keeps the focal point fixed', () {
    const focal = Offset(300, 500);
    const t0 = Offset(20, -40);
    const s0 = 1.5;
    const s1 = 3.0;
    final t1 = zoomAround(focal: focal, translation: t0, s0: s0, s1: s1);
    // The image point under the focal point before and after is the same.
    final before = (focal - t0) / s0;
    final after = (focal - t1) / s1;
    expect((before - after).distance, lessThan(1e-9));
  });

  test('the scale rubber-bands at most 0.18 beyond 1x and 4x', () {
    expect(rubberScale(2.5), 2.5);
    expect(rubberScale(4.0), 4.0);
    expect(rubberScale(40), lessThanOrEqualTo(4.18));
    expect(rubberScale(40), greaterThan(4.1));
    expect(rubberScale(0.01), greaterThanOrEqualTo(0.82));
    expect(rubberScale(0.01), lessThan(1));
    expect(scaleAtLimit(4.05), isTrue);
    expect(scaleAtLimit(2), isFalse);
  });

  test('a double tap is a second tap within 280 ms and 24 px', () {
    expect(isDoubleTap(dt: const Duration(milliseconds: 280), distance: 24), isTrue);
    expect(isDoubleTap(dt: const Duration(milliseconds: 281), distance: 10), isFalse);
    expect(isDoubleTap(dt: const Duration(milliseconds: 100), distance: 25), isFalse);
    expect(doubleTapTarget(1), 2.5);
    expect(doubleTapTarget(2.5), 1);
  });

  test('dismissal by a 180 px projection or 800 px/s', () {
    expect(shouldDismissImage(100, 100), isFalse); // 100 + 50 = 150
    expect(shouldDismissImage(100, 200), isTrue); // 100 + 100 = 200
    expect(shouldDismissImage(-60, -799 * 0.1), isFalse);
    expect(shouldDismissImage(5, 800), isTrue);
    expect(shouldDismissImage(-5, -800), isTrue);
    expect(shouldDismissImage(0, 0), isFalse);
  });

  test('the drag visuals: scale, radius and backdrop follow the drag', () {
    expect(dismissScale(0), 1);
    expect(dismissScale(120), closeTo(0.9, 1e-9));
    expect(dismissScale(9999), 0.85);
    expect(dismissRadius(0), 0);
    expect(dismissRadius(180), 28);
    expect(dismissBackdrop(160), closeTo(0.5, 1e-9));
    expect(dismissBackdrop(400), 0);
  });

  test('pan limits cover the viewport and rubber-band past them', () {
    final l = panLimit(image: const Size(400, 800), viewport: const Size(400, 800), scale: 2);
    expect(l, const Offset(200, 400));
    expect(panClamp(150, 200), 150);
    expect(panClamp(5000, 200), lessThanOrEqualTo(240));
    expect(panClamp(5000, 200, rubber: false), 200);
    expect(panLimit(image: const Size(400, 800), viewport: const Size(400, 800), scale: 1), Offset.zero);
  });
}
