import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/revealed_headings.dart';
import 'package:manhwamaniacs/skins/glass/primitives/typed_headline.dart';

import 'support.dart';

const _text = 'Good evening, Yash';

Widget _headline([String text = _text]) => TypedHeadline(text, role: gt.typeLargeTitle, placement: 'gallery:greeting');

Finder get _rich => find.byType(RichText);

TextSpan _root(WidgetTester tester) => tester.widget<RichText>(_rich.first).text as TextSpan;

Color? _colorOf(TextSpan root, int i) => (root.children![i] as TextSpan).style?.color;

Finder get _caret => find.byWidgetPredicate((w) => w is CustomPaint && w.painter.runtimeType.toString() == '_CaretPainter');

void main() {
  setUp(GlassMotionBind.reset);

  testWidgets('focus arriving on the headline at 100 ms does not skip the typing', (tester) async {
    await tester.pumpWidget(primHost(_headline()));
    await pumpFor(tester, 100);
    Focus.of(tester.element(_rich.first)).requestFocus();
    await pumpFor(tester, 100);
    // 200 ms in: 4 graphemes are visible, the 10th is still transparent.
    expect(_colorOf(_root(tester), 9), const Color(0x00000000));
    expect(_colorOf(_root(tester), 0), isNot(const Color(0x00000000)));
  });

  testWidgets('letters and caret start together, and the caret is gone at the end of the timeline', (tester) async {
    await tester.pumpWidget(primHost(_headline()));
    final left = tester.getTopLeft(_rich.first).dx;
    await tester.pump(const Duration(milliseconds: 20));
    expect(_caret, findsOneWidget);
    expect(tester.getTopLeft(_caret).dx, lessThan(left + 4));
    await pumpFor(tester, 380);
    // Grapheme 6+ is visible; the caret is past grapheme 0.
    expect(tester.getTopLeft(_caret).dx, greaterThan(left + 10));
    final n = _text.characters.length;
    await pumpFor(tester, n * 50 + 3 * 1060 + 350 + 200 + 50);
    expect(_caret, findsNothing);
    expect(find.text(_text), findsOneWidget);
  });

  testWidgets('a tap completes it; the caret still leaves on its own clock', (tester) async {
    await tester.pumpWidget(primHost(_headline()));
    await pumpFor(tester, 100);
    await tester.tapAt(tester.getCenter(_rich.first));
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump(const Duration(milliseconds: 20));
    final root = _root(tester);
    for (var i = 0; i < _text.characters.length - 1; i++) {
      expect(_colorOf(root, i), isNot(const Color(0x00000000)), reason: 'grapheme $i');
    }
    expect(_caret, findsOneWidget);
    await pumpFor(tester, 3700);
    expect(_caret, findsNothing);
  });

  testWidgets('a key event with focus on the headline completes it', (tester) async {
    await tester.pumpWidget(primHost(_headline()));
    await pumpFor(tester, 100);
    Focus.of(tester.element(_rich.first)).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump(const Duration(milliseconds: 20));
    expect(_colorOf(_root(tester), 9), isNot(const Color(0x00000000)));
  });

  testWidgets('frame 0 has the width of the final text', (tester) async {
    await tester.pumpWidget(primHost(_headline()));
    final w0 = tester.getSize(_rich.first).width;
    await pumpFor(tester, 7000);
    expect(tester.getSize(find.text(_text)).width, closeTo(w0, 0.5));
  });

  testWidgets('a second pump in the same session shows the text at once', (tester) async {
    var show = true;
    late StateSetter set;
    await tester.pumpWidget(primHost(StatefulBuilder(builder: (context, s) {
      set = s;
      return show ? _headline() : const SizedBox();
    },),),);
    await pumpFor(tester, 7000);
    set(() => show = false);
    await tester.pump();
    set(() => show = true);
    await tester.pump();
    expect(find.text(_text), findsOneWidget);
    expect(_caret, findsNothing);
  });

  testWidgets('reduced motion renders the plain text with no caret', (tester) async {
    await tester.pumpWidget(primHost(_headline(), reduced: true));
    await tester.pump();
    expect(find.text(_text), findsOneWidget);
    expect(_caret, findsNothing);
  });

  testWidgets('a 60-grapheme headline types 48 and fades the tail in as one span', (tester) async {
    final long = List.generate(60, (i) => String.fromCharCode(97 + i % 26)).join();
    await tester.pumpWidget(primHost(SizedBox(width: 380, child: _headline(long))));
    await pumpFor(tester, 2390);
    var root = _root(tester);
    expect(_colorOf(root, 46), isNot(const Color(0x00000000)));
    expect(_colorOf(root, 48), const Color(0x00000000));
    await pumpFor(tester, 110);
    root = _root(tester);
    expect(_colorOf(root, 47), isNot(const Color(0x00000000)));
    final mid = _colorOf(root, 55)!;
    expect(mid.a, greaterThan(0));
    expect(mid.a, lessThan(1));
    await pumpFor(tester, 150);
    expect(_colorOf(_root(tester), 59)!.a, 1);
  });

  // mobile/45 H1 and H3.
  testWidgets('the caret is 2 px wide, 0.72 em tall; the heading carries its full label from the first frame under ExcludeSemantics spans', (tester) async {
    final h = tester.ensureSemantics();
    await tester.pumpWidget(primHost(_headline()));
    await tester.pump(const Duration(milliseconds: 20));
    final caret = tester.getSize(_caret);
    expect(caret.width, 2);
    final em = _root(tester).style!.fontSize!;
    expect(caret.height, closeTo(em * 0.72, 0.5));
    expect(tester.widget<CustomPaint>(_caret).painter.runtimeType.toString(), '_CaretPainter'); // iris400 core, painted by the glass tokens
    expect(find.bySemanticsLabel(_text), findsOneWidget, reason: 'the full string, frame 1');
    h.dispose();
    await pumpFor(tester, 7000);
  });

  testWidgets('navigating away completes it silently, and after a skip the count never advances again', (tester) async {
    var show = true;
    late StateSetter set;
    await tester.pumpWidget(primHost(StatefulBuilder(builder: (context, s) {
      set = s;
      return show ? _headline() : const SizedBox();
    },),),);
    await pumpFor(tester, 100);
    await tester.tapAt(tester.getCenter(_rich.first));
    await tester.pump();
    await pumpFor(tester, 200);
    final root = _root(tester);
    final before = [for (var i = 0; i < _text.characters.length - 1; i++) _colorOf(root, i)];
    await pumpFor(tester, 500);
    expect([for (var i = 0; i < _text.characters.length - 1; i++) _colorOf(_root(tester), i)], before);
    set(() => show = false);
    await pumpFor(tester, 4000);
  });

  testWidgets('the placement is "{profileId}:{placement}" in revealedHeadingsProvider from the moment typing starts', (tester) async {
    await tester.pumpWidget(primHost(_headline()));
    await tester.pump(const Duration(milliseconds: 20));
    final c = ProviderScope.containerOf(tester.element(_rich.first));
    expect(c.read(revealedHeadingsProvider).single, endsWith(':gallery:greeting'));
    expect(c.read(revealedHeadingsProvider).single, matches(RegExp(r'^(\d+|anon):gallery:greeting$')));
    await pumpFor(tester, 7000);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(primHost(_headline()));
    await tester.pump(const Duration(milliseconds: 20));
    expect(_caret, findsOneWidget, reason: 'a fresh ProviderScope types again');
    await pumpFor(tester, 7000);
  });

  test('the timeline is n x 50 + the tail + three blinks + the dematerialise', () {
    expect(TypedHeadline.timeline(10), const Duration(milliseconds: 500 + 3 * 1060 + 350));
    expect(TypedHeadline.timeline(60), const Duration(milliseconds: 2400 + 200 + 3 * 1060 + 350));
  });
}

class GlassMotionBind {
  static void reset() {}
}
