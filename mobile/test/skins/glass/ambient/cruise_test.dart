import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/ambient/cruise.dart';

void main() {
  test('manga px/s is 60 x m inside 0.25-4.00', () {
    expect(mangaPxPerSecond(1), 60);
    expect(mangaPxPerSecond(4), 240);
    expect(mangaPxPerSecond(0.1), 15);
    expect(mangaPxPerSecond(9), 240);
  });

  test('the novel formula at 250 wpm, 12 words a line and 30 px lines is 10.42 px/s', () {
    expect(novelPxPerSecond(1, wpm: 250, wordsPerLine: 12, lineHeightPx: 30), closeTo(10.42, 0.01));
    expect(novelPxPerSecond(2, wpm: 250, wordsPerLine: 12, lineHeightPx: 30), closeTo(20.83, 0.01));
  });

  test('dragging up 80 px adds 0.50x, 8 px is 0.05x, and the ends hold', () {
    expect(rawAfterDrag(1.0, -80), closeTo(1.5, 1e-9));
    expect(rawAfterDrag(1.0, 8), closeTo(0.95, 1e-9));
    expect(rawAfterDrag(3.9, -400), 4.0);
    expect(rawAfterDrag(0.3, 400), 0.25);
  });

  test('the magnet holds 1.0x within 0.08 and not beyond', () {
    expect(settle(1.07), 1.0);
    expect(settle(0.93), 1.0);
    expect(settle(1.09), 1.1);
    expect(settle(1.5), 1.5);
  });

  test('speed text has one decimal, two when needed', () {
    expect(formatSpeed(1), '1.0×');
    expect(formatSpeed(1.5), '1.5×');
    expect(formatSpeed(1.25), '1.25×');
    expect(formatSpeed(0.25), '0.25×');
  });

  test('ticks fire on each multiple of 0.25 crossed, either way', () {
    expect(tickCrossed(1.2, 1.3), 1.25);
    expect(tickCrossed(1.3, 1.2), 1.25);
    expect(tickCrossed(1.05, 1.2), isNull);
    expect(tickCrossed(1.0, 1.0), isNull);
  });

  test('a coasting flick engages at round(v / 60, 0.05) between 15 and 240 px/s', () {
    expect(speedForVelocity(90), 1.5);
    expect(speedForVelocity(61), 1.0);
    expect(engages(240), isTrue);
    expect(engages(241), isFalse);
    expect(engages(14), isFalse);
    expect(engages(-100), isFalse);
  });
}
