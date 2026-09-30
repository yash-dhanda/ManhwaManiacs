import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/models/global_search_result.dart';
import 'package:manhwamaniacs/features/sources/models/source_search_group.dart';
import 'package:manhwamaniacs/skins/glass/screens/search/groups.dart';

SourceSearchGroup g(String? id, int n, {SourceGroupStatus status = SourceGroupStatus.ok}) => SourceSearchGroup(
      source: id,
      sourceName: id ?? 'Library',
      status: status,
      items: [for (var i = 0; i < n; i++) GlobalSearchItem(kind: 'source', seriesId: '$i', title: 't$i')],
    );

void main() {
  test('tier 1: library first, pinned in pin order, then by count', () {
    final order = arrangeGroupKeys(const [], [g('a', 2), g('b', 5), g(null, 1), g('c', 3), g('d', 9)], ['c', 'a']);
    expect(order, ['@local', 'c', 'a', 'd', 'b']);
  });

  test('tier 2 only appends, never reorders what is on screen', () {
    final first = arrangeGroupKeys(const [], [g('a', 2), g('b', 5)], const []);
    expect(first, ['b', 'a']);
    final next = arrangeGroupKeys(first, [g('a', 2), g('b', 5), g('z', 99), g('y', 1)], const []);
    expect(next, ['b', 'a', 'z', 'y']);
  });

  test('initials', () {
    expect(groupInitial(g(null, 0)), 'L');
    expect(groupInitial(g('mangadex', 0)), 'M');
  });
}
