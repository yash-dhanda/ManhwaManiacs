import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/features/sources/utils/series_content_kind.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/book/book_view.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_data.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_states.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/manga_view.dart';

bool _notFound(Object e) =>
    e is ApiError &&
    (e.statusCode == 404 || e.code == 'series_not_found' || e.code == 'source_not_found');

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
  });

  final String sourceId;
  final String seriesKey;
  final FollowedSeries? followed;
  final String? focusChapter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(sourceSeriesDetailProvider((sourceId: sourceId, seriesId: seriesKey)));
    return detail.when(
      loading: () => const FeatureGalley(),
      error: (e, _) => _notFound(e)
          ? FeatureNotAvailable(title: followed?.title)
          : FeatureNotice(
              kicker: 'CORRECTION',
              headline: "Couldn't load this series.",
              deck: 'The source did not answer.',
              primaryLabel: 'Try again',
              onPrimary: () => ref.invalidate(
                  sourceSeriesDetailProvider((sourceId: sourceId, seriesId: seriesKey)),),
              quietLabel: 'Back to the source',
              onQuiet: () => context.canPop() ? context.pop() : context.go('/sources/$sourceId'),
            ),
      data: (v) {
        final data = FeatureData(
          sourceId: sourceId,
          seriesKey: seriesKey,
          series: v.series,
          chapters: v.chapters,
          followed: followed,
        );
        final novel = isNovelSource(ref.watch(contentModeScopeProvider), sourceId) ?? false;
        return novel
            ? BookView(data: data, focusChapter: focusChapter)
            : MangaFeatureView(data: data);
      },
    );
  }
}
