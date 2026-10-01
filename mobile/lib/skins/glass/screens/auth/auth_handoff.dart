import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/onboarding/store/onboarding_draft.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/routes/redirect_hold.dart';
import 'package:manhwamaniacs/skins/glass/screens/auth/lens_split_handoff.dart';
import 'package:manhwamaniacs/skins/glass/screens/onboarding/glass_steps.dart';
import 'package:manhwamaniacs/skins/glass/screens/profiles/restart_into.dart';
import 'package:manhwamaniacs/skins/glass/shell/dock_geometry.dart';
import 'package:manhwamaniacs/skins/glass/shell/handoff_layer.dart';
import 'package:manhwamaniacs/skins/glass/shell/melt.dart';
import 'package:manhwamaniacs/skins/glass/shell/profile_switch.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart';
import 'package:manhwamaniacs/skins/glass/shell/sidebar_geometry.dart';
import 'package:manhwamaniacs/skins/glass/splash/glass_mark.dart';

/// Whether the Look step shows (glass 8.7).
bool glassLookShownOf(WidgetRef ref) => Flags.glassAvailable;

/// Where a profile lands: its onboarding step while it needs onboarding, else Home.
String glassDestinationFor(WidgetRef ref, Profile p) {
  final pending = ref.read(onboardingStoreProvider).readPending();
  if (!needsOnboarding(p, pending)) return Routes.tonight();
  final step = resumeGlassStep(p.onboarding, lookShown: glassLookShownOf(ref)) ?? 1;
  return Routes.onboarding({'step': step});
}

/// The rect a flight ends in: the dock's [tab] on phones, the sidebar's profile capsule (or Home item) on wider frames.
Rect glassFlightTarget(BuildContext context, {GlassTab tab = GlassTab.you, bool sidebarHome = false}) {
  final mq = MediaQuery.of(context);
  if (mq.size.shortestSide < 600) return GlassDockGeometry.of(mq.size, mq.padding).tabRect(tab);
  final g = GlassSidebarGeometry.of(mq.size, expanded: sidebarStartsExpanded(mq.size.width));
  return sidebarHome ? g.homeItem : g.profileCapsule;
}

/// A content twin of a lens for flights above the router.
class GlassFlyingLens extends StatelessWidget {
  const GlassFlyingLens({super.key, this.size = 56});
  final double size;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(color: Color(0x66131317), shape: BoxShape.circle, border: Border.fromBorderSide(BorderSide(color: Color(0x38FFFFFF), width: 0.5))),
        child: SizedBox.square(dimension: size, child: Center(child: GlassMark(height: size * 0.43))),
      );
}

/// What follows a successful sign-in or registration once the Slab condense has landed its droplet in the lens (glass 8.3):
/// a remembered profile that is still on the account goes straight home (the lens flies to the dock or sidebar, or melts into
/// the profile's own skin); otherwise the lens splits into the picker's orbs. Releases the redirect hold when it is done.
Future<void> completeAuth(BuildContext context, WidgetRef ref, {required Rect? lensRect, bool registered = false}) async {
  final hold = ref.read(glassRedirectHoldProvider.notifier);
  final reduced = glassReduced(ref);
  final size = MediaQuery.sizeOf(context);
  final centre = lensRect?.center ?? Offset(size.width / 2, 120);
  final radius = (lensRect?.width ?? 56) / 2;
  Profile? remembered;
  if (!registered) {
    final active = ref.read(activeProfileProvider);
    if (active != null) {
      try {
        final list = await ref.read(profilesProvider.future);
        remembered = list.where((p) => p.id == active.id).firstOrNull;
      } catch (_) {
        remembered = null;
      }
    }
  }
  if (!context.mounted) {
    hold.state = false;
    return;
  }
  if (remembered != null) {
    final sw = ref.read(glassProfileSwitchProvider);
    final r = await sw.prepare(remembered);
    if (!context.mounted) {
      hold.state = false;
      return;
    }
    final skin = r.restartTo;
    if (skin != null) {
      await playMelt(ref);
      if (context.mounted) await restartIntoSkin(context, ref, skin);
      hold.state = false;
      return;
    }
    final dest = glassDestinationFor(ref, remembered);
    final target = glassFlightTarget(context);
    if (!reduced && lensRect != null) {
      await ref.read(glassEffectsProvider).flyOrb(from: lensRect, to: target, orb: const GlassFlyingLens());
    }
    ref.read(glassArrivalProvider.notifier).state = GlassArrival(kind: GlassArrivalKind.profile, point: target.center);
    sw.commit(dest);
    hold.state = false;
    return;
  }
  ref.read(glassLensSplitProvider.notifier).state = GlassLensSplit(centre: centre, radius: radius);
  hold.state = false;
}
