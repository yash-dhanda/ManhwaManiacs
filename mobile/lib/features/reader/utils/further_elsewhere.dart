import 'package:manhwamaniacs/features/reader/models/reading_progress.dart';

/// This device's own furthest saved position in a series.
typedef OwnFurthest = ({double number, int page});

/// The server row another device is further on at, or null.
///
/// The server only says a push did not advance its row; the furthest row in the series may be this
/// device's own, as when a reader goes back to re-read chapter 3 after reaching chapter 40. So a row
/// counts only when it is past the chapter being read ([here], whose number must be known) and past
/// [own], the furthest this device itself has saved.
ReadingProgress? furtherElsewhere(Iterable<ReadingProgress> rows, {required String hereKey, required double? here, OwnFurthest? own}) {
  if (here == null) return null;
  ReadingProgress? far;
  for (final r in rows) {
    final n = r.chapterNumber;
    if (n != null && n > (far?.chapterNumber ?? double.negativeInfinity)) far = r;
  }
  if (far == null || far.chapterKey == hereKey || far.chapterNumber! <= here) return null;
  if (own != null && (own.number > far.chapterNumber! || (own.number == far.chapterNumber && own.page >= far.lastPage))) return null;
  return far;
}
