import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/utils/manual_order.dart';

import 'shelf_fixtures.dart';

void main() {
  test('reorder moves one item and never mutates the input', () {
    const l = ['a', 'b', 'c', 'd'];
    expect(reorder(l, 0, 2), ['b', 'c', 'a', 'd']);
    expect(reorder(l, 3, 0), ['d', 'a', 'b', 'c']);
    expect(reorder(l, 1, 1), l);
    expect(l, ['a', 'b', 'c', 'd']);
  });

  test('only the changed sort_order values are written, after renumbering 0 ... n - 1', () {
    final before = [for (var i = 0; i < 5; i++) shelfSeries(10 + i, sortOrder: i)];
    final after = reorder(before, 3, 1);
    expect(changedSortOrders(before, after), [(id: 13, sortOrder: 1), (id: 11, sortOrder: 2), (id: 12, sortOrder: 3)]);
    expect(changedSortOrders(before, before), isEmpty);
  });

  test('a fresh library where every row shares sort_order 0 writes everything after the first', () {
    final before = [for (var i = 0; i < 3; i++) shelfSeries(i + 1)];
    final after = reorder(before, 2, 0);
    expect(changedSortOrders(before, after), [(id: 1, sortOrder: 1), (id: 2, sortOrder: 2)]);
  });
}
