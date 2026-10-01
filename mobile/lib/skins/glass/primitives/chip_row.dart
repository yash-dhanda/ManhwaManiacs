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
/// The viewport is clipped to the row's box (so every visible chip can be tapped) and a chip that does not fit runs under the
/// trailing fade, never hard-cut mid-word; 24 px of trailing room lets the last chip clear the fade at the end of the scroll.
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
    return glassTrailingFade(
      SingleChildScrollView(
        controller: controller,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: pad.copyWith(right: pad.right < 24 ? 24 : pad.right),
        child: row,
      ),
    );
  }
}
