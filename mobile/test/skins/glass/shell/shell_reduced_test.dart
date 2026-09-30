import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/shell/dock_state.dart';
import 'package:manhwamaniacs/skins/glass/shell/large_title.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';

import '../../../screenshots/support/shot_harness.dart';
import 'shell_rig.dart';

Future<void> _ms(WidgetTester t, int ms) async {
  await t.pump();
  await t.pump(Duration(milliseconds: ms));
}

Future<ShellRig> _pump(WidgetTester t, {String start = '/', bool reduced = false, bool solid = false}) async {
  final rig = await pumpGlassShell(t, start: start);
  final prefs = rig.container.read(glassInAppPrefsProvider.notifier);
  if (reduced) prefs.setReduceMotion(true);
  if (solid) prefs.setSolidGlass(true);
  await _ms(t, 300);
  return rig;
}

double _dockHeight(WidgetTester t) => t.getSize(find.bySemanticsLabel('Main')).height;

void main() {
  setUpAll(loadAppFonts);

  testWidgets('reduced motion: minimise is an instant swap', (t) async {
    final rig = await _pump(t, start: '/dev/glass/shell', reduced: true);
    final before = _dockHeight(t);
    await t.dragFrom(const Offset(200, 640), const Offset(0, -80));
    await _ms(t, 16);
    expect(rig.container.read(glassDockMinimisedProvider), isTrue);
    expect(_dockHeight(t), lessThan(before));
    expect(_dockHeight(t), closeTo(50, 0.5));
  });

  testWidgets('normal motion: the minimise morph has not finished 16 ms in', (t) async {
    final rig = await _pump(t, start: '/dev/glass/shell');
    await t.dragFrom(const Offset(200, 640), const Offset(0, -80));
    await _ms(t, 16);
    expect(rig.container.read(glassDockMinimisedProvider), isTrue);
    expect(_dockHeight(t), greaterThan(50));
    await _ms(t, 800);
    expect(_dockHeight(t), closeTo(50, 0.5));
  });

  testWidgets('reduced motion: a push is a 200 ms cross-fade, in place afterwards', (t) async {
    final rig = await _pump(t, start: '/dev/glass/shell', reduced: true);
    await t.tap(find.text('Push a level').first);
    await _ms(t, 260);
    expect(rig.at, startsWith('/dev/glass/shell'));
    expect(t.getTopLeft(find.byType(GlassLargeTitle).last).dx, lessThan(60));
  });

  testWidgets('normal motion: a push is still sliding 100 ms in', (t) async {
    await _pump(t, start: '/dev/glass/shell');
    await t.tap(find.text('Push a level').first);
    await _ms(t, 100);
    expect(t.getTopLeft(find.byType(GlassLargeTitle).last).dx, greaterThan(60));
  });

  testWidgets('a tab switch cross-fades over 120 ms under reduced motion', (t) async {
    await _pump(t, reduced: true);
    await t.tap(dockTab('Library'));
    await _ms(t, 200);
    expect(find.byType(FadeTransition), findsWidgets);
  });

  testWidgets('solid glass: no live layers, hard edges', (t) async {
    final rig = await _pump(t, start: '/dev/glass/shell', solid: true);
    expect(rig.container.read(glassRegistryProvider).layers, 0);
    expect(find.byKey(const ValueKey('glass-edge-hard')), findsWidgets);
  });
}
