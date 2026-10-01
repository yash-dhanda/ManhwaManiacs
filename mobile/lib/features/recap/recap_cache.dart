import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/storage/profile_scoped_key.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/features/recap/recap_deck.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';

const kRecapCachePrefix = 'mm.recap.cache.';
const kRecapCacheMax = 20;

/// `"{source}:{series}:{to}:{scope}"`.
String recapCacheKey(String source, String series, String to, String scope) => '$source:$series:$to:$scope';

class CachedRecap {
  const CachedRecap(this.deck, this.savedAt);
  final DeckState deck;
  final DateTime savedAt;
}

/// Finished decks per profile in SharedPreferences (`mm.recap.cache.u{user}p{profile}`), at most 20, least recently opened evicted.
/// The 18+ purge deletes the whole key: cached recap payloads are never kept and never refetched offline.
final recapCacheProvider = Provider<RecapCache>(RecapCache.new, name: 'recapCache');

class RecapCache {
  RecapCache(this._ref);
  final Ref _ref;

  String get _key => profileScopedKey(_ref, prefix: kRecapCachePrefix, deviceKey: '${kRecapCachePrefix}device', watch: false);

  Map<String, Map<String, dynamic>> _load() {
    final raw = _ref.read(sharedPrefsProvider).getString(_key);
    if (raw == null) return {};
    try {
      final d = jsonDecode(raw);
      if (d is Map) return {for (final e in d.entries) if (e.value is Map) e.key as String: Map<String, dynamic>.from(e.value as Map)};
    } catch (_) {}
    return {};
  }

  Future<void> _store(Map<String, Map<String, dynamic>> m) => _ref.read(sharedPrefsProvider).setString(_key, jsonEncode(m));

  /// The saved deck for [key], marking it most recently opened.
  Future<CachedRecap?> readCachedRecap(String key) async {
    final m = _load();
    final e = m[key];
    if (e == null) return null;
    e['openedAt'] = _ref.read(clockProvider)().toIso8601String();
    await _store(m);
    final saved = DateTime.tryParse(e['savedAt'] as String? ?? '');
    if (saved == null) return null;
    return CachedRecap(DeckState.fromJson(e), saved);
  }

  Future<void> save(String key, DeckState deck) async {
    final now = _ref.read(clockProvider)().toIso8601String();
    final m = _load();
    m[key] = {...deck.toJson(), 'savedAt': now, 'openedAt': now};
    while (m.length > kRecapCacheMax) {
      final oldest = m.entries.reduce((a, b) => '${a.value['openedAt']}'.compareTo('${b.value['openedAt']}') <= 0 ? a : b);
      m.remove(oldest.key);
    }
    await _store(m);
  }

  /// The 18+ purge and sign-out.
  Future<void> clear() => _ref.read(sharedPrefsProvider).remove(_key);
}
