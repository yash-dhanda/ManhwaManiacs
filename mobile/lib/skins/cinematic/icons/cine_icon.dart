import 'package:flutter/widgets.dart';

import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';

/// Cinematic icon (cinematic 2.7): Light at 24 and 32, Regular at 20 and 16,
/// Fill when selected; never Bold, Thin or Duotone. No hit area: the button owns it.
class CineIcon extends StatelessWidget {
  const CineIcon(
    this.role, {
    super.key,
    this.size = 24,
    this.weight,
    this.selected = false,
    this.color,
    this.semanticLabel,
  }) : assert(size == 16 || size == 20 || size == 24 || size == 32, 'size must be 16, 20, 24 or 32');

  final CineIconRole role;
  final double size;
  final CineIconWeight? weight;
  final bool selected;
  final Color? color;
  final String? semanticLabel;

  static CineIconWeight resolveWeight(double size, {CineIconWeight? weight, bool selected = false}) =>
      weight ?? (selected ? CineIconWeight.fill : size <= 20 ? CineIconWeight.regular : CineIconWeight.light);

  @override
  Widget build(BuildContext context) {
    final w = resolveWeight(size, weight: weight, selected: selected);
    final byWeight = cineIcons[role]!;
    final icon = Icon(byWeight[w] ?? byWeight[CineIconWeight.regular]!, size: size, color: color ?? IconTheme.of(context).color);
    return semanticLabel == null
        ? ExcludeSemantics(child: icon)
        : Semantics(label: semanticLabel, image: true, child: ExcludeSemantics(child: icon));
  }
}
