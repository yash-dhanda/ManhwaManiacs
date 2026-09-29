import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/glass/dev/calibration_page.dart';
import 'package:manhwamaniacs/skins/glass/dev/glass_dev_index.dart';
import 'package:manhwamaniacs/skins/glass/glass_skin.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../screenshots/support/shot_harness.dart';
import '../../support/test_overrides.dart';

Future<ProviderContainer> pumpPage(WidgetTester tester, Widget page, {Size size = const Size(390, 844)}) async {
  SharedPreferences.setMockInitialValues(testPrefsDefaults());
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs), activeProfileOverride()],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
        home: GlassRoot(child: Material(type: MaterialType.transparency, child: page)),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 400));
  return ProviderScope.containerOf(tester.element(find.byType(GlassRoot)));
}

void main() {
  setUpAll(loadAppFonts);

  for (final (platform, name) in [(TargetPlatform.iOS, '44 pt'), (TargetPlatform.android, '48 dp')]) {
    testWidgets('every control on the development index is at least $name and labelled', (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      final handle = tester.ensureSemantics();
      await pumpPage(tester, const GlassDevIndex());
      expect(find.text('Glass calibration'), findsWidgets);
      await expectLater(tester, meetsGuideline(platform == TargetPlatform.iOS ? iOSTapTargetGuideline : androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('every control on the calibration page is at least $name', (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      final handle = tester.ensureSemantics();
      await pumpPage(tester, const GlassCalibrationPage());
      await expectLater(tester, meetsGuideline(platform == TargetPlatform.iOS ? iOSTapTargetGuideline : androidTapTargetGuideline));
      handle.dispose();
      debugDefaultTargetPlatformOverride = null;
    });
  }

  testWidgets('the layers row shows the live counts and turns warning above the budget', (tester) async {
    final c = await pumpPage(tester, const GlassDevIndex());
    expect(find.textContaining('0 / 6 layers · 0 / 8 shapes · 0 scrims'), findsOneWidget);
    final ctl = c.read(glassRegistryProvider.notifier);
    for (var i = 0; i < 7; i++) {
      ctl.register(GlassRegistration(id: ctl.newId(), label: 'x$i', kind: GlassLayerKind.controls, shapes: 1, rect: () => null));
    }
    await tester.pump();
    expect(find.textContaining('7 / 6 layers · 7 / 8 shapes'), findsOneWidget);
  });

  testWidgets('the motion timings switch shows the overlay', (tester) async {
    final c = await pumpPage(tester, const GlassDevIndex());
    expect(find.byType(GlassMotionTimingsOverlay), findsNothing);
    c.read(glassShowMotionTimingsProvider.notifier).state = true;
    await tester.pump();
    expect(find.byType(GlassMotionTimingsOverlay), findsOneWidget);
  });

  /// The page is a lazy list: scroll until [text] is built.
  Future<void> revealText(WidgetTester tester, String text) async {
    final position = tester.state<ScrollableState>(find.byType(Scrollable).first).position;
    for (var i = 0; i < 60 && find.text(text).evaluate().isEmpty; i++) {
      position.jumpTo(position.pixels + 300);
      await tester.pump();
    }
    expect(find.text(text), findsOneWidget);
  }

  Set<String> textsUnder(Element root) {
    final out = <String>{};
    void walk(Element e) {
      final w = e.widget;
      if (w is Text && w.data != null) out.add(w.data!);
      e.visitChildren(walk);
    }

    walk(root);
    return out;
  }

  testWidgets('a hardware keyboard reaches a control with Tab and operates it with Enter and Space', (tester) async {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    addTearDown(() => FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic);
    final c = await pumpPage(tester, const GlassCalibrationPage());
    await revealText(tester, 'Increase contrast');
    expect(c.read(glassInAppPrefsProvider).increaseContrast, isFalse);
    var reached = false;
    for (var i = 0; i < 20 && !reached; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final ctx = FocusManager.instance.primaryFocus?.context;
      reached = ctx is Element && textsUnder(ctx).contains('Increase contrast');
    }
    expect(reached, isTrue, reason: 'Tab reaches the Increase contrast toggle');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(c.read(glassInAppPrefsProvider).increaseContrast, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(c.read(glassInAppPrefsProvider).increaseContrast, isFalse);
  });

  testWidgets('the physics tile is caught mid-flight and settles on a detent', (tester) async {
    await pumpPage(tester, const GlassCalibrationPage());
    await revealText(tester, 'Drag');
    final tile = find.text('Drag');
    final start = tester.getCenter(tile).dy;
    // Fling down and let go: the tile projects to a detent and settles through the rubber-band spring.
    final gesture = await tester.startGesture(tester.getCenter(tile));
    await gesture.moveBy(const Offset(0, 40));
    await gesture.moveBy(const Offset(0, 40));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 80));
    final mid = tester.getCenter(tile).dy;
    expect(mid, isNot(start));
    // Catch it in flight: a new touch stops the spring where it is.
    final g2 = await tester.startGesture(tester.getCenter(tile));
    await g2.moveBy(const Offset(0, 1));
    await tester.pump(const Duration(milliseconds: 50));
    final caught = tester.getCenter(tile).dy;
    await g2.up();
    await tester.pumpAndSettle();
    expect((caught - mid).abs(), lessThan(60));
    expect(tester.takeException(), isNull);
    expect(GlassMotion.recorder.entries.any((e) => e.label == 'RUBBER BAND'), isTrue);
  });
}
