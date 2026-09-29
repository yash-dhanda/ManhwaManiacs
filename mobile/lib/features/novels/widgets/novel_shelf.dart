import 'package:flutter/material.dart';
import 'package:manhwamaniacs/app/theme/app_colors.dart';
import 'package:manhwamaniacs/app/theme/app_presets.dart';
import 'package:manhwamaniacs/features/library/utils/read_state_label.dart';
import 'package:manhwamaniacs/features/novels/models/novel_typography.dart';
import 'package:manhwamaniacs/features/novels/utils/novel_book.dart';
import 'package:manhwamaniacs/features/novels/utils/novel_shelf_logic.dart';
import 'package:manhwamaniacs/shared/widgets/scroll_reveal.dart';
import 'package:manhwamaniacs/shared/widgets/series_cover_image.dart';

/// A shelf of books, in place of the poster grid.
///
/// The grid asks the cover to carry the identity, and three columns of them
/// on a phone leaves room for a title and nothing else. That is right for
/// manhwa, whose art IS the recognition. It is wrong for novels: a web-novel
/// aggregator's cover is usually a generated placeholder, so a grid of them is
/// a grid of interchangeable rectangles.
///
/// What a reader actually recognises a novel by is its title, its author and
/// its length — so a row leads with those, in the serif that carries the mode,
/// with the cover kept small and to the side. Kept rather than dropped,
/// because when the art IS real it still helps.
///
/// The library shelves the reader's own books through this same widget, which
/// is why a row can carry a long-press, a selection mark and an unread count:
/// a phone's library is worked on as well as read from, and a shelf that lost
/// those would be a prettier library the owner could no longer tidy.
class NovelShelf extends StatelessWidget {
  const NovelShelf({
    super.key,
    required this.itemCount,
    required this.bookAt,
    this.selectionMode = false,
    this.gutter,
  });

  final int itemCount;
  final ShelfBook Function(int index) bookAt;

  /// Whether a multi-select is open. Shelf-wide rather than per-book because
  /// the column of marks has to appear the moment selection starts, while
  /// nothing is selected yet.
  final bool selectionMode;

  /// Horizontal inset for a row and its hairline.
  ///
  /// Defaults to the shelf's own `lg`. A screen whose page gutter is wider
  /// passes that instead, so the shelf reads as the continuation of the
  /// heading above it rather than a panel indented inside it.
  final double? gutter;

  @override
  Widget build(BuildContext context) {
    final inset = gutter ?? context.space.lg;
    return SliverList.separated(
      itemCount: itemCount,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        thickness: 1,
        indent: inset,
        endIndent: inset,
        color: context.colors.border,
      ),
      itemBuilder: (context, index) => ScrollReveal(
        index: index,
        child: _ShelfRow(
          book: bookAt(index),
          selectionMode: selectionMode,
          gutter: inset,
        ),
      ),
    );
  }
}

class _ShelfRow extends StatelessWidget {
  const _ShelfRow({
    required this.book,
    required this.selectionMode,
    required this.gutter,
  });

  final ShelfBook book;
  final bool selectionMode;
  final double gutter;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const serif = kNovelSerifStack;
    final meta = book.metaParts.join('  ·  ');
    final blurb = shelfBlurb(book.description);
    final hasMetaLine =
        meta.isNotEmpty || book.isFavorite || book.unreadCount > 0;

    return InkWell(
      onTap: book.onTap,
      onLongPress: book.onLongPress,
      // Translucent rather than opaque so the press ripple still reads
      // through a picked row.
      child: ColoredBox(
        color: book.selected ? colors.primary.withAlpha(26) : Colors.transparent,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: gutter,
            vertical: context.space.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectionMode) ...[
                _SelectionMark(selected: book.selected),
                SizedBox(width: context.space.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: serif.first,
                        fontFamilyFallback: serif.sublist(1),
                        fontSize: 17,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                        color: colors.fg,
                      ),
                    ),
                    if (hasMetaLine)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            if (book.unreadCount > 0) ...[
                              _UnreadBadge(count: book.unreadCount),
                              SizedBox(width: context.space.sm),
                            ],
                            if (book.isFavorite) ...[
                              Icon(Icons.star, size: 13, color: colors.warning),
                              const SizedBox(width: 4),
                            ],
                            if (meta.isNotEmpty)
                              Flexible(
                                child: Text(
                                  meta,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.muted,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    if (blurb != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          blurb,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: colors.muted,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(width: context.space.md),
              _Plate(coverUrl: book.coverUrl, title: book.title),
            ],
          ),
        ),
      ),
    );
  }
}

/// The multi-select mark, round to match the poster grid's.
///
/// Indicator only: the row's own `onTap` is what toggles it, wired by the
/// screen that owns the selection.
class _SelectionMark extends StatelessWidget {
  const _SelectionMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 24,
      height: 24,
      // Optically centred on the title's cap height rather than its line box.
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? colors.primary : colors.bg.withAlpha(150),
        border: Border.all(
          color: selected ? colors.primary : colors.fg.withAlpha(150),
          width: 1.5,
        ),
      ),
      child: selected
          ? Icon(Icons.check, size: 15, color: colors.primaryFg)
          : null,
    );
  }
}

/// "2 NEW" — the same pill the poster grid pins to a cover, sized for a line
/// of metadata instead.
class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.space.sm,
        vertical: context.space.xxs,
      ),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(context.radii.pill),
      ),
      child: Text(
        newCountBadgeText(count),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: colors.primaryFg,
        ),
      ),
    );
  }
}

/// The small cover, or a plate standing in for one.
///
/// The stand-in is a bordered rectangle carrying the book's initial rather
/// than a broken-image glyph: on an archive where most books have no art, a
/// column of broken images reads as a broken app.
class _Plate extends StatelessWidget {
  const _Plate({required this.coverUrl, required this.title});

  final String? coverUrl;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const size = Size(46, 66);

    if (coverUrl != null && coverUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(context.radii.sm),
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: SeriesCoverImage(
            url: coverUrl!,
            displayWidth: size.width,
            borderRadius: 0,
          ),
        ),
      );
    }

    final initial = title.trim().isEmpty ? '·' : title.trim()[0].toUpperCase();
    return Container(
      width: size.width,
      height: size.height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.radii.sm),
        color: colors.surface2,
        border: Border.all(color: colors.border),
      ),
      child: Text(
        initial,
        style: TextStyle(
          fontFamily: kNovelSerifStack.first,
          fontFamilyFallback: kNovelSerifStack.sublist(1),
          fontSize: 20,
          color: colors.muted,
        ),
      ),
    );
  }
}
