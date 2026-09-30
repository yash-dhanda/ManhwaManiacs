import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/platform/gravity.dart';
import 'package:sensors_plus/sensors_plus.dart';

AccelerometerEvent _e(double x, double y) => AccelerometerEvent(x, y, 0, DateTime(2026));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late StreamController<AccelerometerEvent> ctl;
  late int starts;
  late ProviderContainer c;

  setUp(() {
    starts = 0;
    ctl = StreamController<AccelerometerEvent>.broadcast();
    addTearDown(ctl.close);
    c = ProviderContainer(overrides: [
      gravitySensorProvider.overrideWithValue(() {
        starts++;
        return ctl.stream;
      }),
    ],);
    addTearDown(c.dispose);
  });

  test('no subscription without consumers', () {
    final g = c.read(gravityProvider);
    expect(g.sensorSubscriptions, 0);
    expect(starts, 0);
  });

  test('two consumers share one subscription; it ends with the last', () async {
    final g = c.read(gravityProvider);
    final a = g.stream.listen((_) {});
    final b = g.stream.listen((_) {});
    expect(starts, 1);
    expect(g.sensorSubscriptions, 1);
    await a.cancel();
    expect(g.sensorSubscriptions, 1);
    await b.cancel();
    expect(g.sensorSubscriptions, 0);
  });

  test('low-pass after three samples, relative to the first pose', () async {
    final g = c.read(gravityProvider);
    final out = <Offset>[];
    final s = g.stream.listen(out.add);
    ctl
      ..add(_e(0, 9.80665))
      ..add(_e(9.80665, 9.80665))
      ..add(_e(9.80665, 9.80665));
    await Future<void>.delayed(Duration.zero);
    expect(out, hasLength(3));
    expect(out[0], Offset.zero);
    // Smoothed x: 0 -> 0.15 -> 0.15 + 0.15 * 0.85.
    expect(out[1].dx, closeTo(0.15, 1e-9));
    expect(out[2].dx, closeTo(0.15 + 0.15 * 0.85, 1e-9));
    expect(out[2].dy, closeTo(0, 1e-9));
    await s.cancel();
  });
}
