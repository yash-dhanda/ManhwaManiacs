import 'dart:math' as math;
import 'package:flutter/painting.dart' show Axis;
import 'package:manhwamaniacs/features/reader/engine/neighbour.dart';
import 'package:manhwamaniacs/features/reader/engine/zoom_math.dart' show rubberBand;

enum ReadingDirection { ltr, rtl }

/// The axis a drag has committed to: horizontal once `|dx| > 2|dy|` after 10 px, vertical the
/// other way round, else null.
Axis? lockAxis(double dx, double dy) {
  if (math.max(dx.abs(), dy.abs()) < 10) return null;
  if (dx.abs() > 2 * dy.abs()) return Axis.horizontal;
  if (dy.abs() > 2 * dx.abs()) return Axis.vertical;
  return null;
}

class SwipeNeighbourState {
  const SwipeNeighbourState(this.displayed, this.direction);
  final double displayed;
  final NeighbourDirection direction;
}

NeighbourDirection _dirOf(double dx, ReadingDirection d) {
  final left = dx < 0;
  return (left == (d == ReadingDirection.ltr)) ? NeighbourDirection.next : NeighbourDirection.previous;
}

/// The sideways drag [dx] as shown on the 0.35 band.
SwipeNeighbourState swipeNeighbour(double dx, {required double viewportWidth, required ReadingDirection direction}) =>
    SwipeNeighbourState(dx.sign * rubberBand(dx.abs(), viewportWidth, 0.35), _dirOf(dx, direction));

enum SwipeRelease { committed, cancelled }

/// Commits when the projected raw travel `|dx + 0.499 vx|` (capped at one viewport) passes 96 px.
SwipeRelease releaseSwipeNeighbour(double dx, double vx, {required double viewportWidth, required bool hasNeighbour}) {
  final p = math.min((dx + 0.499 * vx).abs(), viewportWidth);
  return hasNeighbour && p > 96 ? SwipeRelease.committed : SwipeRelease.cancelled;
}
