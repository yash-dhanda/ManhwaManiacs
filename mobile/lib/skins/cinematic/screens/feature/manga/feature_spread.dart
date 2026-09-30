import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/ambient_scope.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_states.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/feature_hero.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// The tablet spread (8 columns): text in columns 1-4, the cover against the
/// right edge in 5-8 with `scrimGutter` over the art columns 5-6 and the 2 px
/// `spot` reading-progress rule along its bottom. Height `clamp(520, 0.64 x
/// screen height, 760)`.
class FeatureSpread extends StatelessWidget {
  const FeatureSpread({super.key, required this.parts});
  final HeroParts parts;

  @override
  Widget build(BuildContext context) {
    final t = cineOf(context);
    final amb = CineAmbient.of(context);
    final h = (MediaQuery.sizeOf(context).height * 0.64).clamp(520.0, 760.0);
    return Padding(
      padding: EdgeInsets.zero,
      child: SizedBox(
        key: const Key('feature-spread'),
        height: h,
        child: Stack(
          children: [
            // The duotone field to the left of the cover.
            Positioned.fill(child: ColoredBox(color: amb.duo)),
            Row(
              children: [
                Expanded(
                  flex: 4,
                  // The text sits on the duotone field: black at 0.84 across the column is the
                  // over-art minimum for every ink it uses (cinematic 2.1.4, `proof` row).
                  child: ColoredBox(
                    color: const Color.fromRGBO(0, 0, 0, 0.84),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      // Foot-anchored; scrolls from its foot when a short screen (a landscape phone) is
                      // shorter than the text.
                      child: LayoutBuilder(
                        builder: (context, box) => SingleChildScrollView(
                          reverse: true,
                          child: ConstrainedBox(
                            constraints:
                                BoxConstraints(minHeight: box.maxHeight),
                            child: Align(
                              alignment: Alignment.bottomLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  parts.kicker,
                                  const SizedBox(height: 8),
                                  parts.title,
                                  if (parts.deck != null) ...[
                                    const SizedBox(height: 8),
                                    parts.deck!
                                  ],
                                  const SizedBox(height: 16),
                                  parts.credits,
                                  const SizedBox(height: 16),
                                  parts.actions,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      parts.cover,
                      const IgnorePointer(
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: 0.5,
                          child: DecoratedBox(
                              decoration:
                                  BoxDecoration(gradient: CineScrim.gutter)),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 2,
                        child: LayoutBuilder(
                          builder: (context, c) => Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              key: const Key('reading-rule'),
                              width: c.maxWidth * parts.progressFraction,
                              height: 2,
                              color: t.colorSpot,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
