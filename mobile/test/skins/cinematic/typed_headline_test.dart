import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/typed_headline.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

const _style = TextStyle(fontSize: 20, color: Color(0xFFF3F0E8));
final _text = List.generate(40, (i) => String.fromCharCode(97 + i % 26)).join(); // 40 graphemes

Widget _host(Widget child, {bool reduced = false}) => MaterialApp(
      theme: ThemeData(extensions: const [cinematicTokens]),
      builder: (context, app) => MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: reduced), child: app!),
      home: Scaffold(body: child),
    );

int _revealed(WidgetTester t) {
  final rich = t.widget<RichText>(find.descendant(of: find.byType(TypedHeadline), matching: find.byType(RichText)));
  final root = (rich.text as TextSpan).children!.first as TextSpan;
  final first = root.children!.first as TextSpan;
  return first.text!.characters.length;
}

final _caret = find.byWidgetPredicate((w) => w is Container && w.color == cinematicTokens.colorSpot);

double _caretOpacity(WidgetTester t) => t.widget<Opacity>(find.ancestor(of: _caret, matching: find.byType(Opacity)).first).opacity;

void main() {
  testWidgets('one grapheme per 50 ms', (t) async {
    await t.pumpWidget(_host(TypedHeadline(_text, style: _style)));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    expect(_revealed(t), inInclusiveRange(9, 11));
    await t.pump(const Duration(milliseconds: 500));
    expect(_revealed(t), inInclusiveRange(19, 21));
    await t.pump(const Duration(milliseconds: 1100));
    expect(_revealed(t), 40);
  });

  testWidgets('the caret blinks off, on ... then fades', (t) async {
    await t.pumpWidget(_host(TypedHeadline(_text, style: _style)));
    await t.pump();
    await t.pump(const Duration(milliseconds: 2000));
    expect(_revealed(t), 40);
    await t.pump(const Duration(milliseconds: 100));
    expect(_caretOpacity(t), 0);
    await t.pump(const Duration(milliseconds: 500));
    expect(_caretOpacity(t), 1);
    await t.pump(const Duration(milliseconds: 2660));
    expect(_caretOpacity(t), closeTo(0.5, 0.05));
    await t.pump(const Duration(seconds: 1));
  });

  testWidgets('a tap completes it and it stays complete', (t) async {
    var done = 0;
    await t.pumpWidget(_host(TypedHeadline(_text, style: _style, onDone: () => done++)));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    await t.tap(find.byType(TypedHeadline));
    await t.pump();
    expect(_revealed(t), 40);
    await t.pump(const Duration(milliseconds: 200));
    expect(_revealed(t), 40);
    expect(done, 1);
    await t.pump(const Duration(seconds: 4));
  });

  testWidgets('Enter on the focused headline completes it', (t) async {
    await t.pumpWidget(_host(TypedHeadline(_text, style: _style)));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    Focus.of(t.element(find.descendant(of: find.byType(TypedHeadline), matching: find.byType(RichText)))).requestFocus();
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.pump();
    expect(_revealed(t), 40);
    await t.pump(const Duration(seconds: 4));
  });

  testWidgets('reduced motion: full text on the first frame, no caret', (t) async {
    await t.pumpWidget(_host(TypedHeadline(_text, style: _style), reduced: true));
    expect(find.text(_text), findsOneWidget);
    expect(_caret, findsNothing);
  });

  testWidgets('the full text is in the semantics tree from frame 0; level sets the header flag', (t) async {
    final h = t.ensureSemantics();
    await t.pumpWidget(_host(TypedHeadline(_text, style: _style, level: 1)));
    expect(t.getSemantics(find.byType(TypedHeadline)), isSemantics(label: _text, isHeader: true));
    await t.pump(const Duration(seconds: 6));
    h.dispose();
  });

  testWidgets('a headline with no level is not a header', (t) async {
    final h = t.ensureSemantics();
    await t.pumpWidget(_host(TypedHeadline(_text, style: _style)));
    expect(t.getSemantics(find.byType(TypedHeadline)), isNot(isSemantics(isHeader: true)));
    await t.pump(const Duration(seconds: 6));
    h.dispose();
  });

  // mobile/24 F1 (cinematic 10.2): focus does not skip; Space skips; the whole reveal takes
  // n x 50 ms + 3,180 ms of caret blinks + 160 ms fade + 200 ms of slack, then the caret is gone.
  testWidgets('focus at 100 ms does not skip it: the 10th grapheme is still hidden at 200 ms', (t) async {
    await t.pumpWidget(_host(TypedHeadline(_text, style: _style)));
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    Focus.of(t.element(find.descendant(of: find.byType(TypedHeadline), matching: find.byType(RichText)))).requestFocus();
    await t.pump(const Duration(milliseconds: 100));
    expect(_revealed(t), lessThan(10));
    expect(_caret, findsOneWidget);
    await t.pump(const Duration(seconds: 6));
  });

  testWidgets('Space on the focused headline completes it and the count never advances again', (t) async {
    await t.pumpWidget(_host(TypedHeadline(_text, style: _style)));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    Focus.of(t.element(find.descendant(of: find.byType(TypedHeadline), matching: find.byType(RichText)))).requestFocus();
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.space);
    await t.pump();
    expect(_revealed(t), 40);
    await t.pump(const Duration(milliseconds: 500));
    expect(_revealed(t), 40);
    await t.pump(const Duration(seconds: 4));
  });

  testWidgets('every grapheme is revealed and the caret is gone after n x 50 + 3,180 + 160 + 200 ms', (t) async {
    await t.pumpWidget(_host(TypedHeadline(_text, style: _style)));
    await t.pump();
    await t.pump(Duration(milliseconds: 40 * 50 + 3180 + 160 + 200));
    expect(_revealed(t), 40);
    // The caret has faded out: gone from the tree or fully transparent.
    if (_caret.evaluate().isNotEmpty) expect(_caretOpacity(t), 0);
  });
}
