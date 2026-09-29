import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/avatar_presets.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_badge.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_tooltip.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

const List<double> kAvatarSizes = [20, 24, 28, 32, 44, 56, 96, 112, 144];

/// A profile avatar (cinematic 7.25): a circle with a field colour darkening to 60 % black at the
/// rim and a Phosphor Fill glyph at 45 % of the diameter. Selected: a 2 px `spot` ring at 3 px.
class CineAvatar extends StatelessWidget {
  const CineAvatar({
    super.key,
    required this.avatarKey,
    this.size = 44,
    this.selected = false,
    this.adult = false,
    this.onTap,
    this.semanticName,
  }) : assert(size >= 20, 'avatars start at 20 px');

  final String? avatarKey;
  final double size;
  final bool selected, adult;
  final VoidCallback? onTap;

  /// The preset's name ("Matinee") as the label, where the caller asks for it.
  final String? semanticName;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final p = avatarPreset(avatarKey);
    Widget disc = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [p.field, Color.lerp(p.field, const Color(0xFF000000), 0.6)!]),
      ),
      child: CineGlyphIcon(p.glyph, size: size * 0.45, weight: CineIconWeight.fill, color: c.colorInk100),
    );
    disc = Stack(clipBehavior: Clip.none, children: [
      disc,
      if (selected)
        Positioned(
          left: -5,
          top: -5,
          right: -5,
          bottom: -5,
          child: IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.colorSpot, width: 2)))),
        ),
      if (adult) Positioned(right: -4, bottom: -4, child: CineBadge.certificate(large: true, onArt: true)),
    ],);
    final label = semanticName ?? p.name;
    if (onTap == null) return Semantics(label: semanticName, image: true, excludeSemantics: true, child: disc);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: CinePressable(round: true, onTap: onTap, builder: (_, st) => AnimatedOpacity(opacity: st.pressed ? 0.8 : 1, duration: c.durTick, child: disc)),
    );
  }
}

/// The "reading now" ring: 2 px at 3 px offset in the series' `ambient.duo`, dissolving over
/// 800 ms on change and fading out over 800 ms when reading stops.
class CineReadingNowRing extends StatelessWidget {
  const CineReadingNowRing({super.key, required this.child, this.duo, this.tooltip});
  final Widget child;

  /// Null when the person is not reading.
  final Color? duo;

  /// e.g. "Reading Omniscient Reader · CH 212".
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final d = CineMotion.reduced(context) ? Duration.zero : c.durDissolve;
    final ring = TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: duo ?? const Color(0x00000000)),
      duration: d,
      curve: c.easeTurn,
      child: child,
      builder: (_, color, child) => Stack(clipBehavior: Clip.none, children: [
        Padding(padding: const EdgeInsets.all(5), child: child),
        Positioned.fill(child: IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color ?? const Color(0x00000000), width: 2))))),
      ],),
    );
    return tooltip == null || duo == null ? ring : CineTooltip(message: tooltip!, child: ring);
  }
}
