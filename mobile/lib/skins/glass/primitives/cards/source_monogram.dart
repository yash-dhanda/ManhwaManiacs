import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';

/// The speaker palette of glass 2.1.5, for tinting a monogram by a hash of the source id.
List<Color> get glassSpeakerPalette => [
      GlassColors.spk1,
      GlassColors.spk2,
      GlassColors.spk3,
      GlassColors.spk4,
      GlassColors.spk5,
      GlassColors.spk6,
      GlassColors.spk7,
      GlassColors.spk8,
      GlassColors.spk9,
      GlassColors.spk10,
    ];

/// A stable hash of [id] (FNV-1a), so a source keeps its colour across launches.
int stableHash(String id) {
  var h = 0x811c9dc5;
  for (final u in id.codeUnits) {
    h = ((h ^ u) * 0x01000193) & 0xFFFFFFFF;
  }
  return h;
}

/// The logo fallback (glass 7.7): the first letter of the source name in `headline` 600 `label1` on
/// `surface3`, radius 10, tinted by a hash of the source id into the speaker palette at 24 %.
class GlassSourceMonogram extends StatelessWidget {
  const GlassSourceMonogram({super.key, required this.name, required this.sourceId, this.size = 44});
  final String name;
  final String sourceId;
  final double size;

  Color get tint => glassSpeakerPalette[stableHash(sourceId) % glassSpeakerPalette.length];

  @override
  Widget build(BuildContext context) {
    final letter = name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase();
    final small = size <= 20;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Color.alphaBlend(tint.withValues(alpha: 0.24), gt.colorSurface3),
        borderRadius: BorderRadius.circular(small ? 4 : gt.radiusSm),
      ),
      child: GlassLabel(letter, role: small ? gt.typeCaption1 : gt.typeHeadline, wght: 600, color: gt.colorLabel1),
    );
  }
}
