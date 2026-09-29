import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/sources/models/series_enrichment.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';

/// The AniList credits for a series; `null` while there is no match or on any
/// failure (the page simply omits the lines). Kept alive for an hour.
final seriesEnrichmentProvider = FutureProvider.autoDispose
    .family<SeriesEnrichment?, ({String sourceId, String seriesKey})>((ref, key) async {
  final link = ref.keepAlive();
  final timer = Future<void>.delayed(const Duration(hours: 1), link.close);
  ref.onDispose(timer.ignore);
  final result =
      await ref.watch(sourcesRepositoryProvider).seriesEnrichment(key.sourceId, key.seriesKey);
  return result.isErr ? null : result.value;
});
