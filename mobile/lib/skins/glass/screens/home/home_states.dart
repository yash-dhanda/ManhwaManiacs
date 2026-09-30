import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/primitives/poster.dart';
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/lens_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/object_lens.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/spotlight_card.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// Loading (glass 8.8): the greeting is already there; after 180 ms a spotlight skeleton card (2:3 at 62 % width, radius 26; the stage
/// skeleton on wider frames) and three rail skeletons (a header bar and five posters).
class HomeLoadingSkeleton extends StatelessWidget {
  const HomeLoadingSkeleton({super.key, this.delayed = true});
  final bool delayed;

  @override
  Widget build(BuildContext context) {
    final frame = GlassFrame.of(context);
    final wide = frame.index >= GlassFrameKind.tablet.index;
    final margin = GlassFrame.screenMargin(context);
    final pw = posterWidthFor(frame);
    final cw = spotlightCoverWidth(context, wide: wide);
    return Semantics(
      container: true,
      label: 'Loading',
      value: 'Loading',
      child: GlassSkeletonGroup(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (wide)
              GlassSkeleton(height: frame.index >= GlassFrameKind.desktop.index ? 440 : 360, radius: 26, delayed: delayed)
            else
              Center(child: GlassSkeleton(width: cw, height: cw * 1.5, radius: 26, delayed: delayed)),
            const SizedBox(height: 24),
            for (var r = 0; r < 3; r++) ...[
              Align(alignment: Alignment.centerLeft, child: GlassSkeleton(width: 160, height: 22, radius: 8, delayed: delayed)),
              const SizedBox(height: 12),
              SizedBox(
                height: pw * 1.5,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.only(right: margin),
                  itemCount: 5,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => GlassSkeleton(width: pw, height: pw * 1.5, index: i, delayed: delayed),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}

/// The new profile's inline lens under its rails (nothing followed, nothing read).
class HomeNewProfileLens extends ConsumerWidget {
  const HomeNewProfileLens({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: GlassObjectLens(
          situation: LensSituation.library,
          title: 'Nothing followed yet',
          placement: GlassLensPlacement.inline,
          primary: LensAction('Browse sources', () => ref.read(skinRouterProvider).go(Routes.sources())),
        ),
      );
}

/// Every section failed: the whole screen is the lens.
class HomeErrorLens extends StatelessWidget {
  const HomeErrorLens({super.key, required this.onRetry});
  final Future<bool> Function() onRetry;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: GlassObjectLens(
          situation: LensSituation.loadError,
          tone: GlassLensTone.error,
          title: "Couldn't load your home",
          primary: LensAction('Try again', onRetry),
        ),
      );
}
