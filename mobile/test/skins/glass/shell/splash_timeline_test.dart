import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/splash/splash_timeline.dart';

void main() {
  test('free fall lands at 200 ms from 180 px above', () {
    expect(splashCold(0).dropletDy, -180);
    expect(splashCold(100).dropletDy, closeTo(-180 + 0.5 * 9000 * 0.01, 1e-6));
    expect(splashCold(200).dropletDy, 0);
    expect(splashCold(1000).dropletDy, 0);
  });

  test('impact squashes then recovers; the ripple runs 500 ms to 140 px', () {
    final at = splashCold(200);
    expect(at.squashX, closeTo(1.25, 0.02));
    expect(at.squashY, closeTo(0.80, 0.02));
    expect(splashCold(900).squashX, closeTo(1, 0.05));
    expect(at.rippleRadius, 0);
    expect(splashCold(450).rippleRadius, closeTo(70, 1));
    expect(splashCold(700).rippleOpacity, closeTo(0, 1e-9));
  });

  test('lens grows from 24 to 128 px and refraction settles by 700 ms', () {
    expect(splashCold(150).lensSide, 24);
    expect(splashCold(700).refractBlur, 0);
    expect(splashCold(700).chromaOffset, 0);
    expect(splashCold(450).refractBlur, closeTo(6, 0.01));
    expect(splashCold(1000).lensSide, closeTo(128, 3));
  });

  test('wordmark reveals 500 to 1000 ms, hand-off 1000 to 1200 ms', () {
    expect(splashCold(500).wordmark, 0);
    expect(splashCold(750).wordmark, closeTo(0.5, 1e-9));
    expect(splashCold(1000).wordmark, 1);
    expect(splashCold(1000).handoff, 0);
    expect(splashCold(1100).handoff, closeTo(0.5, 1e-9));
    expect(splashCold(1200).handoff, 1);
  });

  test('the mark fades over 120 ms', () {
    expect(splashCold(0).markOpacity, 1);
    expect(splashCold(120).markOpacity, 0);
  });

  test('warm plays under 4 h unless a skin switch just happened', () {
    final now = DateTime(2026, 9, 30, 12);
    expect(splashIsWarm(now: now, lastSeen: now.subtract(const Duration(hours: 3)), skinSwitchArrival: false), isTrue);
    expect(splashIsWarm(now: now, lastSeen: now.subtract(const Duration(hours: 5)), skinSwitchArrival: false), isFalse);
    expect(splashIsWarm(now: now, lastSeen: now.subtract(const Duration(hours: 1)), skinSwitchArrival: true), isFalse);
    expect(splashIsWarm(now: now, lastSeen: null, skinSwitchArrival: false), isFalse);
  });

  test('warm is 400 ms and reduced is 200 ms', () {
    expect(splashWarm(250).lensOpacity, 1);
    expect(splashWarm(400).handoff, 1);
    expect(splashDuration(SplashKind.warm), 400);
    expect(splashDuration(SplashKind.reduced), 200);
    expect(splashReducedFade(100), closeTo(0.5, 1e-9));
  });
}
