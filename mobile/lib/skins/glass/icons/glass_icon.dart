import 'package:flutter/widgets.dart';

import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart';

/// Glass icon (glass 2.7): Regular 22 by default, Duotone when selected at
/// rest, Fill on press, Bold at 16 and below, Light at 48 and above.
/// No hit area: the control owns it.
class GlassIcon extends StatelessWidget {
  const GlassIcon(
    this.role, {
    super.key,
    this.size = 22,
    this.weight,
    this.selected = false,
    this.pressed = false,
    this.color,
    this.semanticLabel,
  });

  final GlassIconRole role;
  final double size;
  final GlassIconWeight? weight;
  final bool selected;
  final bool pressed;
  final Color? color;
  final String? semanticLabel;

  static GlassIconWeight resolveWeight(double size, {GlassIconWeight? weight, bool selected = false, bool pressed = false}) =>
      weight ??
      (pressed
          ? GlassIconWeight.fill
          : selected
              ? GlassIconWeight.duotone
              : size <= 16
                  ? GlassIconWeight.bold
                  : size >= 48
                      ? GlassIconWeight.light
                      : GlassIconWeight.regular);

  @override
  Widget build(BuildContext context) {
    final w = resolveWeight(size, weight: weight, selected: selected, pressed: pressed);
    final c = color ?? IconTheme.of(context).color;
    final byWeight = glassIcons[role]!;
    final Widget icon = w == GlassIconWeight.duotone
        ? PhosphorDuotoneIcon(byWeight[w] ?? byWeight[GlassIconWeight.regular]!, glassDuotoneSecondary[role], size: size, color: c)
        : Icon(byWeight[w] ?? byWeight[GlassIconWeight.regular]!, size: size, color: c);
    return semanticLabel == null
        ? ExcludeSemantics(child: icon)
        : Semantics(label: semanticLabel, image: true, child: ExcludeSemantics(child: icon));
  }
}

/// Two constants stacked: the secondary layer at opacity 0.20 under the primary.
class PhosphorDuotoneIcon extends StatelessWidget {
  const PhosphorDuotoneIcon(this.primary, this.secondary, {super.key, required this.size, this.color});

  final IconData primary;
  final IconData? secondary;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => Stack(
        alignment: Alignment.center,
        children: [
          if (secondary != null) Opacity(opacity: 0.20, child: Icon(secondary, size: size, color: color)),
          Icon(primary, size: size, color: color),
        ],
      );
}
