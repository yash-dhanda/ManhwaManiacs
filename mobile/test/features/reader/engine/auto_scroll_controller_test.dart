import 'package:fake_async/fake_async.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/engine/auto_scroll_controller.dart';
import 'package:manhwamaniacs/features/reader/engine/auto_scroll_model.dart';

const _frame = Duration(microseconds: 16667);

double _run(AutoScrollController c, Duration d, double base) {
  var px = 0.0;
  for (var t = Duration.zero; t < d; t += _frame) {
    px += c.advance(_frame, base);
  }
  return px;
}

AutoScrollController _make() => AutoScrollController()
  ..configure(ramp: const Duration(milliseconds: 400), curve: const Cubic(0.16, 1, 0.3, 1).transform)
  ..start();

void main() {
  final base = mangaPxPerSecond(1.0, 844);

  test('1.00x at 844 px moves 46.9 px/s after the ramp', () {
    final c = _make();
    _run(c, const Duration(milliseconds: 500), base);
    final px = _run(c, const Duration(seconds: 3), base);
    expect(px / 3, closeTo(46.9, 1.0));
  });

  test('a speed step ramps without a jump in rate', () {
    final c = _make();
    _run(c, const Duration(seconds: 1), base);
    final before = c.currentRate;
    final first = c.advance(_frame, base * 1.25) / (_frame.inMicroseconds / 1e6);
    expect((first - before).abs(), lessThan(base * 0.25 * 0.5));
    _run(c, const Duration(milliseconds: 500), base * 1.25);
    expect(c.currentRate, closeTo(base * 1.25, 0.01));
  });

  test('pace by dialogue halves the rate for a 42-word screen', () {
    final c = _make()..configure(paceByDialogue: true);
    c.setWords(42);
    expect(c.paced, isTrue);
    _run(c, const Duration(milliseconds: 600), base);
    expect(c.currentRate, closeTo(base * 0.5, 0.01));
    c.setWords(null);
    expect(c.paced, isFalse);
  });

  test('a touch pauses; release resumes after 800 ms; a drag stays paused', () {
    fakeAsync((async) {
      final c = _make();
      _run(c, const Duration(seconds: 1), base);
      c.touchDown();
      expect(c.advance(_frame, base), 0);
      c.touchUp();
      async.elapse(const Duration(milliseconds: 700));
      expect(c.moving, isFalse);
      async.elapse(const Duration(milliseconds: 150));
      expect(c.moving, isTrue);
      c.touchDown();
      c.manualDrag();
      c.touchUp();
      async.elapse(const Duration(seconds: 3));
      expect(c.moving, isFalse);
      c.start();
      expect(c.moving, isTrue);
    });
  });

  test('resume after release off keeps it paused', () {
    fakeAsync((async) {
      final c = _make()..configure(resumeAfterRelease: false);
      c.touchDown();
      c.touchUp();
      async.elapse(const Duration(seconds: 2));
      expect(c.moving, isFalse);
    });
  });

  test('chip toggle pauses and resumes', () {
    final c = _make();
    c.togglePause();
    expect(c.userPaused, isTrue);
    expect(c.advance(_frame, base), 0);
    c.togglePause();
    expect(c.moving, isTrue);
  });
}
