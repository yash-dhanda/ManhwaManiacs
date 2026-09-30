import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/cinematic/flight.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// Copy i's progress at [t] of a flight of [n]: its 480 ms interval starts at i x 60 ms
/// (`Interval` on the whole clock, curve `turn`).
double flightProgress(int i, int n, double t) {
  final total = flightDuration(n).inMilliseconds.toDouble();
  final a = i * 60 / total, b = (i * 60 + 480) / total;
  return CineCurves.turn.transform(((t - a) / (b - a)).clamp(0.0, 1.0));
}

/// The copies in flight, above the Navigator so they survive the `/welcome` to `/` swap (mounted
/// once in the skin's app builder). Ignores pointers. Fail-safe: 3000 ms after `arm()` without a
/// `land()` the copies fade out over 240 ms and the layer resets.
class FlightLayer extends ConsumerStatefulWidget {
  const FlightLayer({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<FlightLayer> createState() => _FlightLayerState();
}

class _FlightLayerState extends ConsumerState<FlightLayer> with TickerProviderStateMixin {
  late final AnimationController _fly;
  late final AnimationController _fade;
  Timer? _failSafe;
  List<FlightItem> _held = const [];
  Map<String, Rect> _targets = const {};
  Set<String> _landed = {};
  bool _fading = false;

  @override
  void initState() {
    super.initState();
    _fly = AnimationController(vsync: this);
    _fade = AnimationController(vsync: this, duration: const Duration(milliseconds: 240));
  }

  @override
  void dispose() {
    _failSafe?.cancel();
    _fly.dispose();
    _fade.dispose();
    _release();
    super.dispose();
  }

  void _release() {
    for (final i in _held) {
      i.image.dispose();
    }
    _held = const [];
  }

  void _onState(FlightState? prev, FlightState next) {
    if (next.status == FlightStatus.armed && prev?.status != FlightStatus.armed) {
      _release();
      // The notifier owns no image lifetime; the layer clones so both can dispose independently.
      _held = [for (final i in next.items) FlightItem(key: i.key, image: i.image.clone(), rect: i.rect)];
      _targets = const {};
      _landed = {};
      _fading = false;
      _fade.value = 0;
      _failSafe?.cancel();
      _failSafe = Timer(const Duration(milliseconds: 3000), _abort);
      setState(() {});
    } else if (next.status == FlightStatus.flying && prev?.status == FlightStatus.armed) {
      _failSafe?.cancel();
      _targets = next.targets;
      final d = flightDuration(_held.length);
      final h = CineMotion.track(MotionName.cutToHome, d.inMilliseconds);
      _fly.duration = d;
      _fly.addListener(_tick);
      _fly.forward(from: 0).whenComplete(() {
        h.end();
        _fly.removeListener(_tick);
        if (!mounted) return;
        ref.read(cineFlightProvider.notifier).done();
        setState(_release);
      });
    } else if (next.status == FlightStatus.idle && prev?.status != FlightStatus.idle && !_fading) {
      _failSafe?.cancel();
      _release();
      setState(() {});
    }
  }

  void _tick() {
    final n = _held.length;
    for (var i = 0; i < n; i++) {
      final k = _held[i].key;
      if (!_landed.contains(k) && _fly.value * flightDuration(n).inMilliseconds >= i * 60 + 480) {
        _landed.add(k);
        ref.read(cineFlightProvider.notifier).landedOne(k);
      }
    }
    setState(() {});
  }

  Future<void> _abort() async {
    if (!mounted || ref.read(cineFlightProvider).status != FlightStatus.armed) return;
    setState(() => _fading = true);
    await _fade.forward(from: 0);
    if (!mounted) return;
    _release();
    ref.read(cineFlightProvider.notifier).reset();
    setState(() => _fading = false);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<FlightState>(cineFlightProvider, _onState);
    final n = _held.length;
    final flying = ref.read(cineFlightProvider).status == FlightStatus.flying;
    return Stack(textDirection: TextDirection.ltr, children: [
      Positioned.fill(child: widget.child),
      if (n > 0)
        Positioned.fill(
          child: IgnorePointer(
            child: Stack(children: [
              for (var i = 0; i < n; i++) _copy(i, n, flying),
            ],),
          ),
        ),
    ],);
  }

  Widget _copy(int i, int n, bool flying) {
    final item = _held[i];
    if (_landed.contains(item.key) && flying) return const SizedBox.shrink();
    var rect = item.rect;
    var opacity = 1.0;
    final target = _targets[item.key];
    if (flying && target != null) {
      final p = flightProgress(i, n, _fly.value);
      rect = Rect.lerp(item.rect, target, p)!;
      // A slot beyond the rail's visible edge fades over its last 160 ms.
      if (target.left >= MediaQuery.sizeOf(context).width - 1) {
        final total = flightDuration(n).inMilliseconds;
        final endMs = i * 60 + 480;
        final nowMs = _fly.value * total;
        opacity = ((endMs - nowMs) / 160).clamp(0.0, 1.0);
      }
    }
    if (_fading) opacity *= 1 - CineCurves.lift.transform(_fade.value);
    return Positioned.fromRect(rect: rect, child: Opacity(opacity: opacity, child: RawImage(image: item.image, fit: BoxFit.cover)));
  }
}
