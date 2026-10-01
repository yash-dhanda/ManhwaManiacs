import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show EdgeInsets;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Typed Dart side of the `mm/platform` channel (glass 15.3 Native). Every call answers a safe
/// default on a platform or a test host that has no handler, so callers never branch on failure.
class MmPlatform {
  MmPlatform({MethodChannel? channel}) : _channel = channel ?? const MethodChannel('mm/platform') {
    _channel.setMethodCallHandler(_onCall);
  }

  static final MmPlatform instance = MmPlatform();

  final MethodChannel _channel;
  final _reduceTransparency = StreamController<bool>.broadcast();
  final _contrast = StreamController<double>.broadcast();
  final _lowPower = StreamController<bool>.broadcast();

  /// `power.lowPowerChanged {value}`: iOS Low Power Mode, Android Battery Saver.
  Stream<bool> get lowPowerChanges => _lowPower.stream;

  /// `a11y.reduceTransparencyChanged {value}` (iOS).
  Stream<bool> get reduceTransparencyChanges => _reduceTransparency.stream;

  /// `a11y.contrastLevelChanged {value}` (Android 14+).
  Stream<double> get contrastLevelChanges => _contrast.stream;

  Future<dynamic> _onCall(MethodCall call) async {
    final v = (call.arguments as Map?)?['value'];
    switch (call.method) {
      case 'a11y.reduceTransparencyChanged':
        _reduceTransparency.add(v == true);
      case 'a11y.contrastLevelChanged':
        _contrast.add((v as num?)?.toDouble() ?? 0.0);
      case 'power.lowPowerChanged':
        _lowPower.add(v == true);
    }
    return null;
  }

  Future<T?> _call<T>(String method, [Object? args]) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// iOS `UIAccessibility.isReduceTransparencyEnabled`; Android has no system signal.
  Future<bool> reduceTransparency() async => await _call<bool>('a11y.reduceTransparency') ?? false;

  /// Android 14+ `UiModeManager.getContrast()` in -1..1; 0.0 elsewhere.
  Future<double> contrastLevel() async => (await _call<num>('a11y.contrastLevel'))?.toDouble() ?? 0.0;

  /// iOS Low Power Mode or Android Battery Saver; false where unknown.
  Future<bool> lowPower() async => await _call<bool>('power.lowPower') ?? false;

  /// Android `AudioManager.isMusicActive()`; iOS `isOtherAudioPlaying`.
  Future<bool> isMusicActive() async => await _call<bool>('audio.isMusicActive') ?? false;

  /// Android 10+: system-gesture exclusion rects, logical px `[left, top, width, height]`; empty clears.
  Future<void> setExclusionRects(List<List<double>> rects) => _call<void>('gestures.setExclusionRects', {'rects': rects});

  /// Android: the stable system-bar and cutout insets in logical px (what the bars take when shown, also while the reader
  /// hides them). Null on iOS and wherever the window has none yet: callers fall back to `MediaQuery.viewPaddingOf`.
  Future<EdgeInsets?> stableInsets() async {
    final m = await _call<Map<Object?, Object?>>('display.stableInsets');
    if (m == null) return null;
    double side(String k) => (m[k] as num?)?.toDouble() ?? 0;
    return EdgeInsets.fromLTRB(side('left'), side('top'), side('right'), side('bottom'));
  }

  /// Android `HAPTIC_FEEDBACK_ENABLED`; true elsewhere.
  Future<bool> hapticsSystemEnabled() async => await _call<bool>('haptics.systemEnabled') ?? true;

  @visibleForTesting
  void dispose() {
    _channel.setMethodCallHandler(null);
    _reduceTransparency.close();
    _contrast.close();
    _lowPower.close();
  }
}

final mmPlatformProvider = Provider<MmPlatform>((ref) => MmPlatform.instance);
