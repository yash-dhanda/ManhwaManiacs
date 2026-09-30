import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/cine_icon.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/cine_text.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

enum CineButtonKind { primary, secondary, quiet }

/// Square-cornered Cinematic button: `primary` (spot fill), `secondary`
/// (1 px outline) or `quiet` (text). Visual height 40 (32 when [small]); the
/// hit target is 44 (iOS) / 48 (Android).
class CineButton extends StatelessWidget {
  const CineButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.kind = CineButtonKind.primary,
    this.small = false,
    this.icon,
    this.loading = false,
    this.semanticsLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final CineButtonKind kind;
  final bool small;
  final CineIconRole? icon;
  final bool loading;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final (bg, fg, border) = switch (kind) {
      CineButtonKind.primary => (CineColors.spot, CineColors.paper0, null),
      CineButtonKind.secondary => (Colors.transparent, CineColors.ink100, CineColors.ink60),
      CineButtonKind.quiet => (Colors.transparent, CineColors.ink60, null),
    };
    final hit = minHit(context);
    final visual = small ? 32.0 : 40.0;
    final color = enabled ? fg : fg.withValues(alpha: 0.45);
    final child = Row(mainAxisSize: MainAxisSize.min, children: [
      if (icon != null) ...[CineIcon(icon!, size: 20, color: color), const SizedBox(width: 8)],
      CineText(label, context.cine.typeLabel, color: color, maxLines: 1, excludeSemantics: true),
      if (loading) ...[
        const SizedBox(width: 8),
        SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: color)),
      ],
    ],);
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticsLabel ?? label,
      excludeSemantics: true,
      onTap: enabled ? onPressed : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onPressed : null,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: hit, minWidth: hit),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: Container(
              height: visual,
              padding: EdgeInsets.symmetric(horizontal: small ? 12 : 20),
              decoration: BoxDecoration(color: enabled || kind != CineButtonKind.primary ? bg : CineColors.spot.withValues(alpha: 0.45), border: border == null ? null : Border.all(color: border)),
              alignment: Alignment.center,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// The `on-art` icon button (§7.2): a 40 px `color.onart` square, glyph 20
/// Regular; the hit target is 44 / 48.
class OnArtButton extends StatelessWidget {
  const OnArtButton({super.key, required this.role, required this.label, required this.onPressed});

  final CineIconRole role;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final hit = minHit(context);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onPressed,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: SizedBox(
          width: hit,
          height: hit,
          child: Center(child: Container(width: 40, height: 40, color: CineColors.onart, alignment: Alignment.center, child: CineIcon(role, size: 20, color: CineColors.ink100))),
        ),
      ),
    );
  }
}

/// The 44 / 48 tappable wrapper for any small visual.
class CineTap extends StatelessWidget {
  const CineTap({super.key, required this.onTap, required this.child, this.label, this.minWidth = true, this.onLongPress});

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget child;
  final String? label;
  final bool minWidth;

  @override
  Widget build(BuildContext context) {
    final hit = minHit(context);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: label != null,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: onLongPress,
        child: ConstrainedBox(constraints: BoxConstraints(minHeight: hit, minWidth: minWidth ? hit : 0), child: Center(widthFactor: minWidth ? null : 1, child: child)),
      ),
    );
  }
}
