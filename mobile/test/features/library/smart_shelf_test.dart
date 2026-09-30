import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/models/collection.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/repositories/library_repository_impl.dart';
import 'package:manhwamaniacs/features/library/utils/smart_shelf.dart';

import 'shelf_fixtures.dart';

class _Recording implements HttpClientAdapter {
  final List<({String method, String path, Object? data})> calls = [];
  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? s, Future<void>? c) async {
    calls.add((method: o.method, path: o.path, data: o.data));
    return ResponseBody.fromString('{"id":1,"name":"n","series_count":0,"sort_order":0}', 200,
        headers: {Headers.contentTypeHeader: ['application/json']},);
  }

  @override
  void close({bool force = false}) {}
}

ShelfRules r(List<ShelfRule> l) => ShelfRules(all: l);

void main() {
  final rows = [
    shelfSeries(1, newCount: 5),
    shelfSeries(2, status: 'completed', newCount: 0, fav: true),
    shelfSeries(3, newCount: 3, fav: true),
    shelfSeries(4, status: 'on_hold', newCount: 9),
  ];
  List<int> ids(ShelfRules x) => [for (final s in evaluateShelf(x, rows)) s.id];

  test('each operator', () {
    expect(ids(r(const [ShelfRule(field: 'reading_status', op: 'eq', value: 'reading')])), [1, 3]);
    expect(ids(r(const [ShelfRule(field: 'reading_status', op: 'ne', value: 'reading')])), [2, 4]);
    expect(ids(r(const [ShelfRule(field: 'new_count', op: 'gte', value: 3)])), [1, 3, 4]);
    expect(ids(r(const [ShelfRule(field: 'reading_status', op: 'in', value: ['completed', 'on_hold'])])), [2, 4]);
    expect(ids(r(const [ShelfRule(field: 'is_favorite', op: 'eq', value: true)])), [2, 3]);
  });

  test('AND across rules keeps library order; empty rules match everything; unknown fields are ignored', () {
    expect(ids(r(const [ShelfRule(field: 'reading_status', op: 'eq', value: 'reading'), ShelfRule(field: 'new_count', op: 'gte', value: 3)])), [1, 3]);
    expect(ids(const ShelfRules()), [1, 2, 3, 4]);
    expect(ids(r(const [ShelfRule(field: 'mood', op: 'eq', value: 'x')])), [1, 2, 3, 4]);
  });

  test('content kind and format come from the callbacks; missing data skips the rule', () {
    String? kind(FollowedSeries s) => s.id == 1 ? 'novel' : 'manga';
    List<int> ev(ShelfRules x) => [for (final s in evaluateShelf(x, rows, contentKindOf: kind)) s.id];
    expect(ev(r(unfinishedNovels)), [1]);
    expect(ev(r(const [ShelfRule(field: 'format', op: 'in', value: ['manhwa'])])), [1, 2, 3, 4]);
  });

  test('describeRules writes the credit text', () {
    expect(
      describeRules(r(const [
        ShelfRule(field: 'reading_status', op: 'eq', value: 'reading'),
        ShelfRule(field: 'new_count', op: 'gte', value: 3),
        ShelfRule(field: 'is_favorite', op: 'eq', value: true),
        ShelfRule(field: 'format', op: 'in', value: ['manhwa', 'manga']),
        ...unfinishedNovels,
      ]),),
      'READING · 3+ NEW · FAVOURITES · MANHWA, MANGA · UNFINISHED NOVELS',
    );
  });

  test('rules round trip through json', () {
    final j = r(unfinishedNovels).toJson();
    expect(ShelfRules.tryParse(j), r(unfinishedNovels));
    expect(ShelfRules.tryParse('x'), isNull);
  });

  test('Collection parses rules, previews, duo and createdAt tolerantly', () {
    final c = Collection.fromJson({
      'id': 3,
      'name': 'Fresh',
      'series_count': 2,
      'sort_order': 1,
      'created_at': '2026-09-01T10:00:00Z',
      'preview_covers': ['/a', '/b', '/c', '/d', '/e'],
      'preview_ambient_duo': '#B8B2A4',
      'rules': {'all': [{'field': 'is_favorite', 'op': 'eq', 'value': true}]},
    });
    expect(c.smart, isTrue);
    expect(c.previewCovers, ['/a', '/b', '/c', '/d']);
    expect(c.previewAmbientDuo, const Color(0xFFB8B2A4));
    expect(c.createdAt, isNotNull);
    final plain = Collection.fromJson({'id': 1, 'name': 'x'});
    expect(plain.smart, isFalse);
    expect(plain.previewCovers, isEmpty);
    expect(plain.previewAmbientDuo, isNull);
    expect(plain.createdAt, isNull);
  });

  test('create, update and reorder send the right bodies', () async {
    final rec = _Recording();
    final repo = LibraryRepositoryImpl(Dio(BaseOptions(baseUrl: 'http://example.test'))..httpClientAdapter = rec);
    await repo.createCollection(name: 'A', rules: r(unfinishedNovels));
    await repo.updateCollection(1, clearRules: true);
    await repo.updateCollection(1, name: 'B');
    await repo.reorderCollectionMembers(1, [(sourceId: 's', seriesKey: 'k1'), (sourceId: 's', seriesKey: 'k2')]);
    expect((rec.calls[0].data as Map<String, dynamic>)['rules'], isA<Map<String, dynamic>>());
    expect((rec.calls[1].data as Map<String, dynamic>).containsKey('rules'), isTrue);
    expect((rec.calls[1].data as Map<String, dynamic>)['rules'], isNull);
    expect((rec.calls[2].data as Map<String, dynamic>).containsKey('rules'), isFalse);
    expect(rec.calls[3].method, 'PUT');
    expect(rec.calls[3].path, '/library/collections/1/series/order');
    expect(rec.calls[3].data, {
      'items': [
        {'source_id': 's', 'series_key': 'k1'},
        {'source_id': 's', 'series_key': 'k2'},
      ],
    });
  });
}
