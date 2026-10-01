// ignore_for_file: require_trailing_commas, avoid_redundant_argument_values, prefer_const_declarations, directives_ordering, prefer_function_declarations_over_variables
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/letter_reveal.dart';
import 'package:manhwamaniacs/skins/glass/primitives/reveal_slots.dart';

import 'support.dart';

Widget _reveal(String text, {String? key = 'title'}) => LetterReveal(text, role: gt.typeLargeTitle, revealKey: key, screenId: 'test');

Finder _opacities(Finder within) => find.descendant(of: within, matching: find.byType(Opacity));

double _firstLetterOpacity(WidgetTester tester, Finder within) => tester.widget<Opacity>(_opacities(within).first).opacity;

void main() {
  setUp(glassRevealSlots.reset);

  testWidgets('no word breaks across lines at 200 px, and a longer title later does not throw', (tester) async {
    Widget host(String t) => primHost(SizedBox(width: 200, child: _reveal(t)));
    await tester.pumpWidget(host('The Return of the Mad Demon Hunter Squad'));
    await pumpFor(tester, 300);
    final rows = find.descendant(of: find.byType(LetterReveal), matching: find.byType(Row));
    expect(rows, findsWidgets);
    for (final r in rows.evaluate()) {
      final box = r.renderObject! as RenderBox;
      // A word is one unbreakable Row: no taller than one line.
      expect(box.size.height, lessThan(60), reason: 'a word wrapped');
    }
    await tester.pumpWidget(host('The Return of the Mad Demon Hunter Squad and the Very Long Winter of Unexpected Consequences'));
    await pumpFor(tester, 300);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a heading below the fold waits for 25 % visibility, then runs', (tester) async {
    final c = ScrollController();
    await tester.pumpWidget(primHost(
      SizedBox(
        height: 600,
        width: 390,
        child: SingleChildScrollView(controller: c, child: Column(children: [const SizedBox(height: 1200), _reveal('Because you read Solo Leveling'), const SizedBox(height: 1200)])),
      ),
    ),);
    await pumpFor(tester, 500);
    expect(_firstLetterOpacity(tester, find.byType(LetterReveal)), 0);
    expect(glassRevealSlots.running, 0);
    // Bring 37 % of it into view (the heading wraps to about 160 px at this width); 7 % first: still waiting.
    c.jumpTo(1200 - 600 + 12);
    await pumpFor(tester, 200);
    expect(glassRevealSlots.running, 0);
    c.jumpTo(1200 - 600 + 60);
    await pumpFor(tester, 16);
    await pumpFor(tester, 200);
    expect(glassRevealSlots.running, 1);
    expect(_firstLetterOpacity(tester, find.byType(LetterReveal)), greaterThan(0));
  });

  testWidgets('focus on the heading at 100 ms does not complete it', (tester) async {
    await tester.pumpWidget(primHost(Focus(child: _reveal('Continue reading'))));
    await pumpFor(tester, 100);
    Focus.of(tester.element(find.byType(LetterReveal))).requestFocus();
    await pumpFor(tester, 60);
    expect(glassRevealSlots.running, 1);
    expect(find.byType(Row), findsWidgets);
  });

  testWidgets('a tap completes it at once', (tester) async {
    await tester.pumpWidget(primHost(_reveal('Continue reading')));
    await pumpFor(tester, 100);
    await tester.tap(find.byType(LetterReveal));
    await tester.pump();
    expect(find.text('Continue reading'), findsOneWidget);
    expect(glassRevealSlots.running, 0);
  });

  testWidgets('three headings entering together run at most two at once; the third starts when one ends', (tester) async {
    await tester.pumpWidget(primHost(Column(children: [_reveal('First heading', key: 'a'), _reveal('Second heading', key: 'b'), _reveal('Third heading', key: 'c')])));
    await pumpFor(tester, 100);
    expect(glassRevealSlots.running, 2);
    expect(glassRevealSlots.waiting, 1);
    await pumpFor(tester, revealDuration(13).inMilliseconds + 100);
    // The third took a slot when the first ended, and is still running or done; never more than two.
    expect(glassRevealSlots.running, lessThanOrEqualTo(2));
    await pumpFor(tester, 2500);
    expect(glassRevealSlots.running, 0);
    expect(find.text('Third heading'), findsOneWidget);
  });

  testWidgets('a second pump in the same session shows the heading at rest', (tester) async {
    var show = true;
    late StateSetter set;
    await tester.pumpWidget(primHost(StatefulBuilder(builder: (context, s) {
      set = s;
      return show ? _reveal('Continue reading') : const SizedBox();
    },),),);
    await pumpFor(tester, 2500);
    set(() => show = false);
    await tester.pump();
    set(() => show = true);
    await tester.pump();
    expect(find.text('Continue reading'), findsOneWidget);
    expect(glassRevealSlots.running, 0);
  });

  testWidgets('reduced motion renders the plain text', (tester) async {
    await tester.pumpWidget(primHost(_reveal('Continue reading'), reduced: true));
    await tester.pump();
    expect(find.text('Continue reading'), findsOneWidget);
    expect(glassRevealSlots.running, 0);
  });

  // mobile/45 H5: the timing contract of 10.2.
  testWidgets('every letter settles within 24 x (g - 1) + 345 + 100 ms; the glint crosses once, 120 ms after the last letter, over 500 ms', (tester) async {
    const text = 'Continue reading'; // 15 letters: spaces take no time
    const g = 15;
    await tester.pumpWidget(primHost(_reveal(text)));
    await pumpFor(tester, 24 * (g - 1) + 345 + 100);
    for (final o in _opacities(find.byType(LetterReveal)).evaluate()) {
      expect((o.widget as Opacity).opacity, 1, reason: 'a letter is still waiting');
    }
    final lastSettled = 24 * (g - 1) + 345;
    expect(find.descendant(of: find.byType(LetterReveal), matching: find.byType(ShaderMask)), findsNothing, reason: 'the glint waits 120 ms after the last letter');
    await pumpFor(tester, lastSettled + 120 + 250 - (24 * (g - 1) + 345 + 100));
    expect(find.descendant(of: find.byType(LetterReveal), matching: find.byType(ShaderMask)), findsOneWidget, reason: 'mid-glint');
    await pumpFor(tester, 600);
    expect(find.descendant(of: find.byType(LetterReveal), matching: find.byType(ShaderMask)), findsNothing, reason: 'one crossing only');
  });

  testWidgets('a fresh ProviderScope (a new session or an AppRestart) reveals again; the same scope does not', (tester) async {
    await tester.pumpWidget(primHost(_reveal('Continue reading')));
    await pumpFor(tester, 3000);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(primHost(_reveal('Continue reading')));
    await pumpFor(tester, 100);
    expect(glassRevealSlots.running, 1, reason: 'a new scope starts a new session');
    await pumpFor(tester, 3000);
  });

  test('above 60 graphemes it animates per word', () {
    final long = List.filled(14, 'wordy').join(' ');
    expect(RevealPlan(long).perWord, isTrue);
    expect(RevealPlan(long).unitCount, 14);
    expect(RevealPlan('Short title').perWord, isFalse);
    expect(RevealPlan('Short title').unitCount, 10);
  });

  test('CJK runs break between graphemes; Latin words stay whole', () {
    final p = RevealPlan('進撃の巨人 Titan');
    expect(p.words.where((w) => w.length == 1).length, greaterThanOrEqualTo(5));
    expect(p.words.last, ['T', 'i', 't', 'a', 'n']);
  });
}
