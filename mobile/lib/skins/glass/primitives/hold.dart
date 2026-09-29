import 'dart:math' as math;

import 'package:flutter/painting.dart' show Offset;
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';

/// What the hold machine reports (glass 4.6, 7.1, 14.8).
sealed class HoldEvent {
  const HoldEvent();
}

/// A release before 200 ms within 8 px of movement.
class HoldClick extends HoldEvent {
  const HoldClick();
}

/// Moved 8 px or more before 200 ms, or the pointer was cancelled: no fill, and the release does nothing.
class HoldCancel extends HoldEvent {
  const HoldCancel();
}

/// The liquid fill begins (200 ms).
class HoldFillStart extends HoldEvent {
  const HoldFillStart();
}

/// `hold.ramp`, every 150 ms from the fill's start; intensity rises 0.2 to 0.8.
class HoldRamp extends HoldEvent {
  const HoldRamp(this.intensity);
  final double intensity;
}

/// A release after 200 ms and before completion: the fill drains from [level].
class HoldAborted extends HoldEvent {
  const HoldAborted(this.level);
  final double level;
}

/// 1,200 ms after pointer down.
class HoldDone extends HoldEvent {
  const HoldDone();
}

enum HoldPhase { idle, pending, filling, done, cancelled, aborted }

/// The hold-to-confirm state machine, pure and time-stamped in milliseconds, so it tests without a widget.
class HoldMachine {
  HoldMachine({
    this.startMs = 200,
    this.confirmMs = 1200,
    this.slop = 8,
    this.rampEveryMs = 150,
  });

  final double startMs;
  final double confirmMs;
  final double slop;
  final double rampEveryMs;

  HoldPhase _phase = HoldPhase.idle;
  double _downT = 0;
  Offset _downPos = Offset.zero;
  Offset _pos = Offset.zero;
  int _ramps = 0;

  HoldPhase get phase => _phase;
  bool get active => _phase == HoldPhase.pending || _phase == HoldPhase.filling;

  double get fillMs => confirmMs - startMs;

  void _reset() {
    _phase = HoldPhase.idle;
    _ramps = 0;
  }

  List<HoldEvent> down(double t, Offset pos) {
    _phase = HoldPhase.pending;
    _downT = t;
    _downPos = pos;
    _pos = pos;
    _ramps = 0;
    return const [];
  }

  List<HoldEvent> move(double t, Offset pos) {
    final out = tick(t);
    _pos = pos;
    if (_phase == HoldPhase.pending && (pos - _downPos).distance >= slop) {
      _phase = HoldPhase.cancelled;
      out.add(const HoldCancel());
    }
    return out;
  }

  List<HoldEvent> up(double t) {
    final out = tick(t);
    switch (_phase) {
      case HoldPhase.pending:
        if ((_pos - _downPos).distance < slop) out.add(const HoldClick());
        _reset();
      case HoldPhase.filling:
        out.add(HoldAborted(levelAt(t)));
        _phase = HoldPhase.aborted;
        _reset();
      case HoldPhase.done || HoldPhase.cancelled || HoldPhase.aborted || HoldPhase.idle:
        _reset();
    }
    return out;
  }

  /// A pointer cancel (a scroll took the gesture).
  List<HoldEvent> cancel() {
    final was = _phase;
    _reset();
    return was == HoldPhase.pending || was == HoldPhase.filling ? [const HoldCancel()] : [];
  }

  List<HoldEvent> tick(double t) {
    final out = <HoldEvent>[];
    final e = t - _downT;
    if (_phase == HoldPhase.pending && e >= startMs) {
      _phase = HoldPhase.filling;
      out.add(const HoldFillStart());
    }
    if (_phase == HoldPhase.filling) {
      final fe = e - startMs;
      while (_ramps * rampEveryMs <= fe && _ramps * rampEveryMs <= fillMs - 0.001) {
        out.add(HoldRamp(0.2 + 0.6 * (_ramps * rampEveryMs / fillMs).clamp(0.0, 1.0)));
        _ramps++;
      }
      if (e >= confirmMs) {
        _phase = HoldPhase.done;
        out.add(const HoldDone());
      }
    }
    return out;
  }

  /// The fill level 0..1 at [t]. [stepped] is the reduced-motion form: four 25 % increments, 250 ms apart.
  double levelAt(double t, {bool stepped = false}) {
    if (_phase == HoldPhase.done) return 1;
    final x = ((t - _downT - startMs) / fillMs).clamp(0.0, 1.0);
    if (!stepped) return x;
    return (math.min(x, 1.0) * 4).floor() / 4;
  }
}

/// The thresholds as the tokens carry them.
const double kHoldStartMs = GlassThresholds.holdStart;
const double kHoldConfirmMs = GlassThresholds.holdConfirm;
