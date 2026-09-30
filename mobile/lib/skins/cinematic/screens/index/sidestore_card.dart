import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/settings/models/app_version.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The iOS card Settings → About mounts (mobile/18): the build is managed by SideStore.
class SideStoreCard extends ConsumerWidget {
  const SideStoreCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.cine;
    final url = AppVersionInfo.sourceUrlFor(AppUpdateChannel.sideStore, ref.watch(apiBaseUrlProvider));
    return Container(
      key: const Key('sidestore-card'),
      padding: EdgeInsets.symmetric(vertical: c.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CineRoleText('MANAGED BY SIDESTORE', c.typeKicker, color: c.colorInk60),
          SizedBox(height: c.space2),
          CineRoleText(
            'This build is installed through SideStore. It updates when SideStore refreshes this source.',
            c.typeUi,
          ),
          SizedBox(height: c.space3),
          Semantics(
            container: true,
            excludeSemantics: true,
            label: url,
            child: SelectableText(url, key: const Key('sidestore-url'), style: CineText.style(context, c.typeFolio).copyWith(color: c.colorInk80)),
          ),
          SizedBox(height: c.space2),
          CineButton(
            label: 'Copy source URL',
            variant: CineButtonVariant.quiet,
            onPressed: () {
              unawaited(Clipboard.setData(ClipboardData(text: url)));
              ref.read(cineToastsProvider.notifier).info('Source URL copied');
            },
          ),
          SizedBox(height: c.space2),
          CineRoleText(
            'SideStore re-signs the app every 7 days. Open SideStore once a week so it keeps launching.',
            c.typeCaption,
            color: c.colorInk60,
          ),
        ],
      ),
    );
  }
}
