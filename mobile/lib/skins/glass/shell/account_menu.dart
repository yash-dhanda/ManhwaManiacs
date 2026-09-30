import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/skins/glass/glass/ambient_field.dart' show moodColour;
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/profile_orb.dart';
import 'package:manhwamaniacs/skins/glass/shell/profile_menu.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_common.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// The rows of the sidebar's account menu (glass 7.16): a header with the display name, "@username", the email and an
/// "Administrator" tag, the other profiles as 32 px orbs, "Manage profiles", "Settings", "Switch account" and "Sign out".
List<GlassMenuEntry> accountMenuEntries(WidgetRef ref, BuildContext context, Rect anchor, {bool signingOut = false}) {
  final auth = ref.read(authControllerProvider);
  final user = auth is AuthAuthenticated ? auth.user : null;
  final active = ref.read(activeProfileProvider);
  final profiles = [for (final p in ref.read(profilesProvider).valueOrNull ?? const <Profile>[]) if (p.id != active?.id) p];
  final router = ref.read(skinRouterProvider);
  return [
    if (user != null) ...[
      GlassMenuEntry(label: user.label, enabled: false),
      GlassMenuEntry(label: '@${user.username}', enabled: false),
      if (user.email != null && user.email!.isNotEmpty) GlassMenuEntry(label: user.email!, enabled: false),
      if (user.isAdmin) const GlassMenuEntry(label: 'Administrator', enabled: false),
    ],
    for (final p in profiles)
      GlassMenuEntry(
        label: p.name,
        separatorBefore: p == profiles.first,
        leading: GlassProfileOrb(preset: avatarPresetFor(p.avatarKey), size: 32, mood: moodColour(p.mood)),
        onSelected: () => unawaited(switchProfileWithHandoff(context, ref, p, from: anchor)),
      ),
    GlassMenuEntry(label: 'Manage profiles', separatorBefore: true, onSelected: () => router.go('/profiles/manage')),
    GlassMenuEntry(label: 'Settings', onSelected: () => router.go('/settings')),
    GlassMenuEntry(
      label: 'Switch account',
      separatorBefore: true,
      run: () async {
        await ref.read(authControllerProvider.notifier).logout();
        router.go('/login');
      },
    ),
    GlassMenuEntry(
      label: signingOut ? 'Signing out…' : 'Sign out',
      destructive: true,
      run: () async {
        await ref.read(authControllerProvider.notifier).logout();
      },
    ),
  ];
}

Future<void> showAccountMenu(BuildContext context, WidgetRef ref, Rect anchor) =>
    showGlassMenu(context, anchor: anchor, title: 'Account', entries: accountMenuEntries(ref, context, anchor));
