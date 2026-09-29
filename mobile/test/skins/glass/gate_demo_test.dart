import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/glass/gate_demo.dart';

import '../../screenshots/support/shot_harness.dart';
import '../../screenshots/support/skin_shots.dart';

Widget gate([GateEngine engine = GateEngine.frost]) => ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: GlassGateScreen(ready: Future.value(), initialEngine: engine),
      ),
    );

void main() {
  setUpAll(loadAppFonts);

  Future<void> pumpGate(WidgetTester t, {Size size = const Size(390, 3000)}) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    t.view.padding = const FakeViewPadding(top: 47, bottom: 34);
    addTearDown(t.view.reset);
    await t.pumpWidget(gate());
    await t.pump(const Duration(milliseconds: 300));
  }

  testWidgets('shows the header, 8 rails, the four tabs and the readout', (t) async {
    await pumpGate(t);
    expect(find.text('Glass device gate'), findsOneWidget);
    for (var i = 1; i <= 8; i++) {
      expect(find.text('Rail $i'), findsOneWidget);
    }
    for (final tab in ['Home', 'Library', 'Sources', 'You']) {
      expect(find.bySemanticsLabel(tab), findsWidgets, reason: tab);
    }
    expect(find.textContaining('FPS'), findsOneWidget);
    expect(find.textContaining('FROST'), findsWidgets);
  });

  for (final (platform, min) in [(TargetPlatform.iOS, 44.0), (TargetPlatform.android, 48.0)]) {
    testWidgets('every control is at least $min on $platform', (t) async {
      debugDefaultTargetPlatformOverride = platform;
      await pumpGate(t);
      for (final label in ['LIQUID', 'FROST', 'Sheet', 'Auto-fling']) {
        final size = t.getSize(find.widgetWithText(InkWell, label));
        expect(size.height, greaterThanOrEqualTo(min), reason: label);
        expect(size.width, greaterThanOrEqualTo(min), reason: label);
      }
      for (var i = 0; i < 4; i++) {
        final size = t.getSize(find.byKey(ValueKey('tab-$i')));
        expect(size.height, greaterThanOrEqualTo(min), reason: 'tab $i');
        expect(size.width, greaterThanOrEqualTo(min), reason: 'tab $i');
      }
      debugDefaultTargetPlatformOverride = null;
    });
  }

  testWidgets('the Sheet capsule opens the frost sheet with 30 rows', (t) async {
    await pumpGate(t, size: const Size(390, 844));
    await t.tap(find.widgetWithText(InkWell, 'Sheet'));
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('Row 1'), findsOneWidget);
  });

  testWidgets('Tab reaches the switch and the capsules with visible focus', (t) async {
    await pumpGate(t);
    final focused = <String>[];
    for (var i = 0; i < 12; i++) {
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.pump();
      final f = FocusManager.instance.primaryFocus;
      final ctx = f?.context;
      if (ctx != null) {
        final label = find.descendant(of: find.byElementPredicate((e) => e == ctx), matching: find.byType(Text));
        if (label.evaluate().isNotEmpty) focused.add((t.widget(label.first) as Text).data ?? '');
      }
    }
    expect(focused, containsAll(['LIQUID', 'FROST', 'Sheet', 'Auto-fling']));
  });

  for (final engine in GateEngine.values) {
    testWidgets('Tab reaches all four tabs in ${engine.name}', (t) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(gate(engine));
      await t.pump(const Duration(milliseconds: 300));
      final reached = <int>{};
      for (var i = 0; i < 20; i++) {
        await t.sendKeyEvent(LogicalKeyboardKey.tab);
        await t.pump();
        final ctx = FocusManager.instance.primaryFocus?.context;
        if (ctx == null) continue;
        for (var k = 0; k < 4; k++) {
          final tabEl = find.byKey(ValueKey('tab-$k')).evaluate().firstOrNull;
          if (tabEl == null) continue;
          var inside = ctx == tabEl;
          ctx.visitAncestorElements((a) {
            if (a == tabEl) inside = true;
            return !inside;
          });
          if (inside) reached.add(k);
        }
      }
      expect(reached, {0, 1, 2, 3});
    });
  }

  testWidgets('captures the FROST gate at 390x844', (t) async {
    await pumpGate(t, size: const Size(390, 844));
    final dir = proofDir;
    if (dir != null) {
      await t.pumpWidget(RepaintBoundary(key: kSkinShotKey, child: gate()));
      await t.pump(const Duration(milliseconds: 300));
      await writeShot(t, find.byKey(kSkinShotKey), '$dir/glass-gate-frost-390x844.png', pixelRatio: 3);
    }
  });
}
