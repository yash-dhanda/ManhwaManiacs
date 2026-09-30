import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/source_monogram.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/poster.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_rail_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_rails.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// "New in your pinned sources": for each source a mini rail, a header row (28 px logo or monogram, the name in `headline`, "See all")
/// and its latest covers (up to three) as posters linking to `/sources/{id}?mode=latest`.
class HomePinnedSourcesRail extends ConsumerWidget {
  const HomePinnedSourcesRail({super.key, required this.rail});
  final HomeRailSpec rail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sources = rail.items.cast<HomeSourceItem>();
    final margin = GlassFrame.screenMargin(context);
    final w = posterWidthFor(GlassFrame.of(context));
    void go(String path) => unawaited(ref.read(skinRouterProvider).push<void>(path));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        HomeRailHeader(title: rail.title, railId: rail.id),
        for (final s in sources)
          Padding(
            padding: EdgeInsets.fromLTRB(margin, 12, margin, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (s.suggested) Padding(padding: const EdgeInsets.only(bottom: 4), child: GlassLabel('Suggested sources', role: gt.typeCaption1, color: gt.colorLabel3)),
                Row(
                  children: [
                    SizedBox(width: 28, height: 28, child: GlassSourceMonogram(name: s.name, sourceId: s.sourceId, size: 28)),
                    const SizedBox(width: 10),
                    Expanded(child: GlassLabel(s.name, role: gt.typeHeadline)),
                    GlassButton(label: 'See all', semanticsLabel: 'See all, ${s.name}', variant: GlassButtonVariant.plain, size: GlassButtonSize.small, onPressed: () => go('/sources/${Uri.encodeComponent(s.sourceId)}')),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  child: Row(
                  children: [
                    for (final url in s.latestCovers.take(3))
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GlassPoster(
                          cover: HomeCoverImage(url: url, width: w),
                          title: '${s.name}, latest',
                          width: w,
                          onTap: () => go('/sources/${Uri.encodeComponent(s.sourceId)}?mode=latest'),
                        ),
                      ),
                  ],
                ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
