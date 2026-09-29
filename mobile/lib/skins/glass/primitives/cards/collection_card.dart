import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/slab.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:motor/motor.dart';

/// The resting angles of a fan of [n] covers (degrees): -8, -3, 3, 8 for four.
List<double> fanRestAngles(int n) => switch (n) {
      0 => const [],
      1 => const [0],
      2 => const [-4, 4],
      3 => const [-6, 0, 6],
      _ => const [-8, -3, 3, 8],
    };

/// The Fan open angles (glass 4.10): -24, -8, 8, 24 for four; -16, 0, 16 for three; -8, 8 for two; 0 for one.
List<double> fanOpenAngles(int n) => switch (n) {
      0 => const [],
      1 => const [0],
      2 => const [-8, 8],
      3 => const [-16, 0, 16],
      _ => const [-24, -8, 8, 24],
    };

/// A collection (glass 7.7): a 21:9 slab with a fanned stack of up to four member covers on the left (each
/// 72 x 108, overlapping 40 %), the name in `title3` and "12 series" on the right. `fanOpen()` (the Fan open
/// move on `springCelebrate`) is exposed for `mobile/32` through a `GlobalKey<GlassCollectionCardState>`.
class GlassCollectionCard extends ConsumerStatefulWidget {
  const GlassCollectionCard({super.key, required this.name, required this.count, required this.covers, this.onTap, this.width = 320});
  final String name;
  final int count;
  final List<Widget> covers;
  final VoidCallback? onTap;
  final double width;

  @override
  ConsumerState<GlassCollectionCard> createState() => GlassCollectionCardState();
}

class GlassCollectionCardState extends ConsumerState<GlassCollectionCard> with SingleTickerProviderStateMixin {
  late final SingleMotionController _open = SingleMotionController(motion: SpringMotion(springOf(gt.springCelebrate)), vsync: this);

  @override
  void initState() {
    super.initState();
    _open.value = 0;
  }

  /// The Fan open move.
  Future<void> fanOpen() => GlassMotion.playMotor(MotionName.fanOpen, _open, 1);

  Future<void> fanClose() => GlassMotion.playMotor(MotionName.fanOpen, _open, 0);

  @override
  void dispose() {
    _open.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = math.min(4, widget.covers.length);
    final rest = fanRestAngles(n);
    final opened = fanOpenAngles(n);
    final h = widget.width * 9 / 21;
    return SizedBox(
      width: widget.width,
      height: h,
      child: GlassSlab(
        onTap: widget.onTap,
        semanticsLabel: '${widget.name}, ${widget.count} series',
        child: Row(
          children: [
            SizedBox(
              width: widget.width * 0.6,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: SizedBox(
              width: 72 + (n - 1) * 43.2 + 8,
              height: h - 24,
              child: AnimatedBuilder(
                animation: _open,
                builder: (context, _) => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (var i = 0; i < n; i++)
                      Positioned(
                        left: i * 43.2,
                        top: (h - 24 - 108) / 2,
                        width: 72,
                        height: 108,
                        child: Transform.rotate(
                          angle: (rest[i] + (opened[i] - rest[i]) * _open.value) * math.pi / 180,
                          child: ClipRRect(borderRadius: BorderRadius.circular(gt.radiusSm), child: widget.covers[i]),
                        ),
                      ),
                  ],
                ),
              ),
            ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GlassLabel(widget.name, role: gt.typeTitle3, maxLines: 2),
                  GlassLabel('${widget.count} series', role: gt.typeFootnote, color: gt.colorLabel2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
