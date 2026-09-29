import 'package:flutter/widgets.dart';

/// The material-aware type axes of glass 3.5: `ROND` follows the tier, `GRAD` follows the backdrop.
/// Outside any glass the lookup returns null and the role's own `ROND` and `GRAD 0` apply.
class GlassTextAxes extends InheritedWidget {
  const GlassTextAxes({super.key, required this.rond, required this.grad, required super.child});

  final double rond;
  final int grad;

  static GlassTextAxesData? of(BuildContext context) {
    final w = context.dependOnInheritedWidgetOfExactType<GlassTextAxes>();
    return w == null ? null : GlassTextAxesData(w.rond, w.grad);
  }

  @override
  bool updateShouldNotify(GlassTextAxes old) => old.rond != rond || old.grad != grad;
}

class GlassTextAxesData {
  const GlassTextAxesData(this.rond, this.grad);
  final double rond;
  final int grad;
}
