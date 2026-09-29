import 'package:manhwamaniacs/features/novels/utils/novel_book.dart';
import 'package:manhwamaniacs/features/reader/models/bookmark.dart';

/// How far through the chapter a bookmark sits, in the words the design asked
/// for: "62% of chapter 14".
///
/// Degrades in two steps rather than lying. Without a chapter number the
/// chapter cannot be named, so it is "62% through this chapter"; without a
/// unit count there is no percentage at all — an old page-only bookmark
/// migrated from before this design says "page 4" and nothing more, because
/// claiming it was 0% of the way in would be inventing a fact.
String bookmarkPositionLabel(Bookmark bookmark) {
  final percent = bookmark.positionPercent;
  final number = bookmark.chapterNumber;
  if (percent == null) {
    return bookmark.mediaType.isNovel
        ? 'Paragraph ${bookmark.anchorIndex}'
        : 'Page ${bookmark.anchorIndex}';
  }
  if (number == null) return '$percent% through this chapter';
  return '$percent% of chapter ${formatChapterNumber(number)}';
}
