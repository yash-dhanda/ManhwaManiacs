import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/novels/utils/shake_detector.dart';
import 'package:manhwamaniacs/features/novels/utils/voice_pulse.dart';

AccelSample s(double m, int ms) => (x: m, y: 0, z: 0, at: DateTime.utc(2026).add(Duration(milliseconds: ms)));

void main() {
  group('ShakeCounter', () {
    test('two peaks above 25 within 600 ms is a shake', () {
      final c = ShakeCounter();
      expect(c.add(s(30, 0)), isFalse);
      expect(c.add(s(2, 100)), isFalse);
      expect(c.add(s(31, 300)), isTrue);
    });
    test('peaks too far apart, or too weak, are not', () {
      final c = ShakeCounter();
      c.add(s(30, 0));
      c.add(s(1, 100));
      expect(c.add(s(30, 900)), isFalse);
      c.add(s(1, 950));
      expect(c.add(s(20, 1000)), isFalse);
    });
    test('one sustained peak counts once', () {
      final c = ShakeCounter();
      expect(c.add(s(30, 0)), isFalse);
      expect(c.add(s(32, 50)), isFalse);
      expect(c.add(s(33, 100)), isFalse);
    });
  });

  group('ShakeDetector', () {
    test('subscribes only while wanted and cancels otherwise', () async {
      final ctrl = StreamController<AccelSample>.broadcast();
      addTearDown(ctrl.close);
      var shakes = 0;
      final d = ShakeDetector(onShake: () => shakes++, source: () => ctrl.stream);
      expect(ctrl.hasListener, isFalse);
      d.setListening(true);
      expect(ctrl.hasListener, isTrue);
      d.setListening(true);
      ctrl.add(s(30, 0));
      ctrl.add(s(1, 50));
      ctrl.add(s(30, 200));
      await Future<void>.delayed(Duration.zero);
      expect(shakes, 1);
      d.setListening(false);
      await Future<void>.delayed(Duration.zero);
      expect(ctrl.hasListener, isFalse);
      expect(d.listening, isFalse);
    });
  });

  group('VoicePulse', () {
    test('rms', () {
      expect(rms(const []), 0);
      expect(rms(const [1, -1, 1, -1]), closeTo(1, 1e-9));
      expect(rms(const [0.5, 0.5]), closeTo(0.5, 1e-9));
    });
    test('attack is faster than release', () {
      final up = VoicePulse()..step(1, const Duration(milliseconds: 80));
      expect(up.value, closeTo(1 - 1 / 2.718281828, 1e-3));
      final down = VoicePulse();
      down.step(1, const Duration(seconds: 2));
      final peak = down.value;
      down.step(0, const Duration(milliseconds: 240));
      expect(down.value, closeTo(peak / 2.718281828, 0.01));
    });
    test('alpha', () {
      expect(pulseAlpha(0, reduced: false), closeTo(0.08, 1e-9));
      expect(pulseAlpha(1, reduced: false), closeTo(0.32, 1e-9));
      expect(pulseAlpha(1, reduced: true), 0.20);
    });
  });
}
