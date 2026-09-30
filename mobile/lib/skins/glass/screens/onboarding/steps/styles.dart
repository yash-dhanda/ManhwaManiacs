import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/onboarding/models/taste.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/letter_reveal.dart';
import 'package:manhwamaniacs/skins/glass/primitives/spring_value.dart';
import 'package:manhwamaniacs/skins/glass/screens/onboarding/style_art.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// Step 5, Art style: nine 1:1 crops in a 3 by 3 grid, or typographic tiles until the crops exist.
class GlassStylesStep extends ConsumerWidget {
  const GlassStylesStep({super.key, required this.selected, required this.onToggle});
  final List<StyleId> selected;
  final ValueChanged<StyleId> onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final margin = GlassFrame.screenMargin(context);
    final w = (MediaQuery.sizeOf(context).width - 2 * margin).clamp(0.0, 560.0);
    final cell = (w - 24) / 3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LetterReveal('Which art styles do you like?', role: gt.typeTitle1, screenId: 'onboarding', revealKey: '5', headingLevel: 1),
        const SizedBox(height: 20),
        Center(
          child: SizedBox(
            width: w,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (var i = 0; i < kGlassStyles.length; i++)
                  _Tile(
                    style: kGlassStyles[i],
                    index: i + 1,
                    size: cell,
                    on: selected.contains(kGlassStyles[i].id),
                    onTap: () {
                      glassFire(ref, HapticEvent.select);
                      onToggle(kGlassStyles[i].id);
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.style, required this.index, required this.size, required this.on, required this.onTap});
  final GlassStyle style;
  final int index;
  final double size;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        checked: on,
        button: true,
        label: style.label,
        excludeSemantics: true,
        onTap: onTap,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox.square(
            dimension: size,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: ColoredBox(
                    color: gt.colorSurface1,
                    child: kGlassStyleArtBundled
                        ? Image.asset(style.assetPath(index), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink())
                        : Padding(padding: const EdgeInsets.all(8), child: Center(child: GlassText(style.label, role: gt.typeTitle3, textAlign: TextAlign.center, maxLines: 3, maxScale: 1.3))),
                  ),
                ),
                if (on) Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: gt.colorIris500, width: 2)))),
                Positioned(
                  top: 6,
                  right: 6,
                  child: SpringValue(
                    value: on ? 1 : 0,
                    spring: gt.springTick,
                    builder: (context, v, _) => Transform.scale(
                      scale: v.clamp(0.0, 1.25),
                      child: Opacity(
                        opacity: v.clamp(0.0, 1.0),
                        child: DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, color: gt.colorIris500), child: SizedBox.square(dimension: 24, child: Center(child: GlyphIcon(GlassGlyph.check, size: 14, color: gt.colorOnTint)))),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
