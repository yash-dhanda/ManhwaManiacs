import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/a11y/folio.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/stock.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The in-page running head at the top of the chapter in the scroll layout (cinematic 8.15.1): the
/// series title and the chapter kicker on the left, the folio (`42%`) on the right. Its opacity
/// follows its distance from the top of the viewport over 120 px as it scrolls away; under
/// reduced motion it simply scrolls away.
class NovelInPageHead extends StatelessWidget {
  const NovelInPageHead({
    super.key,
    required this.seriesTitle,
    required this.kicker,
    required this.percent,
    required this.stock,
    required this.scroll,
  });

  final String seriesTitle, kicker;
  final ValueListenable<int> percent;
  final CineStockColors stock;
  final ScrollController scroll;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final reduced = CineMotion.reduced(context);
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CineRoleText(
            [if (seriesTitle.isNotEmpty) seriesTitle, kicker].join(' · '),
            c.typeKicker,
            color: stock.muted,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 16),
        ValueListenableBuilder<int>(
          valueListenable: percent,
          builder: (context, p, _) => Semantics(
            label: folioLabel('$p%'),
            excludeSemantics: true,
            child: CineRoleText('$p%', c.typeFolio, color: stock.muted),
          ),
        ),
      ],
    );
    if (reduced) return row;
    return AnimatedBuilder(
      animation: scroll,
      child: row,
      builder: (context, child) {
        final offset = scroll.hasClients ? scroll.offset : 0.0;
        return Opacity(opacity: (1 - offset / 120).clamp(0.0, 1.0), child: child);
      },
    );
  }
}
