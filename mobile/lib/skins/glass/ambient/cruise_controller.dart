import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/reader/engine/auto_scroll_controller.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine.dart';
import 'package:manhwamaniacs/skins/glass/ambient/cruise.dart';

/// What cruise drives: the manga strip's engine or the novel's scroll column. The controller never moves a page itself.
abstract interface class CruiseSource {
  /// Fires whenever running, the touch pauses or the scroll velocity change.
  Listenable get changes;
  bool get running;

  /// The ramp, the touch pauses and the resume delay live here.
  AutoScrollController get autoScroll;

  /// Forward px/s of a coasting scroll (positive while reading forward).
  double get scrollVelocity;

  /// A flick that engages cruise (manga only): the multiplier it took.
  Stream<double> get engaged;
  void armEngage();
  void start(double speed, Duration ramp);
  void setSpeed(double speed);
  void stop();
}

/// The manga strip: 60 px/s x m through the engine's `startAutoScroll`.
class EngineCruiseSource implements CruiseSource {
  EngineCruiseSource(this.engine);
  final ReaderEngine engine;

  @override
  Listenable get changes => Listenable.merge([engine, engine.autoScroll]);
  @override
  bool get running => engine.value.autoScrolling;
  @override
  AutoScrollController get autoScroll => engine.autoScroll;
  @override
  double get scrollVelocity => engine.value.scrollVelocity;
  @override
  Stream<double> get engaged => engine.cruiseEngagedEvents.map((e) => e.multiplier);
  @override
  void armEngage() => engine.engageFromVelocity();
  @override
  void start(double speed, Duration ramp) => engine.startAutoScroll(mangaPxPerSecond(speed), ramp: ramp);
  @override
  void setSpeed(double speed) => engine.setAutoScrollPxPerSecond(mangaPxPerSecond(speed));
  @override
  void stop() {
    if (engine.value.autoScrolling) engine.toggleAutoScroll();
  }
}

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
  CruiseSource? _source;
  void Function(double speed)? _persist;
  bool Function() _reduced = () => false;
  StreamSubscription<double>? _engaged;
  bool _engageArmed = false;

  @override
  CruiseState build() {
    ref.onDispose(_detach);
    return const CruiseState();
  }

  /// Binds the open reader. [speed] is the series' saved value; [persist] saves a new one for this series.
  void attach(CruiseSource source, {required double speed, required void Function(double) persist, required bool Function() reduced}) {
    _detach();
    _source = source;
    _persist = persist;
    _reduced = reduced;
    source.changes.addListener(_onEngine);
    _engaged = source.engaged.listen((m) {
      if (_reduced()) return;
      state = state.copyWith(speed: speed = snapSpeed(m));
      _persist?.call(state.speed);
    });
    state = CruiseState(speed: speed);
    _apply();
  }

  void _detach() {
    final e = _source;
    if (e != null) {
      e.changes.removeListener(_onEngine);
      e.stop();
    }
    _engaged?.cancel();
    _engaged = null;
    _source = null;
  }

  double snapSpeed(double v) => settle(v);

  bool get running => state.running;

  /// The saved speed changed elsewhere (the settings slider): follow it.
  void follow(double speed) {
    if (speed == state.speed) return;
    state = state.copyWith(speed: speed);
    if (state.running) _source?.setSpeed(speed);
  }

  void start() {
    final e = _source;
    if (e == null || state.running) return;
    final reduced = _reduced();
    e.autoScroll.configure(resumeAfterRelease: !reduced);
    e.start(state.speed, reduced ? Duration.zero : Cruise.ramp);
  }

  void stop() {
    _source?.stop();
  }

  void toggle() => state.running ? stop() : start();

  /// A tap on the pill while paused (Reduce Motion, or after a touch) resumes at speed.
  void resume() => _source?.autoScroll.clearPause();

  /// Live while dragging: applies at once, no ramp.
  void preview(double v) {
    if (v == state.speed) return;
    state = state.copyWith(speed: v);
    if (state.running) _source?.setSpeed(v);
  }

  /// A release: persist for this series.
  void commit(double v) {
    preview(v);
    _persist?.call(v);
  }

  void step(double by) => commit(settle(clampSpeed(state.speed + by)));

  void _apply() {
    final e = _source;
    if (e == null) return;
    final running = e.running;
    final ac = e.autoScroll;
    final next = state.copyWith(running: running, paused: running && !ac.moving);
    if (next != state) state = next;
    if (!running) {
      _engageArmed = false;
      return;
    }
    if (_reduced()) return;
    final v = e.scrollVelocity;
    if (ac.dragged && !ac.touching) {
      if (v > Cruise.engageBelowPxPerS && !_engageArmed) {
        _engageArmed = true;
        e.armEngage();
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
