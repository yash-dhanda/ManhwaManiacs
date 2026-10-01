import 'dart:math' show max;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heroine/heroine.dart' show Heroine;
import 'package:manhwamaniacs/features/library/providers/daily_goal_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novels_gate_provider.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/glass/ambient_field.dart' show moodColour;
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/content_mode_switch.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/goal_ring.dart';
import 'package:manhwamaniacs/skins/glass/primitives/profile_orb.dart';
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/admin_common.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_common.dart' show avatarPresetFor;
import 'package:manhwamaniacs/skins/glass/transitions/poster_zoom.dart' show glassZoomMotion;
import 'package:manhwamaniacs/skins/glass/type.dart';

/// The active profile's orb at [size], wearing the daily goal ring when the profile has a goal (glass 9.2.2).
class YouOrb extends ConsumerWidget {
  const YouOrb({super.key, this.size = 72});
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(activeProfileProvider);
    final orb = GlassProfileOrb(preset: avatarPresetFor(p?.avatarKey), size: size, mood: p == null ? null : moodColour(p.mood), name: p?.name);
    final goal = ref.watch(dailyGoalProvider);
    if (goal.goalMinutes == null) return orb;
    // The live progress answers, or the 1-day statistics on a cold start, whichever knows more.
    final seconds = max(goal.todaySeconds, ref.watch(statsTodaySecondsProvider) ?? 0);
    return GlassGoalRing(orbSize: size, minutes: seconds ~/ 60, goal: goal.goalMinutes!, child: orb);
  }
}

/// The profile block (glass 8.24): the 72 px orb with its goal ring, the name, "@yash · Administrator", "Switch profile" and the
/// content-mode switch when novels are on. [orbKey] marks the orb's slot for the Orb lift; [orbVisible] hides it while the copy flies.
class ProfileBlock extends ConsumerWidget {
  const ProfileBlock({super.key, required this.orbKey, this.orbOpacity = 1});
  final GlobalKey orbKey;
  final double orbOpacity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(activeProfileProvider);
    final user = glassUser(ref);
    final name = p?.name ?? user?.label ?? 'You';
    final handle = user == null ? '' : (user.isAdmin ? '@${user.username} · Administrator' : '@${user.username}');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        SizedBox(
          key: orbKey,
          width: 72,
          height: 72,
          child: Opacity(
            opacity: orbOpacity,
            child: p == null ? const YouOrb() : Heroine(tag: 'profile-orb-${p.id}', motion: glassZoomMotion(), child: const YouOrb()),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Semantics(label: name, excludeSemantics: true, child: GlassText(name, role: gt.typeTitle1, maxLines: 1, overflow: TextOverflow.ellipsis)),
            if (handle.isNotEmpty) GlassText(handle, role: gt.typeFootnote, color: gt.colorLabel2, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            GlassButton(label: 'Switch profile', onPressed: () => GoRouter.of(context).go(Routes.profiles())),
          ],),
        ),
      ],),
      if (ref.watch(novelsEnabledProvider)) const Padding(padding: EdgeInsets.only(top: 12), child: GlassContentModeSwitch(variant: GlassContentModeVariant.navRow)),
    ],);
  }
}

/// The loading form: a 72 px circle and two text bars.
class ProfileBlockSkeleton extends StatelessWidget {
  const ProfileBlockSkeleton({super.key});
  @override
  Widget build(BuildContext context) => const GlassSkeletonGroup(
        label: 'Loading your profile',
        child: Row(children: [
          GlassSkeleton(width: 72, height: 72, circle: true),
          SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              GlassSkeleton(width: 160, height: 24, index: 1),
              SizedBox(height: 8),
              GlassSkeleton(width: 110, height: 14, index: 2),
            ],),
          ),
        ],),
      );
}
