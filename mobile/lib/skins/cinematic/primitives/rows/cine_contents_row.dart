import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_menu.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_dot_leader.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_row.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The novel table-of-contents row (cinematic 7.16): ordinal `typeFolio` right-aligned, the title
/// in Newsreader 16, dot leaders, the length `12 MIN`, then a state mark: `42%` in `spot`, `READ`,
/// a headphones glyph when narrated, the download mark. Minimum 48. [current] is the chapter being
/// read (a `spot.wash` band with a 2 px `spot` bar).
class CineContentsRow extends StatelessWidget {
  const CineContentsRow({
    super.key,
    required this.ordinal,
    required this.title,
    this.minutes,
    this.percent,
    this.read = false,
    this.narrated = false,
    this.downloadMark,
    this.current = false,
    this.onTap,
    this.menu,
  });

  final int ordinal;
  final String title;
  final int? minutes, percent;
  final bool read, narrated, current;
  final Widget? downloadMark;
  final VoidCallback? onTap;
  final List<CineMenuEntry<Object?>>? menu;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final ink = read ? c.colorInk45 : c.colorInk100;
    return CineRowShell(
      minHeight: 48,
      onTap: onTap,
      menu: menu,
      current: current,
      semanticLabel: [
        'Chapter $ordinal',
        title,
        if (minutes != null) '$minutes minutes',
        if (read) 'read' else if (percent != null) '$percent percent read',
        if (narrated) 'narrated',
      ].join(', '),
      child: Row(children: [
        SizedBox(width: 32, child: CineRoleText('$ordinal', c.typeFolio, color: c.colorInk45, textAlign: TextAlign.right)),
        SizedBox(width: c.space3),
        Flexible(child: CineLit(title, CineFace.newsreader, 16, 24, color: ink)),
        SizedBox(width: c.space2),
        const Expanded(child: Padding(padding: EdgeInsets.only(top: 8), child: CineDotLeader())),
        SizedBox(width: c.space2),
        if (minutes != null) CineRoleText('$minutes MIN', c.typeFolio, color: c.colorInk45),
        if (percent != null && !read) Padding(padding: EdgeInsets.only(left: c.space2), child: CineRoleText('$percent%', c.typeFolio, color: c.colorSpot)),
        if (read) Padding(padding: EdgeInsets.only(left: c.space2), child: CineRoleText('READ', c.typeMicro, color: c.colorInk45)),
        if (narrated) Padding(padding: EdgeInsets.only(left: c.space2), child: CineGlyphIcon(CineGlyph.headphones, size: 16, color: c.colorInk60)),
        if (downloadMark != null) Padding(padding: EdgeInsets.only(left: c.space2), child: downloadMark),
      ],),
    );
  }
}
