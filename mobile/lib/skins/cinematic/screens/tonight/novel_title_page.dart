import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/cine_grain.dart';
import 'package:manhwamaniacs/skins/cinematic/duotone.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/ambient_scope.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_image.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/layout/cine_credits.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/layout/cine_grid.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/cover_story_header.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/cover_story_parts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/cover_story_phone.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/tonight_layout.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The Bodoni initial on `paper.1`: the title-page plate of a book with no cover (cinematic 8.0.8).
class NovelPlate extends StatelessWidget {
  const NovelPlate({super.key, required this.data, required this.size});
  final CoverStoryData data;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final initial = data.cover.title.isEmpty ? '' : data.cover.title.characters.first;
    final hasCover = data.imageUrl != null;
    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(color: c.colorPaper1, border: Border.all(color: c.colorRule2)),
      child: hasCover
          ? CineImage(url: data.imageUrl, title: data.cover.title)
          : Center(child: ExcludeSemantics(child: CineLit(initial, CineFace.bodoni, size.width * 0.6, size.width * 0.6, wght: 800, color: c.colorInk60))),
    );
  }
}

/// The novel title page (cinematic 8.0.8): the cover at `blur.bleed` duotoned to `ambient.duo` as a
/// field (grain and Drift on the field only) with a square-cornered plate on it, the headline and
/// deck under `scrim.foot`. Phones: a 120 x 176 plate centred in the upper half; tablets: a
/// 168 x 248 plate in columns 5-8, the text and a byline in columns 1-4.
class NovelCoverLayout extends CoverLayout {
  NovelCoverLayout._(super.data, {required this.wide, required this.size, required this.height, required this.grid, required this.metrics, required this.plate, required this.plateAt, required this.credits});

  factory NovelCoverLayout.of(BuildContext context, CoverStoryData data, {List<(String, String)> credits = const []}) {
    final size = MediaQuery.sizeOf(context);
    final grid = CineGrid.of(context);
    final wide = size.width >= 600;
    final h = wide ? spreadHeight(size) : phoneCoverHeight(size);
    final width = wide ? grid.span(4) : size.width - grid.left - grid.right;
    final byline = wide && data.cover.author != null ? 40.0 : 0.0;
    final m = CoverTextMetrics.measure(context, data, width, wide: wide, extra: byline);
    final plate = wide ? const Size(168, 248) : const Size(120, 176);
    final at = wide
        ? Offset(grid.col(4) + (size.width - grid.col(4) - plate.width) / 2, (h - plate.height) / 2)
        : Offset((size.width - plate.width) / 2, (h * 0.5 - plate.height) / 2 + MediaQuery.viewPaddingOf(context).top / 2 + 16);
    return NovelCoverLayout._(data, wide: wide, size: size, height: h, grid: grid, metrics: m, plate: plate, plateAt: at, credits: credits);
  }

  final bool wide;
  final Size size;
  @override
  final double height;
  final CineGridSpec grid;
  final CoverTextMetrics metrics;
  final Size plate;
  final Offset plateAt;
  final List<(String, String)> credits;

  static const double bottomPad = 16;
  double get _extra => wide ? (credits.isEmpty ? 0 : ((credits.length + 1) ~/ 2) * 44 + 16) + 72 : 0;
  double get textTop => height - (wide ? 40 : bottomPad) - metrics.height - _extra;

  @override
  Rect get artRest => plateAt & plate;

  @override
  Widget field(BuildContext context) {
    final c = context.cine;
    final amb = CineAmbient.of(context);
    final image = CineImage(url: data.imageUrl, title: data.cover.title);
    return SizedBox(
      width: size.width,
      height: height,
      child: ClipRect(
        child: ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: c.blurBleed, sigmaY: c.blurBleed),
          child: CineDuotone(duo: amb.duo, child: CineGrain(child: CineDrift(child: image))),
        ),
      ),
    );
  }

  @override
  Widget art(BuildContext context) => CoverPlate(data: data, size: plate);

  @override
  Widget overlays(BuildContext context) {
    final c = context.cine;
    final tint = CineAmbient.of(context).tint;
    return Stack(fit: StackFit.expand, children: [
      DecoratedBox(decoration: BoxDecoration(gradient: c.scrimVignette)),
      DecoratedBox(decoration: BoxDecoration(gradient: scrimFoot(tint, textTop - 24, height))),
      if (wide) Positioned(left: grid.col(4), top: 0, bottom: 0, width: grid.span(2) + grid.gutter, child: DecoratedBox(decoration: BoxDecoration(gradient: c.scrimGutter))),
    ],);
  }

  @override
  Widget text(BuildContext context) {
    final c = context.cine;
    final byline = data.cover.author;
    return Stack(children: [
      Positioned(
        left: grid.left,
        width: wide ? grid.span(4) : size.width - grid.left - grid.right,
        bottom: 0,
        child: Padding(
          padding: EdgeInsets.only(bottom: wide ? 40 : bottomPad),
          child: CoverTextColumn(data: data, role: metrics.role, children: [
            if (wide && byline != null) ...[
              SizedBox(height: c.space3),
              CineLit('by $byline', CineFace.newsreader, 22, 28, italic: true),
              SizedBox(height: c.space3),
              Container(key: const Key('tonight-byline-rule'), width: 56, height: 1, color: c.colorInk100),
            ],
            if (wide && credits.isNotEmpty) ...[SizedBox(height: c.space4), CineSetIn(child: CineCredits(rows: credits))],
            if (wide) ...[SizedBox(height: c.space4), CoverActions(data: data, wide: true)],
          ],),
        ),
      ),
    ],);
  }
}

/// The plate in the novel title page's frozen frame: the cover, or the Bodoni initial.
class CoverPlate extends StatelessWidget {
  const CoverPlate({super.key, required this.data, required this.size});
  final CoverStoryData data;
  final Size size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size.width,
        height: size.height,
        child: data.imageUrl == null ? NovelPlate(data: data, size: size) : CoverArt(data: data, drift: false),
      );
}
