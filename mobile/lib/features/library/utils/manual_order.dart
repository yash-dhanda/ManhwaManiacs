import 'package:manhwamaniacs/features/library/models/followed_series.dart';

/// [list] with the item at [from] moved to [to] (both indices into the original list).
List<T> reorder<T>(List<T> list, int from, int to) {
  if (from == to || from < 0 || from >= list.length) return List.of(list);
  final out = List<T>.of(list);
  final item = out.removeAt(from);
  out.insert(to.clamp(0, out.length), item);
  return out;
}

/// The minimal patch list after renumbering [after] as 0 ... n - 1: only rows whose stored
/// `sort_order` differs from their new index.
List<({int id, int sortOrder})> changedSortOrders(List<FollowedSeries> before, List<FollowedSeries> after) {
  final was = {for (final s in before) s.id: s.sortOrder};
  return [
    for (var i = 0; i < after.length; i++)
      if (was[after[i].id] != i) (id: after[i].id, sortOrder: i),
  ];
}
