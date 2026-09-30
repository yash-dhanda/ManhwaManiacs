import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_taps.dart';

void main() {
  const size = Size(400, 800);
  test('the lock centre is 20-80 % by 15-85 %', () {
    expect(isLockCentre(const Offset(200, 400), size), isTrue);
    expect(isLockCentre(const Offset(79, 400), size), isFalse);
    expect(isLockCentre(const Offset(321, 400), size), isFalse);
    expect(isLockCentre(const Offset(200, 119), size), isFalse);
    expect(isLockCentre(const Offset(200, 681), size), isFalse);
  });

  test('five centre taps within 2 s each unlock; an edge tap or a gap does not count', () {
    final l = LockCounter();
    var t = DateTime(2026);
    LockResult tap(Offset p, int afterMs) {
      t = t.add(Duration(milliseconds: afterMs));
      return l.tap(p, size, t);
    }

    const c = Offset(200, 400);
    expect(tap(c, 0), LockResult.counted);
    expect(tap(const Offset(10, 10), 100), LockResult.ignored);
    expect(tap(c, 1900), LockResult.counted);
    expect(tap(c, 1900), LockResult.counted);
    expect(tap(c, 1900), LockResult.counted);
    expect(tap(c, 1900), LockResult.unlocked);
    // A 2.1 s gap starts over.
    expect(tap(c, 100), LockResult.counted);
    expect(tap(c, 2100), LockResult.counted);
    expect(l.count, 1);
  });

  test('tap zones on the strip', () {
    StripTap tapAt(double x, double y, {bool scroll = true, bool rtl = false}) =>
        stripTap(Offset(x, y), size, tapToScroll: scroll, rtl: rtl);
    expect(tapAt(200, 400, scroll: false), StripTap.toggleChrome);
    expect(tapAt(10, 700, scroll: false), StripTap.toggleChrome);
    expect(tapAt(200, 100), StripTap.scrollBack);
    expect(tapAt(200, 700), StripTap.scrollForward);
    expect(tapAt(50, 400), StripTap.scrollBack);
    expect(tapAt(350, 400), StripTap.scrollForward);
    expect(tapAt(200, 400), StripTap.toggleChrome);
    expect(tapAt(50, 400, rtl: true), StripTap.scrollForward);
  });

  test('double tap toggles resting and min(2 x resting, 3)', () {
    expect(doubleTapZoomTarget(1.0, 1.0), 2.0);
    expect(doubleTapZoomTarget(2.0, 1.0), 1.0);
    expect(doubleTapZoomTarget(1.7, 1.0), 1.0);
    expect(doubleTapZoomTarget(1.8, 1.8), 3.0);
    expect(doubleTapZoomTarget(3.0, 1.8), 1.8);
    expect(tapScrollFraction(forward: true), 0.75);
    expect(tapScrollFraction(forward: false), -0.75);
  });
}
