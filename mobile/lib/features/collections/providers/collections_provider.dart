import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/library/models/collection.dart';
import 'package:manhwamaniacs/features/library/utils/smart_shelf.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';

final collectionSearchProvider = StateProvider<String>(
  (ref) => '',
  name: 'collectionSearch',
);

final collectionsProvider =
    AsyncNotifierProvider.autoDispose<CollectionsNotifier, List<Collection>>(
  CollectionsNotifier.new,
  name: 'collections',
);

class CollectionsNotifier extends AutoDisposeAsyncNotifier<List<Collection>> {
  @override
  Future<List<Collection>> build() async {
    final repo = ref.read(libraryRepositoryProvider);
    final result = await repo.listCollections();
    if (result.isErr) throw result.error;
    return result.value;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(libraryRepositoryProvider);
      final result = await repo.listCollections();
      if (result.isErr) throw result.error;
      return result.value;
    });
  }

  /// Refetches without going through the loading state (the list stays on screen).
  Future<void> reload() async {
    final result = await ref.read(libraryRepositoryProvider).listCollections();
    if (result.isErr) {
      state = AsyncError<List<Collection>>(result.error, StackTrace.current).copyWithPrevious(state);
    } else {
      state = AsyncData(result.value);
    }
  }

  /// Shows [items] now (an optimistic reorder, or its rollback).
  void setLocal(List<Collection> items) => state = AsyncData(items);

  Future<AppError?> createCollection({
    required String name,
    String? description,
    ShelfRules? rules,
  }) async {
    final repo = ref.read(libraryRepositoryProvider);
    final result = rules == null
        ? await repo.createCollection(name: name, description: description)
        : await repo.createCollection(name: name, description: description, rules: rules);
    if (result.isErr) return result.error;
    await reload();
    return null;
  }
}
