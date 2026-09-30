import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/primitives/stack/stack_overview_math.dart';

void main() {
  test('slots: all levels up to eight, then "+N earlier" and the newest seven', () {
    for (var n = 1; n <= 8; n++) {
      final s = stackSlots(n);
      expect(s.count, n);
      expect(s.earlier, 0);
      expect(s.first, 0);
    }
    final ten = stackSlots(10);
    expect(ten.count, 8);
    expect(ten.earlier, 3);
    expect(ten.first, 3); // levels 3..9 are drawn under the "+3 earlier" card
    expect(stackSlots(9).earlier, 2);
  });

  test('offsets are 28 % of the scaled height, compressed when they do not fit', () {
    final o = cardOffsets(4, 500);
    expect(o, [0, 140, 280, 420]);
    expect(cardOffsets(1, 500), [0]);
    expect(cardOffsets(0, 500), isEmpty);
    final tight = cardOffsets(8, 500, available: 850);
    expect(tight.first, 0);
    expect(tight.last, closeTo(350, 1e-9)); // (850 - 500) of room across 7 gaps
    final roomy = cardOffsets(3, 500, available: 2000);
    expect(roomy[1], 140);
  });

  test('a sideways swipe removes the card past 40 % of its width, projected', () {
    expect(swipeRemoves(-160, 0, 390 * kCardScale), isTrue); // 0.4 x 241.8 = 96.7
    expect(swipeRemoves(-90, 0, 390 * kCardScale), isFalse);
    expect(swipeRemoves(-40, -600, 390 * kCardScale), isTrue);
    expect(swipeRemoves(40, 100, 390 * kCardScale), isFalse);
  });

  test('the card size is 0.62 of the screen', () {
    final s = cardSize(390, 844);
    expect(s.width, closeTo(241.8, 1e-9));
    expect(s.height, closeTo(523.28, 1e-9));
    expect(kFanDegrees, 14);
    expect(kFanPerspective, 0.0012);
    expect(kCardRadius, 26);
  });
}
