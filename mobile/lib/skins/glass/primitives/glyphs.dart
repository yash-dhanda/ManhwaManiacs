import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart' show GlassIconWeight;

/// A Phosphor glyph the generated `phosphor.g.dart` does not carry (its list is limited to the semantic
/// icon roles). The codepoints come from `brand/phosphor/codepoints.json`; the six font files are all
/// bundled, so every weight resolves. Constants, so icon tree shaking still works.
class Glyph {
  const Glyph({required this.regular, required this.fill, required this.bold, required this.light});
  final IconData regular;
  final IconData fill;
  final IconData bold;
  final IconData light;

  IconData of(GlassIconWeight w) => switch (w) {
        GlassIconWeight.fill => fill,
        GlassIconWeight.bold => bold,
        GlassIconWeight.light => light,
        _ => regular,
      };
}

abstract final class GlassGlyph {
  static const warningCircle = Glyph(
    regular: IconData(0xe4e2, fontFamily: 'PhosphorRegular'),
    fill: IconData(0xe4e2, fontFamily: 'PhosphorFill'),
    bold: IconData(0xe4e2, fontFamily: 'PhosphorBold'),
    light: IconData(0xe4e2, fontFamily: 'PhosphorLight'),
  );
  static const warning = Glyph(
    regular: IconData(0xe4e0, fontFamily: 'PhosphorRegular'),
    fill: IconData(0xe4e0, fontFamily: 'PhosphorFill'),
    bold: IconData(0xe4e0, fontFamily: 'PhosphorBold'),
    light: IconData(0xe4e0, fontFamily: 'PhosphorLight'),
  );
  static const caretDown = Glyph(
    regular: IconData(0xe136, fontFamily: 'PhosphorRegular'),
    fill: IconData(0xe136, fontFamily: 'PhosphorFill'),
    bold: IconData(0xe136, fontFamily: 'PhosphorBold'),
    light: IconData(0xe136, fontFamily: 'PhosphorLight'),
  );
  static const caretRight = Glyph(
    regular: IconData(0xe13a, fontFamily: 'PhosphorRegular'),
    fill: IconData(0xe13a, fontFamily: 'PhosphorFill'),
    bold: IconData(0xe13a, fontFamily: 'PhosphorBold'),
    light: IconData(0xe13a, fontFamily: 'PhosphorLight'),
  );
  static const eye = Glyph(
    regular: IconData(0xe220, fontFamily: 'PhosphorRegular'),
    fill: IconData(0xe220, fontFamily: 'PhosphorFill'),
    bold: IconData(0xe220, fontFamily: 'PhosphorBold'),
    light: IconData(0xe220, fontFamily: 'PhosphorLight'),
  );
  static const eyeSlash = Glyph(
    regular: IconData(0xe224, fontFamily: 'PhosphorRegular'),
    fill: IconData(0xe224, fontFamily: 'PhosphorFill'),
    bold: IconData(0xe224, fontFamily: 'PhosphorBold'),
    light: IconData(0xe224, fontFamily: 'PhosphorLight'),
  );
  static const globe = Glyph(
    regular: IconData(0xe288, fontFamily: 'PhosphorRegular'),
    fill: IconData(0xe288, fontFamily: 'PhosphorFill'),
    bold: IconData(0xe288, fontFamily: 'PhosphorBold'),
    light: IconData(0xe288, fontFamily: 'PhosphorLight'),
  );
  static const imageBroken = Glyph(
    regular: IconData(0xe7a8, fontFamily: 'PhosphorRegular'),
    fill: IconData(0xe7a8, fontFamily: 'PhosphorFill'),
    bold: IconData(0xe7a8, fontFamily: 'PhosphorBold'),
    light: IconData(0xe7a8, fontFamily: 'PhosphorLight'),
  );
  static const trash = Glyph(
    regular: IconData(0xe4a6, fontFamily: 'PhosphorRegular'),
    fill: IconData(0xe4a6, fontFamily: 'PhosphorFill'),
    bold: IconData(0xe4a6, fontFamily: 'PhosphorBold'),
    light: IconData(0xe4a6, fontFamily: 'PhosphorLight'),
  );
  static const cloudArrowDown = Glyph(
    regular: IconData(0xe1ac, fontFamily: 'PhosphorRegular'),
    fill: IconData(0xe1ac, fontFamily: 'PhosphorFill'),
    bold: IconData(0xe1ac, fontFamily: 'PhosphorBold'),
    light: IconData(0xe1ac, fontFamily: 'PhosphorLight'),
  );
  static const check = Glyph(
    regular: IconData(0xe182, fontFamily: 'PhosphorRegular'),
    fill: IconData(0xe182, fontFamily: 'PhosphorFill'),
    bold: IconData(0xe182, fontFamily: 'PhosphorBold'),
    light: IconData(0xe182, fontFamily: 'PhosphorLight'),
  );
  static const checkCircle = Glyph(
    regular: IconData(0xe184, fontFamily: 'PhosphorRegular'),
    fill: IconData(0xe184, fontFamily: 'PhosphorFill'),
    bold: IconData(0xe184, fontFamily: 'PhosphorBold'),
    light: IconData(0xe184, fontFamily: 'PhosphorLight'),
  );
  static const x = Glyph(
    regular: IconData(0xe4f6, fontFamily: 'PhosphorRegular'),
    fill: IconData(0xe4f6, fontFamily: 'PhosphorFill'),
    bold: IconData(0xe4f6, fontFamily: 'PhosphorBold'),
    light: IconData(0xe4f6, fontFamily: 'PhosphorLight'),
  );
  static const magnifyingGlass = Glyph(
    regular: IconData(0xe30c, fontFamily: 'PhosphorRegular'),
    fill: IconData(0xe30c, fontFamily: 'PhosphorFill'),
    bold: IconData(0xe30c, fontFamily: 'PhosphorBold'),
    light: IconData(0xe30c, fontFamily: 'PhosphorLight'),
  );
  static const wifiSlash = Glyph(
    regular: IconData(0xe4f2, fontFamily: 'PhosphorRegular'),
    fill: IconData(0xe4f2, fontFamily: 'PhosphorFill'),
    bold: IconData(0xe4f2, fontFamily: 'PhosphorBold'),
    light: IconData(0xe4f2, fontFamily: 'PhosphorLight'),
  );
  static const sparkle = Glyph(
    regular: IconData(0xe6a2, fontFamily: 'PhosphorRegular'),
    fill: IconData(0xe6a2, fontFamily: 'PhosphorFill'),
    bold: IconData(0xe6a2, fontFamily: 'PhosphorBold'),
    light: IconData(0xe6a2, fontFamily: 'PhosphorLight'),
  );
  static const bellSimple = Glyph(
    regular: IconData(0xe0d0, fontFamily: 'PhosphorRegular'),
    fill: IconData(0xe0d0, fontFamily: 'PhosphorFill'),
    bold: IconData(0xe0d0, fontFamily: 'PhosphorBold'),
    light: IconData(0xe0d0, fontFamily: 'PhosphorLight'),
  );
  static const bellRinging = Glyph(
    regular: IconData(0xe5e8, fontFamily: 'PhosphorRegular'),
    fill: IconData(0xe5e8, fontFamily: 'PhosphorFill'),
    bold: IconData(0xe5e8, fontFamily: 'PhosphorBold'),
    light: IconData(0xe5e8, fontFamily: 'PhosphorLight'),
  );
  static const star = Glyph(
    regular: IconData(0xe46a, fontFamily: 'PhosphorRegular'),
    fill: IconData(0xe46a, fontFamily: 'PhosphorFill'),
    bold: IconData(0xe46a, fontFamily: 'PhosphorBold'),
    light: IconData(0xe46a, fontFamily: 'PhosphorLight'),
  );
  static const pushPin = Glyph(
    regular: IconData(0xe3e2, fontFamily: 'PhosphorRegular'),
    fill: IconData(0xe3e2, fontFamily: 'PhosphorFill'),
    bold: IconData(0xe3e2, fontFamily: 'PhosphorBold'),
    light: IconData(0xe3e2, fontFamily: 'PhosphorLight'),
  );
  static const bookmarkSimple = Glyph(
    regular: IconData(0xe0ea, fontFamily: 'PhosphorRegular'),
    fill: IconData(0xe0ea, fontFamily: 'PhosphorFill'),
    bold: IconData(0xe0ea, fontFamily: 'PhosphorBold'),
    light: IconData(0xe0ea, fontFamily: 'PhosphorLight'),
  );
  static const arrowClockwise = Glyph(
    regular: IconData(0xe036, fontFamily: 'PhosphorRegular'),
    fill: IconData(0xe036, fontFamily: 'PhosphorFill'),
    bold: IconData(0xe036, fontFamily: 'PhosphorBold'),
    light: IconData(0xe036, fontFamily: 'PhosphorLight'),
  );
  static const play = Glyph(
    regular: IconData(0xe3d0, fontFamily: 'PhosphorRegular'),
    fill: IconData(0xe3d0, fontFamily: 'PhosphorFill'),
    bold: IconData(0xe3d0, fontFamily: 'PhosphorBold'),
    light: IconData(0xe3d0, fontFamily: 'PhosphorLight'),
  );
  static const dotsThree = Glyph(
    regular: IconData(0xe1fe, fontFamily: 'PhosphorRegular'),
    fill: IconData(0xe1fe, fontFamily: 'PhosphorFill'),
    bold: IconData(0xe1fe, fontFamily: 'PhosphorBold'),
    light: IconData(0xe1fe, fontFamily: 'PhosphorLight'),
  );
  static const arrowSquareOut = Glyph(
    regular: IconData(0xe5de, fontFamily: 'PhosphorRegular'),
    fill: IconData(0xe5de, fontFamily: 'PhosphorFill'),
    bold: IconData(0xe5de, fontFamily: 'PhosphorBold'),
    light: IconData(0xe5de, fontFamily: 'PhosphorLight'),
  );
  static const heart = Glyph(
    regular: IconData(0xe2a8, fontFamily: 'PhosphorRegular'),
    fill: IconData(0xe2a8, fontFamily: 'PhosphorFill'),
    bold: IconData(0xe2a8, fontFamily: 'PhosphorBold'),
    light: IconData(0xe2a8, fontFamily: 'PhosphorLight'),
  );
  static const cat = Glyph(
    regular: IconData(0xe748, fontFamily: 'PhosphorRegular'),
    fill: IconData(0xe748, fontFamily: 'PhosphorFill'),
    bold: IconData(0xe748, fontFamily: 'PhosphorBold'),
    light: IconData(0xe748, fontFamily: 'PhosphorLight'),
  );
  static const ghost = Glyph(
    regular: IconData(0xe62a, fontFamily: 'PhosphorRegular'),
    fill: IconData(0xe62a, fontFamily: 'PhosphorFill'),
    bold: IconData(0xe62a, fontFamily: 'PhosphorBold'),
    light: IconData(0xe62a, fontFamily: 'PhosphorLight'),
  );
  static const rocketLaunch = Glyph(
    regular: IconData(0xe3fe, fontFamily: 'PhosphorRegular'),
    fill: IconData(0xe3fe, fontFamily: 'PhosphorFill'),
    bold: IconData(0xe3fe, fontFamily: 'PhosphorBold'),
    light: IconData(0xe3fe, fontFamily: 'PhosphorLight'),
  );
  static const coffee = Glyph(
    regular: IconData(0xe1c2, fontFamily: 'PhosphorRegular'),
    fill: IconData(0xe1c2, fontFamily: 'PhosphorFill'),
    bold: IconData(0xe1c2, fontFamily: 'PhosphorBold'),
    light: IconData(0xe1c2, fontFamily: 'PhosphorLight'),
  );
  static const sword = Glyph(
    regular: IconData(0xe5ba, fontFamily: 'PhosphorRegular'),
    fill: IconData(0xe5ba, fontFamily: 'PhosphorFill'),
    bold: IconData(0xe5ba, fontFamily: 'PhosphorBold'),
    light: IconData(0xe5ba, fontFamily: 'PhosphorLight'),
  );
  static const magicWand = Glyph(
    regular: IconData(0xe6b6, fontFamily: 'PhosphorRegular'),
    fill: IconData(0xe6b6, fontFamily: 'PhosphorFill'),
    bold: IconData(0xe6b6, fontFamily: 'PhosphorBold'),
    light: IconData(0xe6b6, fontFamily: 'PhosphorLight'),
  );
  static const moon = Glyph(
    regular: IconData(0xe330, fontFamily: 'PhosphorRegular'),
    fill: IconData(0xe330, fontFamily: 'PhosphorFill'),
    bold: IconData(0xe330, fontFamily: 'PhosphorBold'),
    light: IconData(0xe330, fontFamily: 'PhosphorLight'),
  );
  static const bookOpen = Glyph(
    regular: IconData(0xe0e6, fontFamily: 'PhosphorRegular'),
    fill: IconData(0xe0e6, fontFamily: 'PhosphorFill'),
    bold: IconData(0xe0e6, fontFamily: 'PhosphorBold'),
    light: IconData(0xe0e6, fontFamily: 'PhosphorLight'),
  );
  static const flame = Glyph(
    regular: IconData(0xe624, fontFamily: 'PhosphorRegular'),
    fill: IconData(0xe624, fontFamily: 'PhosphorFill'),
    bold: IconData(0xe624, fontFamily: 'PhosphorBold'),
    light: IconData(0xe624, fontFamily: 'PhosphorLight'),
  );
  static const arrowUp = Glyph(
    regular: IconData(0xe08e, fontFamily: 'PhosphorRegular'),
    fill: IconData(0xe08e, fontFamily: 'PhosphorFill'),
    bold: IconData(0xe08e, fontFamily: 'PhosphorBold'),
    light: IconData(0xe08e, fontFamily: 'PhosphorLight'),
  );
  static const user = Glyph(
    regular: IconData(0xe4c2, fontFamily: 'PhosphorRegular'),
    fill: IconData(0xe4c2, fontFamily: 'PhosphorFill'),
    bold: IconData(0xe4c2, fontFamily: 'PhosphorBold'),
    light: IconData(0xe4c2, fontFamily: 'PhosphorLight'),
  );
  static const image = Glyph(
    regular: IconData(0xe2ca, fontFamily: 'PhosphorRegular'),
    fill: IconData(0xe2ca, fontFamily: 'PhosphorFill'),
    bold: IconData(0xe2ca, fontFamily: 'PhosphorBold'),
    light: IconData(0xe2ca, fontFamily: 'PhosphorLight'),
  );
  static const plus = Glyph(
    regular: IconData(0xe3d4, fontFamily: 'PhosphorRegular'),
    fill: IconData(0xe3d4, fontFamily: 'PhosphorFill'),
    bold: IconData(0xe3d4, fontFamily: 'PhosphorBold'),
    light: IconData(0xe3d4, fontFamily: 'PhosphorLight'),
  );
  static const minus = Glyph(
    regular: IconData(0xe32a, fontFamily: 'PhosphorRegular'),
    fill: IconData(0xe32a, fontFamily: 'PhosphorFill'),
    bold: IconData(0xe32a, fontFamily: 'PhosphorBold'),
    light: IconData(0xe32a, fontFamily: 'PhosphorLight'),
  );
}

/// A [Glyph] as an icon. Icons carry no semantics of their own: the control that owns them labels them.
class GlyphIcon extends StatelessWidget {
  const GlyphIcon(this.glyph, {super.key, this.size = 22, this.color, this.weight = GlassIconWeight.regular});
  final Glyph glyph;
  final double size;
  final Color? color;
  final GlassIconWeight weight;

  @override
  Widget build(BuildContext context) =>
      ExcludeSemantics(child: Icon(glyph.of(size <= 16 && weight == GlassIconWeight.regular ? GlassIconWeight.bold : weight), size: size, color: color ?? IconTheme.of(context).color));
}
