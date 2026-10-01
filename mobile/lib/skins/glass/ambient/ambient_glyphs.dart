import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';

/// Phosphor glyphs the ambient features need (codepoints from `brand/phosphor/codepoints.json`).
abstract final class AmbientGlyph {
  static const speakerSimpleSlash = Glyph(
    regular: IconData(0xe456, fontFamily: 'PhosphorRegular'),
    fill: IconData(0xe456, fontFamily: 'PhosphorFill'),
    bold: IconData(0xe456, fontFamily: 'PhosphorBold'),
    light: IconData(0xe456, fontFamily: 'PhosphorLight'),
  );
  static const squaresFour = Glyph(
    regular: IconData(0xe464, fontFamily: 'PhosphorRegular'),
    fill: IconData(0xe464, fontFamily: 'PhosphorFill'),
    bold: IconData(0xe464, fontFamily: 'PhosphorBold'),
    light: IconData(0xe464, fontFamily: 'PhosphorLight'),
  );
}
