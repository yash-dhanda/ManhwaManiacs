import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/pinch_steps.dart';

void main() {
  test('one step per x1.15, truncated toward zero', () {
    expect(pinchSteps(1), 0);
    expect(pinchSteps(1.149), 0);
    expect(pinchSteps(1.15), 1);
    expect(pinchSteps(1.15 * 1.15), 2);
    expect(pinchSteps(1 / 1.15), -1);
    expect(pinchSteps(0.9), 0);
    expect(pinchSteps(0), 0);
  });

  test('clamped 15-30', () {
    expect(pinchSize(19, 1.15 * 1.15), 21);
    expect(pinchSize(29, 4), 30);
    expect(pinchSize(16, 0.25), 15);
  });

  test('keys step and reset the same value', () {
    expect(keySize(19, step: 1, defaultSize: 19), 20);
    expect(keySize(15, step: -1, defaultSize: 19), 15);
    expect(keySize(26, reset: true, defaultSize: 19), 19);
  });
}
