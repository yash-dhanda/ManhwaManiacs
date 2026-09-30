import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/app/switch_skin.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/glass/ambient_field.dart'
    show moodColour;
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/profile_orb.dart';
import 'package:manhwamaniacs/skins/glass/shell/dock_geometry.dart';
import 'package:manhwamaniacs/skins/glass/shell/handoff_layer.dart';
import 'package:manhwamaniacs/skins/glass/shell/melt.dart';
import 'package:manhwamaniacs/skins/glass/shell/profile_switch.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_common.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart';
import 'package:manhwamaniacs/skins/glass/shell/sidebar_geometry.dart';

/// Where the chosen orb lands: the dock's You tab on phones, the sidebar's profile capsule on wider frames.
Rect profileFlightTarget(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  if (GlassFrame.of(context) == GlassFrameKind.phone) {
    final r = GlassDockGeometry.of(size, MediaQuery.paddingOf(context))
        .tabRect(GlassTab.you);
    return Rect.fromCenter(center: r.center, width: 24, height: 24);
  }
  final expanded =
      ProviderScope.containerOf(context).read(glassSidebarChoiceProvider) ??
          sidebarStartsExpanded(size.width);
  final c = GlassSidebarGeometry.of(size, expanded: expanded).profileCapsule;
  return Rect.fromCenter(
      center: expanded ? Offset(c.left + 24, c.center.dy) : c.center,
      width: 32,
      height: 32,);
}

/// The short hand-off (glass 8.25.2): the orb flies to its place, the field pours to the new mood, then every branch resets at Home.
/// A profile whose skin differs melts and restarts instead, with no alert and no Undo.
Future<void> switchProfileWithHandoff(
    BuildContext context, WidgetRef ref, Profile target,
    {required Rect from,}) async {
  final sw = ref.read(glassProfileSwitchProvider);
  final prepared = await sw.prepare(target);
  if (!context.mounted) return;
  unawaited(ref.read(glassHapticsProvider).fire(HapticEvent.profileSelect));
  final restartTo = prepared.restartTo;
  if (restartTo != null) {
    await playMelt(ref);
    if (!context.mounted) return;
    await restartInto(context, ref, skin: restartTo, returnRoute: '/');
    return;
  }
  final to = profileFlightTarget(context);
  final orb = GlassProfileOrb(
      preset: avatarPresetFor(target.avatarKey),
      size: 32,
      mood: moodColour(target.mood),);
  await ref.read(glassEffectsProvider).flyOrb(from: from, to: to, orb: orb);
  sw.commit(Routes.tonight());
}

/// The profile switcher menu (long-press on the profile orb or the dock's You tab): each other profile as a 32 px orb row.
Future<void> showProfileSwitcher(
    BuildContext context, WidgetRef ref, Rect anchor,) async {
  final active = ref.read(activeProfileProvider);
  final profiles = ref.read(profilesProvider).valueOrNull ?? const <Profile>[];
  final others = [
    for (final p in profiles)
      if (p.id != active?.id) p,
  ];
  if (others.isEmpty) return;
  await showGlassMenu(
    context,
    anchor: anchor,
    title: 'Switch profile',
    entries: [
      for (final p in others)
        GlassMenuEntry(
          label: p.name,
          leading: GlassProfileOrb(
              preset: avatarPresetFor(p.avatarKey),
              size: 24,
              mood: moodColour(p.mood),),
          onSelected: () => unawaited(
              switchProfileWithHandoff(context, ref, p, from: anchor),),
        ),
    ],
  );
}
