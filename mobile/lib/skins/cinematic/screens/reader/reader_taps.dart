import 'dart:math' as math;
import 'dart:ui';

// The reader tap rules, free of widgets (cinematic 8.14.3, 8.14.5, 11).

/// The centre region lock mode listens to: 20-80 % of the width by 15-85 % of the height.
bool isLockCentre(Offset position, Size size) =>
    position.dx > size.width * 0.2 &&
    position.dx < size.width * 0.8 &&
    position.dy > size.height * 0.15 &&
    position.dy < size.height * 0.85;

enum LockResult { ignored, counted, unlocked }

/// Five taps in the centre region, each within 2 s of the previous, unlock the controls.
class LockCounter {
  LockCounter({this.needed = 5, this.window = const Duration(seconds: 2)});

  final int needed;
  final Duration window;
  int count = 0;
  DateTime? _last;

  LockResult tap(Offset position, Size size, DateTime now) {
    if (!isLockCentre(position, size)) return LockResult.ignored;
    if (_last == null || now.difference(_last!) > window) count = 0;
    _last = now;
    count++;
    if (count >= needed) {
      count = 0;
      _last = null;
      return LockResult.unlocked;
    }
    return LockResult.counted;
  }

  void reset() {
    count = 0;
    _last = null;
  }
}

enum StripTap { toggleChrome, scrollBack, scrollForward }

/// With `stripTaps = TAP_TO_SCROLL`: the top third and the left-middle scroll back, the bottom
/// third and the right-middle scroll forward, the centre toggles the chrome. Otherwise every tap
/// toggles it. [rtl] swaps the sides.
StripTap stripTap(Offset position, Size size, {required bool tapToScroll, bool rtl = false}) {
  if (!tapToScroll) return StripTap.toggleChrome;
  final y = position.dy / size.height, x = position.dx / size.width;
  if (y < 1 / 3) return StripTap.scrollBack;
  if (y > 2 / 3) return StripTap.scrollForward;
  if (x < 1 / 3) return rtl ? StripTap.scrollForward : StripTap.scrollBack;
  if (x > 2 / 3) return rtl ? StripTap.scrollBack : StripTap.scrollForward;
  return StripTap.toggleChrome;
}

/// The double-tap target: from the series' resting zoom to min(2 x resting, 3.0), from any other
/// zoom back to the resting zoom.
double doubleTapZoomTarget(double current, double resting) =>
    (current - resting).abs() < 0.05 ? math.min(resting * 2, 3.0) : resting;

/// How far a tap-to-scroll moves: 75 % of the viewport, backwards when [forward] is false.
double tapScrollFraction({required bool forward}) => forward ? 0.75 : -0.75;
