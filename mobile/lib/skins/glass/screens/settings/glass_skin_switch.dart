import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/shell/skin_switch_flow.dart';
import 'package:manhwamaniacs/skins/skin.dart';

/// The one entry point for an explicit skin switch from Glass (glass 8.25.2): the alert blooms from [origin] (the card), then the
/// switch runs (PATCH through the outbox, device keys, melt, icon rule, restart). Onboarding step 2, the profile form's skin row
/// and the Settings cards route through it. Only Cinematic is a target from Glass; choosing Glass does nothing here.
abstract final class GlassSkinSwitch {
  static Future<void> start(BuildContext context, WidgetRef ref, SkinId target, {Rect? origin}) async {
    if (target == SkinId.glass) return;
    await startSkinSwitch(context, ref, sourceRect: origin ?? Rect.fromLTWH(MediaQuery.sizeOf(context).width / 2, MediaQuery.sizeOf(context).height / 2, 1, 1));
  }
}
