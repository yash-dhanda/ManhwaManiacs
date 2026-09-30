import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';

// Pure swipe-row numbers (glass 7.34, 4.6, 8.0.5).

/// One action slot behind the row.
const double kSwipeSlot = 88;

/// The share of the row width, projected, past which a swipe commits its first action.
const double kFullSwipeFraction = 0.6;

/// A pill inflates from 0.6 to 1.0 as it is revealed: `0.6 + 0.4 x clamp(reveal / 88, 0, 1)`.
double pillScale(double reveal) => 0.6 + 0.4 * (reveal / kSwipeSlot).clamp(0.0, 1.0);

/// The width of a tray of [n] actions.
double trayWidth(int n) => n * kSwipeSlot;

/// Release: true when the projected offset passes half the tray (it opens), else it closes.
bool opensTray(double offset, double velocity, int n) {
  final p = project(offset, velocity);
  return p.sign == offset.sign && p.abs() > trayWidth(n) / 2;
}

/// The full-swipe line: the projected offset past 60 % of the row width.
bool fullSwipeCrossed(double offset, double velocity, double rowWidth) {
  final p = project(offset, velocity);
  return p.sign == offset.sign && p.abs() > kFullSwipeFraction * rowWidth;
}

/// The iOS back swipe owns the first 24 px of the leading edge: a row never starts a drag there.
bool startsInBackStrip(double downX, {double screenLeft = 0, double strip = 24}) => downX - screenLeft < strip;
