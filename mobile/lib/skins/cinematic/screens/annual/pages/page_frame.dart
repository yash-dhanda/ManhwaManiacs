import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/library/models/annual.dart';
import 'package:manhwamaniacs/skins/cinematic/cine_grain.dart';
import 'package:manhwamaniacs/skins/cinematic/duotone.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_image.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/set_heading.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/annual/annual_player.dart';
import 'package:manhwamaniacs/skins/cinematic/tint.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// What every page of the story needs.
class AnnualEnv {
  const AnnualEnv({
    required this.annual,
    required this.profileName,
    required this.player,
    required this.goTo,
    required this.close,
    required this.readNumbers,
    required this.now,
  });

  final Annual annual;
  final String profileName;
  final AnnualPlayer player;
  final ValueChanged<int> goTo;
  final VoidCallback close;
  final VoidCallback readNumbers;
  final DateTime now;
}

/// The page ground (cinematic 9.2.4): the top series' cover in duotone to its
/// `ambient.duo` (fallback `#B8B2A4`) with grain 0.06 and the vignette, a foot
/// scrim ending on the top series' `ambient.tint` (fallback `#0E0D0B`), and a
/// centred 9:16 safe box the content is bottom-anchored in.
class AnnualPageFrame extends ConsumerWidget {
  const AnnualPageFrame(
      {super.key,
      required this.annual,
      required this.child,
      this.artOverride,
      this.showArt = true,
      this.alignment = Alignment.bottomCenter,});

  final Annual annual;
  final Widget child;

  /// Replaces the ground art (the cover's mosaic).
  final Widget? artOverride;
  final bool showArt;
  final Alignment alignment;

  static Color tintOf(Annual a) => parseAmbientHex(
      a.topSeries.isEmpty ? null : a.topSeries.first.ambient?.tint,
      fallback: CineColors.ambientFallbackTint,);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final top = annual.topSeries.isEmpty ? null : annual.topSeries.first;
    final tint = tintOf(annual);
    Widget art;
    if (artOverride != null) {
      art = artOverride!;
    } else if (showArt && top?.coverUrl != null) {
      art = AnnualArt(
          url: top!.coverUrl!, duo: parseAmbientHex(top.ambient?.duo),);
    } else {
      art = const CineGrain(child: ColoredBox(color: CineColors.paper1));
    }
    return LayoutBuilder(
      builder: (context, box) {
        final safeW = math.min(box.maxWidth, box.maxHeight * 9 / 16);
        final safeH = math.min(box.maxHeight, box.maxWidth * 16 / 9);
        return Stack(
          fit: StackFit.expand,
          children: [
            art,
            const DecoratedBox(
                decoration: BoxDecoration(gradient: CineScrim.vignette),),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: const Alignment(0, -0.2),
                    end: Alignment.bottomCenter,
                    stops: CineScrim.kScrimStops,
                    colors: [
                      for (final a in CineScrim.kScrimAlpha)
                        tint.withValues(alpha: a),
                    ],),
              ),
            ),
            Center(
                child: SizedBox(
                    width: safeW,
                    height: safeH,
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                        child: Align(alignment: alignment, child: child),),),),
          ],
        );
      },
    );
  }
}

/// A cover in duotone to its `ambient.duo` with grain at 0.06 (cinematic 2.1.5, 9.2.4).
class AnnualArt extends StatelessWidget {
  const AnnualArt(
      {super.key, required this.url, required this.duo, this.opacity = 1,});
  final String url;
  final Color duo;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    Widget art =
        CineGrain(child: CineDuotone(duo: duo, child: CineImage(url: url)));
    if (opacity < 1) art = Opacity(opacity: opacity, child: art);
    return ExcludeSemantics(child: art);
  }
}

/// A page title: the letter reveal on `signal` (it plays when the page is built, i.e. shown), with
/// an optional grapheme range typed at 50 ms per grapheme (the figure).
class AnnualTitle extends StatelessWidget {
  const AnnualTitle(this.text, this.role,
      {super.key,
      required this.id,
      this.typedRange,
      this.level = 2,
      this.color,});
  final String text, id;
  final CineTextRole role;
  final ({int start, int end})? typedRange;
  final int level;
  final Color? color;

  @override
  Widget build(BuildContext context) => SetHeading(
        text,
        id: 'annual-$id',
        style: CineText.style(context, role)
            .copyWith(color: color ?? CineColors.ink100),
        cap: role.cap,
        level: level,
        trigger: SetTrigger.signal,
        typedRange: typedRange,
      );
}
