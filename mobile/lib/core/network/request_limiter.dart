import 'dart:async';
import 'dart:collection';
import 'dart:io' show HttpDate;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// P0 visible reader page and the next; P1 user-initiated lists; P2 covers in
/// view; P3 prefetch. P0 and P1 never wait, they only record a start.
enum RequestPriority { p0, p1, p2, p3 }

class LimiterTicket {
  LimiterTicket._(this.priority, this.startedAt);
  final RequestPriority priority;
  final DateTime startedAt;
  bool _ended = false;
}

/// Thrown from [RequestLimiter.acquire] when its `cancel` future completed first.
class LimiterCancelled implements Exception {
  @override
  String toString() => 'LimiterCancelled';
}

/// Parses a `Retry-After` value: delta seconds or an HTTP date.
Duration? parseRetryAfter(String? v, {DateTime? now}) {
  if (v == null) return null;
  final s = int.tryParse(v.trim());
  if (s != null) return Duration(seconds: s < 0 ? 0 : s);
  try {
    final d = HttpDate.parse(v).difference(now ?? DateTime.now());
    return d.isNegative ? Duration.zero : d;
  } catch (_) {
    return null;
  }
}

/// The sources bucket limiter (cinematic 15.6): a sliding window of start times
/// (each slot frees `window` after the request that took it, never a refilling
/// bucket), P2 before P3, first come first served within a priority.
class RequestLimiter {
  RequestLimiter({
    this.capacity = 50,
    this.window = const Duration(seconds: 60),
    this.p3MinFree = 20,
    this.p3MaxInFlight = 2,
    DateTime Function()? now,
    Timer Function(Duration, void Function())? createTimer,
  })  : _now = now ?? DateTime.now,
        _createTimer = createTimer ?? Timer.new;

  final int capacity;
  final Duration window;
  final int p3MinFree;
  final int p3MaxInFlight;
  final DateTime Function() _now;
  final Timer Function(Duration, void Function()) _createTimer;

  final List<LimiterTicket> _starts = [];
  final Queue<_Waiter> _p2 = Queue();
  final Queue<_Waiter> _p3 = Queue();
  int _p3InFlight = 0;
  DateTime? _pausedUntil;
  Timer? _wake;

  void _prune() {
    final t = _now();
    _starts.removeWhere((s) => t.difference(s.startedAt) >= window);
  }

  int free() {
    _prune();
    final f = capacity - _starts.length;
    return f < 0 ? 0 : f;
  }

  bool get _paused => _pausedUntil != null && _now().isBefore(_pausedUntil!);

  LimiterTicket _start(RequestPriority p) {
    final t = LimiterTicket._(p, _now());
    _starts.add(t);
    if (p == RequestPriority.p3) _p3InFlight++;
    return t;
  }

  Future<LimiterTicket> acquire(RequestPriority p, {Future<void>? cancel}) {
    if (p == RequestPriority.p0 || p == RequestPriority.p1) return Future.value(_start(p));
    final w = _Waiter(p);
    (p == RequestPriority.p2 ? _p2 : _p3).add(w);
    cancel?.then((_) {
      if (w.done) return;
      w.done = true;
      (p == RequestPriority.p2 ? _p2 : _p3).remove(w);
      w.completer.completeError(LimiterCancelled());
      _pump();
    });
    _pump();
    return w.completer.future;
  }

  void _pump() {
    _wake?.cancel();
    _wake = null;
    while (true) {
      if (_paused) break;
      if (_p2.isNotEmpty && free() >= 1) {
        final w = _p2.removeFirst()..done = true;
        w.completer.complete(_start(w.priority));
      } else if (_p3.isNotEmpty && free() >= p3MinFree && _p3InFlight < p3MaxInFlight) {
        final w = _p3.removeFirst()..done = true;
        w.completer.complete(_start(w.priority));
      } else {
        break;
      }
    }
    if (_p2.isEmpty && _p3.isEmpty) return;
    // Sleep until the next time the answer can change: the pause ends or the
    // oldest start leaves the window. A P3 in-flight slot wakes us via release().
    final t = _now();
    Duration? d;
    if (_paused) {
      d = _pausedUntil!.difference(t);
    } else if (_starts.isNotEmpty) {
      d = _starts.first.startedAt.add(window).difference(t);
    }
    if (d != null) {
      _wake = _createTimer(d.isNegative ? Duration.zero : d, _pump);
    }
  }

  void release(LimiterTicket t) {
    if (t._ended) return;
    t._ended = true;
    if (t.priority == RequestPriority.p3) _p3InFlight--;
    _pump();
  }

  /// A response served from a local cache costs nothing.
  void refund(LimiterTicket t) {
    _starts.remove(t);
    release(t);
  }

  void pause(Duration d) {
    final until = _now().add(d);
    if (_pausedUntil == null || until.isAfter(_pausedUntil!)) _pausedUntil = until;
    _pump();
  }

  Future<T> run<T>(RequestPriority p, Future<T> Function() task, {Future<void>? cancel}) async {
    var retried = false;
    while (true) {
      final t = await acquire(p, cancel: cancel);
      try {
        return await task();
      } on DioException catch (e) {
        if (e.response?.statusCode != 429) rethrow;
        final d = parseRetryAfter(e.response?.headers.value('retry-after'), now: _now()) ?? const Duration(seconds: 12);
        pause(d);
        if (p != RequestPriority.p0 || retried) rethrow;
        retried = true;
        final c = Completer<void>();
        _createTimer(d, c.complete);
        await c.future;
      } finally {
        release(t);
      }
    }
  }
}

class _Waiter {
  _Waiter(this.priority);
  final RequestPriority priority;
  final Completer<LimiterTicket> completer = Completer();
  bool done = false;
}

final sourcesLimiterProvider = Provider<RequestLimiter>((ref) => RequestLimiter());
