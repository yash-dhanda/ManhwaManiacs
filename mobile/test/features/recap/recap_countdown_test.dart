import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/recap/utils/recap_countdown.dart';

typedef R = RecapCountdown;

void main() {
  test('runs only once started and never below 0', () {
    var s = const CountdownState();
    expect(R.tick(s, 1000).remainingMs, 12000);
    s = R.start(s);
    s = R.tick(s, 5000);
    expect(s.remainingMs, 7000);
    expect(s.seconds, 7);
    s = R.tick(s, 99999);
    expect(s.remainingMs, 0);
    expect(s.finished, isTrue);
  });
  test('each reason pauses', () {
    for (final r in PauseReason.values) {
      var s = R.start(const CountdownState());
      s = R.pause(s, r);
      expect(R.tick(s, 1000).remainingMs, 12000, reason: '$r');
      expect(R.tick(R.resume(s, r), 1000).remainingMs, 11000, reason: '$r');
    }
  });
  test('reset returns to 12,000 ms', () {
    var s = R.tick(R.start(const CountdownState()), 4000);
    expect(R.reset(s).remainingMs, 12000);
  });
  test('key stays until Space; space toggles', () {
    var s = R.pause(R.start(const CountdownState()), PauseReason.key);
    s = R.resume(R.pause(s, PauseReason.touch), PauseReason.touch);
    expect(s.pausedBy, {PauseReason.key});
    s = R.toggleSpace(s);
    expect(s.pausedBy, isEmpty);
    s = R.toggleSpace(s);
    expect(s.pausedBy, {PauseReason.space});
    s = R.pause(s, PauseReason.touch);
    s = R.toggleSpace(s);
    expect(s.pausedBy, {PauseReason.touch});
  });
}
