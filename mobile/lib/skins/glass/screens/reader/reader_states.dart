import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/core/error/not_available.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_frames.dart';
import 'package:manhwamaniacs/skins/back_parent.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/lens_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/object_lens.dart';
import 'package:manhwamaniacs/skins/glass/shell/glass_back_button.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// The loading and failure states stand in for the reader's chrome: the nav row's Back at safe-top + 8, and Android back to the
/// series on a cold open (nothing beneath).
Widget _withBack(BuildContext context, Widget child) => SkinBackFallback(
      glass: true,
      child: Stack(children: [
        Positioned.fill(child: child),
        Positioned(top: MediaQuery.viewPaddingOf(context).top + 8, left: GlassFrame.screenMargin(context), child: const GlassBackButton()),
      ],),
    );

/// Loading a chapter (glass 8.14.6): three page-shaped skeletons (2:3, at most 420 wide) with the sheen and a `glassThin` capsule
/// "Loading chapter 143"; after 3 s it adds "This source can be slow".
class GlassReaderLoading extends StatefulWidget {
  const GlassReaderLoading({super.key, this.chapterLabel, this.slowAfter = const Duration(seconds: 3)});
  final String? chapterLabel;
  final Duration slowAfter;

  @override
  State<GlassReaderLoading> createState() => _GlassReaderLoadingState();
}

class _GlassReaderLoadingState extends State<GlassReaderLoading> {
  Timer? _slow;
  bool _isSlow = false;

  @override
  void initState() {
    super.initState();
    _slow = Timer(widget.slowAfter, () {
      if (mounted) setState(() => _isSlow = true);
    });
  }

  @override
  void dispose() {
    _slow?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = math.min(size.width - 32, 420.0);
    final label = widget.chapterLabel == null ? 'Loading chapter' : 'Loading ${widget.chapterLabel!.toLowerCase()}';
    final text = _isSlow ? '$label · This source can be slow' : label;
    final capW = measureText(context, text, roleStyle(context, gt.typeFootnote, onGlass: true, wght: 600)).width + 32;
    return _withBack(context, ColoredBox(
      color: const Color(0xFF000000),
      child: Stack(
        children: [
          GlassSkeletonGroup(
            label: label,
            child: ListView(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 16),
              children: [
                for (var i = 0; i < 3; i++)
                  Center(
                    child: Container(
                      width: w,
                      height: w * 1.5,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(color: const Color(0xFF0B0B0F), borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            top: MediaQuery.viewPaddingOf(context).top + 60,
            left: 0,
            right: 0,
            child: Center(
              child: SkinGlass(
                size: Size(math.min(capW, size.width - 32), 36),
                tier: GlassTierId.t2,
                layer: GlassLayerKind.overlays,
                debugLabel: 'reader loading capsule',
                child: Center(child: GlassText(text, role: gt.typeFootnote, wght: 600, onGlass: true, maxLines: 1)),
              ),
            ),
          ),
        ],
      ),
    ),);
  }
}

/// A reader that did not open (glass 8.14.6): the error lens with the server's message, Try again and Go to series; or "This
/// chapter has no pages" with Go to series; unavailable content (glass 8.0.8); or the gate closed on a mature series.
class GlassReaderFailure extends StatelessWidget {
  const GlassReaderFailure({super.key, required this.failure, this.gated = false, this.onHome});
  final ReaderFailure failure;
  final bool gated;
  final VoidCallback? onHome;

  @override
  Widget build(BuildContext context) {
    final Widget lens;
    if (gated) {
      lens = GlassObjectLens(
        situation: LensSituation.unavailable,
        title: "This isn't available on this profile",
        tone: GlassLensTone.error,
        primary: LensAction('Back home', onHome ?? failure.back),
      );
    } else if (failure.error != null && notAvailableKind(failure.error!) != null) {
      // Unavailable content (glass 8.0.8): the specific line and Back. Gated 18+ answers the same codes, so nothing reveals it.
      lens = GlassObjectLens(
        situation: LensSituation.unavailable,
        title: "This isn't here any more",
        description: switch (notAvailableKind(failure.error!)!) {
          NotAvailableKind.source => 'This source was removed from the server.',
          NotAvailableKind.series => "The source doesn't have this series any more.",
          NotAvailableKind.notBrowsable => "This source can't be browsed; open its series from search or your library.",
        },
        primary: LensAction('Back', failure.back),
      );
    } else if (failure.noPages) {
      lens = GlassObjectLens(situation: LensSituation.loadError, title: 'This chapter has no pages', primary: LensAction('Go to series', failure.back));
    } else {
      final e = failure.error;
      lens = GlassObjectLens(
        situation: LensSituation.loadError,
        title: "Couldn't open this chapter",
        description: e?.userMessage,
        tone: GlassLensTone.error,
        primary: LensAction('Try again', failure.retry),
        secondary: LensAction('Go to series', failure.back),
      );
    }
    return _withBack(context, ColoredBox(color: const Color(0xFF000000), child: Center(child: lens)));
  }
}
