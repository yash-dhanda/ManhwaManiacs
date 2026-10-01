/// The player's three tiles (glass 8.16.2, E9): 72 px `fill2` twin tiles. Speed ("1.25×", opens the speed dial), Voices (the
/// narrator's orb and "Cast of 6", opens the cast sheet), Sleep ("Off" or the live countdown, opens the sleep menu).
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/novels/controllers/narration_controller.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_cast_provider.dart';
import 'package:manhwamaniacs/features/novels/utils/sleep_timer.dart';
import 'package:manhwamaniacs/skins/glass/glass/shape.dart';
import 'package:manhwamaniacs/skins/glass/listen/glass_narration_host.dart';
import 'package:manhwamaniacs/skins/glass/listen/listen_common.dart';
import 'package:manhwamaniacs/skins/glass/listen/sleep_menu.dart';
import 'package:manhwamaniacs/skins/glass/listen/speed_dial_tile.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

class GlassPlayerTiles extends ConsumerWidget {
  const GlassPlayerTiles({super.key});

  Rect _rect(BuildContext c) {
    final box = c.findRenderObject();
    return box is RenderBox && box.hasSize ? box.localToGlobal(Offset.zero) & box.size : Rect.zero;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(narrationControllerProvider);
    final t = s.target;
    if (t == null) return const SizedBox(height: 72);
    final narr = ref.read(narrationControllerProvider.notifier);
    final narrator = ref.watch(glassNarratorProvider(t.key));
    final cast = ref.watch(novelAttributionProvider(t.key)).valueOrNull?.cast.length ?? 0;
    return SizedBox(
      height: 72,
      child: Row(
        children: [
          Expanded(
            child: _Tile(
              label: 'Speed',
              semantics: 'Speed, ${speedLabel(s.speed)}',
              onTap: (c) => showGlassSpeedDial(context, anchor: _rect(c)),
              child: GlassText(speedLabel(s.speed), role: gt.typeMonoLarge, onGlass: true, maxLines: 1, maxScale: 1.3),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _Tile(
              label: 'Voices',
              semantics: 'Voices, cast of $cast',
              onTap: (_) => ref.read(glassNarrationActionsProvider).openSheet('cast'),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ListenVoiceOrb(hue: narrator.hue, initial: narrator.initial, size: 24),
                  const SizedBox(width: 6),
                  Flexible(child: GlassText('Cast of $cast', role: gt.typeCaption1, wght: 600, onGlass: true, maxLines: 1, maxScale: 1.3, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _Tile(
              label: 'Sleep',
              semantics: 'Sleep timer',
              onTap: (c) => showGlassSleepMenu(context, anchor: _rect(c)),
              child: ValueListenableBuilder<SleepState>(
                valueListenable: narr.sleepState,
                builder: (context, st, _) => GlassText(st.countdown ?? (st.choice.kind == SleepKind.off ? 'Off' : st.choice.label), role: gt.typeMonoLarge, size: st.countdown == null && st.choice.kind != SleepKind.off ? 13 : null, onGlass: true, maxLines: 1, maxScale: 1.3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.semantics, required this.onTap, required this.child});
  final String label, semantics;
  final void Function(BuildContext) onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Builder(
        builder: (c) => GlassPressable(
          material: GlassMaterial.content,
          shape: const GlassShape.superellipse(20),
          minHit: false,
          onTap: () => onTap(c),
          semanticsLabel: semantics,
          builder: (context, info) => DecoratedBox(
            decoration: ShapeDecoration(color: gt.colorFill2, shape: const GlassShape.superellipse(20).border(const Size(110, 72))),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GlassText(label, role: gt.typeCaption2, onGlass: true, color: gt.colorLabel2, maxLines: 1, maxScale: 1.3),
                  const SizedBox(height: 4),
                  child,
                ],
              ),
            ),
          ),
        ),
      );
}
