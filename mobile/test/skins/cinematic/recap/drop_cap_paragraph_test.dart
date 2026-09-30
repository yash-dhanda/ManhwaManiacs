import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/recap/drop_cap_paragraph.dart';

void main() {
  const style = TextStyle(fontSize: 18, height: 28 / 18, fontFamily: 'Roboto');
  final text = List.generate(80, (i) => 'word$i').join(' ');

  test('the first three lines beside the cap break on a word boundary', () {
    final s = RecapDropCap.split(text, style, 200, 3);
    expect(s.head, isNotEmpty);
    expect(s.tail, isNotEmpty);
    expect('${s.head} ${s.tail}', text);
    expect(s.head.endsWith(' '), isFalse);
    expect(RegExp(r'^word\d+$').hasMatch(s.head.split(' ').last), isTrue, reason: 'never a cut word');
    final tp = TextPainter(text: TextSpan(text: s.head, style: style), textDirection: TextDirection.ltr)..layout(maxWidth: 200);
    expect(tp.computeLineMetrics().length, lessThanOrEqualTo(3));
  });

  test('a short paragraph stays whole', () {
    final s = RecapDropCap.split('Two short lines.', style, 300, 3);
    expect(s.head, 'Two short lines.');
    expect(s.tail, isEmpty);
  });

  test('re-measured as words stream: the head only grows', () {
    var last = 0;
    for (var n = 5; n <= 80; n += 5) {
      final t = List.generate(n, (i) => 'word$i').join(' ');
      final h = RecapDropCap.split(t, style, 200, 3).head.length;
      expect(h, greaterThanOrEqualTo(last));
      last = h;
    }
  });
}
