import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/downloads/utils/mature_filter.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/utils/followed_series_cache.dart';
import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/features/sources/utils/source_pins_cache.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';

/// Stamps every on-device row that names a series with whether it is 18+, from what the device
/// knows, and re-stamps when the answer changes. Works from local caches only, so it runs offline.
class MatureStamper {
  MatureStamper(this._ref);
  final Ref _ref;

  static final _scopeRe = RegExp(r'^u(\d+)p(\d+)$');

  /// The stamp for a series: the offline follow cache's resolved rating, else the source's own
  /// `mature` flag (pin cache, then the loaded sources list), else null (not known).
  Future<bool?> resolve(String sourceId, String seriesKey) async {
    final scope = _ref.read(activeDownloadsScopeIdProvider);
    if (scope == null) return null;
    final prefs = _ref.read(sharedPrefsProvider);
    for (final s in readCachedFollowedSeries(prefs, followedSeriesCacheKeyFor(scope))) {
      if (s.sourceId == sourceId && s.seriesKey == seriesKey) {
        return isMatureLocal(
          resolvedRating: s.rating,
          matureOverride: s.matureOverride,
          contentRating: s.contentRating,
          sourceMature: false,
        );
      }
    }
    final m = _scopeRe.firstMatch(scope);
    if (m != null) {
      final key = sourcePinsCacheKeyFor(userId: int.parse(m.group(1)!), profileId: int.parse(m.group(2)!));
      for (final pin in readCachedSourcePins(prefs, key)) {
        if (pin.sourceId == sourceId) return pin.mature;
      }
    }
    for (final src in _ref.read(sourcesListProvider).valueOrNull ?? const <SourceSummary>[]) {
      if (src.id == sourceId) return src.mature;
    }
    return null;
  }

  /// A series was re-rated (`mature_override` changed): re-stamp its rows in every store and
  /// rewrite its follow-cache row with the server's resolved [rating].
  Future<void> restampSeries(
    String sourceId,
    String seriesKey,
    bool mature, {
    String? rating,
    bool? matureOverride,
    bool overrideGiven = false,
  }) async {
    final store = _ref.read(downloadsStoreProvider);
    if (store != null) await store.stampSeries(sourceId, seriesKey, mature);
    final scope = _ref.read(activeDownloadsScopeIdProvider);
    if (scope == null) return;
    final prefs = _ref.read(sharedPrefsProvider);
    final key = followedSeriesCacheKeyFor(scope);
    final rows = readCachedFollowedSeries(prefs, key);
    var changed = false;
    final out = <FollowedSeries>[];
    for (final s in rows) {
      if (s.sourceId == sourceId && s.seriesKey == seriesKey) {
        out.add(
          s.withRating(
            rating ?? (mature ? 'mature' : 'safe'),
            matureOverride: matureOverride,
            setOverride: overrideGiven,
          ),
        );
        changed = true;
      } else {
        out.add(s);
      }
    }
    if (changed) await writeCachedFollowedSeries(prefs, key, out);
  }

  /// Stamps every row whose stamp is null from the caches, else false. Once per session and after
  /// each library sync that writes the follow cache.
  Future<void> restampMissing() async {
    final store = _ref.read(downloadsStoreProvider);
    if (store == null) return;
    try {
      for (final (sourceId, seriesKey) in await store.unstampedSeries()) {
        final m = await resolve(sourceId, seriesKey);
        await store.stampSeriesWhereMissing(sourceId, seriesKey, m ?? false);
      }
    } catch (_) {
      // Housekeeping: a store that cannot answer is retried on the next launch or sync.
    }
  }
}

final matureStamperProvider = Provider<MatureStamper>(MatureStamper.new, name: 'matureStamper');

/// Runs [MatureStamper.restampMissing] once whenever the downloads scope becomes known. Watched by
/// the shell (or anything long-lived); a no-op without a scope.
final matureRestampOnScopeProvider = Provider<void>(
  (ref) {
    if (ref.watch(activeDownloadsScopeIdProvider) == null) return;
    unawaited(ref.read(matureStamperProvider).restampMissing());
  },
  name: 'matureRestampOnScope',
);
