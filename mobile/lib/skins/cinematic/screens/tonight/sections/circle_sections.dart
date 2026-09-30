import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/circle_poll_scope.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_avatar.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_poster.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/typed_text.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/circle/letters_list.dart' show LetterActions;
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/sections.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/sections/tonight_rail.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

double _rowHeight(double w) => w * 3 / 2 + 44;

/// Up to three 20 px avatars overlapping by 6 px, at the bottom-left of a poster's art.
class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.members});
  final List<ProfileRef> members;

  @override
  Widget build(BuildContext context) {
    final shown = members.take(3).toList();
    return SizedBox(
      height: 20,
      width: 20.0 + 14.0 * (shown.length - 1),
      child: Stack(children: [
        for (var i = 0; i < shown.length; i++) Positioned(left: 14.0 * i, child: CineAvatar(avatarKey: shown[i].avatarKey, size: 20, semanticName: shown[i].name)),
      ],),
    );
  }
}

Widget _withAvatars(double w, Widget poster, List<ProfileRef> members) => Stack(clipBehavior: Clip.none, children: [
      poster,
      Positioned(left: 6, top: w * 1.5 - 26, child: IgnorePointer(child: _AvatarStack(members: members))),
    ],);

/// `Sent to you`: the letters' series with the sender's avatar bottom-left and the newest note typed
/// under the heading (cinematic 8.8, 9.3.4). A poster opens the series and marks its letter read.
class SentToYouSection extends ConsumerWidget {
  const SentToYouSection({super.key, required this.plan});
  final PlannedSection plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.cine;
    final items = plan.section.items.whereType<Letter>().toList();
    final note = plan.section.note;
    final from = items.isEmpty ? null : items.first.from.name;
    final line = note == null || note.isEmpty ? null : (from == null ? note : '$from: $note');
    return TonightRail(
      headingId: 'tonight.sent_to_you',
      heading: plan.section.title,
      folio: plan.folio,
      itemCount: items.length,
      visiblePhone: 2.3,
      visibleTablet: 4.3,
      onSeeAll: () => context.go(Routes.circle({'tab': 'letters'})),
      captionWidget: line == null
          ? null
          : TypedText.plain(line.length > 140 ? line.substring(0, 140) : line, key: ValueKey('sent-note-$line'), style: CineText.style(context, c.typeBodyItalic).copyWith(color: c.colorInk60), maxLines: 2, overflow: TextOverflow.ellipsis),
      itemHeight: _rowHeight,
      itemBuilder: (context, i, w) {
        final l = items[i];
        return _withAvatars(
          w,
          CinePoster(
            key: ValueKey('sent-${l.id}'),
            title: l.title,
            url: coverAbs(ref, l.coverUrl),
            folio: l.state == LetterState.kept ? 'KEPT' : null,
            duo: l.ambient?.duo,
            flickerIndex: i,
            onTap: () => unawaited(LetterActions(context, ref).read(l)),
          ),
          [l.from],
        );
      },
    );
  }
}

/// `From the Circle`: posters with an avatar stack bottom-left, `See all` to the Circle.
class FromTheCircleSection extends ConsumerWidget {
  const FromTheCircleSection({super.key, required this.plan});
  final PlannedSection plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = plan.section.items.whereType<HomeCircleItem>().toList();
    return CirclePollScope(
      child: TonightRail(
        headingId: 'tonight.circle',
        heading: plan.section.title,
        folio: plan.folio,
        itemCount: items.length,
        visiblePhone: 2.3,
        visibleTablet: 4.3,
        onSeeAll: () => context.go(Routes.circle()),
        itemHeight: _rowHeight,
        itemBuilder: (context, i, w) {
          final it = items[i];
          return _withAvatars(
            w,
            CinePoster(
              key: ValueKey('circle-${it.series.sourceId}-${it.series.seriesKey}'),
              title: it.series.title,
              url: coverAbs(ref, it.series.coverUrl),
              duo: it.series.ambient?.duo,
              flickerIndex: i,
              onTap: () => context.push(Routes.feature(it.series.sourceId, it.series.seriesKey)),
            ),
            it.stack,
          );
        },
      ),
    );
  }
}

/// `Most read in the circle`: ranked posters (a Bodoni Roman numeral in `ink.45`, half behind the
/// poster's left edge).
class MostReadInCircleSection extends ConsumerWidget {
  const MostReadInCircleSection({super.key, required this.plan});
  final PlannedSection plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = plan.section.items.whereType<HomeCircleItem>().toList();
    return TonightRail(
      headingId: 'tonight.circle_top',
      heading: plan.section.title,
      folio: plan.folio,
      itemCount: items.length,
      visiblePhone: 2.3,
      visibleTablet: 4.3,
      itemHeight: _rowHeight,
      itemBuilder: (context, i, w) {
        final it = items[i];
        return Padding(
          padding: EdgeInsets.only(left: w * 0.18),
          child: CinePoster(
            key: ValueKey('top-${it.series.sourceId}-${it.series.seriesKey}'),
            title: it.series.title,
            url: coverAbs(ref, it.series.coverUrl),
            caption: CinePosterCaption.ranked,
            rank: it.rank ?? i + 1,
            duo: it.series.ambient?.duo,
            flickerIndex: i,
            onTap: () => context.push(Routes.feature(it.series.sourceId, it.series.seriesKey)),
          ),
        );
      },
    );
  }
}
