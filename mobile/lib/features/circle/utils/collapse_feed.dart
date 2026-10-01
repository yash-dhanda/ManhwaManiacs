import 'package:manhwamaniacs/features/circle/models/circle_models.dart';

/// One activity row: a feed item, or a run of chapter finishes collapsed into "read chapters 140–152" (glass 9.3.1).
class FeedEntry {
  const FeedEntry(this.item, {this.range, this.items = const []});

  /// The newest item of the run (the row's actor, series, cover and time).
  final FeedItem item;

  /// `(from, to)` chapter numbers when several finishes collapsed; null for a single item.
  final (double, double)? range;

  /// Every item the row stands for, newest first.
  final List<FeedItem> items;
}

/// Merges consecutive `finishedChapter` items by the same actor in the same series on the same local day (the day of
/// `createdAt + utcOffset`); other kinds are never merged.
List<FeedEntry> collapseReads(List<FeedItem> items, {required Duration utcOffset}) {
  DateTime? day(FeedItem i) {
    final t = i.createdAt?.toUtc().add(utcOffset);
    return t == null ? null : DateTime.utc(t.year, t.month, t.day);
  }

  bool joins(FeedItem a, FeedItem b) =>
      a.kind == FeedKind.finishedChapter &&
      b.kind == FeedKind.finishedChapter &&
      a.actor.profileId == b.actor.profileId &&
      a.sourceId == b.sourceId &&
      a.seriesKey == b.seriesKey &&
      day(a) != null &&
      day(a) == day(b);

  final runs = <List<FeedItem>>[];
  for (final i in items) {
    if (runs.isNotEmpty && joins(runs.last.last, i)) {
      runs.last.add(i);
    } else {
      runs.add([i]);
    }
  }
  return [
    for (final r in runs)
      () {
        final ns = [for (final i in r) if (i.chapterNumber != null) i.chapterNumber!];
        final ranged = r.length > 1 && ns.length > 1;
        return FeedEntry(r.first, items: r, range: ranged ? (ns.reduce((a, b) => a < b ? a : b), ns.reduce((a, b) => a > b ? a : b)) : null);
      }(),
  ];
}
