import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/raised_folio.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// A rail's header row, reusable outside rails: a drawn rule, the folio, the revealed heading and
/// See all (cinematic 7.8, 7.27).
class CineSectionHeader extends StatelessWidget {
  const CineSectionHeader({super.key, required this.headingId, required this.heading, this.folio, this.onSeeAll, this.rule = true, this.footnote});
  final String headingId, heading;
  final String? folio;
  final VoidCallback? onSeeAll;
  final bool rule;

  /// A raised footnote mark after the heading (The Numbers' "Chapters per day").
  final int? footnote;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
      if (rule) ...[const CineRuleDraw(), SizedBox(height: c.space3)],
      Row(children: [
        if (folio != null) ...[CineRoleText(folio!, c.typeFolio, color: c.colorInk45), SizedBox(width: c.space3)],
        Flexible(
          child: SetHeading(
            heading,
            id: 'section-$headingId',
            style: CineText.style(context, c.typeSection).copyWith(color: c.colorInk100),
            cap: c.typeSection.cap,
            level: 2,
            linked: onSeeAll != null,
          ),
        ),
        if (footnote != null)
          Padding(padding: const EdgeInsets.only(left: 2), child: Text.rich(TextSpan(children: [raisedFolio(footnote!, CineText.style(context, c.typeSection).fontSize ?? 24)]))),
        const Spacer(),
        if (onSeeAll != null)
          Semantics(
            button: true,
            label: 'See all, $heading',
            excludeSemantics: true,
            onTap: onSeeAll,
            child: CinePressable(
              onTap: onSeeAll,
              builder: (_, st) => Row(mainAxisSize: MainAxisSize.min, children: [
                CineRoleText('See all', c.typeLabel, color: st.hovered ? c.colorInk100 : c.colorInk60),
                const SizedBox(width: 4),
                CineGlyphIcon(CineGlyph.arrowRight, size: 16, color: st.hovered ? c.colorInk100 : c.colorInk60),
              ],),
            ),
          ),
      ],),
    ],);
  }
}
