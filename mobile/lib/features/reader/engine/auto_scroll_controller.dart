import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:manhwamaniacs/features/reader/engine/auto_scroll_model.dart';

/// The auto-scroll behaviour on top of the engine's `autoScrollEnabled` / speed: the 400 ms ramp,
/// pace by dialogue, touch and drag interruption. Skin-neutral: durations and curves come from the
/// skin through [configure]. Both the manga strip and the novel scroll layout drive it.
class AutoScrollController extends ChangeNotifier {
  AutoScrollController() : _ramp = RateRamp(ramp: const Duration(milliseconds: 400), curve: _linear);

  static double _linear(double t) => t;

  RateRamp _ramp;
  Duration resumeDelay = const Duration(milliseconds: 800);
  bool resumeAfterRelease = true;
  bool paceByDialogue = false;
  int? _words;
  bool _touching = false;
  bool _held = false; // paused by a touch that has not been released yet or a manual drag
  bool _userPaused = false; // paused with the chip / `p`
  Timer? _resume;
  bool _paceApplied = false;

  /// Sets the ramp the skin uses for every change of the effective speed.
  void configure({Duration? ramp, double Function(double t)? curve, bool? resumeAfterRelease, bool? paceByDialogue}) {
    if (ramp != null || curve != null) {
      final rate = _ramp.rate;
      _ramp = RateRamp(ramp: ramp ?? _ramp.ramp, curve: curve ?? _ramp.curve, initial: rate);
    }
    if (resumeAfterRelease != null) this.resumeAfterRelease = resumeAfterRelease;
    if (paceByDialogue != null && paceByDialogue != this.paceByDialogue) {
      this.paceByDialogue = paceByDialogue;
      _notify();
    }
  }

  /// Words on screen (null when the chapter has no dialogue text).
  void setWords(int? words) {
    if (words == _words) return;
    _words = words;
    _notify();
  }

  /// A pace factor applies only when pace by dialogue is on and the chapter has dialogue text.
  double get paceFactorNow => paceByDialogue && _words != null ? paceFactor(_words!) : 1.0;
  bool get paced => paceByDialogue && _words != null;

  bool get userPaused => _userPaused;
  bool get touching => _touching;

  /// A manual drag paused auto-scroll and it stays paused until [resumeAfterMomentum] or the user resumes.
  bool get dragged => _dragged;

  /// Glass cruise (glass 9.4.1): the momentum of a flick settled, so the drag latch lifts and the normal resume delay runs.
  void resumeAfterMomentum() {
    if (!_dragged || _touching) return;
    _dragged = false;
    _scheduleResume();
  }

  bool get held => _held;
  bool get moving => !_userPaused && !_held;

  /// The chip / `p`: running <-> paused.
  void togglePause() {
    _userPaused = !_userPaused;
    if (_userPaused) _ramp.retargetImmediate(0);
    _notify();
  }

  void clearPause() {
    if (!_userPaused && !_held) return;
    _userPaused = false;
    _held = false;
    _resume?.cancel();
    _notify();
  }

  /// A finger went down: pause at once.
  void touchDown() {
    _touching = true;
    _resume?.cancel();
    if (!_held) {
      _held = true;
      _ramp.retargetImmediate(0);
      _notify();
    }
  }

  /// The finger lifted: resume after [resumeDelay] when "Resume after I let go" is on.
  void touchUp() {
    _touching = false;
    if (_dragged) return;
    _scheduleResume();
  }

  bool _dragged = false;

  /// A manual drag scroll pauses and stays paused until the user resumes.
  void manualDrag() {
    _dragged = true;
    _resume?.cancel();
    if (!_held) {
      _held = true;
      _ramp.retargetImmediate(0);
      _notify();
    }
  }

  void _scheduleResume() {
    _resume?.cancel();
    if (!resumeAfterRelease) return;
    _resume = Timer(resumeDelay, () {
      if (_touching || _dragged) return;
      _held = false;
      _notify();
    });
  }

  /// Back to a clean state (auto-scroll turned off / restarted).
  void reset({bool notify = true}) {
    _resume?.cancel();
    final changed = _held || _dragged || _userPaused || _words != null;
    _touching = false;
    _held = false;
    _dragged = false;
    _userPaused = false;
    _ramp.retargetImmediate(0);
    if (notify && changed) _notify();
  }

  /// A fresh start: clears pauses and drags.
  void start() {
    _dragged = false;
    clearPause();
  }

  /// Pixels to advance this frame. [basePxPerSecond] is the rate at the chosen speed (before pace);
  /// long frames are clamped so dropped frames never change the pace.
  double advance(Duration dt, double basePxPerSecond) {
    final clamped = dt > const Duration(milliseconds: 100) ? const Duration(microseconds: 16667) : dt;
    final target = moving ? basePxPerSecond * paceFactorNow : 0.0;
    _ramp.retarget(target);
    final px = _ramp.advance(clamped);
    _paceApplied = paceFactorNow < 1.0;
    return px;
  }

  bool get paceApplied => _paceApplied;
  double get currentRate => _ramp.rate;

  void _notify() {
    if (hasListeners) notifyListeners();
  }

  @override
  void dispose() {
    _resume?.cancel();
    super.dispose();
  }
}
