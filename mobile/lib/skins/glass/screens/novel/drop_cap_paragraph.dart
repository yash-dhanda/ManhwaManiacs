import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/features/novels/engine/novel_paragraph_layout.dart';
import 'package:manhwamaniacs/features/novels/models/novel_typography.dart';
import 'package:manhwamaniacs/features/novels/utils/novel_book.dart';
import 'package:manhwamaniacs/features/novels/utils/speaker_slots.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/glass_paragraph.dart';

/// The first paragraph with its drop cap (D7): a `Row` of the cap and an `Expanded` piece holding the text up to
/// [NovelParagraphLayout.dropCapSplit], then a full-width piece with the rest, laid out exactly as the paginator does. The three pieces
/// sit in the reader's one `SelectionArea` (selecting across them copies the word whole) and in one `MergeSemantics` labelled with the
/// whole paragraph, so a screen reader reads the word whole too.
class GlassDropCapParagraph extends StatelessWidget {
  const GlassDropCapParagraph({
    super.key,
    required this.paragraph,
    required this.dropCap,
    required this.type,
    required this.style,
    required this.ink,
    required this.width,
    this.end,
    this.runs = const [],
    this.decorations = const [],
    this.onRunTap,
    this.locale,
    this.textKey,
    this.semanticsLabel,
    this.repaint,
  });

  final String paragraph;
  final DropCap dropCap;
  final NovelType type;
  final TextStyle style;
  final Color ink;
  final double width;

  /// A paged slice ends here (paragraph offset).
  final int? end;
  final List<SpeakerRun> runs;
  final List<GlassParagraphDecoration> decorations;
  final void Function(SpeakerRun run, Rect globalRect)? onRunTap;
  final Locale? locale;
  final GlobalKey? textKey;
  final String? semanticsLabel;

  /// Repaints the decorations without a rebuild (the listen band).
  final Listenable? repaint;

  @override
  Widget build(BuildContext context) {
    final spec = type.dropCapSpec ?? kGlassDropCap;
    final capStyle = spec.at(type.fontSize, ink);
    final lead = paragraph.indexOf(dropCap.initial);
    final restStart = lead + dropCap.initial.length;
    final rest = paragraph.substring(restStart);
    final cap = TextPainter(text: TextSpan(text: dropCap.initial, style: capStyle), textDirection: TextDirection.ltr, textScaler: TextScaler.noScaling)..layout();
    final gap = spec.gapEm * (capStyle.fontSize ?? type.fontSize * 3);
    final capW = cap.width;
    final capBaseline = cap.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    cap.dispose();
    final split = restStart + NovelParagraphLayout.dropCapSplit(rest, style, width: width, capAdvancePlusGap: capW + gap, justify: type.justify, lines: spec.lines);
    final stop = end ?? paragraph.length;
    // The cap's baseline sits on the last line beside it (the third, or fewer for a short paragraph).
    final narrow = TextPainter(text: TextSpan(text: paragraph.substring(restStart, math.min(split, stop)), style: style), textDirection: TextDirection.ltr, textScaler: TextScaler.noScaling)
      ..layout(maxWidth: math.max(1, width - capW - gap));
    final m = narrow.computeLineMetrics();
    final baseline = m.isEmpty ? capBaseline : m[math.min(spec.lines, m.length) - 1].baseline;
    // The paginator's layout (NovelParagraphLayout): with more lines than the cap spans, the rest starts at the tight bottom of the
    // last narrow line; otherwise the paragraph is at least as tall as the cap's lines.
    final double rowHeight;
    if (split < stop) {
      final boxes = narrow.getBoxesForSelection(TextSelection(baseOffset: 0, extentOffset: narrow.plainText.length));
      rowHeight = boxes.isEmpty ? narrow.height : boxes.map((b) => b.bottom).reduce(math.max);
    } else {
      rowHeight = math.max(narrow.height, spec.lines * type.fontSize * type.lineHeight);
    }
    narrow.dispose();
    final align = type.justify ? TextAlign.justify : TextAlign.start;
    return MergeSemantics(
      child: Semantics(
        label: semanticsLabel ?? paragraph,
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: rowHeight,
                child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: math.max(0, baseline - capBaseline)),
                    child: Text(dropCap.initial, style: capStyle.copyWith(inherit: false), textScaler: TextScaler.noScaling),
                  ),
                  SizedBox(width: gap),
                  Expanded(
                    child: OverflowBox(
                      alignment: Alignment.topLeft,
                      maxHeight: double.infinity,
                      child: GlassTextPiece(
                      key: const ValueKey('dropcap-beside'),
                      textKey: textKey,
                      paragraph: paragraph,
                      start: restStart,
                      end: math.min(split, stop),
                      style: style,
                      align: align,
                      runs: runs,
                      decorations: decorations,
                      onRunTap: onRunTap,
                      locale: locale,
                      repaint: repaint,
                    ),
                    ),
                  ),
                ],
              ),
              ),
              if (split < stop)
                GlassTextPiece(
                  key: const ValueKey('dropcap-rest'),
                  paragraph: paragraph,
                  start: split,
                  end: stop,
                  style: style,
                  align: align,
                  runs: runs,
                  decorations: decorations,
                  onRunTap: onRunTap,
                  locale: locale,
                  repaint: repaint,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
