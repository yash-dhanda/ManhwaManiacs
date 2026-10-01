import 'dart:math' as math;

import 'package:manhwamaniacs/features/reader/models/reading_progress.dart';

/// A chapter as the mark-read call sites see it.
typedef ChapterRef = ({
  String sourceId,
  String seriesKey,
  String chapterKey,
  double? chapterNumber,
  int pageCount,
  bool completed,
});

/// A chapter of one series for the "up to here" selection.
typedef ChapterMark = ({String key, double? number, bool completed});

/// Every not-yet-completed chapter numbered at or below [number]
/// (chapters without a number are excluded). An unnumbered target ([number]
/// null) has no place in the numbering, so nothing: "up to an extra" must not
/// read as "up to infinity" and mark the whole series.
List<ChapterMark> chaptersUpTo(List<ChapterMark> chapters, double? number) => [
      if (number != null)
        for (final c in chapters)
          if (c.number != null && c.number! <= number && !c.completed) c,
    ];

/// The keys an Undo deletes: only those that were not completed before.
List<String> undoMarkReadKeys(Set<String> previouslyCompleted, List<String> marked) => [
      for (final k in marked)
        if (!previouslyCompleted.contains(k)) k,
    ];

/// The API takes 200 rows (or keys) at a time.
Iterable<List<T>> chunksOf200<T>(List<T> items) sync* {
  for (var i = 0; i < items.length; i += 200) {
    yield items.sublist(i, math.min(i + 200, items.length));
  }
}

/// The `manual: true` progress rows for [chapters] (the 8.17 one-chapter call): completed at their
/// last page, zero time spent, so marking never moves statistics or streaks. Goes straight to the
/// server, never the progress outbox.
///
/// Every row carries one stamp, [at] (now by default): unstamped, the server dated each row as it
/// applied it, so the LAST row of a batch became the newest-touched chapter that Continue resumes
/// from. A series page passes `manualMarkStamp` so a mark never outranks the chapter being read.
List<ProgressPush> manualReadRows(List<ChapterRef> chapters, {DateTime? at}) {
  final stamp = (at ?? DateTime.now()).toUtc();
  return [
      for (final c in chapters)
        ProgressPush(
          sourceId: c.sourceId,
          seriesKey: c.seriesKey,
          chapterKey: c.chapterKey,
          chapterNumber: c.chapterNumber,
          lastPage: math.max(c.pageCount, 1),
          pageCount: math.max(c.pageCount, 1),
          isCompleted: true,
          manual: true,
          lastReadAt: stamp,
        ),
    ];
}
