import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/poster.dart';

/// A history tile (glass 7.7): a poster with a 3 px progress line along its bottom edge, a 36 px play orb
/// bottom-right ("p. 18" or "42 %") drawn as a content twin on the cover-overlay backing (`rgba(0,0,0,0.86)`
/// disc, 0.5 px `rgba(255,255,255,0.22)` rim, no backdrop read), and below it the title and "Ch 12 - 3 h ago".
class GlassHistoryTile extends StatelessWidget {
  const GlassHistoryTile({super.key, required this.cover, required this.title, required this.when, required this.position, required this.progress, this.onOpen, this.onResume, this.width});
  final Widget cover;
  final String title;

  /// "Ch 12 · 3 h ago".
  final String when;

  /// "p. 18" or "42 %".
  final String position;
  final double progress;
  final VoidCallback? onOpen;
  final VoidCallback? onResume;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final w = width ?? 124.0;
    return SizedBox(
      width: w,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              GlassPoster(cover: cover, title: '$title, $when, $position', width: w, meta: GlassPosterMeta(progress: progress), onTap: onOpen),
              Positioned(
                right: 6,
                bottom: 12,
                child: Semantics(
                  label: 'Resume at $position',
                  button: true,
                  onTap: onResume,
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: onResume,
                    child: Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: const Color(0xDB000000), shape: BoxShape.circle, border: Border.all(color: const Color(0x38FFFFFF), width: 0.5)),
                      child: GlyphIcon(GlassGlyph.play, size: 16, color: gt.colorLabel1),
                    ),
                  ),
                ),
              ),
              Positioned(left: 8, bottom: 12, child: _Pill(position)),
            ],
          ),
          const SizedBox(height: 8),
          GlassLabel(title, role: gt.typeFootnote, wght: 600, maxLines: 2),
          GlassLabel(when, role: gt.typeCaption1, color: gt.colorLabel3),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: const Color(0xDB000000), borderRadius: BorderRadius.circular(10)),
        child: GlassLabel(text, role: gt.typeMono, size: 11, height: 14, color: gt.colorLabel1),
      );
}
