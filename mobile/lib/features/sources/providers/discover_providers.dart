import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/network/request_limiter.dart';
import 'package:manhwamaniacs/features/library/providers/genre_weights_provider.dart';
import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/features/sources/models/source_genre.dart';
import 'package:manhwamaniacs/features/sources/models/source_health.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/features/sources/providers/source_pins_provider.dart';
import 'package:manhwamaniacs/features/sources/utils/genre_index.dart';
import 'package:manhwamaniacs/features/sources/utils/trending.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';

/// A source's genre list, fetched at most once per source per 24 h (P3).
final sourceGenresProvider = FutureProvider.autoDispose
    .family<List<SourceGenre>, String>((ref, sourceId) async {
  final link = ref.keepAlive();
  final timer = Timer(const Duration(hours: 24), link.close);
  ref.onDispose(timer.cancel);
  final result = await ref.read(requestLimiterProvider).run(RequestPriority.p3,
      () => ref.read(sourcesRepositoryProvider).listGenres(sourceId),);
  if (result.isErr) return const [];
  return result.value;
});

/// `GET /sources/health` rows (worst first).
final sourcesHealthProvider =
    FutureProvider.autoDispose<List<SourceSummary>>((ref) async {
  final result = await ref.read(requestLimiterProvider).run(RequestPriority.p1,
      () => ref.read(sourcesRepositoryProvider).listHealth(),);
  if (result.isErr) throw result.error;
  return result.value;
});

final sourceHealthSummaryProvider =
    FutureProvider.autoDispose<SourceHealthSummary>((ref) async {
  final result = await ref.read(requestLimiterProvider).run(RequestPriority.p1,
      () => ref.read(sourcesRepositoryProvider).healthSummary(),);
  if (result.isErr) throw result.error;
  return result.value;
});

/// Page 1 of a source's `popular` browse mode (P3); `[]` when it has none.
final popularFirstPageProvider = FutureProvider.autoDispose
    .family<List<SourceSeriesSummary>, String>((ref, sourceId) async {
  final repo = ref.read(sourcesRepositoryProvider);
  final limiter = ref.read(requestLimiterProvider);
  final modes = await limiter.run(
      RequestPriority.p3, () => repo.listBrowseModes(sourceId),);
  if (modes.isErr || !modes.value.any((m) => m.id == 'popular')) {
    return const [];
  }
  final page = await limiter.run(
    RequestPriority.p3,
    () => repo.listSeries(sourceId, sort: 'popular'),
  );
  return page.isErr ? const [] : page.value.items;
});

/// The genre tiles: union of the pinned sources' genres by profile weight.
final genreIndexProvider =
    FutureProvider.autoDispose<List<GenreEntry>>((ref) async {
  final pins = ref.watch(sourcePinsProvider).valueOrNull?.pins ?? const [];
  final live = [
    for (final p in pins)
      if (p.available) p,
  ];
  final genres = <String, List<SourceGenre>>{};
  await Future.wait([
    for (final p in live)
      ref
          .watch(sourceGenresProvider(p.sourceId).future)
          .then((g) => genres[p.sourceId] = g),
  ]);
  final weights = await ref.watch(genreWeightsProvider(40).future);
  return buildGenreIndex(live, genres, weights);
});

final trendingProvider =
    FutureProvider.autoDispose<List<TrendingTitle>>((ref) async {
  final pins = ref.watch(sourcePinsProvider).valueOrNull?.pins ?? const [];
  final live = [
    for (final p in pins)
      if (p.available) p,
  ];
  final pages = <String, List<SourceSeriesSummary>>{};
  await Future.wait([
    for (final p in live)
      ref
          .watch(popularFirstPageProvider(p.sourceId).future)
          .then((s) => pages[p.sourceId] = s),
  ]);
  return buildTrending(live, pages);
});

/// First series of [genre] on [sourceId], for a genre tile's cover (P3).
final genreCoverProvider = FutureProvider.autoDispose
    .family<SourceSeriesSummary?, ({String sourceId, String genre})>(
        (ref, key) async {
  final result = await ref.read(requestLimiterProvider).run(
        RequestPriority.p3,
        () => ref
            .read(sourcesRepositoryProvider)
            .listSeries(key.sourceId, genre: key.genre),
      );
  if (result.isErr || result.value.items.isEmpty) return null;
  return result.value.items.first;
});

/// Dialogue still page image bytes at 480 px wide (P3).
typedef StillImageFetch = Future<Uint8List?> Function(String url);
