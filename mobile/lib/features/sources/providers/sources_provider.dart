import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/utils/pagination.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';

final sourcesListProvider =
    FutureProvider.autoDispose<List<SourceSummary>>((ref) async {
  final repo = ref.watch(sourcesRepositoryProvider);
  final result = await repo.listSources();
  if (result.isErr) throw result.error;
  return result.value;
});

/// Free-text filter over the Sources screen. With ~50 connectors this is the
/// primary way to reach one, so it lives in a provider rather than screen state
/// and survives a rebuild of the list.
final sourcesFilterQueryProvider = StateProvider<String>(
  (ref) => '',
  name: 'sourcesFilterQuery',
);

enum SourcesFilter { all, pinned, mature }

final sourcesFilterProvider = StateProvider<SourcesFilter>(
  (ref) => SourcesFilter.all,
  name: 'sourcesFilter',
);

class SourceBrowseQuery {
  const SourceBrowseQuery({
    required this.sourceId,
    this.search = '',
    this.sort = 'default',
    this.genre,
  });

  final String sourceId;
  final String search;
  final String sort;
  final String? genre;

  /// [genre] `''` clears the genre filter.
  SourceBrowseQuery copyWith({
    String? search,
    String? sort,
    String? genre,
  }) =>
      SourceBrowseQuery(
        sourceId: sourceId,
        search: search ?? this.search,
        sort: sort ?? this.sort,
        genre: genre == null ? this.genre : (genre.isEmpty ? null : genre),
      );

  @override
  bool operator ==(Object other) =>
      other is SourceBrowseQuery &&
      other.sourceId == sourceId &&
      other.search == search &&
      other.sort == sort &&
      other.genre == genre;

  @override
  int get hashCode => Object.hash(sourceId, search, sort, genre);
}

final sourceBrowseQueryProvider =
    StateProvider.family<SourceBrowseQuery, String>(
  (ref, sourceId) => SourceBrowseQuery(sourceId: sourceId),
  name: 'sourceBrowseQuery',
);

final sourceBrowseModesProvider = FutureProvider.autoDispose
    .family<List<SourceBrowseMode>, String>((ref, sourceId) async {
  final repo = ref.watch(sourcesRepositoryProvider);
  final result = await repo.listBrowseModes(sourceId);
  if (result.isErr) throw result.error;
  return result.value;
});

/// Accumulated, infinite-scrollable browse results for one source. Mirrors
/// [LibraryListNotifier]'s accumulate-on-loadMore pattern rather than the
/// page-by-page replace the source browser originally used.
class SourceBrowseState {
  const SourceBrowseState({
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.hasNext = false,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
    this.cache,
    this.query,
  });

  /// The query these items answer. A rebuild for a new query keeps the old
  /// value attached while it loads or fails, so screens compare this with the
  /// current query rather than drawing the old posters under the new label.
  final SourceBrowseQuery? query;

  /// The `cache` block of the newest page fetched from page 1 / refresh.
  final Map<String, dynamic>? cache;
  final bool loadMoreFailed;
  final List<SourceSeriesSummary> items;
  final int total;
  final int page;
  final bool hasNext;
  final bool isLoadingMore;

  bool get isEmpty => items.isEmpty;

  /// Whether this value answers [current] (or does not say which query it is).
  bool answers(SourceBrowseQuery current) => query == null || query == current;

  /// The header count. Many connectors report the page size (or 0) as the
  /// total, so while more pages remain a total no larger than what is loaded
  /// reads as "N+".
  String get countLabel =>
      hasNext && total <= items.length ? '${items.length}+' : '$total';

  SourceBrowseState copyWith({
    List<SourceSeriesSummary>? items,
    int? total,
    int? page,
    bool? hasNext,
    bool? isLoadingMore,
    bool? loadMoreFailed,
  }) =>
      SourceBrowseState(
        items: items ?? this.items,
        total: total ?? this.total,
        page: page ?? this.page,
        hasNext: hasNext ?? this.hasNext,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
        cache: cache,
        query: query,
      );
}

final sourceBrowseProvider = AsyncNotifierProvider.autoDispose
    .family<SourceBrowseNotifier, SourceBrowseState, String>(
  SourceBrowseNotifier.new,
  name: 'sourceBrowse',
);

class SourceBrowseNotifier
    extends AutoDisposeFamilyAsyncNotifier<SourceBrowseState, String> {
  @override
  Future<SourceBrowseState> build(String sourceId) async {
    // Re-fetches from page 1 whenever search/sort changes -- matching
    // LibraryListNotifier/SearchListNotifier, which don't carry a `page`
    // field in their query either; a fresh query always restarts pagination.
    final query = ref.watch(sourceBrowseQueryProvider(sourceId));
    final gen = ++_gen;
    var page = await _fetchPage(sourceId, query, 1);
    // The 18+ gate can empty a whole page while the source still has more;
    // skip ahead a few pages rather than calling the catalogue empty.
    for (var i = 0; i < _maxEmptySkips && page.items.isEmpty && page.hasNext; i++) {
      if (gen != _gen) break;
      final next = await _fetchPageResult(sourceId, query, page.page + 1);
      if (next.isErr) break;
      page = next.value;
    }
    return SourceBrowseState(
      items: page.items,
      total: page.total < page.items.length ? page.items.length : page.total,
      page: page.page,
      hasNext: page.hasNext,
      cache: page.cache,
      query: query,
    );
  }

  static const _maxEmptySkips = 4;

  /// Bumped by every [build]; a [loadMore] that started under an older query
  /// drops its page instead of writing it over the new results.
  int _gen = 0;

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null ||
        !current.hasNext ||
        current.isLoadingMore ||
        state.isLoading ||
        current.query != ref.read(sourceBrowseQueryProvider(arg))) {
      return;
    }
    final gen = _gen;

    state =
        AsyncData(current.copyWith(isLoadingMore: true, loadMoreFailed: false));

    final query = current.query!;
    final nextPage = current.page + 1;
    final result = await _fetchPageResult(arg, query, nextPage);
    if (gen != _gen) return;

    if (result.isErr) {
      // Leave existing items in place; just stop showing the loading spinner
      // so the user can retry by scrolling again.
      state = AsyncData(
          current.copyWith(isLoadingMore: false, loadMoreFailed: true),);
      return;
    }

    final page = result.value;
    // Pages are cached independently, so neighbours can overlap.
    final seen = {for (final s in current.items) s.id};
    final items = [
      ...current.items,
      for (final s in page.items)
        if (seen.add(s.id)) s,
    ];
    state = AsyncData(
      current.copyWith(
        items: items,
        total: [current.total, page.total, items.length]
            .reduce((a, b) => a > b ? a : b),
        page: page.page,
        hasNext: page.hasNext,
        isLoadingMore: false,
      ),
    );
  }

  /// True when the source answered; on failure the previous grid stays (as
  /// the AsyncError's value) and the caller tells the user.
  Future<bool> refresh() async {
    // Keep the previous value attached so the AsyncValue stays *reloading*
    // rather than a fresh load; skipLoadingOnReload then keeps the grid on
    // screen (behind the RefreshIndicator spinner) instead of flashing the
    // full-screen "Opening…" loader.
    state = const AsyncLoading<SourceBrowseState>().copyWithPrevious(state);
    // `refresh=true` asks the source itself, past the server's saved copy.
    _forceRefresh = true;
    state = await AsyncValue.guard(() => build(arg));
    return !state.hasError;
  }

  bool _forceRefresh = false;

  Future<PagedResult<SourceSeriesSummary>> _fetchPage(
    String sourceId,
    SourceBrowseQuery query,
    int page,
  ) async {
    final result = await _fetchPageResult(sourceId, query, page);
    if (result.isErr) throw result.error;
    return result.value;
  }

  Future<Result<PagedResult<SourceSeriesSummary>>> _fetchPageResult(
    String sourceId,
    SourceBrowseQuery query,
    int page,
  ) {
    final repo = ref.read(sourcesRepositoryProvider);
    final refresh = _forceRefresh && page == 1;
    if (refresh) _forceRefresh = false;
    return repo.listSeries(
      sourceId,
      page: page,
      query: query.search.isEmpty ? null : query.search,
      sort: query.sort == 'default' ? null : query.sort,
      genre: query.genre,
      refresh: refresh,
    );
  }
}

class SourceSeriesDetailData {
  const SourceSeriesDetailData({
    required this.series,
    required this.chapters,
  });

  final SourceSeriesSummary series;
  final List<SourceChapterSummary> chapters;
}

final sourceSeriesDetailProvider = FutureProvider.autoDispose
    .family<SourceSeriesDetailData, ({String sourceId, String seriesId})>(
  (ref, params) async {
    final repo = ref.watch(sourcesRepositoryProvider);
    final seriesResult = await repo.getSeries(params.sourceId, params.seriesId);
    final chaptersResult =
        await repo.getChapters(params.sourceId, params.seriesId);
    if (seriesResult.isErr) throw seriesResult.error;
    if (chaptersResult.isErr) throw chaptersResult.error;
    return SourceSeriesDetailData(
      series: seriesResult.value,
      chapters: chaptersResult.value,
    );
  },
);
