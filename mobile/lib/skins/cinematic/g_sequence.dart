import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart';

/// `g 1`..`g 12` / `g 0` targets (cinematic 8.0.6).
const Map<int, String> gTargets = {
  1: '/',
  2: '/library',
  3: '/updates',
  4: '/search',
  5: '/downloads',
  6: '/library/collections',
  7: '/library/history',
  8: '/library/bookmarks',
  9: '/ocr',
  10: '/library/statistics',
  11: '/circle',
  12: '/library/recommendations',
  0: '/settings',
};

const int kGArmMs = 1500;
const int kGOneWaitMs = 600;

enum GPhase { idle, armed, one }

sealed class GEffect {
  const GEffect();
}

/// The key is not the sequence's.
class GIgnored extends GEffect {
  const GIgnored();
}

/// The sequence swallowed the key and is still (or newly) armed.
class GConsumed extends GEffect {
  const GConsumed();
}

/// The sequence ended without a jump.
class GCancelled extends GEffect {
  const GCancelled({required this.consumed});
  final bool consumed;
}

class GJump extends GEffect {
  const GJump(this.number);
  final int number;
}

/// The pure state machine: `g` arms for 1500 ms; `g 2`..`g 9` and `g 0` jump at once; `g 1` waits
/// 600 ms for `0`, `1` or `2` (10, 11, 12) and otherwise jumps to 01; `Enter` jumps to 01 at once;
/// any other key, `Esc` or the timeout cancels. Time is passed in, so tests need no clock.
class GSequenceMachine {
  GSequenceMachine({this.novelsMode = false});

  /// In novels mode `g 9` (Dialogue) cancels.
  bool novelsMode;

  GPhase phase = GPhase.idle;
  int _at = 0;

  /// `G _` while armed, `G 1_` after the one.
  String? get chip => switch (phase) {
        GPhase.idle => null,
        GPhase.armed => 'G _',
        GPhase.one => 'G 1_',
      };

  /// Milliseconds after which [tick] does something, or null while idle.
  int? get deadlineMs => switch (phase) {
        GPhase.idle => null,
        GPhase.armed => _at + kGArmMs,
        GPhase.one => _at + kGOneWaitMs,
      };

  GEffect tick(int nowMs) {
    final d = deadlineMs;
    if (d == null || nowMs < d) return const GIgnored();
    final was = phase;
    phase = GPhase.idle;
    return was == GPhase.one ? const GJump(1) : const GCancelled(consumed: false);
  }

  /// [key] is `g`, a digit `0`..`9`, `enter`, `escape` or anything else (`other`).
  ///
  /// Callers run [tick] first: an expired wait is settled before the key is read.
  GEffect key(String key, int nowMs) {
    switch (phase) {
      case GPhase.idle:
        if (key == 'g') {
          phase = GPhase.armed;
          _at = nowMs;
          return const GConsumed();
        }
        return const GIgnored();
      case GPhase.armed:
        if (key == 'enter') return _end(const GJump(1));
        if (key == '1') {
          phase = GPhase.one;
          _at = nowMs;
          return const GConsumed();
        }
        final n = int.tryParse(key);
        if (n != null && key.length == 1) {
          if (n == 9 && novelsMode) return _end(const GCancelled(consumed: true));
          return _end(GJump(n));
        }
        return _end(const GCancelled(consumed: true));
      case GPhase.one:
        final n = int.tryParse(key);
        if (n != null && key.length == 1 && n <= 2) return _end(GJump(10 + n));
        return _end(const GCancelled(consumed: true));
    }
  }

  GEffect _end(GEffect e) {
    phase = GPhase.idle;
    return e;
  }

  void cancel() => phase = GPhase.idle;
}

/// Feeds the machine from one `HardwareKeyboard` handler. [enabled] says whether the sequence is
/// live right now (off in readers, while a text field has focus, and when single-key shortcuts
/// are off). [onJump] receives the target path; [onChange] the chip text for the frame.
class GSequenceController extends ChangeNotifier {
  GSequenceController({required this.enabled, required this.onJump, required this.novelsMode});

  final bool Function() enabled;
  final void Function(String path) onJump;
  final bool Function() novelsMode;

  final GSequenceMachine machine = GSequenceMachine();
  Timer? _timer;
  KeyEvent? _consumedEvent;
  bool _attached = false;
  int _now() => DateTime.now().millisecondsSinceEpoch;

  /// Kept on the chip for 160 ms after the sequence ends.
  String? chip;
  Timer? _chipFade;

  void attach() {
    if (_attached) return;
    _attached = true;
    HardwareKeyboard.instance.addHandler(_onKey);
    keyConsumers.add(consumes);
  }

  void detach() {
    if (!_attached) return;
    _attached = false;
    HardwareKeyboard.instance.removeHandler(_onKey);
    keyConsumers.remove(consumes);
    _timer?.cancel();
    _chipFade?.cancel();
  }

  /// True for the event the sequence just swallowed, so page bindings can skip it.
  bool consumes(KeyEvent e) =>
      _consumedEvent != null &&
      _consumedEvent!.logicalKey == e.logicalKey &&
      _consumedEvent!.timeStamp == e.timeStamp;

  static String? _label(KeyEvent e) {
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.keyG) return 'g';
    if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter) return 'enter';
    if (k == LogicalKeyboardKey.escape) return 'escape';
    final digits = [
      LogicalKeyboardKey.digit0, LogicalKeyboardKey.digit1, LogicalKeyboardKey.digit2, LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4, LogicalKeyboardKey.digit5, LogicalKeyboardKey.digit6, LogicalKeyboardKey.digit7,
      LogicalKeyboardKey.digit8, LogicalKeyboardKey.digit9,
    ];
    final i = digits.indexOf(k);
    return i >= 0 ? '$i' : 'other';
  }

  static bool _isModifier(LogicalKeyboardKey k) =>
      k == LogicalKeyboardKey.shiftLeft ||
      k == LogicalKeyboardKey.shiftRight ||
      k == LogicalKeyboardKey.controlLeft ||
      k == LogicalKeyboardKey.controlRight ||
      k == LogicalKeyboardKey.altLeft ||
      k == LogicalKeyboardKey.altRight ||
      k == LogicalKeyboardKey.metaLeft ||
      k == LogicalKeyboardKey.metaRight;

  bool _onKey(KeyEvent e) {
    if (e is! KeyDownEvent) return false;
    if (_isModifier(e.logicalKey)) return false;
    if (!enabled()) {
      if (machine.phase != GPhase.idle) _finish(null);
      return false;
    }
    final hw = HardwareKeyboard.instance;
    final chorded = hw.isControlPressed || hw.isMetaPressed || hw.isAltPressed || hw.isShiftPressed;
    machine.novelsMode = novelsMode();
    final now = _now();
    final expired = machine.tick(now);
    if (expired is GJump) _finish(expired.number);
    if (expired is GCancelled) _finish(null);
    var label = _label(e)!;
    if (chorded) label = 'other';
    return _apply(machine.key(label, now), e);
  }

  bool _apply(GEffect effect, KeyEvent e) {
    switch (effect) {
      case GIgnored():
        return false;
      case GConsumed():
        _consumedEvent = e;
        _arm();
        return true;
      case GCancelled(:final consumed):
        if (consumed) _consumedEvent = e;
        _finish(null);
        return consumed;
      case GJump(:final number):
        _consumedEvent = e;
        _finish(number);
        return true;
    }
  }

  void _arm() {
    chip = machine.chip;
    _chipFade?.cancel();
    _timer?.cancel();
    final d = machine.deadlineMs;
    if (d != null) _timer = Timer(Duration(milliseconds: d - _now() + 1), _expire);
    notifyListeners();
  }

  void _expire() {
    // The timer fires at the deadline: settle the machine at it, whatever the wall clock says.
    final effect = machine.tick(machine.deadlineMs ?? _now());
    switch (effect) {
      case GJump(:final number):
        _finish(number);
      case GCancelled():
        _finish(null);
      default:
        if (machine.phase != GPhase.idle) _arm();
    }
  }

  void _finish(int? number) {
    _timer?.cancel();
    machine.cancel();
    _chipFade?.cancel();
    _chipFade = Timer(const Duration(milliseconds: 160), () {
      chip = null;
      notifyListeners();
    });
    notifyListeners();
    if (number != null) {
      final path = gTargets[number];
      if (path != null) onJump(path);
    }
  }

  @override
  void dispose() {
    detach();
    super.dispose();
  }
}
