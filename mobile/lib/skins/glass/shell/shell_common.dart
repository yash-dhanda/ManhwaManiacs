import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/skins/glass/glass/ambient_field.dart'
    show moodColour;
import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart'
    show GlassButtonIcon;
import 'package:manhwamaniacs/skins/glass/primitives/goal_ring.dart';
import 'package:manhwamaniacs/skins/glass/primitives/profile_orb.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart';

/// A [GlassButtonIcon] for a semantic icon role: the Regular glyph, the Fill one on press.
GlassButtonIcon roleIcon(GlassIconRole r) {
  final m = glassIcons[r]!;
  return GlassButtonIcon(m[GlassIconWeight.regular]!,
      fill: m[GlassIconWeight.fill],);
}

const List<String> _avatarKeys = [
  'violet',
  'cyan',
  'rose',
  'amber',
  'emerald',
  'ember',
  'blade',
  'phantom',
  'arcane',
  'lunar',
  'star',
  'reader',
];

GlassAvatarPreset avatarPresetFor(String? key) {
  final i = _avatarKeys.indexOf(key ?? '');
  return GlassAvatarPreset.values[i < 0 ? 0 : i];
}

/// The global rect of [context]'s render box (a trigger's anchor for menus and flights).
Rect globalRectOf(BuildContext context) {
  final ro = context.findRenderObject();
  if (ro is! RenderBox || !ro.attached) return Rect.zero;
  return ro.localToGlobal(Offset.zero) & ro.size;
}

/// The active profile's orb, wearing the goal ring when `glassGoalRingProvider` has one.
class GlassMyOrb extends ConsumerWidget {
  const GlassMyOrb(
      {super.key, this.size = 44, this.onPressed, this.onDisc = false,});
  final double size;
  final VoidCallback? onPressed;
  final bool onDisc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ActiveProfile? p = ref.watch(activeProfileProvider);
    final goal = ref.watch(glassGoalRingProvider);
    final orb = GlassProfileOrb(
      preset: avatarPresetFor(p?.avatarKey),
      size: size,
      mood: p == null ? null : moodColour(p.mood),
      name: p?.name,
      onPressed: onPressed,
    );
    if (goal == null) return orb;
    return GlassGoalRing(
        orbSize: size,
        minutes: goal.minutes,
        goal: goal.goal,
        onDisc: onDisc,
        child: orb,);
  }
}
