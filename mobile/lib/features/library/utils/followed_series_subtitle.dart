import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/models/followed_series_meta.dart';
import 'package:manhwamaniacs/features/library/utils/local_read_marks.dart';
import 'package:manhwamaniacs/features/library/utils/read_state_label.dart';

/// The card's one muted line: where the reader is ("Not started", "Ch 5 of
/// 120") when the row carries a read state; else the latest chapter we
/// actually know about, else a chapter count only when the checker has
/// populated one, else nothing at all.
///
/// [local] is this phone's own record for the series: it turns a server
/// "Not started" into where the phone got to (`readStateWithLocal`).
String? followedSeriesCardSubtitle(
  FollowedSeries series,
  FollowedSeriesMeta meta, {
  LocalReadMark? local,
}) {
  final progress = readStateLabel(readStateWithLocal(series.readState, local));
  if (progress != null) return progress;
  final latest = meta.latestChapterLabel;
  if (latest != null) return 'Latest: $latest';
  final known = series.chapterCount;
  if (known <= 0) return null;
  return known == 1 ? '1 chapter' : '$known chapters';
}
