import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/buttons.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/cine_text.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// While a screen reader runs the story cannot rely on taps and swipes: the
/// three controls are drawn bottom-centre as `on-art` buttons (7.1: fill
/// `color.onart`, text `ink.100`).
class ScreenReaderControls extends StatelessWidget {
  const ScreenReaderControls({super.key, required this.onPrevious, required this.onPause, required this.onNext, required this.paused});

  final VoidCallback onPrevious;
  final VoidCallback onPause;
  final VoidCallback onNext;
  final bool paused;

  @override
  Widget build(BuildContext context) {
    Widget b(String label, VoidCallback f) => CineTap(
          label: label,
          minWidth: false,
          onTap: f,
          child: Container(height: 40, padding: const EdgeInsets.symmetric(horizontal: 12), color: CineColors.onart, alignment: Alignment.center, child: CineText(label, context.cine.typeLabel, excludeSemantics: true)),
        );
    return Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [b('Previous page', onPrevious), b(paused ? 'Play' : 'Pause', onPause), b('Next page', onNext)]);
  }
}
