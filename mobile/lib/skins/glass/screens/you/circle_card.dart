import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/circle/utils/dispatch.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/slab.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/profile_orb.dart';
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';
import 'package:manhwamaniacs/skins/glass/primitives/status_capsule.dart';
import 'package:manhwamaniacs/skins/glass/screens/you/reading_card.dart' show YouCardProblem;
import 'package:manhwamaniacs/skins/glass/shell/shell_common.dart' show avatarPresetFor;
import 'package:manhwamaniacs/skins/glass/type.dart';

/// Where a member is (glass 9.3.1): reading now, active today, or away.
enum Presence { readingNow, activeToday, away }

Presence presenceOf(CircleMember m, DateTime now) {
  if (m.now != null) return Presence.readingNow;
  final a = m.lastActiveAt?.toLocal();
  if (a != null && a.year == now.year && a.month == now.month && a.day == now.day) return Presence.activeToday;
  return Presence.away;
}

/// A 32 px presence orb: reading now wears a breathing `bloom` ring, active today a static ring at 40 %, away none.
class PresenceOrb extends ConsumerStatefulWidget {
  const PresenceOrb({super.key, required this.member, required this.presence, this.size = 32});
  final ProfileRef member;
  final Presence presence;
  final double size;
  @override
  ConsumerState<PresenceOrb> createState() => _PresenceOrbState();
}

class _PresenceOrbState extends ConsumerState<PresenceOrb> with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = ref.watch(glassMotionPrefsProvider.select((m) => m.reduced));
    final reading = widget.presence == Presence.readingNow;
    if (reading && !reduced && !_breath.isAnimating) _breath.repeat(reverse: true);
    if ((!reading || reduced) && _breath.isAnimating) _breath.stop();
    final orb = GlassProfileOrb(preset: avatarPresetFor(widget.member.avatarKey), size: widget.size, name: widget.member.name);
    if (widget.presence == Presence.away) return Padding(padding: const EdgeInsets.all(3), child: orb);
    return AnimatedBuilder(
      animation: _breath,
      builder: (_, child) {
        final a = reading ? (reduced ? 1.0 : 0.55 + 0.45 * _breath.value) : 0.4;
        return Container(
          padding: const EdgeInsets.all(1),
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: gt.colorBloom.withValues(alpha: a), width: 2)),
          child: child,
        );
      },
      child: orb,
    );
  }
}

/// The Circle card (glass 8.24): up to five presence orbs and the last three feed items, the whole card a button to Circle; when
/// this profile does not share, the "Read together" opt-in line instead.
class CircleCard extends ConsumerWidget {
  const CircleCard({super.key, this.offline = false});
  final bool offline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pid = ref.watch(activeProfileProvider)?.id;
    final sharing = pid == null ? null : ref.watch(sharingProvider(pid)).valueOrNull;
    if (sharing != null && !sharing.activity) {
      return GlassSlab(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GlassText('Read together: share what this profile reads with the other readers on this server.', role: gt.typeCallout),
          const SizedBox(height: 8),
          GlassButton(label: 'Turn on sharing', variant: GlassButtonVariant.plain, size: GlassButtonSize.small, onPressed: () => GoRouter.of(context).go(Routes.settings(SettingsSection.circle))),
        ],),
      );
    }
    final members = ref.watch(circleMembersProvider);
    final feed = ref.watch(circleFeedProvider(null));
    if (members.hasError && !members.hasValue) {
      return YouCardProblem(offline: offline, onRetry: () => ref
        ..invalidate(circleMembersProvider)
        ..invalidate(circleFeedProvider(null)),);
    }
    if (!members.hasValue) return const GlassSkeletonGroup(label: 'Loading your Circle', child: GlassSkeleton(height: 120, radius: 26));
    final now = DateTime.now();
    final list = [...members.value!]..sort((a, b) => presenceOf(a, now).index.compareTo(presenceOf(b, now).index));
    final shown = list.take(5).toList();
    final items = (feed.valueOrNull?.items ?? const <FeedItem>[]).take(3).toList();
    final reading = list.where((m) => presenceOf(m, now) == Presence.readingNow).length;
    return GlassSlab(
      padding: const EdgeInsets.all(16),
      semanticsLabel: 'Circle: ${list.length} ${list.length == 1 ? 'reader' : 'readers'}${reading > 0 ? ', $reading reading now' : ''}',
      onTap: () => GoRouter.of(context).go(Routes.circle()),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (offline && members.hasValue) const Padding(padding: EdgeInsets.only(bottom: 8), child: GlassStatusCapsule(kind: GlassStatusKind.savedCopy, savedAgo: 'earlier')),
        Row(children: [
          Expanded(child: GlassText('Circle', role: gt.typeHeadline)),
          for (final m in shown) Padding(padding: const EdgeInsets.only(left: 4), child: PresenceOrb(member: m, presence: presenceOf(m, now))),
        ],),
        if (list.isEmpty) GlassText('No one else reads here yet.', role: gt.typeFootnote, color: gt.colorLabel2),
        for (final i in items)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(children: [
              GlassProfileOrb(preset: avatarPresetFor(i.actor.avatarKey), size: 24, name: i.actor.name),
              const SizedBox(width: 8),
              Expanded(child: GlassText(dispatchText(i, true), role: gt.typeFootnote, maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],),
          ),
      ],),
    );
  }
}
