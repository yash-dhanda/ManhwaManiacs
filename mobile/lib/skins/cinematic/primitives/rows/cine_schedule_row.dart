import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_menu.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_row.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

enum CineReadState { unread, inProgress, read }

/// `TODAY`, `YESTERDAY`, `3 D AGO` (under a week), else `12 SEP 2026`.
String scheduleDateLabel(DateTime date, DateTime now) {
  final d = DateTime(date.year, date.month, date.day);
  final n = DateTime(now.year, now.month, now.day);
  final days = n.difference(d).inDays;
  if (days <= 0) return 'TODAY';
  if (days == 1) return 'YESTERDAY';
  if (days < 7) return '$days D AGO';
  const m = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
  return '${date.day} ${m[date.month - 1]} ${date.year}';
}

/// Drops a "Chapter 12" the source title repeats when the number column already says it.
String dedupeChapterTitle(String title, String? number) {
  if (number == null) return title;
  final m = RegExp('^\\s*(?:chapter|ch\\.?)\\s*${RegExp.escape(number)}\\s*[:.\\-–—]?\\s*(.*)\$', caseSensitive: false).firstMatch(title);
  if (m == null) return title;
  final rest = m[1]!.trim();
  return rest.isEmpty ? 'Chapter $number' : rest;
}

/// The chapter row (cinematic 7.16): the chapter number in `typeFolioLg` in a 56 px right-aligned
/// column (`·` when there is none, decimals as they are), the title, a caption with the release
/// date and page count, then progress `14/27` in `spot` (in progress) or `READ` (complete, the
/// text dims to `ink.45`), a download-mark slot and the Circle reaction slot.
class CineScheduleRow extends StatelessWidget {
  const CineScheduleRow({
    super.key,
    required this.title,
    this.number,
    this.released,
    this.pages,
    this.state = CineReadState.unread,
    this.progressPage,
    this.downloadMark,
    this.reactionSlot,
    this.onTap,
    this.menu,
    this.now,
    this.selected = false,
    this.selectMode = false,
    this.onSelectedChanged,
    this.errorText,
    this.onRetry,
    this.loading = false,
  });

  final String title;
  final String? number;
  final DateTime? released;
  final int? pages, progressPage;
  final CineReadState state;
  final Widget? downloadMark, reactionSlot;
  final VoidCallback? onTap;
  final List<CineMenuEntry<Object?>>? menu;
  final DateTime? now;
  final bool selected, selectMode, loading;
  final ValueChanged<bool>? onSelectedChanged;
  final String? errorText;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final read = state == CineReadState.read;
    final dim = read ? c.colorInk45 : c.colorInk100;
    final caption = [
      if (released != null) scheduleDateLabel(released!, now ?? DateTime.now()),
      if (pages != null) '$pages PAGES',
    ].join(' · ');
    final t = dedupeChapterTitle(title, number);
    final spoken = [
      number == null ? 'Chapter' : 'Chapter $number',
      t,
      if (caption.isNotEmpty) caption.toLowerCase(),
      if (read) 'read' else if (state == CineReadState.inProgress && progressPage != null && pages != null) 'page $progressPage of $pages',
    ].join(', ');
    return CineRowShell(
      onTap: onTap,
      menu: menu,
      selected: selected,
      selectMode: selectMode,
      onSelectedChanged: onSelectedChanged,
      error: errorText != null,
      loading: loading,
      semanticLabel: spoken,
      child: Row(children: [
        SizedBox(width: 56, child: CineRoleText(number ?? '·', c.typeFolioLg, color: dim, textAlign: TextAlign.right)),
        SizedBox(width: c.space4),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            CineRoleText(t, c.typeTitle, color: dim),
            if (errorText != null) CineRoleText(errorText!, c.typeCaption, color: c.colorProof) else if (caption.isNotEmpty) CineRoleText(caption, c.typeCaption, color: c.colorInk45),
          ],),
        ),
        if (errorText != null && onRetry != null)
          GestureDetector(onTap: onRetry, child: CineRoleText('Retry', c.typeLabel, color: c.colorInk100, decoration: TextDecoration.underline))
        else ...[
          if (state == CineReadState.inProgress && progressPage != null && pages != null)
            Padding(padding: EdgeInsets.only(left: c.space3), child: CineRoleText('$progressPage/$pages', c.typeFolio, color: c.colorSpot)),
          if (read) Padding(padding: EdgeInsets.only(left: c.space3), child: CineRoleText('READ', c.typeMicro, color: c.colorInk45)),
          if (downloadMark != null) Padding(padding: EdgeInsets.only(left: c.space3), child: downloadMark),
          if (reactionSlot != null) Padding(padding: EdgeInsets.only(left: c.space3), child: reactionSlot),
        ],
      ],),
    );
  }
}
