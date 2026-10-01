import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/app/switch_skin.dart';
import 'package:manhwamaniacs/features/downloads/providers/active_download_queue_provider.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/profiles/providers/skin_outbox.dart';
import 'package:manhwamaniacs/skins/cinematic/overlays/stop_the_press.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/edition/confirm_switch.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/edition/edition_card.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/edition/next_issue_plate.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/skin.dart';

const String kEditionSubhead = 'Two versions of the same app.';
const String kEditionCaption = "Switching restarts the app. You'll come back to this page. Your edition follows this profile to every device.";
const String kEditionOffline = "Saves when you're back online.";

/// The edition picker (cinematic 8.30.3): the Cinematic card (this edition) and, beside or under
/// it, Glass: the disabled `NEXT ISSUE` plate while [glassAvailable] is false, else its card with
/// `Switch to Glass`.
class EditionPicker extends ConsumerWidget {
  const EditionPicker({super.key, required this.glassAvailable});

  final bool glassAvailable;

  Future<void> _switch(BuildContext context, WidgetRef ref) async {
    final queued = ref.read(activeDownloadCountProvider) > 0;
    final ok = await confirmEditionSwitch(context, downloadsQueued: queued);
    if (!ok || !context.mounted) return;
    await switchSkinFrom(context, ref, to: SkinId.glass, outgoing: () => StopThePress.outgoing(context));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.cine;
    final profileId = ref.watch(activeProfileProvider.select((p) => p?.id));
    final pending = profileId != null && ref.watch(skinOutboxProvider).pendingFor(profileId) != null;
    final cinematic = EditionCard(
      skinFolder: 'cinematic',
      name: 'Cinematic',
      family: SkinId.cinematic.displayFamily,
      description: 'Cinematic: black stock, film titles, a magazine\'s rhythm.',
      current: true,
    );
    final Widget glass = glassAvailable
        ? EditionCard(
            skinFolder: 'glass',
            name: 'Glass',
            family: SkinId.glass.displayFamily,
            description: 'Glass: layered glass, springs and depth.',
            switchLabel: 'Switch to Glass',
            missing: 'Preview frames arrive with the Glass build.',
            onSwitch: () => unawaited(_switch(context, ref)),
          )
        : const NextIssuePlate();
    return LayoutBuilder(
      builder: (context, box) {
        final wide = MediaQuery.sizeOf(context).width >= 600;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          CineRoleText('EDITION', c.typeKicker, color: c.colorInk60),
          SizedBox(height: c.space1),
          CineRoleText(kEditionSubhead, c.typeSubhead),
          SizedBox(height: c.space4),
          if (wide)
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: cinematic),
              SizedBox(width: c.space4),
              Expanded(child: glass),
            ],)
          else ...[cinematic, SizedBox(height: c.space6), glass],
          if (glassAvailable) ...[
            SizedBox(height: c.space3),
            CineRoleText(kEditionCaption, c.typeCaption, color: c.colorInk60),
            if (pending) CineRoleText(kEditionOffline, c.typeCaption, color: c.colorSpot),
          ],
        ],);
      },
    );
  }
}
