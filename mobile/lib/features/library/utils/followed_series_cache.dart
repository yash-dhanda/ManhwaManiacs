import 'dart:convert';

import 'package:manhwamaniacs/features/downloads/utils/mature_filter.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Write-through cache of the last library page the server answered with —
/// the same idea as `sources/utils/source_pins_cache.dart`, for the same
/// reason: the server owns this list, but an offline launch must not act as
/// though the library does not exist.
///
/// It exists for one thing the on-device chapter store structurally cannot
/// answer. The store is keyed by `(sourceId, seriesKey)`; the library series
/// route is keyed by `followed_id`, a server-side row id. With the server
/// unreachable there is nothing to translate one into the other, so a series
/// whose chapters are sitting on the phone still could not be opened. This
/// cache is that translation, and the offline library grid falls out of it.
///
/// Deliberately **not** a cache of chapter content or reading progress: the
/// chapters come from the store (which knows what is actually downloaded) and
/// progress is the server's, unknowable offline. Caching either here would
/// invent a second source of truth for both.
const followedSeriesCacheKey = 'manhwamaniacs:followed-series';

/// Keyed by the downloads scope id (`u{userId}p{profileId}`) rather than a
/// key of its own, so the offline library and the offline chapter store are
/// scoped identically by construction — one profile can never be shown
/// another profile's followed series, exactly as it can never be shown
/// another profile's downloads.
String followedSeriesCacheKeyFor(String scopeId) =>
    '$followedSeriesCacheKey:$scopeId';

/// The cached shelf. [gateOpen] false drops the series the device knows to be 18+ (the same rule
/// as the server's, `mature_filter.dart`); the merge and restamp paths read it unfiltered
/// (the default) so a hidden row is never lost from the cache.
List<FollowedSeries> readCachedFollowedSeries(
  SharedPreferences prefs,
  String key, {
  bool gateOpen = true,
}) {
  final raw = prefs.getString(key);
  if (raw == null || raw.isEmpty) return const [];
  try {
    final parsed = jsonDecode(raw);
    if (parsed is! List) return const [];
    return filterMature(
      parsed.whereType<Map<String, dynamic>>().map(FollowedSeries.fromJson),
      gateOpen: gateOpen,
      isMature: (s) => isMatureLocal(
        resolvedRating: s.rating,
        matureOverride: s.matureOverride,
        contentRating: s.contentRating,
        sourceMature: false,
      ),
    );
  } catch (_) {
    // A cache that cannot be read is a cache that is not there. Never let a
    // half-written or schema-drifted entry be the reason a screen throws.
    return const [];
  }
}

Future<void> writeCachedFollowedSeries(
  SharedPreferences prefs,
  String key,
  List<FollowedSeries> series,
) =>
    prefs.setString(key, jsonEncode([for (final s in series) s.toJson()]));

/// The cached follow row for [followedId], or `null` if this profile has
/// never had that series in a synced page.
FollowedSeries? cachedFollowedSeriesById(
  SharedPreferences prefs,
  String key,
  int followedId, {
  bool gateOpen = true,
}) {
  for (final series in readCachedFollowedSeries(prefs, key, gateOpen: gateOpen)) {
    if (series.id == followedId) return series;
  }
  return null;
}

/// The cached follow row for ([sourceId], [seriesKey]), or `null`: the cover and title a settings list shows for a series it
/// stores only by key (the recap skip list, the Circle's hidden series).
FollowedSeries? cachedFollowedSeriesByKey(
  SharedPreferences prefs,
  String key,
  String sourceId,
  String seriesKey, {
  bool gateOpen = true,
}) {
  for (final series in readCachedFollowedSeries(prefs, key, gateOpen: gateOpen)) {
    if (series.sourceId == sourceId && series.seriesKey == seriesKey) return series;
  }
  return null;
}
