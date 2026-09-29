import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';
import 'package:manhwamaniacs/skins/skin_haptics.dart';

/// One fired event, for widget tests that count haptics (debug builds only).
@immutable
class GlassHapticLog {
  const GlassHapticLog(this.event, this.intensity, this.kind);
  final HapticEvent event;
  final double intensity;
  final GlassHapticKind kind;

  @override
  String toString() => '${event.name}@${intensity.toStringAsFixed(2)}';
}

enum GlassHapticKind { tick, impact }

/// The Glass haptics service (glass 5.1, 5.2). It sits on [SkinHaptics], which plays each event's pattern
/// through the platform (and honours the per-device Haptics switch and `haptics.systemEnabled` on Android),
/// and adds what a fast gesture needs: ticks (`selection`) at most one per 40 ms, impacts at most one per
/// 120 ms, a burst keeping the strongest, and intensities scaled by velocity and depth.
class GlassHaptics {
  GlassHaptics({required SkinHaptics haptics, Duration Function()? clock})
      : _haptics = haptics,
        _clock = clock ?? (() => Duration(microseconds: DateTime.now().microsecondsSinceEpoch));

  final SkinHaptics _haptics;
  final Duration Function() _clock;

  static const int _logCapacity = 64;

  /// The last 64 fired events (debug builds only).
  static final List<GlassHapticLog> debugLog = [];

  final Map<GlassHapticKind, Duration> _last = {};
  final Map<GlassHapticKind, _Pending> _pending = {};
  final Map<GlassHapticKind, Timer> _timers = {};

  static Duration _interval(GlassHapticKind k) => Duration(
        milliseconds: (k == GlassHapticKind.tick ? glassTokens.physicsHapticMinInterval : glassTokens.physicsImpactMinInterval).round(),
      );

  /// The event's class: a `selection` first step is a tick, everything else an impact.
  static GlassHapticKind kindOf(HapticEvent event) {
    final steps = glassHaptics[event];
    if (steps == null || steps.isEmpty) return GlassHapticKind.impact;
    return HapticPattern.parse(steps.first.pattern).name == 'selection' ? GlassHapticKind.tick : GlassHapticKind.impact;
  }

  /// glass 5.1: the intensity an event fires at. `nav.push` follows depth (and the velocity term of a
  /// thrown push); `:velocity` patterns follow `impactIntensity(v)` (capped by the pattern); the rest
  /// use their literal intensity, or full strength.
  static double intensityOf(HapticEvent event, {double? velocity, int? depth}) {
    final steps = glassHaptics[event];
    if (steps == null || steps.isEmpty) return 0;
    if (event == HapticEvent.navPush) {
      final d = depthIntensity(depth ?? 1);
      return velocity == null ? d : math.max(d, impactIntensity(velocity));
    }
    final p = HapticPattern.parse(steps.first.pattern);
    if (p.velocity) {
      final i = impactIntensity(velocity ?? 0);
      return p.velocityCap == null ? i : math.min(i, p.velocityCap!);
    }
    return p.intensity ?? (kindOf(event) == GlassHapticKind.tick ? 0.3 : 1.0);
  }

  Future<void> fire(HapticEvent event, {double? velocity, int? depth}) async {
    if (!_haptics.enabled) return;
    final steps = glassHaptics[event];
    if (steps == null || steps.isEmpty) return;
    final kind = kindOf(event);
    final strength = intensityOf(event, velocity: velocity, depth: depth);
    final now = _clock();
    final last = _last[kind];
    if (last == null || now - last >= _interval(kind)) {
      _timers.remove(kind)?.cancel();
      _pending.remove(kind);
      return _play(kind, event, strength, velocity, depth, now);
    }
    // Inside the window: hold the burst's strongest and play it when the window ends.
    final held = _pending[kind];
    if (held == null || strength >= held.strength) _pending[kind] = _Pending(event, strength, velocity, depth);
    _timers[kind] ??= Timer(_interval(kind) - (now - last), () => flush(kind));
  }

  /// Plays the held event of [kind], if any (the timer's job; tests call it directly).
  @visibleForTesting
  Future<void> flush(GlassHapticKind kind) async {
    _timers.remove(kind);
    final p = _pending.remove(kind);
    if (p == null) return;
    await _play(kind, p.event, p.strength, p.velocity, p.depth, _clock());
  }

  Future<void> _play(GlassHapticKind kind, HapticEvent event, double strength, double? velocity, int? depth, Duration now) {
    _last[kind] = now;
    if (kDebugMode) {
      debugLog.add(GlassHapticLog(event, strength, kind));
      if (debugLog.length > _logCapacity) debugLog.removeAt(0);
    }
    return _haptics.fire(event, velocity: velocity ?? 0, depth: depth ?? 1);
  }

  void dispose() {
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
    _pending.clear();
  }
}

class _Pending {
  const _Pending(this.event, this.strength, this.velocity, this.depth);
  final HapticEvent event;
  final double strength;
  final double? velocity;
  final int? depth;
}

final glassHapticsProvider = Provider<GlassHaptics>((ref) {
  final h = GlassHaptics(haptics: ref.watch(skinHapticsProvider));
  ref.onDispose(h.dispose);
  return h;
});
