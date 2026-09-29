import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloaded_series_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/downloads/providers/mature_gate_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/mature_stamper.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/home/utils/continue_hidden.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/providers/shelf_query_provider.dart';
import 'package:manhwamaniacs/features/library/utils/all_followed.dart';
import 'package:manhwamaniacs/features/library/utils/followed_series_cache.dart';
import 'package:manhwamaniacs/features/library/utils/offline_shelf.dart';
import 'package:manhwamaniacs/features/library/utils/shelf_counts.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The shelf page: up to 200 rows the server sorted and filtered, the server's total, and whether
/// this is the offline edition (saved series only).
typedef ShelfResult = ({List<FollowedSeries> rows, int total, bool offline});

final shelfProvider = AsyncNotifierProvider.autoDispose<ShelfNotifier, ShelfResult>(ShelfNotifier.new, name: 'shelf');

class ShelfNotifier extends AutoDisposeAsyncNotifier<ShelfResult> {
  @override
  Future<ShelfResult> build() async {
    final q = ref.watch(shelfQueryProvider);
    final scope = ref.watch(contentModeScopeProvider);
    final gateOpen = ref.watch(matureGateOpenProvider);
    final repo = ref.read(libraryRepositoryProvider);
    final r = await repo.listSeries(
      perPage: 200,
      sort: q.sort.wire,
      search: q.q.trim().isEmpty ? null : q.q.trim(),
      readingStatus: q.status.wire,
      isFavorite: q.fav ? true : null,
      tagIds: q.tagIds.isEmpty ? null : q.tagIds,
      newOnly: q.newOnly ? true : null,
    );
    if (r.isErr) {
      final e = r.error;
      if (e is NetworkError || e is TimeoutError) return _offline(scope, gateOpen);
      throw e;
    }
    final page = r.value;
    // Everything the cache write needs is read now: after the await, the build may be outdated.
    final key = _cacheKey;
    if (key != null) {
      unawaited(_cache(ref.read(sharedPrefsProvider), key, ref.read(matureStamperProvider), page.items, authoritative: !q.filtering, total: page.total));
    }
    return (rows: scope.filter(page.items, (s) => s.sourceId), total: page.total, offline: false);
  }

  String? get _cacheKey {
    final id = ref.read(activeDownloadsScopeIdProvider);
    return id == null ? null : followedSeriesCacheKeyFor(id);
  }

  /// An unfiltered page holding the whole library replaces the follow cache; anything narrower
  /// merges, so a filter never shrinks the shelf an offline launch shows.
  static Future<void> _cache(
    SharedPreferences prefs,
    String key,
    MatureStamper stamper,
    List<FollowedSeries> items, {
    required bool authoritative,
    required int total,
  }) async {
    if (authoritative && total <= items.length) {
      await writeCachedFollowedSeries(prefs, key, items);
    } else {
      final merged = {
        for (final s in readCachedFollowedSeries(prefs, key)) s.id: s,
        for (final s in items) s.id: s,
      };
      await writeCachedFollowedSeries(prefs, key, merged.values.toList());
    }
    unawaited(stamper.restampMissing());
  }

  Future<ShelfResult> _offline(ContentModeScope scope, bool gateOpen) async {
    final key = _cacheKey;
    final cached = key == null ? const <FollowedSeries>[] : readCachedFollowedSeries(ref.read(sharedPrefsProvider), key, gateOpen: gateOpen);
    final saved = await ref.watch(downloadedSeriesProvider.future);
    final rows = offlineShelf(cachedFollows: cached, saved: saved, matureEnabled: gateOpen);
    final scoped = scope.filter(rows, (s) => s.sourceId);
    return (rows: scoped, total: scoped.length, offline: true);
  }

  /// Replaces one row in place (a favourite or status change) without refetching the page.
  void replace(FollowedSeries row) {
    final cur = state.valueOrNull;
    if (cur == null) return;
    state = AsyncData((rows: [for (final s in cur.rows) s.id == row.id ? row : s], total: cur.total, offline: cur.offline));
  }

  /// Puts [rows] in place of the rows they share an id with.
  void replaceMany(Iterable<FollowedSeries> rows) {
    final by = {for (final r in rows) r.id: r};
    final cur = state.valueOrNull;
    if (cur == null || by.isEmpty) return;
    state = AsyncData((rows: [for (final s in cur.rows) by[s.id] ?? s], total: cur.total, offline: cur.offline));
  }

  /// Takes a row out of the page (an unfollow).
  void removeRow(int id) {
    final cur = state.valueOrNull;
    if (cur == null) return;
    state = AsyncData((rows: [for (final s in cur.rows) if (s.id != id) s], total: cur.total > 0 ? cur.total - 1 : 0, offline: cur.offline));
  }

  /// Sets the page's order in place (a manual-order drop) before the writes land.
  void setRows(List<FollowedSeries> rows) {
    final cur = state.valueOrNull;
    if (cur == null) return;
    state = AsyncData((rows: rows, total: cur.total, offline: cur.offline));
  }
}

/// The masthead deck's and slug line's counts over the whole followed list, in the active mode.
final shelfCountsProvider = FutureProvider.autoDispose<ShelfCounts>((ref) async {
  final scope = ref.watch(contentModeScopeProvider);
  final gateOpen = ref.watch(matureGateOpenProvider);
  final r = await listAllFollowed(ref.read(libraryRepositoryProvider));
  if (r.isErr) {
    final e = r.error;
    if (e is NetworkError || e is TimeoutError) {
      final id = ref.read(activeDownloadsScopeIdProvider);
      final cached = id == null ? const <FollowedSeries>[] : readCachedFollowedSeries(ref.read(sharedPrefsProvider), followedSeriesCacheKeyFor(id), gateOpen: gateOpen);
      final saved = await ref.watch(downloadedSeriesProvider.future);
      return shelfCounts(scope.filter(offlineShelf(cachedFollows: cached, saved: saved, matureEnabled: gateOpen), (s) => s.sourceId));
    }
    throw e;
  }
  return shelfCounts(scope.filter(r.value, (s) => s.sourceId));
});

/// The Continue cuttings of the shelf: up to 12 rows, minus the ones removed from the row, each
/// with its `recap` availability so Quick look's `Previously on` follows 9.1.5.
final shelfContinueProvider = FutureProvider.autoDispose<List<HomeContinueItem>>((ref) async {
  final hidden = ref.watch(continueHiddenProvider);
  final r = await ref.read(libraryRepositoryProvider).continueReading(limit: 12);
  if (r.isErr) throw r.error;
  return [
    for (final row in filterHidden(r.value, hidden)) HomeContinueItem(row: row, recap: RecapAvailability.tryParse(row.recapRaw)),
  ];
});
