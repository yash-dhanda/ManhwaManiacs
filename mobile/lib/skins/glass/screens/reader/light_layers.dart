import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';

/// The reader's light layers (glass 8.14.1), above the pages and below the chrome, never hit-testable: a black layer at
/// `(1 - brightness) x 0.9` (0.72 at 20 %) and the `readerWarmth` `#FF8A00` layer at `warmth x 0.36` multiplied in.
class ReaderLightLayers extends StatelessWidget {
  const ReaderLightLayers({super.key, required this.brightness, required this.warmth, required this.child});
  final double brightness;
  final double warmth;
  final Widget child;

  static double dimAlpha(double brightness) => (1 - brightness.clamp(0.2, 1.0)) * 0.9;
  static double warmthAlpha(double warmth) => warmth.clamp(0.0, 1.0) * 0.36;

  @override
  Widget build(BuildContext context) {
    final dim = dimAlpha(brightness);
    final warm = warmthAlpha(warmth);
    // The structure never changes with the values, so the page list below keeps its state.
    return Stack(
      fit: StackFit.passthrough,
      children: [
        ColorFiltered(colorFilter: ColorFilter.mode(gt.colorReaderWarmth.withValues(alpha: warm), BlendMode.multiply), child: child),
        Positioned.fill(child: IgnorePointer(child: ColoredBox(key: const ValueKey('reader-dim'), color: Color.fromRGBO(0, 0, 0, dim)))),
      ],
    );
  }
}
