import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/paper_frame.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart' show GlassShape;

/// The end matter (D11): 96 px of space, a 96 px rule, "END OF CHAPTER 12", the length line, the ordered [reactionSlots]
/// (`mobile/43`'s strip), the Next card or the last-chapter line, then "Previous chapter" and "Back to the book". Content, never
/// glass: the card is `surface1` on the paper.
class GlassEndMatter extends StatelessWidget {
  const GlassEndMatter({
    super.key,
    required this.endLabel,
    required this.lengthLine,
    this.nextLabel,
    this.onNext,
    this.locked = false,
    this.onPrevious,
    required this.onBackToBook,
    this.reactionSlots = const [],
    this.endOfDownload = false,
    this.onDownloadNext,
    this.cardKey,
  });

  final String endLabel, lengthLine;

  /// "Chapter 13 · The Tower"; null on the last chapter the source has published.
  final String? nextLabel;
  final VoidCallback? onNext;

  /// The pull reached 72 px: the card is locked (D12).
  final bool locked;
  final VoidCallback? onPrevious;
  final VoidCallback onBackToBook;
  final List<Widget> reactionSlots;

  /// Offline and the next chapter is not on the phone (J).
  final bool endOfDownload;
  final VoidCallback? onDownloadNext;
  final GlobalKey? cardKey;

  @override
  Widget build(BuildContext context) {
    final colors = PaperScope.of(context);
    final caption = roleStyle(context, gt.typeCaption1, maxScale: 1.3);
    final meta = roleStyle(context, gt.typeMono, size: 12, height: 16, maxScale: 1.3).copyWith(color: colors.muted);
    Widget plain(String label, VoidCallback? onTap) => GlassButton(label: label, onPressed: onTap, variant: GlassButtonVariant.plain, lb: 0);
    return Padding(
      padding: const EdgeInsets.only(top: 96, bottom: 160),
      child: Column(
        children: [
          ExcludeSemantics(child: SizedBox(width: 96, height: 1, child: ColoredBox(color: colors.muted))),
          const SizedBox(height: 16),
          Text(endLabel, style: caption.copyWith(color: colors.muted, letterSpacing: 0.22 * (caption.fontSize ?? 12)), textScaler: TextScaler.noScaling),
          const SizedBox(height: 6),
          Text(lengthLine, style: meta, textScaler: TextScaler.noScaling),
          ...reactionSlots,
          const SizedBox(height: 32),
          if (endOfDownload) ...[
            Text('End of the downloaded copy', style: roleStyle(context, gt.typeBody).copyWith(color: colors.ink), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            plain('Download next 10 when online', onDownloadNext),
          ] else if (nextLabel != null)
            _NextCard(key: cardKey, label: nextLabel!, onTap: onNext, locked: locked)
          else
            Text("You've reached the last chapter this source has published", style: roleStyle(context, gt.typeBody).copyWith(color: colors.muted), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (onPrevious != null) plain('Previous chapter', onPrevious),
              plain('Back to the book', onBackToBook),
            ],
          ),
        ],
      ),
    );
  }
}

class _NextCard extends StatelessWidget {
  const _NextCard({super.key, required this.label, required this.onTap, required this.locked});
  final String label;
  final VoidCallback? onTap;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final colors = PaperScope.of(context);
    final caption = roleStyle(context, gt.typeCaption1, maxScale: 1.3);
    return GlassPressable(
      material: GlassMaterial.content,
      shape: const GlassShape.superellipse(20),
      onTap: onTap,
      semanticsLabel: 'Next, $label',
      builder: (context, _) => AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: gt.colorSurface1,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: locked ? gt.colorIris400 : const Color(0x00000000), width: 1.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NEXT', style: caption.copyWith(color: colors.muted, letterSpacing: 0.22 * (caption.fontSize ?? 12)), textScaler: TextScaler.noScaling),
                    const SizedBox(height: 4),
                    Text(label, style: TextStyle(fontFamily: 'LiterataMM', fontSize: 20, height: 1.3, color: colors.ink, fontVariations: const [FontVariation('opsz', 20), FontVariation('wght', 500)])),
                  ],
                ),
              ),
              GlyphIcon(GlassGlyph.caretRight, color: colors.ink),
            ],
          ),
        ),
    );
  }
}
