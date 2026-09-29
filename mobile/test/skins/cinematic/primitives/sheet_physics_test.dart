import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/sheet_physics.dart';

void main() {
  test('rubberBand is 0 at 0, monotone, and bounded by d', () {
    expect(rubberBand(0, 400), 0);
    expect(rubberBand(100, 400), closeTo(400 * (1 - 1 / (100 * 0.35 / 400 + 1)), 1e-9));
    expect(rubberBand(200, 400), greaterThan(rubberBand(100, 400)));
    expect(rubberBand(1e9, 400), lessThan(400));
    expect(rubberBand(-5, 400), 0);
  });

  test('nearestDetent picks the closest visible height', () {
    expect(nearestDetent(400, [400, 736]), 400);
    expect(nearestDetent(560, [400, 736]), 400);
    expect(nearestDetent(570, [400, 736]), 736);
    expect(nearestDetent(900, [400, 736]), 736);
  });

  test('shouldDismiss: 30 % and 800 px/s', () {
    expect(shouldDismiss(0.31, 0), isFalse);
    expect(shouldDismiss(0.29, 0), isTrue);
    expect(shouldDismiss(0.9, 799), isFalse);
    expect(shouldDismiss(0.9, 801), isTrue);
    expect(shouldDismiss(0.9, -2000), isFalse);
  });
}
