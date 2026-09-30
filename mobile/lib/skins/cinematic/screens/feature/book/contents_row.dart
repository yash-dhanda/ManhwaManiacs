import 'package:flutter/material.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/utils/download_mark.dart';
import 'package:manhwamaniacs/features/novels/utils/novel_book.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/phosphor.g.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_download_mark.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_states.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/schedule_row.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

const double kContentsRowExtent = 48;

/// Dot leaders: a `·` every 0.5 em in `ink.30` between the title and the
/// length.
class DotLeader extends StatelessWidget {
  const DotLeader({super.key, required this.color, this.em = 16});
  final Color color;
  final double em;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, box) => CustomPaint(
          size: Size(box.maxWidth, 16),
          painter: _LeaderPainter(color, em / 2),
        ),
      );
}

class _LeaderPainter extends CustomPainter {
  _LeaderPainter(this.color, this.step);
  final Color color;
  final double step;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    for (var x = step / 2; x < size.width; x += step) {
      canvas.drawCircle(Offset(x, size.height - 3), 0.8, p);
    }
  }

  @override
  bool shouldRepaint(_LeaderPainter old) => old.color != color || old.step != step;
}

/// One contents row (§7.16, 48 px minimum): ordinal, title, dot leaders,
/// length, state mark.
class ContentsRow extends StatelessWidget {
  const ContentsRow({
    super.key,
    required this.chapter,
    required this.read,
    required this.percent,
    required this.narrated,
    required this.downloadState,
    required this.current,
    required this.selecting,
    required this.selected,
    required this.onTap,
    this.onLongPress,
    this.onMenu,
    this.onSwipeRead,
    this.onMarkTap,
    this.minutes,
    this.reactionSlot,
  });

  final SourceChapterSummary chapter;
  final bool read;
  final int? percent;
  final bool narrated;
  final DownloadChapterState? downloadState;
  final bool current;
  final bool selecting;
  final bool selected;
  final int? minutes;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onMenu;
  final VoidCallback? onSwipeRead;
  final VoidCallback? onMarkTap;

  /// The circle's reaction count folio, when the chapter has any.
  final Widget? reactionSlot;

  @override
  Widget build(BuildContext context) {
    final t = cineOf(context);
    final e = tocEntry(number: chapter.number, title: chapter.title);
    final ink = read ? t.colorInk45 : t.colorInk100;
    final saved = downloadState == DownloadChapterState.complete;
    final folio = CineType.style(context, t.typeFolio);
    final body = CineType.style(context, t.typeBody);

    Widget row = Container(
      constraints: const BoxConstraints(minHeight: kContentsRowExtent),
      decoration: BoxDecoration(
        color: selected ? t.colorPaper3 : (current ? t.colorSpotWash : null),
        border: (selected || current) ? Border(left: BorderSide(color: t.colorSpot, width: 2)) : null,
      ),
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        children: [
          if (selecting)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CineCheckbox(checked: selected || saved, dimmed: saved),
            ),
          SizedBox(
            width: 40,
            child: Text(e.ordinal ?? '·',
                textAlign: TextAlign.right, style: folio.copyWith(color: t.colorSpot),),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              e.title ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: body.copyWith(color: ink),
            ),
          ),
          Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: DotLeader(color: t.colorInk30))),
          if (reactionSlot != null) Padding(padding: const EdgeInsets.only(left: 6), child: reactionSlot),
          if (minutes != null) Text('$minutes MIN', style: folio.copyWith(color: t.colorInk60)),
          if (percent != null)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Text('$percent%', style: folio.copyWith(color: t.colorSpot)),
            )
          else if (read)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Text('READ', style: folio.copyWith(color: t.colorInk45)),
            ),
          if (narrated)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(PhosphorRegular.headphones, size: 16, semanticLabel: 'Narrated'),
            ),
          CineDownloadMark(state: downloadMarkState(downloadState), onTap: onMarkTap),
          if (!selecting && onMenu != null)
            IconButton(
              tooltip: 'Chapter options',
              constraints: const BoxConstraints(minWidth: 44, minHeight: 48),
              padding: EdgeInsets.zero,
              icon: const Icon(PhosphorRegular.dotsThree, size: 20),
              onPressed: onMenu,
            )
          else
            const SizedBox(width: 8),
        ],
      ),
    );
    row = Semantics(
      button: true,
      selected: selected,
      label: '${e.ordinal == null ? '' : 'Chapter ${e.ordinal}, '}${e.title ?? ''}'
          '${read ? ', read' : ''}${current ? ', current' : ''}',
      child: InkWell(onTap: onTap, onLongPress: onLongPress, child: CineFocusRing(child: row)),
    );
    if (onSwipeRead == null) return row;
    return Dismissible(
      key: ValueKey('toc-${chapter.id}'),
      direction: DismissDirection.endToStart,
      dismissThresholds: const {DismissDirection.endToStart: 0.5},
      confirmDismiss: (_) async {
        onSwipeRead!();
        return false;
      },
      background: const SizedBox.shrink(),
      secondaryBackground: Align(
        alignment: Alignment.centerRight,
        child: Container(
          width: 72,
          color: t.colorInk100,
          alignment: Alignment.center,
          child: const Text('READ',
              style: TextStyle(
                  color: Color(0xFF000000), fontSize: 11, fontWeight: FontWeight.w700,),),
        ),
      ),
      child: row,
    );
  }
}
