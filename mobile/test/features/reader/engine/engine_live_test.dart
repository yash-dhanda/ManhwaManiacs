import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/engine/engine_live.dart';

void main() {
  test('state follows velocity only at 3000 / 0 crossings', () {
    var s = 0.0;
    final changes = <double>[];
    for (var i = 0; i < 200; i++) {
      final v = i < 50 ? i * 100.0 : (i < 150 ? 5000.0 - (i - 50) * 50 : 0.0);
      final n = stateVelocity(s, v);
      if (n != s) changes.add(n);
      s = n;
    }
    // first non-zero sample, crossing above 3000, crossing back below, then 0
    expect(changes.length, lessThanOrEqualTo(6));
    expect(s, 0);
    expect(stateVelocity(2000, 2900), 2000);
    expect(stateVelocity(2000, 3100), 3100);
    expect(stateVelocity(3100, 2900), 2900);
    expect(stateVelocity(3100, 0), 0);
  });
  test('overscroll crosses 0, 48, 72 only', () {
    expect(stateOverscroll(0, 10), 10);
    expect(stateOverscroll(10, 40), 10);
    expect(stateOverscroll(10, 48), 48);
    expect(stateOverscroll(48, 60), 48);
    expect(stateOverscroll(48, 72), 72);
    expect(stateOverscroll(72, 90), 72);
    expect(stateOverscroll(-50, -10), -10);
    expect(stateOverscroll(-10, 0), 0);
  });
  test('seam enters and leaves only', () {
    expect(stateSeam(null, 0.2), 0.2);
    expect(stateSeam(0.2, 0.5), 0.2);
    expect(stateSeam(0.5, null), isNull);
  });
  test('live notifier skips equal values', () {
    final l = EngineLive();
    var n = 0;
    l.scrollVelocity.addListener(() => n++);
    l.scrollVelocity.value = 5;
    l.scrollVelocity.value = 5;
    l.scrollVelocity.value = 6;
    expect(n, 2);
    l.dispose();
  });
}
