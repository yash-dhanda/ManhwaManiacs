import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/pagination.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/reader/models/reader_page.dart';
import 'package:manhwamaniacs/features/sources/models/series_enrichment.dart';
import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/features/sources/models/source_genre.dart';
import 'package:manhwamaniacs/features/sources/models/source_health.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/features/sources/providers/discover_providers.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/features/sources/repositories/sources_repository.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';

SourceSeriesSummary _series(String id, {String title = 'Series'}) {
  return SourceSeriesSummary(
    id: id,
    sourceId: 'test-source',
    title: title,
    chapterCount: 10,
    genres: const [],
    coverUrl: 'https://example.com/$id.jpg',
  );
}

class _FakeSourcesRepository implements SourcesRepository {

  @override
  Future<Result<List<ReaderPage>>> getChapterPages(String sourceId, String chapterKey) async => const Ok([]);

  @override
  Future<Result<List<SourceGenre>>> listGenres(String sourceId) async => genresFail
      ? const Err(NetworkError(message: 'offline'))
      : const Ok([SourceGenre(id: 'lianai', label: 'Romance')]);

  bool genresFail = false;

  @override
  Future<Result<List<SourceSummary>>> listHealth() async => const Ok([]);

  @override
  Future<Result<SourceHealthSummary>> healthSummary() async => const Ok(SourceHealthSummary());
  @override
  Future<Result<SeriesEnrichment?>> seriesEnrichment(
    String sourceId,
    String seriesKey,
  ) async => const Ok(null);

  _FakeSourcesRepository(this.pagesByQuery);

  /// Keyed by "query|sort|page" so tests can assert exactly which page was
  /// requested for a given search/sort combination.
  final Map<String, Result<PagedResult<SourceSeriesSummary>>> pagesByQuery;
  final List<int> requestedPages = [];

  /// Holds a "query|sort|page" request open until the test completes it.
  final Map<String, Completer<void>> gates = {};

  @override
  Future<Result<PagedResult<SourceSeriesSummary>>> listSeries(
    String sourceId, {
    int page = 1,
    String? query,
    String? sort,
    String? genre,
    bool refresh = false,
  }) async {
    requestedPages.add(page);
    final key = '${query ?? ''}|${sort ?? ''}|$page';
    await gates[key]?.future;
    return pagesByQuery[key] ??
        const Ok(PagedResult(items: [], total: 0, page: 1, perPage: 20, hasNext: false));
  }

  @override
  Future<Result<List<SourceBrowseMode>>> listBrowseModes(String sourceId) async =>
      const Ok([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('build() fetches page 1 and exposes hasNext/total', () async {
    final repo = _FakeSourcesRepository({
      '||1': Ok(
        PagedResult(
          items: [_series('a'), _series('b')],
          total: 50,
          page: 1,
          perPage: 2,
          hasNext: true,
        ),
      ),
    });
    final container = ProviderContainer(
      overrides: [sourcesRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    final state = await container.read(sourceBrowseProvider('test-source').future);

    expect(state.items.map((s) => s.id), ['a', 'b']);
    expect(state.total, 50);
    expect(state.hasNext, isTrue);
    expect(state.page, 1);
  });

  test('loadMore appends the next page instead of replacing it', () async {
    final repo = _FakeSourcesRepository({
      '||1': Ok(
        PagedResult(items: [_series('a')], total: 3, page: 1, perPage: 1, hasNext: true),
      ),
      '||2': Ok(
        PagedResult(items: [_series('b')], total: 3, page: 2, perPage: 1, hasNext: true),
      ),
    });
    final container = ProviderContainer(
      overrides: [sourcesRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await container.read(sourceBrowseProvider('test-source').future);
    await container.read(sourceBrowseProvider('test-source').notifier).loadMore();

    final state = container.read(sourceBrowseProvider('test-source')).value!;
    expect(state.items.map((s) => s.id), ['a', 'b']);
    expect(state.page, 2);
  });

  test('loadMore is a no-op once hasNext is false', () async {
    final repo = _FakeSourcesRepository({
      '||1': Ok(
        PagedResult(items: [_series('a')], total: 1, page: 1, perPage: 1, hasNext: false),
      ),
    });
    final container = ProviderContainer(
      overrides: [sourcesRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await container.read(sourceBrowseProvider('test-source').future);
    await container.read(sourceBrowseProvider('test-source').notifier).loadMore();

    // Only the initial page-1 fetch happened -- loadMore made no request.
    expect(repo.requestedPages, [1]);
  });

  test('loadMore leaves existing items in place if the next page fails',
      () async {
    final repo = _FakeSourcesRepository({
      '||1': Ok(
        PagedResult(items: [_series('a')], total: 2, page: 1, perPage: 1, hasNext: true),
      ),
      '||2': const Err(NetworkError(message: 'offline')),
    });
    final container = ProviderContainer(
      overrides: [sourcesRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await container.read(sourceBrowseProvider('test-source').future);
    await container.read(sourceBrowseProvider('test-source').notifier).loadMore();

    final state = container.read(sourceBrowseProvider('test-source')).value!;
    expect(state.items.map((s) => s.id), ['a']);
    expect(state.isLoadingMore, isFalse);
  });

  test('changing the query resets pagination back to page 1', () async {
    final repo = _FakeSourcesRepository({
      '||1': Ok(
        PagedResult(items: [_series('a')], total: 1, page: 1, perPage: 1, hasNext: false),
      ),
      'solo||1': Ok(
        PagedResult(items: [_series('b', title: 'Solo Leveling')], total: 1, page: 1, perPage: 1, hasNext: false),
      ),
    });
    final container = ProviderContainer(
      overrides: [sourcesRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await container.read(sourceBrowseProvider('test-source').future);

    container.read(sourceBrowseQueryProvider('test-source').notifier).state =
        container.read(sourceBrowseQueryProvider('test-source')).copyWith(search: 'solo');

    final state = await container.read(sourceBrowseProvider('test-source').future);
    expect(state.items.single.title, 'Solo Leveling');
    expect(state.page, 1);
  });

  PagedResult<SourceSeriesSummary> pg(List<String> ids, int page, {bool more = true, int total = 0}) =>
      PagedResult(items: [for (final i in ids) _series(i)], total: total, page: page, perPage: 2, hasNext: more);

  test('a loadMore that lands after a query change does not overwrite the new results', () async {
    final repo = _FakeSourcesRepository({
      '||1': Ok(pg(['a'], 1)),
      '||2': Ok(pg(['b'], 2)),
      '|popular|1': Ok(pg(['p'], 1, more: false)),
    });
    repo.gates['||2'] = Completer<void>();
    final container = ProviderContainer(overrides: [sourcesRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(container.dispose);
    final sub = container.listen(sourceBrowseProvider('test-source'), (_, __) {});
    addTearDown(sub.close);

    await container.read(sourceBrowseProvider('test-source').future);
    final more = container.read(sourceBrowseProvider('test-source').notifier).loadMore();
    container.read(sourceBrowseQueryProvider('test-source').notifier).update((q) => q.copyWith(sort: 'popular'));
    await container.read(sourceBrowseProvider('test-source').future);
    repo.gates['||2']!.complete();
    await more;

    final state = container.read(sourceBrowseProvider('test-source')).value!;
    expect(state.items.map((s) => s.id), ['p']);
    expect(state.hasNext, isFalse);
  });

  test('loadMore drops series already on screen', () async {
    final repo = _FakeSourcesRepository({
      '||1': Ok(pg(['a', 'b'], 1)),
      '||2': Ok(pg(['b', 'c'], 2, more: false)),
    });
    final container = ProviderContainer(overrides: [sourcesRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(container.dispose);
    await container.read(sourceBrowseProvider('test-source').future);
    await container.read(sourceBrowseProvider('test-source').notifier).loadMore();
    expect(container.read(sourceBrowseProvider('test-source')).value!.items.map((s) => s.id), ['a', 'b', 'c']);
  });

  test('a page the 18+ gate emptied is skipped, not shown as an empty catalogue', () async {
    final repo = _FakeSourcesRepository({
      '||1': Ok(pg([], 1)),
      '||2': Ok(pg(['c'], 2)),
    });
    final container = ProviderContainer(overrides: [sourcesRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(container.dispose);
    final state = await container.read(sourceBrowseProvider('test-source').future);
    expect(state.items.map((s) => s.id), ['c']);
    expect(state.page, 2);
  });

  test('refresh reports a failure and keeps the previous grid', () async {
    final repo = _FakeSourcesRepository({'||1': Ok(pg(['a'], 1))});
    final container = ProviderContainer(overrides: [sourcesRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(container.dispose);
    final sub = container.listen(sourceBrowseProvider('test-source'), (_, __) {});
    addTearDown(sub.close);
    await container.read(sourceBrowseProvider('test-source').future);
    repo.pagesByQuery['||1'] = const Err(NetworkError(message: 'offline'));
    final ok = await container.read(sourceBrowseProvider('test-source').notifier).refresh();
    expect(ok, isFalse);
    expect(container.read(sourceBrowseProvider('test-source')).valueOrNull?.items.map((s) => s.id), ['a']);
  });

  test('countLabel does not pass a page-size total off as the catalogue size', () {
    final s = SourceBrowseState(items: [_series('a'), _series('b')], total: 2, hasNext: true);
    expect(s.countLabel, '2+');
    expect(SourceBrowseState(items: [_series('a')], total: 900, hasNext: true).countLabel, '900');
    expect(SourceBrowseState(items: [_series('a')], total: 1).countLabel, '1');
  });

  test('state carries the query it answers', () async {
    final repo = _FakeSourcesRepository({'||1': Ok(pg(['a'], 1))});
    final container = ProviderContainer(overrides: [sourcesRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(container.dispose);
    final state = await container.read(sourceBrowseProvider('test-source').future);
    expect(state.query, container.read(sourceBrowseQueryProvider('test-source')));
  });

  test('a failed genre fetch is not cached as an empty list', () async {
    final repo = _FakeSourcesRepository({})..genresFail = true;
    final container = ProviderContainer(overrides: [sourcesRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(container.dispose);
    final sub = container.listen(sourceGenresProvider('test-source'), (_, __) {});
    await expectLater(container.read(sourceGenresProvider('test-source').future), throwsA(anything));
    repo.genresFail = false;
    container.invalidate(sourceGenresProvider('test-source'));
    expect((await container.read(sourceGenresProvider('test-source').future)).single.id, 'lianai');
    sub.close();
  });
}
