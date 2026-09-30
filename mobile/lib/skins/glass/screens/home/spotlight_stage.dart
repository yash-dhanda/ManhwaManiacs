import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/glass/shape.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/hero_field.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/spotlight_card.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/spotlights.dart';

/// The tablet and desktop stage (glass 8.8): 440 px tall on the desktop frame, 360 on the tablet. The cover card 240 px wide on the
/// left over the enlargement; at the right the title in `display`, the meta, the `why` and the two actions; bottom right a strip of
/// the next four covers. `Left` and `Right` page it (the parent `Focus`), hover tilts the card toward the pointer, and it never
/// auto-rotates.
class SpotlightStage extends ConsumerWidget {
  const SpotlightStage({super.key, required this.specs, required this.index, required this.handlers, required this.onSelect, required this.tiltActive, required this.controlsOnScreen, required this.desktop});
  final List<SpotlightSpec> specs;
  final int index;
  final SpotlightHandlers handlers;
  final ValueChanged<int> onSelect;
  final bool tiltActive;
  final bool controlsOnScreen;
  final bool desktop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spec = specs[index];
    final h = desktop ? 440.0 : 360.0;
    final margin = GlassFrame.screenMargin(context);
    final hit = GlassFrame.hitMin(context);
    final next = [for (var k = 1; k <= 4; k++) if (index + k < specs.length) index + k];
    return SizedBox(
      height: h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(left: -margin, right: -margin, top: 0, bottom: 0, child: HeroField(palette: spec.palette)),
          Positioned(
            left: 24,
            top: (h - 240 * 1.5) / 2,
            child: SpotlightTilt(active: tiltActive, child: SpotlightCover(spec: spec, width: 240, position: index, count: specs.length, handlers: handlers)),
          ),
          Positioned(
            left: 24 + 240 + 32,
            right: 24,
            top: 24,
            bottom: 24 + 72 + 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SpotlightText(spec: spec, wide: true),
                const SizedBox(height: 16),
                SpotlightActions(spec: spec, handlers: handlers, onScreen: controlsOnScreen),
              ],
            ),
          ),
          if (next.isNotEmpty)
            Positioned(
              right: 24,
              bottom: 16,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final k in next)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: SizedBox(
                        width: 48 < hit ? hit : 48,
                        height: 72,
                        child: GlassPressable(
                          material: GlassMaterial.content,
                          sink: 0.94,
                          shape: const GlassShape.superellipse(10),
                          minHit: false,
                          onTap: () => onSelect(k),
                          semanticsLabel: 'Show ${specs[k].title}',
                          builder: (context, info) => Center(
                            child: SizedBox(
                              width: 48,
                              height: 72,
                              child: ClipRSuperellipse(borderRadius: BorderRadius.circular(10), child: specs[k].isWrapped ? WrappedFace(year: specs[k].year ?? DateTime.now().year) : HomeCoverImage(url: specs[k].coverUrl, width: 48)),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
