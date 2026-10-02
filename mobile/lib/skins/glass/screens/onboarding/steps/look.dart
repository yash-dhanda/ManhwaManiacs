import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/letter_reveal.dart';
import 'package:manhwamaniacs/skins/glass/primitives/spring_value.dart';
import 'package:manhwamaniacs/skins/glass/screens/onboarding/skin_preview_loop.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';
import 'package:manhwamaniacs/skins/skin_preview.dart';

/// Step 2, Look (only when Glass is available): the two skins as preview cards, a radio group with Glass selected. Choosing
/// Glass carries on; choosing Cinematic restarts into Cinematic at its Formats step.
class GlassLookStep extends ConsumerWidget {
  const GlassLookStep({super.key, required this.skin, required this.onChoose, required this.profileId});
  final String skin;
  final ValueChanged<String> onChoose;
  final int profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wide = GlassFrame.of(context) != GlassFrameKind.phone;
    final cards = [
      _Card(skin: 'glass', title: 'Glass', line: 'Liquid glass, springs and depth.', selected: skin == 'glass', onTap: () => onChoose('glass')),
      _Card(skin: 'cinematic', title: 'Cinematic', line: 'Dark cinema, posters and title cards.', selected: skin == 'cinematic', onTap: () => onChoose('cinematic')),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LetterReveal('Pick a look', role: gt.typeTitle1, screenId: 'onboarding', revealKey: '2', headingLevel: 1),
        const SizedBox(height: 20),
        Semantics(
          container: true,
          label: 'Look',
          child: wide
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: cards[0]), const SizedBox(width: 16), Expanded(child: cards[1])])
              : Column(children: [cards[0], const SizedBox(height: 16), cards[1]]),
        ),
        const SizedBox(height: 16),
        GlassText('Choosing Cinematic restarts the app in Cinematic and carries on from here.', role: gt.typeFootnote, color: gt.colorLabel2),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.skin, required this.title, required this.line, required this.selected, required this.onTap});
  final String skin;
  final String title;
  final String line;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        inMutuallyExclusiveGroup: true,
        checked: selected,
        button: true,
        label: '$title. $line',
        excludeSemantics: true,
        onTap: onTap,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          // The selection ring is drawn over the card (the preview art used to cover its top half).
          child: Container(
            decoration: BoxDecoration(color: gt.colorSurface1, borderRadius: BorderRadius.circular(26)),
            foregroundDecoration: selected ? BoxDecoration(borderRadius: BorderRadius.circular(26), border: Border.all(color: gt.colorIris500, width: 2)) : null,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // The whole phone at its own 390:844 ratio beside the text, so nothing in the miniature is cropped.
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(width: 104, height: 104 / kSkinPreviewAspect, child: GlassSkinPreviewLoop(skin: skin)),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(4, 16, 44, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GlassText(title, role: gt.typeTitle2),
                              const SizedBox(height: 4),
                              GlassText(line, role: gt.typeFootnote, color: gt.colorLabel2),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: SpringValue(
                      value: selected ? 1 : 0,
                      spring: gt.springTick,
                      builder: (context, v, _) => Transform.scale(
                        scale: v.clamp(0.0, 1.25),
                        child: Opacity(
                          opacity: v.clamp(0.0, 1.0),
                          child: DecoratedBox(
                            decoration: BoxDecoration(shape: BoxShape.circle, color: gt.colorIris500),
                            child: SizedBox.square(dimension: 24, child: Center(child: GlyphIcon(GlassGlyph.check, size: 14, color: gt.colorOnTint))),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
