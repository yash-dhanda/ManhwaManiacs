import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// `scrim.head` (cinematic 2.8.3): black at .88 flat over the bar's laid-out height, then the 13
/// eased stops reversed from .88 to 0 over [fade]. The caller paints it behind the bar's content
/// as `Positioned(top: 0, left: 0, right: 0, bottom: -fade)` in a `Stack(clipBehavior: Clip.none)`,
/// so the flat part follows the bar at every text scale. [tint] is the reader chrome's page tint.
Widget scrimHead(double bar, double fade, {Color? tint}) {
  final base = tint == null ? const Color(0xFF000000) : Color.lerp(const Color(0xFF000000), tint, 0.25)!;
  final total = bar + fade;
  final b = total <= 0 ? 0.0 : bar / total;
  final f = total <= 0 ? 1.0 : fade / total;
  const stops = CineScrim.kScrimStops;
  const alpha = CineScrim.kScrimAlpha;
  return IgnorePointer(
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0, b, for (var i = 12; i >= 0; i--) b + (1 - stops[i]) * f],
          colors: [
            base.withValues(alpha: 0.88),
            base.withValues(alpha: 0.88),
            for (var i = 12; i >= 0; i--) base.withValues(alpha: 0.88 * alpha[i]),
          ],
        ),
      ),
    ),
  );
}

/// The bar paints its scrim behind its content: a `Stack(clipBehavior: Clip.none)` with this first.
Widget scrimHeadLayer({required double fade, Color? tint}) => Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: -fade,
      child: LayoutBuilder(builder: (context, c) => scrimHead(c.maxHeight - fade, fade, tint: tint)),
    );
