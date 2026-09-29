import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/dev/dev_controls.dart';
import 'package:manhwamaniacs/skins/glass/dev/gallery_sections.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/glass/ambient_field.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// The sections of the primitives gallery, in order (`?section=` picks one).
const List<String> kGlassGallerySections = [
  'buttons',
  'hold',
  'icon-buttons',
  'inputs',
  'search',
  'chips',
  'segmented',
  'cards',
  'posters',
  'rails',
  'skeletons',
  'progress',
  'badges',
  'avatars',
  'tooltips',
  'reveals',
];

/// `/dev/glass/primitives` (glass 15.8, `mobile/26`): one section per family of the first half of the
/// component catalogue. Each shows every variant in every state, over three grounds side by side on tablet
/// and stacked on phones: black, the ambient field and a white panel (to show the legibility dim and the
/// backing discs). The live surfaces are budget-exempt here (`GlassBudgetScope(exempt: true)`). A toolbar
/// toggles Solid glass, Increase contrast and Reduce motion through the in-app keys.
class GlassGallery extends ConsumerWidget {
  const GlassGallery({super.key, this.section});

  /// One of [kGlassGallerySections], or null for all of them.
  final String? section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inApp = ref.watch(glassInAppPrefsProvider);
    final ctl = ref.read(glassInAppPrefsProvider.notifier);
    final margin = GlassFrame.screenMargin(context);
    final names = section == null ? kGlassGallerySections : [section!];
    return GlassAmbientScope(
      spec: const GlassAmbientSpec.aurora(),
      child: GlassBudgetScope(
        exempt: true,
        label: 'gallery',
        child: ColoredBox(
          color: const Color(0xFF000000),
          child: SafeArea(
            child: ListView(
              padding: EdgeInsets.fromLTRB(margin, 16, margin, 48),
              children: [
                GlassText('Primitives', role: glassTokens.typeLargeTitle),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    for (final e in [
                      ('Solid glass', inApp.solidGlass, ctl.setSolidGlass),
                      ('Increase contrast', inApp.increaseContrast, ctl.setIncreaseContrast),
                      ('Reduce motion', inApp.reduceMotion, ctl.setReduceMotion),
                    ])
                      SizedBox(width: 220, child: DevToggle(label: e.$1, value: e.$2, onChanged: e.$3)),
                  ],
                ),
                for (final n in names) GlassGallerySection(name: n),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
