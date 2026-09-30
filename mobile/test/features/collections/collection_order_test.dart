import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/collections/providers/collection_detail_provider.dart';
import 'package:manhwamaniacs/features/collections/providers/collection_order.dart';
import 'package:manhwamaniacs/features/collections/providers/collections_provider.dart';
import 'package:manhwamaniacs/features/collections/utils/collection_sorting.dart';
import 'package:manhwamaniacs/features/library/models/collection.dart';
import 'package:manhwamaniacs/features/library/models/collection_detail.dart';
import 'package:manhwamaniacs/features/library/repositories/library_repository.dart';
import 'package:manhwamaniacs/features/library/utils/smart_shelf.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';

Collection _c(int id, int order, {DateTime? at}) => Collection(id: id, name: 'C$id', seriesCount: 1, sortOrder: order, createdAt: at);

class _Repo implements LibraryRepository {
  _Repo(this.items);
  List<Collection> items;
  final List<({int id, int? sortOrder})> patches = [];
  final List<List<({String sourceId, String seriesKey})>> orders = [];
  bool fail = false;

  @override
  Future<Result<List<Collection>>> listCollections() async => Ok(items);

  @override
  Future<Result<CollectionDetail>> getCollection(int id) async => Ok(CollectionDetail(
        id: id,
        name: 'C',
        seriesCount: 3,
        sortOrder: 0,
        series: [for (var i = 0; i < 3; i++) CollectionSeriesRef(sourceId: 's', seriesKey: 'k$i', sortOrder: i)],
      ),);

  @override
  Future<Result<Collection>> updateCollection(int id, {String? name, String? description, int? sortOrder, ShelfRules? rules, bool clearRules = false}) async {
    patches.add((id: id, sortOrder: sortOrder));
    if (fail) return const Err(NetworkError(message: 'x'));
    return Ok(_c(id, sortOrder ?? 0));
  }

  @override
  Future<Result<void>> reorderCollectionMembers(int id, List<({String sourceId, String seriesKey})> items) async {
    orders.add(items);
    return fail ? const Err(NetworkError(message: 'x')) : const Ok(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  test('recently created sorts newest first, by id when no date', () {
    final items = [_c(1, 0, at: DateTime.utc(2026)), _c(2, 1, at: DateTime.utc(2026, 3)), _c(3, 2), _c(4, 3)];
    expect(sortCollections(items, CollectionSort.recentlyCreated).map((c) => c.id), [4, 3, 2, 1]);
    final dated = [_c(1, 0, at: DateTime.utc(2026)), _c(2, 1, at: DateTime.utc(2026, 3))];
    expect(sortCollections(dated, CollectionSort.recentlyCreated).map((c) => c.id), [2, 1]);
  });

  test('a collection drop writes only the changed sort_order values', () async {
    final before = [_c(1, 0), _c(2, 1), _c(3, 2), _c(4, 3)];
    final repo = _Repo(before);
    final c = ProviderContainer(overrides: [libraryRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(c.dispose);
    c.listen(collectionsProvider, (_, __) {});
    await c.read(collectionsProvider.future);
    final ok = await c.read(collectionOrderProvider).collections(before, [before[0], before[2], before[1], before[3]]);
    expect(ok, isTrue);
    expect(repo.patches.map((p) => (p.id, p.sortOrder)).toSet(), {(3, 1), (2, 2)});
    expect(c.read(collectionsProvider).value!.map((x) => x.id), [1, 3, 2, 4]);
  });

  test('a failed collection write rolls the order back', () async {
    final before = [_c(1, 0), _c(2, 1)];
    final repo = _Repo(before)..fail = true;
    final c = ProviderContainer(overrides: [libraryRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(c.dispose);
    c.listen(collectionsProvider, (_, __) {});
    await c.read(collectionsProvider.future);
    final ok = await c.read(collectionOrderProvider).collections(before, [before[1], before[0]]);
    expect(ok, isFalse);
    expect(c.read(collectionsProvider).value!.map((x) => x.id), [1, 2]);
  });

  test('member reorder sends the full list and rolls back on failure', () async {
    final repo = _Repo(const []);
    final c = ProviderContainer(overrides: [libraryRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(c.dispose);
    c.listen(collectionDetailProvider(5), (_, __) {});
    await c.read(collectionDetailProvider(5).future);
    final order = c.read(collectionOrderProvider);
    const next = [(sourceId: 's', seriesKey: 'k2'), (sourceId: 's', seriesKey: 'k0'), (sourceId: 's', seriesKey: 'k1')];
    expect(await order.members(5, next), isTrue);
    expect(repo.orders.single.map((m) => m.seriesKey), ['k2', 'k0', 'k1']);
    expect(c.read(collectionDetailProvider(5)).value!.series.map((m) => m.seriesKey), ['k2', 'k0', 'k1']);
    repo.fail = true;
    expect(await order.members(5, const [(sourceId: 's', seriesKey: 'k1'), (sourceId: 's', seriesKey: 'k2'), (sourceId: 's', seriesKey: 'k0')]), isFalse);
    expect(c.read(collectionDetailProvider(5)).value!.series.map((m) => m.seriesKey), ['k2', 'k0', 'k1']);
  });
}
