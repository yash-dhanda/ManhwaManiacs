import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_dialog.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/dialog_route.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/sheet_route.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The body of "Restart in Glass?": the restart line, the download line when a queue exists and
/// the icon line on Android while "App icon follows the skin" is on (release/01 Decision 1).
String restartInGlassBody({required bool downloadsQueued, required TargetPlatform platform, bool iconFollows = false}) => [
      'The app closes and reopens in the Glass edition, on this page.',
      if (downloadsQueued) 'Downloads resume after the restart.',
      if (platform == TargetPlatform.android && iconFollows) 'The app icon changes after you next close the app from Recents. Shortcuts on your home screen may need adding again.',
    ].join(' ');

/// The edition switch's confirmation: a sheet below 600 dp, a dialog from 600 dp. `Stay in
/// Cinematic` is the initial focus. Resolves `true` only for `Restart in Glass`.
Future<bool> confirmEditionSwitch(BuildContext context, {required bool downloadsQueued, bool iconFollows = false}) async {
  final body = restartInGlassBody(downloadsQueued: downloadsQueued, platform: Theme.of(context).platform, iconFollows: iconFollows);
  final wide = MediaQuery.sizeOf(context).width >= 600;
  final stay = FocusNode(debugLabel: 'stay-in-cinematic');
  Widget actions(BuildContext ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        CineButton(label: 'Restart in Glass', fullWidth: true, onPressed: () => Navigator.of(ctx).pop(true)),
        const SizedBox(height: 8),
        CineButton(label: 'Stay in Cinematic', variant: CineButtonVariant.quiet, fullWidth: true, focusNode: stay, onPressed: () => Navigator.of(ctx).pop(false)),
      ],);
  final Object? result;
  if (wide) {
    result = await showCineDialog<bool>(
      context,
      builder: (ctx) => CineDialog(
        title: 'Restart in Glass?',
        body: body,
        onCancel: () => Navigator.of(ctx).pop(false),
        actions: [
          CineButton(label: 'Restart in Glass', onPressed: () => Navigator.of(ctx).pop(true)),
          CineButton(label: 'Stay in Cinematic', variant: CineButtonVariant.quiet, focusNode: stay, onPressed: () => Navigator.of(ctx).pop(false)),
        ],
      ),
    );
  } else {
    result = await showCineSheet<bool>(
      context,
      kicker: 'EDITION',
      title: 'Restart in Glass?',
      builder: (ctx) => Padding(
        padding: EdgeInsets.symmetric(vertical: ctx.cine.space4), // the sheet body sets the gutter
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          CineRoleText(body, ctx.cine.typeBody),
          SizedBox(height: ctx.cine.space4),
          actions(ctx),
        ],),
      ),
    );
  }
  WidgetsBinding.instance.addPostFrameCallback((_) => stay.dispose());
  return result == true;
}
