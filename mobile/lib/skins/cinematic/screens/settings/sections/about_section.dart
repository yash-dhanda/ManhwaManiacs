import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/settings/models/app_version.dart';
import 'package:manhwamaniacs/features/settings/providers/app_update_provider.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/overlays/whats_new_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_credits_row.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/index/app_update_card.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/index/sidestore_card.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/settings_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// About (cinematic 8.30.2 row 15).
class AboutSection extends ConsumerWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.cine;
    final info = ref.watch(packageInfoProvider);
    final remote = ref.watch(appUpdateProvider).valueOrNull;
    final apk = AppUpdateChannel.forPlatform(Theme.of(context).platform) == AppUpdateChannel.apk;
    final ios = Theme.of(context).platform == TargetPlatform.iOS;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      JumpRow(id: 'app-version', child: CineCreditsRow(label: 'APP VERSION', value: info.hasValue ? '${info.value!.version} (${info.value!.buildNumber})' : '–')),
      JumpRow(id: 'server-version', child: CineCreditsRow(label: 'SERVER', value: remote == null ? '–' : '${remote.remoteVersion} (${remote.remoteBuild})')),
      SettingsLinkRow(id: 'whats-new', label: "What's new", onTap: () => unawaited(showWhatsNewSheet(context, ref))),
      if (apk) const AppUpdateCard(),
      if (ios) Padding(padding: EdgeInsets.only(top: c.space4), child: const SideStoreCard()),
      SettingsLinkRow(id: 'licenses', label: 'Licenses', onTap: () => unawaited(context.push<void>('/settings/about?licenses=1'))),
    ],);
  }
}
