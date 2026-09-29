import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/utils/shelf_counts.dart';

import 'shelf_fixtures.dart';

void main() {
  final rows = [
    shelfSeries(1, newCount: 3, fav: true),
    shelfSeries(2, newCount: 0, status: 'completed'),
    shelfSeries(3, newCount: 1, status: 'on_hold', fav: true),
    shelfSeries(4, started: false, status: 'unread'),
  ];

  test('counts total, with new, favourites and by status', () {
    final c = shelfCounts(rows);
    expect(c.total, 4);
    expect(c.withNew, 2);
    expect(c.favourites, 2);
    expect(c.byStatus, {'reading': 1, 'completed': 1, 'on_hold': 1, 'unread': 1});
  });

  test('the deck drops zero parts and speaks books in novels mode', () {
    expect(shelfDeck(shelfCounts(rows), novels: false), '4 series · 2 with new chapters · 2 favourites');
    expect(shelfDeck(shelfCounts([shelfSeries(1, newCount: 0)]), novels: false), '1 series');
    expect(shelfDeck(shelfCounts(rows), novels: true), '4 books on your shelf');
    expect(shelfDeck(shelfCounts(const []), novels: false), '');
  });
}
