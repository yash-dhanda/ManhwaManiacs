import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// "Mira · voiced by Ada", or "Mira" with no assigned voice (D10).
String runChipText(String speaker, String? voice) => voice == null || voice.isEmpty ? speaker : '$speaker · voiced by $voice';

/// How long the run chip stays (D10).
const Duration kRunChipHold = Duration(seconds: 2);

/// The run chip: `glassThin` (T2), materialises 8 px above the run, holds 2 s, dematerialises. It is the chip line of the L budget.
class GlassRunChip extends StatefulWidget {
  const GlassRunChip({super.key, required this.text, required this.anchor, required this.onGone, required this.lb, this.tint});
  final String text;

  /// The run's first box, in the reader's coordinates.
  final Rect anchor;
  final VoidCallback onGone;
  final double lb;
  final Color? tint;

  @override
  State<GlassRunChip> createState() => _GlassRunChipState();
}

class _GlassRunChipState extends State<GlassRunChip> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  Timer? _hold;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this);
    unawaited(GlassMotion.play(MotionName.materialise, controller: _c, target: 1));
    _hold = Timer(kRunChipHold, () async {
      await GlassMotion.play(MotionName.dematerialise, controller: _c, target: 0);
      if (mounted) widget.onGone();
    });
  }

  @override
  void dispose() {
    _hold?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = roleStyle(context, gt.typeFootnote, onGlass: true, wght: 600, maxScale: 1.3);
    final w = measureText(context, widget.text, style).width + 24;
    final size = MediaQuery.sizeOf(context);
    final left = (widget.anchor.left).clamp(8.0, size.width - w - 8);
    final top = widget.anchor.top - 8 - 32;
    return Positioned(
      left: left,
      top: top,
      width: w,
      height: 32,
      child: FadeTransition(
        opacity: _c,
        child: Semantics(
          liveRegion: true,
          label: widget.text,
          child: SkinGlass(
            tier: GlassTierId.t2,
            lb: widget.lb,
            layer: GlassLayerKind.hud,
            debugLabel: 'novel run chip',
            child: GlassHost(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.tint != null) DecoratedBox(decoration: BoxDecoration(color: widget.tint, borderRadius: BorderRadius.circular(16))),
                  Center(child: GlassText(widget.text, role: gt.typeFootnote, wght: 600, onGlass: true, maxScale: 1.3, maxLines: 1)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
