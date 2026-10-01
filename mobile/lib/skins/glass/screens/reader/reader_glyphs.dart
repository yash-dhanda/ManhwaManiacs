import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';

/// The Phosphor glyphs the reader needs that the shared lists do not carry (codepoints from `brand/phosphor/codepoints.json`).
abstract final class ReaderGlyph {
  static const lock = Glyph(
    regular: IconData(0xe2fa, fontFamily: 'PhosphorRegular'),
    fill: IconData(0xe2fa, fontFamily: 'PhosphorFill'),
    bold: IconData(0xe2fa, fontFamily: 'PhosphorBold'),
    light: IconData(0xe2fa, fontFamily: 'PhosphorLight'),
  );
  static const sun = Glyph(
    regular: IconData(0xe472, fontFamily: 'PhosphorRegular'),
    fill: IconData(0xe472, fontFamily: 'PhosphorFill'),
    bold: IconData(0xe472, fontFamily: 'PhosphorBold'),
    light: IconData(0xe472, fontFamily: 'PhosphorLight'),
  );
  static const chatText = Glyph(
    regular: IconData(0xe17a, fontFamily: 'PhosphorRegular'),
    fill: IconData(0xe17a, fontFamily: 'PhosphorFill'),
    bold: IconData(0xe17a, fontFamily: 'PhosphorBold'),
    light: IconData(0xe17a, fontFamily: 'PhosphorLight'),
  );
  static const shareNetwork = Glyph(
    regular: IconData(0xe408, fontFamily: 'PhosphorRegular'),
    fill: IconData(0xe408, fontFamily: 'PhosphorFill'),
    bold: IconData(0xe408, fontFamily: 'PhosphorBold'),
    light: IconData(0xe408, fontFamily: 'PhosphorLight'),
  );
  static const list = Glyph(
    regular: IconData(0xe2f0, fontFamily: 'PhosphorRegular'),
    fill: IconData(0xe2f0, fontFamily: 'PhosphorFill'),
    bold: IconData(0xe2f0, fontFamily: 'PhosphorBold'),
    light: IconData(0xe2f0, fontFamily: 'PhosphorLight'),
  );
}
