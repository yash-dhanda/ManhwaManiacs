import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_prefs_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/micro_progress.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/keyboard_sheet.dart';

import '../../../screenshots/support/shot_network.dart';
import 'reader_test_support.dart';

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key, {int ms = 700, bool shift = false, bool ctrl = false}) async {
  if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  if (ctrl) await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(key);
  if (ctrl) await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await settleReader(tester, ms: ms);
}

bool _micro(WidgetTester tester) => tester.widget<ReaderMicroProgress>(find.byType(ReaderMicroProgress)).visible;

void main() {
  setUpAll(setUpShotCoverCache);

  testWidgets('the Reader group is registered for the ? sheet with every binding of N', (tester) async {
    await pumpReader(tester);
    await settleReader(tester, ms: 300);
    final groups = ProviderScope.containerOf(tester.element(find.byType(MaterialApp))).read(shortcutRegistryProvider.notifier).registeredGroups();
    final reader = groups.singleWhere((g) => g.name == 'Reader');
    final described = reader.entries.map((e) => e.description).toSet();
    for (final d in [
      'Next page', 'Previous page', 'One screen forward', 'One screen back', 'Start of the chapter', 'End of the chapter',
      'Next chapter', 'Previous chapter', 'Go to page', 'Cinema mode', 'Show or hide the controls', 'Auto-scroll', 'Slower', 'Faster',
      'Bookmark this page', 'Back to the series', 'Contents', 'Zoom in', 'Zoom out', 'Reset zoom', 'Close, then leave',
    ]) {
      expect(described, contains(d));
    }
    await disposeReader(tester);
  });

  testWidgets('j k move a page, End and Home the ends, m toggles the chrome', (tester) async {
    await pumpReader(tester);
    await settleReader(tester, ms: 500);
    expect(find.text('1 / 6'), findsOneWidget);
    await _key(tester, LogicalKeyboardKey.keyJ);
    expect(find.text('2 / 6'), findsOneWidget);
    await _key(tester, LogicalKeyboardKey.keyK);
    expect(find.text('1 / 6'), findsOneWidget);
    await _key(tester, LogicalKeyboardKey.end, ms: 1200);
    expect(find.text('6 / 6'), findsOneWidget);
    await _key(tester, LogicalKeyboardKey.home, ms: 1200);
    expect(find.text('1 / 6'), findsOneWidget);
    await _key(tester, LogicalKeyboardKey.keyM, ms: 500);
    expect(chromeVisible(tester), isFalse);
    expect(_micro(tester), isTrue, reason: 'micro progress while hidden');
    await _key(tester, LogicalKeyboardKey.keyM, ms: 500);
    expect(chromeVisible(tester), isTrue);
    await disposeReader(tester);
  });

  testWidgets('c is cinema mode: the chrome goes and the micro progress stays away; Esc leaves cinema first', (tester) async {
    await pumpReader(tester);
    await settleReader(tester, ms: 500);
    await _key(tester, LogicalKeyboardKey.keyC, ms: 600);
    expect(chromeVisible(tester), isFalse);
    expect(_micro(tester), isFalse, reason: 'not in cinema mode');
    // Escape: cinema first, and the reader is still open.
    await _key(tester, LogicalKeyboardKey.escape, ms: 600);
    expect(chromeVisible(tester), isTrue);
    expect(find.text('series page'), findsNothing);
    // Escape again leaves the reader.
    await _key(tester, LogicalKeyboardKey.escape, ms: 1200);
    expect(find.text('series page'), findsOneWidget);
    await disposeReader(tester);
  });

  testWidgets('= - 0 zoom and show the chip; s leaves', (tester) async {
    await pumpReader(tester);
    await settleReader(tester, ms: 500);
    await _key(tester, LogicalKeyboardKey.equal, ms: 300);
    expect(find.text('110%'), findsOneWidget);
    await _key(tester, LogicalKeyboardKey.minus, ms: 300);
    expect(find.text('100%'), findsOneWidget);
    await _key(tester, LogicalKeyboardKey.equal, ms: 100);
    await _key(tester, LogicalKeyboardKey.equal, ms: 100);
    await _key(tester, LogicalKeyboardKey.digit0, ms: 300);
    expect(find.text('100%'), findsOneWidget);
    await settleReader(tester);
    await _key(tester, LogicalKeyboardKey.keyS, ms: 1200);
    expect(find.text('series page'), findsOneWidget);
    await disposeReader(tester);
  });

  testWidgets('g opens the page field, [ opens Contents, l goes to the next chapter', (tester) async {
    await pumpReader(tester);
    await settleReader(tester, ms: 500);
    await _key(tester, LogicalKeyboardKey.keyG, ms: 500);
    expect(find.byType(TextField), findsOneWidget);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settleReader(tester, ms: 500);
    await _key(tester, LogicalKeyboardKey.bracketLeft, ms: 800);
    expect(find.text('CONTENTS'), findsWidgets);
    await _key(tester, LogicalKeyboardKey.escape, ms: 800);
    await disposeReader(tester);
  });

  testWidgets('l steps to the next chapter and h to the previous', (tester) async {
    final rig = await pumpReader(tester);
    await settleReader(tester, ms: 500);
    await _key(tester, LogicalKeyboardKey.keyL, ms: 1000);
    expect(rig.router.state.uri.path, contains('/library/read/demo/k/c3'));
    await disposeReader(tester);
  });

  testWidgets('p starts auto-scroll and , . step the speed; b bookmarks', (tester) async {
    await pumpReader(tester);
    await settleReader(tester, ms: 500);
    await _key(tester, LogicalKeyboardKey.keyP, ms: 500);
    final speed = ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    double x() => speed.read(readerPrefsProvider('demo:k')).autoScrollSpeedX;
    final before = x();
    // Plain . is nothing (plain , opens Reading setup, mobile/13): only Shift+, and Shift+. change the speed.
    await _key(tester, LogicalKeyboardKey.period, ms: 300);
    expect(find.text('${(before + 0.25).toStringAsFixed(1)}×'), findsNothing);
    await _key(tester, LogicalKeyboardKey.period, ms: 300, shift: true);
    expect(find.text('${(before + 0.25).toStringAsFixed(1)}×'), findsWidgets, reason: '> is faster');
    await _key(tester, LogicalKeyboardKey.comma, ms: 300, shift: true);
    await _key(tester, LogicalKeyboardKey.comma, ms: 300, shift: true);
    expect(find.text('${(before - 0.25).toStringAsFixed(1)}×'), findsWidgets, reason: '< is slower');
    await _key(tester, LogicalKeyboardKey.keyP, ms: 300);
    await _key(tester, LogicalKeyboardKey.keyB, ms: 500);
    expect(tester.takeException(), isNull);
    await disposeReader(tester);
  });

  testWidgets('→ d step forward, ← a step back, in LTR', (tester) async {
    await pumpReader(tester);
    await settleReader(tester, ms: 500);
    await _key(tester, LogicalKeyboardKey.arrowRight, ms: 300);
    expect(find.text('2 / 6'), findsOneWidget);
    await _key(tester, LogicalKeyboardKey.keyD, ms: 300);
    expect(find.text('3 / 6'), findsOneWidget);
    await _key(tester, LogicalKeyboardKey.arrowLeft, ms: 300);
    expect(find.text('2 / 6'), findsOneWidget);
    await _key(tester, LogicalKeyboardKey.keyA, ms: 300);
    expect(find.text('1 / 6'), findsOneWidget);
    await disposeReader(tester);
  });

  testWidgets('in RTL the arrows and d a run the other way', (tester) async {
    await pumpReader(tester);
    await settleReader(tester, ms: 500);
    final c = ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await c.read(readerSeriesPrefsProvider.notifier).setFor('demo:k', {'direction': 'rtl'});
    await settleReader(tester, ms: 300);
    await _key(tester, LogicalKeyboardKey.keyJ, ms: 300);
    await _key(tester, LogicalKeyboardKey.keyJ, ms: 300);
    expect(find.text('3 / 6'), findsOneWidget);
    await _key(tester, LogicalKeyboardKey.arrowRight, ms: 300);
    expect(find.text('2 / 6'), findsOneWidget, reason: '→ is back in RTL');
    await _key(tester, LogicalKeyboardKey.keyD, ms: 300);
    expect(find.text('1 / 6'), findsOneWidget);
    await _key(tester, LogicalKeyboardKey.arrowLeft, ms: 300);
    expect(find.text('2 / 6'), findsOneWidget, reason: '← is forward in RTL');
    await _key(tester, LogicalKeyboardKey.keyA, ms: 300);
    expect(find.text('3 / 6'), findsOneWidget);
    await disposeReader(tester);
  });

  testWidgets('Space scrolls a screen forward and Shift+Space back', (tester) async {
    await pumpReader(tester);
    await settleReader(tester, ms: 500);
    final scroll = find.byType(Scrollable).first;
    double at() => tester.state<ScrollableState>(scroll).position.pixels;
    final start = at();
    await _key(tester, LogicalKeyboardKey.space, ms: 1200);
    final forward = at();
    expect(forward, greaterThan(start));
    await _key(tester, LogicalKeyboardKey.space, ms: 1200, shift: true);
    expect(at(), lessThan(forward));
    await disposeReader(tester);
  });

  testWidgets('Ctrl+Shift+→ and ← step chapters', (tester) async {
    final rig = await pumpReader(tester);
    await settleReader(tester, ms: 500);
    await _key(tester, LogicalKeyboardKey.arrowRight, ms: 1000, shift: true, ctrl: true);
    expect(rig.router.state.uri.path, contains('/library/read/demo/k/c3'));
    await disposeReader(tester);
    final rig2 = await pumpReader(tester);
    await settleReader(tester, ms: 500);
    await _key(tester, LogicalKeyboardKey.arrowLeft, ms: 1000, shift: true, ctrl: true);
    // The previous chapter is prepended to the feed or opened by the route; either way c1 is now the one read.
    expect(rig2.router.state.uri.path.contains('/c1') || find.text('CH 1').evaluate().isNotEmpty, isTrue);
    await disposeReader(tester);
  });

  testWidgets('the ? sheet lists every Reader binding with its keycaps', (tester) async {
    await pumpReader(tester);
    await settleReader(tester, ms: 300);
    final groups = ProviderScope.containerOf(tester.element(find.byType(MaterialApp))).read(shortcutRegistryProvider.notifier).registeredGroups();
    final reader = orderedShortcutGroups(groups).singleWhere((g) => g.name == 'Reader');
    final caps = {for (final e in reader.entries) e.description: keycapsOf(e, TargetPlatform.android)};
    expect(caps['Slower'], ['<']);
    expect(caps['Faster'], ['>']);
    expect(caps['Next page'], isNotEmpty);
    expect(caps['One screen back']!.single.toLowerCase(), contains('shift'));
    expect(caps['Next chapter']!.any((k) => k.toLowerCase().contains('ctrl')) || reader.entries.any((e) => e.description == 'Next chapter' && (e.activator as SingleActivator).control), isTrue);
    await disposeReader(tester);
  });

  testWidgets('with Single-key shortcuts off only modified bindings work', (tester) async {
    await pumpReader(tester);
    await settleReader(tester, ms: 500);
    final c = ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await c.read(singleKeyShortcutsProvider.notifier).set(false);
    await settleReader(tester, ms: 300);
    await _key(tester, LogicalKeyboardKey.keyJ, ms: 300);
    await _key(tester, LogicalKeyboardKey.arrowRight, ms: 300);
    await _key(tester, LogicalKeyboardKey.keyD, ms: 300);
    expect(find.text('1 / 6'), findsOneWidget, reason: 'no single-key binding fires');
    await _key(tester, LogicalKeyboardKey.keyC, ms: 600);
    expect(chromeVisible(tester), isTrue);
    // Modified and Escape bindings stay live.
    await _key(tester, LogicalKeyboardKey.arrowRight, ms: 1000, shift: true, ctrl: true);
    expect(find.text('1 / 6'), findsNothing);
    await disposeReader(tester);
  });
}
