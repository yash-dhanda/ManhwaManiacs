import 'dart:ui' show ImageFilter;

import 'package:flutter/widgets.dart';

/// The line guide (G9): two frosted bands (`BackdropFilter` blur 6 with the paper at 55 %) above and below the current line band (two
/// body lines tall). Drag the band or tap above or below it to move it one band. A scrim, not a `SkinGlass` layer.
class NovelLineGuide extends StatefulWidget {
  const NovelLineGuide({super.key, required this.lineHeightPx, required this.paper, this.initialTop});
  final double lineHeightPx;
  final Color paper;
  final double? initialTop;

  @override
  State<NovelLineGuide> createState() => _NovelLineGuideState();
}

/// The frost's blur and the paper's share of its fill.
const double kLineGuideBlur = 6, kLineGuideFill = 0.55;

class _NovelLineGuideState extends State<NovelLineGuide> {
  double? _top;

  double get _band => widget.lineHeightPx * 2;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final h = c.maxHeight;
        final top = (_top ??= widget.initialTop ?? h * 0.38 - _band / 2).clamp(0.0, h - _band);
        Widget frost() => ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: kLineGuideBlur, sigmaY: kLineGuideBlur),
                child: ColoredBox(color: widget.paper.withValues(alpha: kLineGuideFill)),
              ),
            );
        return Stack(
          key: const ValueKey('novel-line-guide'),
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: top,
              child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => setState(() => _top = top - _band), child: ExcludeSemantics(child: frost())),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: top,
              height: _band,
              child: Semantics(
                label: 'Line guide',
                hint: 'Drag to move',
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onVerticalDragUpdate: (d) => setState(() => _top = (top + d.delta.dy).clamp(0.0, h - _band)),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: top + _band,
              bottom: 0,
              child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => setState(() => _top = top + _band), child: ExcludeSemantics(child: frost())),
            ),
          ],
        );
      },);
}
