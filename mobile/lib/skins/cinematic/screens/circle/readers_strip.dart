import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/utils/presence.dart';
import 'package:manhwamaniacs/features/sources/providers/source_progress_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_avatar.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_badge.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/layout/cine_grid.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// Names that more than one member carries: each of them also shows `@username` (cinematic 9.3.2).
Set<String> duplicateMemberNames(Iterable<ProfileRef> members) {
  final seen = <String>{}, dup = <String>{};
  for (final m in members) {
    if (!seen.add(m.name)) dup.add(m.name);
  }
  return dup;
}

/// The readers strip: every member as a 44 px avatar over the name, 24 px apart, a trailing 24 px
/// fade; members with `now` wear the reading-now ring and a `NOW` badge. A 450 ms long-press shows
/// what they are reading (the chapter folio only when the viewer has progress on that chapter); a
/// tap opens the member page.
class ReadersStrip extends ConsumerWidget {
  const ReadersStrip({super.key, required this.members});
  final List<CircleMember> members;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grid = CineGrid.of(context);
    final dup = duplicateMemberNames(members);
    final progress = ref.watch(sourceProgressProvider.select((m) => m.keys.toSet()));
    return SizedBox(
      height: 112,
      child: ShaderMask(
        shaderCallback: (r) => const LinearGradient(colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0x00FFFFFF)], stops: [0, 0.94, 1]).createShader(r),
        blendMode: BlendMode.dstIn,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.only(left: grid.left, right: grid.right + 24),
          itemCount: members.length,
          separatorBuilder: (_, __) => const SizedBox(width: 24),
          itemBuilder: (context, i) => ReaderChip(member: members[i], showUsername: dup.contains(members[i].name), viewerProgress: progress),
        ),
      ),
    );
  }
}

/// One member: avatar (with the ring), name, `NOW`, optional `@username`.
class ReaderChip extends StatefulWidget {
  const ReaderChip({super.key, required this.member, required this.showUsername, required this.viewerProgress, this.avatarSize = 44});
  final CircleMember member;
  final bool showUsername;
  final Set<String> viewerProgress;
  final double avatarSize;

  @override
  State<ReaderChip> createState() => _ReaderChipState();
}

class _ReaderChipState extends State<ReaderChip> {
  final _tip = GlobalKey<TooltipState>();

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final m = widget.member;
    final now = m.now;
    final label = now == null ? null : nowLabel(now, widget.viewerProgress);
    final avatar = CineReadingNowRing(duo: now == null ? null : ringColour(now), child: CineAvatar(avatarKey: m.avatarKey, size: widget.avatarSize));
    return Semantics(
      button: true,
      label: '${m.name}${now == null ? '' : ', reading now'}',
      excludeSemantics: true,
      onTap: () => unawaited(context.push(Routes.circleMember(m.profileId))),
      onLongPress: label == null ? null : () => _tip.currentState?.ensureTooltipVisible(),
      child: Tooltip(
        key: _tip,
        message: label ?? '',
        triggerMode: TooltipTriggerMode.manual,
        decoration: BoxDecoration(color: c.colorPaper2, border: Border.all(color: c.colorRule2)),
        textStyle: CineText.style(context, c.typeCaption).copyWith(color: c.colorInk100),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: CinePressable(
          hit: false,
          onTap: () => unawaited(context.push(Routes.circleMember(m.profileId))),
          onLongPress: label == null
              ? null
              : () {
                  cineFeedback(context, HapticEvent.longpressOpen);
                  _tip.currentState?.ensureTooltipVisible();
                },
          builder: (context, st) => ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 64),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              avatar,
              SizedBox(height: c.space1),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Flexible(child: CineRoleText(m.name, c.typeUi, color: st.hovered || st.focused ? c.colorInk100 : c.colorInk100, maxLines: 1, overflow: TextOverflow.ellipsis)),
                if (now != null) ...[SizedBox(width: c.space1), const CineBadge('NOW', variant: CineBadgeVariant.now)],
              ],),
              if (widget.showUsername && m.username != null) CineRoleText('@${m.username}', c.typeCaption, color: c.colorInk45, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],),
          ),
        ),
      ),
    );
  }
}
