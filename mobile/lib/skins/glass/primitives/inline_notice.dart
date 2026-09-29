import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/icons/phosphor.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

enum GlassNoticeVariant { info, warning, danger, success }

/// An inline notice (glass 7.30): a `surface1` slab, radius 20, padding 12 16, a leading 20 px glyph in the semantic
/// colour, text `callout`, an optional plain action trailing and a 3 px leading bar in the semantic colour.
class GlassInlineNotice extends StatelessWidget {
  const GlassInlineNotice({super.key, required this.message, this.variant = GlassNoticeVariant.info, this.actionLabel, this.onAction});
  final String message;
  final GlassNoticeVariant variant;
  final String? actionLabel;
  final VoidCallback? onAction;

  Color get _color => switch (variant) {
        GlassNoticeVariant.info => gt.colorInfo,
        GlassNoticeVariant.warning => gt.colorWarning,
        GlassNoticeVariant.danger => gt.colorDanger,
        GlassNoticeVariant.success => gt.colorSuccess,
      };

  IconData get _glyph => switch (variant) {
        GlassNoticeVariant.info => GlassGlyphExt2.info,
        GlassNoticeVariant.warning => GlassGlyph.warning.fill,
        GlassNoticeVariant.danger => GlassGlyph.warningCircle.fill,
        GlassNoticeVariant.success => PhosphorFill.checkCircle,
      };

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        liveRegion: variant == GlassNoticeVariant.danger,
        child: ClipRSuperellipse(
          borderRadius: BorderRadius.circular(20),
          child: DecoratedBox(
            decoration: BoxDecoration(color: gt.colorSurface1),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 3),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(_glyph, size: 20, color: _color),
                        const SizedBox(width: 12),
                        Expanded(child: GlassText(message, role: gt.typeCallout, maxScale: 1.5)),
                        if (actionLabel != null) ...[const SizedBox(width: 8), GlassButton(label: actionLabel!, variant: GlassButtonVariant.plain, size: GlassButtonSize.small, onPressed: onAction)],
                      ],
                    ),
                  ),
                ),
                Positioned(left: 0, top: 0, bottom: 0, width: 3, child: ColoredBox(key: const ValueKey('glass-notice-bar'), color: _color)),
              ],
            ),
          ),
        ),
      );
}

/// Glyphs the generated tables lack.
abstract final class GlassGlyphExt2 {
  static const info = IconData(0xe2ce, fontFamily: 'PhosphorFill');
}
