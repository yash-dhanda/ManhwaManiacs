import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/utils/auto_scroll_speed.dart';
import 'package:manhwamaniacs/features/reader/utils/time_left.dart';

void main() {
  test('auto-scroll px/s in engine units', () {
    expect(autoScrollPxPerSecondX(1.0, 844), closeTo(46.9, 0.05));
    expect(autoScrollPxPerSecondX(3.0, 1080), closeTo(180, 1e-9));
    expect(stepAutoScrollSpeed(1.0, 0.25), 1.25);
    expect(stepAutoScrollSpeed(3.0, 0.25), 3.0);
    expect(stepAutoScrollSpeed(0.5, -0.25), 0.5);
  });

  test('time left is null until 2 minutes of pace samples exist', () {
    final t = PaceTracker();
    final t0 = DateTime(2026, 1, 1);
    t.sample(1, t0);
    t.sample(4, t0.add(const Duration(seconds: 100)));
    expect(t.pagesPerMinute, isNull);
    t.sample(9, t0.add(const Duration(minutes: 2)));
    expect(t.pagesPerMinute, closeTo(4, 1e-9));
    expect(minutesLeft(page: 9, pageCount: 40, pagesPerMinute: t.pagesPerMinute), 8);
    expect(minutesLeft(page: 9, pageCount: 40, pagesPerMinute: null), isNull);
    t.sample(2, t0.add(const Duration(minutes: 3)));
    expect(t.pagesPerMinute, isNull, reason: 'going back restarts the window');
  });
}
