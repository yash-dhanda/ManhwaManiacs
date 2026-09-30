import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/settings/providers/app_update_provider.dart';
import 'package:manhwamaniacs/skins/glass/primitives/alert.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';
import 'package:url_launcher/url_launcher.dart';

/// The install-steps alert (glass 8.29): three numbered steps after "Download update".
Future<void> showInstallStepsAlert(BuildContext context) => showGlassAlert<void>(
      context,
      title: 'Install the update',
      extra: const _InstallSteps(),
      actions: const [GlassAlertAction<void>('Got it')],
    );

class _InstallSteps extends StatelessWidget {
  const _InstallSteps();

  static const steps = [
    'Open the downloaded file from your notifications or the Downloads app.',
    'Allow installs from this source if Android asks, then tap Install.',
    'Come back here. This notice clears once the new version is running.',
  ];

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 24, height: 24, alignment: Alignment.center, decoration: BoxDecoration(color: gt.colorFill3, shape: BoxShape.circle), child: GlassText('${i + 1}', role: gt.typeFootnote, wght: 700, onGlass: true)),
                  const SizedBox(width: 12),
                  Expanded(child: GlassText(steps[i], role: gt.typeCallout, onGlass: true)),
                ],
              ),
            ),
        ],
      );
}

/// The body of the `?sheet=app-update` sheet (a `medium` sheet): installed and available versions, "Download update" and the notes.
class GlassAppUpdateBody extends ConsumerWidget {
  const GlassAppUpdateBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(appUpdateProvider).valueOrNull;
    if (info == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _line('Installed', info.localVersion),
          _line('Available', info.remoteVersion),
          const SizedBox(height: 16),
          GlassButton(
            label: 'Download update',
            variant: GlassButtonVariant.primary,
            onPressed: () async {
              await launchUrl(Uri.parse(info.downloadUrl), mode: LaunchMode.externalApplication);
              if (context.mounted) unawaited(showInstallStepsAlert(context));
            },
          ),
          const SizedBox(height: 16),
          GlassText("Downloading doesn't install automatically.", role: gt.typeFootnote, color: gt.colorLabel2),
          const SizedBox(height: 4),
          GlassText('Updating from 1.2.x? Uninstall version 1.2 first.', role: gt.typeFootnote, color: gt.colorLabel2),
        ],
      ),
    );
  }

  Widget _line(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [Expanded(child: GlassText(k, role: gt.typeBody)), GlassText(v, role: gt.typeBody, wght: 600)]),
      );
}
