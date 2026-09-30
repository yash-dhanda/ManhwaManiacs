import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';

/// While a screen reader runs the story cannot rely on taps and swipes: the three controls are
/// drawn bottom-centre as `on-art` buttons (cinematic 7.1: fill `color.onart`, text `ink.100`).
class ScreenReaderControls extends StatelessWidget {
  const ScreenReaderControls(
      {super.key,
      required this.onPrevious,
      required this.onPause,
      required this.onNext,
      required this.paused,});

  final VoidCallback onPrevious;
  final VoidCallback onPause;
  final VoidCallback onNext;
  final bool paused;

  @override
  Widget build(BuildContext context) {
    Widget b(String label, VoidCallback f) => CineButton(
        label: label,
        variant: CineButtonVariant.onArt,
        size: CineButtonSize.sm,
        onPressed: f,);
    return Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          b('Previous page', onPrevious),
          b(paused ? 'Play' : 'Pause', onPause),
          b('Next page', onNext),
        ],);
  }
}
