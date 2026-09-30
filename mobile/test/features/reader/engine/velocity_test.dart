import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/engine/velocity.dart';

void main() {
  test('constant motion', () {
    final t = VelocityTracker100();
    for (var i = 0; i < 30; i++) {
      t.add(Duration(microseconds: i * 8333), i * 8.333 * 1.2);
    }
    expect(t.velocity(), closeTo(1200, 1));
  });
  test('reversal flips within a window', () {
    final t = VelocityTracker100();
    var p = 0.0;
    var ms = 0;
    for (var i = 0; i < 20; i++) { t.add(Duration(milliseconds: ms += 10), p += 10); }
    for (var i = 0; i < 12; i++) { t.add(Duration(milliseconds: ms += 10), p -= 10); }
    expect(t.velocity(), lessThan(0));
  });
  test('stop reads 0 after 100 ms', () {
    final t = VelocityTracker100();
    t.add(Duration.zero, 0);
    t.add(const Duration(milliseconds: 10), 10);
    expect(t.velocity(const Duration(milliseconds: 50)), isNot(0));
    expect(t.velocity(const Duration(milliseconds: 110)), 0);
  });
}
