import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_text_field.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

Widget _host(Widget child) => MaterialApp(theme: ThemeData(extensions: const [cinematicTokens]), home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('a tap fires onPressed; disabled and loading do not', (t) async {
    var n = 0;
    await t.pumpWidget(_host(CineButton(label: 'Go', onPressed: () => n++)));
    await t.tap(find.byType(CineButton));
    expect(n, 1);
    await t.pumpWidget(_host(const CineButton(label: 'Go', onPressed: null)));
    await t.tap(find.byType(CineButton), warnIfMissed: false);
    await t.pumpWidget(_host(CineButton(label: 'Go', loading: true, onPressed: () => n++)));
    await t.tap(find.byType(CineButton), warnIfMissed: false);
    expect(n, 1);
    await t.pump(const Duration(seconds: 1));
  });

  testWidgets('loading keeps the label until 400 ms, then shows loadingLabel', (t) async {
    await t.pumpWidget(_host(CineButton(label: 'Sign in', loadingLabel: 'Signing in…', loading: true, onPressed: () {})));
    await t.pump(const Duration(milliseconds: 200));
    expect(find.text('Sign in'), findsOneWidget);
    await t.pump(const Duration(milliseconds: 300));
    await t.pump(const Duration(milliseconds: 200));
    expect(find.text('Signing in…'), findsOneWidget);
  });

  testWidgets('the split button speaks its folio, and stacks it at text scale 1.5', (t) async {
    final h = t.ensureSemantics();
    await t.pumpWidget(_host(CineButton(label: 'Continue', variant: CineButtonVariant.split, folio: 'CH 143 · p.12', onPressed: () {})));
    expect(find.bySemanticsLabel('Continue, chapter 143, page 12'), findsOneWidget);
    final wide = t.getSize(find.byType(CineButton)).height;
    await t.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [cinematicTokens]),
      builder: (c, a) => MediaQuery(data: MediaQuery.of(c).copyWith(textScaler: const TextScaler.linear(1.5)), child: a!),
      home: Scaffold(body: Center(child: CineButton(label: 'Continue', variant: CineButtonVariant.split, folio: 'CH 143 · p.12', onPressed: () {}))),
    ),);
    expect(t.getSize(find.byType(CineButton)).height, greaterThanOrEqualTo(64));
    expect(t.getSize(find.byType(CineButton)).height, greaterThan(wide));
    h.dispose();
  });

  testWidgets('an error line shows in words and clears its colour after the hold', (t) async {
    await t.pumpWidget(_host(CineButton(label: 'Retry', errorText: 'The server didn’t answer.', onPressed: () {})));
    expect(find.text('The server didn’t answer.'), findsOneWidget);
    await t.pump(const Duration(milliseconds: 2100));
    expect(find.text('The server didn’t answer.'), findsOneWidget);
  });

  testWidgets('a field shows its error with the ‸ prefix and its label', (t) async {
    await t.pumpWidget(_host(const SizedBox(width: 300, child: CineTextField(label: 'EMAIL', errorText: 'Not an address.'))));
    expect(find.text('‸ Not an address.'), findsOneWidget);
    expect(find.text('EMAIL'), findsOneWidget);
  });

  testWidgets('a field types into its TextField', (t) async {
    final ctl = TextEditingController();
    await t.pumpWidget(_host(SizedBox(width: 300, child: CineTextField(label: 'NAME', controller: ctl))));
    await t.enterText(find.byType(TextField), 'lantern');
    expect(ctl.text, 'lantern');
  });
}
