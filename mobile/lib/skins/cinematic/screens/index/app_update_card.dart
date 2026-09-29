import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/settings/models/app_version.dart';
import 'package:manhwamaniacs/features/settings/providers/app_update_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/index/update_banner.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The Android APK update card Settings → About mounts (mobile/18): up to date, available,
/// unreachable or loading.
class AppUpdateCard extends ConsumerWidget {
  const AppUpdateCard({super.key, this.preview});

  /// Test and proof hook.
  final AsyncValue<AppVersionInfo?>? preview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.cine;
    final AsyncValue<AppVersionInfo?> async = preview ?? ref.watch(appUpdateProvider);
    return Container(
      key: const Key('app-update-card'),
      padding: EdgeInsets.symmetric(vertical: c.space3),
      child: async.when(
        loading: () => Container(key: const Key('update-greek'), width: 160, height: 20, color: c.colorPaper3),
        error: (_, __) => CineRoleText("Couldn't check for updates.", c.typeCaption, color: c.colorProof),
        data: (info) {
          if (info == null) return CineRoleText("Couldn't check for updates.", c.typeCaption, color: c.colorProof);
          if (!info.hasUpdate) {
            return CineRoleText('UP TO DATE — ${info.localVersion}', c.typeFolio, color: c.colorSet);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CineRoleText('${info.localVersion} → ${info.remoteVersion}', c.typeFolioLg),
              SizedBox(height: c.space2),
              CineButton(
                label: 'Download update',
                size: CineButtonSize.sm,
                onPressed: () => unawaited(downloadUpdate(context, ref, info)),
              ),
            ],
          );
        },
      ),
    );
  }
}
