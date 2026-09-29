import 'dart:math' as math;

/// `floor((W + gap) / (gridMin + gap))`, at least one column (glass 7.8).
int posterColumns(double contentWidth, double gridMin, double gap) => math.max(1, ((contentWidth + gap) / (gridMin + gap)).floor());

/// `W = min(windowWidth - sidebarOffset, 1440) - 2 x margin` (glass 7.8): [sidebarOffset] 304 expanded or
/// 100 collapsed, [margin] 32, or 40 at 1440 and wider.
double posterContentWidth({required double windowWidth, required double sidebarOffset, required double margin}) =>
    math.min(windowWidth - sidebarOffset, 1440) - 2 * margin;
