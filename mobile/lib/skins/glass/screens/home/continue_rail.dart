import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/home/utils/continue_hidden.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/parts/recap/continue_series.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/continue_stack.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/rail.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/hero_claim.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_actions.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_rail_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_rails.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/poster_menu.dart';

/// "Continue reading" (glass 8.8): Continue stacks, 280 x 132 on phones and 320 x 148 wider, no horizontal swipe. The long-press menu and the
/// trailing ellipsis open the same menu, which starts with "Previously on".
class HomeContinueRail extends ConsumerWidget {
  const HomeContinueRail({super.key, required this.rail});
  final HomeRailSpec rail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wide = GlassFrame.of(context).index >= GlassFrameKind.desktop.index;
    final items = rail.items.cast<HomeContinueItem>();
    return GlassRail(
      title: rail.title,
      revealKey: railRevealKey(ref, rail.id),
      screenId: kHomeScreenId,
      onSeeAll: seeAllOf(ref, rail),
      itemCount: items.length,
      itemWidth: wide ? 320 : 280,
      itemHeight: (wide ? 148 : 132) * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.75),
      itemBuilder: (context, i) => ContinueCard(item: items[i]),
    );
  }
}

class ContinueCard extends ConsumerWidget {
  const ContinueCard({super.key, required this.item});
  final HomeContinueItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final row = item.row;
    final target = HomeContinueTarget.fromContinue(item);
    Rect rectOf() {
      final ro = context.findRenderObject();
      return ro is RenderBox && ro.attached ? ro.localToGlobal(Offset.zero) & ro.size : Rect.zero;
    }

    void menu() {
      final from = rectOf();
      unawaited(showSeriesMenu(
        context,
        ref,
        SeriesMenuSpec(sourceId: row.sourceId, seriesKey: row.seriesKey, title: row.title ?? row.seriesKey, coverUrl: row.coverUrl, target: target, readNumber: row.chapterNumber),
        from,
        first: [GlassMenuEntry(label: 'Previously on', onSelected: () => unawaited(openRecap(ref, row.sourceId, row.seriesKey, item.recap?.toKey ?? row.chapterKey, from: from)))],
        extra: [
          GlassMenuEntry(
            label: 'Remove from row',
            onSelected: () {
              hideContinue(ref.read, row);
              showGlassToast(ref, GlassToastSpec('Removed from Continue reading', undo: () => unhideContinue(ref.read, row)));
            },
          ),
        ],
      ),);
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      excludeFromSemantics: true, // the trailing ellipsis is the accessible way to the same menu
      onLongPress: menu,
      child: GlassContinueStack(
        cover: HomeHero(sourceId: row.sourceId, seriesKey: row.seriesKey, child: HomeCoverImage(url: row.coverUrl, width: 88)),
        title: row.title ?? row.seriesKey,
        chapter: (row.chapterNumber ?? 0).round(),
        page: row.lastPage,
        pageCount: row.pageCount,
        onOpen: () => unawaited(openSeries(ref, row.sourceId, row.seriesKey, from: rectOf())),
        onContinue: () => unawaited(continueSeries(context, ref, target, rectOf())),
        onMore: menu,
        onPreviouslyOn: () => unawaited(openRecap(ref, row.sourceId, row.seriesKey, item.recap?.toKey ?? row.chapterKey, from: rectOf())),
      ),
    );
  }
}
