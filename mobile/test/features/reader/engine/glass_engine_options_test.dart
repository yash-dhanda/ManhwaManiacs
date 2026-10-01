import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_options.dart';
import 'package:manhwamaniacs/features/reader/engine/zoom_math.dart';

void main() {
  test('defaults keep the legacy and Cinematic path: 0.5-3.0, 0.5 band, engine-owned wake and lock', () {
    const o = ReaderEngineOptions();
    expect(o.pinchMin, isNull);
    expect(o.pinchMax, isNull);
    expect(o.rubberBandMax, isNull);
    expect(o.legacyWakeAndLock, isTrue);
    // The default band the engine applies when rubberBandMax is null.
    expect(rubberScale(3.5, max: kZoomMax, d: o.rubberBandMax ?? 0.5), rubberScale(3.5, max: kZoomMax));
  });

  test('Glass rubberBandMax 0.18: the displayed overshoot never exceeds 0.18 (glass 4.5)', () {
    for (final raw in [3.2, 4.0, 10.0, 1000.0]) {
      final shown = rubberScale(raw, min: 1, max: 3, d: 0.18);
      expect(shown, greaterThan(3));
      expect(shown - 3, lessThan(0.18));
    }
    for (final raw in [0.8, 0.2, -50.0]) {
      expect(1 - rubberScale(raw, min: 1, max: 3, d: 0.18), lessThan(0.18));
    }
    expect(rubberScale(2.2, min: 1, max: 3, d: 0.18), 2.2, reason: 'inside the range nothing changes');
  });
}
