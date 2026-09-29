import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/skins/cinematic/duotone.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/quick_look_builders.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_image.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/quick_look.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/sections.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/sections/tonight_rail.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/tonight_layout.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// `Sources`: 16:9 tiles with the newest cover duotoned to the fallback duo, the source name on a
/// `scrim.foot` into the fallback tint, three 40 x 60 plates of the newest covers at the bottom
/// right (cinematic 8.8). With no pins the caption above reads `SUGGESTED SOURCES`.
class SourceTilesSection extends ConsumerWidget {
  const SourceTilesSection({super.key, required this.plan, required this.env});
  final PlannedSection plan;
  final TonightEnv env;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = plan.section.items.whereType<HomeSourceItem>().toList();
    final suggested = items.isNotEmpty && items.every((s) => s.suggested);
    return TonightRail(
      headingId: 'tonight.sources',
      heading: plan.section.title,
      folio: plan.folio,
      itemCount: items.length,
      visiblePhone: 1.2,
      visibleTablet: 2.2,
      caption: suggested ? 'SUGGESTED SOURCES' : null,
      onSeeAll: seeAllFor(context, plan.section.type),
      itemHeight: (w) => w * 9 / 16 + 16,
      itemBuilder: (context, i, w) => _Tile(item: items[i], ref: ref),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.item, required this.ref});
  final HomeSourceItem item;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final back = item.latestCovers.isEmpty ? null : coverAbs(ref, item.latestCovers.first);
    return Semantics(
      button: true,
      label: item.name,
      excludeSemantics: true,
      onTap: () => context.go(Routes.source(item.sourceId)),
      onLongPress: () => unawaited(openSourceQuickLook(context, ref, item)),
      child: CineQuickLookTarget(
        onOpen: () => unawaited(openSourceQuickLook(context, ref, item)),
        child: CinePressable(
          hit: false,
          onTap: () => context.go(Routes.source(item.sourceId)),
          builder: (context, st) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Transform.translate(
                offset: Offset(0, st.pressed ? 1 : 0),
                child: Stack(fit: StackFit.expand, children: [
                  CineDuotone(duo: c.colorAmbientFallbackDuo, child: CineImage(url: back, title: item.name)),
                  LayoutBuilder(builder: (ctx, b) => DecoratedBox(decoration: BoxDecoration(gradient: scrimFoot(c.colorAmbientFallbackTint, b.maxHeight - 44, b.maxHeight)))),
                  Positioned(left: 12, right: 12 + 3 * 44.0, bottom: 12, child: CineRoleText(item.name, c.typeSubhead, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      for (var k = 0; k < item.latestCovers.take(3).length; k++) ...[
                        if (k > 0) const SizedBox(width: 4),
                        SizedBox(width: 40, height: 60, child: CineImage(url: coverAbs(ref, item.latestCovers[k]), title: '')),
                      ],
                    ],),
                  ),
                ],),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
