import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/novels/utils/sleep_timer.dart';

void main() {
  late List<double> volumes;
  late int fadeStarts, pauses;
  late SleepTimer timer;

  SleepTimer make() => SleepTimer(
        setVolume: volumes.add,
        pause: () async => pauses++,
        onFadeStart: () => fadeStarts++,
      );

  setUp(() {
    volumes = [];
    fadeStarts = pauses = 0;
    timer = make();
  });

  test('parse maps stored spellings', () {
    expect(SleepChoice.parse('off'), SleepChoice.off);
    expect(SleepChoice.parse('15'), SleepChoice.minutes(15));
    expect(SleepChoice.parse('chapter'), SleepChoice.endOfChapter);
    expect(SleepChoice.parse('nextChapter'), SleepChoice.endOfNextChapter);
    expect(SleepChoice.parse('bogus'), SleepChoice.off);
    expect(SleepChoice.minutes(999).minutes, 180);
    expect(SleepChoice.minutes(0).minutes, 1);
  });

  test('counts down live, fades the last 8 s, then pauses and restores', () {
    fakeAsync((async) {
      timer.set(SleepChoice.minutes(1));
      expect(timer.state.value.countdown, '1:00');
      async.elapse(const Duration(seconds: 30));
      expect(timer.state.value.countdown, '0:30');
      expect(fadeStarts, 0);
      async.elapse(const Duration(seconds: 21)); // 9 s left
      expect(fadeStarts, 0);
      async.elapse(const Duration(seconds: 2)); // 7 s left
      expect(fadeStarts, 1);
      expect(timer.state.value.fading, isTrue);
      expect(volumes.last, closeTo(7 / 8, 0.02));
      async.elapse(const Duration(seconds: 7));
      async.flushMicrotasks();
      expect(pauses, 1);
      expect(volumes.last, 1);
      expect(timer.state.value.armed, isFalse);
      expect(fadeStarts, 1);
    });
  });

  test('extend adds five minutes and cancels the fade', () {
    fakeAsync((async) {
      timer.set(SleepChoice.minutes(1));
      async.elapse(const Duration(seconds: 55));
      expect(timer.state.value.fading, isTrue);
      expect(timer.state.value.inLastMinute, isTrue);
      expect(timer.extend(), isTrue);
      expect(timer.state.value.fading, isFalse);
      expect(volumes.last, 1);
      expect(timer.state.value.countdown, '5:05');
      expect(timer.state.value.inLastMinute, isFalse);
    });
  });

  test('extend is a no-op without a running minutes timer', () {
    expect(timer.extend(), isFalse);
    timer.set(SleepChoice.endOfChapter);
    expect(timer.extend(), isFalse);
  });

  test('end of chapter stops at the boundary once', () {
    timer.set(SleepChoice.endOfChapter);
    expect(timer.onChapterBoundary(), SleepBoundary.stop);
    expect(timer.onChapterBoundary(), SleepBoundary.proceed);
  });

  test('end of next chapter lets one boundary pass', () {
    timer.set(SleepChoice.endOfNextChapter);
    expect(timer.onChapterBoundary(), SleepBoundary.proceed);
    expect(timer.onChapterBoundary(), SleepBoundary.stop);
    expect(timer.onChapterBoundary(), SleepBoundary.proceed);
  });

  test('a minutes timer ignores boundaries and cancel disarms', () {
    fakeAsync((async) {
      timer.set(SleepChoice.minutes(5));
      expect(timer.onChapterBoundary(), SleepBoundary.proceed);
      timer.cancel();
      expect(timer.state.value.armed, isFalse);
      async.elapse(const Duration(minutes: 6));
      expect(pauses, 0);
    });
  });
}
