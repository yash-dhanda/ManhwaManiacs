import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/settings/models/app_version.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/index/install_now_dialog.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:url_launcher/url_launcher.dart';

/// How the update URL opens: outside the app. An override point for tests.
final updateLauncherProvider = Provider<Future<bool> Function(Uri)>(
  (ref) => (u) => launchUrl(u, mode: LaunchMode.externalApplication),
  name: 'updateLauncher',
);

/// Opens the APK download outside the app; a failure is a toast naming the URL. Then the steps.
Future<void> downloadUpdate(BuildContext context, WidgetRef ref, AppVersionInfo info, {Future<bool> Function(Uri)? launch}) async {
  final Future<bool> Function(Uri) open = launch ?? ref.read(updateLauncherProvider);
  var ok = false;
  try {
    ok = await open(Uri.parse(info.downloadUrl));
  } catch (_) {
    ok = false;
  }
  if (!ok) {
    ref.read(cineToastsProvider.notifier).error("Couldn't open ${info.downloadUrl}");
    return;
  }
  if (context.mounted) await showInstallNowDialog(context);
}

/// The Android APK update banner (cinematic 8.28): `paper.0` with a 2 px `spot` left rule.
class UpdateBanner extends ConsumerWidget {
  const UpdateBanner({super.key, required this.info, this.buttonFocus, this.launch});
  final AppVersionInfo info;
  final FocusNode? buttonFocus;

  /// Test hook for the launcher.
  final Future<bool> Function(Uri)? launch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.cine;
    return Semantics(
      container: true,
      label: 'Update available, ${info.remoteVersion} build ${info.remoteBuild}. Installed ${info.localVersion} build ${info.localBuild}.',
      child: Container(
        key: const Key('update-banner'),
        decoration: BoxDecoration(color: c.colorPaper0, border: Border(left: BorderSide(color: c.colorSpot, width: 2), bottom: c.ruleHair)),
        padding: EdgeInsets.all(c.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CineRoleText('UPDATE AVAILABLE · ${info.remoteVersion} (${info.remoteBuild})', c.typeKicker, color: c.colorSpot),
            SizedBox(height: c.space1),
            CineRoleText('INSTALLED ${info.localVersion} (${info.localBuild})', c.typeCreditLabel, color: c.colorInk60),
            SizedBox(height: c.space3),
            CineButton(
              label: 'Download update',
              size: CineButtonSize.sm,
              focusNode: buttonFocus,
              onPressed: () => unawaited(downloadUpdate(context, ref, info, launch: launch)),
            ),
            SizedBox(height: c.space3),
            CineRoleText("Downloading doesn't install it automatically.", c.typeCaption, color: c.colorInk60),
            CineRoleText('Updating from 1.2.x? Uninstall the old app first.', c.typeCaption, color: c.colorInk60),
          ],
        ),
      ),
    );
  }
}
