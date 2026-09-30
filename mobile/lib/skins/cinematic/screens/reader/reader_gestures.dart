import 'dart:math' as math;

import 'package:flutter/gestures.dart';

/// The chapter swipe's rules (cinematic 8.14.5, 11): a horizontal drag of at least [kSwipeCommitPx]
/// or [kSwipeCommitVelocity] px/s, live only at zoom <= 1.0, starting outside the edge zones, and
/// within [kSwipeAngle] degrees of horizontal.
const double kSwipeCommitPx = 72;
const double kSwipeCommitVelocity = 600;
const double kSwipeAngle = 30;
const double kSwipeEdgeMin = 24;

/// The width of each edge zone: max(24 px, the system gesture inset).
double swipeEdgeZone(double systemGestureInset) => math.max(kSwipeEdgeMin, systemGestureInset);

/// Whether a touch at [x] on a screen [width] wide may start a chapter swipe.
bool swipeStartAllowed(double x, double width, {double leftInset = 0, double rightInset = 0}) =>
    x >= swipeEdgeZone(leftInset) && x <= width - swipeEdgeZone(rightInset);

/// Whether [delta] is within [degrees] of horizontal.
bool withinHorizontal(Offset delta, [double degrees = kSwipeAngle]) {
  if (delta.dx == 0) return false;
  return delta.dy.abs() <= math.tan(degrees * math.pi / 180) * delta.dx.abs();
}

enum SwipeVerdict { none, toward, away }

/// The verdict of a finished drag: [dx] pixels along x with [vx] px/s at release. Negative [dx]
/// (a finger moving left) goes forward in LTR; [rtl] flips it. `toward` is the next chapter.
SwipeVerdict classifySwipe({
  required double dx,
  required double vx,
  required double zoom,
  required bool rtl,
  bool enabled = true,
}) {
  if (!enabled || zoom > 1.0) return SwipeVerdict.none;
  final fast = vx.abs() >= kSwipeCommitVelocity;
  if (dx.abs() < kSwipeCommitPx && !fast) return SwipeVerdict.none;
  final leftward = (dx != 0 ? dx : vx) < 0;
  return leftward != rtl ? SwipeVerdict.toward : SwipeVerdict.away;
}

/// A horizontal drag that rejects pointers starting inside the edge zones and accepts only when
/// the drag is within [kSwipeAngle] of horizontal at that moment, so steeper drags stay with the
/// vertical scroll.
class ChapterSwipeRecognizer extends HorizontalDragGestureRecognizer {
  ChapterSwipeRecognizer({super.debugOwner, required this.screenWidth, this.leftInset = 0, this.rightInset = 0, this.zoom = 1});

  double screenWidth;
  double leftInset, rightInset;

  /// The strip's zoom: above 1.0 the swipe is not live.
  double zoom;

  final Map<int, Offset> _starts = {};
  final Map<int, Offset> _lasts = {};

  @override
  bool isPointerAllowed(PointerEvent event) =>
      zoom <= 1.0 &&
      swipeStartAllowed(event.position.dx, screenWidth, leftInset: leftInset, rightInset: rightInset) &&
      super.isPointerAllowed(event);

  @override
  void addAllowedPointer(PointerDownEvent event) {
    _starts[event.pointer] = event.position;
    _lasts[event.pointer] = event.position;
    super.addAllowedPointer(event);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerMoveEvent) _lasts[event.pointer] = event.position;
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      _starts.remove(event.pointer);
      _lasts.remove(event.pointer);
    }
    super.handleEvent(event);
  }

  @override
  bool hasSufficientGlobalDistanceToAccept(PointerDeviceKind pointerDeviceKind, double? deviceTouchSlop) {
    final pointer = _lasts.keys.isEmpty ? null : _lasts.keys.first;
    if (pointer == null) return false;
    final delta = _lasts[pointer]! - _starts[pointer]!;
    return withinHorizontal(delta) && super.hasSufficientGlobalDistanceToAccept(pointerDeviceKind, deviceTouchSlop);
  }
}
