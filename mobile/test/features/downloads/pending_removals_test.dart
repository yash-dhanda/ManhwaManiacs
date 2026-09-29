import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/downloads/utils/pending_removals.dart';

class _Fake {
  final List<_FakeTimer> timers = [];
  Timer make(Duration d, void Function() f) {
    final t = _FakeTimer(f);
    timers.add(t);
    return t;
  }
}

class _FakeTimer implements Timer {
  _FakeTimer(this.f);
  final void Function() f;
  bool cancelled = false;
  bool fired = false;
  @override
  void cancel() => cancelled = true;
  @override
  bool get isActive => !cancelled && !fired;
  @override
  int get tick => 0;
  void fire() {
    if (cancelled) return;
    fired = true;
    f();
  }
}

void main() {
  test('expiry runs the removal and clears the pending flag', () async {
    final fake = _Fake();
    final p = PendingRemovals(timerFactory: fake.make);
    var ran = 0;
    p.schedule('a', () async => ran++);
    expect(p.isPending('a'), isTrue);
    fake.timers.single.fire();
    await Future<void>.delayed(Duration.zero);
    expect(ran, 1);
    expect(p.isPending('a'), isFalse);
  });

  test('undo cancels: nothing runs, the row stops reading REMOVING', () async {
    final fake = _Fake();
    final p = PendingRemovals(timerFactory: fake.make);
    var ran = 0;
    final h = p.schedule('a', () async => ran++);
    h.undo();
    expect(p.isPending('a'), isFalse);
    expect(fake.timers.single.cancelled, isTrue);
    fake.timers.single.fire();
    expect(ran, 0);
  });

  test('flushAll runs every pending removal at once', () async {
    final fake = _Fake();
    final p = PendingRemovals(timerFactory: fake.make);
    final ran = <String>[];
    p.schedule('a', () async => ran.add('a'));
    p.schedule('b', () async => ran.add('b'));
    await p.flushAll();
    expect(ran, ['a', 'b']);
    expect(p.keys, isEmpty);
    expect(fake.timers.every((t) => t.cancelled), isTrue);
  });

  test('a second schedule for the same key replaces the first', () async {
    final fake = _Fake();
    final p = PendingRemovals(timerFactory: fake.make);
    final ran = <int>[];
    final first = p.schedule('a', () async => ran.add(1));
    p.schedule('a', () async => ran.add(2));
    expect(fake.timers.first.cancelled, isTrue);
    first.undo(); // a stale handle must not cancel the replacement
    expect(p.isPending('a'), isTrue);
    fake.timers.last.fire();
    await Future<void>.delayed(Duration.zero);
    expect(ran, [2]);
  });

  test('the default delay is 8000 ms', () {
    Duration? seen;
    final p = PendingRemovals(timerFactory: (d, f) {
      seen = d;
      return _FakeTimer(f);
    },);
    p.schedule('a', () async {});
    expect(seen, const Duration(milliseconds: 8000));
  });
}
