import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs_more.dart';

/// The "Top" capsule (glass 8.11): after 400 px of scroll, bottom-right; a tap scrolls to the top. Semantics "Back to top".
class TopCapsule extends StatelessWidget {
  const TopCapsule({super.key, required this.visible, required this.onTap});
  final bool visible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        ignoring: !visible,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 180),
          child: Semantics(
            button: true,
            label: 'Back to top',
            excludeSemantics: true,
            onTap: onTap,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                child: DecoratedBox(
                  decoration: BoxDecoration(color: gt.colorFill2, borderRadius: BorderRadius.circular(24)),
                  child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(GlassGlyph28.arrowUp.regular, size: 16, color: gt.colorLabel1), const SizedBox(width: 6), GlassLabel('Top', role: gt.typeFootnote, wght: 600)])),
                ),
              ),
            ),
          ),
        ),
      );
}
