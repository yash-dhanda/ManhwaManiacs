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
/// The row always scrolls edge to edge of the screen: wherever it sits (a page gutter, a card, a sheet) it measures how far its box
/// is from the screen's sides and bleeds out over that distance, its first chip staying where it was, so a chip that does not fit
/// runs under the trailing fade at the screen edge instead of being cut mid-word at a gutter.
class GlassChipRow extends StatefulWidget {
  const GlassChipRow({super.key, required this.children, this.gap = 8, this.controller, this.padding});
  final List<Widget> children;
  final double gap;
  final ScrollController? controller;
  final EdgeInsets? padding;

  @override
  State<GlassChipRow> createState() => _GlassChipRowState();
}

class _GlassChipRowState extends State<GlassChipRow> {
  double _left = 0, _right = 0;

  /// Measures the box's distance to the screen sides after layout; rebuilds only when it changed.
  void _measure(Duration _) {
    if (!mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return;
    final x = box.localToGlobal(Offset.zero).dx;
    final w = MediaQuery.sizeOf(context).width;
    final l = x.clamp(0.0, w), r = (w - x - box.size.width).clamp(0.0, w);
    if ((l - _left).abs() > 0.5 || (r - _right).abs() > 0.5) {
      setState(() {
        _left = l;
        _right = r;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback(_measure);
    final margin = GlassFrame.contentMargin(context);
    final pad = widget.padding ?? EdgeInsets.symmetric(horizontal: margin, vertical: 8);
    final row = AnimatedSize(
      duration: Duration(milliseconds: gt.springSnappy.ms),
      curve: Curves.easeOutCubic,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < widget.children.length; i++) ...[
            if (i > 0) SizedBox(width: widget.gap),
            widget.children[i],
          ],
        ],
      ),
    );
    final scroller = glassTrailingFade(
      SingleChildScrollView(
        controller: widget.controller,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: pad + EdgeInsets.only(left: _left, right: _right),
        child: row,
      ),
    );
    if (_left == 0 && _right == 0) return scroller;
    return LayoutBuilder(
      builder: (context, c) => !c.hasBoundedWidth
          ? scroller
          : Transform.translate(
              offset: Offset((_right - _left) / 2, 0),
              child: OverflowBox(minWidth: c.maxWidth + _left + _right, maxWidth: c.maxWidth + _left + _right, fit: OverflowBoxFit.deferToChild, child: scroller),
            ),
    );
  }
}
