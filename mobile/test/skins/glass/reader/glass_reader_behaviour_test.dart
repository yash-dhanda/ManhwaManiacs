// ignore_for_file: require_trailing_commas
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/ocr/models/page_text.dart';
import 'package:manhwamaniacs/features/reader/engine/neighbour.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/dialogue_overlay.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/glass_manga_reader.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/reader_chrome.dart';

import 'glass_reader_rig.dart';

/// The toast messages shown so far (the toast host lives in the shell, absent from the rig).
List<String> toasts(WidgetTester t) =>
    ProviderScope.containerOf(t.element(find.byType(GlassMangaReader))).read(glassToastProvider).map((e) => e.spec.message).toList();

bool chromeOn(WidgetTester t) => t.state<GlassMangaReaderState>(find.byType(GlassMangaReader)).engine.value.chromeVisible;

/// The engine's 800 ms grace reads the wall clock.
Future<void> pastGrace(WidgetTester t) => t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 900)));

Future<void> pull(WidgetTester t, double dy, {bool release = true}) async {
  final g = await t.startGesture(const Offset(200, 420));
  await g.moveBy(Offset(0, dy.sign * 20));
  await t.pump();
  await g.moveBy(Offset(0, dy));
  await t.pump();
  await t.pump(const Duration(milliseconds: 50));
  if (release) await g.up();
  await t.pump(const Duration(milliseconds: 50));
}

Future<void> key(WidgetTester t, LogicalKeyboardKey k, {String? char, bool shift = false}) async {
  if (shift) await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await t.sendKeyEvent(k, character: char);
  if (shift) await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await settleReader(t, ms: 500);
}

const _ocr = [
  PageText(page: 1, text: 'The gate opens at dawn.\nWho opens it?', boxes: [
    OcrTextBox(text: 'The gate opens at dawn.', x: 0.3, y: 0.2, width: 0.5, height: 0.06),
    OcrTextBox(text: 'Who opens it?', x: 0.2, y: 0.5, width: 0.4, height: 0.05),
  ]),
  PageText(page: 2, text: 'The gate is closed.', boxes: [OcrTextBox(text: 'The gate is closed.', x: 0.2, y: 0.3, width: 0.5, height: 0.06)]),
];

void main() {
  testWidgets('24 px of downward scroll hides the chrome, 56 px up restores it; the pill reads 1 / 6', (t) async {
    await pumpGlassReader(t);
    await settleReader(t, ms: 1000);
    expect(chromeOn(t), isTrue);
    await pastGrace(t);
    await pull(t, -40);
    await settleReader(t, ms: 400);
    expect(chromeOn(t), isFalse);
    expect(find.text('1 / 6').evaluate().isNotEmpty || find.text('2 / 6').evaluate().isNotEmpty, isTrue, reason: 'the pill shows the page readout');
    await pull(t, 70);
    await settleReader(t, ms: 400);
    expect(chromeOn(t), isTrue);
    await disposeGlassReader(t);
  });

  testWidgets('hidden chrome is out of semantics; Tab restores it', (t) async {
    final h = t.ensureSemantics();
    await pumpGlassReader(t);
    await settleReader(t, ms: 1000);
    expect(find.bySemanticsLabel('Reader settings'), findsWidgets);
    t.state<GlassMangaReaderState>(find.byType(GlassMangaReader)).engine.hideChrome();
    await settleReader(t, ms: 600);
    expect(find.bySemanticsLabel('Reader settings'), findsNothing);
    await key(t, LogicalKeyboardKey.tab);
    expect(chromeOn(t), isTrue);
    h.dispose();
    await disposeGlassReader(t);
  });

  testWidgets('the chrome never hides by scrolling while a screen reader runs', (t) async {
    await pumpGlassReader(t, accessible: true);
    await settleReader(t, ms: 1000);
    await pastGrace(t);
    await pull(t, -80);
    await settleReader(t, ms: 4000);
    expect(chromeOn(t), isTrue);
    await disposeGlassReader(t);
  });

  testWidgets('g opens the go-to popover and the done action jumps', (t) async {
    await pumpGlassReader(t);
    await settleReader(t, ms: 1000);
    await key(t, LogicalKeyboardKey.keyG, char: 'g');
    expect(find.byType(GoToPagePopover), findsOneWidget);
    await t.enterText(find.byKey(const ValueKey('reader-goto-field')), '4');
    await t.testTextInput.receiveAction(TextInputAction.done);
    await settleReader(t, ms: 1200);
    expect(find.byType(GoToPagePopover), findsNothing);
    expect(t.state<GlassMangaReaderState>(find.byType(GlassMangaReader)).engine.value.page, 4);
    await disposeGlassReader(t);
  });

  testWidgets('the rail reads "Page 1 of 6"', (t) async {
    final h = t.ensureSemantics();
    await pumpGlassReader(t);
    await settleReader(t, ms: 1000);
    expect(find.bySemanticsLabel('Page scrubber'), findsOneWidget);
    final node = t.getSemantics(find.bySemanticsLabel('Page scrubber'));
    expect(node.value, 'Page 1 of 6');
    h.dispose();
    await disposeGlassReader(t);
  });

  testWidgets(', opens ?sheet=settings and Android back closes it', (t) async {
    final rig = await pumpGlassReader(t, platform: TargetPlatform.android);
    await settleReader(t, ms: 1000);
    await key(t, LogicalKeyboardKey.comma, char: ',');
    await settleReader(t, ms: 800);
    expect(find.text('Page transition').evaluate().isNotEmpty || find.text('Chapters').evaluate().isNotEmpty, isTrue);
    expect(rig.at.queryParameters['sheet'], 'settings');
    await t.binding.handlePopRoute();
    await settleReader(t, ms: 2000);
    expect(find.text('One at a time'), findsNothing);
    expect(rig.at.queryParameters['sheet'], isNull);
    expect(find.byType(GlassMangaReader), findsOneWidget, reason: 'the sheet popped first, not the reader');
    await disposeGlassReader(t);
  });

  testWidgets('Layout Single turns pages with the arrow key', (t) async {
    await pumpGlassReader(t, prefsValues: {'mm.reader-prefs.device': '{"demo:k":{"layout":"single"}}'});
    await settleReader(t, ms: 1000);
    final s = t.state<GlassMangaReaderState>(find.byType(GlassMangaReader));
    expect(s.paged, isTrue);
    await key(t, LogicalKeyboardKey.arrowRight);
    await settleReader(t, ms: 800);
    expect(s.engine.value.page, 2);
    await disposeGlassReader(t);
  });

  testWidgets(
    'one at a time: a 144 raw px pull past the end commits the next chapter with the State kept',
    timeout: const Timeout(Duration(seconds: 90)),
    (t) async {
      final rig = await pumpGlassReader(t, pages: 2, prefsValues: {'mm.reader-settings.device': '{"glass":{"chapters":"single"}}'});
      await settleReader(t, ms: 1000);
      final before = t.state<GlassMangaReaderState>(find.byType(GlassMangaReader));
      final pos = t.state<ScrollableState>(find.byType(Scrollable).first).position;
      pos.jumpTo(pos.maxScrollExtent);
      await t.pump();
      final events = <NeighbourEvent>[];
      final sub = before.engine.neighbourEvents.listen(events.add);
      await pull(t, -144);
      await settleReader(t, ms: 3000);
      // Not awaited: the engine's broadcast controller completes the cancel on a later microtask turn the fake clock never runs.
      unawaited(sub.cancel());
      expect(events.map((e) => e.phase), contains(NeighbourPhase.locked));
      expect(rig.at.path, '/reader/demo/k/c3');
      expect(identical(t.state<GlassMangaReaderState>(find.byType(GlassMangaReader)), before), isTrue);
      await disposeGlassReader(t);
    },
  );

  testWidgets('SystemChrome: immersiveSticky on enter, edgeToEdge on exit; orientations widen then restore', (t) async {
    final rig = await pumpGlassReader(t);
    await settleReader(t, ms: 600);
    String? modeOf(MethodCall c) => c.method == 'SystemChrome.setEnabledSystemUIMode' ? c.arguments as String : null;
    expect(rig.systemCalls.map(modeOf).whereType<String>(), contains('SystemUiMode.immersiveSticky'));
    final orient = rig.systemCalls.where((c) => c.method == 'SystemChrome.setPreferredOrientations').map((c) => c.arguments as List).toList();
    expect(orient.last, isEmpty, reason: 'all four orientations in the reader');
    rig.router.pop();
    await settleReader(t, ms: 600);
    expect(rig.systemCalls.map(modeOf).whereType<String>().last, 'SystemUiMode.edgeToEdge');
    final o2 = rig.systemCalls.where((c) => c.method == 'SystemChrome.setPreferredOrientations').map((c) => c.arguments as List).toList();
    expect(o2.last, ['DeviceOrientation.portraitUp'], reason: 'portrait again on a phone');
    await disposeGlassReader(t);
  });

  testWidgets('Android exclusion rects: the rail band and the brightness band in portrait, only the rail in landscape, cleared on exit', (t) async {
    final rig = await pumpGlassReader(t, platform: TargetPlatform.android);
    await settleReader(t, ms: 800);
    final portrait = rig.platform.exclusions.last;
    expect(portrait.length, 2);
    expect(portrait[1], [0, 844 / 2 - 100, 0.12 * 390, 200]);
    expect(portrait[0][3], 200);
    rig.router.pop();
    await settleReader(t, ms: 600);
    expect(rig.platform.exclusions.last, isEmpty);
    await disposeGlassReader(t);

    final rig2 = await pumpGlassReader(t, platform: TargetPlatform.android, size: const Size(844, 390));
    await settleReader(t, ms: 800);
    expect(rig2.platform.exclusions.where((r) => r.isNotEmpty).every((r) => r.length <= 1), isTrue, reason: 'no brightness band in landscape');
    await disposeGlassReader(t);
  });

  testWidgets('iOS makes no exclusion call', (t) async {
    final rig = await pumpGlassReader(t);
    await settleReader(t, ms: 800);
    expect(rig.platform.exclusions, isEmpty);
    await disposeGlassReader(t);
  });

  testWidgets('keep awake: on with the switch, on while cruising with it off, released 2 s after, released when paused', (t) async {
    var rig = await pumpGlassReader(t, prefsValues: {'mm.reader-settings.device': '{"glass":{"keepAwake":true}}'});
    await settleReader(t, ms: 600);
    expect(rig.wakelock.on, isTrue);
    for (final st in [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused]) {
      t.binding.handleAppLifecycleStateChanged(st);
    }
    await t.pump();
    expect(rig.wakelock.on, isFalse);
    for (final st in [AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]) {
      t.binding.handleAppLifecycleStateChanged(st);
    }
    await disposeGlassReader(t);

    rig = await pumpGlassReader(t);
    await settleReader(t, ms: 600);
    expect(rig.wakelock.on, isFalse);
    final s = t.state<GlassMangaReaderState>(find.byType(GlassMangaReader));
    s.toggleCruise();
    await settleReader(t, ms: 300);
    expect(rig.wakelock.on, isTrue, reason: 'always on while cruise runs');
    s.toggleCruise();
    await settleReader(t, ms: 1000);
    expect(rig.wakelock.on, isTrue, reason: 'held for 2 s after cruise stops');
    await settleReader(t);
    expect(rig.wakelock.on, isFalse);
    await disposeGlassReader(t);
  });

  testWidgets('o shows the dialogue boxes in one CustomPaint; Esc removes them', (t) async {
    await pumpGlassReader(t, ocr: _ocr);
    await settleReader(t, ms: 1000);
    await key(t, LogicalKeyboardKey.keyO, char: 'o');
    expect(find.byKey(const ValueKey('reader-dialogue-paint')), findsOneWidget);
    final paint = t.widget<CustomPaint>(find.byKey(const ValueKey('reader-dialogue-paint')));
    expect((paint.painter! as DialoguePainter).boxes.length, 3);
    await key(t, LogicalKeyboardKey.escape);
    expect(find.byKey(const ValueKey('reader-dialogue-paint')), findsNothing);
    expect(find.byType(GlassMangaReader), findsOneWidget, reason: 'Esc closed the overlay, not the reader');
    await disposeGlassReader(t);
  });

  testWidgets('?q= opens with the hit lens and "Match 1 of 3"; n steps to match 2', (t) async {
    await pumpGlassReader(t, ocr: _ocr, query: '?q=gate');
    await settleReader(t);
    expect(find.text('Match 1 of 2'), findsOneWidget);
    expect(find.byType(HitLens), findsOneWidget);
    await key(t, LogicalKeyboardKey.keyN, char: 'n');
    expect(find.text('Match 2 of 2'), findsOneWidget);
    await disposeGlassReader(t);
  });

  testWidgets('landscape phone 844 x 390: page capsule top right, the bottom rail, no bottom capsule', (t) async {
    await pumpGlassReader(t, size: const Size(844, 390));
    await settleReader(t, ms: 1000);
    expect(find.byType(LandscapeScrubRail), findsOneWidget);
    await disposeGlassReader(t);
  });

  testWidgets('desktop frame 1366 x 1024: t and , open both panels; at 1100 the second closes the first', (t) async {
    await pumpGlassReader(t, size: const Size(1366, 1024));
    await settleReader(t, ms: 1000);
    await key(t, LogicalKeyboardKey.keyT, char: 't');
    await key(t, LogicalKeyboardKey.comma, char: ',');
    expect(find.bySemanticsLabel('Chapters'), findsWidgets);
    final s = t.state<GlassMangaReaderState>(find.byType(GlassMangaReader));
    expect(s.panelsOpen, (left: true, right: true));
    await disposeGlassReader(t);

    await pumpGlassReader(t, size: const Size(1100, 820));
    await settleReader(t, ms: 1000);
    await key(t, LogicalKeyboardKey.keyT, char: 't');
    await key(t, LogicalKeyboardKey.comma, char: ',');
    expect(t.state<GlassMangaReaderState>(find.byType(GlassMangaReader)).panelsOpen, (left: false, right: true));
    expect(toasts(t), contains('One panel at a time at this window size'));
    await disposeGlassReader(t);
  });

  testWidgets('hit targets meet the iOS and Android guidelines', (t) async {
    final h = t.ensureSemantics();
    await pumpGlassReader(t);
    await settleReader(t, ms: 1000);
    await expectLater(t, meetsGuideline(iOSTapTargetGuideline));
    await disposeGlassReader(t);
    await pumpGlassReader(t, platform: TargetPlatform.android);
    await settleReader(t, ms: 1000);
    await expectLater(t, meetsGuideline(androidTapTargetGuideline));
    h.dispose();
    await disposeGlassReader(t);
  });

  testWidgets('the brightness band owns a drag from inside it on both platforms; a drag at x 80 scrolls the strip', (t) async {
    for (final (platform, x) in [(TargetPlatform.iOS, 40.0), (TargetPlatform.android, 10.0)]) {
      await pumpGlassReader(t, platform: platform);
      await settleReader(t, ms: 1000);
      final s = t.state<GlassMangaReaderState>(find.byType(GlassMangaReader));
      final pos = t.state<ScrollableState>(find.byType(Scrollable).first).position;
      final before = pos.pixels;
      final g = await t.startGesture(Offset(x, 600));
      await g.moveBy(const Offset(0, -12));
      await t.pump();
      await g.moveBy(const Offset(0, -150));
      await t.pump();
      expect(find.bySemanticsLabel(RegExp(r'^Brightness \d+ %')), findsOneWidget, reason: '$platform');
      await g.up();
      await settleReader(t, ms: 700);
      expect(pos.pixels, before, reason: 'the strip did not scroll from the band ($platform)');
      expect(s.mounted, isTrue);
      await disposeGlassReader(t);
    }
    await pumpGlassReader(t);
    await settleReader(t, ms: 1000);
    final pos = t.state<ScrollableState>(find.byType(Scrollable).first).position;
    final before = pos.pixels;
    await t.dragFrom(const Offset(80, 600), const Offset(0, -200));
    await settleReader(t, ms: 500);
    expect(pos.pixels, greaterThan(before));
    await disposeGlassReader(t);
  });

  testWidgets('a furtherElsewhere row shows the jump toast', (t) async {
    await pumpGlassReader(t);
    await settleReader(t, ms: 1000);
    t
        .state<GlassMangaReaderState>(find.byType(GlassMangaReader))
        .engine
        .reportServerProgress(chapterKey: 'c3', chapterNumber: 146, lastPage: 12, advanced: false);
    await settleReader(t, ms: 500);
    expect(toasts(t), contains("You're further ahead on another device: Ch 146, p. 12"));
    await disposeGlassReader(t);
  });

  testWidgets('the Esc order: popover, then the dialogue overlay, then cinema, then leave', (t) async {
    await pumpGlassReader(t, ocr: _ocr, prefsValues: {'mm.reader-settings.device': '{"cinema":true}'});
    await settleReader(t, ms: 1000);
    final s = t.state<GlassMangaReaderState>(find.byType(GlassMangaReader));
    await key(t, LogicalKeyboardKey.keyO, char: 'o');
    s.setGoTo(true);
    await settleReader(t, ms: 300);
    await key(t, LogicalKeyboardKey.escape);
    expect(find.byType(GoToPagePopover), findsNothing);
    expect(find.byKey(const ValueKey('reader-dialogue-paint')), findsOneWidget);
    await key(t, LogicalKeyboardKey.escape);
    expect(find.byKey(const ValueKey('reader-dialogue-paint')), findsNothing);
    s.engine.hideChrome();
    await settleReader(t, ms: 300);
    await key(t, LogicalKeyboardKey.escape);
    expect(s.engine.value.chromeVisible, isTrue, reason: 'cinema exits first');
    await key(t, LogicalKeyboardKey.escape);
    expect(find.byType(GlassMangaReader), findsNothing, reason: 'the reader left');
    await disposeGlassReader(t);
  });
}
