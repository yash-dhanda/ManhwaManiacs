import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/novels/utils/listen_sessions.dart';

class _FakeTimer implements Timer {
  _FakeTimer(this.callback);
  final void Function() callback;
  bool cancelled = false;
  @override
  void cancel() => cancelled = true;
  @override
  bool get isActive => !cancelled;
  @override
  int get tick => 0;
}

void main() {
  late DateTime clock;
  late List<ClosedListenSession> closed;
  late List<_FakeTimer> timers;
  late ListenSessionTracker t;
  const ch1 = (sourceId: 's', seriesKey: 'b', chapterKey: 'c1');
  const ch2 = (sourceId: 's', seriesKey: 'b', chapterKey: 'c2');
  void wait(int s) => clock = clock.add(Duration(seconds: s));

  setUp(() {
    clock = DateTime.utc(2026, 9, 30, 12);
    closed = [];
    timers = [];
    t = ListenSessionTracker(
      onClosed: closed.add,
      now: () => clock,
      timer: (d, cb) {
        expect(d, kListenPauseClose);
        return _FakeTimer(cb)..also(timers.add);
      },
    );
  });

  test('play, a 30 s pause, then the timer closes one session with wall-clock seconds', () {
    t.play(ch1, voice: 'a');
    wait(40);
    t.voiceChanged('b');
    wait(20);
    t.pause();
    expect(closed, isEmpty);
    wait(30);
    timers.last.callback();
    expect(closed.length, 1);
    final s = closed.single;
    expect(s.seconds, 60);
    expect(s.voiceIds, ['a', 'b']);
    expect(s.startedAt, DateTime.utc(2026, 9, 30, 12));
    expect(s.toJson()['started_at'], '2026-09-30T12:00:00.000Z');
    expect(s.toJson()['chapter_key'], 'c1');
  });

  test('resuming inside the 30 s keeps one session and cancels the close', () {
    t.play(ch1);
    wait(15);
    t.pause();
    final pending = timers.last;
    wait(10);
    t.play(ch1);
    expect(pending.cancelled, isTrue);
    wait(15);
    t.close();
    expect(closed.single.seconds, 30);
  });

  test('a 7 s session produces no row', () {
    t.play(ch1);
    wait(7);
    t.close();
    expect(closed, isEmpty);
    expect(t.open, isFalse);
  });

  test('changing chapter closes the session; leaving closes too', () {
    t.play(ch1);
    wait(20);
    t.play(ch2);
    expect(closed.single.chapterKey, 'c1');
    wait(12);
    t.close();
    expect(closed.map((s) => s.chapterKey), ['c1', 'c2']);
  });

  test('voice_ids are the top three by played time', () {
    t.play(ch1, voice: 'a');
    wait(5);
    t.voiceChanged('b');
    wait(10);
    t.voiceChanged('c');
    wait(20);
    t.voiceChanged('d');
    wait(1);
    t.voiceChanged('a');
    wait(2);
    t.close();
    expect(closed.single.voiceIds, ['c', 'b', 'a']);
  });
}

extension<T> on T {
  void also(void Function(T) f) => f(this);
}
