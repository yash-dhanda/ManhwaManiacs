/// The player's transport (glass 8.16.2, E8): back 15 s, previous sentence, play/pause (72 px, `iris600` at 86 % with a white 0.30 rim),
/// next sentence, forward 15 s.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/novels/controllers/narration_controller.dart';
import 'package:manhwamaniacs/skins/glass/glass/shape.dart';
import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/glass/icons/phosphor.g.dart';
import 'package:manhwamaniacs/skins/glass/listen/glass_narration_host.dart';
import 'package:manhwamaniacs/skins/glass/listen/listen_common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/primitives/progress.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

class GlassTransport extends ConsumerWidget {
  const GlassTransport({super.key, this.disabledReason});

  /// "Needs a connection or saved audio" while offline with no saved audio.
  final String? disabledReason;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(narrationControllerProvider);
    final n = ref.read(narrationControllerProvider.notifier);
    final actions = ref.read(glassNarrationActionsProvider);
    final phase = listenPhaseOf(s);
    final off = disabledReason != null;
    Widget side(String label, Widget glyph, VoidCallback onTap) => _TransportButton(label: label, onTap: off ? null : onTap, child: glyph);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        side('Back 15 seconds', const _Seek15(back: true), () => unawaited(n.seekBy(const Duration(seconds: -15)))),
        side('Previous sentence', Icon(PhosphorFill.skipBack, size: 24, color: gt.colorOnGlass), () => unawaited(n.stepSentence(-1))),
        _PlayLarge(phase: phase, disabledReason: disabledReason, onTap: () => phase == ListenPhase.failed ? unawaited(n.retry()) : unawaited(actions.toggle())),
        side('Next sentence', Icon(PhosphorFill.skipForward, size: 24, color: gt.colorOnGlass), () => unawaited(n.stepSentence(1))),
        side('Forward 15 seconds', const _Seek15(back: false), () => unawaited(n.seekBy(const Duration(seconds: 15)))),
      ],
    );
  }
}

class _Seek15 extends StatelessWidget {
  const _Seek15({required this.back});
  final bool back;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 28,
        height: 28,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform(alignment: Alignment.center, transform: Matrix4.diagonal3Values(back ? -1 : 1, 1, 1), child: Icon(PhosphorRegular.arrowClockwise, size: 28, color: gt.colorOnGlass)),
            GlassText('15', role: gt.typeCaption2, wght: 700, size: 9, onGlass: true, maxLines: 1),
          ],
        ),
      );
}

class _TransportButton extends StatelessWidget {
  const _TransportButton({required this.label, required this.onTap, required this.child});
  final String label;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 48,
        height: 48,
        child: GlassPressable(
          material: GlassMaterial.content,
          sink: 0.92,
          shape: const GlassShape.circle(),
          minHit: false,
          enabled: onTap != null,
          onTap: onTap,
          semanticsLabel: label,
          builder: (context, info) => Center(child: Opacity(opacity: onTap == null ? 0.4 : 1, child: child)),
        ),
      );
}

class _PlayLarge extends StatelessWidget {
  const _PlayLarge({required this.phase, required this.onTap, this.disabledReason});
  final ListenPhase phase;
  final VoidCallback onTap;
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    final busy = phase == ListenPhase.preparing || phase == ListenPhase.buffering;
    final glyph = phase == ListenPhase.playing ? listenIcon(GlassIconRole.pause) : (phase == ListenPhase.failed ? PhosphorFill.arrowClockwise : listenIcon(GlassIconRole.play));
    return SizedBox(
      width: 72,
      height: 72,
      child: GlassPressable(
        material: GlassMaterial.content,
        sink: 0.94,
        shape: const GlassShape.circle(),
        minHit: false,
        enabled: disabledReason == null,
        onTap: onTap,
        semanticsLabel: listenPhaseLabel(phase),
        semanticsHint: disabledReason,
        disabledReason: disabledReason,
        builder: (context, info) => DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: gt.colorIris600.withValues(alpha: disabledReason == null ? 0.86 : 0.4),
            border: Border.all(color: phase == ListenPhase.failed ? gt.colorWarning : const Color(0x4DFFFFFF), width: phase == ListenPhase.failed ? 2 : 1),
          ),
          child: Center(child: busy ? GlassSpinner(size: 28, color: gt.colorOnGlass) : Icon(glyph, size: math.min(32, 72 * 0.44), color: gt.colorOnGlass)),
        ),
      ),
    );
  }
}
