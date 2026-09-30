import 'dart:math' as math;
import 'dart:ui';

// Pure reorder numbers (glass 7.35, 4.6): the slot under the pointer, edge auto-scroll speed, keyboard moves.

/// Auto-scroll: `1200 px/s x depthIntoZone / 64` inside the 64 px edge zone of a scrollable.
const double kAutoScrollZone = 64;
const double kAutoScrollMax = 1200;

double autoScrollSpeed(double depthIntoZone) => kAutoScrollMax * depthIntoZone.clamp(0.0, kAutoScrollZone) / kAutoScrollZone;

/// Signed scroll speed for a pointer at [y] in a viewport spanning [top]..[bottom]: negative near the top edge.
double edgeScrollVelocity(double y, double top, double bottom) {
  if (y < top + kAutoScrollZone) return -autoScrollSpeed(top + kAutoScrollZone - y);
  if (y > bottom - kAutoScrollZone) return autoScrollSpeed(y - (bottom - kAutoScrollZone));
  return 0;
}

/// The slot under [pointer]: in a list the row whose vertical band holds it (before the first row is the first, after the
/// last is the last); in a grid the cell containing it, else the nearest centre.
int reorderTarget(List<Rect> slots, Offset pointer, {bool grid = false}) {
  if (slots.isEmpty) return 0;
  if (!grid) {
    for (var i = 0; i < slots.length; i++) {
      if (pointer.dy < slots[i].bottom) return i;
    }
    return slots.length - 1;
  }
  for (var i = 0; i < slots.length; i++) {
    if (slots[i].contains(pointer)) return i;
  }
  var best = 0;
  var bestD = double.infinity;
  for (var i = 0; i < slots.length; i++) {
    final d = (slots[i].center - pointer).distanceSquared;
    if (d < bestD) {
      bestD = d;
      best = i;
    }
  }
  return best;
}

/// The column count measured from the slots: how many share the first row's top.
int measuredColumns(List<Rect> slots) {
  if (slots.isEmpty) return 1;
  final top = slots.first.top;
  return math.max(1, slots.where((r) => (r.top - top).abs() < 1).length);
}

enum ReorderMove { up, down, left, right, top, bottom }

/// The index after a keyboard move, clamped at both ends. Left and right move one slot in a grid.
int movedIndex(int from, ReorderMove move, int count, {int columns = 1}) {
  if (count <= 0) return 0;
  final to = switch (move) {
    ReorderMove.up => from - columns,
    ReorderMove.down => from + columns,
    ReorderMove.left => from - 1,
    ReorderMove.right => from + 1,
    ReorderMove.top => 0,
    ReorderMove.bottom => count - 1,
  };
  return to.clamp(0, count - 1);
}

/// "Solo Leveling moved to position 3 of 12" (assertive).
String reorderAnnouncement(String name, int position, int total) => '$name moved to position $position of $total';

/// Where each item sits while [from] is dragged over [target]: the items between shift by one slot.
int displacedSlot(int index, int from, int target) {
  if (index == from) return target;
  if (from < target && index > from && index <= target) return index - 1;
  if (from > target && index >= target && index < from) return index + 1;
  return index;
}
