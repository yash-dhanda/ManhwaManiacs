import 'package:manhwamaniacs/features/library/models/shelf_query.dart';
import 'package:manhwamaniacs/features/library/utils/shelf_counts.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_slug_lines.dart';

/// The six sorts' words (cinematic 8.9), in menu order.
const Map<ShelfSort, String> kShelfSortLabels = {
  ShelfSort.updated: 'Recently updated',
  ShelfSort.added: 'Recently added',
  ShelfSort.read: 'Recently read',
  ShelfSort.title: 'Title A–Z',
  ShelfSort.unread: 'Most unread',
  ShelfSort.manual: 'Manual order',
};

/// The slug line's words (the 7.19 vocabulary), in slug-line order; `1`–`7` select them.
const Map<ShelfStatus, String> kShelfStatusLabels = {
  ShelfStatus.all: 'ALL',
  ShelfStatus.reading: 'READING',
  ShelfStatus.unread: 'NOT STARTED',
  ShelfStatus.completed: 'DONE',
  ShelfStatus.onHold: 'ON HOLD',
  ShelfStatus.planToRead: 'PLAN TO READ',
  ShelfStatus.dropped: 'DROPPED',
};

const Map<ShelfDensity, String> kShelfDensityLabels = {
  ShelfDensity.wall: 'WALL',
  ShelfDensity.compact: 'COMPACT',
  ShelfDensity.list: 'LIST',
};

/// The status slugs with their raised counts; [counts] null shows `–` (loading).
List<CineSlug> shelfStatusSlugs(ShelfCounts? counts) => [
      for (final e in kShelfStatusLabels.entries)
        CineSlug(
          e.key.name,
          e.value,
          count: counts == null ? null : (e.key == ShelfStatus.all ? counts.total : counts.byStatus[e.key.wire] ?? 0),
        ),
    ];

ShelfStatus? shelfStatusByName(String id) {
  for (final s in ShelfStatus.values) {
    if (s.name == id) return s;
  }
  return null;
}
