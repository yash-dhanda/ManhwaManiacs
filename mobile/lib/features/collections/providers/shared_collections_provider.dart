import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';

typedef SharedCollections = ({List<SharedShelf> collections, List<SharedShelf> sharedWithMe});

/// `GET /library/collections?include_shared=true`: the viewer's own shelves and the shelves shared
/// with them. The legacy `collectionsProvider` keeps reading the bare list.
final sharedCollectionsProvider = FutureProvider.autoDispose<SharedCollections>((ref) async {
  final r = await ref.watch(circleRepositoryProvider).collectionsWithShared();
  if (r.isErr) throw r.error;
  return r.value;
}, name: 'sharedCollections',);

/// One shelf with its role, owner, members and rows from the shelf's own snapshot.
final sharedShelfDetailProvider = FutureProvider.autoDispose.family<SharedShelfDetail, int>((ref, id) async {
  final r = await ref.watch(circleRepositoryProvider).shelfDetail(id);
  if (r.isErr) throw r.error;
  return r.value;
}, name: 'sharedShelfDetail',);
