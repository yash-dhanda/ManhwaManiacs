// ignore_for_file: non_const_argument_for_const_parameter
import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';

/// Phosphor codepoints the primitives need that no icon role names (brand/phosphor/codepoints.json).
/// The bundled fonts are the full Phosphor set, so these resolve without a generated constant.
abstract final class CineGlyph {
  static const check = 0xe182;
  static const checkSquare = 0xe186;
  static const star = 0xe46a;
  static const x = 0xe4f6;
  static const arrowRight = 0xe06c;
  static const magnifyingGlass = 0xe30c;
  static const cloudArrowDown = 0xe1ac;
  static const imageBroken = 0xe7a8;
  static const dotsSixVertical = 0xeae2;
  static const filmSlate = 0xe8c2;
  static const newspaper = 0xe344;
  static const heart = 0xe2a8;
  static const flashlight = 0xe246;
  static const penNib = 0xe3ac;
  static const fire = 0xe242;
  static const sword = 0xe5ba;
  static const ghost = 0xe62a;
  static const magicWand = 0xe6b6;
  static const moonStars = 0xe58e;
  static const bookOpenText = 0xe8f2;
  static const play = 0xe3d0;
  static const pause = 0xe39e;
  static const bellRinging = 0xe5e8;
  static const plus = 0xe3d4;
  static const minus = 0xe32a;
  static const caretDown = 0xe136;
  static const caretUp = 0xe13c;
  static const caretRight = 0xe13a;
  static const headphones = 0xe2a6;
  static const dotsThree = 0xe1fe;
  static const thumbsUp = 0xe48e;
  static const sparkle = 0xe6a2;
  static const arrowLineUp = 0xe066;
  static const arrowLineDown = 0xe05c;

  // Custom-font glyphs are not tree-shaken, so a non-const codepoint is fine.
  static IconData data(int cp, CineIconWeight w) => IconData(
        cp,
        fontFamily: switch (w) { CineIconWeight.light => 'PhosphorLight', CineIconWeight.regular => 'PhosphorRegular', CineIconWeight.fill => 'PhosphorFill' },
      );
}

/// A Phosphor glyph by codepoint, at 12/16/20/24/28/32 px; decorative unless [semanticLabel] is set.
class CineGlyphIcon extends StatelessWidget {
  const CineGlyphIcon(this.codepoint, {super.key, this.size = 20, this.weight, this.color, this.semanticLabel});
  final int codepoint;
  final double size;
  final CineIconWeight? weight;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final w = weight ?? (size <= 20 ? CineIconWeight.regular : CineIconWeight.light);
    final icon = Icon(CineGlyph.data(codepoint, w), size: size, color: color);
    return semanticLabel == null ? ExcludeSemantics(child: icon) : Semantics(label: semanticLabel, image: true, child: ExcludeSemantics(child: icon));
  }
}
