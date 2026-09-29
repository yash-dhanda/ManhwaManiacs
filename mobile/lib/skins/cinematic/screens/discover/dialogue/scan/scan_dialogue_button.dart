import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/downloads/models/chapter_identity.dart';
import 'package:manhwamaniacs/features/ocr/controllers/ocr_run_controller.dart';
import 'package:manhwamaniacs/features/ocr/providers/ocr_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/cine_glyphs.g.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// The chapter-row action `Scan dialogue` for a saved manga chapter when OCR
/// is available. Busy: a leader dial; indexed: the `TEXT` badge and a
/// re-scan confirmation.
class ScanDialogueButton extends ConsumerWidget {
  const ScanDialogueButton({super.key, required this.chapter, this.chapterNumber});

  final ChapterIdentity chapter;
  final double? chapterNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.cine;
    if (!ref.watch(ocrFeatureVisibleProvider)) return const SizedBox.shrink();
    final run = ref.watch(ocrRunControllerProvider);
    final scanning = run.isBusy &&
        run.chapter?.sourceId == chapter.sourceId &&
        run.chapter?.seriesKey == chapter.seriesKey &&
        run.chapter?.chapterKey == chapter.chapterKey;
    final indexed = ref
            .watch(ocrCoverageProvider((sourceId: chapter.sourceId, seriesKey: chapter.seriesKey)))
            .valueOrNull
            ?.covers(chapter.chapterKey) ??
        false;

    Future<void> scan() async {
      if (indexed) {
        final again = await showDialog<bool>(
          context: context,
          barrierColor: CineScrim.modal,
          builder: (context) => AlertDialog(
            backgroundColor: t.colorPaper2,
            shape: const RoundedRectangleBorder(),
            title: Text('Scan this chapter again?', style: cineText(context, t.typeSubhead)),
            actions: [
              QuietButton('Cancel', onPressed: () => Navigator.of(context).pop(false)),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Scan again', style: cineText(context, t.typeUi, color: t.colorSpot)),
              ),
            ],
          ),
        );
        if (again != true) return;
      }
      await ref
          .read(ocrRunControllerProvider.notifier)
          .runChapter(id: chapter, chapterNumber: chapterNumber);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (indexed)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(border: Border.all(color: t.colorInk60)),
            child: Text('TEXT', style: cineText(context, t.typeMicro, color: t.colorInk60)),
          ),
        Semantics(
          button: true,
          label: 'Scan dialogue',
          excludeSemantics: true,
          child: SizedBox(
            width: 48,
            height: 48,
            child: scanning
                ? const Center(child: LeaderDial())
                : IconButton(
                    onPressed: run.isBusy ? null : scan,
                    icon: Icon(CineGlyphs.bubbleSearchRegular, size: 20, color: t.colorInk100),
                  ),
          ),
        ),
      ],
    );
  }
}
