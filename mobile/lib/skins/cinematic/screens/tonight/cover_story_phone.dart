import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/ambient_scope.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/layout/cine_grid.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/cover_story_header.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/cover_story_parts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/tonight_layout.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// The measured text block of a cover story: kicker, headline (stepped down to fit three lines),
/// deck. Its height fixes where `scrim.foot` turns solid.
class CoverTextMetrics {
  const CoverTextMetrics({required this.role, required this.height});
  final CineTextRole role;
  final double height;

  static CoverTextMetrics measure(BuildContext context, CoverStoryData d, double width, {bool wide = false, double extra = 0}) {
    final c = context.cine;
    final role = fitCoverRole(context, d.feed.headline, width, maxLines: 3, wide: wide);
    final kicker = measureText(context, d.kicker, c.typeKicker, width, maxLines: 1);
    final head = measureText(context, d.feed.headline, role, width, maxLines: 3);
    final deck = d.feed.deck.isEmpty ? 0.0 : measureText(context, d.feed.deck, c.typeDeck, width, maxLines: 2) + 8;
    return CoverTextMetrics(role: role, height: kicker + 8 + head + deck + extra);
  }
}

/// The phone cover story (cinematic 8.8): the cover full-bleed at 4:5 (height
/// `min(width x 1.25, 0.70 x screen)`), `scrim.foot` into `ambient.tint`, the vignette, grain and
/// Drift on the art, and the kicker, typed headline and deck on the solid end colour.
class PhoneCoverLayout extends CoverLayout {
  PhoneCoverLayout._(super.data, {required this.size, required this.height, required this.metrics, required this.left, required this.right});

  factory PhoneCoverLayout.of(BuildContext context, CoverStoryData data) {
    final size = MediaQuery.sizeOf(context);
    final grid = CineGrid.of(context);
    final h = phoneCoverHeight(size);
    final m = CoverTextMetrics.measure(context, data, size.width - grid.left - grid.right);
    return PhoneCoverLayout._(data, size: size, height: h, metrics: m, left: grid.left, right: grid.right);
  }

  final Size size;
  @override
  final double height;
  final CoverTextMetrics metrics;
  final double left, right;

  /// The block's bottom padding, and the y where the scrim reaches alpha 1 (24 px above the text).
  static const double bottomPad = 16;
  double get textTop => height - bottomPad - metrics.height;

  @override
  Rect get artRest => Rect.fromLTWH(0, 0, size.width, height);

  @override
  Widget art(BuildContext context) => SizedBox(width: size.width, height: height, child: CoverArt(data: data));

  @override
  Widget overlays(BuildContext context) {
    final tint = CineAmbient.of(context).tint;
    return Stack(fit: StackFit.expand, children: [
      const DecoratedBox(decoration: BoxDecoration(gradient: CineScrim.vignette)),
      DecoratedBox(decoration: BoxDecoration(gradient: scrimFoot(tint, textTop - 24, height))),
    ],);
  }

  @override
  Widget text(BuildContext context) => Stack(children: [
        Positioned(
          left: left,
          right: right,
          bottom: 0,
          child: Padding(
            padding: const EdgeInsets.only(bottom: bottomPad),
            child: CoverTextColumn(data: data, role: metrics.role),
          ),
        ),
      ],);
}

/// Kicker, headline and deck in reading order.
class CoverTextColumn extends StatelessWidget {
  const CoverTextColumn({super.key, required this.data, required this.role, this.children = const []});
  final CoverStoryData data;
  final CineTextRole role;

  /// Extra blocks after the deck (credits, actions on a spread).
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      CoverKicker(data: data),
      SizedBox(height: c.space2),
      TonightHeadline(data: data, role: role),
      if (data.feed.deck.isNotEmpty) ...[SizedBox(height: c.space2), TonightDeck(text: data.feed.deck)],
      ...children,
    ],);
  }
}
