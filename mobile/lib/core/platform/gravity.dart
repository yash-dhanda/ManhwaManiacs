import 'dart:async';
import 'dart:ui' show Offset;

import 'package:flutter/widgets.dart' show AppLifecycleListener, AppLifecycleState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Test seam for the accelerometer (30 Hz, glass 15.7).
final gravitySensorProvider = Provider<Stream<AccelerometerEvent> Function()>(
  (ref) => () => accelerometerEventStream(samplingPeriod: const Duration(milliseconds: 33)),
  name: 'gravitySensor',
);

const double _g = 9.80665;
const double _alpha = 0.15;

/// The one accelerometer subscription every tilt effect shares (glass 2.4.2 rule 5: "the same reading drives every phone tilt
/// effect"). [stream] carries the gravity vector's screen-plane components in g (Android axes: x right, y up the screen), low-passed
/// with alpha 0.15 and relative to the pose captured when the first consumer subscribed. It is reference-counted: the sensor
/// subscription starts with the first listener, ends with the last, and pauses while the app is not resumed.
class GravitySource {
  GravitySource(this._sensor) {
    _controller = StreamController<Offset>.broadcast(onListen: _start, onCancel: _stop);
  }

  final Stream<AccelerometerEvent> Function() _sensor;
  late final StreamController<Offset> _controller;
  StreamSubscription<AccelerometerEvent>? _sub;
  AppLifecycleListener? _lifecycle;
  Offset? _smoothed;
  Offset? _pose;

  /// Live sensor subscriptions (0 or 1), for tests and the widget check of glass 15.7.
  int get sensorSubscriptions => _sub == null ? 0 : 1;

  Stream<Offset> get stream => _controller.stream;

  void _listen() {
    _sub ??= _sensor().listen(_onEvent, onError: (Object _) {});
  }

  void _pause() {
    _sub?.cancel();
    _sub = null;
  }

  void _start() {
    _smoothed = null;
    _pose = null;
    _lifecycle = AppLifecycleListener(onStateChange: (s) => s == AppLifecycleState.resumed ? _listen() : _pause());
    _listen();
  }

  void _stop() {
    _lifecycle?.dispose();
    _lifecycle = null;
    _pause();
  }

  void _onEvent(AccelerometerEvent e) {
    final v = Offset(e.x / _g, e.y / _g);
    final s = _smoothed == null ? v : _smoothed! + (v - _smoothed!) * _alpha;
    _smoothed = s;
    _pose ??= s;
    _controller.add(s - _pose!);
  }

  void dispose() {
    _stop();
    _controller.close();
  }
}

final gravityProvider = Provider<GravitySource>((ref) {
  final s = GravitySource(ref.watch(gravitySensorProvider));
  ref.onDispose(s.dispose);
  return s;
}, name: 'gravity',);
