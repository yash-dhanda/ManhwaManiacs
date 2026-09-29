import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/cine_grain.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/layout/cine_grid.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// A cover spread (cinematic 7.28, 8.0.9). Phones: the cover, then the text. Tablets: the text on
/// four columns and the art on four, bleeding off the right edge, with a `sigma` 56 copy of the art
/// filling its columns, `scrim.gutter` over the two columns where they meet, grain and Drift on the
/// art only.
class CineSpread extends StatelessWidget {
  const CineSpread({super.key, required this.text, required this.artBuilder, this.grain = true});
  final Widget text;

  /// Builds the art; called twice on tablets (the sharp cover and its blurred copy).
  final WidgetBuilder artBuilder;
  final bool grain;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final grid = CineGrid.of(context);
    if (MediaQuery.sizeOf(context).width < 600) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
        AspectRatio(aspectRatio: 2 / 3, child: artBuilder(context)),
        SizedBox(height: c.space4),
        text,
      ],);
    }
    final artLeft = grid.col(4);
    return LayoutBuilder(builder: (context, box) {
      final screenW = MediaQuery.sizeOf(context).width;
      final artW = screenW - artLeft; // bleeds off the right edge
      return SizedBox(
        height: artW * 1.2,
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned(
            left: artLeft - grid.left,
            top: 0,
            bottom: 0,
            width: artW,
            child: ClipRect(
              child: Stack(fit: StackFit.expand, children: [
                ImageFiltered(imageFilter: ui.ImageFilter.blur(sigmaX: c.blurBleed, sigmaY: c.blurBleed), child: artBuilder(context)),
                Center(
                  child: AspectRatio(
                    aspectRatio: 2 / 3,
                    child: CineDrift(child: grain ? CineGrain(opacity: 0.05, child: artBuilder(context)) : artBuilder(context)),
                  ),
                ),
                Positioned(left: 0, top: 0, bottom: 0, width: grid.span(2) + grid.gutter, child: DecoratedBox(decoration: BoxDecoration(gradient: c.scrimGutter))),
              ],),
            ),
          ),
          Positioned(left: 0, top: 0, bottom: 0, width: grid.span(4), child: text),
        ],),
      );
    },);
  }
}
