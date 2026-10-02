import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/downloads/providers/offline_series_provider.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/providers/library_series_actions.dart';
import 'package:manhwamaniacs/features/library/providers/series_detail_provider.dart';
import 'package:manhwamaniacs/features/library/utils/series_identity.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/features/sources/utils/series_content_kind.dart';
import 'package:manhwamaniacs/features/updates/providers/updates_provider.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/screens/series/book_page.dart';
import 'package:manhwamaniacs/skins/glass/screens/series/manga_variant.dart';
import 'package:manhwamaniacs/skins/glass/screens/series/series_actions.dart';
import 'package:manhwamaniacs/skins/glass/screens/series/series_data.dart';
import 'package:manhwamaniacs/skins/glass/screens/series/series_detail.dart';
import 'package:manhwamaniacs/skins/glass/screens/series/series_states.dart';

bool _unavailableCode(Object e) => e is ApiError && (e.statusCode == 404 || const {'series_not_found', 'source_not_found', 'source_not_browsable'}.contains(e.code));

/// `/sources/:sourceId/series/:seriesKey` (glass 8.12, 8.13): the series detail or the book page by the series' content kind, with
/// every page-level state of 8.12 States and the unavailable lens of 8.0.8.
class GlassFeatureScreen extends ConsumerWidget {
  const GlassFeatureScreen({super.key, required this.sourceId, required this.seriesKey, this.chapter, this.sheet, this.velocity, this.followed});
  final String sourceId, seriesKey;
  final String? chapter, sheet;
  final Offset? velocity;

  /// The follow row when the caller already resolved it (`featureByFollow`).
  final FollowedSeries? followed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cached = ref.watch(updatesProvider.select((s) => s.valueOrNull?.followed));
    final row = cached == null ? followed : followFor(cached, sourceId, seriesKey);
    if (sourceKindPending(ref, sourceId)) return const SeriesSkeleton();
    final novel = isNovelSource(ref.watch(contentModeScopeProvider), sourceId) ?? false;
    final source = ref.watch(sourcesListProvider).valueOrNull?.where((s) => s.id == sourceId).firstOrNull;
    final gateOpen = ref.watch(matureContentProvider).valueOrNull ?? false;
    final mature = (source?.mature ?? false) || row?.rating == 'mature';
    if (mature && !gateOpen) return const SeriesLens(kind: SeriesLensKind.gated);
    final key = (sourceId: sourceId, seriesId: seriesKey);
    final detail = ref.watch(sourceSeriesDetailProvider(key));
    Widget page(GlassSeriesData d) => GlassSeriesPage(
          key: ValueKey('series-page-$sourceId-$seriesKey-$novel'),
          data: d,
          variant: novel ? BookVariant(mature: mature) : MangaVariant(velocity: velocity, mature: mature),
          focusChapter: chapter,
          sheet: sheet,
          velocity: velocity,
          mature: mature,
        );
    return detail.when(
      skipLoadingOnRefresh: true,
      loading: () => SeriesSkeleton(book: novel),
      error: (e, _) {
        void retry() => ref.invalidate(sourceSeriesDetailProvider(key));
        if (_unavailableCode(e)) {
          final f = row;
          final dead = e is ApiError && (e.code == 'source_not_found' || e.statusCode == 404);
          return SeriesLens(
            kind: SeriesLensKind.unavailable,
            sourceId: sourceId,
            book: novel,
            message: e is ApiError && e.code == 'source_not_browsable' ? "This source can't open series right now." : 'This series is no longer available from its source.',
            onMove: f != null && dead ? () => _moveStub(context, ref, f, novel) : null,
            onRemove: f == null
                ? null
                : () async {
                    final a = ref.read(librarySeriesActionsProvider);
                    final r = await a.remove(f);
                    ref.invalidate(updatesProvider);
                    if (r.error == null) showGlassToast(ref, GlassToastSpec('Removed ${f.title} from your library.', undo: () => fire(a.restore(f, slots: r.slots).then((_) => ref.invalidate(updatesProvider)))));
                    seriesBack(ref, sourceId: sourceId);
                  },
          );
        }
        if (e is NetworkError || e is TimeoutError) {
          // Offline with saved chapters: the page from the device, its saved chapters only.
          final saved = ref.watch(offlineEditionProvider((sourceId: sourceId, seriesKey: seriesKey))).valueOrNull;
          if (saved != null) {
            final f = row;
            final series = f == null
                ? saved.series
                : SourceSeriesSummary(id: seriesKey, sourceId: sourceId, title: f.title, chapterCount: f.chapterCount, genres: const [], coverUrl: f.coverUrl);
            return page(GlassSeriesData(sourceId: sourceId, seriesKey: seriesKey, series: series, chapters: saved.chapters, followed: row, novel: novel, offline: true));
          }
          return SeriesLens(kind: SeriesLensKind.offline, sourceId: sourceId, book: novel);
        }
        return SeriesLens(kind: SeriesLensKind.error, sourceId: sourceId, book: novel, onRetry: retry);
      },
      data: (v) => page(GlassSeriesData(sourceId: sourceId, seriesKey: seriesKey, series: v.series, chapters: v.chapters, followed: row, novel: novel)),
    );
  }

  /// Move to another source from the unavailable lens: the sheet needs the series' title, so it works from the follow row.
  void _moveStub(BuildContext context, WidgetRef ref, FollowedSeries f, bool novel) {
    final d = GlassSeriesData(
      sourceId: f.sourceId,
      seriesKey: f.seriesKey,
      series: SourceSeriesSummary(id: f.seriesKey, sourceId: f.sourceId, title: f.title, chapterCount: f.chapterCount, genres: const [], coverUrl: f.coverUrl),
      chapters: const [],
      followed: f,
      novel: novel,
    );
    openMoveSource(context, d);
  }
}

/// `/library/:followedId` (glass 8.0.3 `featureByFollow`): resolves the follow row and renders the same screen in place (the header
/// skeleton meanwhile, no redirect).
class GlassFeatureByFollowScreen extends ConsumerStatefulWidget {
  const GlassFeatureByFollowScreen({super.key, required this.followedId, this.chapter, this.sheet});
  final int followedId;
  final String? chapter, sheet;

  @override
  ConsumerState<GlassFeatureByFollowScreen> createState() => _GlassFeatureByFollowScreenState();
}

class _GlassFeatureByFollowScreenState extends ConsumerState<GlassFeatureByFollowScreen> {
  /// The row this route resolved to; from then on the page stays on that series (an unfollow
  /// deletes the id, an undo follows under a new one) and finds its follow by series.
  FollowedSeries? _pinned;

  Widget _page(FollowedSeries f) => GlassFeatureScreen(sourceId: f.sourceId, seriesKey: f.seriesKey, followed: f, chapter: widget.chapter, sheet: widget.sheet);

  @override
  Widget build(BuildContext context) {
    final followedId = widget.followedId;
    if (_pinned == null) {
      final cached = ref.watch(updatesProvider.select((s) => s.valueOrNull?.followed));
      for (final f in cached ?? const <FollowedSeries>[]) {
        if (f.id == followedId) _pinned = f;
      }
    }
    final pin = _pinned;
    if (pin != null) return _page(pin);
    return ref.watch(seriesDetailProvider(followedId)).whenData((v) => v.series).when(
          loading: () => const SeriesSkeleton(),
          data: (f) => _page(_pinned = f),
          error: (e, _) => e is ApiError && (e.statusCode == 404 || e.code == 'series_not_found')
              ? const SeriesLens(kind: SeriesLensKind.followMissing)
              : SeriesLens(kind: SeriesLensKind.error, onRetry: () => ref.invalidate(seriesDetailProvider(followedId))),
        );
  }
}
