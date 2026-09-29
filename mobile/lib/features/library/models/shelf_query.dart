import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Reading-status filter of the shelf. [wire] is the stored `reading_status`; null for `all`.
enum ShelfStatus {
  all(null),
  reading('reading'),
  unread('unread'),
  completed('completed'),
  onHold('on_hold'),
  planToRead('plan_to_read'),
  dropped('dropped');

  const ShelfStatus(this.wire);
  final String? wire;

  static ShelfStatus parse(String? v) {
    if (v == null) return all;
    final k = v.toLowerCase().replaceAll('-', '_');
    for (final s in values) {
      if (s.wire == k || s.name.toLowerCase() == k.replaceAll('_', '') || s.name == v) return s;
    }
    return all;
  }
}

/// The six sorts of the shelf. Every one runs on the server (`GET /library/series?sort=`).
enum ShelfSort {
  updated('recently_updated'),
  added('recently_added'),
  read('-last_read_at'),
  title('title'),
  unread('-new_count'),
  manual('sort_order');

  const ShelfSort(this.wire);
  final String wire;

  static ShelfSort parse(String? v) => values.firstWhere((s) => s.name == v, orElse: () => updated);
}

enum ShelfDensity {
  wall,
  compact,
  list;

  static ShelfDensity parse(String? v) => values.firstWhere((d) => d.name == v, orElse: () => wall);
}

/// What the route contract carries besides the query: `select=1` opens select mode on mount.
typedef ShelfRoute = ({ShelfQuery query, bool openSelectMode});

/// The shelf's whole query: `?status&sort&fav&view&q&select` plus `new` and `tags` (cinematic 8.0.3).
@immutable
class ShelfQuery {
  const ShelfQuery({
    this.status = ShelfStatus.all,
    this.sort = ShelfSort.updated,
    this.fav = false,
    this.newOnly = false,
    this.tagIds = const [],
    this.density = ShelfDensity.wall,
    this.q = '',
  });

  final ShelfStatus status;
  final ShelfSort sort;
  final bool fav, newOnly;
  final List<int> tagIds;
  final ShelfDensity density;
  final String q;

  /// A status other than ALL, favourites, new only, a tag or a search is active.
  bool get filtering => status != ShelfStatus.all || fav || newOnly || tagIds.isNotEmpty || q.trim().isNotEmpty;

  /// How many of the Filters sheet's filters are on (the `Filters ⁽2⁾` folio): status, favourites,
  /// new only and tags count; sort, density and search do not.
  int get activeFilterCount => (status != ShelfStatus.all ? 1 : 0) + (fav ? 1 : 0) + (newOnly ? 1 : 0) + (tagIds.isNotEmpty ? 1 : 0);

  /// Manual order can be dragged only over the whole, unfiltered shelf.
  bool get canReorder => sort == ShelfSort.manual && !filtering;

  ShelfQuery copyWith({
    ShelfStatus? status,
    ShelfSort? sort,
    bool? fav,
    bool? newOnly,
    List<int>? tagIds,
    ShelfDensity? density,
    String? q,
  }) =>
      ShelfQuery(
        status: status ?? this.status,
        sort: sort ?? this.sort,
        fav: fav ?? this.fav,
        newOnly: newOnly ?? this.newOnly,
        tagIds: tagIds ?? this.tagIds,
        density: density ?? this.density,
        q: q ?? this.q,
      );

  /// Every filter cleared; sort and density stay.
  ShelfQuery cleared() => ShelfQuery(sort: sort, density: density);

  /// [base] with the route's parameters laid over it. Unknown values fall back to the base.
  static ShelfRoute fromRoute(Map<String, String> query, {ShelfQuery base = const ShelfQuery()}) {
    var s = base;
    final status = query['status'];
    if (status != null) s = s.copyWith(status: ShelfStatus.parse(status));
    final sort = query['sort'];
    if (sort != null && ShelfSort.values.any((e) => e.name == sort)) s = s.copyWith(sort: ShelfSort.parse(sort));
    if (query.containsKey('fav')) s = s.copyWith(fav: query['fav'] == '1' || query['fav'] == 'true');
    if (query.containsKey('new')) s = s.copyWith(newOnly: query['new'] == '1' || query['new'] == 'true');
    final view = query['view'];
    if (view != null && ShelfDensity.values.any((e) => e.name == view)) s = s.copyWith(density: ShelfDensity.parse(view));
    final tags = query['tags'];
    if (tags != null) s = s.copyWith(tagIds: [for (final p in tags.split(',')) if (int.tryParse(p.trim()) case final n? when n > 0) n]);
    if (query.containsKey('q')) s = s.copyWith(q: query['q']);
    return (query: s, openSelectMode: query['select'] == '1');
  }

  /// `GET /library/series` parameters.
  Map<String, String> toListParams() => {
        'sort': sort.wire,
        if (status.wire != null) 'reading_status': status.wire!,
        if (fav) 'is_favorite': 'true',
        if (newOnly) 'new_only': 'true',
        if (tagIds.isNotEmpty) 'tag_ids': tagIds.join(','),
        if (q.trim().isNotEmpty) 'search': q.trim(),
        'page': '1',
        'per_page': '200',
      };

  /// Stored per profile: everything except [q].
  String toStoredJson() => jsonEncode({
        'status': status.name,
        'sort': sort.name,
        'fav': fav,
        'new': newOnly,
        'tags': tagIds,
        'density': density.name,
      });

  static ShelfQuery? fromStoredJson(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final m = jsonDecode(raw);
      if (m is! Map) return null;
      return ShelfQuery(
        status: ShelfStatus.values.firstWhere((e) => e.name == m['status'], orElse: () => ShelfStatus.all),
        sort: ShelfSort.parse(m['sort'] as String?),
        fav: m['fav'] == true,
        newOnly: m['new'] == true,
        tagIds: [for (final t in (m['tags'] as List<dynamic>? ?? const [])) if (t is int) t],
        density: ShelfDensity.parse(m['density'] as String?),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is ShelfQuery &&
      other.status == status &&
      other.sort == sort &&
      other.fav == fav &&
      other.newOnly == newOnly &&
      listEquals(other.tagIds, tagIds) &&
      other.density == density &&
      other.q == q;

  @override
  int get hashCode => Object.hash(status, sort, fav, newOnly, Object.hashAll(tagIds), density, q);
}
