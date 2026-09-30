import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/ocr/controllers/ocr_run_controller.dart';
import 'package:manhwamaniacs/features/ocr/models/page_text.dart';
import 'package:manhwamaniacs/features/ocr/providers/ocr_providers.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/hit.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_progress.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/ocr_overlay.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// DIALOGUE (cinematic 8.14.12): the chapter's transcript as subtitle lines per page. A tap on a
/// line scrolls there and pulses that bubble twice through the page overlay. No text, a 404 or an
/// empty transcript reads "Dialogue isn't indexed for this chapter." and, for a chapter saved on
/// this device, offers `Scan it on your phone`.
class DialogueTab extends ConsumerWidget {
  const DialogueTab({
    super.key,
    required this.engine,
    required this.overlay,
    required this.sourceId,
    required this.seriesKey,
    required this.chapterKey,
    required this.saved,
    this.chapterNumber,
  });

  final ReaderEngine engine;
  final OcrOverlayController overlay;
  final String sourceId, seriesKey, chapterKey;
  final bool saved;
  final double? chapterNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.cine;
    final id = chapterIdentityOf(sourceId, seriesKey, chapterKey);
    final text = ref.watch(ocrChapterTextProvider(id));
    final pages = text.valueOrNull;
    if (text.isLoading && pages == null) {
      return const Center(child: CineLeaderDial(size: 24));
    }
    if (text.hasError) {
      return Padding(
        padding: EdgeInsets.all(c.space4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CineRoleText('CORRECTION', c.typeKicker, color: c.colorProof),
          CineRoleText("This didn't load.", c.typeUi),
          CineButton(label: 'Try again', variant: CineButtonVariant.quiet, size: CineButtonSize.sm, onPressed: () => ref.invalidate(ocrChapterTextProvider(id))),
        ],),
      );
    }
    final withText = [for (final p in pages ?? const <PageText>[]) if (!p.isEmpty) p]..sort((a, b) => a.page.compareTo(b.page));
    if (withText.isEmpty) {
      final run = ref.watch(ocrRunControllerProvider);
      return Padding(
        padding: EdgeInsets.all(c.space4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CineRoleText("Dialogue isn't indexed for this chapter.", c.typeCaption, color: c.colorInk60),
          if (saved && ref.watch(ocrFeatureVisibleProvider))
            CineButton(
              label: run.isBusy && run.chapter == id ? 'SCANNING ${run.completedPages} OF ${run.totalPages}' : 'Scan it on your phone',
              variant: CineButtonVariant.quiet,
              size: CineButtonSize.sm,
              onPressed: run.isBusy ? null : () => unawaited(ref.read(ocrRunControllerProvider.notifier).runChapter(id: id, chapterNumber: chapterNumber)),
            ),
        ],),
      );
    }
    final reduced = MediaQuery.disableAnimationsOf(context);
    return ListView(
      padding: EdgeInsets.all(c.space4),
      children: [
        for (final p in withText) ...[
          Padding(padding: EdgeInsets.only(top: c.space3), child: CineRoleText('p. ${p.page}', c.typeFolio, color: c.colorSpot)),
          for (final l in dialogueLines(p))
            CinePressable(
              onTap: () {
                engine.jumpToPage(p.page, glide: !reduced);
                if (l.box != null) overlay.pulse(chapterKey, p.page, l.box!);
              },
              builder: (context, st) => ConstrainedBox(
                constraints: BoxConstraints(minHeight: cineHitMin(context)),
                child: Align(alignment: Alignment.centerLeft, child: CineRoleText(l.text, c.typeBody, color: c.colorInk100)),
              ),
            ),
        ],
      ],
    );
  }
}
