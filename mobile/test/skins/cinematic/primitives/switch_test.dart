import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_switch.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

import 'cine_harness.dart';

void main() {
  testWidgets('toggling fires toggleOn then toggleOff', (t) async {
    final log = <HapticEvent>[];
    var v = false;
    await pumpCine(t, StatefulBuilder(builder: (context, set) => Center(child: CineSwitch(value: v, label: 'Notify', onChanged: (x) => set(() => v = x)))), haptics: log);
    await t.tap(find.byType(CineSwitch));
    await t.pumpAndSettle();
    await t.tap(find.byType(CineSwitch));
    await t.pumpAndSettle();
    expect(log, [HapticEvent.toggleOn, HapticEvent.toggleOff]);
  });

  testWidgets('pressed, the knob widens to 20 px', (t) async {
    await pumpCine(t, Center(child: CineSwitch(value: false, label: 'Notify', onChanged: (_) {})));
    expect(t.getSize(find.byKey(const Key('cine-switch-knob'))).width, 16);
    final g = await t.startGesture(t.getCenter(find.byType(CineSwitch)));
    await t.pumpAndSettle();
    expect(t.getSize(find.byKey(const Key('cine-switch-knob'))).width, 20);
    await g.cancel();
  });

  testWidgets('a server-backed switch shows loading, then reverts and errors on failure', (t) async {
    final done = Completer<void>();
    await pumpCine(t, Center(child: CineSwitch(value: false, label: '18+', onChanged: (_) => done.future)));
    await t.tap(find.byType(CineSwitch));
    await t.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('cine-switch-knob')), findsNothing);
    done.completeError(Exception('no'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('cine-switch-knob')), findsOneWidget);
    expect(find.text('That didn’t save. Try again.'), findsOneWidget);
    await t.pump(const Duration(milliseconds: 2100));
    expect(find.text('That didn’t save. Try again.'), findsNothing);
  });

  testWidgets('reduced motion: the knob jumps', (t) async {
    var v = false;
    await pumpCine(t, StatefulBuilder(builder: (context, set) => Center(child: CineSwitch(value: v, onChanged: (x) => set(() => v = x)))), reduced: true);
    final x0 = t.getTopLeft(find.byKey(const Key('cine-switch-knob'))).dx;
    await t.tap(find.byType(CineSwitch));
    await t.pump();
    expect(t.getTopLeft(find.byKey(const Key('cine-switch-knob'))).dx, greaterThan(x0 + 15));
  });
}
