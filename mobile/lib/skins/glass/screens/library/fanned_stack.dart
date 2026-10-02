import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/collection_card.dart' show fanOpenAngles, fanRestAngles;
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';

/// A fanned stack of up to four covers (glass 7.7, 8.18): resting at -8, -3, 3, 8 degrees, open at -24, -8, 8, 24 (Fan open), each cover
/// overlapping its neighbour by 40 %. [open] runs 0 to 1. Used as the header of a collection, larger than the card's stack.
class FannedStack extends StatelessWidget {
  const FannedStack({super.key, required this.covers, required this.open, this.coverWidth = 110});
  final List<Widget> covers;
  final Animation<double> open;
  final double coverWidth;

  @override
  Widget build(BuildContext context) {
    final n = math.min(4, covers.length);
    final rest = fanRestAngles(n);
    final opened = fanOpenAngles(n);
    final h = coverWidth * 1.5;
    final step = coverWidth * 0.6;
    // The outer covers lean up to 8 degrees: their corners reach this far past the box, so the box makes room for them and the fan
    // never touches the screen edge.
    final lean = h / 2 * math.sin(8 * math.pi / 180);
    // Reduce Motion (Fan open, 150 ms fade): the covers sit at their open angles and [open] fades them in instead of turning them.
    final reduced = GlassMotion.isReduced();
    return SizedBox(
      width: coverWidth + (n == 0 ? 0 : n - 1) * step + 2 * lean,
      height: h + 16,
      child: AnimatedBuilder(
        animation: open,
        builder: (context, _) => Opacity(opacity: reduced ? open.value.clamp(0.0, 1.0) : 1, child: Stack(clipBehavior: Clip.none, children: [
          for (var i = 0; i < n; i++)
            Positioned(
              left: lean + i * step,
              top: 8,
              width: coverWidth,
              height: h,
              child: Transform.rotate(
                angle: (reduced ? opened[i] : rest[i] + (opened[i] - rest[i]) * open.value) * math.pi / 180,
                child: ClipRRect(borderRadius: BorderRadius.circular(gt.radiusSm), child: covers[i]),
              ),
            ),
        ],),),
      ),
    );
  }
}
