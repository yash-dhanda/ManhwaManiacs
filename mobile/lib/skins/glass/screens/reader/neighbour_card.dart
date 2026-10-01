import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/features/reader/engine/neighbour.dart';
import 'package:manhwamaniacs/features/reader/models/reader_page.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/page_thumb.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

const double kNeighbourCardHeight = 232;

/// How much of the card shows for a displayed pull of [overscroll] px: nothing below the 48 px arm, all of it at the 72 px lock.
double neighbourCardReveal(double overscroll) {
  final a = overscroll.abs();
  if (a < armPx) return 0;
  return ((a - armPx) / (commitPx - armPx) * 0.6 + 0.4).clamp(0.0, 1.0);
}

/// The next-chapter card of one-at-a-time mode (glass 8.14.4): a `glassThick` partial sheet rising from the bottom (or falling from
/// the top for the previous chapter), its position driven every frame by the engine's displayed overscroll; the neighbour's first
/// page tilted 8 degrees in depth, "Chapter 144", "42 pages · about 6 min" and a tinted "Read next". [zoom] (0-1) carries it to
/// full screen once the reader lets go past the lock.
class NeighbourCard extends StatelessWidget {
  const NeighbourCard({
    super.key,
    required this.direction,
    required this.label,
    required this.info,
    required this.firstPage,
    required this.overscroll,
    required this.zoom,
    required this.onRead,
    this.tilt = 0,
    this.reduced = false,
    this.forceReveal,
  });

  final NeighbourDirection direction;
  final String label;
  final NeighbourInfo? info;
  final ReaderPage? firstPage;
  final ValueListenable<double> overscroll;
  final Animation<double> zoom;
  final VoidCallback onRead;

  /// Device tilt, -1 to 1 (+-4 degrees).
  final double tilt;
  final bool reduced;

  /// Captures: hold the card at this reveal.
  final double? forceReveal;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final next = direction == NeighbourDirection.next;
    return ValueListenableBuilder<double>(
      valueListenable: overscroll,
      builder: (context, o, _) => AnimatedBuilder(
        animation: zoom,
        builder: (context, _) {
          final z = zoom.value;
          var reveal = forceReveal ?? neighbourCardReveal(o);
          // Reduced motion: the card appears at the lock, nothing before it.
          if (reduced && forceReveal == null) reveal = o.abs() >= commitPx ? 1 : 0;
          if (reveal <= 0 && z <= 0) return const SizedBox.shrink();
          final w = math.min(size.width - 16, 480.0);
          const h = kNeighbourCardHeight;
          final cardW = w + (size.width - w) * z;
          final cardH = h + (size.height - h) * z;
          final travel = (1 - reveal) * (h + 24);
          final top = next ? size.height - cardH - 8 * (1 - z) + travel : 8 * (1 - z) - travel;
          final locked = o.abs() >= commitPx;
          final minutes = info?.minutes;
          return Stack(
            children: [
              Positioned(
                left: (size.width - cardW) / 2,
                top: top,
                width: cardW,
                height: cardH,
                child: SkinGlass(
                  size: Size(cardW, cardH),
                  tier: GlassTierId.t4,
                  shape: GlassShape.superellipse(gt.radiusXl * (1 - z)),
                  layer: GlassLayerKind.overlays,
                  debugLabel: 'reader next chapter card',
                  child: Opacity(
                    opacity: (1 - z * 1.5).clamp(0.0, 1.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 1 / 900)
                              ..rotateX((8 + 4 * tilt) * math.pi / 180),
                            child: SizedBox(width: 96, height: 144, child: ReaderPageThumb(page: firstPage)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GlassText(next ? (locked ? 'Let go to read' : 'Up next') : (locked ? 'Let go to go back' : 'Before this'), role: gt.typeCaption1, onGlass: true),
                                const SizedBox(height: 4),
                                GlassText(label, role: gt.typeTitle3, onGlass: true, maxLines: 2),
                                if (info != null) ...[
                                  const SizedBox(height: 4),
                                  GlassText('${info!.pageCount} pages · about ${minutes ?? 1} min', role: gt.typeFootnote, onGlass: true),
                                ],
                                const SizedBox(height: 12),
                                GlassButton(
                                  label: next ? 'Read next' : 'Read previous',
                                  onPressed: onRead,
                                  variant: GlassButtonVariant.primary,
                                  twin: GlassTwin.tinted,
                                  size: GlassButtonSize.small,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The sideways chapter swipe's title card (glass 8.14.4), a content twin sliding in from the side by `displayed` px.
class SwipeNeighbourCard extends StatelessWidget {
  const SwipeNeighbourCard({super.key, required this.displayed, required this.label, required this.fromRight});
  final double displayed;
  final String label;
  final bool fromRight;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    const w = 220.0;
    final x = fromRight ? size.width - displayed.abs() : displayed.abs() - w;
    return Positioned(
      left: x,
      top: size.height / 2 - 60,
      width: w,
      height: 120,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(color: gt.colorTwinDense, borderRadius: BorderRadius.circular(gt.radiusXl), border: Border.all(color: const Color(0x38FFFFFF), width: 0.5)),
          child: Center(child: GlassText(label, role: gt.typeHeadline, color: gt.colorLabel1)),
        ),
      ),
    );
  }
}
