/// Shake to extend the sleep timer (cinematic 8.16.6). The accelerometer is subscribed ONLY while
/// a sleep timer is in its last minute or its fade, and cancelled otherwise: a phone in a pocket
/// must not keep the sensor awake all evening.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// One accelerometer reading, gravity removed (m/s^2).
typedef AccelSample = ({double x, double y, double z, DateTime at});

/// A shake is two peaks above this magnitude within [kShakeWindow].
const double kShakeThreshold = 25;
const Duration kShakeWindow = Duration(milliseconds: 600);

/// Glass (8.16.6): 2.2 g, two peaks within 300 ms, sampled at 30 Hz (15.7).
const double kGlassShakeThresholdMs2 = 2.2 * 9.80665;
const Duration kGlassShakeWindow = Duration(milliseconds: 300);
const Duration kGlassShakeSampling = Duration(milliseconds: 33);

/// Counts peaks in a stream of samples; [add] returns true when a shake completed.
class ShakeCounter {
  ShakeCounter({this.threshold = kShakeThreshold, this.window = kShakeWindow});
  final double threshold;
  final Duration window;
  DateTime? _firstPeak;
  bool _above = false;

  bool add(AccelSample s) {
    final magnitude = math.sqrt(s.x * s.x + s.y * s.y + s.z * s.z);
    final above = magnitude > threshold;
    final rising = above && !_above;
    _above = above;
    if (!rising) return false;
    final first = _firstPeak;
    if (first != null && s.at.difference(first) <= window) {
      _firstPeak = null;
      return true;
    }
    _firstPeak = s.at;
    return false;
  }
}

/// The live sensor stream, replaceable in tests.
typedef AccelerometerSource = Stream<AccelSample> Function();

Stream<AccelSample> platformAccelerometer({Duration? samplingPeriod}) =>
    userAccelerometerEventStream(samplingPeriod: samplingPeriod ?? SensorInterval.normalInterval).map((e) => (x: e.x, y: e.y, z: e.z, at: DateTime.now()));

class ShakeDetector {
  ShakeDetector({
    required this.onShake,
    AccelerometerSource? source,
    double thresholdMs2 = kShakeThreshold,
    Duration window = kShakeWindow,
    Duration? samplingPeriod,
  })  : _source = source ?? (() => platformAccelerometer(samplingPeriod: samplingPeriod)),
        _counter = ShakeCounter(threshold: thresholdMs2, window: window);

  final VoidCallback onShake;
  final AccelerometerSource _source;
  StreamSubscription<AccelSample>? _sub;
  final ShakeCounter _counter;

  /// Whether the sensor is subscribed right now.
  bool get listening => _sub != null;

  /// Subscribe while [wanted], cancel otherwise. Idempotent.
  void setListening(bool wanted) {
    if (wanted && _sub == null) {
      _sub = _source().listen(
        (s) {
          if (_counter.add(s)) onShake();
        },
        onError: (Object _) {},
      );
    } else if (!wanted && _sub != null) {
      unawaited(_sub!.cancel());
      _sub = null;
    }
  }

  void dispose() => setListening(false);
}
