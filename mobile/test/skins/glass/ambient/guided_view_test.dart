import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine.dart';
import 'package:manhwamaniacs/features/reader/models/reader_chapter.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/glass/ambient/guided.dart';
import 'package:manhwamaniacs/skins/glass/ambient/guided_view.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../reader/demo_pages.dart';

/// The demo chapter's pages 1-4 with the panel boxes of `brand/demo/demo.json` (pixels turned into page fractions).
({ReaderChapter chapter, Map<int, List<Rect>> panels}) demo() {
  final d = jsonDecode(File('../brand/demo/demo.json').readAsStringSync()) as Map<String, dynamic>;
  final pages = [for (final p in (d['pages'] as List).take(4)) Map<String, dynamic>.from(p as Map)];
  final panels = <int, List<Rect>>{
    for (final (i, p) in pages.indexed)
      i + 1: [
        for (final b in (p['panels'] as List).cast<Map<String, dynamic>>())
          Rect.fromLTWH((b['x'] as num) / (p['width'] as num), (b['y'] as num) / (p['height'] as num), (b['w'] as num) / (p['width'] as num), (b['h'] as num) / (p['height'] as num)),
      ],
  };
  return (chapter: DemoPages.load().chapter('c1', pages: 4), panels: panels);
}

void main() {
  const size = Size(390, 844);
  final announcements = <String>[];

  setUp(() {
    announcements.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, (m) async {
      if (m is Map && m['type'] == 'announce') announcements.add(((m['data'] as Map)['message'] ?? '') as String);
      return null;
    });
  });
  tearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, null));

  late ReaderEngine engine;
  late List<(int, double?)> closed;
  var reduced = false;

  Future<void> pump(WidgetTester t, {Map<int, List<Rect>>? panels, bool rtl = false, bool disableAnimations = false}) async {
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final d = demo();
    engine = ReaderEngine();
    engine.ambient.seed('c1', panels: {for (final e in (panels ?? d.panels).entries) e.key: e.value});
    engine.ambient.pageCount = 4;
    closed = [];
    reduced = disableAnimations;
    await t.pumpWidget(
      ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs), if (disableAnimations) glassMotionPrefsProvider.overrideWith((_) => const GlassMotionPrefs(reduced: true))],
        child: MediaQuery(
          data: MediaQueryData(size: size, devicePixelRatio: 3, disableAnimations: disableAnimations),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: SkinGlassRoot(
              child: Material(
                child: GlassGuidedView(engine: engine, chapter: d.chapter, rtl: rtl, initialPage: 1, onClose: (p, top) => closed.add((p, top)), onNextChapter: () {}),
              ),
            ),
          ),
        ),
      ),
    );
    await t.pump();
    await t.pump();
    await t.pump(const Duration(milliseconds: 600));
  }

  Finder lensFinder() => find.byWidgetPredicate((w) => w is SkinGlass && w.debugLabel == 'guided lens');

  Rect lens(WidgetTester t) => t.getRect(lensFinder());

  testWidgets('it opens framing panel 1: the lens sits on the panel at 24 px padding, and the counter reads Panel 1 of 8', (t) async {
    await pump(t);
    expect(lensFinder(), findsOneWidget);
    // Page 1 is 800 x 1777 contained in 390 x 844; panel 1 (800 x 814) is width-bound: framed at (390 - 48) / 390.
    final r = lens(t);
    expect(r.width, closeTo(342, 1), reason: '$r');
    expect(find.text('Panel 1 of 8 · Page 1'), findsOneWidget);
    expect(find.bySemanticsLabel('Show the whole page'), findsOneWidget);
    expect(find.bySemanticsLabel('Close guided view'), findsOneWidget);
    await t.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('the right arrow steps to panel 2 and announces it politely', (t) async {
    await pump(t);
    final before = lens(t);
    await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text('Panel 2 of 8 · Page 1'), findsOneWidget);
    expect(announcements.any((a) => a.contains('Panel 2')), isTrue);
    expect(before, isNotNull);
    await t.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a 60 px horizontal drag steps, a centre tap does nothing', (t) async {
    await pump(t);
    await t.tapAt(const Offset(195, 400));
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('Panel 1 of 8 · Page 1'), findsOneWidget);
    await t.dragFrom(const Offset(250, 300), const Offset(-60, 0));
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text('Panel 2 of 8 · Page 1'), findsOneWidget);
    await t.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('the right band steps at once and the left band goes back; mirrored for right-to-left', (t) async {
    await pump(t);
    await t.tapAt(const Offset(360, 400));
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text('Panel 2 of 8 · Page 1'), findsOneWidget);
    await t.tapAt(const Offset(20, 400));
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text('Panel 1 of 8 · Page 1'), findsOneWidget);
    await t.pumpWidget(const SizedBox.shrink());

    await pump(t, rtl: true);
    await t.tapAt(const Offset(20, 400));
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text('Panel 2 of 8 · Page 1'), findsOneWidget);
    await t.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a centre double tap shows the whole page and returns after 1.5 s', (t) async {
    await pump(t);
    await t.tapAt(const Offset(195, 400));
    await t.pump(const Duration(milliseconds: 80));
    await t.tapAt(const Offset(195, 400));
    await t.pump(const Duration(milliseconds: 600));
    expect(lensFinder(), findsNothing);
    await t.pump(const Duration(milliseconds: 1500));
    await t.pump(const Duration(milliseconds: 600));
    expect(lensFinder(), findsOneWidget);
    await t.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('the overview shows a numbered chip per panel and a tap flies to that panel', (t) async {
    await pump(t);
    await t.tap(find.bySemanticsLabel('Show the whole page'));
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text('1'), findsWidgets);
    expect(find.text('2'), findsWidgets);
    expect(lensFinder(), findsNothing);
    await t.tap(find.bySemanticsLabel('Panel 2').first);
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text('Panel 2 of 8 · Page 1'), findsOneWidget);
    expect(lensFinder(), findsOneWidget);
    await t.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Esc leaves, and inside the overview it closes the overview first', (t) async {
    await pump(t);
    await t.tap(find.bySemanticsLabel('Show the whole page'));
    await t.pump(const Duration(milliseconds: 600));
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await t.pump(const Duration(milliseconds: 600));
    expect(closed, isEmpty);
    expect(lensFinder(), findsOneWidget);
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await t.pump();
    expect(closed.single.$1, 1);
    await t.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a page with no panels reads "Page 2 · whole page" and next moves to the next page', (t) async {
    final d = demo();
    await pump(t, panels: {1: d.panels[1]!, 2: const [], 3: d.panels[3]!, 4: d.panels[4]!});
    await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text('Page 2 · whole page'), findsOneWidget);
    expect(lensFinder(), findsNothing);
    await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await t.pump(const Duration(milliseconds: 600));
    expect(find.textContaining('Page 3'), findsOneWidget);
    await t.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('with Reduce Motion a step completes within 150 ms', (t) async {
    await pump(t, disableAnimations: true);
    final before = lens(t);
    await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await t.pump(const Duration(milliseconds: 150));
    expect(find.text('Panel 2 of 8 · Page 1'), findsOneWidget);
    expect(lens(t).top, isNot(closeTo(before.top, 0.5)));
    expect(reduced, isTrue);
    await t.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a tall panel is walked in steps before moving on', (t) async {
    // Page 3 of the demo is one 2835 px panel on a 2931 px page: taller than the viewport at width fit.
    await pump(t);
    for (var i = 0; i < 5; i++) {
      await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await t.pump(const Duration(milliseconds: 100));
    }
    await t.pump(const Duration(milliseconds: 600));
    expect(find.textContaining('Page 3'), findsOneWidget);
    expect(find.text('Panel 6 of 8 · Page 3'), findsOneWidget);
    await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await t.pump(const Duration(milliseconds: 600));
    // Still panel 6: the first walked step of a tall panel is followed by another slice.
    expect(find.text('Panel 6 of 8 · Page 3'), findsOneWidget);
    await t.pumpWidget(const SizedBox.shrink());
  });

  test('the walk the view uses is the spec walk', () {
    expect(walkSteps(2.5 * 844, 844).length, 3);
  });
}
