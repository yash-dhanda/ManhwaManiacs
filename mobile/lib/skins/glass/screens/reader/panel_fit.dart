import 'dart:math' as math;

/// The desktop frame's strip (glass 8.14.11): `clamp(480, 0.5 x width, 900)`.
double desktopStripWidth(double width) => (0.5 * width).clamp(480.0, 900.0);

const double kReaderLeftPanel = 300, kReaderRightPanel = 360;

/// The strip with panels open: `min(clamp(480, 0.5 w, 900), w - sum(panel + 24) - 24)`.
double stripWithPanels(double width, {bool left = false, bool right = false}) {
  final taken = (left ? kReaderLeftPanel + 24 : 0) + (right ? kReaderRightPanel + 24 : 0);
  return math.min(desktopStripWidth(width), width - taken - (left || right ? 24 : 0));
}

/// Opening [opening] (`left` or `right`) with the other panel open: true when both fit (the strip stays at 480 or wider).
bool bothPanelsFit(double width) => stripWithPanels(width, left: true, right: true) >= 480;

/// The strip's centre with panels open: the middle of the remaining width.
double stripCentre(double width, {bool left = false, bool right = false}) {
  final l = left ? kReaderLeftPanel + 24 : 0.0;
  final r = right ? kReaderRightPanel + 24 : 0.0;
  return l + (width - l - r) / 2;
}
