import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/primitives/wave.dart';

void main() {
  const view = Rect.fromLTWH(0, 0, 400, 800);

  test('delay is distance / 1.6 px per ms', () {
    final d = waveDelays([const Rect.fromLTWH(80, 0, 40, 40)], const Offset(100, 20), view);
    expect(d[0], Duration.zero);
    final far = waveDelays([const Rect.fromLTWH(0, 100, 40, 40)], const Offset(20, 20), view);
    expect(far[0]!.inMicroseconds, closeTo(100 / 1.6 * 1000, 2));
  });

  test('the delay is capped at 240 ms', () {
    final d = waveDelays([const Rect.fromLTWH(0, 700, 40, 40)], Offset.zero, view);
    expect(d[0], const Duration(milliseconds: 240));
  });

  test('items outside the viewport get null', () {
    final d = waveDelays([const Rect.fromLTWH(0, 900, 40, 40), const Rect.fromLTWH(0, 10, 40, 40)], Offset.zero, view);
    expect(d[0], isNull);
    expect(d[1], isNotNull);
  });
}
