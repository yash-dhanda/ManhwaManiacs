import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/library/models/tag.dart';
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

/// Adds and removes this profile's tags on a series. TODO(mobile/09): mobile/09
/// owns `TagsController`; this stands in until it lands.
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
