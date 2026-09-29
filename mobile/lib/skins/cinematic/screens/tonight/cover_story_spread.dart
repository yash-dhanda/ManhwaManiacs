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

/// The tablet spread (cinematic 8.0.9, 8.8): text on columns 1-4, the sharp cover on columns 5-8
/// at the full spread height, the same cover at `blur.bleed` duotoned to `ambient.duo` filling the
/// space to its left, `scrim.gutter` over art columns 5-6, grain and Drift on the art only.
class SpreadCoverLayout extends CoverLayout {
  SpreadCoverLayout._(super.data, {required this.size, required this.height, required this.grid, required this.metrics, required this.credits, required this.creditsHeight});

  factory SpreadCoverLayout.of(BuildContext context, CoverStoryData data, {List<(String, String)> credits = const []}) {
    final size = MediaQuery.sizeOf(context);
    final grid = CineGrid.of(context);
    final c = context.cine;
    final m = CoverTextMetrics.measure(context, data, grid.span(4), wide: true);
    // Credits (two rows a pair, 48 px each) and the 56 px action row, with their gaps.
    final creditsH = credits.isEmpty ? 0.0 : ((credits.length + 1) ~/ 2) * 44 + c.space4;
    return SpreadCoverLayout._(data, size: size, height: spreadHeight(size), grid: grid, metrics: m, credits: credits, creditsHeight: creditsH);
  }

  final Size size;
  @override
  final double height;
  final CineGridSpec grid;
  final CoverTextMetrics metrics;
  final List<(String, String)> credits;
  final double creditsHeight;

  static const double bottomPad = 40;
  static const double actionsHeight = 56 + 16;

  double get textBlockHeight => metrics.height + creditsHeight + actionsHeight;
  double get textTop => height - bottomPad - textBlockHeight;

  @override
  Rect get artRest => Rect.fromLTWH(grid.col(4), 0, size.width - grid.col(4), height);

  Widget _image(BuildContext context, {Alignment alignment = Alignment.center}) => CineImage(url: data.imageUrl, title: data.cover.title, alignment: alignment);

  @override
  Widget field(BuildContext context) {
    final c = context.cine;
    final amb = CineAmbient.of(context);
    return SizedBox(
      width: size.width,
      height: height,
      child: ClipRect(
        child: ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: c.blurBleed, sigmaY: c.blurBleed),
          child: CineDuotone(duo: amb.duo, child: CineGrain(child: _image(context))),
        ),
      ),
    );
  }

  @override
  Widget art(BuildContext context) => SizedBox(width: artRest.width, height: height, child: CoverArt(data: data));

  @override
  Widget overlays(BuildContext context) {
    final c = context.cine;
    final tint = CineAmbient.of(context).tint;
    return Stack(fit: StackFit.expand, children: [
      DecoratedBox(decoration: BoxDecoration(gradient: c.scrimVignette)),
      DecoratedBox(decoration: BoxDecoration(gradient: scrimFoot(tint, textTop - 24, height))),
      Positioned(left: grid.col(4), top: 0, bottom: 0, width: grid.span(2) + grid.gutter, child: DecoratedBox(decoration: BoxDecoration(gradient: c.scrimGutter))),
    ],);
  }

  @override
  Widget text(BuildContext context) => Stack(children: [
        Positioned(
          left: grid.left,
          width: grid.span(4),
          bottom: 0,
          child: Padding(
            padding: const EdgeInsets.only(bottom: bottomPad),
            child: CoverTextColumn(data: data, role: metrics.role, children: [
              if (credits.isNotEmpty) ...[
                SizedBox(height: context.cine.space4),
                CineSetIn(child: CineCredits(rows: credits)),
              ],
              SizedBox(height: context.cine.space4),
              CoverActions(data: data, wide: true),
            ],),
          ),
        ),
      ],);
}
