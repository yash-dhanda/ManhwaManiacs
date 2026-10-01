import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/screens/wrapped/story_math.dart';

void main() {
  test('the rubber band is 25 % at the ends', () {
    expect(stackOffset(-100, hasNext: true, hasPrev: false), -100);
    expect(stackOffset(-100, hasNext: false, hasPrev: true), -25);
    expect(stackOffset(80, hasNext: true, hasPrev: false), 20);
    expect(stackOffset(80, hasNext: false, hasPrev: true), 80);
  });

  test('the beneath card rises from 0.94 and 60 %', () {
    expect(beneathScaleAt(0), 0.94);
    expect(beneathScaleAt(1), 1);
    expect(beneathBrightnessAt(0), 0.6);
    expect(beneathBrightnessAt(1), 1);
    expect(leaveProgress(-180, 360), 0.5);
  });

  test('release projection picks the card', () {
    expect(commitDirection(-50, 0, 360, hasNext: true, hasPrev: true), 0);
    expect(commitDirection(-50, -1000, 360, hasNext: true, hasPrev: true), 1);
    expect(commitDirection(200, 0, 360, hasNext: true, hasPrev: true), -1);
    expect(commitDirection(-300, 0, 360, hasNext: false, hasPrev: true), 0);
    expect(commitDirection(300, 0, 360, hasNext: true, hasPrev: false), 0);
  });

  test('swipe down closes past 120 px projected', () {
    expect(closesOnRelease(60, 0), isFalse);
    expect(closesOnRelease(60, 400), isTrue);
    expect(closesOnRelease(130, 0), isTrue);
    expect(closesOnRelease(-200, -900), isFalse);
  });

  test('taps, thirds and the auto-advance rules', () {
    expect(isTap(const Duration(milliseconds: 200), 4), isTrue);
    expect(isTap(const Duration(milliseconds: 450), 4), isFalse);
    expect(isTap(const Duration(milliseconds: 100), 12), isFalse);
    expect(tapDirection(100, 360), -1);
    expect(tapDirection(130, 360), 1);
    expect(autoProgress(3000), 0.5);
    expect(autoProgress(9000), 1);
    bool runs({bool pressed = false, bool paused = false, bool resumed = true, bool share = false, bool reader = false, bool last = false}) => autoAdvanceRuns(pressed: pressed, paused: paused, resumed: resumed, shareOpen: share, screenReader: reader, last: last);
    expect(runs(), isTrue);
    expect(runs(pressed: true), isFalse);
    expect(runs(paused: true), isFalse);
    expect(runs(resumed: false), isFalse);
    expect(runs(share: true), isFalse);
    expect(runs(reader: true), isFalse);
    expect(runs(last: true), isFalse);
  });
}
