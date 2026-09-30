import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/network/bulk_limiter.dart';

void main() {
  test('never starts a seventh inside 60 s; frees a slot a window after its start', () async {
    var t = DateTime(2026);
    final wakes = <void Function()>[];
    final l = BulkLimiter(now: () => t, createTimer: (d, f) {
      wakes.add(f);
      return _FakeTimer();
    });
    var granted = 0;
    for (var i = 0; i < 7; i++) {
      // ignore: unawaited_futures
      l.acquire().then((_) => granted++);
    }
    await Future<void>.delayed(Duration.zero);
    expect(granted, 6);
    t = t.add(const Duration(seconds: 59));
    for (final w in List.of(wakes)) {
      w();
    }
    await Future<void>.delayed(Duration.zero);
    expect(granted, 6);
    t = t.add(const Duration(seconds: 1));
    for (final w in List.of(wakes)) {
      w();
    }
    await Future<void>.delayed(Duration.zero);
    expect(granted, 7);
  });

  test('a 429 pauses starts for Retry-After', () async {
    var t = DateTime(2026);
    final wakes = <void Function()>[];
    final l = BulkLimiter(now: () => t, createTimer: (d, f) {
      wakes.add(f);
      return _FakeTimer();
    });
    l.pause(const Duration(seconds: 30));
    expect(l.pausedUntil, isNotNull);
    var granted = false;
    // ignore: unawaited_futures
    l.acquire().then((_) => granted = true);
    await Future<void>.delayed(Duration.zero);
    expect(granted, isFalse);
    t = t.add(const Duration(seconds: 30));
    for (final w in List.of(wakes)) {
      w();
    }
    await Future<void>.delayed(Duration.zero);
    expect(granted, isTrue);
    expect(l.pausedUntil, isNull);
  });
}

class _FakeTimer implements Timer {
  @override
  void cancel() {}
  @override
  bool get isActive => true;
  @override
  int get tick => 0;
}
