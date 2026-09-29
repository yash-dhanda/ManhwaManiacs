import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// P0 user-blocking ... P3 background. See redesign DESIGN §15.6.
enum RequestPriority { p0, p1, p2, p3 }

/// The sources request limiter: a token bucket every source-facing request
/// passes through at its priority. P3 runs only while at least [p3Floor] tokens
/// remain and at most [p3InFlight] at a time; [pause] (a 429's Retry-After)
/// holds P2 and P3.
///
/// TODO(mobile/03): stand-in with the mobile/03 surface (`run` at a priority);
/// replace with the shared limiter when that step lands.
class RequestLimiter {
  RequestLimiter({
    this.capacity = 30,
    this.refillEvery = const Duration(milliseconds: 200),
    this.p3Floor = 20,
    this.p3InFlight = 2,
  }) : _tokens = capacity.toDouble();

  final int capacity;
  final Duration refillEvery;
  final int p3Floor;
  final int p3InFlight;

  double _tokens;
  int _p3Running = 0;
  DateTime _last = DateTime.now();
  DateTime? _pausedUntil;

  void pause(Duration d) => _pausedUntil = DateTime.now().add(d);

  void _refill() {
    final now = DateTime.now();
    _tokens = (_tokens +
            now.difference(_last).inMilliseconds / refillEvery.inMilliseconds)
        .clamp(0, capacity.toDouble());
    _last = now;
  }

  bool _canRun(RequestPriority p) {
    _refill();
    if (_tokens < 1) return false;
    if (p.index >= RequestPriority.p2.index) {
      final until = _pausedUntil;
      if (until != null && DateTime.now().isBefore(until)) return false;
    }
    if (p == RequestPriority.p3) {
      return _tokens >= p3Floor && _p3Running < p3InFlight;
    }
    return true;
  }

  Future<T> run<T>(
      RequestPriority priority, Future<T> Function() request,) async {
    while (priority != RequestPriority.p0 && !_canRun(priority)) {
      await Future<void>.delayed(refillEvery);
    }
    if (priority != RequestPriority.p0) _tokens -= 1;
    if (priority == RequestPriority.p3) _p3Running++;
    try {
      return await request();
    } finally {
      if (priority == RequestPriority.p3) _p3Running--;
    }
  }
}

final requestLimiterProvider =
    Provider<RequestLimiter>((ref) => RequestLimiter(), name: 'requestLimiter');
