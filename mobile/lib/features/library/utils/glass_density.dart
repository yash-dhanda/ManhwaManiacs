import 'dart:math' as math;

/// Library density of the Glass shelf (glass 8.17). Pure: the steps, the grid maths and the pinch and wheel thresholds.
enum GlassDensityWide { comfortable, compact, list }

/// The phone value: List (`columns == 0`) or 2 | 3 | 4 | 5 columns.
class GlassPhoneDensity {
  const GlassPhoneDensity._(this.columns);
  static const list = GlassPhoneDensity._(0);
  static const c2 = GlassPhoneDensity._(2);
  static const c3 = GlassPhoneDensity._(3);
  static const c4 = GlassPhoneDensity._(4);
  static const c5 = GlassPhoneDensity._(5);

  /// Order from the largest items to the smallest: `list ↔ 2 ↔ 3 ↔ 4 ↔ 5`.
  static const values = [list, c2, c3, c4, c5];

  final int columns;
  bool get isList => columns == 0;

  static GlassPhoneDensity of(int columns) => values.firstWhere((d) => d.columns == columns, orElse: () => c3);

  /// `"list"` or the column count, as stored.
  Object get wire => isList ? 'list' : columns;

  static GlassPhoneDensity parse(Object? v) => v == 'list' ? list : (v is int ? of(v) : c3);

  @override
  bool operator ==(Object other) => other is GlassPhoneDensity && other.columns == columns;

  @override
  int get hashCode => columns;

  @override
  String toString() => isList ? 'list' : '$columns columns';
}

/// One step on the phone ladder; [larger] means larger items (fewer columns). Clamped at both ends.
GlassPhoneDensity stepPhone(GlassPhoneDensity current, {required bool larger}) {
  final i = GlassPhoneDensity.values.indexOf(current);
  final next = larger ? i - 1 : i + 1;
  return GlassPhoneDensity.values[next.clamp(0, GlassPhoneDensity.values.length - 1)];
}

/// One step over `comfortable ↔ compact ↔ list`; [larger] means larger items, so `list` is the largest here (rows).
GlassDensityWide stepWide(GlassDensityWide current, {required bool larger}) {
  const order = [GlassDensityWide.list, GlassDensityWide.comfortable, GlassDensityWide.compact];
  final i = order.indexOf(current);
  final next = larger ? i - 1 : i + 1;
  return order[next.clamp(0, order.length - 1)];
}

/// `minmax(min, 1fr)` column minimum: tablet Comfortable 148, desktop Comfortable 152, Compact 112 on both. List has no grid; it
/// answers the Comfortable minimum so callers never divide by zero.
double gridMin(GlassDensityWide d, {required bool desktop}) => switch (d) {
      GlassDensityWide.compact => 112,
      _ => desktop ? 152 : 148,
    };

/// The Flutter form of `repeat(auto-fill, minmax(min, 1fr))`.
int gridColumns(double width, double gridMin, double gap) => math.max(1, ((width + gap) / (gridMin + gap)).floor());

/// A pinch's committed steps: +1 toward larger items at scale ≥ 1.25, −1 toward smaller at ≤ 0.8, else 0. At most one per gesture.
int pinchSteps(double scale) => scale >= 1.25 ? 1 : (scale <= 0.8 ? -1 : 0);

/// Ctrl/⌘ + wheel: one step per 120 px of accumulated `scrollDelta.dy`, negative toward larger items (so `+1` = larger). The
/// accumulator is reset by the caller after [wheelReset] without input ([WheelAccumulator] does it).
int wheelSteps(double accumulated) => -(accumulated / 120).truncate();

const Duration wheelReset = Duration(milliseconds: 400);

/// Accumulates wheel deltas and converts them to steps; resets after [wheelReset] of silence and keeps the remainder after a step.
class WheelAccumulator {
  double _sum = 0;
  Duration? _last;

  /// Adds [dy] at time [now]; returns the steps to apply now (+1 larger, −1 smaller, 0 none).
  int add(double dy, Duration now) {
    if (_last != null && now - _last! > wheelReset) _sum = 0;
    _last = now;
    _sum += dy;
    final steps = wheelSteps(_sum);
    if (steps != 0) _sum += steps * 120;
    return steps;
  }
}
