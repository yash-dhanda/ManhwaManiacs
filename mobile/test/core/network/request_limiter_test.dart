// ignore_for_file: unawaited_futures
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/network/request_limiter.dart';

/// Manual clock plus timer queue: no real time anywhere.
class ManualClock {
  DateTime now = DateTime.utc(2026);
  final List<_T> _timers = [];

  Timer create(Duration d, void Function() f) {
    final t = _T(now.add(d), f);
    _timers.add(t);
    return t;
  }

  /// Advances time, firing due timers in order and flushing microtasks after each.
  Future<void> advance(Duration d) async {
    await pumpEventQueue();
    final end = now.add(d);
    while (true) {
      _timers.removeWhere((t) => t.cancelled);
      final due = _timers.where((t) => !t.at.isAfter(end)).toList()..sort((a, b) => a.at.compareTo(b.at));
      if (due.isEmpty) break;
      final t = due.first;
      _timers.remove(t);
      if (t.at.isAfter(now)) now = t.at;
      t.f();
      await pumpEventQueue();
    }
    now = end;
    await pumpEventQueue();
  }
}

class _T implements Timer {
  _T(this.at, this.f);
  final DateTime at;
  final void Function() f;
  bool cancelled = false;
  @override
  void cancel() => cancelled = true;
  @override
  bool get isActive => !cancelled;
  @override
  int get tick => 0;
}

DioException e429(String? retryAfter) => DioException(
      requestOptions: RequestOptions(path: '/sources/x'),
      response: Response(
        requestOptions: RequestOptions(path: '/sources/x'),
        statusCode: 429,
        headers: Headers.fromMap({if (retryAfter != null) 'retry-after': [retryAfter]}),
      ),
    );

void main() {
  late ManualClock clock;
  late RequestLimiter lim;
  setUp(() {
    clock = ManualClock();
    lim = RequestLimiter(now: () => clock.now, createTimer: clock.create);
  });

  Future<List<LimiterTicket>> fill(int n, [RequestPriority p = RequestPriority.p2]) async =>
      [for (var i = 0; i < n; i++) await lim.acquire(p)];

  test('50 starts leave free()==0 and the 51st P2 waits until the first is 60 s old', () async {
    await fill(50);
    expect(lim.free(), 0);
    var started = false;
    lim.acquire(RequestPriority.p2).then((_) => started = true);
    await clock.advance(const Duration(seconds: 59));
    expect(started, isFalse);
    await clock.advance(const Duration(seconds: 1));
    expect(started, isTrue);
  });

  test('P0 and P1 never wait, even at 0 free', () async {
    await fill(50);
    var got = 0;
    lim.acquire(RequestPriority.p0).then((_) => got++);
    lim.acquire(RequestPriority.p1).then((_) => got++);
    await pumpEventQueue();
    expect(got, 2);
  });

  test('P3 waits while free < 20 and while 2 P3 are in flight', () async {
    await fill(31); // free 19
    var started = false;
    lim.acquire(RequestPriority.p3).then((_) => started = true);
    await clock.advance(const Duration(seconds: 1));
    expect(started, isFalse);
    await clock.advance(const Duration(seconds: 60));
    expect(started, isTrue); // window emptied, free 50
    final a = await lim.acquire(RequestPriority.p3);
    var third = false;
    lim.acquire(RequestPriority.p3).then((_) => third = true);
    await pumpEventQueue();
    // in flight: first waiter + a = 2
    expect(third, isFalse);
    lim.release(a);
    await pumpEventQueue();
    expect(third, isTrue);
  });

  test('a 12 s pause holds P2 and P3 but not P0 or P1', () async {
    lim.pause(const Duration(seconds: 12));
    var p2 = false, p3 = false, p0 = false, p1 = false;
    lim.acquire(RequestPriority.p2).then((_) => p2 = true);
    lim.acquire(RequestPriority.p3).then((_) => p3 = true);
    lim.acquire(RequestPriority.p0).then((_) => p0 = true);
    lim.acquire(RequestPriority.p1).then((_) => p1 = true);
    await clock.advance(const Duration(seconds: 11));
    expect([p2, p3, p0, p1], [false, false, true, true]);
    await clock.advance(const Duration(seconds: 1));
    expect([p2, p3], [true, true]);
  });

  test('P2 is served before P3', () async {
    await fill(50);
    final order = <String>[];
    lim.acquire(RequestPriority.p3).then((_) => order.add('p3'));
    lim.acquire(RequestPriority.p2).then((_) => order.add('p2'));
    await clock.advance(const Duration(seconds: 60));
    expect(order.first, 'p2');
  });

  test('a P0 whose task throws 429 with Retry-After: 5 retries once after 5 s', () async {
    var calls = 0;
    final f = lim.run(RequestPriority.p0, () async {
      calls++;
      if (calls == 1) throw e429('5');
      return 'ok';
    });
    await pumpEventQueue();
    expect(calls, 1);
    await clock.advance(const Duration(seconds: 4));
    expect(calls, 1);
    await clock.advance(const Duration(seconds: 1));
    expect(await f, 'ok');
    expect(calls, 2);
  });

  test('a P0 that keeps failing 429 is retried only once', () async {
    var calls = 0;
    final f = lim.run(RequestPriority.p0, () async {
      calls++;
      throw e429('1');
    });
    final err = expectLater(f, throwsA(isA<DioException>()));
    await clock.advance(const Duration(seconds: 2));
    await err;
    expect(calls, 2);
  });

  test('refund frees the slot', () async {
    final ts = await fill(50);
    expect(lim.free(), 0);
    lim.refund(ts.first);
    expect(lim.free(), 1);
  });

  test('a cancelled waiter never starts', () async {
    await fill(50);
    final c = Completer<void>();
    Object? err;
    var started = false;
    lim.acquire(RequestPriority.p2, cancel: c.future).then((_) => started = true, onError: (Object e) {
      err = e;
      return false;
    },);
    c.complete();
    await clock.advance(const Duration(seconds: 61));
    expect(started, isFalse);
    expect(err, isA<LimiterCancelled>());
    expect(lim.free(), 50); // its slot was never taken
  });

  test('regression: no 60 s window holds more than 50 P2 starts across 99 attempts', () async {
    final starts = <DateTime>[];
    for (var i = 0; i < 99; i++) {
      lim.acquire(RequestPriority.p2).then((t) => starts.add(t.startedAt));
    }
    await clock.advance(const Duration(seconds: 200));
    expect(starts.length, 99);
    for (final s in starts) {
      final inWin = starts.where((t) => !t.isBefore(s) && t.difference(s) < const Duration(seconds: 60)).length;
      expect(inWin, lessThanOrEqualTo(50));
    }
  });

  test('parseRetryAfter reads seconds and HTTP dates', () {
    expect(parseRetryAfter('7'), const Duration(seconds: 7));
    expect(parseRetryAfter(null), isNull);
    expect(parseRetryAfter('nonsense'), isNull);
    final now = DateTime.utc(2026, 1, 1, 12);
    expect(parseRetryAfter('Thu, 01 Jan 2026 12:00:09 GMT', now: now), const Duration(seconds: 9));
  });
}
