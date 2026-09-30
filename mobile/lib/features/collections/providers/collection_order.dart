import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/collections/providers/collection_detail_provider.dart';
import 'package:manhwamaniacs/features/collections/providers/collections_provider.dart';
import 'package:manhwamaniacs/features/library/models/collection.dart';
import 'package:manhwamaniacs/features/library/utils/bulk_runner.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';

/// A collection's members' identity, in shelf order.
typedef MemberKey = ({String sourceId, String seriesKey});

/// Puts [after] on screen at once and writes `sort_order` for the collections whose position
/// changed (4 at a time). A failed write puts [before] back. Returns whether every write held.
Future<bool> reorderCollections(Ref ref, List<Collection> before, List<Collection> after) async {
  final notifier = ref.read(collectionsProvider.notifier);
  final repo = ref.read(libraryRepositoryProvider);
  final prev = <int, int>{for (final c in before) c.id: c.sortOrder};
  final renumbered = [
    for (var i = 0; i < after.length; i++)
      Collection(
        id: after[i].id,
        name: after[i].name,
        description: after[i].description,
        coverUrl: after[i].coverUrl,
        seriesCount: after[i].seriesCount,
        sortOrder: i,
        rules: after[i].rules,
        previewCovers: after[i].previewCovers,
        previewAmbientDuo: after[i].previewAmbientDuo,
        createdAt: after[i].createdAt,
      ),
  ];
  final changed = [for (final c in renumbered) if (prev[c.id] != c.sortOrder) c];
  notifier.setLocal(renumbered);
  final out = await runBulk<Collection>(
    changed,
    (c) async {
      final Result<Collection> r = await repo.updateCollection(c.id, sortOrder: c.sortOrder);
      return r.isErr ? Err(r.error) : const Ok(null);
    },
  );
  if (out.failed > 0) {
    notifier.setLocal(before);
    return false;
  }
  return true;
}

/// Puts [ordered] on screen at once and sends the full list; a failure restores the old order
/// (the caller shows the toast). Returns whether the write held.
Future<bool> reorderMembers(Ref ref, int collectionId, List<MemberKey> ordered) async {
  final notifier = ref.read(collectionDetailProvider(collectionId).notifier);
  final before = notifier.memberOrder();
  notifier.setMemberOrder(ordered);
  final r = await ref.read(libraryRepositoryProvider).reorderCollectionMembers(collectionId, ordered);
  if (r.isErr) {
    notifier.setMemberOrder(before);
    return false;
  }
  return true;
}

/// [reorderCollections] and [reorderMembers] bound to a `Ref`, so a widget calls them with `ref.read`.
class CollectionOrder {
  const CollectionOrder(this._ref);
  final Ref _ref;
  Future<bool> collections(List<Collection> before, List<Collection> after) => reorderCollections(_ref, before, after);
  Future<bool> members(int collectionId, List<MemberKey> ordered) => reorderMembers(_ref, collectionId, ordered);
}

final collectionOrderProvider = Provider<CollectionOrder>(CollectionOrder.new, name: 'collectionOrder');
