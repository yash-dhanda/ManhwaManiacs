import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/glass/shape.dart';
import 'package:manhwamaniacs/skins/glass/primitives/badge.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart'
    show GlassButtonIcon;
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';

/// An icon control that lives inside a bar group's glass (no layer of its own): a 44 px circle hit area with the Regular glyph, the
/// Fill glyph while pressed. The group draws the glass (glass 2.4.1: a bar group is one layer, one shape per member).
class GlassBarIcon extends StatelessWidget {
  const GlassBarIcon(
      {super.key,
      required this.icon,
      required this.label,
      required this.onPressed,
      this.onLongPress,
      this.badge,
      this.toggled,
      this.iconBuilder,});
  final GlassButtonIcon icon;
  final String label;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final int? badge;
  final bool? toggled;

  /// Replaces the glyph (the Home bell swings on a new count); the press state is the builder's business.
  final WidgetBuilder? iconBuilder;

  @override
  Widget build(BuildContext context) {
    final hit = GlassFrame.hitMin(context);
    final side = hit < 44 ? 44.0 : hit;
    return SizedBox(
      width: side,
      height: side,
      child: GlassPressable(
        material: GlassMaterial.content,
        sink: 0.92,
        shape: const GlassShape.circle(),
        minHit: false,
        onTap: onPressed,
        onLongPress: onLongPress,
        enabled: onPressed != null,
        semanticsLabel:
            badge != null && badge! > 0 ? '$label, $badge new' : label,
        toggled: toggled,
        tooltip: label,
        builder: (context, info) => GlassBadged(
          badge: badge != null && badge! > 0 ? GlassBadge.count(badge!) : null,
          child: Center(
              child: iconBuilder?.call(context) ?? Icon(
                  info.states.pressed || (toggled ?? false)
                      ? icon.fill
                      : icon.regular,
                  size: 22,
                  color: gt.colorOnGlass,),),
        ),
      ),
    );
  }
}
