import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/library/models/collection.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';

/// The shelves (collections) that contain a series. There is no membership
/// endpoint, so each shelf is read once (ponytail: N+1 over a handful of
/// shelves; a `?series=` filter on `/library/collections` removes it).
final seriesShelvesProvider = FutureProvider.autoDispose
    .family<List<CollectionRef>, ({String sourceId, String seriesKey})>((ref, k) async {
  final repo = ref.watch(libraryRepositoryProvider);
  final all = await repo.listCollections();
  if (all.isErr) return const [];
  final details = await Future.wait([for (final c in all.value) repo.getCollection(c.id)]);
  return [
    for (final r in details)
      if (r.isOk &&
          r.value.series.any((s) => s.sourceId == k.sourceId && s.seriesKey == k.seriesKey))
        CollectionRef(id: r.value.id, name: r.value.name),
  ];
});
