import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_slider.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

import 'cine_harness.dart';

Future<ValueNotifier<double>> _pump(WidgetTester t, {List<HapticEvent>? haptics}) async {
  final v = ValueNotifier<double>(5);
  await pumpCine(
    t,
    Padding(
      padding: const EdgeInsets.all(24),
      child: ValueListenableBuilder<double>(
        valueListenable: v,
        builder: (_, val, __) => CineSlider(
          value: val,
          max: 20,
          divisions: 20,
          label: 'Size',
          flagText: (x) => '${x.round()} px',
          valueText: (x) => '${x.round()} pixels',
          onChanged: (x) => v.value = x,
        ),
      ),
    ),
    haptics: haptics,
  );
  await t.sendKeyEvent(LogicalKeyboardKey.tab);
  await t.pump();
  return v;
}

void main() {
  testWidgets('arrows step, Shift steps by ten, Home and End jump', (t) async {
    final v = await _pump(t);
    Future<void> key(LogicalKeyboardKey k) async {
      await t.sendKeyEvent(k);
      await t.pump(const Duration(milliseconds: 400));
    }

    await key(LogicalKeyboardKey.arrowRight);
    expect(v.value, 6);
    await key(LogicalKeyboardKey.arrowLeft);
    await key(LogicalKeyboardKey.arrowLeft);
    expect(v.value, 4);
    await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await key(LogicalKeyboardKey.arrowRight);
    await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    expect(v.value, 14);
    await key(LogicalKeyboardKey.end);
    expect(v.value, 20);
    await key(LogicalKeyboardKey.home);
    expect(v.value, 0);
  });

  testWidgets('semantics expose the value and increase / decrease', (t) async {
    final h = t.ensureSemantics();
    final v = await _pump(t);
    final node = t.getSemantics(find.bySemanticsLabel('Size'));
    expect(node.value, '5 pixels');
    expect(node.increasedValue, '6 pixels');
    expect(node.decreasedValue, '4 pixels');
    t.semantics.performAction(find.semantics.byLabel('Size'), SemanticsAction.increase);
    await t.pump();
    expect(v.value, 6);
    h.dispose();
  });

  testWidgets('dragging shows the flag and fires select per step', (t) async {
    final log = <HapticEvent>[];
    final v = await _pump(t, haptics: log);
    final g = await t.startGesture(t.getCenter(find.byType(CineSlider)));
    await g.moveBy(const Offset(60, 0));
    await t.pump();
    expect(find.byKey(const Key('cine-slider-flag')), findsOneWidget);
    await g.up();
    await t.pumpAndSettle();
    expect(find.byKey(const Key('cine-slider-flag')), findsNothing);
    expect(v.value, isNot(5));
    expect(log, isNotEmpty);
    expect(log.every((e) => e == HapticEvent.select), isTrue);
  });
}
