import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';

/// The 30 x 30 icon tile of a settings row (glass 7.17): radius 12, an 18 px white glyph on the section's colour.
/// Tile colours are this step's choice (mobile/39 report): white on each is at least 3:1 (icon_tile_test).
class SettingsIconTile extends StatelessWidget {
  const SettingsIconTile({super.key, required this.glyph, required this.color});
  final Glyph glyph;
  final Color color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
          alignment: Alignment.center,
          child: GlyphIcon(glyph, size: 18, color: const Color(0xFFFFFFFF)),
        ),
      );
}
