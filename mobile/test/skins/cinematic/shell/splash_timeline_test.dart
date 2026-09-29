import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/splash/splash_timeline.dart';

void main() {
  test('the last letter starts at 540 and lands at 1180', () {
    expect(kSplashLastLetterStartMs, 540);
    expect(kSplashLettersLandMs, 1180);
    expect(splashLetterAt(0, 252).t, 0);
    expect(splashLetterAt(0, 252 + 640).t, closeTo(1, 1e-9));
    expect(splashLetterAt(12, 539).t, 0);
    expect(splashLetterAt(12, 540).t, 0);
    expect(splashLetterAt(12, 1180).t, closeTo(1, 1e-9));
    // 13 graphemes, 24 ms apart.
    for (var i = 1; i < 13; i++) {
      expect(splashLetterAt(i, 252.0 + 24 * i).t, 0);
      expect(splashLetterAt(i, 252.0 + 24 * i + 1).t, greaterThan(0));
      expect(splashLetterAt(i - 1, 252.0 + 24 * i).t, greaterThan(0));
    }
  });

  test('the timeline table', () {
    final t = {for (final s in splashTimeline) s.element: (s.startMs, s.endMs)};
    expect(t['monogram-in'], (0, 100));
    expect(t['intersection'], (100, 420));
    expect(t['monogram-out'], (252, 572));
    expect(t['wordmark-letters'], (252, 1180));
    expect(t['oxford-rule'], (700, 1180));
    expect(t['impression'], (1180, 1260));
    expect(t['handoff'], (1180, 1400));
  });

  test('the hand-off is max(probeDone, 1180); the reveal is never stretched', () {
    expect(splashHandoffAt(null), isNull);
    expect(splashHandoffAt(0), 1180);
    expect(splashHandoffAt(900), 1180);
    expect(splashHandoffAt(1180), 1180);
    expect(splashHandoffAt(3000), 3000);
  });

  test('the dial and CONNECTING appear at 2400 ms while the probe is pending', () {
    expect(splashShowsDial(2399, null), isFalse);
    expect(splashShowsDial(2400, null), isTrue);
    expect(splashShowsDial(2400, 2000), isFalse);
  });

  test('the impression moves the lockup 1 px down and back over 80 ms', () {
    expect(splashImpressionOffset(1180), 0);
    expect(splashImpressionOffset(1220), closeTo(1, 1e-9));
    expect(splashImpressionOffset(1260), closeTo(0, 1e-9));
  });

  test('a warm start is under 4 h after the last hand-off with no skin restart', () {
    const now = 100000000;
    expect(splashIsWarm(lastHandoffEpochMs: now - 3 * 3600000, skinRestart: false, nowEpochMs: now), isTrue);
    expect(splashIsWarm(lastHandoffEpochMs: now - 5 * 3600000, skinRestart: false, nowEpochMs: now), isFalse);
    expect(splashIsWarm(lastHandoffEpochMs: now - 1000, skinRestart: true, nowEpochMs: now), isFalse);
    expect(splashIsWarm(lastHandoffEpochMs: null, skinRestart: false, nowEpochMs: now), isFalse);
  });
}
