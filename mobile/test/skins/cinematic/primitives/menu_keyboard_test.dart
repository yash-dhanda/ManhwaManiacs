import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_menu.dart';

import 'cine_harness.dart';

String? _picked;

Future<void> _open(WidgetTester t) async {
  _picked = null;
  await pumpCine(
    t,
    Builder(
      builder: (context) => Align(
        alignment: Alignment.topLeft,
        child: CineButton(
          key: const Key('trigger'),
          label: 'Menu',
          onPressed: () async => _picked = await showCineMenu<String>(context, anchor: cineAnchorRect(context), entries: const [
            CineMenuEntry(label: 'Open', value: 'open'),
            CineMenuEntry(label: 'Disabled', value: 'no', disabled: true),
            CineMenuEntry(label: 'Favourite', value: 'fav'),
            CineMenuEntry(label: 'Remove', value: 'rm', destructive: true, separatorBefore: true),
          ],),
        ),
      ),
    ),
  );
  await t.tap(find.byKey(const Key('trigger')));
  await t.pumpAndSettle();
}

void main() {
  testWidgets('arrows skip disabled items, Enter picks', (t) async {
    await _open(t);
    await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.pumpAndSettle();
    expect(_picked, 'fav');
  });

  testWidgets('type-ahead jumps to the first match', (t) async {
    await _open(t);
    await t.sendKeyEvent(LogicalKeyboardKey.keyR);
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.pumpAndSettle();
    expect(_picked, 'rm');
  });

  testWidgets('Home and End', (t) async {
    await _open(t);
    await t.sendKeyEvent(LogicalKeyboardKey.end);
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.pumpAndSettle();
    expect(_picked, 'rm');
  });

  testWidgets('Esc closes and focus returns to the trigger', (t) async {
    await pumpCine(t, const SizedBox());
    await _open(t);
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await t.pumpAndSettle();
    expect(_picked, isNull);
    expect(find.text('Favourite'), findsNothing);
  });
}
