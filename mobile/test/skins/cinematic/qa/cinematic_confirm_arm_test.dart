// ignore_for_file: directives_ordering, require_trailing_commas, prefer_const_constructors, avoid_redundant_argument_values, unnecessary_lambdas, unnecessary_await_in_return
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_confirm_dialog.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// C11 (7.10, 15.7): every destructive confirm in the app is `showCineConfirm`, so the 1000 ms
/// `dur.arm` is one implementation. The source scan lists every call site; the variants below
/// prove the arm for each shape of the dialog.
bool? _result;

Future<void> _pump(WidgetTester t, Widget Function(BuildContext) trigger, {bool reduced = false}) async {
  _result = null;
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(
    theme: ThemeData(extensions: const [cinematicTokens]),
    builder: (c, a) => MediaQuery(data: MediaQuery.of(c).copyWith(disableAnimations: reduced), child: a!),
    home: Scaffold(body: Builder(builder: (context) => Center(child: trigger(context)))),
  ),);
}

final Map<String, Future<bool> Function(BuildContext)> _variants = {
  'destructive': (c) => showCineConfirm(c, title: 'Delete Ana?', confirmLabel: 'Delete', destructive: true),
  'sign out': (c) => showCineConfirm(c, title: 'Sign out on this device?', confirmLabel: 'Sign out', destructive: true),
  'acknowledge': (c) => showCineConfirm(c, title: 'Reset all sessions?', confirmLabel: 'Reset', destructive: true, acknowledge: 'I understand'),
};

void main() {
  test('every showCineConfirm call site is listed (the arm has one implementation)', () {
    final sites = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      final n = RegExp(r'\bshowCineConfirm\(').allMatches(f.readAsStringSync()).length;
      if (n > 0 && !f.path.endsWith('cine_confirm_dialog.dart')) sites.add('${f.path} x$n');
    }
    // ignore: avoid_print
    print('CONFIRM SITES\n${sites.join('\n')}');
    expect(sites.length, greaterThanOrEqualTo(20));
    // No other widget hand-rolls a destructive dialog.
    for (final f in Directory('lib/skins/cinematic').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      expect(f.readAsStringSync().contains(RegExp(r'\bshowDialog(<\w+>)?\(')), isFalse, reason: f.path);
    }
  });

  for (final e in _variants.entries) {
    testWidgets('${e.key}: two taps 150 ms apart do not confirm; a tap after 1000 ms does', (t) async {
      await _pump(t, (c) => CineButton(key: const Key('trigger'), label: 'Go', onPressed: () async => _result = await e.value(c)));
      await t.tap(find.byKey(const Key('trigger')));
      await t.pump();
      await t.pump(const Duration(milliseconds: 150));
      await t.tap(find.byKey(const Key('confirm-commit')), warnIfMissed: false);
      await t.pump(const Duration(milliseconds: 150));
      await t.tap(find.byKey(const Key('confirm-commit')), warnIfMissed: false);
      await t.pump(const Duration(milliseconds: 100));
      expect(_result, isNull, reason: 'confirmed inside the arm');
      await t.pump(const Duration(milliseconds: 800));
      if (find.byKey(const Key('confirm-ack')).evaluate().isNotEmpty) await t.tap(find.byKey(const Key('confirm-ack')));
      await t.pump(const Duration(milliseconds: 300));
      await t.tap(find.byKey(const Key('confirm-commit')));
      await t.pumpAndSettle();
      expect(_result, isTrue);
    });
  }
}
