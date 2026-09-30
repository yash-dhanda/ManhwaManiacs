import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/engine/zoom_math.dart';

void main() {
  test('the focal point stays fixed within 0.5 px for 1 -> 2 and 2 -> 0.5', () {
    for (final (offset, focal, from, to) in [(300.0, 200.0, 1.0, 2.0), (900.0, 350.0, 2.0, 0.5), (0.0, 400.0, 1.0, 3.0)]) {
      final next = focalOffset(offset, focal, from, to);
      // The content y under the finger, in unscaled content units, before and after.
      expect(((next + focal) / to - (offset + focal) / from).abs(), lessThan(0.5 / to));
    }
  });

  test('horizontal twin matches the vertical formula', () {
    expect(focalOffsetX(10, 195, 1, 2), focalOffset(10, 195, 1, 2));
  });

  test('1.26 snaps to 1.3 and clamping holds 0.5-3.0', () {
    expect(snapZoom(1.26), 1.3);
    expect(snapZoom(1.24), 1.2);
    expect(clampZoom(0.2), 0.5);
    expect(clampZoom(4), 3.0);
    expect(clampZoom(1.7), 1.7);
  });

  test('the rubber band is 0 at x = 0 and approaches d, halving at x = d / 0.35', () {
    expect(rubberBand(0, 100), 0);
    expect(rubberBand(100 / 0.35, 100), closeTo(50, 1e-9));
    expect(rubberBand(1e9, 100), closeTo(100, 0.01));
    expect(rubberBand(100, 100), closeTo(100 * (1 - 1 / 1.35), 1e-9));
  });

  test('rubberScale passes in-range scales and pulls back out-of-range ones', () {
    expect(rubberScale(1.5), 1.5);
    expect(rubberScale(3.5), lessThan(3.5));
    expect(rubberScale(3.5), greaterThan(3.0));
    expect(rubberScale(0.3), greaterThan(0.0));
    expect(rubberScale(0.3), lessThan(0.5));
  });
}
