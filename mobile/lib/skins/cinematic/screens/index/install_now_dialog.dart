import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_dialog.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/dialog_route.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

const List<(String, String)> kInstallSteps = [
  ('01', 'Open the downloaded APK from your notification shade or Downloads.'),
  ('02', 'Tap Install and confirm any prompt.'),
  ('03', 'Return here: the version updates and this banner clears on its own.'),
];

/// Shown after the APK download opens: three numbered steps and `Got it`.
Future<void> showInstallNowDialog(BuildContext context) => showCineDialog<void>(context, builder: (_) => const InstallNowDialog());

class InstallNowDialog extends StatelessWidget {
  const InstallNowDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return CineDialog(
      title: 'Install now',
      body: 'The new version is downloading to your device.',
      onCancel: () => Navigator.of(context).pop(),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (n, text) in kInstallSteps)
            Padding(
              padding: EdgeInsets.only(bottom: c.space3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 32, child: CineRoleText(n, c.typeFolio, color: c.colorInk60)),
                  Expanded(child: CineRoleText(text, c.typeUi)),
                ],
              ),
            ),
        ],
      ),
      actions: [CineButton(label: 'Got it', variant: CineButtonVariant.quiet, onPressed: () => Navigator.of(context).pop())],
    );
  }
}
