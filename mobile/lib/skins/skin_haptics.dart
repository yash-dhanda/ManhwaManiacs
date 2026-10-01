import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaimon/gaimon.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/skins.dart';
import 'package:manhwamaniacs/skins/token_types.g.dart';

const _primitives = {
  'selection', 'light', 'medium', 'heavy', 'rigid', 'soft', 'success', //
  'warning', 'error', 'toggleOn', 'toggleOff', 'dragStart', 'rigidBack',
};

enum HapticKind { primitive, ahap, none }

/// One parsed pattern string (shared/00 §2 "haptics" grammar).
class HapticPattern {
  const HapticPattern._(
    this.kind,
    this.name, {
    this.intensity,
    this.velocity = false,
    this.velocityCap,
    this.depth = false,
  });

  final HapticKind kind;
  final String name;

  /// Literal `:0.4` intensity.
  final double? intensity;

  /// `:velocity` or `:velocity<=c`.
  final bool velocity;
  final double? velocityCap;

  /// `ahap:name{depth}`.
  final bool depth;

  bool get isNone => kind == HapticKind.none;
  bool get isAhap => kind == HapticKind.ahap;
  bool get qualified => intensity != null || velocity;

  static HapticPattern parse(String s) {
    if (s == 'none') return const HapticPattern._(HapticKind.none, 'none');
    if (s.startsWith('ahap:')) {
      var n = s.substring(5);
      var depth = false;
      if (n.endsWith('{depth}')) {
        depth = true;
        n = n.substring(0, n.length - 7);
      }
      if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9]*$').hasMatch(n)) {
        throw FormatException('Bad haptic pattern', s);
      }
      return HapticPattern._(HapticKind.ahap, n, depth: depth);
    }
    final i = s.indexOf(':');
    final name = i < 0 ? s : s.substring(0, i);
    if (!_primitives.contains(name)) throw FormatException('Bad haptic pattern', s);
    if (i < 0) return HapticPattern._(HapticKind.primitive, name);
    final q = s.substring(i + 1);
    if (q == 'velocity') return HapticPattern._(HapticKind.primitive, name, velocity: true);
    if (q.startsWith('velocity<=')) {
      final c = double.tryParse(q.substring(10));
      if (c == null || c < 0 || c > 1) throw FormatException('Bad haptic pattern', s);
      return HapticPattern._(HapticKind.primitive, name, velocity: true, velocityCap: c);
    }
    final v = double.tryParse(q);
    if (v == null || v < 0 || v > 1) throw FormatException('Bad haptic pattern', s);
    return HapticPattern._(HapticKind.primitive, name, intensity: v);
  }
}

/// glass §5.1: `i = clamp(0.3 + |v| / 4000, 0.3, 1.0)`.
double velocityIntensity(double v) => (0.3 + v.abs() / 4000).clamp(0.3, 1.0);

/// Everything platform-side, so tests can record instead of vibrate.
abstract interface class HapticsDriver {
  Future<void> named(HapticsType type);
  Future<void> ahap(String json);
  Future<void> impact(String style, double intensity);
  Future<bool> perform(String pattern);
  Future<bool> oneShot(int ms, int amplitude);
  Future<bool> systemEnabled();
}

const _channel = MethodChannel('mm/platform');

class PlatformHapticsDriver implements HapticsDriver {
  const PlatformHapticsDriver();

  Future<T?> _call<T>(String method, [Object? args]) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<void> named(HapticsType type) async {
    try {
      await Haptics.vibrate(type);
    } catch (_) {}
  }

  @override
  Future<void> ahap(String json) async {
    try {
      Gaimon.patternFromData(json);
    } catch (_) {}
  }

  @override
  Future<void> impact(String style, double intensity) async {
    await _call<void>('haptics.impact', {'style': style, 'intensity': intensity});
  }

  @override
  Future<bool> perform(String pattern) async =>
      await _call<bool>('haptics.perform', {'pattern': pattern}) ?? false;

  @override
  Future<bool> oneShot(int ms, int amplitude) async =>
      await _call<bool>('haptics.oneShot', {'ms': ms, 'amplitude': amplitude}) ?? false;

  @override
  Future<bool> systemEnabled() async =>
      await _call<bool>('haptics.systemEnabled') ?? true;
}

const _types = {
  'selection': HapticsType.selection,
  'light': HapticsType.light,
  'medium': HapticsType.medium,
  'heavy': HapticsType.heavy,
  'rigid': HapticsType.rigid,
  'soft': HapticsType.soft,
  'success': HapticsType.success,
  'warning': HapticsType.warning,
  'error': HapticsType.error,
};

const _impactStyles = {'soft', 'light', 'medium', 'heavy', 'rigid'};

/// One skin's haptic vocabulary played through the right platform call.
///
/// The device-wide "Haptic feedback" switch is [enabled]; the plan says
/// per-profile but cinematic §5 and glass §5 make it per device.
class SkinHaptics {
  SkinHaptics({
    required this.skin,
    required this.map,
    required this.enabled,
    HapticsDriver? driver,
    AssetBundle? bundle,
  })  : _driver = driver ?? const PlatformHapticsDriver(),
        _bundle = bundle ?? rootBundle;

  final SkinId skin;
  final Map<HapticEvent, List<HapticStep>> map;
  final bool enabled;
  final HapticsDriver _driver;
  final AssetBundle _bundle;

  final Map<String, Future<String>> _ahapCache = {};
  Future<bool>? _systemOn;

  bool get _android => defaultTargetPlatform == TargetPlatform.android;
  bool get _glass => skin == SkinId.glass;

  Future<bool> _system() => _systemOn ??= _driver.systemEnabled();

  Future<void> fire(HapticEvent event, {double velocity = 0, int depth = 1}) async {
    if (!enabled) return;
    final steps = map[event];
    if (steps == null || steps.isEmpty) return;
    var at = 0;
    final now = <Future<void>>[];
    for (final step in steps) {
      at += step.afterMs;
      final count = step.maxRepeats ?? 1;
      for (var k = 0; k < count; k++) {
        final t = at + k * (step.repeatEveryMs ?? 0);
        if (t == 0) {
          now.add(_play(step.pattern, velocity, depth));
        } else {
          Timer(Duration(milliseconds: t), () => unawaited(_play(step.pattern, velocity, depth)));
        }
      }
    }
    await Future.wait(now);
  }

  Future<void> _play(String raw, double velocity, int depth) async {
    final p = HapticPattern.parse(raw);
    if (p.isNone) return;
    if (_android && !await _system() && !(_glass && !p.isAhap && !p.velocity)) return;
    if (p.isAhap) {
      final n = p.depth ? '${p.name}${depth.clamp(1, 4)}' : p.name;
      final json = await (_ahapCache[n] ??=
          _bundle.loadString('assets/haptics/${skin.name}/$n.ahap.json'));
      return _driver.ahap(json);
    }
    var i = p.intensity ?? 1.0;
    if (p.velocity) {
      i = velocityIntensity(velocity);
      if (p.velocityCap != null) i = math.min(i, p.velocityCap!);
    }
    final n = p.name;
    if (_android && _glass) {
      if (p.velocity) {
        if (await _system() &&
            await _driver.oneShot(12, (i * 255).round())) {
          return;
        }
      }
      await _driver.perform(n);
      return;
    }
    if (!_android) {
      switch (n) {
        case 'toggleOn':
          return _driver.impact('rigid', 0.5);
        case 'toggleOff':
          return _driver.impact('soft', 0.4);
        case 'rigidBack':
          return _driver.impact('soft', 0.3);
        case 'dragStart':
          return _driver.named(HapticsType.light);
      }
      if (p.qualified && _impactStyles.contains(n)) return _driver.impact(n, i);
      return _driver.named(_types[n]!);
    }
    // Android, Cinematic (and legacy, whose map is empty).
    switch (n) {
      case 'toggleOn':
        return _driver.named(HapticsType.medium);
      case 'toggleOff':
      case 'rigidBack':
      case 'dragStart':
        return _driver.named(HapticsType.light);
    }
    return _driver.named(_types[n]!);
  }
}

final skinHapticsProvider = Provider<SkinHaptics>((ref) => SkinHaptics(
      skin: ref.watch(skinIdProvider),
      map: ref.watch(skinProvider).haptics,
      enabled: ref.watch(hapticFeedbackProvider),
    ),);

/// Settings -> Sound and haptics "Feel it" (glass 5.3): sample [index] of selection, soft 0.5, rigid 0.6, droplet, success.
/// Android has no `impact` channel method and no Core Haptics, so it plays the samples the way Glass's Android path does.
Future<void> playFeelSample(int index, {HapticsDriver driver = const PlatformHapticsDriver(), AssetBundle? bundle}) async {
  final android = defaultTargetPlatform == TargetPlatform.android;
  switch (index) {
    case 0:
      await driver.named(HapticsType.selection);
    case 1 when android:
      await driver.perform('soft');
    case 1:
      await driver.impact('soft', 0.5);
    case 2 when android:
      await driver.perform('rigid');
    case 2:
      await driver.impact('rigid', 0.6);
    case 3 when android:
      await driver.oneShot(12, 153);
    case 3:
      try {
        await driver.ahap(await (bundle ?? rootBundle).loadString('assets/haptics/glass/droplet.ahap.json'));
      } catch (_) {}
    default:
      await driver.named(HapticsType.success);
  }
}
