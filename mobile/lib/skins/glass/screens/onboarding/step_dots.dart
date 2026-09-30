import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/spring_value.dart';

/// The droplet dots at the top of onboarding (glass 8.7): 8 px dots 8 px apart, completed `g800`, upcoming `g500`, the current one a
/// 24 by 8 `iris400` capsule sliding on `springTab`. One semantics node: "Step 3 of 7". [merge] (0 to 1) slides them together for the
/// Dots merge.
class StepDots extends StatelessWidget {
  const StepDots({super.key, required this.index, required this.total, this.merge = 0});

  /// One-based position of the current step among the shown steps.
  final int index;
  final int total;
  final double merge;

  static const double dot = 8;
  static const double gap = 8;
  static const double capsule = 24;

  /// The row's width: the dots and the wider capsule.
  static double widthFor(int total) => total * dot + (total - 1) * gap + (capsule - dot);

  /// The left edge of dot [i] (zero-based) when the capsule sits at [current] (zero-based, may be fractional while sliding).
  static double leftOf(int i, double current) {
    final base = i * (dot + gap);
    final shift = (capsule - dot) * ((i - current).clamp(0.0, 1.0));
    return base + shift;
  }

  @override
  Widget build(BuildContext context) {
    final w = widthFor(total);
    return Semantics(
      label: 'Step $index of $total',
      child: ExcludeSemantics(
        child: SizedBox(
          width: w,
          height: dot,
          child: SpringValue(
            value: (index - 1).toDouble(),
            spring: gt.springTab,
            builder: (context, cur, _) => Stack(
              clipBehavior: Clip.none,
              children: [
                for (var i = 0; i < total; i++)
                  Positioned(
                    left: (leftOf(i, cur) * (1 - merge) + (w / 2 - dot / 2) * merge),
                    child: DecoratedBox(
                      decoration: BoxDecoration(shape: BoxShape.circle, color: i < index - 1 ? GlassColors.g800 : GlassColors.g500),
                      child: const SizedBox.square(dimension: dot),
                    ),
                  ),
                Positioned(
                  left: cur * (dot + gap) * (1 - merge) + (w / 2 - dot / 2) * merge,
                  child: Opacity(
                    opacity: 1 - merge,
                    child: DecoratedBox(
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: gt.colorIris400),
                      child: const SizedBox(width: capsule, height: dot),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
