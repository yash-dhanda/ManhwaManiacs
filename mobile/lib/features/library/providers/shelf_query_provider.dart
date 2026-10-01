import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/storage/profile_scoped_key.dart';
import 'package:manhwamaniacs/features/library/models/shelf_query.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefix = 'mm.shelf-query.';
const _legacyQueryKey = 'manhwamaniacs:library-query'; // K16
const _legacyCoverScaleKey = 'settings_library_cover_scale'; // K15

/// The retired legacy skin's stored query (K16) and cover-size slider (K15) as a [ShelfQuery];
/// null when neither was ever written. The keys are read and left in place.
ShelfQuery? migrateLegacyShelfQuery(SharedPreferences prefs) {
  final raw = prefs.getString(_legacyQueryKey);
  final scale = prefs.getDouble(_legacyCoverScaleKey);
  if ((raw == null || raw.isEmpty) && scale == null) return null;
  var q = const ShelfQuery();
  var viewList = false;
  if (raw != null && raw.isNotEmpty) {
    try {
      final m = jsonDecode(raw);
      if (m is Map) {
        final sort = (m['sort'] as String?)?.replaceAll('_', '').toLowerCase();
        final filter = m['filter'] as String?;
        viewList = m['viewMode'] == 'list';
        q = q.copyWith(
          sort: switch (sort) {
            'recentlyadded' => ShelfSort.added,
            'title' => ShelfSort.title,
            _ => ShelfSort.updated,
          },
          status: switch (filter) {
            'reading' => ShelfStatus.reading,
            'completed' => ShelfStatus.completed,
            _ => ShelfStatus.all,
          },
          fav: m['favoritesOnly'] == true,
        );
      }
    } catch (_) {}
  }
  final density = viewList
      ? ShelfDensity.list
      : (scale != null && scale < 0.85 ? ShelfDensity.compact : ShelfDensity.wall);
  return q.copyWith(density: density);
}

/// The shelf's query, persisted per profile (everything except the search text). The first read
/// for a profile with nothing stored migrates once from the legacy keys.
final shelfQueryProvider = NotifierProvider<ShelfQueryNotifier, ShelfQuery>(ShelfQueryNotifier.new, name: 'shelfQuery');

class ShelfQueryNotifier extends Notifier<ShelfQuery> {
  String _key({required bool watch}) => profileScopedKey(ref, prefix: _prefix, deviceKey: '${_prefix}device', watch: watch);

  @override
  ShelfQuery build() {
    final prefs = ref.watch(sharedPrefsProvider);
    return ShelfQuery.fromStoredJson(prefs.getString(_key(watch: true))) ?? migrateLegacyShelfQuery(prefs) ?? const ShelfQuery();
  }

  /// Applies [next] and stores it (never the search text).
  void set(ShelfQuery next) {
    final changedStored = next.copyWith(q: '') != state.copyWith(q: '');
    state = next;
    if (changedStored) {
      ref.read(sharedPrefsProvider).setString(_key(watch: false), next.toStoredJson());
    }
  }

  void patch(ShelfQuery Function(ShelfQuery q) f) => set(f(state));

  /// A route's parameters laid over the stored query for this visit; not stored.
  void applyRoute(Map<String, String> params) {
    final r = ShelfQuery.fromRoute(params, base: state).query;
    if (r != state) state = r;
  }
}
