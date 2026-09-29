import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_ambient.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/feature_hero.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// The phone hero: the cover full-bleed at 4:5 (height `min(width x 1.25,
/// 0.70 x screen)`), `scrimFoot` into `ambient.tint`, the vignette, and the
/// title block overlapping its lower quarter; then the actions and credits over
/// the page spill (the 30 % of screen height under the hero fading tint to black).
class FeaturePhoneHero extends StatelessWidget {
  const FeaturePhoneHero({super.key, required this.parts});
  final HeroParts parts;

  @override
  Widget build(BuildContext context) {
    final amb = CineAmbient.of(context);
    final size = MediaQuery.sizeOf(context);
    final heroH = (size.width * 1.25).clamp(0.0, size.height * 0.70);
    final foot = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: CineScrim.kScrimStops,
      colors: [
        for (final a in CineScrim.kScrimAlpha) amb.tint.withValues(alpha: a),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          key: const Key('feature-cover-frame'),
          height: heroH,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              parts.cover,
              const IgnorePointer(
                child: DecoratedBox(decoration: BoxDecoration(gradient: CineScrim.vignette)),
              ),
              IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(gradient: foot))),
              Positioned(
                left: 16,
                right: 16,
                bottom: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    parts.kicker,
                    const SizedBox(height: 8),
                    parts.title,
                    if (parts.deck != null) ...[const SizedBox(height: 8), parts.deck!],
                  ],
                ),
              ),
            ],
          ),
        ),
        Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: size.height * 0.30,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [amb.tint, const Color(0xFF000000)],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [parts.actions, const SizedBox(height: 8), parts.credits],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
