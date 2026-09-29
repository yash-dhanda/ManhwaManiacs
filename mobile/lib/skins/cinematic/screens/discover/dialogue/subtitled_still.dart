import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/ocr/models/ocr_search_result.dart';
import 'package:manhwamaniacs/features/ocr/providers/dialogue_still_provider.dart';
import 'package:manhwamaniacs/features/ocr/utils/still_crop.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_extras.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// The 16:9 still: the page image cropped in layout around the matched box,
/// darkened to brightness 0.8, the matched line set as a subtitle on
/// `color.onart` over the lower third. [rack] is false past the 12th still on
/// a screen (those Develop with a plain fade).
class SubtitledStill extends ConsumerWidget {
  const SubtitledStill({super.key, required this.hit, required this.rack});

  final OcrSearchResult hit;
  final bool rack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.cine;
    final page = hit.page;
    if (page == null) return const SizedBox.shrink();
    final still =
        ref.watch(dialogueStillProvider((chapter: hit.identity, page: page)));
    final subtitle = _Subtitle(hit: hit);
    final Widget image = still.when(
      loading: () => ColoredBox(color: t.colorPaper1),
      error: (_, __) => const _Broken(),
      data: (s) {
        if (s == null || (s.file == null && s.bytes == null)) {
          return const _Broken();
        }
        final aspect = s.aspect ?? 0.7;
        final w = stillCropWindow(hit.box, aspect);
        final provider = s.file != null
            ? FileImage(s.file!) as ImageProvider
            : MemoryImage(s.bytes!);
        return LayoutBuilder(
          builder: (context, box) {
            final pageW = box.maxWidth / w.width;
            final pageH = pageW / aspect;
            return ColorFiltered(
              colorFilter: const ColorFilter.matrix([
                0.8, 0, 0, 0, 0, //
                0, 0.8, 0, 0, 0,
                0, 0, 0.8, 0, 0,
                0, 0, 0, 1, 0,
              ]),
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  maxWidth: double.infinity,
                  maxHeight: double.infinity,
                  child: Transform.translate(
                    offset: Offset(-w.left * pageW, -w.top * pageH),
                    child: SizedBox(
                      width: pageW,
                      height: pageH,
                      child: Image(
                          image: provider,
                          fit: BoxFit.fill,
                          gaplessPlayback: true,),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    final reduced = cineReduced(context);
    final stack = AspectRatio(
      aspectRatio: 16 / 9,
      child: Semantics(
        image: true,
        label: still.hasError || still.valueOrNull == null && !still.isLoading
            ? 'Page didn\'t load'
            : null,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _Rack(rack: rack && !reduced, reduced: reduced, child: image),
            Positioned(left: 0, right: 0, bottom: 0, child: subtitle),
          ],
        ),
      ),
    );
    return stack;
  }
}

class _Rack extends StatelessWidget {
  const _Rack({required this.rack, required this.reduced, required this.child});

  final bool rack;
  final bool reduced;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (reduced) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: CineDur.beat,
        builder: (_, v, c) => Opacity(opacity: v, child: c),
        child: child,
      );
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: rack ? CineDur.rack : CineDur.beat,
      curve: CineCurves.settle,
      builder: (_, v, c) {
        if (!rack) return Opacity(opacity: v, child: c);
        final blur = 14 * (1 - v);
        return Transform.scale(
          scale: 1.03 - 0.03 * v,
          child: Opacity(
            opacity: 0.6 + 0.4 * v,
            child: blur < 0.1
                ? c
                : ImageFiltered(
                    imageFilter:
                        ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                    child: c,
                  ),
          ),
        );
      },
      child: child,
    );
  }
}

class _Broken extends StatelessWidget {
  const _Broken();

  @override
  Widget build(BuildContext context) {
    final t = context.cine;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: t.colorPaper1),
        Positioned(
          right: 8,
          bottom: 8,
          // TODO(icons): image-broken is not in the generated glyph subset.
          child:
              Icon(Icons.broken_image_outlined, size: 16, color: t.colorInk60),
        ),
      ],
    );
  }
}

class _Subtitle extends StatelessWidget {
  const _Subtitle({required this.hit});

  final OcrSearchResult hit;

  @override
  Widget build(BuildContext context) {
    final t = context.cine;
    return ColoredBox(
      color: t.colorOnart,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Center(
          child: SweepHighlightText(
            hit.snippet,
            style: cineText(context, t.typeBody),
            maxLines: 2,
            maxScale: 1.3,
          ),
        ),
      ),
    );
  }
}
