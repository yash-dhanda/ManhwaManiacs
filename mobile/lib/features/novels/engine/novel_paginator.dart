import 'dart:math' as math;
import 'package:flutter/painting.dart';

import 'package:manhwamaniacs/features/novels/engine/novel_paragraph_layout.dart';
import 'package:manhwamaniacs/features/novels/models/novel_typography.dart';
import 'package:manhwamaniacs/features/novels/utils/novel_book.dart';
import 'package:manhwamaniacs/features/novels/utils/novel_progress.dart';

/// Height of the page folio band in paged mode (cinematic 8.15.4).
const double kNovelFolioBand = 40;

/// A piece of one paragraph on a page: text offsets [startChar, endChar). [continues] is true when
/// the paragraph carries on after this slice (it was split at a line); a slice with
/// `startChar > 0` is a continuation and is set with no indent and no drop cap.
class NovelPageSlice {
  const NovelPageSlice(this.paragraphIndex, this.startChar, this.endChar, {this.continues = false, this.sceneBreak = false});
  final int paragraphIndex, startChar, endChar;
  final bool continues, sceneBreak;

  bool get isContinuation => startChar > 0;

  @override
  String toString() => 'Slice($paragraphIndex, $startChar-$endChar${continues ? ', continues' : ''})';
}

/// The column width for [measureCh] characters: `min(measure x the advance of "0" in the body
/// style, viewportWidth - 2 x margin)`.
double novelColumnWidthCh(NovelType type, {required double viewportWidth, required double margin}) {
  final tp = novelZeroAdvance(type);
  return math.min(type.measure * tp, viewportWidth - 2 * margin);
}

/// Splits the chapter into pages that fit [pageHeight] exactly by whole lines.
///
/// Every character of every paragraph appears exactly once, in order. A paragraph that does not
/// fit is split after the last whole line that fits (its continuation starts the next page with no
/// indent); a scene break never splits; the opener ([openerHeight]) takes the first page's top.
/// Always returns at least one page.
List<List<NovelPageSlice>> paginateNovelText({
  required List<String> paragraphs,
  required NovelType type,
  required double width,
  required double pageHeight,
  double openerHeight = 0,
  Color ink = const Color(0xFF000000),
}) {
  final pages = <List<NovelPageSlice>>[];
  var page = <NovelPageSlice>[];
  var used = openerHeight;
  final gap = type.paragraphSpacing * type.fontSize;

  void turn() {
    pages.add(page);
    page = <NovelPageSlice>[];
    used = 0;
  }

  for (var i = 0; i < paragraphs.length; i++) {
    final text = paragraphs[i];
    if (isSceneBreak(text)) {
      if (used + kNovelSceneBreakExtent > pageHeight && page.isNotEmpty) turn();
      page.add(NovelPageSlice(i, 0, text.length, sceneBreak: true));
      used += kNovelSceneBreakExtent;
      continue;
    }
    var start = 0;
    while (start < text.length || (text.isEmpty && start == 0)) {
      final first = start == 0;
      final piece = text.substring(start);
      final layout = NovelParagraphLayout(
        text: piece,
        type: type,
        width: width,
        ink: ink,
        indent: first && novelParagraphIndents(paragraphs, i),
        dropCap: first && i == 0,
      );
      final before = (first && page.isNotEmpty && gap > 0) ? gap : 0.0;
      final room = pageHeight - used - before;
      if (layout.height <= room) {
        page.add(NovelPageSlice(i, start, text.length));
        used += before + layout.height;
        layout.dispose();
        break;
      }
      // Whole lines that fit in the room left.
      var k = 0;
      for (final l in layout.lines) {
        if (l.bottom <= room + 0.01) {
          k++;
        } else {
          break;
        }
      }
      if (k == 0) {
        if (page.isNotEmpty) {
          layout.dispose();
          turn();
          continue;
        }
        k = 1; // A line taller than a whole page still gets one page.
      }
      if (k >= layout.lines.length) {
        // Everything fits by lines but the measured height did not (bottom leading): keep whole.
        page.add(NovelPageSlice(i, start, text.length));
        used += before + layout.height;
        layout.dispose();
        break;
      }
      final cut = layout.lines[k - 1].end;
      layout.dispose();
      final end = start + cut;
      if (end <= start) {
        turn();
        continue;
      }
      page.add(NovelPageSlice(i, start, end, continues: true));
      start = end;
      turn();
    }
  }
  if (page.isNotEmpty || pages.isEmpty) pages.add(page);
  return pages;
}

/// Which page shows the start of paragraph [paragraphIndex]'s text (the page holding its first
/// slice), clamped to the pages that exist.
int pageOfParagraph(List<List<NovelPageSlice>> pages, int paragraphIndex) {
  for (var p = 0; p < pages.length; p++) {
    for (final s in pages[p]) {
      if (s.paragraphIndex == paragraphIndex) return p;
      if (s.paragraphIndex > paragraphIndex) return p;
    }
  }
  return math.max(0, pages.length - 1);
}

/// The first paragraph on [page], clamped to the pages that exist.
int paragraphOfPage(List<List<NovelPageSlice>> pages, int page) {
  if (pages.isEmpty) return 0;
  final p = page.clamp(0, pages.length - 1);
  return pages[p].isEmpty ? 0 : pages[p].first.paragraphIndex;
}

/// Page index to progress bucket (1-100): the bucket of the first paragraph on the page.
int bucketOfPage(List<List<NovelPageSlice>> pages, int page, int paragraphCount) =>
    bucketForParagraph(paragraphOfPage(pages, page), paragraphCount);

/// Progress bucket to the page holding that bucket's paragraph.
int pageOfBucket(List<List<NovelPageSlice>> pages, int bucket, int paragraphCount) =>
    pageOfParagraph(pages, paragraphForBucket(bucket, paragraphCount));

/// The advance of `0` in the body style, in px.
double novelZeroAdvance(NovelType type) {
  final tp = TextPainter(text: TextSpan(text: '0', style: type.style(const Color(0xFF000000))), textDirection: TextDirection.ltr, textScaler: TextScaler.noScaling)
    ..layout();
  final w = tp.width;
  tp.dispose();
  return w;
}
