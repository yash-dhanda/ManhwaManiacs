
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/reader/models/bookmark.dart';
import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/row_shell.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/library_common.dart';

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// "Saved 28 Sep, 21:41".
String bookmarkSavedAt(DateTime at) {
  final a = at.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return 'Saved ${a.day} ${_months[a.month - 1]}, ${two(a.hour)}:${two(a.minute)}';
}

/// "Ch 12 · Page 7" (manga) or "Ch 3 · Paragraph 118 · 62 %" (novel).
String bookmarkWhere(Bookmark b) {
  String n(double v) => v % 1 == 0 ? '${v.toInt()}' : '$v';
  final ch = b.chapterNumber == null ? null : 'Ch ${n(b.chapterNumber!)}';
  if (b.mediaType.isNovel) {
    final p = b.positionPercent;
    return [if (ch != null) ch, 'Paragraph ${b.anchorIndex}', if (p != null) '$p %'].join(' · ');
  }
  return [if (ch != null) ch, 'Page ${b.anchorIndex}'].join(' · ');
}

/// One bookmark (glass 8.20): a 44 x 66 cover, the series, where it is, the novel snippet in Literata italic, the note, "Saved ...", and
/// the stale note in `warning`.
class BookmarkRow extends ConsumerWidget {
  const BookmarkRow({super.key, required this.bookmark, required this.title, required this.coverUrl, required this.onOpen, required this.onMenu});
  final Bookmark bookmark;
  final String title;
  final String? coverUrl;
  final VoidCallback onOpen;

  /// Long-press (touch) or the context-menu key: the caller opens the menu for [bookmark] anchored at the row.
  final void Function(Rect from) onMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = bookmark;
    final novel = b.mediaType.isNovel;
    return Builder(builder: (context) {
      return GlassRowShell(
        semanticsLabel: '$title, ${bookmarkWhere(b)}',
        minHeight: 92,
        onTap: onOpen,
        onLongPress: () => onMenu(globalRectOf(context)),
        builder: (context, stacked, info) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox(width: 44, height: 66, child: HomeCoverImage(url: coverUrl, width: 44))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                GlassLabel(title, role: gt.typeHeadline, maxLines: 2),
                Row(children: [
                  Icon(novel ? GlassGlyph.bookOpen.regular : roleIcon(GlassIconRole.stripMode), size: 14, color: gt.colorLabel2),
                  const SizedBox(width: 6),
                  Expanded(child: GlassLabel(bookmarkWhere(b), role: gt.typeFootnote, color: gt.colorLabel2)),
                ],),
                if (novel && (b.snippet ?? '').isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: BookTitle(b.snippet!, italic: true, size: 15)),
                if ((b.note ?? '').isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: GlassLabel(b.note!, role: gt.typeSubhead, maxLines: 3)),
                Padding(padding: const EdgeInsets.only(top: 4), child: GlassLabel(bookmarkSavedAt(b.createdAt), role: gt.typeCaption1, color: gt.colorLabel3)),
                if (b.anchorStale) GlassLabel('The text here changed; this opens at the nearest spot.', role: gt.typeCaption1, color: gt.colorWarning, maxLines: 3),
              ],),
            ),
          ],),
        ),
      );
    },);
  }
}
