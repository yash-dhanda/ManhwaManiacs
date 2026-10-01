import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/novels/engine/novel_paginator.dart';
import 'package:manhwamaniacs/features/novels/engine/novel_paragraph_layout.dart';
import 'package:manhwamaniacs/features/novels/models/novel_typography.dart';
import 'package:manhwamaniacs/features/novels/utils/novel_book.dart';
import 'package:manhwamaniacs/features/novels/utils/novel_progress.dart';

import 'support/novel_fixtures.dart';

const _type = NovelType();
const _ink = Color(0xFFFFFFFF);

List<List<NovelPageSlice>> _paginate(List<String> ps, {double width = 320, double height = 480, double opener = 0, NovelType type = _type}) =>
    paginateNovelText(paragraphs: ps, type: type, width: width, pageHeight: height, openerHeight: opener);

void main() {
  test('every character appears exactly once and in order across pages', () {
    final ps = fixtureParagraphs();
    final pages = _paginate(ps, opener: 200);
    expect(pages.length, greaterThan(2));
    final rebuilt = List<StringBuffer>.generate(ps.length, (_) => StringBuffer());
    final cursor = List<int>.filled(ps.length, 0);
    for (final page in pages) {
      for (final s in page) {
        expect(s.startChar, cursor[s.paragraphIndex], reason: 'contiguous $s');
        rebuilt[s.paragraphIndex].write(ps[s.paragraphIndex].substring(s.startChar, s.endChar));
        cursor[s.paragraphIndex] = s.endChar;
      }
    }
    for (var i = 0; i < ps.length; i++) {
      expect(rebuilt[i].toString(), ps[i]);
    }
    // Slices appear in paragraph order.
    final order = [for (final p in pages) for (final s in p) s.paragraphIndex];
    expect(order, orderedEquals([...order]..sort()));
  });

  test('no page holds more line height than the page', () {
    final ps = fixtureParagraphs();
    for (final height in const [300.0, 480.0, 700.0]) {
      final pages = _paginate(ps, height: height);
      for (final page in pages) {
        var used = 0.0;
        for (final s in page) {
          if (s.sceneBreak) {
            used += kNovelSceneBreakExtent;
            continue;
          }
          final l = NovelParagraphLayout(
            text: ps[s.paragraphIndex].substring(s.startChar),
            type: _type,
            width: 320,
            ink: _ink,
            indent: s.startChar == 0 && novelParagraphIndents(ps, s.paragraphIndex),
            dropCap: s.startChar == 0 && s.paragraphIndex == 0,
          );
          // The slice's own layout.
          final sliceText = ps[s.paragraphIndex].substring(s.startChar, s.endChar);
          final own = NovelParagraphLayout(
            text: sliceText,
            type: _type,
            width: 320,
            ink: _ink,
            indent: s.startChar == 0 && novelParagraphIndents(ps, s.paragraphIndex),
            dropCap: s.startChar == 0 && s.paragraphIndex == 0,
          );
          used += own.height;
          l.dispose();
          own.dispose();
        }
        expect(used, lessThanOrEqualTo(height + 0.5), reason: 'page over $height: $page');
      }
    }
  });

  test('a paragraph of hard line breaks splits across pages (every line its own box)', () {
    final poem = List.generate(60, (i) => 'Line $i of a poem broken by hand.').join('\n');
    final l = NovelParagraphLayout(text: poem, type: _type, width: 320, ink: _ink, indent: false, dropCap: false);
    final starts = [for (final x in l.lines) x.start];
    for (var i = 1; i < starts.length; i++) {
      expect(starts[i], greaterThan(starts[i - 1]), reason: 'line $i repeats an earlier box');
    }
    expect(starts, containsAll([for (var i = 0; i < 60; i++) poem.indexOf('Line $i ')]));
    l.dispose();
    final pages = _paginate([poem]);
    expect(pages.length, greaterThan(2), reason: 'all 60 lines were kept on one overflowing page');
    var cursor = 0;
    for (final page in pages) {
      for (final s in page) {
        expect(s.startChar, cursor);
        cursor = s.endChar;
        final own = NovelParagraphLayout(text: poem.substring(s.startChar, s.endChar), type: _type, width: 320, ink: _ink, indent: false, dropCap: false);
        expect(own.height, lessThanOrEqualTo(480 + 0.5));
        own.dispose();
      }
    }
    expect(cursor, poem.length);
  });

  test('a scene break is never split and takes its own extent', () {
    final ps = fixtureParagraphs();
    final pages = _paginate(ps, height: 260);
    final breaks = [for (final p in pages) for (final s in p) if (s.sceneBreak) s];
    expect(breaks, hasLength(1));
    expect(breaks.single.startChar, 0);
    expect(breaks.single.endChar, ps[breaks.single.paragraphIndex].length);
    expect(isSceneBreak(ps[breaks.single.paragraphIndex]), isTrue);
  });

  test('a size change keeps the anchor paragraph on the current page', () {
    final ps = fixtureParagraphs();
    final small = _paginate(ps);
    final big = _paginate(ps, type: _type.copyWith(fontSize: 26));
    for (final anchor in const [0, 5, 9, 15]) {
      final pageBefore = pageOfParagraph(small, anchor);
      final first = paragraphOfPage(small, pageBefore);
      // Re-paginating and asking for the page of that first paragraph keeps it on screen.
      final pageAfter = pageOfParagraph(big, first);
      expect(big[pageAfter].any((s) => s.paragraphIndex == first), isTrue, reason: 'paragraph $first after resize');
    }
    expect(big.length, greaterThanOrEqualTo(small.length));
  });

  test('page and bucket map both ways and clamp', () {
    final ps = fixtureParagraphs();
    final pages = _paginate(ps);
    final n = ps.length;
    expect(bucketOfPage(pages, 0, n), 1);
    final lastBucket = bucketOfPage(pages, pages.length - 1, n);
    expect(lastBucket, lessThanOrEqualTo(bucketCount(n)));
    expect(bucketOfPage(pages, 99, n), lastBucket);
    expect(pageOfBucket(pages, 1, n), 0);
    expect(pageOfBucket(pages, 9999, n), lessThan(pages.length));
    for (var p = 0; p < pages.length; p++) {
      final b = bucketOfPage(pages, p, n);
      expect(pageOfBucket(pages, b, n), lessThanOrEqualTo(p));
    }
  });

  test('the 12,000-word fixture paginates and reports its duration', () {
    final ps = longFixtureParagraphs();
    final sw = Stopwatch()..start();
    final pages = _paginate(ps, height: 640);
    sw.stop();
    // ignore: avoid_print
    print('paginate: ${ps.length} paragraphs, ${sw.elapsedMilliseconds} ms, ${pages.length} pages');
    expect(pages.length, greaterThan(20));
    var chars = 0;
    for (final p in pages) {
      for (final s in p) {
        chars += s.endChar - s.startChar;
      }
    }
    expect(chars, ps.fold<int>(0, (a, b) => a + b.length));
  });

  test('paragraph spacing drops the indent; continuation slices have neither indent nor cap', () {
    final ps = fixtureParagraphs();
    final spaced = _paginate(ps, type: _type.copyWith(paragraphSpacing: 0.6));
    expect(spaced, isNotEmpty);
    final l = NovelParagraphLayout(text: ps[1], type: _type.copyWith(paragraphSpacing: 0.6), width: 320, ink: _ink, indent: true);
    final plain = NovelParagraphLayout(text: ps[1], type: _type, width: 320, ink: _ink);
    expect(l.lines.first.left, plain.lines.first.left, reason: 'no indent when spacing > 0');
    final indented = NovelParagraphLayout(text: ps[1], type: _type, width: 320, ink: _ink, indent: true);
    expect(indented.boxesFor(0, 1).first.left, closeTo(1.3 * 18, 1), reason: 'the first character starts 1.3em in');
    expect(plain.boxesFor(0, 1).first.left, closeTo(0, 0.5));
  });

  test('the drop cap is granted only for a first paragraph of 80 characters or more', () {
    final ps = fixtureParagraphs();
    final cap = NovelParagraphLayout(text: ps[0], type: _type, width: 320, ink: _ink, dropCap: true);
    expect(cap.hasDropCap, isTrue);
    expect(cap.height, greaterThanOrEqualTo(3 * cap.lineHeightPx - 0.5));
    final short = NovelParagraphLayout(text: 'Too short for a cap.', type: _type, width: 320, ink: _ink, dropCap: true);
    expect(short.hasDropCap, isFalse);
    final quote = NovelParagraphLayout(text: '“${'x' * 100}”', type: _type, width: 320, ink: _ink, dropCap: true);
    expect(quote.hasDropCap, isFalse);
  });
}
