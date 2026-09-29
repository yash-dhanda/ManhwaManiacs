import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/library/models/tag.dart';
import 'package:manhwamaniacs/features/library/providers/shelf_provider.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';

typedef TagSeriesKey = ({String sourceId, String seriesKey});

/// The profile's tags (`GET /library/tags`).
final profileTagsProvider = FutureProvider.autoDispose<List<Tag>>((ref) async {
  final r = await ref.watch(libraryRepositoryProvider).listTags();
  if (r.isErr) throw r.error;
  return r.value;
});

/// Optimistic own-tag lists per series, set by [TagsController] so the page
/// updates before the library list is fetched again.
final seriesTagOverlayProvider =
    StateProvider<Map<TagSeriesKey, List<Tag>>>((ref) => const {});

/// This profile's tags: create, rename and delete them, and add or remove them on a series.
/// Every change refreshes the tags list and the shelf (its tag filter and tag counts).
class TagsController {
  TagsController(this._ref);
  final Ref _ref;

  void _set(TagSeriesKey k, List<Tag> tags) =>
      _ref.read(seriesTagOverlayProvider.notifier).update((m) => {...m, k: tags});

  Future<AppError?> tagSeries(TagSeriesKey k, Tag tag, {required List<Tag> current}) async {
    final r = await _ref.read(libraryRepositoryProvider).addTagToSeries(
          sourceId: k.sourceId,
          seriesKey: k.seriesKey,
          tagId: tag.id,
        );
    if (r.isErr) return r.error;
    if (!current.any((t) => t.id == tag.id)) _set(k, [...current, tag]);
    _refresh();
    return null;
  }

  Future<AppError?> untagSeries(TagSeriesKey k, Tag tag, {required List<Tag> current}) async {
    final r = await _ref.read(libraryRepositoryProvider).removeTagFromSeries(
          sourceId: k.sourceId,
          seriesKey: k.seriesKey,
          tagId: tag.id,
        );
    if (r.isErr) return r.error;
    _set(k, [for (final t in current) if (t.id != tag.id) t]);
    _refresh();
    return null;
  }

  void _refresh() {
    _ref
      ..invalidate(profileTagsProvider)
      ..invalidate(shelfProvider);
  }

  /// `POST /library/tags {name, category: "custom"}`.
  Future<AppError?> create(String name) async {
    final r = await _ref.read(libraryRepositoryProvider).createTag(name: name);
    if (r.isErr) return r.error;
    _refresh();
    return null;
  }

  /// `PATCH /library/tags/{id} {name}`.
  Future<AppError?> rename(int id, String name) async {
    final r = await _ref.read(libraryRepositoryProvider).renameTag(id, name);
    if (r.isErr) return r.error;
    _refresh();
    return null;
  }

  /// `DELETE /library/tags/{id}`: the tag comes off every series.
  Future<AppError?> delete(int id) async {
    final r = await _ref.read(libraryRepositoryProvider).deleteTag(id);
    if (r.isErr) return r.error;
    _refresh();
    return null;
  }

  /// `New tag...`: creates the tag, then applies it.
  Future<AppError?> createAndTag(TagSeriesKey k, String name, {required List<Tag> current}) async {
    final c = await _ref.read(libraryRepositoryProvider).createTag(name: name);
    if (c.isErr) return c.error;
    _ref.invalidate(profileTagsProvider);
    return tagSeries(k, c.value, current: current);
  }
}

final tagsControllerProvider = Provider<TagsController>(TagsController.new);
