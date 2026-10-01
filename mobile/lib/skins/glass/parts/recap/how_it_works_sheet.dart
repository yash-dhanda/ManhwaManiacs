import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/icons/glass_glyphs.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/routes/glass_sheet_route.dart';
import 'package:manhwamaniacs/skins/glass/routes/sheet_registry.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// Registers `?sheet=how-it-works` (glass 8.0.3): `medium`, the 560 px window on wide frames.
void registerHowItWorksSheet() => registerGlobalSheet(
      'how-it-works',
      const GlassSheetSpec(
          title: 'How recaps and dialogue search read manga',
          builder: _how,
          detents: [GlassDetent.medium, GlassDetent.large],
          opening: GlassDetent.medium,),
    );

Widget _how(BuildContext context) => const HowItWorksBody();

class HowItWorksBody extends ConsumerWidget {
  const HowItWorksBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget row(Widget icon, String title, String body) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                  width: 30,
                  height: 30,
                  child: DecoratedBox(
                      decoration: BoxDecoration(
                          color: gt.colorSurface1,
                          borderRadius: BorderRadius.circular(8),),
                      child: Center(child: icon),),),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GlassText(title, role: gt.typeHeadline, onGlass: true),
                    const SizedBox(height: 2),
                    GlassText(body, role: gt.typeFootnote, onGlass: true),
                  ],
                ),
              ),
            ],
          ),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          row(
              GlyphIcon(GlassGlyph.cloudArrowDown,
                  size: 18, color: gt.colorLabel1,),
              'Download the chapter',
              'Text is read from pages saved on this phone.',),
          row(
              Icon(GlassGlyphs.bubbleSearchRegular,
                  size: 18, color: gt.colorLabel1,),
              'Extract text',
              "Your phone reads the speech bubbles and sends only the words to your server. On the web, extraction isn't available.",),
          row(
              GlyphIcon(GlassGlyph.sparkle, size: 18, color: gt.colorMachine),
              'Recaps and dialogue search use it',
              'Recaps are written from these words, and you can search what characters said.',),
          const SizedBox(height: 4),
          GlassButton(
            label: 'Open downloads',
            variant: GlassButtonVariant.primary,
            size: GlassButtonSize.large,
            fullWidth: true,
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(skinRouterProvider).push<void>(Routes.downloads());
            },
          ),
          const SizedBox(height: 8),
          GlassButton(
              label: 'Close',
              variant: GlassButtonVariant.plain,
              size: GlassButtonSize.large,
              fullWidth: true,
              onPressed: () => Navigator.of(context).pop(),),
        ],
      ),
    );
  }
}
