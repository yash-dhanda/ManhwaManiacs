import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/engine/auto_scroll_model.dart';
import 'package:manhwamaniacs/features/reader/engine/guided.dart';
import 'package:manhwamaniacs/features/reader/engine/words.dart';

void main() {
  test('manga rate', () {
    expect(mangaPxPerSecond(1, 844), closeTo(46.9, 0.05));
    expect(mangaPxPerSecond(3, 1080), 180);
  });
  test('pace factor', () {
    expect(paceFactor(0), 1.0);
    expect(paceFactor(12), 1.0);
    expect(paceFactor(42), closeTo(0.5, 1e-9));
    expect(paceFactor(200), 0.5);
  });
  test('snap and novel px/s', () {
    expect(snapSpeedX(1.23), 1.25);
    expect(snapSpeedX(9), 3.0);
    expect(novelPxPerSecond(250, 1, 30, 10), closeTo(12.5, 1e-9));
  });
  test('ramp reaches target smoothly over 400 ms', () {
    final r = RateRamp(ramp: const Duration(milliseconds: 400), curve: const Cubic(0.16, 1, 0.3, 1).transform)..retarget(100);
    var dist = 0.0;
    for (var i = 0; i < 25; i++) {
      dist += r.advance(const Duration(milliseconds: 16));
    }
    expect(r.rate, closeTo(100, 1e-6));
    expect(dist, greaterThan(30));
  });
  test('panel hold', () {
    expect(panelHoldMs(0, GuidedHoldMode.paceByWords, 3500), 1200);
    expect(panelHoldMs(10, GuidedHoldMode.paceByWords, 3500), 3700);
    expect(panelHoldMs(20, GuidedHoldMode.paceByWords, 3500), 6000);
    expect(panelHoldMs(99, GuidedHoldMode.fixed, 3500), 3500);
    expect(panelHoldMs(null, GuidedHoldMode.paceByWords, 3500), 3500);
  });
  test('words counting', () {
    final boxes = [const OcrWordBox(Rect.fromLTWH(0.1, 0.1, 0.2, 0.1), 'a b  c'), const OcrWordBox(Rect.fromLTWH(0.7, 0.7, 0.2, 0.1), 'x y')];
    expect(wordsInRect(boxes, const Rect.fromLTWH(0, 0, 0.5, 0.5)), 3);
    expect(wordsInViewport({1: boxes}, (p, f) => Offset(f.dx * 100, f.dy * 100), const Rect.fromLTWH(0, 0, 50, 50)), 3);
  });
}
