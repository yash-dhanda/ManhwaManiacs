import 'dart:async';

/// The bulk bucket of `POST /reader/chapters/manifest`: 6 request starts per 60 s, a sliding
/// window (a slot frees a window after the start that took it). A 429 pauses every start for its
/// `Retry-After`. Used by the read-all feed so it never starts a seventh batch inside 60 s.
class BulkLimiter {
  BulkLimiter({
    this.capacity = 6,
    this.window = const Duration(seconds: 60),
    DateTime Function()? now,
    Timer Function(Duration, void Function())? createTimer,
  })  : _now = now ?? DateTime.now,
        _timer = createTimer ?? Timer.new;

  final int capacity;
  final Duration window;
  final DateTime Function() _now;
  final Timer Function(Duration, void Function()) _timer;
  final List<DateTime> _starts = [];
  final List<Completer<void>> _waiters = [];
  DateTime? _pausedUntil;
  Timer? _wake;

  /// Until when a 429 holds every start, or null.
  DateTime? get pausedUntil {
    final p = _pausedUntil;
    return p != null && _now().isBefore(p) ? p : null;
  }

  int get free {
    _prune();
    return capacity - _starts.length;
  }

  void _prune() {
    final t = _now();
    _starts.removeWhere((s) => t.difference(s) >= window);
  }

  /// Completes when a start is allowed, and records it.
  Future<void> acquire() {
    final c = Completer<void>();
    _waiters.add(c);
    _pump();
    return c.future;
  }

  /// A 429: hold every start for [retryAfter].
  void pause(Duration retryAfter) {
    final until = _now().add(retryAfter);
    if (_pausedUntil == null || until.isAfter(_pausedUntil!)) _pausedUntil = until;
    _pump();
  }

  void _pump() {
    _wake?.cancel();
    _wake = null;
    while (_waiters.isNotEmpty && pausedUntil == null && free > 0) {
      _starts.add(_now());
      _waiters.removeAt(0).complete();
    }
    if (_waiters.isEmpty) return;
    final t = _now();
    Duration d;
    if (pausedUntil != null) {
      d = pausedUntil!.difference(t);
    } else {
      d = _starts.first.add(window).difference(t);
    }
    _wake = _timer(d.isNegative ? Duration.zero : d, _pump);
  }

  void dispose() {
    _wake?.cancel();
    _waiters.clear();
  }
}
