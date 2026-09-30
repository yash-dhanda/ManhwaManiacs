import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/screens/onboarding/skin_preview_loop.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';
import 'package:manhwamaniacs/skins/skin.dart';

/// One skin card of Appearance (glass 8.25.1): the looping preview, the name, the character line and a "Current" tag. Phones lay it
/// out as a row (preview 160 x 347 at the left); wider frames stack it (preview 240 x 520 on top).
class GlassSkinCard extends StatelessWidget {
  const GlassSkinCard({super.key, required this.skin, required this.current, required this.onChoose});
  final SkinId skin;
  final bool current;

  /// Called with the card's global rect so the switch alert can bloom from it.
  final void Function(Rect origin) onChoose;

  String get name => skin == SkinId.glass ? 'Glass' : 'Cinematic';
  String get character => skin == SkinId.glass ? 'Liquid glass, springs and depth.' : 'Dark cinema, posters and title cards.';

  @override
  Widget build(BuildContext context) {
    final wide = GlassFrame.of(context) != GlassFrameKind.phone;
    final (w, h) = wide ? (240.0, 520.0) : (160.0, 347.0);
    final preview = ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(width: w, height: h, child: ExcludeSemantics(child: GlassSkinPreviewLoop(skin: skin.name, height: h))),
    );
    final text = Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Row(mainAxisSize: MainAxisSize.min, children: [
        GlassText(name, role: gt.typeTitle2),
        if (current) ...[
          const SizedBox(width: 8),
          Container(
            height: 20,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: gt.colorFill2, borderRadius: BorderRadius.circular(10)),
            child: GlassText('Current', role: gt.typeCaption1, wght: 600),
          ),
        ],
      ],),
      const SizedBox(height: 4),
      GlassText(character, role: gt.typeFootnote, color: gt.colorLabel2),
    ],);
    return Builder(
      builder: (context) => Semantics(
        inMutuallyExclusiveGroup: true,
        checked: current,
        button: true,
        label: '$name skin. $character',
        excludeSemantics: true,
        onTap: () => _tap(context),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _tap(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: wide
                ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [preview, const SizedBox(height: 12), text])
                : Row(children: [preview, const SizedBox(width: 16), Expanded(child: text)]),
          ),
        ),
      ),
    );
  }

  void _tap(BuildContext context) {
    if (current) {
      SemanticsService.sendAnnouncement(View.of(context), '$name is the current skin', Directionality.of(context));
      return;
    }
    final box = context.findRenderObject();
    onChoose(box is RenderBox && box.hasSize ? box.localToGlobal(Offset.zero) & box.size : Rect.zero);
  }
}
