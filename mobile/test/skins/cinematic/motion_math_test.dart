import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/motion_math.dart';

void main() {
  test('gridDelay: +32 per item, +64 per row, capped at 480', () {
    expect(gridDelay(0, 0), 0);
    expect(gridDelay(3, 0), 96);
    expect(gridDelay(2, 1), 128);
    expect(gridDelay(5, 6), 480);
    expect(gridDelay(20, 20), 480);
  });

  test('listDelay: 24 per row capped at 360', () {
    expect(listDelay(0), 0);
    expect(listDelay(10), 240);
    expect(listDelay(15), 360);
    expect(listDelay(40), 360);
  });

  test('letterStep: 24 ms, total stagger capped at 560', () {
    expect(letterStep(0), 0);
    expect(letterStep(1), 0);
    expect(letterStep(7), 24);
    expect(letterStep(24), 24); // 23 gaps x 24 = 552
    expect(letterStep(40), closeTo(560 / 39, 1e-9));
    expect(letterStep(40) * 39, closeTo(560, 1e-9));
  });

  test('wordDelay 30 per word', () {
    expect(wordDelay(0), 0);
    expect(wordDelay(4), 120);
  });

  test('typedCount: one grapheme per 50 ms, capped at the length', () {
    expect(typedCount(0, 40), 0);
    expect(typedCount(49, 40), 0);
    expect(typedCount(50, 40), 1);
    expect(typedCount(1000, 40), 20);
    expect(typedCount(5000, 40), 40);
  });

  test('decideEntrance: every branch', () {
    EntranceKind k({bool seen = false, bool skeleton = false, bool append = false}) =>
        decideEntrance(seenThisSession: seen, hadSkeleton: skeleton, isAppend: append);
    expect(k(), EntranceKind.set);
    expect(k(seen: true), EntranceKind.none);
    expect(k(seen: true, skeleton: true, append: true), EntranceKind.none);
    expect(k(skeleton: true), EntranceKind.dissolve);
    expect(k(append: true), EntranceKind.dissolve);
  });
}
