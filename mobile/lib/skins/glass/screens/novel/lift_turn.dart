import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// glass 8.15.4 Lift: perspective 1600, the page rotates 0 -> -100 degrees around its spine.
const double kLiftPerspective = 1 / 1600;
const double kLiftMaxDeg = 100;

/// The specular band: 40 px of `Color(0x2EFFFFFF)` (white at 0.18) crossing the page with progress.
const double kLiftBandWidth = 40;
const Color kLiftBand = Color(0x2EFFFFFF);

/// The page beneath un-dims from 0.85 to 1; the back face is the paper at 92 %.
const double kLiftDimFrom = 0.85;
const double kLiftBackAlpha = 0.92;

/// The angle in radians at [progress] (0..1).
double liftAngle(double progress) => -kLiftMaxDeg * math.pi / 180 * progress.clamp(0.0, 1.0);

/// Past -90 degrees the page shows its back.
bool liftShowsBack(double progress) => kLiftMaxDeg * progress.clamp(0.0, 1.0) > 90;

/// A brightness scale matrix for the page beneath.
ColorFilter liftDim(double brightness) => ColorFilter.matrix([
      brightness, 0, 0, 0, 0,
      0, brightness, 0, 0, 0,
      0, 0, brightness, 0, 0,
      0, 0, 0, 1, 0,
    ]);

/// The turning copy (G5): pure transforms, no `toImage`, no shader. It is `IgnorePointer` + `ExcludeSemantics` +
/// `SelectionContainer.disabled`, so selection stays on the live page.
class LiftingPage extends StatelessWidget {
  const LiftingPage({super.key, required this.progress, required this.paper, required this.child});

  /// 0 flat, 1 fully lifted.
  final double progress;
  final Color paper;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);
    final back = liftShowsBack(p);
    return IgnorePointer(
      child: ExcludeSemantics(
        child: SelectionContainer.disabled(
          child: Transform(
            alignment: Alignment.centerLeft,
            transform: Matrix4.identity()
              ..setEntry(3, 2, kLiftPerspective)
              ..rotateY(liftAngle(p)),
            child: back
                ? ColoredBox(key: const ValueKey('lift-back'), color: paper.withValues(alpha: kLiftBackAlpha))
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(color: paper, child: child),
                      LayoutBuilder(
                        builder: (context, c) => Stack(children: [
                          Positioned(
                            left: (c.maxWidth + kLiftBandWidth) * (1 - p) - kLiftBandWidth,
                            top: 0,
                            bottom: 0,
                            width: kLiftBandWidth,
                            child: const DecoratedBox(
                              decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0x00FFFFFF), kLiftBand, Color(0x00FFFFFF)])),
                            ),
                          ),
                        ],),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
