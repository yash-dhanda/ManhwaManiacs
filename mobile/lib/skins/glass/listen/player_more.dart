/// The player's ⋯ (glass 8.16.2, E3): a `fill2` twin circle 32 (44 hit) before the close button: Save audio (phones with a downloads
/// scope) and Soundscape (rendered only when the `?sheet=` registry has `soundscape`, which `mobile/44` registers).
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/novels/controllers/narration_controller.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/glass/shape.dart';
import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/glass/icons/phosphor.g.dart';
import 'package:manhwamaniacs/skins/glass/listen/glass_narration_host.dart';
import 'package:manhwamaniacs/skins/glass/listen/listen_common.dart';
import 'package:manhwamaniacs/skins/glass/listen/save_audio.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/routes/sheet_registry.dart';

class GlassPlayerMore extends ConsumerWidget {
  const GlassPlayerMore({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => SizedBox(
        width: 44,
        height: 44,
        child: Builder(
          builder: (c) => GlassPressable(
            material: GlassMaterial.content,
            sink: 0.92,
            shape: const GlassShape.circle(),
            minHit: false,
            semanticsLabel: 'More',
            onTap: () {
              final t = ref.read(narrationControllerProvider).target;
              final box = c.findRenderObject();
              final anchor = box is RenderBox && box.hasSize ? box.localToGlobal(Offset.zero) & box.size : Rect.zero;
              final phone = GlassFrame.of(context) == GlassFrameKind.phone;
              unawaited(
                showGlassMenu(
                  context,
                  anchor: anchor,
                  title: 'Player options',
                  entries: [
                    if (t != null && phone && saveAudioAvailable(ref)) saveAudioEntry(context, ref, t),
                    if (glassSheetRegistered('soundscape')) GlassMenuEntry(label: 'Soundscape', icon: listenIcon(GlassIconRole.soundscape, GlassIconWeight.regular), onSelected: () => ref.read(glassNarrationActionsProvider).openSheet('soundscape')),
                    if (t == null || !(phone && saveAudioAvailable(ref)) && !glassSheetRegistered('soundscape')) const GlassMenuEntry(label: 'Nothing else here', icon: PhosphorRegular.dotsThree, enabled: false),
                  ],
                ),
              );
            },
            builder: (context, info) => Center(
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(shape: BoxShape.circle, color: gt.colorFill2),
                child: Icon(PhosphorRegular.dotsThree, size: 20, color: gt.colorOnGlass),
              ),
            ),
          ),
        ),
      );
}
