import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/models/shelf_query.dart';

void main() {
  test('defaults map to the recently updated sort and page 1 of 200', () {
    expect(const ShelfQuery().toListParams(), {'sort': 'recently_updated', 'page': '1', 'per_page': '200'});
  });

  test('every sort maps to its server parameter', () {
    expect({for (final s in ShelfSort.values) s.name: ShelfQuery(sort: s).toListParams()['sort']}, {
      'updated': 'recently_updated',
      'added': 'recently_added',
      'read': '-last_read_at',
      'title': 'title',
      'unread': '-new_count',
      'manual': 'sort_order',
    });
  });

  test('status, favourites, new only, tags and search map to their parameters', () {
    final p = const ShelfQuery(status: ShelfStatus.onHold, fav: true, newOnly: true, tagIds: [1, 4], q: ' solo ').toListParams();
    expect(p['reading_status'], 'on_hold');
    expect(p['is_favorite'], 'true');
    expect(p['new_only'], 'true');
    expect(p['tag_ids'], '1,4');
    expect(p['search'], 'solo');
    expect(const ShelfQuery().toListParams().containsKey('reading_status'), isFalse);
  });

  test('fromRoute reads the route contract and falls back on unknown values', () {
    final r = ShelfQuery.fromRoute({'status': 'plan_to_read', 'sort': 'read', 'fav': '1', 'view': 'list', 'q': 'moon', 'new': '1', 'tags': '2, x, 7', 'select': '1'});
    expect(r.openSelectMode, isTrue);
    expect(r.query.status, ShelfStatus.planToRead);
    expect(r.query.sort, ShelfSort.read);
    expect(r.query.fav, isTrue);
    expect(r.query.newOnly, isTrue);
    expect(r.query.density, ShelfDensity.list);
    expect(r.query.tagIds, [2, 7]);
    expect(r.query.q, 'moon');
    final bad = ShelfQuery.fromRoute({'status': 'nope', 'sort': 'nope', 'view': 'nope'});
    expect(bad.query, const ShelfQuery());
    expect(bad.openSelectMode, isFalse);
  });

  test('a route only overrides what it names', () {
    const base = ShelfQuery(sort: ShelfSort.title, density: ShelfDensity.compact);
    final r = ShelfQuery.fromRoute({'status': 'reading'}, base: base);
    expect(r.query.sort, ShelfSort.title);
    expect(r.query.density, ShelfDensity.compact);
    expect(r.query.status, ShelfStatus.reading);
  });

  test('the stored form round-trips and never carries the search text', () {
    const q = ShelfQuery(status: ShelfStatus.dropped, sort: ShelfSort.manual, fav: true, newOnly: true, tagIds: [3], density: ShelfDensity.list, q: 'secret');
    final back = ShelfQuery.fromStoredJson(q.toStoredJson())!;
    expect(back, q.copyWith(q: ''));
    expect(ShelfQuery.fromStoredJson('not json'), isNull);
  });

  test('filtering, filter count and reorder rules', () {
    expect(const ShelfQuery().filtering, isFalse);
    expect(const ShelfQuery(q: 'a').filtering, isTrue);
    expect(const ShelfQuery(status: ShelfStatus.reading, fav: true, tagIds: [1]).activeFilterCount, 3);
    expect(const ShelfQuery(sort: ShelfSort.manual).canReorder, isTrue);
    expect(const ShelfQuery(sort: ShelfSort.manual, fav: true).canReorder, isFalse);
    expect(const ShelfQuery(fav: true, sort: ShelfSort.title, density: ShelfDensity.list).cleared(), const ShelfQuery(sort: ShelfSort.title, density: ShelfDensity.list));
  });

  group('Glass query names (mobile/32 A1)', () {
    test('reading_status wins over the chip status and is sent once', () {
      const q = ShelfQuery(status: ShelfStatus.reading, readingStatus: ShelfStatus.onHold);
      expect(q.toListParams()['reading_status'], 'on_hold');
      expect(const ShelfQuery(status: ShelfStatus.completed).toListParams()['reading_status'], 'completed');
      expect(q.filtering, isTrue);
      expect(q.cleared().readingStatus, isNull);
    });

    test('every reading_status value parses from the route', () {
      for (final v in ['unread', 'reading', 'completed', 'on_hold', 'plan_to_read', 'dropped']) {
        final r = ShelfQuery.fromRoute({'reading_status': v}).query;
        expect(r.toListParams()['reading_status'], v);
      }
    });

    test('search and is_favorite are aliases of q and fav; the new names win', () {
      final a = ShelfQuery.fromRoute({'search': 'solo', 'is_favorite': 'true'}).query;
      expect((a.q, a.fav), ('solo', true));
      final b = ShelfQuery.fromRoute({'search': 'x', 'q': 'y', 'is_favorite': 'false', 'fav': '1'}).query;
      expect((b.q, b.fav), ('y', true));
      expect(a.toListParams()['search'], 'solo');
      expect(a.toListParams()['is_favorite'], 'true');
    });

    test('the tab name is read by the hub only', () {
      expect(libraryTabFromRoute({'tab': 'history'}), 'history');
      expect(libraryTabFromRoute({'tab': 'nope'}), isNull);
      expect(ShelfQuery.fromRoute({'tab': 'history'}).query, const ShelfQuery());
    });

    test('a round trip through the route keeps the query; Cinematic params are unchanged', () {
      const q = ShelfQuery(status: ShelfStatus.reading, fav: true, tagIds: [2, 5], sort: ShelfSort.title);
      final back = ShelfQuery.fromRoute({'status': 'reading', 'fav': '1', 'tags': '2,5', 'sort': 'title'}).query;
      expect(back, q);
      expect(q.toListParams(), {'sort': 'title', 'reading_status': 'reading', 'is_favorite': 'true', 'tag_ids': '2,5', 'page': '1', 'per_page': '200'});
    });
  });
}
