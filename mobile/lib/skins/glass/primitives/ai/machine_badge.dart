import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart' show GlassIconWeight;
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';

/// The suffix every AI-written line's semantics label carries.
String suggestedByAi(String label) => '$label, suggested by AI';

/// The machine light on AI output only (glass 2.1.9): a `sparkle` in `machine` (Regular 14 while streaming, Fill when final)
/// leading every AI-written line, on a `machineWash` disc where it sits alone. The people light (`bloom`) is never used for it.
class MachineBadge extends StatelessWidget {
  const MachineBadge({super.key, this.streaming = false, this.alone = false, this.size = 14});
  final bool streaming;

  /// A `machineWash` disc behind it where the badge sits by itself.
  final bool alone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final glyph = GlyphIcon(GlassGlyph.sparkle, size: size, color: gt.colorMachine, weight: streaming ? GlassIconWeight.regular : GlassIconWeight.fill);
    if (!alone) return glyph;
    return DecoratedBox(
      decoration: BoxDecoration(color: gt.colorMachineWash, shape: BoxShape.circle),
      child: Padding(padding: const EdgeInsets.all(5), child: glyph),
    );
  }
}
