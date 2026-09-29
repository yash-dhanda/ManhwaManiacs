import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/keyboard/fuzzy_rank.dart';

void main() {
  String id(String s) => s;

  test('subsequence match, case-insensitive, with indices', () {
    final r = rankItems('lb', ['Library', 'Downloads', 'Bookmarks'], id);
    expect(r.map((e) => e.item), ['Library']);
    expect(r.first.matches, [0, 2]);
  });

  test('consecutive and word-start matches rank higher', () {
    final r = rankItems('set', ['Offset field', 'Settings', 'A sad end thing'], id);
    expect(r.first.item, 'Settings');
  });

  test('earlier first match wins', () {
    final r = rankItems('o', ['Zoo', 'Oz'], id);
    expect(r.map((e) => e.item), ['Oz', 'Zoo']);
  });

  test('ties keep input order; empty query keeps everything', () {
    expect(rankItems('', ['b', 'a', 'c'], id).map((e) => e.item), ['b', 'a', 'c']);
    expect(rankItems('x', ['ax', 'bx'], id).map((e) => e.item), ['ax', 'bx']);
  });

  test('limit truncates', () {
    final items = List.generate(100, (i) => 'item $i');
    expect(rankItems('item', items, id).length, 40);
    expect(rankItems('item', items, id, limit: 5).length, 5);
  });
}
