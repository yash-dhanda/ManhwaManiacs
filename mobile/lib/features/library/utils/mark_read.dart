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
/// (chapters without a number are excluded).
List<ChapterMark> chaptersUpTo(List<ChapterMark> chapters, double number) => [
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
List<ProgressPush> manualReadRows(List<ChapterRef> chapters) => [
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
        ),
    ];
