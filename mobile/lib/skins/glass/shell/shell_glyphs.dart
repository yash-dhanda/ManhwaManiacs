import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';

/// Glyphs the shell needs beyond the shared set (codepoints from `brand/phosphor/codepoints.json`).
abstract final class ShellGlyph {
  static const keyboard = Glyph(
    regular: IconData(0xe2d8, fontFamily: 'PhosphorRegular'),
    fill: IconData(0xe2d8, fontFamily: 'PhosphorFill'),
    bold: IconData(0xe2d8, fontFamily: 'PhosphorBold'),
    light: IconData(0xe2d8, fontFamily: 'PhosphorLight'),
  );
  static const arrowBendDownLeft = Glyph(
    regular: IconData(0xe018, fontFamily: 'PhosphorRegular'),
    fill: IconData(0xe018, fontFamily: 'PhosphorFill'),
    bold: IconData(0xe018, fontFamily: 'PhosphorBold'),
    light: IconData(0xe018, fontFamily: 'PhosphorLight'),
  );
}
