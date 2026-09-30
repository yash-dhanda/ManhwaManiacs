import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/glass/ambient_field.dart' show moodColour;
import 'package:manhwamaniacs/skins/glass/primitives/alert.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/profile_orb.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/settings_row.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_common.dart' show avatarPresetFor;
import 'package:manhwamaniacs/skins/glass/type.dart';

/// The Account block of the root and the Account section: the orb, the display name, "@username" and the Admin tag.
class AccountHeader extends ConsumerWidget {
  const AccountHeader({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth is AuthAuthenticated ? auth.user : null;
    final profile = ref.watch(activeProfileProvider);
    final name = profile?.name ?? user?.label ?? 'Account';
    return Semantics(
      button: onTap != null,
      label: 'Account, $name${user == null ? '' : ', @${user.username}'}${user?.isAdmin ?? false ? ', Admin' : ''}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              if (profile != null) GlassProfileOrb(preset: avatarPresetFor(profile.avatarKey), mood: moodColour(profile.mood)) else const SizedBox(width: 44, height: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  GlassText(name, role: gt.typeHeadline, maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (user != null) GlassText('@${user.username}', role: gt.typeFootnote, color: gt.colorLabel2),
                ],),
              ),
              if (user?.isAdmin ?? false)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: gt.colorFill2, borderRadius: BorderRadius.circular(10)),
                  child: GlassText('Admin', role: gt.typeCaption1, wght: 600),
                ),
            ],),
          ),
        ),
      ),
    );
  }
}

/// Settings -> Account (glass 8.25.14).
class AccountSection extends ConsumerWidget {
  const AccountSection({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final ok = await showGlassAlert<bool>(
      context,
      title: 'Sign out?',
      body: "You'll need to sign in again on this device.",
      actions: const [
        GlassAlertAction<bool>('Cancel', role: GlassAlertRole.cancel, value: false),
        GlassAlertAction<bool>('Sign out', role: GlassAlertRole.destructive, value: true),
      ],
    );
    if (ok ?? false) await ref.read(authControllerProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(children: [
        SettingsGroup(children: [
          const SettingsAnchor(id: 'account', child: AccountHeader()),
          SettingsRow(id: 'change-password', title: 'Password and security', caret: true, onTap: () => GoRouter.of(context).go('/settings/security')),
          SettingsRow(id: 'profiles', title: 'Profiles', caret: true, onTap: () => GoRouter.of(context).go(Routes.profilesManage())),
          SettingsRow(id: 'sign-out', title: 'Sign out', onTap: () => unawaited(_signOut(context, ref))),
        ],),
      ],);
}
