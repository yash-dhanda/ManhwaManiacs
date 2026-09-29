import 'package:flutter/foundation.dart';
import 'package:manhwamaniacs/features/novels/utils/novel_book.dart';

/// One book on a shelf.
///
/// A view model rather than a source shape on purpose: browse rows and library
/// rows carry different fields, and the shelf renders both.
class ShelfBook {
  const ShelfBook({
    required this.title,
    required this.author,
    required this.description,
    required this.chapterCount,
    required this.status,
    required this.coverUrl,
    required this.onTap,
    this.note,
    this.onLongPress,
    this.selected = false,
    this.isFavorite = false,
    this.unreadCount = 0,
  });

  final String title;
  final String? author;
  final String? description;
  final int? chapterCount;

  /// Publication status as the source words it ("ongoing", "Completed").
  final String? status;

  /// Already resolved to a fetchable URL by the caller.
  ///
  /// A source with no cover returns an EMPTY STRING, which resolves against the
  /// API base into a URL that loads the backend root as an image. On the manga
  /// side a missing cover is rare enough never to have mattered; on a
  /// public-domain novel archive it is routine, so the caller passes null and
  /// the row draws its own mark instead.
  final String? coverUrl;

  /// Anything shelf-specific worth a line: "Reading · 42%", "Favourite".
  final String? note;

  final VoidCallback onTap;

  /// The library's per-row menu (favourite, remove). Null on a browse shelf,
  /// and null again while a selection is open — a long-press that opened a
  /// destructive sheet mid-select would fire under the thumb that was picking.
  final VoidCallback? onLongPress;

  /// Whether this row is picked in the shelf's multi-select.
  final bool selected;

  /// Drawn as a star beside the metadata: the shelf has no room for the poster
  /// grid's tap-target star, and the sheet behind [onLongPress] is where a
  /// novel gets favourited instead — but the state still has to be visible.
  final bool isFavorite;

  /// Unread new-chapter notifications for this book, 0 for none.
  ///
  /// The one thing a library row exists to say — a grid says it with a badge
  /// on the cover, and a 46pt plate has nowhere to put one, so the shelf
  /// leads its metadata line with it instead.
  final int unreadCount;

  /// The one metadata line under the title, as parts to join.
  ///
  /// Empty parts are dropped rather than rendered as stray separators — a
  /// source that reports no author and no chapter count should produce a title
  /// with nothing under it, not "by  ·  · ".
  List<String> get metaParts => [
        byline(author),
        formatChapterCount(chapterCount),
        formatStatus(status),
        if (note != null && note!.trim().isNotEmpty) note!.trim(),
      ].whereType<String>().toList();
}
