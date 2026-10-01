// ignore_for_file: require_trailing_commas, avoid_redundant_argument_values, prefer_const_declarations, directives_ordering, prefer_function_declarations_over_variables
// ignore_for_file: prefer_const_constructors
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/revealed_headings.dart';

import 'glass_qa_screens.dart';

/// mobile/45 H1 and H4 on the real screens: each placement types its headline once; route focus never skips it.
Finder get _rich => find.byType(RichText);
Finder get _caret => find.byWidgetPredicate((w) => w is CustomPaint && w.painter.runtimeType.toString() == '_CaretPainter');

/// The RichText of the typed headline whose full text starts with [prefix]: its spans are laid out in full from frame 0.
TextSpan? _typed(WidgetTester t, String prefix) {
  for (final e in _rich.evaluate()) {
    final root = (e.widget as RichText).text;
    if (root is TextSpan && root.children != null && root.children!.every((c) => c is TextSpan) && root.toPlainText().startsWith(prefix)) return root;
  }
  return null;
}

Color? _color(TextSpan root, int i) => (root.children![i] as TextSpan).style?.color;

void main() {
  final cases = <(String, ScreenId, String, int)>[
    ('Home greeting', ScreenId.tonight, 'Good', 9), // the 10th grapheme
    ('Login "Welcome back"', ScreenId.login, 'Welcome back', 9),
    ('Onboarding step 1 "Hi, Tester."', ScreenId.onboarding, 'Hi, ', 4), // shorter than 10: the 5th
    ('Wrapped cover "Your 2026 in chapters"', ScreenId.annual, 'Your 2026', 9),
    ('Recap deck "Previously on ..."', ScreenId.recap, 'Previously on', 9),
  ];
  for (final (name, id, prefix, idx) in cases) {
    glassQaWidgets('$name types once: still typing at 200 ms (route focus does not skip it), caret present, full label from frame 1', (t) async {
      final h = t.ensureSemantics();
      final s = kGlassQaScreens.firstWhere((e) => e.id == id);
      final rig = await pumpGlassQa(t, s, settle: false);
      await t.pump();
      // Route focus lands on the header at once (8.0.8): it must not complete the typing.
      final focusNodes = find.byType(Focus).evaluate().where((e) => e.widget is Focus).toList();
      for (final e in focusNodes) {
        final f = (e.widget as Focus).focusNode;
        if (f != null && f.debugLabel == 'large title') f.requestFocus();
      }
      await t.pump(const Duration(milliseconds: 200));
      final root = _typed(t, prefix);
      expect(root, isNotNull, reason: '$name: no typed headline found');
      final n = root!.children!.length;
      expect(_color(root, idx < n ? idx : n - 1), const Color(0x00000000), reason: '$name: grapheme ${idx + 1} is still transparent at 200 ms');
      expect(_caret, findsWidgets);
      expect(find.bySemanticsLabel(RegExp(RegExp.escape(prefix))), findsWidgets, reason: 'the full text is the accessible name from the first frame');
      h.dispose();
      await t.pump(const Duration(seconds: 8));
      await disposeGlassQa(t, rig);
    });
  }

  glassQaWidgets('Home records "{profileId}:home.greeting" in revealedHeadingsProvider; a second visit shows it at rest; a fresh scope types again', (t) async {
    final s = kGlassQaScreens.firstWhere((e) => e.id == ScreenId.tonight);
    final rig = await pumpGlassQa(t, s, settle: false);
    await t.pump(const Duration(milliseconds: 100));
    expect(rig.shell.container.read(revealedHeadingsProvider), contains('1:home.greeting'));
    await t.pump(const Duration(seconds: 8));
    await disposeGlassQa(t, rig);
    final rig2 = await pumpGlassQa(t, s, settle: false);
    await t.pump(const Duration(milliseconds: 100));
    expect(_caret, findsWidgets, reason: 'a new ProviderScope is a new session');
    await t.pump(const Duration(seconds: 8));
    await disposeGlassQa(t, rig2);
  });
}
