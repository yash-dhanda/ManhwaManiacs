import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/reorder_math.dart';

void main() {
  final list = [for (var i = 0; i < 4; i++) Rect.fromLTWH(0, i * 60.0, 300, 56)];
  final grid = [for (var i = 0; i < 6; i++) Rect.fromLTWH((i % 3) * 100.0, (i ~/ 3) * 150.0, 90, 140)];

  test('the target slot in a list follows the vertical band', () {
    expect(reorderTarget(list, const Offset(10, -30)), 0);
    expect(reorderTarget(list, const Offset(10, 20)), 0);
    expect(reorderTarget(list, const Offset(10, 70)), 1);
    expect(reorderTarget(list, const Offset(10, 175)), 2);
    expect(reorderTarget(list, const Offset(10, 900)), 3);
  });

  test('the target slot in a grid is the cell, else the nearest centre', () {
    expect(reorderTarget(grid, const Offset(150, 20), grid: true), 1);
    expect(reorderTarget(grid, const Offset(250, 200), grid: true), 5);
    expect(reorderTarget(grid, const Offset(95, 145), grid: true), 0); // in a gap: nearest centre
    expect(measuredColumns(grid), 3);
  });

  test('auto-scroll speed is 1200 px/s x depth / 64', () {
    expect(autoScrollSpeed(0), 0);
    expect(autoScrollSpeed(32), 600);
    expect(autoScrollSpeed(64), 1200);
    expect(autoScrollSpeed(200), 1200);
    expect(edgeScrollVelocity(300, 100, 700), 0);
    expect(edgeScrollVelocity(100 + 32, 100, 700), -600);
    expect(edgeScrollVelocity(700 - 64, 100, 700), 0);
    expect(edgeScrollVelocity(700, 100, 700), 1200);
  });

  test('keyboard moves clamp at both ends', () {
    expect(movedIndex(0, ReorderMove.up, 5), 0);
    expect(movedIndex(4, ReorderMove.down, 5), 4);
    expect(movedIndex(2, ReorderMove.up, 5), 1);
    expect(movedIndex(2, ReorderMove.down, 5), 3);
    expect(movedIndex(2, ReorderMove.top, 5), 0);
    expect(movedIndex(2, ReorderMove.bottom, 5), 4);
    expect(movedIndex(2, ReorderMove.left, 5), 1);
    expect(movedIndex(0, ReorderMove.left, 5), 0);
    expect(reorderAnnouncement('Solo Leveling', 3, 12), 'Solo Leveling moved to position 3 of 12');
  });

  test('neighbours part around the gap', () {
    // drag 1 over 3: items 2 and 3 shift up one slot
    expect([for (var i = 0; i < 5; i++) displacedSlot(i, 1, 3)], [0, 3, 1, 2, 4]);
    expect([for (var i = 0; i < 5; i++) displacedSlot(i, 3, 1)], [0, 2, 3, 1, 4]);
  });
}
