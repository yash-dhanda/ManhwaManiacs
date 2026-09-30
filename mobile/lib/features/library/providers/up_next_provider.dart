import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/ai/models/similar_result.dart';
import 'package:manhwamaniacs/features/ai/providers/suggested_tags_provider.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/providers/intelligence_providers.dart';
import 'package:manhwamaniacs/features/library/utils/all_followed.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';

/// Which end state asks: the caught-up notice (only `More like this`) or the end of a completed
/// series (the full chain, cinematic 8.14.6).
enum UpNextMode { caughtUp, theEnd }

/// Where the rail's items came from, so the widget can caption them.
enum UpNextSource { similar, sameGenres, recommendations, shelf, none }

typedef UpNext = ({List<HomePickItem> items, UpNextSource source, String? reason});

const UpNext kNoUpNext = (items: <HomePickItem>[], source: UpNextSource.none, reason: null);

typedef UpNextKey = ({String sourceId, String seriesKey, UpNextMode mode});

/// The chain of cinematic 9.1.6: Similar (World cards with their `why`); with the AI desk closed
/// the shared-genre list; `caughtUp` stops there. `theEnd` continues to the first
/// Because-you-read section of the world recommendations, then to From your shelf (favourites,
/// then plan to read, most recently updated first, this series and completed series left out,
/// at most 12). A 404 from `/ai/similar` is unavailable, silently.
final upNextProvider = FutureProvider.autoDispose.family<UpNext, UpNextKey>((ref, k) async {
  final ai = ref.watch(aiRepositoryProvider);
  SimilarResult similar;
  try {
    similar = await ai.similar(SimilarQuery.series(k.sourceId, k.seriesKey));
  } catch (_) {
    similar = const SimilarResult(available: false, reason: 'failed');
  }
  if (similar.items.isNotEmpty) {
    return (
      items: [for (final w in similar.items) HomePickItem(world: w, why: w.why)],
      source: UpNextSource.similar,
      reason: null,
    );
  }
  final reason = similar.available ? null : (similar.reason == 'ok' ? 'not_configured' : similar.reason);
  SimilarResult genres;
  try {
    genres = await ai.similar(SimilarQuery.series(k.sourceId, k.seriesKey, fallbackGenres: true));
  } catch (_) {
    genres = const SimilarResult(available: false, reason: 'failed', basis: 'genres');
  }
  final fromGenres = <HomePickItem>[for (final w in genres.items) HomePickItem(world: w)];
  if (fromGenres.isNotEmpty) return (items: fromGenres, source: UpNextSource.sameGenres, reason: reason);
  if (k.mode == UpNextMode.caughtUp) return (items: const <HomePickItem>[], source: UpNextSource.none, reason: reason);

  try {
    final rec = await ref.watch(recommendationsProvider.future);
    for (final s in rec.sections) {
      if (s.items.isNotEmpty) {
        return (
          items: [for (final w in s.items) HomePickItem(world: w, why: w.why)],
          source: UpNextSource.recommendations,
          reason: reason,
        );
      }
    }
  } catch (_) {}

  final followed = await listAllFollowed(ref.watch(libraryRepositoryProvider));
  if (followed.isErr) return (items: const <HomePickItem>[], source: UpNextSource.none, reason: reason);
  final rows = [
    for (final f in followed.value)
      if (!(f.sourceId == k.sourceId && f.seriesKey == k.seriesKey) && f.readingStatus != 'completed') f,
  ];
  DateTime stamp(FollowedSeries f) => f.updatedAt ?? f.lastCheckedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  int recent(FollowedSeries a, FollowedSeries b) => stamp(b).compareTo(stamp(a));
  final favourites = rows.where((f) => f.isFavorite).toList()..sort(recent);
  final planned = rows.where((f) => !f.isFavorite && f.readingStatus == 'plan_to_read').toList()..sort(recent);
  final shelf = [...favourites, ...planned].take(12);
  return (
    items: [
      for (final f in shelf)
        HomePickItem(
          source: SourceSeriesSummary(
            id: f.seriesKey,
            sourceId: f.sourceId,
            seriesIdentity: f.seriesIdentity,
            title: f.title,
            chapterCount: f.chapterCount,
            genres: const [],
            coverUrl: f.coverUrl,
            ambient: f.ambient,
          ),
        ),
    ],
    source: UpNextSource.shelf,
    reason: reason,
  );
}, name: 'upNext',);
