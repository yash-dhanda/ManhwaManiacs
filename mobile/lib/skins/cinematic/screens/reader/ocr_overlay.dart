import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/downloads/models/chapter_identity.dart';
import 'package:manhwamaniacs/features/ocr/models/ocr_search_result.dart';
import 'package:manhwamaniacs/features/ocr/models/page_text.dart';
import 'package:manhwamaniacs/features/ocr/providers/ocr_providers.dart';
import 'package:manhwamaniacs/features/ocr/utils/ocr_boxes.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/bubble_pulse.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// One line of a page's transcript: the text and, when the API sent geometry, its bubble.
class DialogueLine {
  const DialogueLine(this.text, this.box);
  final String text;
  final OcrTextBox? box;
}

/// A page's lines: one per box that has text, else one per non-empty line of the page text.
List<DialogueLine> dialogueLines(PageText p) {
  final boxed = [for (final b in p.boxes) if (b.text.trim().isNotEmpty) DialogueLine(b.text.trim(), b)];
  if (boxed.isNotEmpty) return boxed;
  return [for (final l in p.text.split('\n')) if (l.trim().isNotEmpty) DialogueLine(l.trim(), null)];
}

/// What the per-page overlay draws now (cinematic 8.14.12, 8.14.13): the outlines of a page's
/// bubbles (`Show dialogue on this page`), a pulse on one bubble (a tapped transcript line) and the
/// popover with the text of a tapped outline.
class OcrOverlayController extends ChangeNotifier {
  ({String chapter, int page})? _outlines;
  ({String chapter, int page, OcrTextBox box, int nonce})? _pulse;
  ({String chapter, int page, OcrTextBox box})? _popover;
  int _nonce = 0;

  ({String chapter, int page})? get outlines => _outlines;
  ({String chapter, int page, OcrTextBox box, int nonce})? get pulseTarget => _pulse;
  ({String chapter, int page, OcrTextBox box})? get popover => _popover;

  bool get active => _outlines != null || _popover != null;

  void showOutlines(String chapter, int page) {
    _outlines = (chapter: chapter, page: page);
    _popover = null;
    notifyListeners();
  }

  void hideOutlines() {
    if (_outlines == null && _popover == null) return;
    _outlines = null;
    _popover = null;
    notifyListeners();
  }

  void pulse(String chapter, int page, OcrTextBox box) {
    _pulse = (chapter: chapter, page: page, box: box, nonce: ++_nonce);
    notifyListeners();
  }

  void endPulse() {
    _pulse = null;
    notifyListeners();
  }

  void openPopover(String chapter, int page, OcrTextBox box) {
    _popover = (chapter: chapter, page: page, box: box);
    notifyListeners();
  }

  void closePopover() {
    if (_popover == null) return;
    _popover = null;
    notifyListeners();
  }
}

/// The overlay slot content of one page: cheap when nothing targets the page.
class OcrPageOverlay extends ConsumerWidget {
  const OcrPageOverlay({super.key, required this.controller, required this.sourceId, required this.seriesKey, required this.chapterKey, required this.page, required this.size});

  final OcrOverlayController controller;
  final String sourceId, seriesKey, chapterKey;
  final int page;
  final Size size;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final out = controller.outlines;
          final pulse = controller.pulseTarget;
          final pop = controller.popover;
          final showOut = out != null && out.chapter == chapterKey && out.page == page;
          final showPulse = pulse != null && pulse.chapter == chapterKey && pulse.page == page;
          final showPop = pop != null && pop.chapter == chapterKey && pop.page == page;
          if (!showOut && !showPulse && !showPop) return const SizedBox.shrink();
          final c = context.cine;
          final children = <Widget>[];
          if (showOut) {
            final texts = ref.watch(ocrChapterTextProvider((sourceId: sourceId, seriesKey: seriesKey, chapterKey: chapterKey))).valueOrNull;
            final pageText = texts?.where((t) => t.page == page).firstOrNull;
            for (final b in pageText?.boxes ?? const <OcrTextBox>[]) {
              final r = boxInPage(b, size);
              if (r == null) continue;
              children.add(Positioned.fromRect(
                rect: r,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => controller.openPopover(chapterKey, page, b),
                  child: DecoratedBox(key: const ValueKey('ocr-outline'), decoration: BoxDecoration(border: Border.all(color: c.colorSpot))),
                ),
              ),);
            }
          }
          if (showPulse) {
            final f = boxFraction(pulse.box);
            if (f != null) {
              children.add(Positioned.fill(
                child: BubblePulse(
                  key: ValueKey('pulse-${pulse.nonce}'),
                  box: OcrBox(x: f.left, y: f.top, w: f.width, h: f.height),
                  onDone: controller.endPulse,
                ),
              ),);
            }
          }
          if (showPop) {
            final r = boxInPage(pop.box, size);
            if (r != null) {
              final below = r.bottom + 8 + 96 < size.height;
              children.add(Positioned(
                left: r.left.clamp(0.0, (size.width - 200).clamp(0.0, double.infinity)),
                top: below ? r.bottom + 8 : (r.top - 8 - 96).clamp(0.0, double.infinity),
                width: 200,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: controller.closePopover,
                  child: Container(
                    key: const ValueKey('ocr-popover'),
                    padding: const EdgeInsets.all(8),
                    color: c.colorPaper2,
                    child: CineRoleText(pop.box.text, c.typeBody, color: c.colorInk100),
                  ),
                ),
              ),);
            }
          }
          return Stack(clipBehavior: Clip.none, children: children);
        },
      );
}

/// A chapter identity for the OCR providers.
ChapterIdentity chapterIdentityOf(String sourceId, String seriesKey, String chapterKey) => (sourceId: sourceId, seriesKey: seriesKey, chapterKey: chapterKey);
