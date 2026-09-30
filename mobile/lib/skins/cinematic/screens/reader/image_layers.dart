import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// The `#000000` dimmer over the pages at alpha `|v| / 100`, under the chrome (cinematic 8.14.5).
class ReaderDimmer extends StatelessWidget {
  const ReaderDimmer({super.key, required this.brightness});

  /// -75..0.
  final int brightness;

  @override
  Widget build(BuildContext context) {
    if (brightness >= 0) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(child: ColoredBox(color: Color.fromRGBO(0, 0, 0, (-brightness / 100).clamp(0.0, 1.0)))),
    );
  }
}

/// The tint of the warmth layer: `color.warmth` at `v / 100 * 0.36`.
Color readerWarmthColor(BuildContext context, int warmthPct) => context.cine.colorWarmth.withValues(alpha: warmthPct / 100 * 0.36);

/// The warmth wrap of the page layer: `color.warmth` at `v / 100 * 0.36` multiplied over the pages
/// only, so blacks stay black.
Widget readerWarmth(BuildContext context, Widget pages, int warmthPct) {
  if (warmthPct <= 0) return pages;
  return ColorFiltered(
    colorFilter: ColorFilter.mode(readerWarmthColor(context, warmthPct), BlendMode.multiply),
    child: pages,
  );
}

/// The reader grounds (cinematic 2.1.6): Black, Ink and Slate.
Color readerGround(BuildContext context, String ground) => switch (ground) {
      'ink' => context.cine.colorPaper1,
      'slate' => context.cine.colorPaper3,
      _ => context.cine.colorPaper0,
    };
