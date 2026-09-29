import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/home/utils/continue_hidden.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/quick_look_builders.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cards/cine_cutting_card.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/quick_look.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/sections.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/sections/tonight_rail.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/tonight_layout.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// `Continue reading`: cuttings (a 3:2 crop biased to the top, a 2 px `spot` progress rule, a
/// folio caption, a nudge badge); rows hidden with "Remove from row" are dropped (cinematic 8.8).
class ContinueCuttingsSection extends ConsumerWidget {
  const ContinueCuttingsSection({super.key, required this.plan, required this.env});
  final PlannedSection plan;
  final TonightEnv env;

  String _folio(HomeContinueItem it, bool novel) {
    final r = it.row;
    if (r.pageCount == 0) return 'NEXT · ${chapterFolio(r.chapterNumber)}';
    final pct = (r.progressPct * 100).round();
    return novel ? '$pct% · ${chapterFolio(r.chapterNumber)}' : '${chapterFolio(r.chapterNumber)} · $pct%';
  }

  String? _nudge(HomeContinueItem it) => switch (it.nudge) {
        ContinueNudge.newChapters => '${it.newCount > 99 ? '99+' : it.newCount} NEW',
        ContinueNudge.almostDone => 'ALMOST DONE',
        ContinueNudge.paused => 'PAUSED ${it.pausedDays} D',
        null => null,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(continueHiddenProvider);
    final novel = env.feed.cover?.isNovel ?? false;
    final all = plan.section.items.whereType<HomeContinueItem>().toList();
    final byRow = {for (final it in all) it.row: it};
    final rows = filterHidden([for (final it in all) it.row], hidden);
    final items = [for (final r in rows) byRow[r]!].take(12).toList();
    if (items.isEmpty && plan.section.hasItems) return const SizedBox.shrink();
    return TonightRail(
      headingId: 'tonight.continue',
      heading: plan.section.title,
      folio: plan.folio,
      itemCount: items.length,
      error: !plan.section.hasItems,
      onRetry: env.refresh,
      visiblePhone: 1.6,
      visibleTablet: 3.2,
      onSeeAll: seeAllFor(context, plan.section.type),
      itemHeight: (w) {
        final c = context.cine;
        return w * 2 / 3 + c.space2 + roleLineHeight(context, c.typeTitle) + c.space1 / 2 + roleLineHeight(context, c.typeFolio) + 4;
      },
      itemBuilder: (context, i, w) {
        final it = items[i];
        final r = it.row;
        final index = plan.section.items.indexOf(it);
        final tag = env.tags.of('${plan.index}:$index');
        final card = CineCuttingCard(
          title: r.title ?? 'Continue',
          folio: _folio(it, novel),
          imageUrl: coverAbs(ref, r.coverUrl),
          progress: r.pageCount > 0 ? r.progressPct.clamp(0.0, 1.0) : null,
          nudge: _nudge(it),
          onTap: () => continueTo(context, ref, r.sourceId, r.seriesKey, r.chapterKey, entry: env.entry),
        );
        return CineQuickLookTarget(
          onOpen: () => unawaited(openCuttingQuickLook(context, ref, it, entry: env.entry, heroTag: tag)),
          child: card,
        );
      },
    );
  }
}
