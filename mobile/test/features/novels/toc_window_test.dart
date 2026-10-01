import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/novels/utils/toc_window.dart';

// The web twin's toc-window.test.ts uses these vectors too (web/33).
void main() {
  group('tocWindow', () {
    test('at the start', () {
      expect(tocWindow(1012, 0), const TocWindow(start: 0, end: 400, earlier: 0, later: 400));
    });
    test('in the middle', () {
      expect(tocWindow(1012, 412), const TocWindow(start: 212, end: 612, earlier: 212, later: 400));
    });
    test('at the end', () {
      expect(tocWindow(1012, 1011), const TocWindow(start: 612, end: 1012, earlier: 612, later: 0));
    });
    test('a short book shows everything', () {
      expect(tocWindow(80, 40), const TocWindow(start: 0, end: 80, earlier: 0, later: 0));
      expect(tocWindow(0, 0), const TocWindow(start: 0, end: 0, earlier: 0, later: 0));
    });
  });

  group('goToMatches', () {
    final chapters = <TocRef>[
      for (var i = 1; i <= 60; i++) (key: 'k$i', number: i.toDouble(), title: 'Chapter $i'),
      (key: 'k12.5', number: 61, title: 'Chapter 12.5'),
      for (var i = 0; i < 50; i++) (key: 'dup$i', number: 100.0 + i, title: 'Chapter 7'),
    ];

    test('an empty query asks for a number', () {
      expect(goToMatches(chapters, '').message, 'Type a chapter number.');
      expect(goToMatches(chapters, 'abc').message, 'Type a chapter number.');
    });
    test('no match names the number', () {
      expect(goToMatches(chapters, '900').message, 'No chapter 900 in this book.');
    });
    test('numbers compare as decimals', () {
      final r = goToMatches(chapters, '12.5');
      expect(r.matches.map((c) => c.key), ['k12.5']);
      expect(goToMatches(chapters, '12').matches.map((c) => c.key), ['k12']);
    });
    test('at most 12 matches and the rest counted', () {
      final r = goToMatches(chapters, '7');
      expect(r.matches, hasLength(12));
      expect(r.more, 39);
    });
  });
}
