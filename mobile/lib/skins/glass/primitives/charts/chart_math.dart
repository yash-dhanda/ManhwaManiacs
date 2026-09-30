import 'dart:math' as math;
import 'dart:ui';

import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart' show glassTokens;
import 'package:manhwamaniacs/skins/token_types.g.dart' show SpringToken;

// Pure chart numbers (glass 7.39): bar width, heat levels, clock and radar geometry, band words, keyboard stepping and the rise wave.

/// One point of a chart: a day or a label, its value, an optional second-axis value, and whether it is still filling (today).
class ChartDatum {
  const ChartDatum({this.day, this.label, required this.value, this.second, this.partial = false});
  final DateTime? day;
  final String? label;
  final double value;
  final double? second;
  final bool partial;
}

/// Bar width: `min(16, available / n - 3)` px, never below 1.
double barWidth(double available, int n) => n <= 0 ? 0 : math.max(1.0, math.min(16.0, available / n - 3));

/// Heat level 0 to 4: 0 when `v <= 0`, else `min(4, ceil(4 v / max))`.
int heatLevel(double v, double max) => v <= 0 || max <= 0 ? 0 : math.min(4, (4 * v / max).ceil());

const double kClockInner = 40;
const double kClockSpan = 40;

/// The outer radius of the hour bar for value [v] of [max]: from 40 to `40 + 40 v / max`.
double clockBarEnd(double v, double max) => kClockInner + kClockSpan * (max <= 0 ? 0 : (v / max).clamp(0.0, 1.0));

/// The bar's opacity: `0.25 + 0.75 v / max`.
double clockOpacity(double v, double max) => 0.25 + 0.75 * (max <= 0 ? 0 : (v / max).clamp(0.0, 1.0));

/// Angle of hour [h] on the clock (midnight at the top, clockwise), in radians.
double clockAngle(int h) => (h % 24) / 24 * 2 * math.pi - math.pi / 2;

/// The hour with the highest value (the first on a tie), or null when everything is zero.
int? peakHour(List<double> hours) {
  var best = -1;
  var bestV = 0.0;
  for (var i = 0; i < hours.length; i++) {
    if (hours[i] > bestV) {
      bestV = hours[i];
      best = i;
    }
  }
  return best < 0 ? null : best;
}

/// "Night owl" 22 to 05, "Early reader" 05 to 09, "Daytime reader" 09 to 17, "Evening reader" 17 to 22.
String bandWord(int hour) {
  final h = hour % 24;
  if (h >= 22 || h < 5) return 'Night owl';
  if (h < 9) return 'Early reader';
  if (h < 17) return 'Daytime reader';
  return 'Evening reader';
}

/// "23:00".
String hourLabel(int h) => '${(h % 24).toString().padLeft(2, '0')}:00';

/// "You read most around 23:00" and its band word.
String peakLine(int hour) => 'You read most around ${hourLabel(hour)}';

/// Vertex [i] of [n] axes at radius [r] * value / max, axes starting at the top and going clockwise.
Offset radarVertex(int i, int n, double value, double max, double r) {
  final a = -math.pi / 2 + i * 2 * math.pi / n;
  final k = max <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
  return Offset(r * k * math.cos(a), r * k * math.sin(a));
}

List<Offset> radarVertices(List<double> values, double r) {
  final max = values.fold<double>(0, math.max);
  return [for (var i = 0; i < values.length; i++) radarVertex(i, values.length, values[i], max, r)];
}

/// The heatmap cell of the data index [i] when the first day falls on [firstWeekday] (Monday = 0): (column, row).
({int col, int row}) heatCell(int i, int firstWeekday) {
  final k = i + firstWeekday;
  return (col: k ~/ 7, row: k % 7);
}

/// Where a selection goes on a key: `delta` steps (left/right one day, up/down one week in a heatmap), clamped; Home and End jump.
int stepSelection(int? current, int delta, int n) {
  if (n <= 0) return 0;
  if (current == null) return delta >= 0 ? 0 : n - 1;
  return (current + delta).clamp(0, n - 1);
}

int homeIndex() => 0;
int endIndex(int n) => math.max(0, n - 1);

/// Bars rise from the baseline in a wave from the left: `delay = min(x / 1.6, 240)` ms.
double riseDelayMs(double x) => math.min(x / 1.6, 240);

/// The height fraction of a bar at [x] [tMs] into the rise, on [spring] (springSnappy).
double riseProgress(double x, double tMs, {SpringToken? spring, double durationMs = 431}) {
  final t = ((tMs - riseDelayMs(x)) / durationMs).clamp(0.0, 1.0);
  if (t <= 0) return 0;
  return SpringCurve(spring ?? glassTokens.springSnappy, settleMs: durationMs.round()).transform(t);
}
