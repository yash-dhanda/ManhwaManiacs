import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/features/sources/utils/series_content_kind.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/book/book_states.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/book/book_view.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_data.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_states.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/manga_view.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/offline_edition.dart';

bool _notFound(Object e) =>
    e is ApiError &&
    (e.statusCode == 404 || e.code == 'series_not_found' || e.code == 'source_not_found');

/// `3 H`, `2 D`, `40 M`: how old a saved copy is.
String savedCopyAge(DateTime fetchedAt, {DateTime? now}) {
  final d = (now ?? DateTime.now()).difference(fetchedAt);
  if (d.inDays >= 1) return '${d.inDays} D';
  if (d.inHours >= 1) return '${d.inHours} H';
  return '${d.inMinutes.clamp(1, 59)} M';
}

/// The one series page for `/sources/:sourceId/series/:seriesKey` and
/// `/library/:followedId`: chooses the manga Feature or the novel Book page by
/// the source's content kind, and owns loading and failure states.
class FeatureView extends ConsumerWidget {
  const FeatureView({
    super.key,
    required this.sourceId,
    required this.seriesKey,
    this.followed,
    this.focusChapter,
    this.tab,
  });

  final String sourceId;
  final String seriesKey;
  final FollowedSeries? followed;
  final String? focusChapter;

  /// `?tab=more-like-this`.
  final String? tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (sourceId: sourceId, seriesId: seriesKey);
    final novel = isNovelSource(ref.watch(contentModeScopeProvider), sourceId);
    final detail = ref.watch(sourceSeriesDetailProvider(key));
    return detail.when(
      loading: () => novel ?? false ? const BookGalley() : const FeatureGalley(),
      error: (e, _) {
        if (_notFound(e)) return FeatureNotAvailable(title: followed?.title);
        void retry() => ref.invalidate(sourceSeriesDetailProvider(key));
        if (e is NetworkError) {
          final saved =
              ref.watch(offlineEditionProvider((sourceId: sourceId, seriesKey: seriesKey))).valueOrNull;
          if (saved != null) {
            final data = FeatureData(
              sourceId: sourceId,
              seriesKey: seriesKey,
              series: saved.series,
              chapters: saved.chapters,
              followed: followed,
            );
            return novel ?? false
                ? BookView(data: data, focusChapter: focusChapter)
                : MangaFeatureView(data: data, offlineEdition: true, initialTab: tab);
          }
          if (novel ?? false) return BookOfflineNotice(sourceId: sourceId);
        }
        if (novel ?? false) return BookErrorNotice(sourceId: sourceId, onRetry: retry);
        return FeatureNotice(
          kicker: 'CORRECTION',
          headline: "Couldn't load this series.",
          deck: 'The source did not answer.',
          primaryLabel: 'Try again',
          onPrimary: retry,
          quietLabel: 'Back to the source',
          onQuiet: () => context.canPop() ? context.pop() : context.go('/sources/$sourceId'),
        );
      },
      data: (v) {
        final data = FeatureData(
          sourceId: sourceId,
          seriesKey: seriesKey,
          series: v.series,
          chapters: v.chapters,
          followed: followed,
        );
        final fetched = v.series.cacheFetchedAt;
        return (novel ?? false)
            ? BookView(data: data, focusChapter: focusChapter)
            : MangaFeatureView(
                data: data,
                initialTab: tab,
                savedCopy: v.series.cacheStale && fetched != null ? savedCopyAge(fetched) : null,
              );
      },
    );
  }
}
