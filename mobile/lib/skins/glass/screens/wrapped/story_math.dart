import 'dart:math' as math;

// Story stack maths (glass 4.4, 4.5, 9.2.3): the card beneath waits at 0.94 and 60 % brightness, the top card follows the finger with a
// 25 % rubber band at the ends and the release projects to the card.

const double kBeneathScale = 0.94;
const double kBeneathBrightness = 0.6;
const double kRubberBand = 0.25;
const double kAutoAdvanceMs = 6000;
const double kCloseProjection = 120;

/// The top card's offset for a drag of [dx]: 25 % of it when there is no card in that direction.
double stackOffset(double dx, {required bool hasNext, required bool hasPrev}) {
  final blocked = dx < 0 ? !hasNext : !hasPrev;
  return blocked ? dx * kRubberBand : dx;
}

/// 0 to 1: how far the top card has left ([dx] of [width]).
double leaveProgress(double dx, double width) => width <= 0 ? 0 : (dx.abs() / width).clamp(0.0, 1.0);

/// The beneath card's scale and brightness at leave progress [p].
double beneathScaleAt(double p) => kBeneathScale + (1 - kBeneathScale) * p;
double beneathBrightnessAt(double p) => kBeneathBrightness + (1 - kBeneathBrightness) * p;

/// Where a release lands: -1 previous (drag right), +1 next (drag left), 0 stay. The position is projected with [vx] px/s over 0.2 s and
/// must pass half the width; blocked directions always stay.
int commitDirection(double dx, double vx, double width, {required bool hasNext, required bool hasPrev}) {
  final projected = dx + vx * 0.2;
  if (projected.abs() < width / 2) return 0;
  final dir = projected < 0 ? 1 : -1;
  if (dir == 1 && !hasNext) return 0;
  if (dir == -1 && !hasPrev) return 0;
  return dir;
}

/// A swipe down closes when its projected travel passes 120 px.
bool closesOnRelease(double dy, double vy) => dy > 0 && dy + math.max(0, vy) * 0.2 > kCloseProjection;

/// A release within 450 ms and 10 px of the press is a tap; later is a hold that resumes the capsule.
bool isTap(Duration held, double movedPx) => held < const Duration(milliseconds: 450) && movedPx <= 10;

/// Tap thirds: the left third is previous, the rest next.
int tapDirection(double x, double width) => x < width / 3 ? -1 : 1;

/// The auto-advance progress (0 to 1) of the current card after [elapsedMs] of running time.
double autoProgress(double elapsedMs) => (elapsedMs / kAutoAdvanceMs).clamp(0.0, 1.0);

/// Whether the auto-advance may run. It keeps running under Reduce Motion (it is timing, not motion).
bool autoAdvanceRuns({required bool pressed, required bool paused, required bool resumed, required bool shareOpen, required bool screenReader, required bool last}) => !pressed && !paused && resumed && !shareOpen && !screenReader && !last;
