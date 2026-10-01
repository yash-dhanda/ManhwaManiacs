import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/features/library/models/collection.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/collection_card.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart' show GlassGlyph;
import 'package:manhwamaniacs/skins/glass/primitives/glyphs_more.dart' show GlassGlyph28;
import 'package:manhwamaniacs/skins/glass/screens/home/home_common.dart';

/// A collection on the Collections page: the `GlassCollectionCard` slab with the "Auto" capsule (smart shelves) or the friend marker
/// "Shared with Aarav" (glass 8.18). [covers] are the member covers (the server's preview, or the first four the device computed).
class LibraryCollectionCard extends StatelessWidget {
  const LibraryCollectionCard({super.key, required this.collection, required this.covers, required this.onTap, this.cardKey, this.sharedWith, this.width = 320});
  final Collection collection;
  final List<String> covers;
  final VoidCallback onTap;
  final GlobalKey<GlassCollectionCardState>? cardKey;
  final String? sharedWith;
  final double width;

  @override
  Widget build(BuildContext context) {
    final auto = collection.smart;
    return Semantics(
      label: [if (auto) 'Auto collection', if (sharedWith != null) 'Shared with $sharedWith'].join(', '),
      child: Stack(children: [
        GlassCollectionCard(
          key: cardKey,
          name: collection.name,
          count: collection.seriesCount,
          covers: [for (final c in covers.take(4)) HomeCoverImage(url: c, width: 72)],
          onTap: onTap,
          width: width,
        ),
        if (auto || sharedWith != null)
          Positioned(
            top: 10,
            right: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(color: const Color(0xDB000000), borderRadius: BorderRadius.circular(999), border: Border.all(color: const Color(0x38FFFFFF), width: 0.5)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (auto) Icon(GlassGlyph28.lightning.fill, size: 14, color: gt.colorIris400) else Icon(GlassGlyph.user.regular, size: 14, color: gt.colorIris400),
                  const SizedBox(width: 4),
                  GlassLabel(auto ? 'Auto' : 'Shared with $sharedWith', role: gt.typeCaption1, wght: 600),
                ],),
              ),
            ),
          ),
      ],),
    );
  }
}
