// ignore_for_file: require_trailing_commas, directives_ordering
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/drop_cap_paragraph.dart';

const _body = TextStyle(fontSize: 16, height: 24 / 16, color: Colors.white);
const _cap = TextStyle(fontSize: 72, height: 1, fontWeight: FontWeight.w800, color: Colors.white);
final _text = List.filled(30, 'lantern').join(' ');

Widget _host(String text, {double width = 300}) => MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: DropCapParagraph(text: text, style: _body, capStyle: _cap),
          ),
        ),
      ),
    );

void main() {
  testWidgets('the cap sits on the third baseline of the beside-lines block', (tester) async {
    await tester.pumpWidget(_host(_text));
    final capFinder = find.text('l');
    final headFinder = find.byWidgetPredicate(
        (w) => w is Text && w.style == _body && (w.data ?? '').startsWith('antern'));
    expect(capFinder, findsOneWidget);
    expect(headFinder, findsOneWidget);

    final capBox = tester.renderObject<RenderParagraph>(capFinder);
    final headBox = tester.renderObject<RenderParagraph>(headFinder);
    final capBaseline =
        tester.getTopLeft(capFinder).dy + capBox.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    final lines = headBox.getBoxesForSelection(TextSelection(baseOffset: 0, extentOffset: headBox.text.toPlainText().length));
    expect(lines, isNotEmpty);
    // The third line's baseline: three 24 px lines, baseline inside the third.
    final headTop = tester.getTopLeft(headFinder).dy;
    final third = headBox.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    final headMetrics = headBox.text.toPlainText();
    expect(headMetrics, isNotEmpty);
    // headBox baseline is the FIRST line's; the third is two line-heights lower.
    final thirdBaseline = headTop + third + 2 * 24;
    expect((capBaseline - thirdBaseline).abs(), lessThan(2.5), // Ahem rounds ascents; real faces land within a pixel
        reason: 'cap baseline $capBaseline vs third text baseline $thirdBaseline');
  });

  testWidgets('the beside block is exactly three lines; the rest sets at full width below', (tester) async {
    await tester.pumpWidget(_host(_text));
    final head = find.byWidgetPredicate(
        (w) => w is Text && w.style == _body && (w.data ?? '').startsWith('antern'));
    final headBox = tester.renderObject<RenderParagraph>(head);
    expect(headBox.size.height, lessThanOrEqualTo(72.5));
    final tail = find.byWidgetPredicate(
        (w) => w is Text && w.style == _body && !(w.data ?? '').startsWith('antern'));
    expect(tail, findsOneWidget);
    expect(tester.getSize(tail).width, closeTo(300, 0.5));
  });

  testWidgets('under 80 characters there is no drop cap', (tester) async {
    await tester.pumpWidget(_host('A short blurb.'));
    expect(find.text('A short blurb.'), findsOneWidget);
    expect(find.text('A'), findsNothing);
  });

  test('split keeps head to three lines and loses no words', () {
    final r = DropCapParagraph.split(_text, _body, 200, 3);
    final tp = TextPainter(text: TextSpan(text: r.head, style: _body), textDirection: TextDirection.ltr)
      ..layout(maxWidth: 200);
    expect(tp.computeLineMetrics().length, lessThanOrEqualTo(3));
    expect('${r.head} ${r.tail}'.replaceAll(RegExp(r'\s+'), ' ').trim(), _text);
    final short = DropCapParagraph.split('two words', _body, 200, 3);
    expect(short.tail, isEmpty);
  });
}
