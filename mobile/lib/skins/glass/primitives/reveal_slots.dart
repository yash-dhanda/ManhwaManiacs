import 'package:flutter/foundation.dart';

/// At most two letter reveals run at once (glass 15.7). A third heading that becomes visible waits and
/// starts when a running reveal ends, if it is still visible; otherwise it completes at once.
class RevealSlotQueue {
  RevealSlotQueue({this.max = 2});

  final int max;
  final Set<Object> _running = {};
  final List<(Object, VoidCallback)> _waiting = [];

  int get running => _running.length;
  int get waiting => _waiting.length;

  /// Runs [start] now when a slot is free (returning true); otherwise queues it.
  bool acquire(Object id, VoidCallback start) {
    if (_running.length < max) {
      _running.add(id);
      start();
      return true;
    }
    _waiting.add((id, start));
    return false;
  }

  /// A reveal ended: hand its slot to the next waiter.
  void release(Object id) {
    _running.remove(id);
    _drain();
  }

  /// The heading left the screen or was completed by a tap before its turn came.
  void withdraw(Object id) {
    _waiting.removeWhere((w) => w.$1 == id);
    if (_running.remove(id)) _drain();
  }

  void _drain() {
    while (_running.length < max && _waiting.isNotEmpty) {
      final next = _waiting.removeAt(0);
      _running.add(next.$1);
      next.$2();
    }
  }

  void reset() {
    _running.clear();
    _waiting.clear();
  }
}

/// The module-level queue every `LetterReveal` shares.
final RevealSlotQueue glassRevealSlots = RevealSlotQueue();

/// `n x 24 ms + 345 ms + 120 ms + 500 ms`: the letters, the last spring settling, the wait before the
/// glint, and the glint.
Duration revealDuration(int units, {int perUnitMs = 24}) => Duration(milliseconds: units * perUnitMs + 345 + 120 + 500);
