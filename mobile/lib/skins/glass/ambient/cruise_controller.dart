import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/reader/engine/cruise_engage.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine.dart';
import 'package:manhwamaniacs/skins/glass/ambient/cruise.dart';

/// What the cruise pill shows: the multiplier, whether the engine is auto-scrolling, whether a touch or a drag has it held.
class CruiseState {
  const CruiseState({this.speed = 1.0, this.running = false, this.paused = false});
  final double speed;
  final bool running, paused;

  CruiseState copyWith({double? speed, bool? running, bool? paused}) =>
      CruiseState(speed: speed ?? this.speed, running: running ?? this.running, paused: paused ?? this.paused);

  @override
  bool operator ==(Object other) => other is CruiseState && other.speed == speed && other.running == running && other.paused == paused;
  @override
  int get hashCode => Object.hash(speed, running, paused);
}

/// The open reader's cruise (glass 9.4.1). It owns no timing of its own: the engine's [AutoScrollController] does the 400 ms ramp
/// and the 800 ms resume, and this class sets the speed, arms flick-to-cruise, lifts the drag latch when the momentum settles,
/// saves the speed per series and turns everything off under Reduce Motion (glass 14.10).
class CruiseController extends AutoDisposeNotifier<CruiseState> {
  ReaderEngine? _engine;
  void Function(double speed)? _persist;
  bool Function() _reduced = () => false;
  StreamSubscription<CruiseEngaged>? _engaged;
  bool _engageArmed = false;

  @override
  CruiseState build() {
    ref.onDispose(_detach);
    return const CruiseState();
  }

  /// Binds the open reader. [speed] is the series' saved value; [persist] saves a new one for this series.
  void attach(ReaderEngine engine, {required double speed, required void Function(double) persist, required bool Function() reduced}) {
    _detach();
    _engine = engine;
    _persist = persist;
    _reduced = reduced;
    engine.addListener(_onEngine);
    engine.autoScroll.addListener(_onEngine);
    _engaged = engine.cruiseEngagedEvents.listen((e) {
      if (_reduced()) return;
      state = state.copyWith(speed: speed = snapSpeed(e.multiplier));
      _persist?.call(state.speed);
    });
    state = CruiseState(speed: speed);
    _apply();
  }

  void _detach() {
    final e = _engine;
    if (e != null) {
      e.removeListener(_onEngine);
      e.autoScroll.removeListener(_onEngine);
      if (e.value.autoScrolling) e.toggleAutoScroll();
    }
    _engaged?.cancel();
    _engaged = null;
    _engine = null;
  }

  double snapSpeed(double v) => settle(v);

  bool get running => state.running;

  /// The saved speed changed elsewhere (the settings slider): follow it.
  void follow(double speed) {
    if (speed == state.speed) return;
    state = state.copyWith(speed: speed);
    if (state.running) _engine?.setAutoScrollPxPerSecond(mangaPxPerSecond(speed));
  }

  void start() {
    final e = _engine;
    if (e == null || state.running) return;
    final reduced = _reduced();
    e.autoScroll.configure(resumeAfterRelease: !reduced);
    e.startAutoScroll(mangaPxPerSecond(state.speed), ramp: reduced ? Duration.zero : Cruise.ramp);
  }

  void stop() {
    final e = _engine;
    if (e == null || !e.value.autoScrolling) return;
    e.toggleAutoScroll();
  }

  void toggle() => state.running ? stop() : start();

  /// A tap on the pill while paused (Reduce Motion, or after a touch) resumes at speed.
  void resume() => _engine?.autoScroll.clearPause();

  /// Live while dragging: applies at once, no ramp.
  void preview(double v) {
    if (v == state.speed) return;
    state = state.copyWith(speed: v);
    if (state.running) _engine?.setAutoScrollPxPerSecond(mangaPxPerSecond(v));
  }

  /// A release: persist for this series.
  void commit(double v) {
    preview(v);
    _persist?.call(v);
  }

  void step(double by) => commit(settle(clampSpeed(state.speed + by)));

  void _apply() {
    final e = _engine;
    if (e == null) return;
    final running = e.value.autoScrolling;
    final ac = e.autoScroll;
    final next = state.copyWith(running: running, paused: running && !ac.moving);
    if (next != state) state = next;
    if (!running) {
      _engageArmed = false;
      return;
    }
    if (_reduced()) return;
    final v = e.value.scrollVelocity;
    if (ac.dragged && !ac.touching) {
      if (v > Cruise.engageBelowPxPerS && !_engageArmed) {
        _engageArmed = true;
        e.engageFromVelocity();
      } else if (v.abs() < Cruise.resumeBelowPxPerS) {
        _engageArmed = false;
        ac.resumeAfterMomentum();
      }
    } else if (ac.touching) {
      _engageArmed = false;
    }
  }

  void _onEngine() => _apply();
}

final cruiseControllerProvider = NotifierProvider.autoDispose<CruiseController, CruiseState>(CruiseController.new, name: 'glassCruise');
