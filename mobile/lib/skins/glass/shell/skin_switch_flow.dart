import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/app/switch_skin.dart';
import 'package:manhwamaniacs/core/platform/app_icon_switcher.dart';
import 'package:manhwamaniacs/features/downloads/providers/active_download_queue_provider.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/primitives/alert.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart'
    show glassSound;
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/screens/onboarding/skin_preview_loop.dart';
import 'package:manhwamaniacs/skins/glass/shell/melt.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart';
import 'package:manhwamaniacs/skins/skin.dart';

/// The alert copy of glass 8.25.2, pure so the notes are a unit test.
({String title, String body, List<String> notes, String stay, String confirm})
    skinSwitchAlertCopy(
            {required bool downloadsQueued, required bool offline,}) =>
        (
          title: 'Restart in Cinematic?',
          body:
              "Everything about the app changes: layout, navigation, type and motion. Your library, progress and downloads stay exactly as they are, and you'll come back to this screen.",
          notes: [
            if (downloadsQueued)
              'Downloads pause for a moment and resume after the restart.',
            if (offline)
              "This profile will switch on your other devices once you're back online.",
          ],
          stay: 'Stay in Glass',
          confirm: 'Restart in Cinematic',
        );

/// Starts the skin switch from Glass (the palette's Skin action now; `mobile/39` adds the Settings cards on this function): the
/// alert blooms from [sourceRect]; confirming plays the melt while `switchSkin` mirrors the device, queues the PATCH and restarts.
Future<void> startSkinSwitch(BuildContext context, WidgetRef ref,
    {required Rect sourceRect,}) async {
  final copy = skinSwitchAlertCopy(
      downloadsQueued: ref.read(activeDownloadCountProvider) > 0,
      offline: ref.read(glassOfflineProvider),);
  final ok = await showGlassAlert<bool>(
    context,
    title: copy.title,
    body: copy.body,
    notes: copy.notes,
    sourceRect: sourceRect,
    // glass 8.25.2 step 1: the arriving skin's preview loop, small, at the top.
    leading: const SizedBox(
      width: double.infinity,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          child: SizedBox(width: 120, height: 260, child: ExcludeSemantics(child: GlassSkinPreviewLoop(skin: 'cinematic'))),
        ),
      ),
    ),
    actions: [
      GlassAlertAction<bool>(copy.stay,
          role: GlassAlertRole.cancel, value: false,),
      GlassAlertAction<bool>(copy.confirm, value: true),
    ],
  );
  if (ok != true || !context.mounted) return;
  await runSkinSwitch(context, ref, SkinId.cinematic);
}

/// The switch itself (no alert): the `skin.switch` haptic and cue, the melt, the icon rule of glass 12.2 inside the restart moment
/// (after the melt reaches black, before the restart; explicit choices only) and the restart. The arrival toast's Undo calls it too.
/// [undoable] false for the Undo itself, so the skin it returns to shows no arrival toast of its own.
Future<void> runSkinSwitch(BuildContext context, WidgetRef ref, SkinId target, {bool undoable = true}) async {
  unawaited(ref.read(glassHapticsProvider).fire(HapticEvent.skinSwitch));
  glassSound(ref, SoundEvent.skinSwitch);
  try {
    await switchSkinFrom(
      context,
      ref,
      to: target,
      undoable: undoable,
      outgoing: () async {
        await playMelt(ref);
        await ref.read(appIconSwitcherProvider).onExplicitSkinChoice(target);
      },
    );
  } catch (_) {
    await unmelt(ref);
    if (context.mounted) {
      showGlassToast(ref, const GlassToastSpec("Couldn't switch skins. Try again.", kind: GlassToastKind.error));
    }
  }
}
