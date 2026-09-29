import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_image.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_row.dart';
import 'package:manhwamaniacs/skins/cinematic/stock.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// A book in the book list (cinematic 8.9.1, novels mode): a 56 x 84 plate, the title in Bodoni
/// Italic 20, the byline, the credits, a two-line blurb and a note in a `spot` folio. Rows are at
/// least 112 px; select mode adds a leading checkbox and the row states are 7.16's. Reused by the
/// collection page and the source catalogue.
class BookListRow extends StatelessWidget {
  const BookListRow({
    super.key,
    required this.title,
    required this.credits,
    this.author,
    this.blurb,
    this.note,
    this.coverUrl,
    this.heroTag,
    this.onTap,
    this.selectMode = false,
    this.selected = false,
    this.onSelectedChanged,
    this.trailing,
    this.focusNode,
    this.dim = false,
  });

  final String title;

  /// `412 CHAPTERS · ONGOING · NOVELARCHIVE`.
  final String credits;

  /// The bare name; the row says "by {author}" and drops the line when it is null.
  final String? author;
  final String? blurb, note, coverUrl;
  final (String, String)? heroTag;
  final VoidCallback? onTap;
  final bool selectMode, selected, dim;
  final ValueChanged<bool>? onSelectedChanged;
  final Widget? trailing;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    Widget plate = SizedBox(
      width: 56,
      height: 84,
      child: DecoratedBox(
        decoration: BoxDecoration(border: Border.all(color: c.colorRule2)),
        child: coverUrl == null || coverUrl!.isEmpty
            ? ColoredBox(
                color: c.colorPaper1,
                child: Center(
                  child: ExcludeSemantics(
                    child: CineLit(title.characters.isEmpty ? '' : title.characters.first.toUpperCase(), CineFace.bodoni, 32, 36, wght: 800, color: c.colorInk60),
                  ),
                ),
              )
            : CineImage(url: coverUrl, title: title),
      ),
    );
    if (heroTag != null) plate = Hero(tag: heroTag!, child: plate);
    final by = author == null || author!.trim().isEmpty ? null : 'by ${author!.trim()}';
    return CineRowShell(
      minHeight: 112,
      onTap: onTap,
      selected: selected,
      selectMode: selectMode,
      onSelectedChanged: onSelectedChanged,
      focusNode: focusNode,
      dim: dim,
      handle: trailing,
      semanticLabel: [title, if (by != null) by, credits, if (note != null) note!].join(', '),
      child: CineStock.raised(Builder(
        builder: (context) {
          final t = context.cine;
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            plate,
            SizedBox(width: t.space4),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                CineLit(title, CineFace.bodoni, 20, 24, italic: true, color: t.colorInk100, maxLines: 2, overflow: TextOverflow.ellipsis),
                if (by != null) CineRoleText(by, t.typeBodyItalic, color: t.colorInk60, maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: t.space1),
                CineRoleText(credits, t.typeCredit, color: t.colorInk60, maxLines: 2, overflow: TextOverflow.ellipsis),
                if (blurb != null && blurb!.isNotEmpty) ...[
                  SizedBox(height: t.space1),
                  CineLit(blurb!, CineFace.newsreader, 15, 21, color: t.colorInk60, maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                if (note != null) ...[
                  SizedBox(height: t.space1),
                  CineRoleText(note!, t.typeFolio, color: t.colorSpot),
                ],
              ],),
            ),
          ],);
        },
      ),),
    );
  }
}
