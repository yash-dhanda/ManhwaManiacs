import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// `Continue │ CH 143` (with the 12 s auto-continue rule and folio), `Skip recaps for this series`
/// and `Close`. Usable from t = 0. [seconds] is null until the countdown starts.
class RecapActions extends StatelessWidget {
  const RecapActions({
    super.key,
    required this.chapterLabel,
    required this.onContinue,
    required this.onSkipSeries,
    required this.onClose,
    this.seconds,
    this.fraction = 1,
    this.wide = false,
    this.onPointer,
  });

  /// `CH 143`; empty when the chapter number is unknown.
  final String chapterLabel;
  final int? seconds;

  /// Remaining share of the countdown, 1 to 0, for the draining 2 px rule.
  final double fraction;
  final bool wide;
  final VoidCallback onContinue, onSkipSeries, onClose;
  final ValueChanged<bool>? onPointer;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final reduced = CineMotion.reduced(context);
    final folio = [if (chapterLabel.isNotEmpty) chapterLabel, if (seconds != null) '$seconds S'].join(' · ');
    Widget cont = CineButton(
      key: const Key('recap-continue'),
      label: 'Continue',
      variant: CineButtonVariant.split,
      size: wide ? CineButtonSize.lg : CineButtonSize.md,
      folio: folio.isEmpty ? null : folio,
      fullWidth: !wide,
      onPressed: () {
        cineFeedback(context, HapticEvent.tapPrimary, sound: SoundEvent.tapPrimary);
        onContinue();
      },
    );
    if (seconds != null && !reduced) {
      cont = Stack(children: [
        cont,
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 2,
          child: IgnorePointer(
            child: AnimatedFractionallySizedBox(
              key: const Key('recap-drain'),
              alignment: Alignment.centerLeft,
              widthFactor: fraction.clamp(0.0, 1.0),
              duration: const Duration(milliseconds: 100),
              child: ColoredBox(color: c.colorSpot),
            ),
          ),
        ),
      ],);
    }
    if (onPointer != null) cont = MouseRegion(onEnter: (_) => onPointer!(true), onExit: (_) => onPointer!(false), child: cont);
    final quiet = Wrap(spacing: c.space3, runSpacing: c.space1, crossAxisAlignment: WrapCrossAlignment.center, children: [
      CineButton(label: 'Skip recaps for this series', variant: CineButtonVariant.quiet, size: CineButtonSize.sm, onPressed: onSkipSeries),
      CineButton(label: 'Close', variant: CineButtonVariant.quiet, size: CineButtonSize.sm, onPressed: onClose),
    ],);
    return Column(
      crossAxisAlignment: wide ? CrossAxisAlignment.start : CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [cont, SizedBox(height: c.space2), quiet],
    );
  }
}
