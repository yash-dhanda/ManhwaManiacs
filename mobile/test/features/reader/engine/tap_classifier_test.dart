import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/engine/tap_classifier.dart';

void main() {
  final t0 = DateTime(2026, 1, 1);
  test('legacy parameters: 280 ms, any distance', () {
    final c = TapClassifier();
    expect(c.classify(const Offset(10, 10), t0), TapKind.single);
    expect(c.classify(const Offset(300, 500), t0.add(const Duration(milliseconds: 279))), TapKind.double);
    expect(c.classify(const Offset(10, 10), t0.add(const Duration(milliseconds: 300))), TapKind.single);
    expect(c.classify(const Offset(10, 10), t0.add(const Duration(milliseconds: 600))), TapKind.single);
  });

  test('cinematic parameters: 300 ms and 24 px', () {
    final c = TapClassifier(doubleTapWindow: const Duration(milliseconds: 300), doubleTapSlop: 24);
    expect(c.classify(const Offset(100, 100), t0), TapKind.single);
    expect(c.classify(const Offset(100, 125), t0.add(const Duration(milliseconds: 100))), TapKind.single, reason: '25 px apart');
    expect(c.classify(const Offset(110, 110), t0.add(const Duration(milliseconds: 250))), TapKind.double);
    expect(c.classify(const Offset(110, 110), t0.add(const Duration(milliseconds: 300))), TapKind.single);
    expect(c.classify(const Offset(110, 110), t0.add(const Duration(milliseconds: 600))), TapKind.double, reason: '300 ms edge');
  });
}
