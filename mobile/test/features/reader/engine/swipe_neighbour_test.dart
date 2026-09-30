import 'package:flutter/painting.dart' show Axis;
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/engine/neighbour.dart';
import 'package:manhwamaniacs/features/reader/engine/swipe_neighbour.dart';

void main() {
  test('axis lock', () {
    expect(lockAxis(9, 0), isNull);
    expect(lockAxis(10, 2), Axis.horizontal);
    expect(lockAxis(2, 10), Axis.vertical);
    expect(lockAxis(8, 6), isNull);
  });
  test('0.35 band on 390', () {
    expect(swipeNeighbour(0, viewportWidth: 390, direction: ReadingDirection.ltr).displayed, 0);
    expect(swipeNeighbour(100, viewportWidth: 390, direction: ReadingDirection.ltr).displayed, closeTo(390 * (1 - 1 / (100 * 0.35 / 390 + 1)), 1e-9));
    expect(swipeNeighbour(-400, viewportWidth: 390, direction: ReadingDirection.ltr).displayed, lessThan(0));
    expect(swipeNeighbour(-400, viewportWidth: 390, direction: ReadingDirection.ltr).direction, NeighbourDirection.next);
    expect(swipeNeighbour(400, viewportWidth: 390, direction: ReadingDirection.ltr).direction, NeighbourDirection.previous);
  });
  test('rtl mirrors', () {
    expect(swipeNeighbour(-50, viewportWidth: 390, direction: ReadingDirection.rtl).direction, NeighbourDirection.previous);
    expect(swipeNeighbour(50, viewportWidth: 390, direction: ReadingDirection.rtl).direction, NeighbourDirection.next);
  });
  test('release', () {
    SwipeRelease r(double dx, double vx, {bool n = true}) => releaseSwipeNeighbour(dx, vx, viewportWidth: 390, hasNeighbour: n);
    expect(r(-97, 0), SwipeRelease.committed);
    expect(r(-95, 0), SwipeRelease.cancelled);
    expect(r(-50, -100), SwipeRelease.committed);
    expect(r(-200, 0, n: false), SwipeRelease.cancelled);
  });
}
