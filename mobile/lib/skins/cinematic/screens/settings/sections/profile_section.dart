import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_avatar.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_confirm_dialog.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_credits_row.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/settings_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// Profile & account (cinematic 8.30.2 row 1).
class ProfileSection extends ConsumerWidget {
  const ProfileSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.cine;
    final profile = ref.watch(activeProfileProvider);
    final auth = ref.watch(authControllerProvider);
    final user = auth is AuthAuthenticated ? auth.user : null;
    final admin = user?.isAdmin ?? false;

    Future<void> signOut() async {
      final ok = await showCineConfirm(
        context,
        title: 'Sign out on this device?',
        body: 'Saved chapters stay on this phone.',
        confirmLabel: 'Sign out',
        destructive: true,
      );
      if (ok) await ref.read(authControllerProvider.notifier).logout();
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (profile != null)
        Semantics(
          container: true,
          label: 'Reading as ${profile.name}',
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: c.space3),
            child: Row(children: [
              CineAvatar(avatarKey: profile.avatarKey, size: 56),
              SizedBox(width: c.space4),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  CineLit(profile.name, CineFace.bodoni, 20, 24, italic: true, wght: 600, color: c.colorInk100, maxLines: 1, overflow: TextOverflow.ellipsis),
                  CineRoleText(profile.mood.label, c.typeCaption, color: c.colorInk60),
                ],),
              ),
            ],),
          ),
        ),
      JumpRow(
        id: 'switch-profile',
        child: Wrap(spacing: c.space2, runSpacing: c.space2, children: [
          CineButton(
            label: 'Switch profile',
            variant: CineButtonVariant.secondary,
            size: CineButtonSize.sm,
            onPressed: () => unawaited(context.push<void>(Routes.profiles(), extra: const <String, String>{'mode': 'switch', 'transition': 'dip'})),
          ),
          JumpRow(
            id: 'manage-profiles',
            child: CineButton(label: 'Manage profiles', variant: CineButtonVariant.quiet, size: CineButtonSize.sm, onPressed: () => unawaited(context.push<void>(Routes.profilesManage()))),
          ),
        ],),
      ),
      SizedBox(height: c.space3),
      SettingsLinkRow(id: 'history', label: 'Reading history', onTap: () => context.go(Routes.history())),
      if (admin) SettingsLinkRow(id: 'status', label: 'System status', onTap: () => unawaited(context.push<void>(Routes.status()))),
      const SettingsKicker('THE ACCOUNT'),
      if (user != null) ...[
        CineCreditsRow(label: 'Display name', value: user.label),
        CineCreditsRow(label: 'Username', value: '@${user.username}'),
        if (admin) const CineCreditsRow(label: 'Role', value: 'ADMINISTRATOR'),
      ],
      SettingsLinkRow(id: 'security', label: 'Password & security', onTap: () => unawaited(context.push<void>(Routes.settings(SettingsSection.security)))),
      if (admin) SettingsLinkRow(id: 'members', label: 'Members', onTap: () => unawaited(context.push<void>(Routes.settings(SettingsSection.members)))),
      SizedBox(height: c.space4),
      JumpRow(id: 'sign-out', child: Align(alignment: Alignment.centerLeft, child: CineButton(label: 'Sign out', variant: CineButtonVariant.destructive, size: CineButtonSize.sm, onPressed: () => unawaited(signOut())))),
    ],);
  }
}

