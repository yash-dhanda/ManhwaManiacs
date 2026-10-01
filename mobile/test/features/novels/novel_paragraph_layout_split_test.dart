import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/novels/engine/novel_paragraph_layout.dart';
import 'package:manhwamaniacs/features/novels/models/novel_typography.dart';
import 'package:manhwamaniacs/features/novels/utils/novel_book.dart';

int _lines(String text, TextStyle style, double width) {
  final tp = TextPainter(text: TextSpan(text: text, style: style), textDirection: TextDirection.ltr, textScaler: TextScaler.noScaling)..layout(maxWidth: width);
  final n = tp.computeLineMetrics().length;
  tp.dispose();
  return n;
}

void main() {
  const style = TextStyle(fontSize: 10, height: 1.5);
  final long = List.generate(40, (i) => 'word$i').join(' ');

  test('a long paragraph splits where its third narrow line ends', () {
    final split = NovelParagraphLayout.dropCapSplit(long, style, width: 200, capAdvancePlusGap: 50);
    expect(split, greaterThan(0));
    expect(split, lessThan(long.length));
    expect(_lines(long.substring(0, split), style, 150), 3);
    expect(_lines(long, style, 150), greaterThan(3));
    // The tail starts a new line: adding its first word to the head makes a fourth line.
    final next = long.substring(split).split(' ').first;
    expect(_lines('${long.substring(0, split)}$next', style, 150), 4);
  });

  test('a paragraph of three lines or fewer sits beside the cap whole', () {
    const short = 'one two three four';
    expect(NovelParagraphLayout.dropCapSplit(short, style, width: 200, capAdvancePlusGap: 50), short.length);
  });

  test('the 80-character floor: shorter first paragraphs get no cap', () {
    final s79 = 'A${'b' * 78}';
    final s80 = 'A${'b' * 79}';
    expect(splitDropCap(s79), isNull);
    expect(splitDropCap(s80), isNotNull);
    expect(const NovelDropCapSpec(style: TextStyle(), sizeEm: 3.1).minLength, kMinDropCapLength);
  });

  test('a face style replaces the Cinematic face; no face style keeps it', () {
    const glass = NovelType(fontSize: 20, lineHeight: 1.75, letterSpacing: 0.02, faceStyle: TextStyle(fontFamily: 'LiterataMM', fontVariations: [FontVariation('wght', 400)]));
    final s = glass.style(const Color(0xFFFFFFFF));
    expect(s.fontFamily, 'LiterataMM');
    expect(s.fontSize, 20);
    expect(s.height, 1.75);
    expect(s.letterSpacing, closeTo(0.4, 1e-9));
    const cine = NovelType(fontSize: 18);
    expect(cine.style(const Color(0xFF000000)).fontFamily, NovelFace.newsreader.family);
    expect(glass == glass.copyWith(), isTrue);
    expect(glass == cine, isFalse);
  });

  test('a skin drop cap is sized in ems of the body', () {
    const spec = NovelDropCapSpec(style: TextStyle(fontFamily: 'LiterataMM'), sizeEm: 3.1);
    final s = spec.at(20, const Color(0xFF123456));
    expect(s.fontSize, closeTo(62, 1e-9));
    expect(s.color, const Color(0xFF123456));
    expect(spec.lines, 3);
    expect(spec.gapEm, 0.08);
  });
}
