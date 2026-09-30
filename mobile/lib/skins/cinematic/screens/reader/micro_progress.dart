import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_tint.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// A 2 px `spot` rule at the very bottom of the screen showing chapter progress while the chrome is
/// hidden (cinematic 8.14.3). Absent in cinema mode.
class ReaderMicroProgress extends StatelessWidget {
  const ReaderMicroProgress({super.key, required this.progress, this.rtl = false, this.visible = true});

  final double progress;
  final bool rtl, visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: 2,
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: Align(
            alignment: rtl ? Alignment.centerRight : Alignment.centerLeft,
            child: FractionallySizedBox(widthFactor: progress.clamp(0.0, 1.0), child: ColoredBox(color: ReaderTintScope.of(context).light ?? context.cine.colorSpot)),
          ),
        ),
      ),
    );
  }
}
