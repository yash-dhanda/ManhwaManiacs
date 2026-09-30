import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/novels/controllers/narration_controller.dart';
import 'package:manhwamaniacs/features/novels/utils/narration_timing.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/speed_ruler.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/listen/listen_common.dart';
import 'package:manhwamaniacs/skins/cinematic/stock.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The speed ruler sheet (cinematic 8.16.4): 0.50-3.00x in 0.05 steps, the presets, hold to reset
/// to 1.00x, the WPM equivalent under the value. Pitch is preserved. Saved per profile.
Future<void> showSpeedSheet(BuildContext context, {CineStockColors? stock}) => showListenSheet<void>(
      context,
      kicker: 'SPEED',
      title: 'Listening speed',
      stock: stock,
      livePreview: true,
      builder: (_) => const SpeedSheetBody(),
    );

class SpeedSheetBody extends ConsumerStatefulWidget {
  const SpeedSheetBody({super.key});

  @override
  ConsumerState<SpeedSheetBody> createState() => _SpeedSheetBodyState();
}

class _SpeedSheetBodyState extends ConsumerState<SpeedSheetBody> {
  double? _preview;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final s = ref.watch(narrationControllerProvider);
    final words = s.target == null ? 0 : wordCountOf(s.target!.paragraphs);
    final total = s.target?.audio.totalMs ?? 0;
    final shown = _preview ?? s.speed;
    final wpm = narrationWpm(words, total, shown);
    return Padding(
      padding: EdgeInsets.fromLTRB(c.space4, c.space2, c.space4, c.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SpeedRuler(
            value: s.speed,
            onChanged: (v) => setState(() => _preview = v),
            onCommit: (v) {
              setState(() => _preview = null);
              unawaited(ref.read(narrationControllerProvider.notifier).setSpeed(v));
            },
            pxCaption: (x) => wpm == 0 ? '' : '≈ ${narrationWpm(words, total, x)} WPM',
          ),
          SizedBox(height: c.space2),
          CineRoleText('Pitch stays the same at every speed.', c.typeCaption, color: c.colorInk60),
        ],
      ),
    );
  }
}
