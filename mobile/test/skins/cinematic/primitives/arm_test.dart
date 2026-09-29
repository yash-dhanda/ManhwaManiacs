import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_confirm_dialog.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

bool? _result;
int _opened = 0;

Future<void> _pump(WidgetTester t, {bool reduced = false, String? phrase}) async {
  _result = null;
  _opened = 0;
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(
    theme: ThemeData(extensions: const [cinematicTokens]),
    builder: (c, a) => MediaQuery(data: MediaQuery.of(c).copyWith(disableAnimations: reduced), child: a!),
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: CineButton(
            key: const Key('trigger'),
            label: 'Delete',
            onPressed: () async {
              _opened++;
              _result = await showCineConfirm(context, title: 'Delete Ana?', confirmLabel: 'Delete', destructive: true, typedPhrase: phrase);
            },
          ),
        ),
      ),
    ),
  ),);
}

Finder get _commit => find.byKey(const Key('confirm-commit'));
Finder get _rule => find.byKey(const Key('cine-arm-rule'));

void main() {
  testWidgets('a double tap opens the dialog and never confirms', (t) async {
    await _pump(t);
    final c = t.getCenter(find.byKey(const Key('trigger')));
    final g1 = await t.startGesture(c);
    await g1.up();
    await t.pump(const Duration(milliseconds: 60));
    final g2 = await t.startGesture(c);
    await g2.up();
    await t.pump(const Duration(milliseconds: 100));
    // The second tap lands on the barrier and dismisses; either way nothing was confirmed.
    await t.pumpAndSettle();
    expect(_opened, 1);
    expect(_result, isNot(true));
  });

  testWidgets('taps and Enter do nothing before 1000 ms; a tap after confirms; Ready is announced', (t) async {
    final announced = <String>[];
    t.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, (m) async {
      if (m is Map && m['type'] == 'announce') announced.add((m['data'] as Map)['message'] as String);
      return null;
    });
    addTearDown(() => t.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, null));
    await _pump(t);
    await t.tap(find.byKey(const Key('trigger')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    await t.tap(_commit);
    await t.pump(const Duration(milliseconds: 100));
    expect(_result, isNull);
    await t.pump(const Duration(milliseconds: 400)); // 900 ms
    await t.sendKeyEvent(LogicalKeyboardKey.tab); // Cancel holds the initial focus; Tab wraps to the commit
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.pump();
    expect(_result, isNull);
    await t.pump(const Duration(milliseconds: 150));
    expect(announced, contains('Ready'));
    await t.tap(_commit);
    await t.pumpAndSettle();
    expect(_result, isTrue);
  });

  testWidgets('Cancel works at 100 ms', (t) async {
    await _pump(t);
    await t.tap(find.byKey(const Key('trigger')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    await t.tap(find.byKey(const Key('confirm-cancel')));
    await t.pumpAndSettle();
    expect(_result, isFalse);
  });

  testWidgets('a heavy confirm stays disabled until the phrase is typed', (t) async {
    await _pump(t, phrase: 'RESTORE');
    await t.tap(find.byKey(const Key('trigger')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 1500));
    await t.tap(_commit);
    await t.pump(const Duration(milliseconds: 50));
    expect(_result, isNull);
    await t.enterText(find.descendant(of: find.byKey(const Key('confirm-phrase')), matching: find.byType(EditableText)), 'restore');
    await t.pump();
    await t.tap(_commit);
    await t.pumpAndSettle();
    expect(_result, isTrue);
  });

  testWidgets('reduced motion: no rule before 1000 ms, full at 1000 ms', (t) async {
    await _pump(t, reduced: true);
    await t.tap(find.byKey(const Key('trigger')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    expect(_rule, findsNothing);
    await t.pump(const Duration(milliseconds: 520));
    expect(_rule, findsOneWidget);
    final w = t.widget<FractionallySizedBox>(find.ancestor(of: _rule, matching: find.byType(FractionallySizedBox)).first);
    expect(w.widthFactor, 1.0);
  });
}
