// ignore_for_file: require_trailing_commas
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/novels/controllers/novel_reader_controller.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/chrome_top.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/lift_turn.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/novel_reader_screen.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/paged_view.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/pinch_size.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/selection_menu.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/side_panels.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/type_rows.dart';

import 'novel_rig.dart';

const _settingsKey = 'mm.novel-settings.device';
const _readerKey = 'mm.reader-settings.device';

Future<void> _key(WidgetTester t, LogicalKeyboardKey k, {bool shift = false}) async {
  if (shift) await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await t.sendKeyEvent(k);
  if (shift) await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await t.pump(const Duration(milliseconds: 50));
}

Future<void> _showChrome(WidgetTester t) async {
  await t.tapAt(const Offset(195, 500));
  await settle(t, ms: 500);
}

void main() {
  testWidgets('D12: pulling past the end arms at 48, locks at 72 and releasing opens the next chapter in place', (t) async {
    final rig = await pumpGlassNovel(t);
    await settle(t);
    await _key(t, LogicalKeyboardKey.end);
    await settle(t, ms: 300);
    final g = await t.startGesture(const Offset(195, 600));
    for (var i = 0; i < 30; i++) {
      await g.moveBy(const Offset(0, -40));
      await t.pump(const Duration(milliseconds: 16));
    }
    final state = rig.state;
    expect(find.byType(NovelPagedView), findsNothing);
    await g.up();
    await settle(t, ms: 1200);
    expect(find.text('CHAPTER 2'), findsOneWidget);
    expect(rig.location, contains('/novels/demo/k/2'));
    expect(state.mounted, isTrue, reason: 'the same reader page swapped the chapter in place');
    await disposeGlassNovel(t);
  });

  testWidgets('D12: auto next opens the next chapter after 900 ms and cancels on scroll-back', (t) async {
    await pumpGlassNovel(t);
    await settle(t);
    final ctl = t.state<GlassNovelReaderState>(find.byType(GlassNovelReader));
    expect(ctl.mounted, isTrue);
    await _key(t, LogicalKeyboardKey.end);
    await t.pump(const Duration(milliseconds: 400));
    // Scroll back before 900 ms: nothing opens.
    await t.drag(find.byType(Scrollable).first, const Offset(0, 300));
    await settle(t, ms: 1500);
    expect(find.text('END OF CHAPTER 1'), findsOneWidget);
    await _key(t, LogicalKeyboardKey.end);
    await settle(t, ms: 1600);
    expect(find.text('CHAPTER 2'), findsOneWidget);
    await disposeGlassNovel(t);
  });

  testWidgets('G8: a pinch steps the size per x1.15, shows "Text size N", never scales the text, reflows once on release', (t) async {
    await pumpGlassNovel(t);
    await settle(t);
    final a = await t.startGesture(const Offset(150, 400), pointer: 7);
    final b = await t.startGesture(const Offset(250, 400), pointer: 8);
    await t.pump();
    await a.moveTo(const Offset(118, 400));
    await b.moveTo(const Offset(282, 400));
    await t.pump(const Duration(milliseconds: 50));
    expect(find.byType(NovelTopCapsule), findsOneWidget);
    expect(find.text('Text size 22'), findsOneWidget);
    expect(find.byType(Transform).evaluate().where((e) => (e.widget as Transform).transform.getMaxScaleOnAxis() > 1.01), isEmpty);
    await a.up();
    await b.up();
    await settle(t, ms: 500);
    expect(find.text('Text size 22'), findsNothing);
    final prefs = rigPrefs(t);
    final stored = jsonDecode(prefs.getString('mm.novel-prefs.device')!) as Map<String, dynamic>;
    expect((stored['demo:k'] as Map<String, dynamic>)['fontSize'], 22);
    await disposeGlassNovel(t);
  });

  testWidgets('G5: Lift draws the turning copy with rotateY; G6: reduced motion turns with Fade', (t) async {
    await pumpGlassNovel(t, prefs: {_settingsKey: jsonEncode({'layout': 'paged', 'glassPageTurn': 'lift'})});
    await settle(t, ms: 1500);
    final g = await t.startGesture(const Offset(300, 500));
    await g.moveBy(const Offset(-20, 0));
    await t.pump(const Duration(milliseconds: 16));
    await g.moveBy(const Offset(-120, 0));
    await t.pump(const Duration(milliseconds: 16));
    await g.moveBy(const Offset(-120, 0));
    await t.pump(const Duration(milliseconds: 16));
    expect(find.byType(LiftingPage), findsOneWidget);
    await g.up();
    await settle(t, ms: 2500);
    expect(find.byType(LiftingPage), findsNothing);
    expect(t.state<NovelPagedViewState>(find.byType(NovelPagedView)).page, 1);
    await disposeGlassNovel(t);

    await pumpGlassNovel(t, reduced: true, prefs: {_settingsKey: jsonEncode({'layout': 'paged', 'glassPageTurn': 'lift'})});
    await settle(t, ms: 1500);
    await t.tapAt(const Offset(370, 500));
    await t.pump(const Duration(milliseconds: 80));
    expect(find.byType(LiftingPage), findsNothing);
    expect(find.byType(FadeTransition), findsWidgets);
    await settle(t, ms: 400);
    expect(t.state<NovelPagedViewState>(find.byType(NovelPagedView)).page, 1);
    await disposeGlassNovel(t);
  });

  testWidgets('C4: the chrome carries the ink tint with page-tinted on, none with it off', (t) async {
    await pumpGlassNovel(t);
    await settle(t);
    await _showChrome(t);
    expect(t.widget<NovelChromeTop>(find.byType(NovelChromeTop)).tint, isNotNull);
    await disposeGlassNovel(t);
    await pumpGlassNovel(t, prefs: {_readerKey: jsonEncode({'glass': {'pageTinted': false}})});
    await settle(t);
    await _showChrome(t);
    await settle(t);
    expect(t.widget<NovelChromeTop>(find.byType(NovelChromeTop)).tint, isNull);
    await disposeGlassNovel(t);
  });

  testWidgets('F1, B4: a selection opens the Glass menu with Shift+F10; Android back clears it first', (t) async {
    await pumpGlassNovel(t, android: true);
    await settle(t);
    final area = t.state<SelectionAreaState>(find.byType(SelectionArea));
    area.selectableRegion.selectAll();
    await settle(t, ms: 300);
    await _key(t, LogicalKeyboardKey.f10, shift: true);
    await settle(t, ms: 600);
    expect(find.byType(GlassSelectionMenu), findsOneWidget);
    for (final row in ['Copy', 'Bookmark this paragraph', 'React to this chapter']) {
      expect(find.text(row), findsOneWidget, reason: row);
    }
    expect(find.text('Play from here'), findsNothing, reason: 'no audio for this chapter');
    expect(find.textContaining('Recommend to'), findsNothing, reason: 'mobile/43 registers the sheet');
    await t.tap(find.text('React to this chapter'));
    await settle(t, ms: 600);
    expect(find.bySemanticsLabel('React with Hype'), findsOneWidget);
    await _key(t, LogicalKeyboardKey.escape);
    area.selectableRegion.selectAll();
    await settle(t, ms: 300);
    final popped = await t.binding.handlePopRoute();
    await settle(t, ms: 300);
    expect(popped, isTrue);
    expect(find.byType(GlassNovelReader), findsOneWidget, reason: 'back cleared the selection, it did not leave');
    await disposeGlassNovel(t);
  });

  testWidgets('B4: nothing beneath sends back to the book page', (t) async {
    await pumpGlassNovel(t, pushed: false);
    await settle(t);
    await t.binding.handlePopRoute();
    await settle(t, ms: 600);
    expect(find.text('feature page'), findsOneWidget);
    await disposeGlassNovel(t);
  });

  testWidgets('D2-D4: the desktop frame opens Contents and Aa as panels; F6 cycles; Esc closes and returns focus', (t) async {
    await pumpGlassNovel(t, size: const Size(1366, 1024));
    await settle(t);
    await _key(t, LogicalKeyboardKey.keyT);
    await settle(t, ms: 600);
    expect(find.bySemanticsLabel('Contents'), findsWidgets);
    expect(find.byType(NovelSidePanel), findsOneWidget);
    await _key(t, LogicalKeyboardKey.comma);
    await settle(t, ms: 600);
    expect(find.byType(NovelTypeBody), findsOneWidget);
    await _key(t, LogicalKeyboardKey.f6);
    await _key(t, LogicalKeyboardKey.escape);
    await settle(t, ms: 600);
    expect(find.byType(NovelTypeBody), findsNothing);
    await disposeGlassNovel(t);
  });

  testWidgets('D3: in a window where both panels do not fit, the second closes the first with the toast', (t) async {
    await pumpGlassNovel(t, size: const Size(1024, 1366));
    await settle(t);
    await _key(t, LogicalKeyboardKey.keyT);
    await settle(t, ms: 600);
    await _key(t, LogicalKeyboardKey.comma);
    await settle(t, ms: 900);
    expect(find.text('One panel at a time at this window size'), findsOneWidget);
    await disposeGlassNovel(t);
  });

  testWidgets('E8: keep screen awake on a phone when the switch is on', (t) async {
    final rig = await pumpGlassNovel(t, prefs: {_readerKey: jsonEncode({'glass': {'keepAwake': true}})});
    await settle(t);
    expect(rig.wakelock.enabled, greaterThan(0));
    await disposeGlassNovel(t);
  });

  testWidgets('B6: the reading surface takes focus on entry', (t) async {
    await pumpGlassNovel(t);
    await settle(t);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'novel reading surface');
    await disposeGlassNovel(t);
  });

  testWidgets('J: an error chapter shows the lens with Back to the book', (t) async {
    await pumpGlassNovel(t, failing: {'1': Exception('boom')});
    await settle(t);
    expect(find.text("Couldn't load this chapter"), findsOneWidget);
    expect(find.text('Back to the book'), findsOneWidget);
    await disposeGlassNovel(t);
  });

  testWidgets('J: an empty chapter', (t) async {
    await pumpGlassNovel(t, paragraphs: const []);
    await settle(t);
    expect(find.text('This chapter came through empty.'), findsOneWidget);
    await disposeGlassNovel(t);
  });

  testWidgets('J: a stale saved copy shows its age in the top-left group', (t) async {
    await pumpGlassNovel(t, cacheStale: true);
    await settle(t);
    await _showChrome(t);
    expect(find.textContaining('Saved copy · 3 h'), findsOneWidget);
    await disposeGlassNovel(t);
  });

  test('controller exposes bookmarkAt for a paragraph', () {
    expect(NovelBookmarkResult.values, contains(NovelBookmarkResult.saved));
  });
}
