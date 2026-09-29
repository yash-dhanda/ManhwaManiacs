import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/core/color/oklch.dart';

/// One painted stand-in for a demo cover: its three palette colours (the 24 covers of
/// `brand/demo/demo.json`), drawn as a dark-to-light gradient with `CustomPaint`. Two of them are
/// white-dominant. `lMax` is computed from the colours and the painted white share, so the
/// legibility dim has real values to follow.
class CalibrationCover {
  const CalibrationCover(this.title, this.palette, {this.whiteDominant = false});

  final String title;
  final List<Color> palette;
  final bool whiteDominant;

  /// The brightest thing on the cover: pure white where the cover is white-dominant, else the
  /// brightest palette colour's relative luminance.
  double get lMax {
    if (whiteDominant) return 1.0;
    return palette.map(relativeLuminance).reduce((a, b) => a > b ? a : b);
  }

  /// The mean relative luminance of the painted tile.
  double get l => palette.map(relativeLuminance).reduce((a, b) => a + b) / palette.length;
}

const List<CalibrationCover> kCalibrationCovers = [
  CalibrationCover('Salt and Iron', [Color(0xFF3B1407), Color(0xFFC4541C), Color(0xFFF2B24A)]),
  CalibrationCover('Ember Ledger', [Color(0xFF2A0B0B), Color(0xFFB3261E), Color(0xFFFF8A3D)]),
  CalibrationCover('The Ninth Regression', [Color(0xFF4A1C0C), Color(0xFFE0762B), Color(0xFFFFD39A)]),
  CalibrationCover('Red Lantern Pact', [Color(0xFF1F0606), Color(0xFF8E1B1B), Color(0xFFF4C542)]),
  CalibrationCover('Dune Courier', [Color(0xFF5A3410), Color(0xFFD99A4E), Color(0xFFFCE3B0)]),
  CalibrationCover('Copper Saints', [Color(0xFF3D1F14), Color(0xFFB8643A), Color(0xFFE9B48A)]),
  CalibrationCover('Moonlit Bakery', [Color(0xFF0B1630), Color(0xFF2E4C8F), Color(0xFFCFE3FF)]),
  CalibrationCover('Glass Tide', [Color(0xFF03282E), Color(0xFF0F7C8A), Color(0xFF8FE3E8)]),
  CalibrationCover('Frost Archive', [Color(0xFF0E1D2B), Color(0xFF4A7BA6), Color(0xFFE6F2FF)]),
  CalibrationCover('Blue Hour Duel', [Color(0xFF101437), Color(0xFF3C3F9E), Color(0xFF9FB4FF)]),
  CalibrationCover('Harbour of Echoes', [Color(0xFF06222A), Color(0xFF1E5F74), Color(0xFF7FD1C7)]),
  CalibrationCover('Cold Orbit', [Color(0xFF070B1A), Color(0xFF22386B), Color(0xFF6FA8FF)]),
  CalibrationCover('Night Ward', [Color(0xFF050507), Color(0xFF14161C), Color(0xFF3A4050)]),
  CalibrationCover('Velvet Abyss', [Color(0xFF07030A), Color(0xFF1C0F24), Color(0xFF4B2A5C)]),
  CalibrationCover('The Quiet Blade', [Color(0xFF040605), Color(0xFF111A14), Color(0xFF2F4A38)]),
  CalibrationCover('Obsidian Hours', [Color(0xFF060606), Color(0xFF16120E), Color(0xFF5A4A36)]),
  CalibrationCover('Petal Almanac', [Color(0xFFFFF4F2), Color(0xFFF6D6DC), Color(0xFFE79AAE)]),
  CalibrationCover('Linen Sky', [Color(0xFFF8F6EF), Color(0xFFE3E8EC), Color(0xFFA9BCCB)]),
  CalibrationCover('Soft Rain Diary', [Color(0xFFF1F5F4), Color(0xFFD5E6E2), Color(0xFF8FB8AE)]),
  CalibrationCover('Morning Porcelain', [Color(0xFFFBF8F3), Color(0xFFEDE3D3), Color(0xFFC9B59A)]),
  CalibrationCover('Ink and Static', [Color(0xFF0A0A0A), Color(0xFF5A5A5A), Color(0xFFD0D0D0)]),
  CalibrationCover('Silent Graphite', [Color(0xFF1E1E1E), Color(0xFF7A7A7A), Color(0xFFBDBDBD)]),
  CalibrationCover('White Room Protocol', [Color(0xFFFFFFFF), Color(0xFFF4F4F4), Color(0xFF1A1A1A)], whiteDominant: true),
  CalibrationCover('Snowfield Letters', [Color(0xFFFFFFFF), Color(0xFFEFEFEF), Color(0xFF2A2A2A)], whiteDominant: true),
];

/// Paints a [CalibrationCover] the way the demo posters read: three bands of the palette on a diagonal,
/// with the white-dominant ones washed to paper.
class CalibrationCoverPainter extends CustomPainter {
  const CalibrationCoverPainter(this.cover);
  final CalibrationCover cover;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final colours = cover.whiteDominant ? [const Color(0xFFFFFFFF), const Color(0xFFF4F4F1), cover.palette.last] : cover.palette;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colours).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(CalibrationCoverPainter old) => old.cover != cover;
}
