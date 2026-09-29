import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_avatar.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_badge.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_confirm_dialog.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// The Index's profile block: a 44 px avatar, the name in Bodoni Italic, `@username` (and the
/// `ADMIN` credit), the mood, and `Switch profile` / `Profiles` / `Switch account…`.
class IndexProfileBlock extends ConsumerWidget {
  const IndexProfileBlock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.cine;
    final profile = ref.watch(activeProfileProvider);
    final auth = ref.watch(authControllerProvider);
    final user = auth is AuthAuthenticated ? auth.user : null;
    if (profile == null) return const SizedBox.shrink();
    Future<void> switchAccount() async {
      final ok = await showCineConfirm(
        context,
        title: 'Switch account?',
        body: "You'll be signed out on this device; saved chapters stay.",
        confirmLabel: 'Switch account',
        destructive: true,
      );
      if (ok) await ref.read(authControllerProvider.notifier).logout();
    }

    return Semantics(
      container: true,
      label: 'Reading as ${profile.name}',
      child: Column(
        key: const Key('index-profile'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CineAvatar(avatarKey: profile.avatarKey),
              SizedBox(width: c.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CineLit(profile.name, CineFace.bodoni, 20, 24, italic: true, wght: 600, color: c.colorInk100, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Row(
                      children: [
                        if (user != null) Flexible(child: CineRoleText('@${user.username}', c.typeCaption, color: c.colorInk60, maxLines: 1, overflow: TextOverflow.ellipsis)),
                        if (user?.isAdmin ?? false) ...[SizedBox(width: c.space2), const CineBadge('ADMIN', variant: CineBadgeVariant.admin)],
                      ],
                    ),
                    CineRoleText(profile.mood.label, c.typeCaption, color: c.colorInk60),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: c.space3),
          Wrap(
            spacing: c.space2,
            runSpacing: c.space2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              CineButton(
                label: 'Switch profile',
                variant: CineButtonVariant.secondary,
                size: CineButtonSize.sm,
                onPressed: () => unawaited(context.push<void>(Routes.profiles(), extra: const <String, String>{'mode': 'switch', 'transition': 'dip'})),
              ),
              CineButton(
                label: 'Profiles',
                variant: CineButtonVariant.quiet,
                size: CineButtonSize.sm,
                onPressed: () => unawaited(context.push<void>(Routes.profilesManage())),
              ),
              CineButton(label: 'Switch account…', variant: CineButtonVariant.quiet, size: CineButtonSize.sm, onPressed: () => unawaited(switchAccount())),
            ],
          ),
        ],
      ),
    );
  }
}
