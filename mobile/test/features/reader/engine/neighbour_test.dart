import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/engine/neighbour.dart';

void main() {
  test('phases', () {
    expect(neighbourPhase(47), NeighbourPhase.idle);
    expect(neighbourPhase(48), NeighbourPhase.armed);
    expect(neighbourPhase(71.9), NeighbourPhase.armed);
    expect(neighbourPhase(72), NeighbourPhase.locked);
    expect(neighbourPhase(-72), NeighbourPhase.locked);
  });
  test('wheel mapping', () {
    expect(wheelDisplayed(139) < 48, isTrue);
    expect(wheelDisplayed(140), closeTo(48, 1e-9));
    expect(wheelDisplayed(210), closeTo(72, 1e-9));
  });
  test('wheel accumulator resets after 400 ms', () {
    final w = WheelAccumulator();
    expect(w.add(100, const Duration(milliseconds: 0)), 100);
    expect(w.add(50, const Duration(milliseconds: 300)), 150);
    expect(w.add(50, const Duration(milliseconds: 701)), 50);
  });
  test('raw/displayed round trip on 844', () {
    for (final x in [0.0, 50, 143, 800]) {
      expect(rawFromDisplayed(displayedFromRaw(x.toDouble(), 844), 844), closeTo(x, 0.01));
      expect(rawFromDisplayed(displayedFromRaw(-x.toDouble(), 844), 844), closeTo(-x, 0.01));
    }
    expect(displayedFromRaw(0, 844), 0);
    expect(displayedFromRaw(93, 844), closeTo(48.2, 0.3));
    expect(displayedFromRaw(144, 844), closeTo(72.4, 0.3));
    expect(displayedFromRaw(1e9, 844), closeTo(844, 0.01));
  });
  test('fling', () {
    expect(flingDistance(1000), closeTo(499, 5));
    expect(flingStep(1000, 8.33), closeTo(1000 * 0.998 * 0.998 * 0.998 * 0.998 * 0.998 * 0.998 * 0.998 * 0.998 * 0.9994, 2));
    expect(neighbourMinutes(42), 7);
  });
}
