import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/slab.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/profile_orb.dart';
import 'package:manhwamaniacs/skins/glass/primitives/rail.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_actions.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_rail_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_rails.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/poster_rail.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/spotlight_card.dart';
import 'package:manhwamaniacs/skins/glass/screens/profiles/avatar_map.dart';

/// "From your Circle" (glass 9.3): letters as cards with the `bloom` rim, friends' reads as posters with a friend orb. The people light
/// only: no machine light here.
class HomeCircleRail extends ConsumerWidget {
  const HomeCircleRail({super.key, required this.rail, required this.env});
  final HomeRailSpec rail;
  final HomeRailEnv env;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = rail.items.cast<HomeCircleCard>();
    return GlassRail(
      title: rail.title,
      revealKey: railRevealKey(ref, rail.id),
      screenId: kHomeScreenId,
      onSeeAll: seeAllOf(ref, rail),
      itemCount: items.length,
      itemWidth: 280,
      itemHeight: 124 * 1.5 + 8 + 40 + 14,
      itemBuilder: (context, i) {
        final c = items[i];
        return c.letter != null ? LetterCard(letter: c.letter!) : FriendReadCard(poster: c.poster!, env: env);
      },
    );
  }
}

/// A letter: the `bloomRim` rim `rgba(255,158,216,0.45)`, the sender's 18 px orb and the bloom chip.
class LetterCard extends ConsumerWidget {
  const LetterCard({super.key, required this.letter});
  final Letter letter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Rect rectOf() {
      final ro = context.findRenderObject();
      return ro is RenderBox && ro.attached ? ro.localToGlobal(Offset.zero) & ro.size : Rect.zero;
    }

    return SizedBox(
      width: 280,
      height: 132,
      child: GlassSlab(
        padding: const EdgeInsets.all(8),
        borderColor: const Color(0x73FF9ED8),
        semanticsLabel: '${letter.title}, ${letter.from.name} thinks you\'d like this',
        onTap: () => unawaited(openSeries(ref, letter.sourceId, letter.seriesKey, from: rectOf())),
        child: Row(
          children: [
            SizedBox(width: 80, height: 116, child: ClipRRect(borderRadius: BorderRadius.circular(gt.radiusMd), child: HomeCoverImage(url: letter.coverUrl, width: 80))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GlassLabel(letter.title, role: gt.typeHeadline, maxLines: 2),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      GlassProfileOrb(preset: glassPresetFor(letter.from.avatarKey), size: 18, friend: true, name: letter.from.name),
                      const SizedBox(width: 6),
                      Expanded(child: BloomChip("${letter.from.name} thinks you'd like this")),
                    ],
                  ),
                  if (letter.note != null) Padding(padding: const EdgeInsets.only(top: 4), child: GlassLabel(letter.note!, role: gt.typeFootnote, italic: true, color: gt.colorLabel2, maxLines: 2)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A friend's read: a poster with an 18 px friend orb at the bottom left and "{name} is reading".
class FriendReadCard extends StatelessWidget {
  const FriendReadCard({super.key, required this.poster, required this.env});
  final HomePoster poster;
  final HomeRailEnv env;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topLeft,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            HomePosterCard(poster: poster, env: env, width: 124),
            if (poster.friend != null)
              Positioned(left: 8, top: 124 * 1.5 - 26, child: GlassFriendBadge(glassPresetFor(poster.friend!.avatarKey), name: poster.friend!.name)),
          ],
        ),
      );
}
