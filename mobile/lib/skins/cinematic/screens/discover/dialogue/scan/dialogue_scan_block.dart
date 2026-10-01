import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/ocr/controllers/ocr_run_controller.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/skin_haptics.dart';

/// READING THE DIALOGUE: drives `ocrRunControllerProvider`; renders every run
/// phase and nothing while idle. Mounted by Downloads (mobile/17) and the
/// recap's `Scan saved chapters` (mobile/19).
class DialogueScanBlock extends ConsumerWidget {
  const DialogueScanBlock({super.key, this.preview});

  /// Test/gallery hook; production reads the controller.
  final OcrRunState? preview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.cine;
    final OcrRunState s = preview ?? ref.watch(ocrRunControllerProvider);
    if (preview == null) {
      ref.listen(ocrRunControllerProvider, (prev, next) {
        if (prev?.phase == next.phase) return;
        if (next.phase == OcrRunPhase.done) {
          ref.read(skinHapticsProvider).fire(HapticEvent.success);
        } else if (next.phase == OcrRunPhase.failed) {
          ref.read(skinHapticsProvider).fire(HapticEvent.error);
        }
      });
    }
    if (s.phase == OcrRunPhase.idle) return const SizedBox.shrink();

    Widget line(String text, {Color? color}) => Text(text,
        style: cineText(context, t.typeUi, color: color ?? t.colorInk100),);

    final children = <Widget>[
      const Kicker('Reading the dialogue'),
      const SizedBox(height: CineSpace.s2),
    ];
    switch (s.phase) {
      case OcrRunPhase.recognizing:
      case OcrRunPhase.paused:
        children.addAll([
          Semantics(
              liveRegion: true,
              child: line('Page ${s.completedPages + 1} of ${s.totalPages}'),),
          const SizedBox(height: CineSpace.s2),
          _Rule(progress: s.progress),
          if (s.phase == OcrRunPhase.paused)
            Padding(
              padding: const EdgeInsets.only(top: CineSpace.s2),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                        text: 'NOTE  ',
                        style: cineText(context, t.typeKicker,
                            color: t.colorSpot,),),
                    TextSpan(
                      text:
                          'Text extraction pauses in the background; keep the app open.',
                      style:
                          cineText(context, t.typeCaption, color: t.colorInk60),
                    ),
                  ],
                ),
              ),
            ),
        ]);
      case OcrRunPhase.uploading:
        children.addAll([
          Semantics(liveRegion: true, child: line('Saving the transcript…')),
          const SizedBox(height: CineSpace.s2),
          const IndeterminateRule(),
        ]);
      case OcrRunPhase.done:
        children.addAll([
          Semantics(
              liveRegion: true,
              child: line('${s.wordCount} words are now searchable.'),),
          CineButton(
              label: 'Search dialogue',
              variant: CineButtonVariant.quiet,
              onPressed: () => context.go(Routes.dialogue()),),
        ]);
      case OcrRunPhase.cancelled:
        children
            .add(Semantics(liveRegion: true, child: line('Scan cancelled.')));
      case OcrRunPhase.failed:
        children.addAll([
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                    text: 'CORRECTION  ',
                    style:
                        cineText(context, t.typeKicker, color: t.colorProof),),
                TextSpan(
                    text: s.message ?? "The scan didn't finish.",
                    style: cineText(context, t.typeCaption),),
              ],
            ),
          ),
          if (s.chapter != null)
            CineButton(
              label: 'Try again',
              variant: CineButtonVariant.quiet,
              onPressed: () => ref
                  .read(ocrRunControllerProvider.notifier)
                  .runChapter(id: s.chapter!),
            ),
        ]);
      case OcrRunPhase.idle:
        break;
    }
    if (s.isBusy) {
      children.add(CineButton(
          label: 'Cancel',
          variant: CineButtonVariant.quiet,
          onPressed: () =>
              ref.read(ocrRunControllerProvider.notifier).cancel(),),);
    }
    return Padding(
      padding: const EdgeInsets.all(CineSpace.s4),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children,),
    );
  }
}

/// 2 px determinate rule: `rule.1` track, `spot` fill, width 240 ms `easeSet`.
class _Rule extends StatelessWidget {
  const _Rule({required this.progress});

  final double? progress;

  @override
  Widget build(BuildContext context) {
    final t = context.cine;
    if (progress == null) return const IndeterminateRule();
    return SizedBox(
      height: 2,
      child: LayoutBuilder(
        builder: (context, box) => Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: t.colorRule1)),
            AnimatedContainer(
              duration: CineDur.line,
              curve: CineCurves.easeSet,
              width: box.maxWidth * progress!.clamp(0, 1),
              color: t.colorSpot,
            ),
          ],
        ),
      ),
    );
  }
}
