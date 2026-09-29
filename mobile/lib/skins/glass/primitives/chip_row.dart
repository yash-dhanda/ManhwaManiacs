import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';

/// A scrolling row of chips (glass 7.5): horizontal, `BouncingScrollPhysics` (momentum, rubber band at both
/// ends), the trailing 24 px masked by a gradient to hint at more, never snapping, 8 px of vertical
/// padding so focus rings are never clipped. Removals close the gap on `springSnappy`.
class GlassChipRow extends StatelessWidget {
  const GlassChipRow({super.key, required this.children, this.gap = 8, this.controller, this.padding});
  final List<Widget> children;
  final double gap;
  final ScrollController? controller;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final margin = GlassFrame.screenMargin(context);
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
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) => LinearGradient(
        colors: const [Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0x00FFFFFF)],
        stops: [0, rect.width <= 24 ? 0.0 : (rect.width - 24) / rect.width, 1],
      ).createShader(rect),
      child: SingleChildScrollView(
        controller: controller,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: pad,
        clipBehavior: Clip.none,
        child: row,
      ),
    );
  }
}
