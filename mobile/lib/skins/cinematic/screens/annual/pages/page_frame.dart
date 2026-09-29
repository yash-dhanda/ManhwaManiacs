import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/library/models/annual.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/cover.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/duotone.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/annual/annual_player.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

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
  const AnnualPageFrame({super.key, required this.annual, required this.child, this.artOverride, this.showArt = true, this.alignment = Alignment.bottomCenter});

  final Annual annual;
  final Widget child;

  /// Replaces the ground art (the cover's mosaic).
  final Widget? artOverride;
  final bool showArt;
  final Alignment alignment;

  static Color tintOf(Annual a) => parseHex(a.topSeries.isEmpty ? null : a.topSeries.first.ambient?.tint, fallback: CineColors.ambientFallbackTint);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final top = annual.topSeries.isEmpty ? null : annual.topSeries.first;
    final tint = tintOf(annual);
    final cover = ref.watch(coverImageProvider);
    Widget art;
    if (artOverride != null) {
      art = artOverride!;
    } else if (showArt && top?.coverUrl != null) {
      art = DuotoneImage(image: cover(top!.coverUrl!), duo: parseHex(top.ambient?.duo));
    } else {
      art = const Stack(fit: StackFit.expand, children: [ColoredBox(color: CineColors.paper1), Grain()]);
    }
    return LayoutBuilder(builder: (context, box) {
      final safeW = math.min(box.maxWidth, box.maxHeight * 9 / 16);
      final safeH = math.min(box.maxHeight, box.maxWidth * 16 / 9);
      return Stack(fit: StackFit.expand, children: [
        art,
        const DecoratedBox(decoration: BoxDecoration(gradient: CineScrim.vignette)),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: const Alignment(0, -0.2), end: Alignment.bottomCenter, stops: CineScrim.kScrimStops, colors: [for (final a in CineScrim.kScrimAlpha) tint.withValues(alpha: a)]),
          ),
        ),
        Center(child: SizedBox(width: safeW, height: safeH, child: Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 28), child: Align(alignment: alignment, child: child)))),
      ],);
    },);
  }
}
