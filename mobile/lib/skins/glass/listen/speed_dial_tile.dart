/// The speed dial from the player's Speed tile (glass 8.16.3, F0): `GlassSpeedDial` (mobile/27) blooms out of the tile as an anchored
/// picker above the player. The value previews while dragging and commits on release through `setSpeed` (pitch preserved by
/// `just_audio`, remembered in the shared `mm.listen-settings` `speed`); "about 190 wpm" comes from the chapter's word count.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/novels/controllers/narration_controller.dart';
import 'package:manhwamaniacs/features/novels/utils/narration_timing.dart';
import 'package:manhwamaniacs/skins/glass/listen/anchored_picker.dart';
import 'package:manhwamaniacs/skins/glass/primitives/speed_dial.dart';

/// "1.25×", "1×", "0.8×".
String speedLabel(double v) => '${v == v.roundToDouble() ? v.toStringAsFixed(0) : (v * 100 % 10 == 0 ? v.toStringAsFixed(1) : v.toStringAsFixed(2))}×';

Future<void> showGlassSpeedDial(BuildContext context, {required Rect anchor}) =>
    showListenPicker(context, anchor: anchor, label: 'Speed', builder: (context, close) => const GlassSpeedDialBody());

/// The dial bound to the narration's speed.
class GlassSpeedDialBody extends ConsumerStatefulWidget {
  const GlassSpeedDialBody({super.key});

  @override
  ConsumerState<GlassSpeedDialBody> createState() => _GlassSpeedDialBodyState();
}

class _GlassSpeedDialBodyState extends ConsumerState<GlassSpeedDialBody> {
  late double _preview = ref.read(narrationControllerProvider).speed;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(narrationControllerProvider);
    final t = s.target;
    final words = t == null ? 0 : wordCountOf(t.paragraphs);
    final total = t?.audio.totalMs ?? 0;
    return GlassSpeedDial(
      value: _preview,
      onChanged: (v) => setState(() => _preview = v),
      onCommit: (v) {
        setState(() => _preview = v);
        unawaited(ref.read(narrationControllerProvider.notifier).setSpeed(v));
      },
      wpmAt: (v) => narrationWpm(words, total, v),
      anchorOffset: const Offset(0, 140),
    );
  }
}
