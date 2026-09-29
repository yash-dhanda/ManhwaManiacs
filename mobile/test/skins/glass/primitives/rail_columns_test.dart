import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/primitives/rail_columns.dart';

void main() {
  test('down keeps the column', () {
    // item 5 at stride 136 with the rail scrolled 500: 180 px into the viewport; the other rail is at rest.
    expect(railColumn(5, 500, 0, 136), 1);
    expect(railColumn(5, 500, 272, 136), 3);
  });

  test('same scroll, same index', () {
    expect(railColumn(4, 300, 300, 136), 4);
  });

  test('never negative', () {
    expect(railColumn(0, 0, 0, 136), 0);
  });
}
