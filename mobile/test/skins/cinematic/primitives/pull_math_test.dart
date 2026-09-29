import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/pull_math.dart';

void main() {
  test('the rubber band is d * (1 - 1 / (x * 0.35 / d + 1))', () {
    expect(pullRubber(0), 0);
    expect(pullRubber(96), closeTo(96 * (1 - 1 / (96 * 0.35 / 96 + 1)), 1e-9));
    expect(pullRubber(10000), lessThan(96));
  });
  test('the rule is full at the 96 px trigger and armed there', () {
    expect(pullRuleFraction(0), 0);
    expect(pullRuleFraction(48), 0.5);
    expect(pullRuleFraction(300), 1);
    expect(pullArmed(95.9), isFalse);
    expect(pullArmed(96), isTrue);
  });
  test('the content offset is capped', () {
    expect(pullContentOffset(5000, max: 48), 48);
    expect(pullContentOffset(-3), 0);
  });
}
