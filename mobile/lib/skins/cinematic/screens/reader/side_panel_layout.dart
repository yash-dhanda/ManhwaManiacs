import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// The two column panels of the reader on tablets (cinematic 8.14.12): the left Contents panel,
/// 3 of the 8 columns (at least 320 px) on `paper.0` with a 1 px `rule.1` inner edge, slides in
/// over 320 ms `settle` and out over 224 ms `lift`; the right slot is `mobile/13`'s Margins panel.
/// Only one panel is open at a time, the one opened last. Reduced motion: a 150 ms fade in place.
/// The panels sit over the page and never push the strip.
class SidePanelLayout extends StatelessWidget {
  const SidePanelLayout({super.key, required this.leftOpen, required this.rightOpen, this.left, this.right, this.leftLabel = 'Contents', this.rightLabel = 'Margins'});

  final bool leftOpen, rightOpen;
  final Widget? left, right;
  final String leftLabel, rightLabel;

  /// 3 of 8 columns: margin 32, gutter 16 (cinematic 2.2.2), minimum 320.
  static double panelWidth(double screenWidth) {
    const margin = 32.0, gutter = 16.0;
    final column = (screenWidth - 2 * margin - 7 * gutter) / 8;
    final w = 3 * column + 2 * gutter;
    return w < 320 ? 320 : w;
  }

  @override
  Widget build(BuildContext context) {
    final width = panelWidth(MediaQuery.sizeOf(context).width);
    return Stack(
      children: [
        if (left != null) _Panel(open: leftOpen, width: width, fromLeft: true, label: leftLabel, child: left!),
        if (right != null) _Panel(open: rightOpen, width: width, fromLeft: false, label: rightLabel, child: right!),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.open, required this.width, required this.fromLeft, required this.label, required this.child});

  final bool open, fromLeft;
  final double width;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final reduced = CineMotion.reduced(context);
    final duration = reduced ? c.durReduced : (open ? c.durColumn : const Duration(milliseconds: 224));
    final curve = open ? CineCurves.settle : CineCurves.lift;
    final panel = Semantics(
      container: true,
      label: label,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: c.colorPaper0,
          border: Border(right: fromLeft ? BorderSide(color: c.colorRule1) : BorderSide.none, left: fromLeft ? BorderSide.none : BorderSide(color: c.colorRule1)),
        ),
        child: child,
      ),
    );
    if (reduced) {
      return Positioned(
        top: 0,
        bottom: 0,
        left: fromLeft ? 0 : null,
        right: fromLeft ? null : 0,
        child: IgnorePointer(
          ignoring: !open,
          child: AnimatedOpacity(opacity: open ? 1 : 0, duration: duration, child: Offstage(offstage: !open, child: panel)),
        ),
      );
    }
    return AnimatedPositioned(
      duration: duration,
      curve: curve,
      top: 0,
      bottom: 0,
      left: fromLeft ? (open ? 0 : -width) : null,
      right: fromLeft ? null : (open ? 0 : -width),
      width: width,
      child: ExcludeSemantics(excluding: !open, child: panel),
    );
  }
}
