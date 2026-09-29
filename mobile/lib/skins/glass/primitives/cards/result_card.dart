import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/poster.dart';

/// A search result (glass 7.7): 112 wide by 208: a 112 x 168 poster and the title in two lines `footnote`.
/// Its source glyph badge is hidden inside source groups ([hideSource]).
class GlassResultCard extends StatelessWidget {
  const GlassResultCard({super.key, required this.cover, required this.title, this.sourceBadge, this.hideSource = false, this.onTap, this.onContextPreview, this.meta = const GlassPosterMeta()});

  final Widget cover;
  final String title;

  /// The source glyph or monogram, shown bottom-left on a backing disc.
  final Widget? sourceBadge;
  final bool hideSource;
  final VoidCallback? onTap;
  final VoidCallback? onContextPreview;
  final GlassPosterMeta meta;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 112,
        height: 208,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                GlassPoster(cover: cover, title: title, width: 112, meta: meta, onTap: onTap, onContextPreview: onContextPreview),
                if (!hideSource && sourceBadge != null)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(width: 24, height: 24, alignment: Alignment.center, decoration: const BoxDecoration(color: Color(0xDB000000), shape: BoxShape.circle), child: SizedBox(width: 16, height: 16, child: sourceBadge)),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(child: GlassLabel(title, role: gt.typeFootnote, wght: 600, maxLines: 2)),
          ],
        ),
      );
}
