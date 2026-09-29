import 'package:manhwamaniacs/features/library/models/followed_series.dart';

typedef ShelfCounts = ({int total, int withNew, int favourites, Map<String, int> byStatus});

/// The masthead deck's and the slug line's counts, over the whole followed list (never the
/// 200-row page). `byStatus` is keyed by the stored `reading_status`.
ShelfCounts shelfCounts(Iterable<FollowedSeries> rows) {
  var total = 0, withNew = 0, favourites = 0;
  final byStatus = <String, int>{};
  for (final s in rows) {
    total++;
    if ((s.readState?.newCount ?? 0) > 0) withNew++;
    if (s.isFavorite) favourites++;
    byStatus[s.readingStatus] = (byStatus[s.readingStatus] ?? 0) + 1;
  }
  return (total: total, withNew: withNew, favourites: favourites, byStatus: byStatus);
}

/// "212 series · 14 with new chapters · 3 favourites"; a zero part is dropped; novels say
/// "38 books on your shelf".
String shelfDeck(ShelfCounts c, {required bool novels}) {
  if (novels) return c.total == 0 ? '' : '${c.total} ${c.total == 1 ? 'book' : 'books'} on your shelf';
  return [
    if (c.total > 0) '${c.total} series',
    if (c.withNew > 0) '${c.withNew} with new chapters',
    if (c.favourites > 0) '${c.favourites} ${c.favourites == 1 ? 'favourite' : 'favourites'}',
  ].join(' · ');
}
