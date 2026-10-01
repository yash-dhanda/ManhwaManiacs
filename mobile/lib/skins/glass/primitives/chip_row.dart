import 'dart:math' as math;

import 'package:flutter/rendering.dart' show OverflowBoxFit;
import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';

/// Masks the trailing 24 px of a horizontal scroller to transparent (the "more this way" hint of glass 7.5).
Widget glassTrailingFade(Widget child) => ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) => LinearGradient(
        colors: const [Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0x00FFFFFF)],
        stops: [0, rect.width <= 24 ? 0.0 : (rect.width - 24) / rect.width, 1],
      ).createShader(rect),
      child: child,
    );

/// A scrolling row of chips (glass 7.5): horizontal, `BouncingScrollPhysics` (momentum, rubber band at both
/// ends), the trailing 24 px masked by a gradient to hint at more, never snapping, 8 px of vertical
/// padding so focus rings are never clipped. Removals close the gap on `springSnappy`.
///
/// The row always scrolls edge to edge of the screen: inside content that already sits on the screen margin it bleeds out
/// over the margin (its first chip still on the gutter), so a chip that does not fit runs under the trailing fade at the
/// screen edge instead of being cut at the gutter.
class GlassChipRow extends StatelessWidget {
  const GlassChipRow({super.key, required this.children, this.gap = 8, this.controller, this.padding});
  final List<Widget> children;
  final double gap;
  final ScrollController? controller;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final margin = GlassFrame.contentMargin(context);
    final pad = padding ?? EdgeInsets.symmetric(horizontal: margin, vertical: 8);
    // ponytail: assumes a row with less than a screen margin of its own padding sits on the gutter (every caller does).
    final bleed = math.max(0.0, GlassFrame.screenMargin(context) - pad.left);
    final row = AnimatedSize(
      duration: Duration(milliseconds: gt.springSnappy.ms),
      curve: Curves.easeOutCubic,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(width: gap),
            children[i],
          ],
        ],
      ),
    );
    final scroller = glassTrailingFade(
      SingleChildScrollView(
        controller: controller,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: pad + EdgeInsets.symmetric(horizontal: bleed),
        child: row,
      ),
    );
    if (bleed == 0) return scroller;
    return LayoutBuilder(
      builder: (context, c) => c.hasBoundedWidth
          ? OverflowBox(minWidth: c.maxWidth + 2 * bleed, maxWidth: c.maxWidth + 2 * bleed, fit: OverflowBoxFit.deferToChild, child: scroller)
          : scroller,
    );
  }
}
